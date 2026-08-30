local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Module = {
    shared = nil,
    _initialized = false,
    _tombradyEnabled = false,
    _hk69Enabled = false,
    _homingSpeed = 60,
    _smoothness = 1,
    _explosionRadius = 5,
    _delayTime = 0.5,
    _descendantAddedConn = nil,
    _fastTouchedHooked = false,
}

local THROWABLE_NAMES = {
    "FragGrenade", "Flashbang", "SmokeGrenade", "StickyCamera",
    "ProximityAlarm", "Grenade", "Projectile", "IncendiaryGrenade",
    "RemoteC4", "ImpactGrenade"
}

function Module:setShared(shared)
    self.shared = shared
    return true
end

function Module:_getMainPart(model)
    local root = model:FindFirstChild("Root")
    if root then return root end
    root = model:FindFirstChild("HumanoidRootPart")
    if root then return root end
    if model.PrimaryPart then return model.PrimaryPart end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then return child end
    end
    return nil
end

function Module:_applyHoming(throwableModel)
    if throwableModel:GetAttribute("HomingApplied") then return end

    local silent_aim = self.shared and self.shared.modules and self.shared.modules.silent_aim
    if not silent_aim then return end

    local target = silent_aim:_getClosestTargetToCursor()
    if not target or not target.Parent then
        -- No target found: revert to original behavior
        throwableModel:SetAttribute("HomingApplied", true)
        throwableModel:SetAttribute("UseOriginalCallback", true)
        return
    end

    local root = self:_getMainPart(throwableModel)
    if not root then return end

    throwableModel:SetAttribute("HomingApplied", true)
    root.CanCollide = false

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not root.Parent or not target.Parent then
            connection:Disconnect()
            return
        end

        local distance = (root.Position - target.Position).Magnitude

        if distance < self._explosionRadius then
            if not throwableModel:GetAttribute("EnteredRadiusTime") then
                throwableModel:SetAttribute("EnteredRadiusTime", os.clock())
            end
            local startTime = throwableModel:GetAttribute("EnteredRadiusTime")
            if os.clock() - startTime >= self._delayTime then
                if not throwableModel:GetAttribute("UseOriginalCallback") then
                    throwableModel:SetAttribute("UseOriginalCallback", true)
                    root.CanCollide = true
                end
            else
                if throwableModel:GetAttribute("UseOriginalCallback") then
                    throwableModel:SetAttribute("UseOriginalCallback", false)
                    root.CanCollide = false
                end
            end
        else
            throwableModel:SetAttribute("EnteredRadiusTime", nil)
            if throwableModel:GetAttribute("UseOriginalCallback") then
                throwableModel:SetAttribute("UseOriginalCallback", false)
                root.CanCollide = false
            end
        end

        local direction = (target.Position - root.Position).Unit
        local targetVel = direction * self._homingSpeed
        root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(targetVel, self._smoothness)
    end)

    root.AncestryChanged:Connect(function()
        if not root.Parent then connection:Disconnect() end
    end)
end

function Module:_setupFastTouched()
    if self._fastTouchedHooked then return end

    local clonefn = clonefunction or function(fn) return fn end
    local closure = newcclosure or function(fn) return fn end

    local ok, HitDetection = pcall(function()
        return require(ReplicatedStorage.Modules.HitDetection)
    end)

    if ok and HitDetection then
        local oldFastTouched = clonefn(HitDetection.FastTouched)
        HitDetection.FastTouched = closure(function(part, original_callback, ...)
            if part and part.Parent and part.Parent:GetAttribute("HomingAttached") then
                local wrapper_callback = function(hitResult)
                    local useOriginal = part.Parent:GetAttribute("UseOriginalCallback")
                    if useOriginal then
                        return original_callback(hitResult)
                    else
                        return false
                    end
                end
                return oldFastTouched(part, wrapper_callback, ...)
            else
                return oldFastTouched(part, original_callback, ...)
            end
        end)
        self._fastTouchedHooked = true
    else
        warn("Homing shit")
    end
end

function Module:init(force)
    if self._initialized and not force then
        return true
    end

    self:_setupFastTouched()

    if self._descendantAddedConn then
        self._descendantAddedConn:Disconnect()
        self._descendantAddedConn = nil
    end

    self._descendantAddedConn = Workspace.DescendantAdded:Connect(function(descendant)
        if not descendant:IsA("Model") then return end

        local name = descendant.Name
        local isNormal = false
        for _, tName in ipairs(THROWABLE_NAMES) do
            if name == tName then
                isNormal = true
                break
            end
        end

        local isHK69 = (name == "HK69")

        if isNormal and self._tombradyEnabled then
            descendant:SetAttribute("HomingAttached", true)
            task.wait(0.05)
            self:_applyHoming(descendant)
        elseif isHK69 and self._hk69Enabled then
            descendant:SetAttribute("HomingAttached", true)
            task.wait(0.05)
            self:_applyHoming(descendant)
        end
    end)

    self._initialized = true
    return true
end

function Module:load(force)
    return self:init(force)
end

function Module:setTombradyEnabled(state)
    self._tombradyEnabled = state == true
    return true
end

function Module:setHk69Enabled(state)
    self._hk69Enabled = state == true
    return true
end

function Module:setHomingSpeed(value)
    self._homingSpeed = tonumber(value) or 60
    return true
end

function Module:setHomingSmoothness(value)
    self._smoothness = tonumber(value) or 1
    return true
end

function Module:unload()
    if self._descendantAddedConn then
        self._descendantAddedConn:Disconnect()
        self._descendantAddedConn = nil
    end
    self._initialized = false
    return true
end

return Module
