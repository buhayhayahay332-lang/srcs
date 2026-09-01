local Module = {
    _initialized = false,
    _enabled = false,
    _hooked = false,
    shared = nil,
    _gunModule = nil,
    _savedConstants = {},
    _savedProps = {},
    _stateBases = {},
    _methodHooks = {},
    _respawnConn = nil,
    config = {
        recoil_reduction = 0,
        horizontal_recoil = 0,
        no_spread = false,
        force_auto = false,
        firerate_rpm = 0,
        firerate_enabled = false,
        equip_speed_boost = 1,
        equip_speed_enabled = false,
        reload_speed_value = 1,
        reload_speed_enabled = false,
        no_flash = false,
        no_trails = false,
        no_hit_effects = false,
        no_kickback = false,
    },
}

local GUN_PATH = { "Modules", "Items", "Item", "Gun" }

local function getGunModule()
    if Module._gunModule then
        return Module._gunModule
    end

    local RS = game:GetService("ReplicatedStorage")
    local node = RS

    for _, childName in ipairs(GUN_PATH) do
        node = node:WaitForChild(childName)
    end

    local ok, gunModule = pcall(require, node)
    if not ok then
        return nil, gunModule
    end

    Module._gunModule = gunModule
    return gunModule
end

local function getConstantsApi()
    if type(getconstants) ~= "function" or type(setconstant) ~= "function" then
        return nil
    end

    return getconstants, setconstant
end

local function saveConstantPatch(self, fn, key, index, oldValue)
    local fnState = self._savedConstants[fn]
    if not fnState then
        fnState = {}
        self._savedConstants[fn] = fnState
    end

    if not fnState[key] then
        fnState[key] = { index = index, old = oldValue }
    end
end

local function restoreSavedConstants(self)
    local _, setconstantFn = getConstantsApi()
    if not setconstantFn then
        return
    end

    for fn, fnState in pairs(self._savedConstants) do
        if type(fn) == "function" and type(fnState) == "table" then
            for _, patch in pairs(fnState) do
                if type(patch) == "table" and patch.index and patch.old ~= nil then
                    pcall(setconstantFn, fn, patch.index, patch.old)
                end
            end
        end
    end
end

local function patchConstantByValue(self, fn, key, oldValue, newValue)
    local getconstantsFn, setconstantFn = getConstantsApi()
    if not getconstantsFn then
        return false, "constant APIs unavailable"
    end

    local okConstants, constants = pcall(getconstantsFn, fn)
    if not okConstants or type(constants) ~= "table" then
        return false, "constants unavailable"
    end

    local patched = 0
    for index = 1, #constants do
        if constants[index] == oldValue then
            saveConstantPatch(self, fn, key .. "_" .. index, index, oldValue)
            if pcall(setconstantFn, fn, index, newValue) then
                patched = patched + 1
            end
        end
    end

    return patched > 0, patched > 0 and nil or "constant not found"
end

local function getHookFunction(self)
    if type(hookfunction) == "function" then
        return hookfunction
    end

    if self.shared and type(self.shared.hookfunction) == "function" then
        return self.shared.hookfunction
    end

    return nil
end

local function installMethodHook(self, target, name, handler)
    if type(target) ~= "table" or type(target[name]) ~= "function" then
        return false, "method not found: " .. tostring(name)
    end

    for _, existing in ipairs(self._methodHooks) do
        if existing.target == target and existing.name == name then
            return true
        end
    end

    local targetFunction = target[name]
    local state = {
        target = target,
        name = name,
        targetFunction = targetFunction,
        original = targetFunction,
        hookInstalled = false,
    }

    local replacement = function(...)
        return handler(state, ...)
    end

    local hookfn = getHookFunction(self)
    if hookfn then
        local okHook, original = pcall(hookfn, targetFunction, replacement)
        if okHook and type(original) == "function" then
            state.original = original
            state.hookInstalled = true
        end
    end

    pcall(function()
        target[name] = replacement
    end)
    table.insert(self._methodHooks, state)
    return true
end

local function restoreMethodHooks(self)
    local hookfn = getHookFunction(self)

    for index = #self._methodHooks, 1, -1 do
        local state = self._methodHooks[index]
        if state.hookInstalled and hookfn then
            pcall(hookfn, state.targetFunction, state.original)
        end

        if type(state.target) == "table" then
            pcall(function()
                state.target[state.name] = state.targetFunction
            end)
        end
    end

    self._methodHooks = {}
end

local function restoreSavedProps(self)
    for obj, objState in pairs(self._savedProps) do
        if type(obj) == "table" and type(objState) == "table" then
            for key, patch in pairs(objState) do
                if type(patch) == "table" and patch.has then
                    pcall(function()
                        rawset(obj, key, patch.value)
                    end)
                end
            end
        end
    end

    self._savedProps = {}
    self._stateBases = {}
end

local function shadowTableField(self, obj, key, replacement)
    if type(obj) ~= "table" then
        return false, "table unavailable"
    end

    local objState = self._savedProps[obj]
    if not objState then
        objState = {}
        self._savedProps[obj] = objState
    end

    if not objState[key] then
        objState[key] = { has = true, value = rawget(obj, key) }
    end

    rawset(obj, key, replacement)

    return true
end

local function getStateBase(self, gun, stateName)
    local bases = self._stateBases[stateName]
    if not bases then
        bases = {}
        self._stateBases[stateName] = bases
    end

    local base = bases[gun]
    if base == nil then
        local state = gun.states[stateName]
        if state then
            base = state:get()
            bases[gun] = base
        end
    end

    return base
end

local function setGunStateScaled(self, gun, stateName, multiplier, enabled)
    if not (gun and gun.states and gun.states[stateName]) then
        return
    end

    local state = gun.states[stateName]
    local base = getStateBase(self, gun, stateName)
    if base == nil then
        return
    end

    local goal = nil
    if enabled then
        goal = base * multiplier
    else
        goal = base
    end

    local current = state:get()
    if current ~= goal then
        pcall(function()
            state:set(goal)
        end)
    end
end

local function setGunStateAbs(self, gun, stateName, value, enabled)
    if not (gun and gun.states and gun.states[stateName]) then
        return
    end

    local base = getStateBase(self, gun, stateName)
    if base == nil then
        return
    end

    local state = gun.states[stateName]
    local goal = enabled and value or base

    local current = state:get()
    if current ~= goal then
        pcall(function()
            state:set(goal)
        end)
    end
end

function Module:setShared(shared)
    if type(shared) ~= "table" then
        return false, "shared must be table"
    end

    self.shared = shared

    if type(shared.applyToEnv) == "function" then
        pcall(function()
            shared:applyToEnv()
        end)
    end

    return true
end

function Module:_installHook()
    if self._hooked then
        return true
    end

    local gunModule, gunErr = getGunModule()
    if not gunModule then
        return false, tostring(gunErr or "gun module unavailable")
    end

    installMethodHook(self, gunModule, "flash", function(state, gun, ...)
        if self._enabled and self.config.no_flash == true then
            return nil
        end
        return state.original(gun, ...)
    end)

    installMethodHook(self, gunModule, "shoot", function(state, gun, ...)
        if not self._enabled or self.config.no_flash ~= true or not gun or not gun.shot then
            return state.original(gun, ...)
        end

        local smoke = gun.shot:FindFirstChild("Smoke")
        local smokeParent = smoke and smoke.Parent
        if smoke and smokeParent then
            smoke.Parent = nil
            task.delay(0.35, function()
                if smoke and not smoke.Parent and smokeParent and smokeParent.Parent then
                    smoke.Parent = smokeParent
                end
            end)
        end

        return state.original(gun, ...)
    end)

    installMethodHook(self, gunModule, "trail", function(state, gun, ...)
        if self._enabled and self.config.no_trails == true then
            return nil
        end
        return state.original(gun, ...)
    end)

    installMethodHook(self, gunModule, "bullet_hit", function(state, gun, ...)
        if self._enabled and self.config.no_hit_effects == true then
            return nil
        end
        return state.original(gun, ...)
    end)

    local parentModule = getmetatable(gunModule)
    if type(parentModule) == "table" and type(parentModule.emit_blood) == "function" then
        installMethodHook(self, parentModule, "emit_blood", function(state, gun, ...)
            if self._enabled and self.config.no_hit_effects == true then
                return nil
            end
            return state.original(gun, ...)
        end)
    end

    installMethodHook(self, gunModule, "reload_begin", function(state, gun, ...)
        local reloadEnabled = self._enabled and self.config.reload_speed_enabled == true
        local reloadValue = tonumber(self.config.reload_speed_value) or 1
        reloadValue = math.max(0.1, math.min(1, reloadValue))
        setGunStateAbs(self, gun, "reload_speed", reloadValue, reloadEnabled)
        return state.original(gun, ...)
    end)

    installMethodHook(self, gunModule, "send_shoot", function(state, gun, ...)
        setGunStateScaled(self, gun,"spread", 0, self._enabled and self.config.no_spread == true)
        return state.original(gun, ...)
    end)

    installMethodHook(self, gunModule,"input_shoot", function(state, gun, ...)
        local rpm = tonumber(self.config.firerate_rpm) or 0
        setGunStateAbs(self, gun, "firerate", rpm, self._enabled and self.config.firerate_enabled == true and rpm > 0)
        local forceAuto = self._enabled and self.config.force_auto == true
        if forceAuto then
            local hadAuto = rawget(gun,"automatic") ~= nil
            local oldAuto = rawget(gun,"automatic")
            rawset(gun,"automatic",true)
            state.original(gun, ...)
            if hadAuto then
                rawset(gun,"automatic",oldAuto)
            else
                rawset(gun,"automatic",nil)
            end
        else
            state.original(gun, ...)
        end
    end)

    installMethodHook(self, gunModule,"input_render", function(state, gun, ...)
        local rpm = tonumber(self.config.firerate_rpm) or 0
        setGunStateAbs(self, gun, "firerate", rpm, self._enabled and self.config.firerate_enabled == true and rpm > 0)
        local forceAuto = self._enabled and self.config.force_auto == true
        if forceAuto then
            local hadAuto = rawget(gun,"automatic") ~= nil
            local oldAuto = rawget(gun,"automatic")
            rawset(gun,"automatic",true)
            state.original(gun, ...)
            if hadAuto then
                rawset(gun,"automatic",oldAuto)
            else
                rawset(gun,"automatic",nil)
            end
        else
            state.original(gun, ...)
        end
    end)

    installMethodHook(self, gunModule,"recoil_function", function(state, gun, ...)
        local recoilMult = 1 - (tonumber(self.config.recoil_reduction)or 0)
        local horizontalMult = 1 - (tonumber(self.config.horizontal_recoil)or 0)
        setGunStateScaled(self, gun,"recoil_up", recoilMult, self._enabled)
        setGunStateScaled(self, gun,"recoil_side", horizontalMult, self._enabled)
        return state.original(gun, ...)
    end)

    self._hooked = true
    return true
end

function Module:_applyConfig()
    local gunModule, gunErr = getGunModule()
    if not gunModule then
        return false, tostring(gunErr or "gun module unavailable")
    end

    restoreSavedConstants(self)
    restoreSavedProps(self)

    local enabled = self._enabled == true

    if enabled then
        local equipBoost = tonumber(self.config.equip_speed_boost) or 1
        if self.config.equip_speed_enabled == true and equipBoost > 1 then
            local equipFn = gunModule.equip
            if type(equipFn) == "function" then
                -- GunModule.equip uses this value for the equip pivot timing.
                patchConstantByValue(self, equipFn, "equip_pivot", 0.2, 0.2 * equipBoost)
            end
        end

        if self.config.no_kickback == true then
            shadowTableField(self, gunModule.anim, "Shoot", {
                key1 = function() return { Completed = { Wait = function() end } } end,
                key2 = function() return { Completed = { Wait = function() end } } end,
                key3 = function() return { Completed = { Wait = function() end } } end,
            })
        end
    end

    return true
end

function Module:_enableRespawnReapply()
    if self._respawnConn then
        return
    end

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    if not player then
        return
    end

    self._respawnConn = player.CharacterAdded:Connect(function()
        if not self._initialized then
            return
        end

        for _, delay in ipairs({ 0.5, 2 }) do
            task.delay(delay, function()
                if not self._initialized then
                    return
                end

                local wasEnabled = self._enabled == true
                self._gunModule = nil
                self._hooked = false

                local ok = self:init(true)
                if ok and wasEnabled and not self._enabled then
                    self._enabled = true
                    self:_applyConfig()
                end
            end)
        end
    end)
end

function Module:init(force)
    if self._initialized and not force then
        return true
    end

    if self._initialized and force then
        self:unload()
    end

    local okHook, hookErr = pcall(function()
        return self:_installHook()
    end)
    if not okHook then
        return false, tostring(hookErr)
    end

    local okApply, applyErr = pcall(function()
        return self:_applyConfig()
    end)
    if not okApply then
        return false, tostring(applyErr)
    end

    self._initialized = true
    self:_enableRespawnReapply()
    return true
end

function Module:load(force)
    return self:init(force)
end

function Module:isLoaded()
    return self._initialized
end

function Module:setEnabled(state)
    local okInit, initErr = self:init(false)
    if not okInit then
        return false, initErr
    end

    self._enabled = state == true
    self:_applyConfig()
    return true
end

function Module:updateConfig(newConfig)
    if type(newConfig) ~= "table" then
        return false, "config must be table"
    end

    for key, value in pairs(newConfig) do
        if self.config[key] ~= nil then
            self.config[key] = value
        end
    end

    self:_applyConfig()
    return true
end

function Module:getConfig()
    return self.config
end

function Module:unload()
    self._enabled = false

    restoreSavedConstants(self)
    restoreMethodHooks(self)
    restoreSavedProps(self)
    self._savedProps = {}
    self._savedConstants = {}
    self._stateBases = {}
    self._hooked = false

    if self._respawnConn then
        self._respawnConn:Disconnect()
        self._respawnConn = nil
    end

    self._initialized = false
    return true
end

return Module
