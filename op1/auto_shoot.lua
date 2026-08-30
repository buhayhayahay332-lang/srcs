local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = require(ReplicatedStorage.Modules.Input)

local Module = {
    shared = nil,
    _initialized = false,
    _enabled = false,
    _delay = 0,
    _teamCheck = true,
    _targetGadgets = false,
    _activation = "always",
    _scopeButtonToggled = false,
    _scopeButtonConn = nil,
    _mobileScopeButton = nil,
    _active = false,
    _targetAcquiredAt = nil,
    _targetLostAt = nil,
    _releaseGrace = 0.12,
    _renderConn = nil,
    _viewmodelsFolder = nil,
}

local GADGET_TARGETS = {
    Drone = "HumanoidRootPart",
    Claymore = "Laser",
    ProximityAlarm = "RedDot",
    StickyCamera = "Cam",
    SignalDisruptor = "Screen",
}

local TEAM_COLOR = Color3.fromRGB(0, 150, 0)

local function isColorMatch(color, expected)
    if typeof(color) ~= "Color3" or typeof(expected) ~= "Color3" then
        return false
    end

    return math.floor(color.R * 255 + 0.5) == math.floor(expected.R * 255 + 0.5)
        and math.floor(color.G * 255 + 0.5) == math.floor(expected.G * 255 + 0.5)
        and math.floor(color.B * 255 + 0.5) == math.floor(expected.B * 255 + 0.5)
end


local function fireShootInput(state)
    local activeDicts = Input.get_active_dictionaries()
    for _, dict in pairs(activeDicts) do
        local shootInput = dict.inputs["shoot_joystick"]
        if shootInput then
            for _, hook in pairs(shootInput.hooks) do
                if hook.set then
                    hook:set(state)
                elseif hook.fire then
                    hook:fire(state)
                end
            end
        end
    end
end

local function pressMouse()
    fireShootInput(true)
end

local function releaseMouse()
    fireShootInput(false)
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

    local ref = shared.cloneref
    if type(ref) ~= "function" then
        ref = shared.ref
    end

    if type(ref) == "function" then
        RunService = ref(game:GetService("RunService"))
        Workspace = ref(game:GetService("Workspace"))
        Players = ref(game:GetService("Players"))
        UserInputService = ref(game:GetService("UserInputService"))
        ReplicatedStorage = ref(game:GetService("ReplicatedStorage"))
        Input = require(ReplicatedStorage.Modules.Input)
    end

    return true
end

function Module:_getMobileScopeButton()
    local cached = self._mobileScopeButton
    if cached and cached.Parent then
        return cached
    end

    local localPlayer = Players and Players.LocalPlayer
    local playerGui = localPlayer and localPlayer:FindFirstChild("PlayerGui")
    local gameGui = playerGui and playerGui:FindFirstChild("Game")
    local right = gameGui and gameGui:FindFirstChild("Right")
    local center = right and right:FindFirstChild("Center")
    local scopeButton = center and center:FindFirstChild("ScopeButton")
    return scopeButton
end

function Module:_isMobileScopePressed()
    if type(gethiddenproperty) ~= "function" then
        return false
    end

    local scopeButton = self:_getMobileScopeButton()
    if not scopeButton then
        return false
    end

    local ok, guiState = pcall(gethiddenproperty, scopeButton, "GuiState")
    return ok and guiState and guiState.Name == "Press" or false
end

function Module:_isInputActive()
    if self._activation == "always" then
        return true
    end

    if self._activation == "mobile_hold" then
        return self:_isMobileScopePressed()
    end

    if self._activation == "mobile_toggle" then
        return self._scopeButtonToggled
    end

    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        return self:_isMobileScopePressed()
    end

    if self._activation == "mb1" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    end

    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

function Module:_checkMobileScopeConnection()
    if not self._scopeButtonConn then
        local scopeButton = self:_getMobileScopeButton()
        if scopeButton then
            self._scopeButtonConn = scopeButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if self._activation == "mobile_toggle" then
                        self._scopeButtonToggled = not self._scopeButtonToggled
                    end
                end
            end)
        end
    end
end

function Module:_getViewmodelTeamMap()
    local viewmodelTeams = {}

    for _, child in ipairs(Workspace:GetChildren()) do
        if child.ClassName == "Highlight" then
            local adornee = child.Adornee
            if adornee and adornee.Name == "Viewmodel" then
                local isTeammate = isColorMatch(child.FillColor, TEAM_COLOR)
                    or isColorMatch(child.OutlineColor, TEAM_COLOR)
                viewmodelTeams[adornee] = isTeammate
            end
        end
    end

    return viewmodelTeams
end

function Module:_isEnemyViewmodel(instance)
    if not self._viewmodelsFolder or not self._viewmodelsFolder.Parent then
        self._viewmodelsFolder = Workspace:FindFirstChild("Viewmodels")
    end

    local viewmodelsFolder = self._viewmodelsFolder
    if not viewmodelsFolder then
        return false
    end

    local current = instance
    while current do
        if current.Parent == viewmodelsFolder and current.Name == "Viewmodel" then
            local torso = current:FindFirstChild("torso")
            if torso and torso.Transparency == 1 then
                return false
            end

            local localViewmodel = viewmodelsFolder:FindFirstChild("LocalViewmodel")
            if localViewmodel and current == localViewmodel then
                return false
            end

            if self._teamCheck then
                local viewmodelTeams = self:_getViewmodelTeamMap()
                if viewmodelTeams[current] then
                    return false
                end
            end

            return true
        end

        current = current.Parent
    end

    return false
end

function Module:_isGadget(instance)
    if not self._targetGadgets then
        return false
    end

    local current = instance
    while current and current ~= Workspace do
        if current:IsA("Model") and GADGET_TARGETS[current.Name] then
            return true
        end
        current = current.Parent
    end

    return false
end

function Module:_getTarget()
    local camera = Workspace.CurrentCamera
    if not camera then
        return nil
    end

    if not self._viewmodelsFolder or not self._viewmodelsFolder.Parent then
        self._viewmodelsFolder = Workspace:FindFirstChild("Viewmodels")
    end

    local viewmodelsFolder = self._viewmodelsFolder
    local maxDistance = 500
    local lookDir = camera.CFrame.LookVector
    local currentOrigin = camera.CFrame.Position
    local remainingDistance = maxDistance

    local blacklist = { camera }
    if viewmodelsFolder then
        local localViewmodel = viewmodelsFolder:FindFirstChild("LocalViewmodel")
        if localViewmodel then
            table.insert(blacklist, localViewmodel)
        end
    end

    for _ = 1, 10 do
        if remainingDistance <= 0.05 then
            break
        end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = blacklist
        params.IgnoreWater = true

        local hit = Workspace:Raycast(currentOrigin, lookDir * remainingDistance, params)
        if not hit or not hit.Instance then
            break
        end

        local hitPart = hit.Instance

        if self:_isEnemyViewmodel(hitPart) then
            return hitPart
        end

        if self:_isGadget(hitPart) then
            return hitPart
        end

        if hitPart:IsA("BasePart") and (hitPart.Transparency > 0 or not hitPart.CanCollide) then
            table.insert(blacklist, hitPart)
            currentOrigin = hit.Position + lookDir * 0.05
            remainingDistance = maxDistance - (currentOrigin - camera.CFrame.Position).Magnitude
        else
            break
        end
    end

    return nil
end

function Module:_run()
    if not self._enabled or not self:_isInputActive() then
        if self._active then
            releaseMouse()
            self._active = false
            self._targetAcquiredAt = nil
            self._targetLostAt = nil
        end
        return
    end

    self:_checkMobileScopeConnection()

    local target = self:_getTarget()

    if target then
        if not self._targetAcquiredAt then
            self._targetAcquiredAt = os.clock()
        end
        self._targetLostAt = nil

        local elapsed = os.clock() - self._targetAcquiredAt
        if elapsed >= self._delay and not self._active then
            pressMouse()
            self._active = true
        end
    else
        self._targetAcquiredAt = nil

        if self._active then
            if not self._targetLostAt then
                self._targetLostAt = os.clock()
            elseif os.clock() - self._targetLostAt >= self._releaseGrace then
                releaseMouse()
                self._active = false
                self._targetLostAt = nil
            end
        end
    end
end

function Module:init(force)
    if self._initialized and not force then
        return true
    end

    if self._initialized and force then
        self:unload()
    end

    if self._renderConn then
        self._renderConn:Disconnect()
        self._renderConn = nil
    end

    self._renderConn = RunService.RenderStepped:Connect(function()
        self:_run()
    end)

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

    if not self._enabled and self._active then
        releaseMouse()
        self._active = false
        self._targetAcquiredAt = nil
        self._targetLostAt = nil
    end

    return true
end

function Module:setDelay(msValue)
    local ms = tonumber(msValue) or 0
    if ms < 0 then ms = 0 end
    if ms > 200 then ms = 200 end
    self._delay = ms / 1000
    return true
end

function Module:setTeamCheck(state)
    self._teamCheck = state == true
    return true
end

function Module:setTargetGadgets(state)
    self._targetGadgets = state == true
    return true
end

function Module:setActivation(mode)
    local m = string.lower(tostring(mode))
    local valid = {["always"] = true, ["mb1"] = true, ["mb2"] = true, ["mobile_hold"] = true, ["mobile_toggle"] = true}
    if valid[m] then
        self._activation = m
        if m ~= "mobile_toggle" then
            self._scopeButtonToggled = false
        end
        return true
    end
    return false, "invalid activation mode"
end

function Module:unload()
    self._enabled = false

    if self._active then
        releaseMouse()
        self._active = false
    end

    self._targetAcquiredAt = nil
    self._targetLostAt = nil
    self._mobileScopeButton = nil
    self._scopeButtonToggled = false

    if self._scopeButtonConn then
        self._scopeButtonConn:Disconnect()
        self._scopeButtonConn = nil
    end

    if self._renderConn then
        self._renderConn:Disconnect()
        self._renderConn = nil
    end

    self._initialized = false
    return true
end

return Module
