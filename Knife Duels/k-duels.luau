if not game:IsLoaded() then game.Loaded:Wait() end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")

local cloneref      = cloneref      or function(o) return o end
local clonefunction = clonefunction or function(f) return f end

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local repo         = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Options  = Library.Options
local Toggles  = Library.Toggles

local Settings = {
    AimAssist = {
        Enabled         = false,
        FOVRadius       = 150,
        Smoothness      = 0.15,
        ShowFOV         = true,
        VisibilityCheck = false,
        Key             = "MB2",
    },
    Chams = {
        Enabled             = false,
        FillColor           = Color3.fromRGB(255, 60, 60),
        FillTransparency    = 0.5,
        OutlineColor        = Color3.fromRGB(255, 255, 255),
        OutlineTransparency = 0,
    },
    Hitbox = {
        Enabled = false,
        Size    = 1,
    },
    SilentAim = {
        Enabled   = true,
        FOV       = 500,
        HitChance = 100,
    },
    KnifeAura = {
        Enabled     = false,
        Range       = 20,
        Delay       = 0.1,
        AttackStage = 1,
        Headshot    = true,
    },
    Movement = {
        WalkSpeed   = 16,
        SprintSpeed = 26,
        JumpHeight  = 10,
    },
    Misc = {
        StabCooldown = 1,
        ThrowCooldown = 1,
    },
}

local function worldToViewport(pos)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), v.Z, onScreen
end

local function isEnemy(player)
    if player == LocalPlayer then return false end
    return LocalPlayer.Character ~= nil
end

local function isAlive(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function isVisible(targetPart)
    local origin    = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local params    = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filters = {}
    if LocalPlayer.Character then table.insert(filters, LocalPlayer.Character) end
    if targetPart.Parent     then table.insert(filters, targetPart.Parent) end
    params.FilterDescendantsInstances = filters
    local result = workspace:Raycast(origin, direction, params)
    return result == nil
end

local function getClosestInFOVCenter(fovRadius)
    local vp     = Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local fovSq  = fovRadius * fovRadius
    local best, bestDist, bestChar = nil, fovSq, nil

    for _, player in ipairs(Players:GetPlayers()) do
        if not isEnemy(player) or not isAlive(player) then continue end
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        if not head then continue end

        local sp, depth, onScreen = worldToViewport(head.Position)
        if not onScreen or depth <= 0 then continue end

        local dx  = sp.X - center.X
        local dy  = sp.Y - center.Y
        local dSq = dx * dx + dy * dy

        if dSq < bestDist then
            bestDist = dSq
            best     = head
            bestChar = char
        end
    end
    return best, bestChar
end

local function getClosestInFOVMouse(fovRadius)
    local mousePos = UserInputService:GetMouseLocation()
    local best, bestDist, bestChar = nil, fovRadius, nil

    for _, player in ipairs(Players:GetPlayers()) do
        if not isEnemy(player) or not isAlive(player) then continue end
        local char = player.Character
        local head = char and (char:FindFirstChild("Head") or getRoot(char))
        if not head then continue end

        local sp, depth, onScreen = worldToViewport(head.Position)
        if not onScreen or depth <= 0 then continue end

        local d = (mousePos - sp).Magnitude
        if d < bestDist then
            bestDist = d
            best     = head
            bestChar = char
        end
    end
    return best, bestChar
end

local function isAimAssistKeyHeld()
    if Options.AA_HoldKey then
        return Options.AA_HoldKey:GetState()
    end
    return false
end

local fovGui, fovFrame

do
    local guiParent = (type(gethui) == "function" and gethui())
                   or cloneref(CoreGui)

    fovGui = Instance.new("ScreenGui")
    fovGui.Name           = "FOV_" .. tostring(math.random(1e8, 9e8))
    fovGui.ResetOnSpawn   = false
    fovGui.IgnoreGuiInset = true
    fovGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    fovGui.DisplayOrder   = 9999
    fovGui.Parent         = guiParent

    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(fovGui)
        elseif protect_gui then protect_gui(fovGui) end
    end)

    fovFrame = Instance.new("Frame")
    fovFrame.BackgroundTransparency = 1
    fovFrame.BorderSizePixel        = 0
    fovFrame.Parent                 = fovGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent       = fovFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color     = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.Parent    = fovFrame
end

RunService.RenderStepped:Connect(function()
    if not fovFrame then return end
    local visible = Settings.AimAssist.Enabled and Settings.AimAssist.ShowFOV
    fovFrame.Visible = visible
    if not visible then return end

    local vp = Camera.ViewportSize
    local r  = Settings.AimAssist.FOVRadius
    fovFrame.Size     = UDim2.new(0, r * 2, 0, r * 2)
    fovFrame.Position = UDim2.new(0, vp.X / 2 - r, 0, vp.Y / 2 - r)
end)

RunService.RenderStepped:Connect(function()
    if not Settings.AimAssist.Enabled then return end
    if not isAimAssistKeyHeld() then return end

    local target = getClosestInFOVCenter(Settings.AimAssist.FOVRadius)
    if not target then return end
    if Settings.AimAssist.VisibilityCheck and not isVisible(target) then return end

    local currentCF   = Camera.CFrame
    local targetCF    = CFrame.lookAt(currentCF.Position, target.Position)
    local savedType   = Camera.CameraType
    Camera.CFrame     = currentCF:Lerp(targetCF, Settings.AimAssist.Smoothness)
    Camera.CameraType = savedType
end)

local chamsTable = {}

local function removeChams(player)
    local h = chamsTable[player]
    if h then
        pcall(function() h:Destroy() end)
        chamsTable[player] = nil
    end
end

local function applyChams(player, char)
    removeChams(player)
    if not Settings.Chams.Enabled then return end

    local h = Instance.new("Highlight")
    h.Adornee             = char
    h.FillColor           = Settings.Chams.FillColor
    h.FillTransparency    = Settings.Chams.FillTransparency
    h.OutlineColor        = Settings.Chams.OutlineColor
    h.OutlineTransparency = Settings.Chams.OutlineTransparency
    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent              = char
    chamsTable[player]    = h
end

local function setupPlayerChams(player)
    if player == LocalPlayer then return end
    if player.Character then applyChams(player, player.Character) end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        applyChams(player, char)
    end)
end

local function refreshAllChams()
    for player in pairs(chamsTable) do removeChams(player) end
    if not Settings.Chams.Enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do setupPlayerChams(p) end
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayerChams(p) end
Players.PlayerAdded:Connect(setupPlayerChams)
Players.PlayerRemoving:Connect(removeChams)

local hitboxConns = {}
local HITBOX_PARTS = {
    Head             = true,
    HumanoidRootPart = false,
    UpperTorso       = false,
    LowerTorso       = false,
    Torso            = false,
}

local function clearHitboxConns(player)
    if hitboxConns[player] then
        for _, c in ipairs(hitboxConns[player]) do
            pcall(function() c:Disconnect() end)
        end
        hitboxConns[player] = nil
    end
end

local function applyHitbox(player, char)
    clearHitboxConns(player)
    if not Settings.Hitbox.Enabled then return end

    hitboxConns[player] = {}
    local s          = Settings.Hitbox.Size
    local targetSize = Vector3.new(s, s, s)

    local function expandPart(part)
        if not part:IsA("BasePart") then return end
        if not HITBOX_PARTS[part.Name] then return end
        part.Size = targetSize
        local conn = part:GetPropertyChangedSignal("Size"):Connect(function()
            if Settings.Hitbox.Enabled and part.Parent then
                task.defer(function()
                    if part.Parent and Settings.Hitbox.Enabled then
                        part.Size = targetSize
                    end
                end)
            end
        end)
        table.insert(hitboxConns[player], conn)
    end

    for _, d in ipairs(char:GetDescendants()) do expandPart(d) end
    local addedConn = char.DescendantAdded:Connect(expandPart)
    table.insert(hitboxConns[player], addedConn)
end

local function setupPlayerHitbox(player)
    if player == LocalPlayer then return end
    if player.Character then applyHitbox(player, player.Character) end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        applyHitbox(player, char)
    end)
end

local function refreshAllHitboxes()
    for player in pairs(hitboxConns) do clearHitboxConns(player) end
    if not Settings.Hitbox.Enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do setupPlayerHitbox(p) end
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayerHitbox(p) end
Players.PlayerAdded:Connect(setupPlayerHitbox)
Players.PlayerRemoving:Connect(clearHitboxConns)

local function patchConfigTablesInGC()
    if not getgc then return end
    for _, item in ipairs(getgc(true)) do
        if type(item) == "table" then
            if rawget(item, "BASE_WALK_SPEED") ~= nil and rawget(item, "SPRINT_SPEED") ~= nil then
                rawset(item, "BASE_WALK_SPEED",    Settings.Movement.WalkSpeed)
                rawset(item, "SPRINT_SPEED",       Settings.Movement.SprintSpeed)
                rawset(item, "MAX_MOMENTUM_SPEED", Settings.Movement.SprintSpeed)
                rawset(item, "BASE_JUMP_HEIGHT",   Settings.Movement.JumpHeight)
            end
            if rawget(item, "StabDebounce") ~= nil or rawget(item, "ThrowCooldown") ~= nil then
                rawset(item, "StabDebounce",      Settings.Misc.StabCooldown)
                rawset(item, "ThirdStabDebounce", Settings.Misc.StabCooldown)
                rawset(item, "ThrowCooldown",     Settings.Misc.ThrowCooldown)
                rawset(item, "ThrowStabDebounce", Settings.Misc.ThrowCooldown)
            end
        end
    end
end

local function patchAllUpvaluesInGC()
    if not getgc then return end
    for _, fn in ipairs(getgc(true)) do
        if type(fn) == "function" and not (iscclosure and iscclosure(fn)) then
            local i = 1
            while true do
                local ok, name, val = pcall(debug.getupvalue, fn, i)
                if not ok or not name then break end
                if type(val) == "table" then
                    if rawget(val, "BASE_WALK_SPEED") ~= nil then
                        val.BASE_WALK_SPEED    = Settings.Movement.WalkSpeed
                        val.SPRINT_SPEED       = Settings.Movement.SprintSpeed
                        val.MAX_MOMENTUM_SPEED = Settings.Movement.SprintSpeed
                        val.BASE_JUMP_HEIGHT   = Settings.Movement.JumpHeight
                    end
                    if rawget(val, "StabDebounce") ~= nil or rawget(val, "ThrowCooldown") ~= nil then
                        val.StabDebounce      = 0.001
                        val.ThirdStabDebounce = 0.001
                        val.ThrowCooldown     = 0.001
                        val.ThrowStabDebounce = 0.001
                    end
                end
                i += 1
            end
        end
    end
end

patchConfigTablesInGC()
patchAllUpvaluesInGC()

do
    local oldLookAt = clonefunction(CFrame.lookAt)
    hookfunction(CFrame.lookAt, newcclosure(function(eye, target, ...)
        if Settings.SilentAim.Enabled then
            local c2 = debug.info(2, "n")
            local c3 = debug.info(3, "n")
            if c2 == "GetTargets" or c3 == "GetTargets" then
                if math.random(1, 100) <= Settings.SilentAim.HitChance then
                    local aimHead = getClosestInFOVMouse(Settings.SilentAim.FOV)
                    if aimHead then
                        return oldLookAt(eye, aimHead.Position)
                    end
                end
            end
        end
        return oldLookAt(eye, target, ...)
    end))

    local oldViewportToRay = clonefunction(Camera.ViewportPointToRay)
    hookfunction(Camera.ViewportPointToRay, newcclosure(function(self, x, y, depth, ...)
        if Settings.SilentAim.Enabled then
            local c2 = debug.info(2, "n")
            local c3 = debug.info(3, "n")
            if c2 == "_GetThrowDirection" or c3 == "_GetThrowDirection" then
                if math.random(1, 100) <= Settings.SilentAim.HitChance then
                    local aimHead = getClosestInFOVMouse(Settings.SilentAim.FOV)
                    if aimHead then
                        local origin = self.CFrame.Position
                        local dir    = (aimHead.Position - origin).Unit
                        return Ray.new(origin, dir)
                    end
                end
            end
        end
        return oldViewportToRay(self, x, y, depth, ...)
    end))
end

local knifeController = nil

local function findKnifeController()
    if not getgc then return nil end
    for _, v in ipairs(getgc(true)) do
        if type(v) == "table"
        and rawget(v, "_GetThrowDirection")
        and rawget(v, "reportHitSignal")
        and rawget(v, "lastKnifeTime") ~= nil then
            return v
        end
    end
end

local lastAura = 0

RunService.Heartbeat:Connect(function()
    if not knifeController then
        knifeController = findKnifeController()
    else
        knifeController.nextKnifeTime          = 0
        knifeController.throwStabDebounceUntil = 0
        knifeController.lastThrowTime          = 0
        knifeController.comboCanContinueUntil  = 0
    end

    if not Settings.KnifeAura.Enabled or not knifeController then return end

    local now = tick()
    if now - lastAura < Settings.KnifeAura.Delay then return end

    local myChar = LocalPlayer.Character
    local myRoot = getRoot(myChar)
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum or myHum.Health <= 0 then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if not isEnemy(player) or not isAlive(player) then continue end
        local eChar = player.Character
        local eRoot = getRoot(eChar)
        if not eRoot then continue end

        if (eRoot.Position - myRoot.Position).Magnitude > Settings.KnifeAura.Range then continue end

        local isHeadshot = Settings.KnifeAura.Headshot
        if Settings.KnifeAura.Headshot then
            local head = eChar:FindFirstChild("Head")
            if head then
                isHeadshot = (head.Position - myRoot.Position).Magnitude < 4.5
            end
        end

        pcall(function()
            knifeController.reportHitSignal:Fire(
                eChar, "Knife", isHeadshot, nil,
                HttpService:GenerateGUID(false),
                eRoot.Position,
                Settings.KnifeAura.AttackStage
            )
        end)

        lastAura = now
        break
    end
end)

local Window = Library:CreateWindow({
    Title            = "K-DEULS FURRY",
    Icon             = 13129527031,
    Footer           = "[ASTRO BETA]",
    Center           = true,
    AutoShow         = true,
    ShowCustomCursor = false,
    NotifySide       = "Right",
})

local Tabs = {
    Combat   = Window:AddTab("Combat",   "crosshair"),
    Visuals  = Window:AddTab("Visuals",  "eye"),
    Movement = Window:AddTab("Movement", "zap"),
    Settings = Window:AddTab("Settings", "settings"),
}

local AimL   = Tabs.Combat:AddLeftGroupbox("Aim Assist", "crosshair")
local KnifeR = Tabs.Combat:AddRightGroupbox("Knife Aura", "zap")

AimL:AddToggle("AA_Enabled", {
    Text    = "Aim Assist",
    Default = Settings.AimAssist.Enabled,
    Callback = function(v)
        Settings.AimAssist.Enabled = v
        fovFrame.Visible = v and Settings.AimAssist.ShowFOV
    end,
})

AimL:AddToggle("AA_ShowFOV", {
    Text    = "Show FOV Circle",
    Default = Settings.AimAssist.ShowFOV,
    Callback = function(v) Settings.AimAssist.ShowFOV = v end,
})

AimL:AddToggle("AA_VisCheck", {
    Text    = "Visibility Check",
    Default = Settings.AimAssist.VisibilityCheck,
    Callback = function(v) Settings.AimAssist.VisibilityCheck = v end,
})

AimL:AddSlider("AA_FOV", {
    Text     = "FOV Radius",
    Default  = Settings.AimAssist.FOVRadius,
    Min      = 50,
    Max      = 600,
    Rounding = 0,
    Callback = function(v) Settings.AimAssist.FOVRadius = v end,
})

AimL:AddSlider("AA_Smooth", {
    Text     = "Smoothness",
    Default  = Settings.AimAssist.Smoothness * 100,
    Min      = 1,
    Max      = 100,
    Rounding = 0,
    Tooltip  = "Higher = snappier",
    Callback = function(v) Settings.AimAssist.Smoothness = v / 100 end,
})

AimL:AddDivider()

AimL:AddLabel("Hold Key"):AddKeyPicker("AA_HoldKey", {
    Default         = "MB2",
    SyncToggleState = false,
    Mode            = "Hold",
    Text            = "Aim Hold Key",
    NoUI            = false,
    ChangedCallback = function(NewKey)
        Settings.AimAssist.Key = tostring(NewKey)
    end,
})

KnifeR:AddToggle("KA_Enabled", {
    Text    = "Knife Aura",
    Default = Settings.KnifeAura.Enabled,
    Risky   = true,
    Callback = function(v) Settings.KnifeAura.Enabled = v end,
})

KnifeR:AddToggle("KA_Headshot", {
    Text    = "Headshot",
    Default = Settings.KnifeAura.Headshot,
    Callback = function(v) Settings.KnifeAura.Headshot = v end,
})

KnifeR:AddSlider("KA_Range", {
    Text     = "Range",
    Default  = Settings.KnifeAura.Range,
    Min      = 1,
    Max      = 100,
    Rounding = 0,
    Callback = function(v) Settings.KnifeAura.Range = v end,
})

KnifeR:AddSlider("KA_Delay", {
    Text     = "Delay (s)",
    Default  = Settings.KnifeAura.Delay * 100,
    Min      = 1,
    Max      = 100,
    Rounding = 0,
    Callback = function(v) Settings.KnifeAura.Delay = v / 100 end,
})

KnifeR:AddSlider("KA_Stage", {
    Text     = "Attack Stage",
    Default  = Settings.KnifeAura.AttackStage,
    Min      = 1,
    Max      = 3,
    Rounding = 0,
    Callback = function(v) Settings.KnifeAura.AttackStage = v end,
})

local ChamsL  = Tabs.Visuals:AddLeftGroupbox("Chams",            "eye")
local HitboxR = Tabs.Visuals:AddRightGroupbox("Hitbox Expander", "box")

ChamsL:AddToggle("Chams_Enabled", {
    Text    = "Chams",
    Default = Settings.Chams.Enabled,
    Callback = function(v)
        Settings.Chams.Enabled = v
        refreshAllChams()
    end,
})

ChamsL:AddLabel("Fill Color"):AddColorPicker("Chams_Fill", {
    Default      = Settings.Chams.FillColor,
    Transparency = Settings.Chams.FillTransparency,
    Title        = "Fill",
    Callback     = function(c)
        Settings.Chams.FillColor = c
        for _, h in pairs(chamsTable) do
            if h and h.Parent then h.FillColor = c end
        end
    end,
})

ChamsL:AddLabel("Outline Color"):AddColorPicker("Chams_Outline", {
    Default      = Settings.Chams.OutlineColor,
    Transparency = Settings.Chams.OutlineTransparency,
    Title        = "Outline",
    Callback     = function(c)
        Settings.Chams.OutlineColor = c
        for _, h in pairs(chamsTable) do
            if h and h.Parent then h.OutlineColor = c end
        end
    end,
})

ChamsL:AddSlider("Chams_FillTrans", {
    Text     = "Fill Transparency",
    Default  = Settings.Chams.FillTransparency * 100,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Callback = function(v)
        Settings.Chams.FillTransparency = v / 100
        for _, h in pairs(chamsTable) do
            if h and h.Parent then h.FillTransparency = v / 100 end
        end
    end,
})

HitboxR:AddToggle("HB_Enabled", {
    Text    = "Hitbox Expander",
    Default = Settings.Hitbox.Enabled,
    Risky   = true,
    Callback = function(v)
        Settings.Hitbox.Enabled = v
        refreshAllHitboxes()
    end,
})

HitboxR:AddSlider("HB_Size", {
    Text     = "Hitbox Size",
    Default  = Settings.Hitbox.Size,
    Min      = 1,
    Max      = 5,
    Rounding = 1,
    Callback = function(v)
        Settings.Hitbox.Size = v
        if Settings.Hitbox.Enabled then refreshAllHitboxes() end
    end,
})

-- ─────────────────────────────────────────────────────────────────
local MovL = Tabs.Movement:AddLeftGroupbox("Speed / Jump", "zap")
local MovR = Tabs.Movement:AddRightGroupbox("Misc", "cog")

-- Safe movement apply: ignores empty/nil/out-of-range input entirely
local function applyMovement(field, raw, min, max)
    if not raw or raw == "" then return end          
    local n = tonumber(raw)
    if not n then return end                          
    n = math.floor(n)
    if n < min or n > max then return end           
    Settings.Movement[field] = n
    patchConfigTablesInGC()
    patchAllUpvaluesInGC()
end
local function applyMisc(field, raw, min, max)
    if not raw or raw == "" then return end         
    local n = tonumber(raw)
    if not n then return end                         
    n = math.floor(n)
    if n < min or n > max then return end           
    Settings.Misc[field] = n
    patchConfigTablesInGC()
    patchAllUpvaluesInGC()
end

MovL:AddInput("Mov_Walk", {
    Text             = "Walk Speed",
    Default          = tostring(Settings.Movement.WalkSpeed),
    Numeric          = true,
    Finished         = true,   -- only fires on Enter, not every keystroke
    ClearTextOnFocus = false,
    Placeholder      = "16 – 50",
    Callback = function(v) applyMovement("WalkSpeed",   v, 16, 50) end,
})

MovL:AddInput("Mov_Sprint", {
    Text             = "Sprint Speed",
    Default          = tostring(Settings.Movement.SprintSpeed),
    Numeric          = true,
    Finished         = true,
    ClearTextOnFocus = false,
    Placeholder      = "26 – 150",
    Callback = function(v) applyMovement("SprintSpeed", v, 26, 150) end,
})

MovL:AddInput("Mov_Jump", {
    Text             = "Jump Height",
    Default          = tostring(Settings.Movement.JumpHeight),
    Numeric          = true,
    Finished         = true,
    ClearTextOnFocus = false,
    Placeholder      = "10 – 100",
    Callback = function(v) applyMovement("JumpHeight",  v,  4,  100) end,
})

MovR:AddInput("Misc_Stab", {
    Text             = "Stab Cooldown",
    Default          = tostring(Settings.Misc.StabCooldown),
    Numeric          = true,
    Finished         = true,
    ClearTextOnFocus = false,
    Placeholder      = "0 – 1",
    Callback = function(v) applyMisc("StabCooldown",  v,  0, 1) end,
})

MovR:AddInput("Misc_Throw", {
    Text             = "Throw Cooldown",
    Default          = tostring(Settings.Misc.ThrowCooldown),
    Numeric          = true,
    Finished         = true,
    ClearTextOnFocus = false,
    Placeholder      = "0 – 1",
    Callback = function(v) applyMisc("ThrowCooldown",  v,  0, 1) end,
})

local menuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")

menuGroup:AddToggle("UI_Cursor", {
    Text     = "Custom Cursor",
    Default  = false,
    Callback = function(v)
        Library.ShowCustomCursor = v
    end,
})

menuGroup:AddDropdown("UI_NotifSide", {
    Text     = "Notification Side",
    Values   = { "Left", "Right" },
    Default  = "Right",
    Callback = function(v)
        Library:SetNotifySide(v)
    end,
})

menuGroup:AddDropdown("DPIDropdown", {
    Values   = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default  = "100%",
    Text     = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        Library:SetDPIScale(DPI)
    end,
})

menuGroup:AddDivider()

menuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI    = true,
    Text    = "Toggle Menu",
})

menuGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end,
})

Library.ToggleKeybind = Options.MenuKeybind

Library:OnUnload(function()
    Settings.SilentAim.Enabled    = false
    Settings.AimAssist.Enabled    = false
    Settings.Hitbox.Enabled       = false
    Settings.KnifeAura.Enabled    = false
    Settings.Chams.Enabled        = false
    Settings.Movement.WalkSpeed   = 16
    Settings.Movement.SprintSpeed = 26
    Settings.Movement.JumpHeight  = 10
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Theme")
SaveManager:SetFolder("ASTRO/configs")
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify({
    Title       = "ASTRO K-DUELS",
    Description = "Loaded successfully!",
    Time        = 3,
})
