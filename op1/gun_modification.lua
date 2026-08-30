local Module = {
    _initialized = false,
    _enabled = false,
    _hooked = false,
    shared = nil,
    _gunModule = nil,
    _savedConstants = {},
    _savedFunctions = {},
    config = {
        recoil_reduction = 0,
        horizontal_recoil = 0,
        no_spread = false,
        force_auto = false,
        firerate_multiplier = 1,
        reload_speed_boost = 1,
        equip_speed_boost = 1,
        silent_shots = false,
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

local function savePatch(self, fn, key, index, oldValue)
    local fnState = self._savedConstants[fn]
    if not fnState then
        fnState = {}
        self._savedConstants[fn] = fnState
    end

    if not fnState[key] then
        fnState[key] = { index = index, old = oldValue }
    end
end

local function restoreSavedPatches(self)
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

local function saveFunctionPatch(self, name, original)
    if self._savedFunctions[name] then
        return
    end

    self._savedFunctions[name] = original
end

local function restoreSavedFunctions(self)
    local gunModule = self._gunModule

    for name, original in pairs(self._savedFunctions) do
        if type(original) == "function" and type(gunModule) == "table" then
            pcall(function()
                gunModule[name] = original
            end)
        end
    end

    self._savedFunctions = {}
end

local function replaceFunction(self, name, replacement)
    local gunModule = self._gunModule
    if type(gunModule) ~= "table" then
        return false, "gun module unavailable"
    end

    local original = gunModule[name]
    if type(original) ~= "function" then
        return false, "function not found"
    end

    saveFunctionPatch(self, name, original)
    gunModule[name] = replacement

    return true
end

local function patchConstantByValue(self, fn, key, oldValue, newValue)
    local getconstantsFn, setconstantFn = getConstantsApi()
    if not getconstantsFn then
        return false, "C APIs unavailable"
    end

    local constants = getconstantsFn(fn)
    if type(constants) ~= "table" then
        return false, "C unavailable"
    end

    local patched = 0

    for index = 1, #constants do
        if constants[index] == oldValue then
            savePatch(self, fn, key .. "_" .. index, index, oldValue)
            local ok = pcall(setconstantFn, fn, index, newValue)
            if ok then
                patched = patched + 1
            end
        end
    end

    if patched > 0 then
        return true
    end

    return false, "C not found"
end

local function patchRecoilFunction(self, fn, vertical, horizontal)
    local getconstantsFn, setconstantFn = getConstantsApi()
    if not getconstantsFn then
        return false, "C APIs unavailable"
    end

    local constants = getconstantsFn(fn)
    if type(constants) ~= "table" then
        return false, "C unavailable"
    end

    local markerIndex = nil
    for index = 1, #constants do
        if constants[index] == "pc" then
            markerIndex = index
            break
        end
    end

    if markerIndex then
        savePatch(self, fn, "recoil_marker", markerIndex, constants[markerIndex])
        pcall(setconstantFn, fn, markerIndex, "tite")

        local verticalIndex = markerIndex + 1
        if type(constants[verticalIndex]) == "number" then
            savePatch(self, fn, "recoil_vertical", verticalIndex, constants[verticalIndex])
            pcall(setconstantFn, fn, verticalIndex, vertical)
        end

        local horizontalIndex = markerIndex + 2
        if type(constants[horizontalIndex]) == "number" then
            savePatch(self, fn, "recoil_horizontal", horizontalIndex, constants[horizontalIndex])
            pcall(setconstantFn, fn, horizontalIndex, horizontal)
        end

        return true
    end

    local patched = 0
    for index = 1, #constants do
        if type(constants[index]) == "number" then
            if patched == 0 then
                savePatch(self, fn, "recoil_vertical", index, constants[index])
                pcall(setconstantFn, fn, index, vertical)
                patched = patched + 1
            elseif patched == 1 then
                savePatch(self, fn, "recoil_horizontal", index, constants[index])
                pcall(setconstantFn, fn, index, horizontal)
                return true
            end
        end
    end

    return patched > 0
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

    self._hooked = true
    return true
end

function Module:_applyConfig()
    local gunModule, gunErr = getGunModule()
    if not gunModule then
        return false, tostring(gunErr or "gun module unavailable")
    end

    restoreSavedPatches(self)
    restoreSavedFunctions(self)

    local enabled = self._enabled == true

    if enabled then
        local recoilValue = tonumber(self.config.recoil_reduction) or 0
        local horizontalValue = tonumber(self.config.horizontal_recoil) or 0

        local recoilFn = gunModule.recoil_function
        if type(recoilFn) == "function" then
            patchRecoilFunction(self, recoilFn, recoilValue, horizontalValue)
        end

        if self.config.no_spread == true then
            local sendShootFn = gunModule.send_shoot
            if type(sendShootFn) == "function" then
                patchConstantByValue(self, sendShootFn, "spread", 100, 0)
            end
        end

        if self.config.force_auto == true then
            local inputShootFn = gunModule.input_shoot
            if type(inputShootFn) == "function" then
                patchConstantByValue(self, inputShootFn, "auto", "automatic", "tag")
            end

            local inputRenderFn = gunModule.input_render
            if type(inputRenderFn) == "function" then
                patchConstantByValue(self, inputRenderFn, "auto", "automatic", "tag")
            end
        end

        local firerateBoost = tonumber(self.config.firerate_multiplier) or 1
        if firerateBoost > 1 then
            local firerateRenderFn = gunModule.input_render
            if type(firerateRenderFn) == "function" then
                patchConstantByValue(self, firerateRenderFn, "firerate", 60, 60 * firerateBoost)
            end

            local firerateShootFn = gunModule.input_shoot
            if type(firerateShootFn) == "function" then
                patchConstantByValue(self, firerateShootFn, "firerate", 60, 60 * firerateBoost)
            end
        end

        local reloadBoost = tonumber(self.config.reload_speed_boost) or 1
        if reloadBoost > 1 then
            local reloadBeginFn = gunModule.reload_begin
            if type(reloadBeginFn) == "function" then
                patchConstantByValue(self, reloadBeginFn, "reload_wait", 0.5, math.max(0.01, 0.5 / reloadBoost))
                patchConstantByValue(self, reloadBeginFn, "single_load_wait", 0.15, math.max(0.01, 0.15 / reloadBoost))
            end
        end

        local equipBoost = tonumber(self.config.equip_speed_boost) or 1
        if equipBoost > 1 then
            local equipFn = gunModule.equip
            if type(equipFn) == "function" then
                patchConstantByValue(self, equipFn, "equip_pivot", 0.2, math.max(0.01, 0.2 / equipBoost))
            end
        end

        if self.config.silent_shots == true then
            local silentShootFn = gunModule.shoot
            if type(silentShootFn) == "function" then
                patchConstantByValue(self, silentShootFn, "silent", "Shoot", "SilencedShoot")
            end
        end

        if self.config.no_flash == true then
            replaceFunction(self, "flash", function() end)

            local smokeShootFn = gunModule.shoot
            if type(smokeShootFn) == "function" then
                patchConstantByValue(self, smokeShootFn, "smoke", 3, 0)
            end
        end

        if self.config.no_trails == true then
            local trailFn = gunModule.trail
            if type(trailFn) == "function" then
                patchConstantByValue(self, trailFn, "trail", 0.1, 0)
            end
        end

        if self.config.no_hit_effects == true then
            replaceFunction(self, "bullet_hit", function() end)
        end

        if self.config.no_kickback == true then
            replaceFunction(self, "kickback", function() end)
        end
    end

    return true
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

    restoreSavedPatches(self)
    restoreSavedFunctions(self)
    self._savedConstants = {}
    self._savedFunctions = {}
    self._hooked = false

    self._initialized = false
    return true
end

return Module
