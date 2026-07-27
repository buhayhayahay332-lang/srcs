--test 7
if not game:IsLoaded() then game.Loaded:Wait() end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local Settings = {
    SilentAim = {
        Enabled   = false,
        FOV       = 200,
        HitChance = 100,
        ShowFOV   = false,
    },
    AimAssist = {
        Enabled    = false,
        Smoothness = 0.08,
        FOV        = 300,
        Key        = Enum.UserInputType.MouseButton2,
    },
    KnifeAura = {
        Enabled     = false,
        Range       = 10,
        Delay       = 0.1,
        AttackStage = 1,
        Headshot    = false,
    },
    ESP = {
        Enabled  = false,
        Box      = false,
        Health   = false,
        Tracers  = false,
        HeadDot  = false,
        Name     = false,
        BoxColor = Color3.fromRGB(255, 255, 255),
    },
    Chams = {
        Enabled             = false,
        Color               = Color3.fromRGB(255, 0, 255),
        OutlineColor        = Color3.fromRGB(255, 255, 255),
        FillTransparency    = 0.5,
        OutlineTransparency = 0,
    },
}

local function getMousePos()
    return UserInputService:GetMouseLocation()
end

local function worldToViewport(pos)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), v.Z, onScreen
end

local function isEnemy(player)
    if player == LocalPlayer then return false end
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    return true
end

local function getRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function isAlive(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getClosestInFOV(fovRadius)
    local best, bestDist, bestChar = nil, fovRadius, nil
    local mousePos = getMousePos()

    for _, player in ipairs(Players:GetPlayers()) do
        if not isEnemy(player) or not isAlive(player) then continue end
        local char = player.Character
        local head = char and (char:FindFirstChild("Head") or getRoot(char))
        if not head then continue end

        local sp, depth, onScreen = worldToViewport(head.Position)
        if not onScreen or depth <= 0 then continue end

        local d = (mousePos - sp).Magnitude
        if d < bestDist then
            bestDist  = d
            best      = head
            bestChar  = char
        end
    end
    return best, bestChar
end

local knifeController   = nil
local HitDetectionUtils = nil

local function findKnifeController()
    if not getgc then return nil end
    for _, v in ipairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "_GetThrowDirection") and rawget(v, "reportHitSignal") then
            return v
        end
    end
    return nil
end

local function findHitDetectionUtils()
    if not getgc then return nil end
    for _, v in ipairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "GetTargets") and rawget(v, "SpherecastProjectile") then
            return v
        end
    end
    return nil
end

task.spawn(function()
    while not knifeController or not HitDetectionUtils do
        knifeController   = findKnifeController()
        HitDetectionUtils = findHitDetectionUtils()
        task.wait(0.5)
    end
end)

local function setupMeleeSilentAim()
    if not HitDetectionUtils then return false end
    local oldGetTargets = HitDetectionUtils.GetTargets

    HitDetectionUtils.GetTargets = newcclosure(function(character, ...)
        if Settings.SilentAim.Enabled and math.random(1, 100) <= Settings.SilentAim.HitChance then
            local target, targetModel = getClosestInFOV(Settings.SilentAim.FOV)
            if target and targetModel then
                return {{model = targetModel, hitPosition = target.Position}}
            end
        end
        return oldGetTargets(character, ...)
    end)
    return true
end

local function setupThrowSilentAim()
    if not knifeController then return false end
    if not knifeController._GetThrowDirection then return false end

    local oldGetThrowDirection = knifeController._GetThrowDirection

    knifeController._GetThrowDirection = newcclosure(function(self, cameraCFrame)
        if Settings.SilentAim.Enabled then
            local target = getClosestInFOV(Settings.SilentAim.FOV)
            if target then
                return (target.Position - cameraCFrame.Position).Unit
            end
        end
        return oldGetThrowDirection(self, cameraCFrame)
    end)
    return true
end

task.spawn(function()
    while true do
        local meleeHooked = setupMeleeSilentAim()
        local throwHooked = setupThrowSilentAim()
        if meleeHooked and throwHooked then
            print("tite#1!")
            break
        end
        task.wait(0.25)
    end
end)

RunService.RenderStepped:Connect(function()
    if not Settings.AimAssist.Enabled then return end

    local held = false
    if Settings.AimAssist.Key == Enum.UserInputType.MouseButton2 then
        held = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif Settings.AimAssist.Key == Enum.UserInputType.MouseButton1 then
        held = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    end
    if not held then return end

    local target = getClosestInFOV(Settings.AimAssist.FOV)
    if not target then return end

    pcall(function()
        local current = Camera.CFrame
        local goal    = CFrame.lookAt(current.Position, target.Position)
        Camera.CFrame = current:Lerp(goal, Settings.AimAssist.Smoothness)
    end)
end)

local lastAura = 0

RunService.Heartbeat:Connect(function()
    if not Settings.KnifeAura.Enabled then return end
    if not knifeController then return end

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

        local dist = (eRoot.Position - myRoot.Position).Magnitude
        if dist > Settings.KnifeAura.Range then continue end

        local stabId     = HttpService:GenerateGUID(false)
        local hitPos     = eRoot.Position
        local isHeadshot = Settings.KnifeAura.Headshot
        if Settings.KnifeAura.Headshot then
            local head = eChar:FindFirstChild("Head")
            if head then
                isHeadshot = (head.Position - myRoot.Position).Magnitude < 4.5
            end
        end

        pcall(function()
            knifeController.reportHitSignal:Fire(
                eChar,
                "Knife",
                isHeadshot,
                nil,
                stabId,
                hitPos,
                Settings.KnifeAura.AttackStage
            )
        end)

        lastAura = now
        break
    end
end)

local function getExecutorName()
    if identifyexecutor and type(identifyexecutor) == "function" then
        local name = identifyexecutor()
        if name then return name end
    end
    if getexecutorname and type(getexecutorname) == "function" then
        local name = getexecutorname()
        if name then return name end
    end
    return "Unknown"
end
local Executor = getExecutorName()
local IsDelta = (Executor == "Delta")

local fovCircleDrawing  
local fovCircleGui      
local fovCircleFrame   

if IsDelta then
    fovCircleGui = Instance.new("ScreenGui")
    fovCircleGui.Name = "FOVCircle"
    fovCircleGui.ResetOnSpawn = false
    fovCircleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    fovCircleGui.Parent = cloneref(game:GetService("CoreGui")) 

    fovCircleFrame = Instance.new("Frame")
    fovCircleFrame.Name = "Circle"
    fovCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fovCircleFrame.Size = UDim2.new(0, 0, 0, 0)
    fovCircleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    fovCircleFrame.BackgroundTransparency = 1
    fovCircleFrame.BorderSizePixel = 0
    fovCircleFrame.Parent = fovCircleGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)  -- full circle
    corner.Parent = fovCircleFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0
    stroke.Parent = fovCircleFrame
else
    fovCircleDrawing = Drawing.new("Circle")
    fovCircleDrawing.Thickness     = 1
    fovCircleDrawing.NumSides      = 64
    fovCircleDrawing.Filled        = false
    fovCircleDrawing.Color         = Color3.fromRGB(255, 255, 255)
    fovCircleDrawing.Transparency  = 1
    fovCircleDrawing.ZIndex        = 999
    fovCircleDrawing.Visible       = false
end

RunService.RenderStepped:Connect(function()
    local visible = Settings.SilentAim.Enabled and Settings.SilentAim.ShowFOV
    local radius = Settings.SilentAim.FOV

    if IsDelta then
        if fovCircleGui then
            fovCircleFrame.Size = UDim2.new(0, radius * 2, 0, radius * 2)
            fovCircleFrame.Visible = visible
            fovCircleGui.Enabled = visible
        end
    else
        if fovCircleDrawing then
            fovCircleDrawing.Visible  = visible
            fovCircleDrawing.Radius   = radius
            fovCircleDrawing.Position = Camera.ViewportSize / 2
        end
    end
end)

local espDrawings = {}
local chamsCache  = {}

local function clearESP(player)
    if espDrawings[player] then
        for _, drawing in pairs(espDrawings[player]) do drawing:Remove() end
        espDrawings[player] = nil
    end
end

local function clearChams(player)
    if chamsCache[player] then
        chamsCache[player]:Destroy()
        chamsCache[player] = nil
    end
end

Players.PlayerRemoving:Connect(function(player)
    clearESP(player)
    clearChams(player)
end)

RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = getRoot(myChar)
    if not myRoot then return end

    if not Settings.ESP.Enabled and not Settings.Chams.Enabled then
        for player in pairs(espDrawings) do clearESP(player) end
        for player in pairs(chamsCache)  do clearChams(player) end
        return
    end

    local screenCenter = Camera.ViewportSize / 2 

    for _, player in ipairs(Players:GetPlayers()) do
        if not isEnemy(player) or not isAlive(player) then
            clearESP(player)
            clearChams(player)
            continue
        end

        local char = player.Character
        local root = getRoot(char)
        local head = char:FindFirstChild("Head")
        if not root or not head then
            clearESP(player)
            clearChams(player)
            continue
        end

        if Settings.Chams.Enabled then
            local highlight = char:FindFirstChildOfClass("Highlight")
            if not highlight then
                highlight         = Instance.new("Highlight")
                highlight.Adornee = char
                highlight.Parent  = char
                chamsCache[player] = highlight
            end
            highlight.FillColor             = Settings.Chams.Color
            highlight.OutlineColor          = Settings.Chams.OutlineColor
            highlight.FillTransparency      = Settings.Chams.FillTransparency
            highlight.OutlineTransparency   = Settings.Chams.OutlineTransparency
        else
            clearChams(player)
        end

        if not Settings.ESP.Enabled then
            clearESP(player)
            continue
        end

        if not espDrawings[player] then
            espDrawings[player] = {
                Box     = Drawing.new("Square"),
                Health  = Drawing.new("Square"),
                Tracer  = Drawing.new("Line"),
                HeadDot = Drawing.new("Circle"),
                Name    = Drawing.new("Text"),
            }
            for _, d in pairs(espDrawings[player]) do
                d.Thickness    = 1
                d.Filled       = false
                d.Transparency = 1
                d.ZIndex       = 999
            end
            espDrawings[player].Box.Color         = Settings.ESP.BoxColor
            espDrawings[player].Health.Color       = Color3.fromRGB(0, 255, 0)
            espDrawings[player].Tracer.Color       = Color3.fromRGB(255, 255, 255)
            espDrawings[player].HeadDot.Color      = Color3.fromRGB(255, 50, 50)
            espDrawings[player].HeadDot.Thickness  = 2
            espDrawings[player].HeadDot.Filled     = true
            espDrawings[player].Name.Size          = 14
            espDrawings[player].Name.Color         = Color3.fromRGB(255, 255, 255)
            espDrawings[player].Name.Center        = true
            espDrawings[player].Name.Outline       = true
        end

        local draw     = espDrawings[player]
        local rootVec  = Camera:WorldToViewportPoint(root.Position)
        local headVec  = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))

        local rootPos      = Vector2.new(rootVec.X, rootVec.Y)
        local headPos      = Vector2.new(headVec.X, headVec.Y)
        local rootOnScreen = rootVec.Z > 0
        local headOnScreen = headVec.Z > 0

        local dist      = (root.Position - myRoot.Position).Magnitude
        local boxHeight = math.clamp((rootPos.Y - headPos.Y) * 1.2, 20, 300)
        local boxWidth  = boxHeight * 0.6

        if rootOnScreen and headOnScreen then
            if Settings.ESP.Box then
                draw.Box.Visible  = true
                draw.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, headPos.Y - boxHeight * 0.15)
                draw.Box.Size     = Vector2.new(boxWidth, boxHeight)
                draw.Box.Color    = Settings.ESP.BoxColor
            else
                draw.Box.Visible = false
            end

            if Settings.ESP.Health then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local hp     = hum.Health / hum.MaxHealth
                    local barY   = headPos.Y - boxHeight * 0.15
                    draw.Health.Visible  = true
                    draw.Health.Position = Vector2.new(rootPos.X - boxWidth / 2 - 6, barY)
                    draw.Health.Size     = Vector2.new(4, boxHeight * hp)
                    draw.Health.Color    = Color3.fromRGB(
                        math.clamp((1 - hp) * 255, 0, 255),
                        math.clamp(hp * 255, 0, 255),
                        0
                    )
                    draw.Health.Filled = true
                end
            else
                draw.Health.Visible = false
            end

            if Settings.ESP.Tracers then
                draw.Tracer.Visible = true
                draw.Tracer.From    = Vector2.new(screenCenter.X, 0)   
                draw.Tracer.To      = headPos
            else
                draw.Tracer.Visible = false
            end

            if Settings.ESP.HeadDot then
                draw.HeadDot.Visible   = true
                draw.HeadDot.Position  = headPos
                draw.HeadDot.Radius    = math.clamp(100 / dist, 3, 8)
            else
                draw.HeadDot.Visible = false
            end

            if Settings.ESP.Name then
                draw.Name.Visible   = true
                draw.Name.Position  = Vector2.new(rootPos.X, headPos.Y - boxHeight * 0.15 - 18)
                draw.Name.Text      = player.Name
            else
                draw.Name.Visible = false
            end
        else
            draw.Box.Visible     = false
            draw.Health.Visible  = false
            draw.Tracer.Visible  = false
            draw.HeadDot.Visible = false
            draw.Name.Visible    = false
        end
    end
end)

local repo         = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title            = "K-DEULS FURRY",
    Icon = 13129527031,
    Footer           = "[ASTRO BETA]",
    Center           = true,
    AutoShow         = true,
    ShowCustomCursor = false,
    NotifySide       = "Right",
})

local Tabs = {
    SilentAim  = Window:AddTab("Silent Aim",  "crosshair"),
    AimAssist  = Window:AddTab("Aim Assist",  "mouse-pointer-2"),
    KnifeAura  = Window:AddTab("Knife Aura",  "sword"),
    ESP        = Window:AddTab("ESP",         "eye"),
    UISettings = Window:AddTab("UI Settings", "settings"),
}

local saLeft  = Tabs.SilentAim:AddLeftGroupbox("Silent Aim",  "crosshair")
local saRight = Tabs.SilentAim:AddRightGroupbox("FOV Circle", "circle-dashed")

saLeft:AddToggle("SA_Enabled", {
    Text     = "Enabled",
    Default  = Settings.SilentAim.Enabled,
    Risky    = true,
    Callback = function(v)
        Settings.SilentAim.Enabled = v
    end,
})

saLeft:AddDivider()

saLeft:AddSlider("SA_FOV", {
    Text     = "FOV Radius",
    Default  = Settings.SilentAim.FOV,
    Min      = 10,
    Max      = 1000,
    Rounding = 0,
    Callback = function(v)
        Settings.SilentAim.FOV = v
    end,
})

saLeft:AddSlider("SA_HitChance", {
    Text     = "Hit Chance",
    Default  = Settings.SilentAim.HitChance,
    Min      = 1,
    Max      = 100,
    Rounding = 0,
    Suffix   = "%",
    Callback = function(v)
        Settings.SilentAim.HitChance = v
    end,
})

saRight:AddToggle("SA_ShowFOV", {
    Text     = "Show FOV Circle",
    Default  = Settings.SilentAim.ShowFOV,
    Callback = function(v)
        Settings.SilentAim.ShowFOV = v
    end,
})

local aaLeft  = Tabs.AimAssist:AddLeftGroupbox("Aim Assist", "mouse-pointer-2")
local aaRight = Tabs.AimAssist:AddRightGroupbox("Settings",  "settings-2")

aaLeft:AddToggle("AA_Enabled", {
    Text     = "Enabled",
    Default  = Settings.AimAssist.Enabled,
    Callback = function(v)
        Settings.AimAssist.Enabled = v
    end,
})

aaLeft:AddDivider()

aaLeft:AddSlider("AA_FOV", {
    Text     = "FOV Radius",
    Default  = Settings.SilentAim.FOV,
    Min      = 10,
    Max      = 1000,
    Rounding = 0,
    Callback = function(v)
        Settings.SilentAim.FOV = v
    end,
})

aaRight:AddSlider("AA_Smoothness", {
    Text     = "Smoothness",
    Default  = math.floor(Settings.AimAssist.Smoothness * 100),
    Min      = 1,
    Max      = 100,
    Rounding = 0,
    Suffix   = "%",
    Callback = function(v)
        Settings.AimAssist.Smoothness = v / 100
    end,
})

aaRight:AddDropdown("AA_Key", {
    Text     = "Hold Key",
    Values   = { "MouseButton1", "MouseButton2" },
    Default  = "MouseButton2",
    Callback = function(v)
        if v == "MouseButton1" then
            Settings.AimAssist.Key = Enum.UserInputType.MouseButton1
        else
            Settings.AimAssist.Key = Enum.UserInputType.MouseButton2
        end
    end,
})

local kaLeft  = Tabs.KnifeAura:AddLeftGroupbox("Knife Aura", "sword")
local kaRight = Tabs.KnifeAura:AddRightGroupbox("Settings",  "settings-2")

kaLeft:AddToggle("KA_Enabled", {
    Text     = "Enabled",
    Default  = Settings.KnifeAura.Enabled,
    Risky    = true,
    Callback = function(v)
        Settings.KnifeAura.Enabled = v
    end,
})

kaLeft:AddDivider()

kaLeft:AddSlider("KA_Range", {
    Text     = "Range",
    Default  = Settings.KnifeAura.Range,
    Min      = 1,
    Max      = 10,
    Rounding = 0,
    Suffix   = " studs",
    Callback = function(v)
        Settings.KnifeAura.Range = v
    end,
})

kaLeft:AddToggle("KA_Headshot", {
    Text     = "Force Headshot",
    Default  = Settings.KnifeAura.Headshot,
    Callback = function(v)
        Settings.KnifeAura.Headshot = v
    end,
})

kaRight:AddSlider("KA_Delay", {
    Text     = "Delay",
    Default  = math.floor(Settings.KnifeAura.Delay * 1000),
    Min      = 0,
    Max      = 1000,
    Rounding = 0,
    Suffix   = "ms",
    Callback = function(v)
        Settings.KnifeAura.Delay = v / 1000
    end,
})

kaRight:AddSlider("KA_AttackStage", {
    Text     = "Attack Stage",
    Default  = Settings.KnifeAura.AttackStage,
    Min      = 1,
    Max      = 3,
    Rounding = 0,
    Callback = function(v)
        Settings.KnifeAura.AttackStage = v
    end,
})

local espLeft  = Tabs.ESP:AddLeftGroupbox("ESP",   "eye")
local espRight = Tabs.ESP:AddRightGroupbox("Chams", "layers")

espLeft:AddToggle("ESP_Enabled", {
    Text     = "Enabled",
    Default  = Settings.ESP.Enabled,
    Risky    = true,
    Callback = function(v)
        Settings.ESP.Enabled = v
    end,
})

espLeft:AddDivider()

--[[
espLeft:AddToggle("ESP_Box", {
    Text     = "Box",
    Default  = Settings.ESP.Box,
    Callback = function(v)
        Settings.ESP.Box = v
    end,
})

]]

--[[
espLeft:AddToggle("ESP_Health", {
    Text     = "Health Bar",
    Default  = Settings.ESP.Health,
    Callback = function(v)
        Settings.ESP.Health = v
    end,
})
]]

espLeft:AddToggle("ESP_Tracers", {
    Text     = "Tracers",
    Default  = Settings.ESP.Tracers,
    Callback = function(v)
        Settings.ESP.Tracers = v
    end,
})

espLeft:AddToggle("ESP_HeadDot", {
    Text     = "Head Dot",
    Default  = Settings.ESP.HeadDot,
    Callback = function(v)
        Settings.ESP.HeadDot = v
    end,
})

espLeft:AddToggle("ESP_Name", {
    Text     = "Name",
    Default  = Settings.ESP.Name,
    Callback = function(v)
        Settings.ESP.Name = v
    end,
})
--[[

espRight:AddLabel("Box Color"):AddColorPicker("ESP_BoxColor", {
    Default  = Settings.ESP.BoxColor,
    Callback = function(v)
        Settings.ESP.BoxColor = v
        for _, drawings in pairs(espDrawings) do
            if drawings.Box then
                drawings.Box.Color = v
            end
        end
    end,
})
]]


espRight:AddToggle("CH_Enabled", {
    Text     = "Enabled",
    Default  = Settings.Chams.Enabled,
    Callback = function(v)
        Settings.Chams.Enabled = v
    end,
})

espRight:AddDivider()

espRight:AddSlider("CH_FillTrans", {
    Text     = "Fill Transparency",
    Default  = math.floor(Settings.Chams.FillTransparency * 100),
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Suffix   = "%",
    Callback = function(v)
        Settings.Chams.FillTransparency = v / 100
    end,
})

espRight:AddSlider("CH_OutlineTrans", {
    Text     = "Outline Transparency",
    Default  = math.floor(Settings.Chams.OutlineTransparency * 100),
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Suffix   = "%",
    Callback = function(v)
        Settings.Chams.OutlineTransparency = v / 100
    end,
})

espRight:AddLabel("Fill Color"):AddColorPicker("CH_FillColor", {
    Default  = Settings.Chams.Color,
    Callback = function(v)
        Settings.Chams.Color = v
    end,
})

espRight:AddLabel("Outline Color"):AddColorPicker("CH_OutlineColor", {
    Default  = Settings.Chams.OutlineColor,
    Callback = function(v)
        Settings.Chams.OutlineColor = v
    end,
})

local menuGroup = Tabs.UISettings:AddLeftGroupbox("Menu", "wrench")

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
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "DPI Scale",
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
    Settings.SilentAim.Enabled = false
    Settings.AimAssist.Enabled = false
    Settings.KnifeAura.Enabled = false
    Settings.ESP.Enabled       = false
    Settings.Chams.Enabled     = false
    if fovCircleDrawing then
        fovCircleDrawing:Remove()
    end
    if fovCircleGui then
        fovCircleGui:Destroy()
    end
    for player in pairs(espDrawings) do clearESP(player) end
    for player in pairs(chamsCache)  do clearChams(player) end
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Theme")
SaveManager:SetFolder("ASTRO/configs")
ThemeManager:ApplyToTab(Tabs.UISettings)
SaveManager:BuildConfigSection(Tabs.UISettings)
SaveManager:LoadAutoloadConfig()

Library:Notify({
    Title       = "ASTRO K-DUELS",
    Description = "Loaded successfully!",
    Time        = 3,
})