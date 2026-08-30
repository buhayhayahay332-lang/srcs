while true do end 
local moduleRepo = "https://raw.githubusercontent.com/buhayhayahay332-lang/srcs/refs/heads/main/op1/"

local MODULE_FILES = {
    shared_runtime     = "shared_runtime.lua",
    fullbright         = "fullbright.lua",
    gun_modification   = "gun_modification.lua",
    EspLib             = "EspLib.lua",
    silent_aim         = "silent_aim.lua",
    attachment_editor  = "attachment_editor.lua",
    auto_shoot         = "auto_shoot.lua",
}

local moduleCache        = {}
local sharedRuntimeCache = nil
local ESP_MODULE_NAME    = "EspLib"

local function log(msg)
    print("[OP1] " .. tostring(msg))
end

local function loadSharedRuntime()
    if type(sharedRuntimeCache) == "table" then return sharedRuntimeCache end
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(moduleRepo .. MODULE_FILES.shared_runtime))()
    end)
    if not ok or type(result) ~= "table" then
        log("shared runtime failed to load")
        return nil
    end
    sharedRuntimeCache = result
    if type(result.applyToEnv) == "function" then
        pcall(function() result:applyToEnv() end)
    end
    return sharedRuntimeCache
end

local function initModule(name, forceReload)
    local cached = moduleCache[name]
    if cached and cached.initialized and not forceReload then return cached.module end

    local file = MODULE_FILES[name]
    if not file then log("unknown module: " .. tostring(name)) return nil end

    local ok, moduleObj = pcall(function()
        return loadstring(game:HttpGet(moduleRepo .. file))()
    end)
    if not ok or not moduleObj then
        log(name .. " failed to load")
        return nil
    end

    local sharedRuntime = loadSharedRuntime()
    if sharedRuntime then
        sharedRuntime.modules = sharedRuntime.modules or {}
        sharedRuntime.modules[name] = moduleObj
        if type(moduleObj.setShared) == "function" then
            pcall(function() moduleObj:setShared(sharedRuntime) end)
        elseif type(moduleObj) == "table" and moduleObj.shared == nil then
            moduleObj.shared = sharedRuntime
        end
    end

    local okInit, initErr = true, nil
    if type(moduleObj.load) == "function" then
        okInit, initErr = moduleObj:load(forceReload == true)
    elseif type(moduleObj.init) == "function" then
        okInit, initErr = moduleObj:init(forceReload == true)
    end
    if okInit == false then
        log(name .. " init failed")
        return nil
    end

    moduleCache[name] = { initialized = true, module = moduleObj }
    return moduleObj
end

local function withModule(name, callback)
    local moduleObj = initModule(name, false)
    if not moduleObj then return false end
    local ok, result = pcall(callback, moduleObj)
    if not ok then log(name .. " callback error") return false end
    return result ~= false
end

local function withModuleRetry(name, callback, retries)
    retries = retries or 3
    local function attempt(n)
        local moduleObj = initModule(name, false)
        if moduleObj then
            local ok, result = pcall(callback, moduleObj)
            if ok and result ~= false then return end
        end
        if n > 1 then
            task.delay(0.5, function() attempt(n - 1) end)
        else
            log(name .. " gave up after retries")
        end
    end
    attempt(retries)
end

local function setSilentAim(state)
    withModule("silent_aim", function(m)
        if type(m.setEnabled) == "function" then m:setEnabled(state) end
    end)
end
local function setSilentAimFov(value)
    withModule("silent_aim", function(m)
        if type(m.setFov) == "function" then m:setFov(value) end
    end)
end
local function setSilentAimSmoothness(value)
    withModule("silent_aim", function(m)
        if type(m.setSmoothness) == "function" then m:setSmoothness(value) end
    end)
end
local function setSilentAimMode(mode)
    withModule("silent_aim", function(m)
        if type(m.setMode) == "function" then m:setMode(mode) end
    end)
end
local function setAimAssistActivation(mode)
    withModule("silent_aim", function(m)
        if type(m.setAimAssistActivation) == "function" then m:setAimAssistActivation(mode) end
    end)
end
local function setSilentAimTargetMode(mode)
    withModule("silent_aim", function(m)
        if type(m.setTargetMode) == "function" then m:setTargetMode(mode) end
    end)
end
local function setSilentAimTeamCheck(state)
    withModule("silent_aim", function(m)
        if type(m.setTeamCheck) == "function" then m:setTeamCheck(state) end
    end)
end
local function setSilentAimTargetGadgets(state)
    withModule("silent_aim", function(m)
        if type(m.setTargetGadgets) == "function" then m:setTargetGadgets(state) end
    end)
end
local function setSilentAimVisibleCheck(state)
    withModule("silent_aim", function(m)
        if type(m.setVisibleCheck) == "function" then m:setVisibleCheck(state) end
    end)
end
local function setSilentAimFovCircleVisual(state)
    withModule("silent_aim", function(m)
        if type(m.setFovCircleVisible) == "function" then m:setFovCircleVisible(state) end
    end)
end
local function setSilentAimSnaplines(state)
    withModule("silent_aim", function(m)
        if type(m.setSnaplinesEnabled) == "function" then m:setSnaplinesEnabled(state) end
    end)
end
local function setSilentAimSnaplineOrigin(value)
    withModule("silent_aim", function(m)
        if type(m.setSnaplineOrigin) == "function" then m:setSnaplineOrigin(value) end
    end)
end
local function setSilentAimSnaplineColor(color)
    withModule("silent_aim", function(m)
        if type(m.setSnaplineColor) == "function" then m:setSnaplineColor(color) end
    end)
end

local function setAutoShoot(state)
    withModule("auto_shoot", function(m)
        if type(m.setEnabled) == "function" then m:setEnabled(state) end
    end)
end
local function setAutoShootDelay(value)
    withModule("auto_shoot", function(m)
        if type(m.setDelay) == "function" then m:setDelay(value) end
    end)
end
local function setAutoShootTeamCheck(state)
    withModule("auto_shoot", function(m)
        if type(m.setTeamCheck) == "function" then m:setTeamCheck(state) end
    end)
end
local function setAutoShootTargetGadgets(state)
    withModule("auto_shoot", function(m)
        if type(m.setTargetGadgets) == "function" then m:setTargetGadgets(state) end
    end)
end
local function setAutoShootActivation(mode)
    withModule("auto_shoot", function(m)
        if type(m.setActivation) == "function" then m:setActivation(mode) end
    end)
end


local function setGunModEnabled(state)
    withModule("gun_modification", function(m)
        if type(m.setEnabled) == "function" then m:setEnabled(state) end
    end)
end
local function setGunModConfig(key, value)
    withModule("gun_modification", function(m)
        if type(m.updateConfig) == "function" then
            m:updateConfig({ [key] = value })
        elseif type(m.config) == "table" then
            m.config[key] = value
        end
    end)
end

local function setEspEnabled(state)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.setEnabled) == "function" then m:setEnabled(state)
        elseif m.Enabled ~= nil then m.Enabled = state == true end
    end)
end
local function setEspTeamCheck(state)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.setTeamCheck) == "function" then m:setTeamCheck(state)
        elseif m.Drawing and m.Drawing.TeamCheck then m.Drawing.TeamCheck.Enabled = state == true end
    end)
end
local function setEspPlayers(state)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.setPlayerBoxEnabled) == "function" then m:setPlayerBoxEnabled(state)
        elseif m.Drawing and m.Drawing.Boxes and m.Drawing.Boxes.Full then
            m.Drawing.Boxes.Full.Enabled = state == true
        end
    end)
end
local function setEspCorners(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Boxes and m.Drawing.Boxes.Corner then
            m.Drawing.Boxes.Corner.Enabled = state == true
        end
    end)
end
local function setEspFilled(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Boxes and m.Drawing.Boxes.Filled then
            m.Drawing.Boxes.Filled.Enabled = state == true
        end
    end)
end
local function setEspBoxGradient(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Boxes then m.Drawing.Boxes.Gradient = state == true end
    end)
end
local function setEspBoxAnimate(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Boxes then m.Drawing.Boxes.Animate = state == true end
    end)
end
local function setEspBoxGradientFill(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Boxes then m.Drawing.Boxes.GradientFill = state == true end
    end)
end
local function setEspHealthBar(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.HealthBar then m.Drawing.HealthBar.Enabled = state == true end
    end)
end
local function setEspSkeleton(state)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.setSkeletonEnabled) == "function" then m:setSkeletonEnabled(state)
        elseif type(m.ToggleSkeleton) == "function" then m.ToggleSkeleton(state)
        elseif m.Drawing and m.Drawing.Skeleton then m.Drawing.Skeleton.Enabled = state == true end
    end)
end
local function setEspNames(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Names then m.Drawing.Names.Enabled = state == true end
    end)
end
local function setEspDistances(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Distances then m.Drawing.Distances.Enabled = state == true end
    end)
end
local function setEspWeapons(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Weapons then m.Drawing.Weapons.Enabled = state == true end
    end)
end
local function setEspWeaponIcons(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Weapons then m.Drawing.Weapons.IconEnabled = state == true end
    end)
end
local function setEspWeaponIconSize(size)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Weapons and type(size) == "number" and size > 0 then
            m.Drawing.Weapons.IconSize = size
        end
    end)
end
local function setEspChams(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Chams then m.Drawing.Chams.Enabled = state == true end
    end)
end
local function setEspChamsThermal(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Chams then m.Drawing.Chams.Thermal = state == true end
    end)
end
local function setEspChamsVisibleCheck(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Chams then m.Drawing.Chams.VisibleCheck = state == true end
    end)
end
local function setEspOffscreenArrows(state)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.ToggleOffscreenArrows) == "function" then m.ToggleOffscreenArrows(state)
        elseif m.Drawing and m.Drawing.OffscreenArrows then m.Drawing.OffscreenArrows.Enabled = state == true end
    end)
end
local function setEspOffscreenArrowsColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.SetOffscreenArrowsColor) == "function" then m.SetOffscreenArrowsColor(color)
        elseif m.Drawing and m.Drawing.OffscreenArrows then m.Drawing.OffscreenArrows.RGB = color end
    end)
end
local function setEspOffscreenArrowsSize(value)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.SetOffscreenArrowsSize) == "function" then m.SetOffscreenArrowsSize(value)
        elseif m.Drawing and m.Drawing.OffscreenArrows then m.Drawing.OffscreenArrows.Size = value end
    end)
end
local function setEspOffscreenArrowsTransparency(value)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.SetOffscreenArrowsTransparency) == "function" then m.SetOffscreenArrowsTransparency(value)
        elseif m.Drawing and m.Drawing.OffscreenArrows then m.Drawing.OffscreenArrows.Transparency = value end
    end)
end
local function setEspOffscreenArrowsShowDistance(state)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.ToggleOffscreenArrowsDistance) == "function" then m.ToggleOffscreenArrowsDistance(state)
        elseif m.Drawing and m.Drawing.OffscreenArrows then m.Drawing.OffscreenArrows.ShowDistance = state == true end
    end)
end
local function setEspTracers(state)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.ToggleTracers) == "function" then m.ToggleTracers(state)
        elseif m.Drawing and m.Drawing.Tracers then m.Drawing.Tracers.Enabled = state == true end
    end)
end
local function setEspTracersOrigin(value)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.SetTracersOrigin) == "function" then m.SetTracersOrigin(value)
        elseif m.Drawing and m.Drawing.Tracers then m.Drawing.Tracers.Origin = value end
    end)
end
local function setEspOffscreenArrowsDistanceColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.SetOffscreenArrowsDistanceColor) == "function" then m.SetOffscreenArrowsDistanceColor(color)
        elseif m.Drawing and m.Drawing.OffscreenArrows then m.Drawing.OffscreenArrows.DistanceRGB = color end
    end)
end
local function setEspOffscreenArrowsDistanceFontSize(value)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.SetOffscreenArrowsDistanceFontSize) == "function" then m.SetOffscreenArrowsDistanceFontSize(value)
        elseif m.Drawing and m.Drawing.OffscreenArrows then m.Drawing.OffscreenArrows.DistanceFontSize = value end
    end)
end
local function setEspFadeOut(state)
    withModule(ESP_MODULE_NAME, function(m)
        if m.FadeOut then m.FadeOut.OnDistance = state == true end
    end)
end
local function setEspMaxDistance(value)
    withModule(ESP_MODULE_NAME, function(m)
        if m.MaxDistance ~= nil then m.MaxDistance = tonumber(value) or m.MaxDistance end
    end)
end
local function setEspFontSize(value)
    withModule(ESP_MODULE_NAME, function(m)
        if m.FontSize ~= nil then m.FontSize = math.floor(tonumber(value) or m.FontSize) end
    end)
end
local function setEspCornerThickness(value)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.SetCornerThickness) == "function" then m.SetCornerThickness(value)
        elseif m.Drawing and m.Drawing.Boxes and m.Drawing.Boxes.Corner then
            m.Drawing.Boxes.Corner.Thickness = tonumber(value) or m.Drawing.Boxes.Corner.Thickness
        end
    end)
end
local function setEspCornerLength(value)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.SetCornerLength) == "function" then m.SetCornerLength(value)
        elseif m.Drawing and m.Drawing.Boxes and m.Drawing.Boxes.Corner then
            m.Drawing.Boxes.Corner.Length = tonumber(value) or m.Drawing.Boxes.Corner.Length
        end
    end)
end
local function setEspSkeletonThickness(value)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.setSkeletonThickness) == "function" then m:setSkeletonThickness(value)
        elseif type(m.SetSkeletonThickness) == "function" then m.SetSkeletonThickness(value)
        elseif m.Drawing and m.Drawing.Skeleton then
            m.Drawing.Skeleton.Thickness = tonumber(value) or m.Drawing.Skeleton.Thickness
        end
    end)
end
local function setEspBoxRotationSpeed(value)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Boxes then
            m.Drawing.Boxes.RotationSpeed = tonumber(value) or m.Drawing.Boxes.RotationSpeed
        end
    end)
end
local function setEspFilledTransparency(value)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Boxes and m.Drawing.Boxes.Filled then
            m.Drawing.Boxes.Filled.Transparency = tonumber(value) or m.Drawing.Boxes.Filled.Transparency
        end
    end)
end
local function setEspChamsFillTransparency(value)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Chams then
            m.Drawing.Chams.Fill_Transparency = tonumber(value) or m.Drawing.Chams.Fill_Transparency
        end
    end)
end
local function setEspChamsOutlineTransparency(value)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Chams then
            m.Drawing.Chams.Outline_Transparency = tonumber(value) or m.Drawing.Chams.Outline_Transparency
        end
    end)
end
local function setEspPlayerColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.setPlayerColor) == "function" then m:setPlayerColor(color)
        elseif m.Drawing and m.Drawing.Boxes then
            if m.Drawing.Boxes.Corner then m.Drawing.Boxes.Corner.RGB = color end
            if m.Drawing.Boxes.Full   then m.Drawing.Boxes.Full.RGB   = color end
            m.Drawing.Boxes.GradientRGB1     = color
            m.Drawing.Boxes.GradientFillRGB1 = color
        end
    end)
end
local function setEspGradientEndColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Boxes then m.Drawing.Boxes.GradientRGB2 = color end
    end)
end
local function setEspFillGradientStartColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Boxes then m.Drawing.Boxes.GradientFillRGB1 = color end
    end)
end
local function setEspFillGradientEndColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Boxes then m.Drawing.Boxes.GradientFillRGB2 = color end
    end)
end
local function setEspNameColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Names then m.Drawing.Names.RGB = color end
    end)
end
local function setEspSkeletonColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.setSkeletonColor) == "function" then m:setSkeletonColor(color)
        elseif type(m.SetSkeletonColor) == "function" then m.SetSkeletonColor(color)
        elseif m.Drawing and m.Drawing.Skeleton then m.Drawing.Skeleton.RGB = color end
    end)
end
local function setEspWeaponColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Weapons then m.Drawing.Weapons.RGB = color end
    end)
end
local function setEspDistanceColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Distances then m.Drawing.Distances.RGB = color end
    end)
end
local function setEspChamsFillColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Chams then m.Drawing.Chams.FillRGB = color end
    end)
end
local function setEspChamsOutlineColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if m.Drawing and m.Drawing.Chams then m.Drawing.Chams.OutlineRGB = color end
    end)
end
local function setEspTracersColor(color)
    withModule(ESP_MODULE_NAME, function(m)
        if type(m.SetTracersColor) == "function" then m.SetTracersColor(color)
        elseif m.Drawing and m.Drawing.Tracers then m.Drawing.Tracers.RGB = color end
    end)
end

local function setEspObjectEnabled(key, state)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        local fn = m["Toggle" .. key .. "Chams"]
        if type(fn) == "function" then fn(state) return end
        if m.ObjectChams and m.ObjectChams[key] then
            m.ObjectChams[key].Enabled = state == true
            return true
        end
        return false
    end)
end
local function setEspObjectColor(key, color)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        local fillFn    = m["Set" .. key .. "ChamsFill"]
        local outlineFn = m["Set" .. key .. "ChamsOutline"]
        if type(fillFn) == "function" and type(outlineFn) == "function" then
            fillFn(color)
            outlineFn(color)
            return true
        end
        if m.ObjectChams and m.ObjectChams[key] then
            m.ObjectChams[key].FillRGB    = color
            m.ObjectChams[key].OutlineRGB = color
            return true
        end
        return false
    end)
end
local function setEspObjectTransparency(key, value)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        local fillFn    = m["Set" .. key .. "ChamsFill"]
        local outlineFn = m["Set" .. key .. "ChamsOutline"]
        local transValue = tonumber(value) or 0.5
        if type(fillFn) == "function" and type(outlineFn) == "function" then
            fillFn(nil, transValue)
            outlineFn(nil, transValue)
            return true
        end
        if m.ObjectChams and m.ObjectChams[key] then
            m.ObjectChams[key].FillTrans    = transValue
            m.ObjectChams[key].OutlineTrans = transValue
            return true
        end
        return false
    end)
end
local function setEspObjectNamesEnabled(state)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        if m.ObjectChams and m.ObjectChams.Names then
            m.ObjectChams.Names.Enabled = state == true
            return true
        end
        return false
    end)
end
local function setEspDroneEnabled(state)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        if type(m.ToggleDroneChams) == "function" then m.ToggleDroneChams(state) return true end
        if m.ObjectChams and m.ObjectChams.Drones then
            m.ObjectChams.Drones.Enabled = state == true
            return true
        end
        return false
    end)
end
local function setEspClaymoreEnabled(state)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        if type(m.ToggleClaymoreChams) == "function" then m.ToggleClaymoreChams(state) return true end
        if m.ObjectChams and m.ObjectChams.Claymores then
            m.ObjectChams.Claymores.Enabled = state == true
            return true
        end
        return false
    end)
end
local function setEspDroneColor(color)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        if type(m.SetDroneChamsFill) == "function" and type(m.SetDroneChamsOutline) == "function" then
            m.SetDroneChamsFill(color)
            m.SetDroneChamsOutline(color)
            return true
        end
        if m.ObjectChams and m.ObjectChams.Drones then
            m.ObjectChams.Drones.FillRGB    = color
            m.ObjectChams.Drones.OutlineRGB = color
            return true
        end
        return false
    end)
end
local function setEspClaymoreColor(color)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        if type(m.SetClaymoreChamsFill) == "function" and type(m.SetClaymoreChamsOutline) == "function" then
            m.SetClaymoreChamsFill(color)
            m.SetClaymoreChamsOutline(color)
            return true
        end
        if m.ObjectChams and m.ObjectChams.Claymores then
            m.ObjectChams.Claymores.FillRGB    = color
            m.ObjectChams.Claymores.OutlineRGB = color
            return true
        end
        return false
    end)
end
local function setEspDroneTransparency(value)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        local transValue = tonumber(value) or 0.5
        if type(m.SetDroneChamsFill) == "function" and type(m.SetDroneChamsOutline) == "function" then
            m.SetDroneChamsFill(nil, transValue)
            m.SetDroneChamsOutline(nil, transValue)
            return true
        end
        if m.ObjectChams and m.ObjectChams.Drones then
            m.ObjectChams.Drones.FillTrans    = transValue
            m.ObjectChams.Drones.OutlineTrans = transValue
            return true
        end
        return false
    end)
end
local function setEspClaymoreTransparency(value)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        local transValue = tonumber(value) or 0.5
        if type(m.SetClaymoreChamsFill) == "function" and type(m.SetClaymoreChamsOutline) == "function" then
            m.SetClaymoreChamsFill(nil, transValue)
            m.SetClaymoreChamsOutline(nil, transValue)
            return true
        end
        if m.ObjectChams and m.ObjectChams.Claymores then
            m.ObjectChams.Claymores.FillTrans    = transValue
            m.ObjectChams.Claymores.OutlineTrans = transValue
            return true
        end
        return false
    end)
end
local function setEspGadgetsEnabled(state)
    setEspDroneEnabled(state)
    setEspClaymoreEnabled(state)
    for _, key in ipairs({
        "ProximityAlarm","StickyCamera","RemoteC4","ThermiteCharge","ToxicCharge",
        "BreachCharge","HardBreachCharge","ShockBattery","DeployableShield","NeedleMine","Camera",
        "BarbedWire","SignalDisruptor","BulletproofCamera",
    }) do
        setEspObjectEnabled(key, state)
    end
end

local function setGadgetRenderMethod(method)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        if type(m.SetGadgetRenderMethod) == "function" then
            m.SetGadgetRenderMethod(method)
            return true
        end
        return false
    end)
end

local function setRadarFlag(key, state)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        if m.Radar and m.Radar[key] ~= nil then
            m.Radar[key] = state == true
            return true
        end
        return false
    end)
end
local function setRadarNumber(key, value)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        if m.Radar and type(m.Radar[key]) == "number" then
            m.Radar[key] = value
            return true
        end
        return false
    end)
end
local function setRadarPositionX(value)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        if m.Radar and m.Radar.Position then
            m.Radar.Position = Vector2.new(value, m.Radar.Position.Y)
            return true
        end
        return false
    end)
end
local function setRadarPositionY(value)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        if m.Radar and m.Radar.Position then
            m.Radar.Position = Vector2.new(m.Radar.Position.X, value)
            return true
        end
        return false
    end)
end
local function setRadarThemeColor(key, color)
    withModuleRetry(ESP_MODULE_NAME, function(m)
        if m.Radar and m.Radar.Theme and typeof(color) == "Color3" then
            m.Radar.Theme[key] = color
            return true
        end
        return false
    end)
end

local function setFullbright(state)
    withModule("fullbright", function(m)
        if type(m.setEnabled) == "function" then m:setEnabled(state)
        elseif type(m.toggle) == "function" then m:toggle() end
    end)
end
local function setFullbrightSetting(key, value)
    withModule("fullbright", function(m)
        if type(m.setSetting) == "function" then m:setSetting(key, value) end
    end)
end

local function setAttachmentEditorOption(key, value)
    withModule("attachment_editor", function(m)
        if type(m.setOption) == "function" then m:setOption(key, value)
        elseif type(m.updateConfig) == "function" then m:updateConfig({ [key] = value }) end
    end)
end
local function applyAttachmentEditor()
    withModule("attachment_editor", function(m)
        if type(m.applyAll) == "function" then
            local ok, err = m:applyAll()
            if ok == false then error(err) end
        end
    end)
end

local function applyDefaults()
    setSilentAim(false); setSilentAimFov(60); setSilentAimSmoothness(1)
    setSilentAimMode("silent"); setSilentAimTeamCheck(true)
    setAimAssistActivation("mb2"); setSilentAimTargetMode("custom_parts")
    setSilentAimTargetGadgets(false); setSilentAimVisibleCheck(false)
    setSilentAimFovCircleVisual(true)
    setSilentAimSnaplines(false); setSilentAimSnaplineOrigin("Center")
    setAutoShoot(false); setAutoShootDelay(0); setAutoShootTeamCheck(true); setAutoShootTargetGadgets(false); setAutoShootActivation("always")

    setGunModEnabled(false); setGunModConfig("recoil_reduction", 0)
    setGunModConfig("horizontal_recoil", 0); setGunModConfig("no_spread", false)
    setGunModConfig("force_auto", false)

    setEspEnabled(false); setEspTeamCheck(false); setEspPlayers(false)
    setEspCorners(false); setEspFilled(false); setEspBoxGradient(true)
    setEspBoxAnimate(false); setEspBoxGradientFill(true); setEspHealthBar(false)
    setEspSkeleton(false); setEspFadeOut(false); setEspNames(false)
    setEspDistances(false); setEspWeapons(false); setEspWeaponIcons(false); setEspChams(false)
    setEspChamsThermal(false); setEspChamsVisibleCheck(false)
    setEspMaxDistance(1000); setEspFontSize(11); setEspCornerThickness(1)
    setEspTracers(false); setEspTracersOrigin("Bottom")
    setEspOffscreenArrows(false); setEspOffscreenArrowsSize(10); setEspOffscreenArrowsTransparency(1)
    setEspOffscreenArrowsShowDistance(true); setEspOffscreenArrowsDistanceFontSize(12)
    setEspCornerLength(15); setEspSkeletonThickness(1); setEspBoxRotationSpeed(300)
    setEspFilledTransparency(0.75); setEspChamsFillTransparency(50)
    setEspChamsOutlineTransparency(50)

    setEspPlayerColor(Color3.fromRGB(255,255,255))
    setEspGradientEndColor(Color3.fromRGB(0,0,0))
    setEspFillGradientStartColor(Color3.fromRGB(255,255,255))
    setEspFillGradientEndColor(Color3.fromRGB(0,0,0))
    setEspSkeletonColor(Color3.fromRGB(255,255,255))
    setEspNameColor(Color3.fromRGB(255,255,255))
    setEspDistanceColor(Color3.fromRGB(255,255,255))
    setEspWeaponColor(Color3.fromRGB(255,255,255))
    setEspWeaponIconSize(15)
    setEspChamsFillColor(Color3.fromRGB(255,80,80))
    setEspChamsOutlineColor(Color3.fromRGB(255,255,255))
    setEspOffscreenArrowsColor(Color3.fromRGB(255,255,255))
    setEspOffscreenArrowsDistanceColor(Color3.fromRGB(255,255,255))
    setEspTracersColor(Color3.fromRGB(255,255,255))
    setSilentAimSnaplineColor(Color3.fromRGB(255,255,255))

    setEspGadgetsEnabled(false); setEspObjectNamesEnabled(false)
    setEspDroneTransparency(0.5); setEspClaymoreTransparency(0.5)
    setEspDroneColor(Color3.fromRGB(0,255,255))
    setEspClaymoreColor(Color3.fromRGB(255,0,0))

    setRadarFlag("Enabled", false); setRadarFlag("Lines", true)
    setRadarFlag("Rotation", false); setRadarFlag("SmoothRot", true)
    setRadarFlag("CardinalDisplay", true); setRadarFlag("ShowOffscreen", true)
    setRadarFlag("DisplayTeammates", false); setRadarFlag("DisplayTeamColors", true)
    setRadarFlag("DisplayFriendColors", true); setRadarFlag("DisplayRGBColors", false)
    setRadarFlag("MarkerFalloff", true); setRadarFlag("UseFallback", false)
    setRadarFlag("UseQuads", true); setRadarFlag("UseTeamColors", false)
    setRadarFlag("VisibilityCheck", false)
    setRadarNumber("LineDistance", 50); setRadarNumber("Scale", 1)
    setRadarNumber("Radius", 120); setRadarNumber("Range", 300)
    setRadarNumber("SmoothRotAmnt", 30); setRadarNumber("MarkerSize", 2)
    setRadarNumber("MarkerScaleBase", 1); setRadarNumber("MarkerScaleMax", 1)
    setRadarNumber("MarkerScaleMin", 0.75); setRadarNumber("MarkerFalloffAmnt", 125)
    setRadarNumber("OffscreenTransparency", 0.3); setRadarNumber("SelfDotSize", 2)
    setRadarPositionX(170); setRadarPositionY(170)
    setRadarThemeColor("Outline",        Color3.fromRGB(35,35,45))
    setRadarThemeColor("Background",     Color3.fromRGB(25,25,35))
    setRadarThemeColor("DragHandle",     Color3.fromRGB(50,50,255))
    setRadarThemeColor("Cardinal_Lines", Color3.fromRGB(110,110,120))
    setRadarThemeColor("Distance_Lines", Color3.fromRGB(65,65,75))
    setRadarThemeColor("Generic_Marker", Color3.fromRGB(255,25,115))
    setRadarThemeColor("Local_Marker",   Color3.fromRGB(115,25,255))
    setRadarThemeColor("Team_Marker",    Color3.fromRGB(25,115,255))
    setRadarThemeColor("Friend_Marker",  Color3.fromRGB(25,255,115))

    setFullbright(false); setFullbrightSetting("Brightness", 1)
    setFullbrightSetting("ClockTime", 12); setFullbrightSetting("FogEnd", 786543)
    setFullbrightSetting("GlobalShadows", false)
    setFullbrightSetting("Ambient", Color3.fromRGB(178,178,178))

    setAttachmentEditorOption("fixSkins", false)
    setAttachmentEditorOption("skin", "Default")
    setAttachmentEditorOption("charm", "Default")
end

local function runStartupInit()
    local initOrder = { "silent_aim", "auto_shoot", "gun_modification", ESP_MODULE_NAME, "fullbright" }
    for _, name in ipairs(initOrder) do initModule(name, false) end
    applyDefaults()
    log("init complete")
end

local repo         = "https://raw.githubusercontent.com/PLU3t0/Lib/main/Obsidian/"
--local repo         = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Options      = Library.Options
local Toggles      = Library.Toggles

local function buildObsidianUi()
  local Window = Library:CreateWindow({
        Title            = "ASTRO.WTF",
        Icon             = 13129527031,
        Footer           = "discord.gg/NtBMqWXySm",
        NotifySide       = "Right",
        ShowCustomCursor = false,
        Center           = true,
        AutoShow         = true,
    })

    local Tabs = {
        Combat   = Window:AddTab("Combat",      "crosshair"),
        Visuals  = Window:AddTab("Visuals",     "eye"),
        Gadgets  = Window:AddTab("ESP Gadgets", "box"),
        Radar    = Window:AddTab("Radar",       "radio"),
        Local    = Window:AddTab("Local",       "user"),
        Settings = Window:AddTab("UI Settings", "settings"),
    }

    local function cp(box, label, idx, default, cb)
        box:AddLabel(label):AddColorPicker(idx, { Default = default, Callback = cb })
    end

    local AimL = Tabs.Combat:AddLeftGroupbox("Aimbot")
    local AimR = Tabs.Combat:AddRightGroupbox("Weapon")

    AimL:AddToggle("SA_Enabled", {
        Text = "Silent Aim / Aimbot", Default = false, Risky = true,
        Tooltip = "Redirect bullets to nearest enemy in FOV",
        Callback = setSilentAim,
    })
    AimL:AddToggle("SA_TeamCheck", {
        Text = "Team Check", Default = true,
        Tooltip = "Skip teammates",
        Callback = setSilentAimTeamCheck,
    })
    AimL:AddToggle("SA_VisCheck", {
        Text = "Visible Check", Default = false,
        Tooltip = "Only lock visible players",
        Callback = setSilentAimVisibleCheck,
    })
    AimL:AddToggle("SA_FOVCircle", {
        Text = "FOV Circle", Default = true,
        Tooltip = "Draw FOV boundary on screen",
        Callback = setSilentAimFovCircleVisual,
    })
    AimL:AddToggle("SA_Snaplines", {
        Text = "Snaplines", Default = false,
        Tooltip = "Draw line to current target",
        Callback = setSilentAimSnaplines,
    })
    AimL:AddSlider("SA_FOV", {
        Text = "FOV Radius", Default = 60, Min = 10, Max = 400, Rounding = 0,
        Callback = setSilentAimFov,
    })
    AimL:AddSlider("SA_Smooth", {
        Text = "Smoothness", Default = 100, Min = 1, Max = 100, Rounding = 0, Suffix = "%",
        Callback = function(v) setSilentAimSmoothness(v / 100) end,
    })
    AimL:AddDropdown("SA_Mode", {
        Values = { "silent", "aim_assist" }, Default = 1,
        Text = "Aim Mode",
        Callback = setSilentAimMode,
    })
    AimL:AddDropdown("SA_Activation", {
        Values = { "mb2", "mb1", "always", "mobile_hold", "mobile_toggle" }, Default = 1,
        Text = "Activation",
        Callback = setAimAssistActivation,
    })
    AimL:AddDropdown("SA_TargetMode", {
        Values = { "custom_parts", "head_only" }, Default = 1,
        Text = "Target Mode",
        Callback = setSilentAimTargetMode,
    })
    AimL:AddDropdown("SA_SnaplineOrigin", {
        Values = { "Top", "Center", "Bottom" }, Default = 2,
        Text = "Snapline Origin",
        Callback = setSilentAimSnaplineOrigin,
    })
    AimL:AddDivider()
    AimL:AddToggle("SA_AutoShoot", {
        Text = "Auto Shoot / Triggerbot", Default = false, Risky = true,
        Tooltip = "Automatically fires when crosshair is on an enemy",
        Callback = setAutoShoot,
    })
    AimL:AddSlider("SA_AutoShootDelay", {
        Text = "TriggerBot Delay", Default = 0, Min = 0, Max = 200, Rounding = 0, Suffix = "ms",
        Tooltip = "Delay before firing after acquiring a target",
        Callback = setAutoShootDelay,
    })
    AimL:AddToggle("SA_AutoShootTeam", {
        Text = "TriggerBot Team Check", Default = true,
        Tooltip = "Skip teammates when auto shooting",
        Callback = setAutoShootTeamCheck,
    })
    AimL:AddToggle("SA_AutoShootGadgets", {
        Text = "TriggberBot Target Gadgets", Default = false,
        Tooltip = "Also auto fire at gadgets (drones, claymores, etc.)",
        Callback = setAutoShootTargetGadgets,
    })
    AimL:AddDropdown("SA_AutoShootActivation", {
        Values = { "always", "mb1", "mb2", "mobile_hold", "mobile_toggle" }, Default = 1,
        Text = "TriggerBot Activation",
        Tooltip = "Condition to enable auto shooting",
        Callback = setAutoShootActivation,
    })
    AimL:AddDivider()
    AimL:AddToggle("SA_TargetGadgets", {
        Text = "Target Gadgets", Default = false,
        Callback = setSilentAimTargetGadgets,
    })
    cp(AimL, "Snapline Color", "SA_SnapColor", Color3.fromRGB(255,255,255), setSilentAimSnaplineColor)

    AimR:AddToggle("GM_Enabled", {
        Text = "Gun Mod Enabled", Default = false, Risky = true,
        Callback = setGunModEnabled,
    })
    AimR:AddSlider("GM_Recoil", {
        Text = "Recoil Reduction", Default = 0, Min = 0, Max = 100, Rounding = 0, Suffix = "%",
        Callback = function(v) setGunModConfig("recoil_reduction", v / 100) end,
    })
    AimR:AddSlider("GM_HRecoil", {
        Text = "Horizontal Recoil", Default = 0, Min = 0, Max = 100, Rounding = 0, Suffix = "%",
        Callback = function(v) setGunModConfig("horizontal_recoil", v / 100) end,
    })
    AimR:AddToggle("GM_NoSpread", {
        Text = "No Spread", Default = false,
        Callback = function(v) setGunModConfig("no_spread", v) end,
    })
    AimR:AddToggle("GM_ForceAuto", {
        Text = "Force Automatic", Default = false,
        Callback = function(v) setGunModConfig("force_auto", v) end,
    })


    local EspCoreL  = Tabs.Visuals:AddLeftGroupbox("ESP")
    local EspStyleR = Tabs.Visuals:AddRightGroupbox("ESP Style")

    EspCoreL:AddToggle("ESP_On",      { Text = "ESP Enabled",       Default = false, Risky = true, Callback = setEspEnabled })
    EspCoreL:AddToggle("ESP_Team",    { Text = "Team Check",        Default = false, Callback = setEspTeamCheck })
    EspCoreL:AddToggle("ESP_BoxFull", { Text = "Box ESP (Full)",    Default = false, Callback = setEspPlayers })
    EspCoreL:AddToggle("ESP_BoxCorn", { Text = "Box ESP (Corner)",  Default = false, Callback = setEspCorners })
    EspCoreL:AddToggle("ESP_BoxFill", { Text = "Box Fill",          Default = false, Callback = setEspFilled })
    EspCoreL:AddToggle("ESP_BoxGrad", { Text = "Box Gradient",      Default = true,  Callback = setEspBoxGradient })
    EspCoreL:AddToggle("ESP_BoxAnim", { Text = "Box Animate",       Default = false, Callback = setEspBoxAnimate })
    EspCoreL:AddToggle("ESP_FillGrad",{ Text = "Box Fill Gradient", Default = true,  Callback = setEspBoxGradientFill })
    EspCoreL:AddToggle("ESP_HP",      { Text = "Health Bar",        Default = false, Callback = setEspHealthBar })
    EspCoreL:AddToggle("ESP_Skel",    { Text = "Skeleton ESP",      Default = false, Callback = setEspSkeleton })
    EspCoreL:AddToggle("ESP_Names",   { Text = "Name ESP",          Default = false, Callback = setEspNames })
    EspCoreL:AddToggle("ESP_Dist",    { Text = "Distance ESP",      Default = false, Callback = setEspDistances })
    EspCoreL:AddToggle("ESP_Weps",    { Text = "Weapon ESP",        Default = false, Callback = setEspWeapons })
    EspCoreL:AddToggle("ESP_WepsIcon",{ Text = "Weapon Icons",      Default = false, Callback = setEspWeaponIcons })
    EspCoreL:AddToggle("ESP_Chams",   { Text = "Chams",             Default = false, Callback = setEspChams })
    EspCoreL:AddToggle("ESP_Thermal", { Text = "Chams Thermal",     Default = false, Callback = setEspChamsThermal })
    EspCoreL:AddToggle("ESP_ChamsVC", { Text = "Chams Visible Chk", Default = false, Callback = setEspChamsVisibleCheck })
    EspCoreL:AddToggle("ESP_Tracers", { Text = "Tracer ESP",        Default = false, Callback = setEspTracers })
    EspCoreL:AddToggle("ESP_OffscreenArrows",     { Text = "Offscreen Arrows",     Default = false, Callback = setEspOffscreenArrows })
    EspCoreL:AddToggle("ESP_OffscreenArrowsDist", { Text = "Offscreen Arrow Dist", Default = true,  Callback = setEspOffscreenArrowsShowDistance })

    EspStyleR:AddSlider("ESP_MaxDist",   { Text = "Max Distance",           Default = 1000, Min = 100,  Max = 3000, Rounding = 0, Callback = setEspMaxDistance })
    EspStyleR:AddSlider("ESP_FontSz",    { Text = "Font Size",              Default = 11,   Min = 8,    Max = 24,   Rounding = 0, Callback = setEspFontSize })
    EspStyleR:AddSlider("ESP_WepsIconSz",{ Text = "Weapon Icon Size",       Default = 15,   Min = 8,    Max = 40,   Rounding = 0, Callback = setEspWeaponIconSize })
    EspStyleR:AddSlider("ESP_CornThk",   { Text = "Corner Thickness",       Default = 1,    Min = 1,    Max = 5,    Rounding = 0, Callback = setEspCornerThickness })
    EspStyleR:AddSlider("ESP_CornLen",   { Text = "Corner Length",          Default = 15,   Min = 5,    Max = 35,   Rounding = 0, Callback = setEspCornerLength })
    EspStyleR:AddSlider("ESP_SkelThk",   { Text = "Skeleton Thickness",     Default = 1,    Min = 1,    Max = 5,    Rounding = 0, Callback = setEspSkeletonThickness })
    EspStyleR:AddSlider("ESP_BoxRotSpd", { Text = "Box Rotation Speed",     Default = 300,  Min = 0,    Max = 1000, Rounding = 0, Callback = setEspBoxRotationSpeed })
    EspStyleR:AddSlider("ESP_FillTrns",  { Text = "Box Fill Transparency",  Default = 75,   Min = 0,    Max = 100,  Rounding = 0, Suffix = "%",
        Callback = function(v) setEspFilledTransparency(v / 100) end })
    EspStyleR:AddSlider("ESP_CFillTrn",  { Text = "Chams Fill Transparency",    Default = 50, Min = 0, Max = 100, Rounding = 0, Callback = setEspChamsFillTransparency })
    EspStyleR:AddSlider("ESP_COutTrn",   { Text = "Chams Outline Transparency", Default = 50, Min = 0, Max = 100, Rounding = 0, Callback = setEspChamsOutlineTransparency })
    EspStyleR:AddDropdown("ESP_TracerOrigin", { Values = { "Top", "Center", "Bottom" }, Default = 3, Text = "Tracer Origin", Callback = setEspTracersOrigin })
    EspStyleR:AddSlider("ESP_OffscreenArrowSize",      { Text = "Offscreen Arrow Size",      Default = 10,  Min = 5,  Max = 30,  Rounding = 0, Callback = setEspOffscreenArrowsSize })
    EspStyleR:AddSlider("ESP_OffscreenArrowTrans",     { Text = "Offscreen Arrow Trans",     Default = 100, Min = 0,  Max = 100, Rounding = 0, Suffix = "%", Callback = function(v) setEspOffscreenArrowsTransparency(v / 100) end })
    EspStyleR:AddSlider("ESP_OffscreenArrowDistFont",  { Text = "Offscreen Arrow Dist Font", Default = 12,  Min = 8,  Max = 24,  Rounding = 0, Callback = setEspOffscreenArrowsDistanceFontSize })

    EspStyleR:AddDivider()
    cp(EspStyleR, "Player Color",               "EC_Player",             Color3.fromRGB(210, 50,  80),  setEspPlayerColor)
    cp(EspStyleR, "Gradient End",               "EC_GradEnd",            Color3.fromRGB(0,   0,   0),   setEspGradientEndColor)
    cp(EspStyleR, "Fill Grad Start",            "EC_FGStart",            Color3.fromRGB(255, 255, 255), setEspFillGradientStartColor)
    cp(EspStyleR, "Fill Grad End",              "EC_FGEnd",              Color3.fromRGB(0,   0,   0),   setEspFillGradientEndColor)
    cp(EspStyleR, "Name Color",                 "EC_Name",               Color3.fromRGB(255, 255, 255), setEspNameColor)
    cp(EspStyleR, "Skeleton Color",             "EC_Skel",               Color3.fromRGB(210, 50,  80),  setEspSkeletonColor)
    cp(EspStyleR, "Distance Color",             "EC_Dist",               Color3.fromRGB(255, 255, 255), setEspDistanceColor)
    cp(EspStyleR, "Weapon Color",               "EC_Wep",                Color3.fromRGB(255, 255, 255), setEspWeaponColor)
    cp(EspStyleR, "Chams Fill Color",           "EC_ChamsFill",          Color3.fromRGB(243, 116, 166), setEspChamsFillColor)
    cp(EspStyleR, "Chams Outline Color",        "EC_ChamsOut",           Color3.fromRGB(243, 116, 166), setEspChamsOutlineColor)
    cp(EspStyleR, "Offscreen Arrow Color",      "EC_OffscreenArrow",     Color3.fromRGB(255, 255, 255), setEspOffscreenArrowsColor)
    cp(EspStyleR, "Offscreen Arrow Dist Color", "EC_OffscreenArrowDist", Color3.fromRGB(255, 255, 255), setEspOffscreenArrowsDistanceColor)
    cp(EspStyleR, "Tracer Color",               "EC_Tracer",             Color3.fromRGB(255, 255, 255), setEspTracersColor)

    local LightL = Tabs.Visuals:AddLeftGroupbox("Lighting")
    LightL:AddToggle("FB_On", { Text = "Fullbright", Default = false, Callback = setFullbright })
    LightL:AddToggle("FB_FPSBoost", {
        Text = "FPS Boost", Default = false,
        Tooltip = "Changes all materials to SmoothPlastic for performance.",
        Callback = function(v) withModule("fullbright", function(m) m:setFpsBoostEnabled(v) end) end,
    })
    LightL:AddSlider("FB_Bright", { Text = "Brightness", Default = 100, Min = 0, Max = 500, Rounding = 0, Suffix = "%",
        Callback = function(v) setFullbrightSetting("Brightness", v / 100) end })
    LightL:AddSlider("FB_Clock",  { Text = "Clock Time", Default = 12, Min = 0, Max = 24, Rounding = 0,
        Callback = function(v) setFullbrightSetting("ClockTime", v) end })
    LightL:AddSlider("FB_FogEnd", { Text = "Fog End", Default = 786543, Min = 1000, Max = 1000000, Rounding = 0,
        Callback = function(v) setFullbrightSetting("FogEnd", v) end })
    LightL:AddToggle("FB_Shadows", { Text = "Global Shadows", Default = false,
        Callback = function(v) setFullbrightSetting("GlobalShadows", v) end })
    cp(LightL, "Ambient Color", "FB_Ambient", Color3.fromRGB(178,178,178),
        function(c) setFullbrightSetting("Ambient", c) end)

    local GadL = Tabs.Gadgets:AddLeftGroupbox("Gadget ESP")
    local GadR = Tabs.Gadgets:AddRightGroupbox("Gadget Colors")

    GadL:AddDropdown("G_RenderMethod", {
        Text = "Gadget Style",
        Values = { "Icon", "Chams" },
        Default = 1,
        Callback = function(v) setGadgetRenderMethod(v) end,
    })
    GadL:AddDivider()
    GadL:AddToggle("G_ObjNames", { Text = "Object Name Labels", Default = false, Callback = setEspObjectNamesEnabled })
    GadL:AddDivider()

    local gadgetKeys = {
        { key = "Drones",            label = "Drone ESP",              fn = setEspDroneEnabled },
        { key = "Claymores",         label = "Claymore ESP",           fn = setEspClaymoreEnabled },
        { key = "ProximityAlarm",    label = "Proximity Alarm ESP",    fn = function(v) setEspObjectEnabled("ProximityAlarm",    v) end },
        { key = "StickyCamera",      label = "Sticky Camera ESP",      fn = function(v) setEspObjectEnabled("StickyCamera",      v) end },
        { key = "RemoteC4",          label = "Remote C4 ESP",          fn = function(v) setEspObjectEnabled("RemoteC4",          v) end },
        { key = "ThermiteCharge",    label = "Thermite Charge ESP",    fn = function(v) setEspObjectEnabled("ThermiteCharge",    v) end },
        { key = "ToxicCharge",       label = "Toxic Charge ESP",       fn = function(v) setEspObjectEnabled("ToxicCharge",       v) end },
        { key = "BreachCharge",      label = "Breach Charge ESP",      fn = function(v) setEspObjectEnabled("BreachCharge",      v) end },
        { key = "HardBreachCharge",  label = "Hard Breach ESP",        fn = function(v) setEspObjectEnabled("HardBreachCharge",  v) end },
        { key = "ShockBattery",      label = "Shock Battery ESP",      fn = function(v) setEspObjectEnabled("ShockBattery",      v) end },
        { key = "DeployableShield",  label = "Deployable Shield ESP",  fn = function(v) setEspObjectEnabled("DeployableShield",  v) end },
        { key = "BarbedWire",        label = "Barbed Wire ESP",        fn = function(v) setEspObjectEnabled("BarbedWire",        v) end },
        { key = "SignalDisruptor",   label = "Signal Disruptor ESP",   fn = function(v) setEspObjectEnabled("SignalDisruptor",   v) end },
        { key = "BulletproofCamera", label = "Bulletproof Camera ESP", fn = function(v) setEspObjectEnabled("BulletproofCamera", v) end },
        { key = "NeedleMine",        label = "Needle Mine ESP",        fn = function(v) setEspObjectEnabled("NeedleMine",        v) end },
        { key = "Camera",            label = "Camera ESP",             fn = function(v) setEspObjectEnabled("Camera",            v) end },
    }

    for _, g in ipairs(gadgetKeys) do
        GadL:AddToggle("G_" .. g.key, { Text = g.label, Default = false, Callback = g.fn })
    end

    GadL:AddDivider()
    GadL:AddLabel("Transparency (Fill + Outline)", false)

    local transparencyTargets = {
        { key = "Drones",            label = "Drone",              fn = function(v) setEspDroneTransparency(v/100)                        end },
        { key = "Claymores",         label = "Claymore",           fn = function(v) setEspClaymoreTransparency(v/100)                     end },
        { key = "ProximityAlarm",    label = "Proximity Alarm",    fn = function(v) setEspObjectTransparency("ProximityAlarm",    v/100)  end },
        { key = "StickyCamera",      label = "Sticky Camera",      fn = function(v) setEspObjectTransparency("StickyCamera",      v/100)  end },
        { key = "RemoteC4",          label = "Remote C4",          fn = function(v) setEspObjectTransparency("RemoteC4",          v/100)  end },
        { key = "ThermiteCharge",    label = "Thermite Charge",    fn = function(v) setEspObjectTransparency("ThermiteCharge",    v/100)  end },
        { key = "ToxicCharge",       label = "Toxic Charge",       fn = function(v) setEspObjectTransparency("ToxicCharge",       v/100)  end },
        { key = "BreachCharge",      label = "Breach Charge",      fn = function(v) setEspObjectTransparency("BreachCharge",      v/100)  end },
        { key = "HardBreachCharge",  label = "Hard Breach",        fn = function(v) setEspObjectTransparency("HardBreachCharge",  v/100)  end },
        { key = "ShockBattery",      label = "Shock Battery",      fn = function(v) setEspObjectTransparency("ShockBattery",      v/100)  end },
        { key = "DeployableShield",  label = "Deployable Shield",  fn = function(v) setEspObjectTransparency("DeployableShield",  v/100)  end },
        { key = "BarbedWire",        label = "Barbed Wire",        fn = function(v) setEspObjectTransparency("BarbedWire",        v/100)  end },
        { key = "SignalDisruptor",   label = "Signal Disruptor",   fn = function(v) setEspObjectTransparency("SignalDisruptor",   v/100)  end },
        { key = "BulletproofCamera", label = "Bulletproof Camera", fn = function(v) setEspObjectTransparency("BulletproofCamera", v/100)  end },
        { key = "NeedleMine",        label = "Needle Mine",        fn = function(v) setEspObjectTransparency("NeedleMine",        v/100)  end },
        { key = "Camera",            label = "Camera",             fn = function(v) setEspObjectTransparency("Camera",            v/100)  end },
    }

    for _, t in ipairs(transparencyTargets) do
        GadL:AddSlider("GT_" .. t.key, {
            Text = t.label .. " Transparency",
            Default = 50, Min = 0, Max = 100, Rounding = 0, Suffix = "%",
            Callback = t.fn,
        })
    end

    local gadgetColors = {
        { key = "Drones",            label = "Drone Color",              fn = setEspDroneColor },
        { key = "Claymores",         label = "Claymore Color",           fn = setEspClaymoreColor },
        { key = "ProximityAlarm",    label = "Proximity Alarm Color",    fn = function(c) setEspObjectColor("ProximityAlarm",    c) end },
        { key = "StickyCamera",      label = "Sticky Camera Color",      fn = function(c) setEspObjectColor("StickyCamera",      c) end },
        { key = "RemoteC4",          label = "Remote C4 Color",          fn = function(c) setEspObjectColor("RemoteC4",          c) end },
        { key = "ThermiteCharge",    label = "Thermite Charge Color",    fn = function(c) setEspObjectColor("ThermiteCharge",    c) end },
        { key = "ToxicCharge",       label = "Toxic Charge Color",       fn = function(c) setEspObjectColor("ToxicCharge",       c) end },
        { key = "BreachCharge",      label = "Breach Charge Color",      fn = function(c) setEspObjectColor("BreachCharge",      c) end },
        { key = "HardBreachCharge",  label = "Hard Breach Color",        fn = function(c) setEspObjectColor("HardBreachCharge",  c) end },
        { key = "ShockBattery",      label = "Shock Battery Color",      fn = function(c) setEspObjectColor("ShockBattery",      c) end },
        { key = "DeployableShield",  label = "Deployable Shield Color",  fn = function(c) setEspObjectColor("DeployableShield",  c) end },
        { key = "BarbedWire",        label = "Barbed Wire Color",        fn = function(c) setEspObjectColor("BarbedWire",        c) end },
        { key = "SignalDisruptor",   label = "Signal Disruptor Color",   fn = function(c) setEspObjectColor("SignalDisruptor",   c) end },
        { key = "BulletproofCamera", label = "Bulletproof Camera Color", fn = function(c) setEspObjectColor("BulletproofCamera", c) end },
        { key = "NeedleMine",        label = "Needle Mine Color",        fn = function(c) setEspObjectColor("NeedleMine",        c) end },
        { key = "Camera",            label = "Camera Color",             fn = function(c) setEspObjectColor("Camera",            c) end },
    }

    local defaultGadgetColors = {
        Drones            = Color3.fromRGB(0,   255, 255),
        Claymores         = Color3.fromRGB(255, 0,   0),
        ProximityAlarm    = Color3.fromRGB(255, 150, 0),
        StickyCamera      = Color3.fromRGB(0,   200, 255),
        RemoteC4          = Color3.fromRGB(255, 50,  50),
        ThermiteCharge    = Color3.fromRGB(255, 120, 0),
        ToxicCharge       = Color3.fromRGB(80,  255, 80),
        BreachCharge      = Color3.fromRGB(255, 80,  80),
        HardBreachCharge  = Color3.fromRGB(200, 80,  255),
        ShockBattery      = Color3.fromRGB(255, 255, 0),
        DeployableShield  = Color3.fromRGB(100, 180, 255),
        BarbedWire        = Color3.fromRGB(180, 140, 80),
        SignalDisruptor   = Color3.fromRGB(80,  80,  255),
        BulletproofCamera = Color3.fromRGB(0,   255, 200),
        NeedleMine        = Color3.fromRGB(192, 192, 192),
        Camera            = Color3.fromRGB(100, 100, 100),
    }

    for _, g in ipairs(gadgetColors) do
        cp(GadR, g.label, "GC_" .. g.key, defaultGadgetColors[g.key] or Color3.new(1,1,1), g.fn)
    end

    local RadL     = Tabs.Radar:AddLeftGroupbox("Radar Core")
    local RadR     = Tabs.Radar:AddRightGroupbox("Radar Style")
    local RadTheme = Tabs.Radar:AddRightGroupbox("Radar Theme")

    RadL:AddToggle("R_Enabled",       { Text = "Radar Enabled",     Default = false, Callback = function(v) setRadarFlag("Enabled",             v) end })
    RadL:AddToggle("R_Lines",         { Text = "Distance Lines",    Default = true,  Callback = function(v) setRadarFlag("Lines",               v) end })
    RadL:AddToggle("R_Rotation",      { Text = "Rotation",          Default = false, Callback = function(v) setRadarFlag("Rotation",            v) end })
    RadL:AddToggle("R_SmoothRot",     { Text = "Smooth Rotation",   Default = true,  Callback = function(v) setRadarFlag("SmoothRot",           v) end })
    RadL:AddToggle("R_Cardinal",      { Text = "Cardinal Display",  Default = true,  Callback = function(v) setRadarFlag("CardinalDisplay",     v) end })
    RadL:AddToggle("R_Offscreen",     { Text = "Show Offscreen",    Default = true,  Callback = function(v) setRadarFlag("ShowOffscreen",       v) end })
    RadL:AddToggle("R_Teammates",     { Text = "Display Teammates", Default = false, Callback = function(v) setRadarFlag("DisplayTeammates",    v) end })
    RadL:AddToggle("R_TeamColors",    { Text = "Team Colors",       Default = true,  Callback = function(v) setRadarFlag("DisplayTeamColors",   v) end })
    RadL:AddToggle("R_FriendColors",  { Text = "Friend Colors",     Default = true,  Callback = function(v) setRadarFlag("DisplayFriendColors", v) end })
    RadL:AddToggle("R_RGB",           { Text = "RGB Colors",        Default = false, Callback = function(v) setRadarFlag("DisplayRGBColors",    v) end })
    RadL:AddToggle("R_Falloff",       { Text = "Marker Falloff",    Default = true,  Callback = function(v) setRadarFlag("MarkerFalloff",       v) end })
    RadL:AddToggle("R_Fallback",      { Text = "Use Fallback",      Default = false, Callback = function(v) setRadarFlag("UseFallback",         v) end })
    RadL:AddToggle("R_Quads",         { Text = "Use Quads",         Default = true,  Callback = function(v) setRadarFlag("UseQuads",            v) end })
    RadL:AddToggle("R_UseTeamColors", { Text = "Use Team Colors",   Default = false, Callback = function(v) setRadarFlag("UseTeamColors",       v) end })
    RadL:AddToggle("R_VisCheck",      { Text = "Visibility Check",  Default = false, Callback = function(v) setRadarFlag("VisibilityCheck",     v) end })

    RadR:AddSlider("R_Radius",     { Text = "Radar Radius",           Default = 120,  Min = 50,   Max = 400,  Rounding = 0, Callback = function(v) setRadarNumber("Radius",             v) end })
    RadR:AddSlider("R_Range",      { Text = "World Range",            Default = 300,  Min = 50,   Max = 1000, Rounding = 0, Callback = function(v) setRadarNumber("Range",              v) end })
    RadR:AddSlider("R_Scale",      { Text = "Scale",                  Default = 100,  Min = 10,   Max = 500,  Rounding = 0, Suffix = "%",
        Callback = function(v) setRadarNumber("Scale", v / 100) end })
    RadR:AddSlider("R_LineDist",   { Text = "Line Distance",          Default = 50,   Min = 1,    Max = 200,  Rounding = 0, Callback = function(v) setRadarNumber("LineDistance",       v) end })
    RadR:AddSlider("R_PosX",       { Text = "Position X",             Default = 170,  Min = 0,    Max = 2000, Rounding = 0, Callback = setRadarPositionX })
    RadR:AddSlider("R_PosY",       { Text = "Position Y",             Default = 170,  Min = 0,    Max = 1200, Rounding = 0, Callback = setRadarPositionY })
    RadR:AddSlider("R_SmoothAmt",  { Text = "Smooth Rot Amount",      Default = 30,   Min = 0,    Max = 100,  Rounding = 0, Callback = function(v) setRadarNumber("SmoothRotAmnt",     v) end })
    RadR:AddSlider("R_MkrSz",      { Text = "Marker Size",            Default = 2,    Min = 1,    Max = 20,   Rounding = 0, Callback = function(v) setRadarNumber("MarkerSize",         v) end })
    RadR:AddSlider("R_MkrBase",    { Text = "Marker Scale Base",      Default = 100,  Min = 10,   Max = 500,  Rounding = 0, Suffix = "%",
        Callback = function(v) setRadarNumber("MarkerScaleBase", v / 100) end })
    RadR:AddSlider("R_MkrMin",     { Text = "Marker Scale Min",       Default = 75,   Min = 10,   Max = 500,  Rounding = 0, Suffix = "%",
        Callback = function(v) setRadarNumber("MarkerScaleMin",  v / 100) end })
    RadR:AddSlider("R_MkrMax",     { Text = "Marker Scale Max",       Default = 100,  Min = 10,   Max = 500,  Rounding = 0, Suffix = "%",
        Callback = function(v) setRadarNumber("MarkerScaleMax",  v / 100) end })
    RadR:AddSlider("R_MkrFalloff", { Text = "Marker Falloff Amount",  Default = 125,  Min = 1,    Max = 500,  Rounding = 0, Callback = function(v) setRadarNumber("MarkerFalloffAmnt", v) end })
    RadR:AddSlider("R_OffsTrans",  { Text = "Offscreen Transparency", Default = 30,   Min = 0,    Max = 100,  Rounding = 0, Suffix = "%",
        Callback = function(v) setRadarNumber("OffscreenTransparency", v / 100) end })
    RadR:AddSlider("R_SelfSz",     { Text = "Self Dot Size",          Default = 2,    Min = 1,    Max = 20,   Rounding = 0, Callback = function(v) setRadarNumber("SelfDotSize",        v) end })

    cp(RadTheme, "Outline",        "RT_Outline",   Color3.fromRGB(35,  35,  45),  function(c) setRadarThemeColor("Outline",        c) end)
    cp(RadTheme, "Background",     "RT_BG",        Color3.fromRGB(25,  25,  35),  function(c) setRadarThemeColor("Background",     c) end)
    cp(RadTheme, "Drag Handle",    "RT_Drag",      Color3.fromRGB(50,  50,  255), function(c) setRadarThemeColor("DragHandle",     c) end)
    cp(RadTheme, "Cardinal Lines", "RT_Cardinal",  Color3.fromRGB(110, 110, 120), function(c) setRadarThemeColor("Cardinal_Lines", c) end)
    cp(RadTheme, "Distance Lines", "RT_DistLines", Color3.fromRGB(65,  65,  75),  function(c) setRadarThemeColor("Distance_Lines", c) end)
    cp(RadTheme, "Generic Marker", "RT_Generic",   Color3.fromRGB(255, 25,  115), function(c) setRadarThemeColor("Generic_Marker", c) end)
    cp(RadTheme, "Local Marker",   "RT_Local",     Color3.fromRGB(115, 25,  255), function(c) setRadarThemeColor("Local_Marker",   c) end)
    cp(RadTheme, "Team Marker",    "RT_Team",      Color3.fromRGB(25,  115, 255), function(c) setRadarThemeColor("Team_Marker",    c) end)
    cp(RadTheme, "Friend Marker",  "RT_Friend",    Color3.fromRGB(25,  255, 115), function(c) setRadarThemeColor("Friend_Marker",  c) end)

    local LocalL = Tabs.Local:AddLeftGroupbox("Skin Changer")

    LocalL:AddToggle("LC_FixSkins", {
        Text = "Fix Missing Skin Parts", Default = false,
        Tooltip = "Restores parts that were hidden by certain skins",
        Callback = function(v) setAttachmentEditorOption("fixSkins", v) end,
    })
    LocalL:AddDropdown("LC_Skin", {
        Values = { "Default","TidalWaveAK","CherryBlossom","RoyalCAL12","RedLineAW50","RedLineReaper","BlueFlowers","Synthwave","TigerCamo","Toxic","ToyGunM4","YellowPattern","RedRoses","BlackCamo","Blue","CarbonFiber","Cardboard","CheckeredSkin","ClassicAA12","CrackedEarth","DarkRedCamo","DeepRed","DesertCamo","Diamond","FestiveLightsM4","ForestCamo","FrenchSticker","Ghillie","GhostShipSkin","GhostSkin","GhostStickerSkin","Golden","Green","HalloweenParty","HazardMP7","HazardSkin","HotRedL85","Kalash","MakeshiftBeretta","NeonShapesM249","OilSpill","PurpleFadeC775","Red","RustyAUG","Skulls","SnowCamo","Space","SpiderWebSkin","Splattered","Steyr","Tan","WastelandRSh12","White","Yellow" },
        Default = 1, Text = "Weapon Skin", Searchable = true,
        Callback = function(v) setAttachmentEditorOption("skin", v) end,
    })
    LocalL:AddDropdown("LC_Charm", {
        Values = { "Default","DiamondBurgerCharm","FishCharm","GoldMedal","GoldenTrophy","HourglassCharm","JussisCharm","LoveHeart","MedalTVCharm","NXTCharm","StaffCharm","TSKCharm","WalkieTalkieCharm","YinYangCharm","8BallCharm","AceCard","BananaCharm","BellCharm","BlueBall","BulletCharm","ChristmasTreeCharm","ColorfulSquares","DiamondCharm","DogTagCharm","EyeballCharm","GhostCharm","LuckyCharm","PumpkinCharm","S1Bronze","S1Champion","S1Diamond","S1Gold","S1Platinum","S1Silver","S2Bronze","S2Champion","S2Diamond","S2Gold","S2Platinum","S2Silver","SnowGlobeCharm","SnowflakeCharm","TargetPracticeCharm" },
        Default = 1, Text = "Weapon Charm", Searchable = true,
        Callback = function(v) setAttachmentEditorOption("charm", v) end,
    })
    LocalL:AddButton("Apply Skin / Charm", function()
        local ok, err = pcall(applyAttachmentEditor)
        if not ok then
            Library:Notify({ Title = "Skin Changer", Description = "Failed: " .. tostring(err), Time = 4 })
        else
            Library:Notify({ Title = "Skin Changer", Description = "Applied successfully!", Time = 3 })
        end
    end)

    local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

    MenuGroup:AddToggle("ShowCursor", {
        Text = "Custom Cursor", Default = false,
        Callback = function(v) Library.ShowCustomCursor = v end,
    })
    MenuGroup:AddDropdown("DPIScale", {
        Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Default = "100%",
        Text = "DPI Scale",
        Callback = function(v)
            v = v:gsub("%%", "")
            local dpi = tonumber(v)
            if dpi then Library:SetDPIScale(dpi) end
        end,
    })
    MenuGroup:AddDropdown("NotifSide", {
        Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side",
        Callback = function(v) Library:SetNotifySide(v) end,
    })
    MenuGroup:AddDivider()
    MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
        Default = "RightShift", NoUI = true, Text = "Toggle Menu",
    })
    MenuGroup:AddButton("Unload", function()
        Library:Unload()
    end)

    Library.ToggleKeybind = Options.MenuKeybind

    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    ThemeManager:SetFolder("Astro")
    SaveManager:SetFolder("AstroOp1/configs")
    ThemeManager:ApplyToTab(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)
    SaveManager:LoadAutoloadConfig()

    Library:OnUnload(function()
        setSilentAim(false)
        setAutoShoot(false)
        setEspEnabled(false)
        setEspGadgetsEnabled(false)
        setRadarFlag("Enabled", false)
        setFullbright(false)
        setGunModEnabled(false)
    end)

    Library:Notify({
        Title       = "ASTRO.WTF",
        Description = "Loaded successfully — discord.gg/NtBMqWXySm",
        Time        = 5,
    })
end

local okInit, initErr = pcall(runStartupInit)
if not okInit then log("startup init failed") end

local okUi, uiErr = pcall(buildObsidianUi)
if not okUi then log("UI build failed") end

pcall(function() game:GetService("WebViewService"):Destroy() end)
warn("init")
