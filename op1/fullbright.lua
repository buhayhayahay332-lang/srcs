local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Module = {
    shared = nil,
    _initialized = false,
    _enabled = false,
    _fpsBoostEnabled = false,
    _connections = {},
    _normal = nil,
    _originalMaterials = {},
    _fullbright = {
        Brightness = 1,
        ClockTime = 12,
        FogEnd = 786543,
        GlobalShadows = false,
        Ambient = Color3.fromRGB(178, 178, 178),
    },
}

function Module:setShared(shared)
    if type(shared) ~= "table" then
        return false, "shared must be table"
    end

    self.shared = shared

    local ref = shared.cloneref
    if type(ref) ~= "function" then
        ref = shared.ref
    end
    if type(ref) == "function" then
        Lighting = ref(game:GetService("Lighting"))
        Workspace = ref(game:GetService("Workspace"))
    end

    return true
end

local function disconnectAll(connections)
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
end

function Module:_captureNormal()
    self._normal = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient,
    }
end

function Module:_apply(settings)
    for property, value in pairs(settings) do
        Lighting[property] = value
    end
end

function Module:_bindMonitors()
    disconnectAll(self._connections)
    for property in pairs(self._fullbright) do
        local conn = Lighting:GetPropertyChangedSignal(property):Connect(function()
            local current = Lighting[property]
            if self._enabled then
                local targetValue = self._fullbright[property]
                if current ~= targetValue then
                    Lighting[property] = targetValue
                end
                return
            end

            if self._normal and current ~= self._normal[property] then
                self._normal[property] = current
            end
        end)
        table.insert(self._connections, conn)
    end
end

function Module:init(force)
    if self._initialized and not force then
        return true
    end

    setmetatable(self._originalMaterials, { __mode = "k" })
    self:_captureNormal()
    self:_bindMonitors()
    self._initialized = true
    return true
end

function Module:load(force)
    return self:init(force)
end

function Module:isLoaded()
    return self._initialized
end

function Module:isEnabled()
    return self._enabled == true
end

function Module:setEnabled(state)
    local okInit, initErr = self:init(false)
    if not okInit then
        return false, initErr
    end

    self._enabled = state == true
    if self._enabled then
        self:_apply(self._fullbright)
    else
        self:_apply(self._normal)
    end
    return true
end

function Module:toggle()
    return self:setEnabled(not self._enabled)
end

function Module:setSetting(property, value)
    local okInit, initErr = self:init(false)
    if not okInit then
        return false, initErr
    end

    if self._fullbright[property] == nil then
        return false, "unknown fullbright setting: " .. tostring(property)
    end

    self._fullbright[property] = value
    if self._enabled then
        Lighting[property] = value
    end
    return true
end

function Module:getSettings()
    return self._fullbright
end

function Module:_applyFpsBoost(enable)
    if enable then
        local function isLocalViewmodelPart(part)
            local viewmodels = Workspace:FindFirstChild("Viewmodels")
            local localViewmodel = viewmodels and viewmodels:FindFirstChild("LocalViewmodel")
            return localViewmodel
                and (part == localViewmodel or part:IsDescendantOf(localViewmodel))
        end

        local function applyToPart(part)
            if part:IsA("BasePart") and not isLocalViewmodelPart(part) then
                if not self._originalMaterials[part] then
                    self._originalMaterials[part] = part.Material
                end
                part.Material = Enum.Material.SmoothPlastic
            end
        end

        for _, part in ipairs(Workspace:GetDescendants()) do
            applyToPart(part)
        end

        local conn = Workspace.DescendantAdded:Connect(applyToPart)
        table.insert(self._connections, conn)
    else
        for part, material in pairs(self._originalMaterials) do
            if part and part.Parent then
                part.Material = material
            end
        end
        self._originalMaterials = {}
        setmetatable(self._originalMaterials, { __mode = "k" })
        self:_bindMonitors()
    end
end

function Module:setFpsBoostEnabled(state)
    local okInit, initErr = self:init(false)
    if not okInit then return false, initErr end

    self._fpsBoostEnabled = state == true
    self:_applyFpsBoost(self._fpsBoostEnabled)
    return true
end

function Module:destroy()
    self:setEnabled(false)
    self:setFpsBoostEnabled(false)
    disconnectAll(self._connections)
    self._initialized = false
end

return Module
