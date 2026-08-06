
-- ── 1. Obsidian ───────────────────────────────────────────────────────────────
local repo         = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- ── 2. Runtime config ─────────────────────────────────────────────────────────
local cfg = {
    silentAim   = true,
    fovSize     = 150,
    maxDistance = 500,

    espEnabled       = true,
    tracerEnabled    = true,
    distanceEnabled  = true,
    highlightEnabled = true,
    boxEnabled       = false,
    cornerBoxEnabled = true,
    healthBarEnabled = true,
    headDotEnabled   = true,

    fovCircleVisible = true,
    espColor = Color3.fromRGB(255, 105, 180),
}

-- ── 3. Services / globals ─────────────────────────────────────────────────────
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Camera        = workspace.CurrentCamera
local LocalPlayer   = Players.LocalPlayer
local BulletHandler = require(game:GetService("ReplicatedStorage").ModuleScripts.GunModules.BulletHandler)
local oldFire       = BulletHandler.Fire

local drawingWorks = pcall(function() return Drawing.new("Line") end)

-- ── 4. Helper — dynamic health colour ────────────────────────────────────────
local function getHealthColor(ratio)
    ratio = math.clamp(ratio, 0, 1)
    if ratio > 0.5 then
        return Color3.fromRGB(math.floor(255 * (1 - ratio) * 2), 255, 0)
    else
        return Color3.fromRGB(255, math.floor(255 * ratio * 2), 0)
    end
end

-- ── 5. Active ESP table (for live colour updates) ─────────────────────────────
local activeESP = {}

-- ── 6. ESP ────────────────────────────────────────────────────────────────────
local function createESP(player)
    if player == LocalPlayer then return end

    -- tracer
    local tracer      = Drawing.new("Line")
    tracer.Color      = cfg.espColor
    tracer.Thickness  = 1

    -- distance text
    local distanceText = drawingWorks and Drawing.new("Text") or nil
    if distanceText then
        distanceText.Color   = cfg.espColor
        distanceText.Size    = 13
        distanceText.Center  = true
        distanceText.Outline = true
    end

    -- highlight / chams
    local highlight = Instance.new("Highlight")
    highlight.FillColor           = cfg.espColor
    highlight.OutlineColor        = cfg.espColor
    highlight.FillTransparency    = 0.8
    highlight.OutlineTransparency = 0
    highlight.Parent              = game:GetService("CoreGui")

    -- 2D box
    local box      = Drawing.new("Square")
    box.Color      = cfg.espColor
    box.Thickness  = 1
    box.Filled     = false

    -- corner box — 8 lines (2 per corner)
    local corners = {}
    for i = 1, 8 do
        corners[i]           = Drawing.new("Line")
        corners[i].Color     = cfg.espColor
        corners[i].Thickness = 1.5
    end

    -- health bar — dark bg + coloured fill
    local healthBg    = Drawing.new("Square")
    healthBg.Color    = Color3.fromRGB(0, 0, 0)
    healthBg.Filled   = true

    local healthFill  = Drawing.new("Square")
    healthFill.Filled = true

    -- head dot
    local headDot      = Drawing.new("Circle")
    headDot.Color      = cfg.espColor
    headDot.Filled     = true
    headDot.Radius     = 3
    headDot.NumSides   = 16

    activeESP[player] = {
        tracer       = tracer,
        distanceText = distanceText,
        highlight    = highlight,
        box          = box,
        corners      = corners,
        healthBg     = healthBg,
        healthFill   = healthFill,
        headDot      = headDot,
    }

    local function hideAll()
        tracer.Visible = false
        if distanceText then distanceText.Visible = false end
        highlight.Enabled  = false
        box.Visible        = false
        for i = 1, 8 do corners[i].Visible = false end
        healthBg.Visible   = false
        healthFill.Visible = false
        headDot.Visible    = false
    end

    local function cleanup()
        tracer:Remove()
        if distanceText then distanceText:Remove() end
        highlight:Destroy()
        box:Remove()
        for i = 1, 8 do corners[i]:Remove() end
        healthBg:Remove()
        healthFill:Remove()
        headDot:Remove()
        activeESP[player] = nil
    end

    local connection
    connection = RunService.RenderStepped:Connect(function()
        local character = player.Character
        if not character or not character:IsDescendantOf(workspace) or not LocalPlayer.Character then
            hideAll()
            if not player:IsDescendantOf(Players) then
                cleanup()
                connection:Disconnect()
            end
            return
        end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local head     = character:FindFirstChild("Head")

        if not (rootPart and humanoid and humanoid.Health > 0 and head) then
            hideAll()
            return
        end

        local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local distance  = localRoot and (rootPart.Position - localRoot.Position).Magnitude or 0

        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local feetPos               = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

        if not (headOnScreen and distance <= cfg.maxDistance) then
            hideAll()
            return
        end

        -- ── box geometry ──────────────────────────────────────────────────────
        local boxH = math.max(feetPos.Y - headPos.Y, 1)
        local boxW = boxH * 0.55
        local boxX = headPos.X - boxW / 2
        local boxY = headPos.Y

        -- ── tracer: top-center of screen → enemy head ─────────────────────────
        tracer.From    = Vector2.new(Camera.ViewportSize.X / 2, 0)
        tracer.To      = Vector2.new(headPos.X, headPos.Y)
        tracer.Visible = cfg.espEnabled and cfg.tracerEnabled

        -- ── distance text: below feet ─────────────────────────────────────────
        if distanceText then
            distanceText.Text     = math.floor(distance) .. " studs"
            distanceText.Position = Vector2.new(feetPos.X, feetPos.Y + 4)
            distanceText.Visible  = cfg.espEnabled and cfg.distanceEnabled
        end

        -- ── chams ─────────────────────────────────────────────────────────────
        highlight.Adornee = character
        highlight.Enabled = cfg.espEnabled and cfg.highlightEnabled

        -- ── 2D box ────────────────────────────────────────────────────────────
        box.Position = Vector2.new(boxX, boxY)
        box.Size     = Vector2.new(boxW, boxH)
        box.Visible  = cfg.espEnabled and cfg.boxEnabled

        -- ── corner box ────────────────────────────────────────────────────────
        local cLen = math.min(boxW, boxH) * 0.25
        local cVis = cfg.espEnabled and cfg.cornerBoxEnabled

        -- top-left
        corners[1].From = Vector2.new(boxX,        boxY);        corners[1].To = Vector2.new(boxX + cLen,        boxY)
        corners[2].From = Vector2.new(boxX,        boxY);        corners[2].To = Vector2.new(boxX,               boxY + cLen)
        -- top-right
        corners[3].From = Vector2.new(boxX + boxW, boxY);        corners[3].To = Vector2.new(boxX + boxW - cLen, boxY)
        corners[4].From = Vector2.new(boxX + boxW, boxY);        corners[4].To = Vector2.new(boxX + boxW,        boxY + cLen)
        -- bottom-left
        corners[5].From = Vector2.new(boxX,        boxY + boxH); corners[5].To = Vector2.new(boxX + cLen,        boxY + boxH)
        corners[6].From = Vector2.new(boxX,        boxY + boxH); corners[6].To = Vector2.new(boxX,               boxY + boxH - cLen)
        -- bottom-right
        corners[7].From = Vector2.new(boxX + boxW, boxY + boxH); corners[7].To = Vector2.new(boxX + boxW - cLen, boxY + boxH)
        corners[8].From = Vector2.new(boxX + boxW, boxY + boxH); corners[8].To = Vector2.new(boxX + boxW,        boxY + boxH - cLen)

        for i = 1, 8 do corners[i].Visible = cVis end

        -- ── health bar (left of box) ──────────────────────────────────────────
        local hpRatio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
        local barX    = boxX - 6

        healthBg.Position = Vector2.new(barX, boxY)
        healthBg.Size     = Vector2.new(3, boxH)
        healthBg.Visible  = cfg.espEnabled and cfg.healthBarEnabled

        healthFill.Color    = getHealthColor(hpRatio)
        healthFill.Position = Vector2.new(barX, boxY + boxH * (1 - hpRatio))
        healthFill.Size     = Vector2.new(3, math.max(boxH * hpRatio, 1))
        healthFill.Visible  = cfg.espEnabled and cfg.healthBarEnabled

        -- ── head dot ──────────────────────────────────────────────────────────
        headDot.Position = Vector2.new(headPos.X, headPos.Y)
        headDot.Visible  = cfg.espEnabled and cfg.headDotEnabled
    end)
end

for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
Players.PlayerAdded:Connect(createESP)

-- ── 7. FOV circle ─────────────────────────────────────────────────────────────
local fovCircle = drawingWorks and (function()
    local circle        = Drawing.new("Circle")
    circle.Color        = cfg.espColor
    circle.Thickness    = 1
    circle.Transparency = 1
    circle.Radius       = cfg.fovSize
    circle.NumSides     = 60
    circle.Filled       = false
    circle.ZIndex       = 999
    return circle
end)() or nil

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Radius   = cfg.fovSize
        fovCircle.Visible  = cfg.fovCircleVisible
    end
end)

-- ── 8. Silent aim ─────────────────────────────────────────────────────────────
local lockedHead = nil

local function getClosestHead()
    local character = LocalPlayer.Character
    if not character then return nil end
    local localRoot = character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end

    local centerPos   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closestHead = nil
    local closestDist = cfg.fovSize * cfg.fovSize

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head     = player.Character:FindFirstChild("Head")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local hum      = player.Character:FindFirstChildOfClass("Humanoid")

            if head and rootPart and hum and hum.Health > 0 then
                local dist3D = (rootPart.Position - localRoot.Position).Magnitude
                if dist3D <= cfg.maxDistance then
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist2D = (Vector2.new(screenPoint.X, screenPoint.Y) - centerPos).Magnitude
                        if dist2D < closestDist then
                            closestDist = dist2D
                            closestHead = head
                        end
                    end
                end
            end
        end
    end

    lockedHead = closestHead
    return closestHead
end

BulletHandler.Fire = function(p6)
    if cfg.silentAim then
        local closestHead = getClosestHead()
        if closestHead then
            p6.Direction = (closestHead.Position - p6.Origin).Unit
        end
    end
    return oldFire(p6)
end

-- ── 9. Window ─────────────────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title            = "Furry Flick",
    Icon             = 13129527031,
    Footer           = "[ASTRO BETA]",
    NotifySide       = "Right",
    ShowCustomCursor = false,
    Center           = true,
    AutoShow         = true,
})

local Tabs = {
    Main            = Window:AddTab("Main",        "crosshair"),
    Visual          = Window:AddTab("Visual",      "eye"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- ── 10. Main tab — Silent Aim ─────────────────────────────────────────────────
local AimBox = Tabs.Main:AddLeftGroupbox("Silent Aim", "crosshair")

AimBox:AddToggle("SilentAim", {
    Text    = "Enable",
    Default = cfg.silentAim,
    Tooltip = "Redirects bullets to the closest head inside FOV",
})

AimBox:AddSlider("FovSize", {
    Text     = "FOV Size",
    Default  = cfg.fovSize,
    Min      = 1,
    Max      = 500,
    Rounding = 0,
    Suffix   = "px",
    Tooltip  = "Screen-space FOV radius used for target selection",
})

AimBox:AddSlider("MaxDistance", {
    Text     = "Max Distance",
    Default  = cfg.maxDistance,
    Min      = 50,
    Max      = 2000,
    Rounding = 0,
    Suffix   = " studs",
    Tooltip  = "Ignore targets beyond this world-space distance",
})

AimBox:AddToggle("FovCircle", {
    Text    = "FOV Circle",
    Default = cfg.fovCircleVisible,
    Tooltip = "Draw the FOV radius circle on screen",
})

-- ── 11. Visual tab — ESP ──────────────────────────────────────────────────────
local EspBox = Tabs.Visual:AddLeftGroupbox("ESP", "eye")

EspBox:AddToggle("EspEnabled", {
    Text    = "Enable ESP",
    Default = cfg.espEnabled,
    Tooltip = "Master toggle — controls all ESP elements",
})

EspBox:AddDivider()

EspBox:AddToggle("TracerEnabled", {
    Text    = "Tracers",
    Default = cfg.tracerEnabled,
    Tooltip = "Line from top-center of screen to enemy head",
})

EspBox:AddToggle("BoxEnabled", {
    Text    = "Box",
    Default = cfg.boxEnabled,
    Tooltip = "Full 2D bounding box around enemy",
})

EspBox:AddToggle("CornerBoxEnabled", {
    Text    = "Corner Box",
    Default = cfg.cornerBoxEnabled,
    Tooltip = "Corner-style bounding box around enemy",
})

EspBox:AddToggle("HealthBarEnabled", {
    Text    = "Health Bar",
    Default = cfg.healthBarEnabled,
    Tooltip = "Vertical health bar left of the box (green → red)",
})

EspBox:AddToggle("HeadDotEnabled", {
    Text    = "Head Dot",
    Default = cfg.headDotEnabled,
    Tooltip = "Filled dot at the enemy head position",
})

EspBox:AddToggle("DistanceEnabled", {
    Text    = "Distance",
    Default = cfg.distanceEnabled,
    Tooltip = "Distance label below the enemy's feet",
})

EspBox:AddToggle("HighlightEnabled", {
    Text    = "Chams",
    Default = cfg.highlightEnabled,
    Tooltip = "Highlight / glow on enemy models",
})

EspBox:AddDivider()

EspBox:AddLabel("Color")
    :AddColorPicker("EspColor", {
        Default = cfg.espColor,
        Title   = "ESP & FOV Color",
    })

-- ── 12. :OnChanged() ──────────────────────────────────────────────────────────

Toggles.SilentAim:OnChanged(function()
    cfg.silentAim = Toggles.SilentAim.Value
end)

Options.FovSize:OnChanged(function()
    cfg.fovSize = Options.FovSize.Value
end)

Options.MaxDistance:OnChanged(function()
    cfg.maxDistance = Options.MaxDistance.Value
end)

Toggles.FovCircle:OnChanged(function()
    cfg.fovCircleVisible = Toggles.FovCircle.Value
end)

Toggles.EspEnabled:OnChanged(function()
    cfg.espEnabled = Toggles.EspEnabled.Value
end)

Toggles.TracerEnabled:OnChanged(function()
    cfg.tracerEnabled = Toggles.TracerEnabled.Value
end)

Toggles.BoxEnabled:OnChanged(function()
    cfg.boxEnabled = Toggles.BoxEnabled.Value
end)

Toggles.CornerBoxEnabled:OnChanged(function()
    cfg.cornerBoxEnabled = Toggles.CornerBoxEnabled.Value
end)

Toggles.HealthBarEnabled:OnChanged(function()
    cfg.healthBarEnabled = Toggles.HealthBarEnabled.Value
end)

Toggles.HeadDotEnabled:OnChanged(function()
    cfg.headDotEnabled = Toggles.HeadDotEnabled.Value
end)

Toggles.DistanceEnabled:OnChanged(function()
    cfg.distanceEnabled = Toggles.DistanceEnabled.Value
end)

Toggles.HighlightEnabled:OnChanged(function()
    cfg.highlightEnabled = Toggles.HighlightEnabled.Value
end)

Options.EspColor:OnChanged(function()
    cfg.espColor = Options.EspColor.Value
    if fovCircle then fovCircle.Color = cfg.espColor end
    for _, esp in pairs(activeESP) do
        if esp.tracer       then esp.tracer.Color           = cfg.espColor end
        if esp.distanceText then esp.distanceText.Color     = cfg.espColor end
        if esp.highlight    then
            esp.highlight.FillColor    = cfg.espColor
            esp.highlight.OutlineColor = cfg.espColor
        end
        if esp.box     then esp.box.Color     = cfg.espColor end
        if esp.headDot then esp.headDot.Color = cfg.espColor end
        if esp.corners then
            for i = 1, 8 do esp.corners[i].Color = cfg.espColor end
        end
    end
end)

-- ── 13. UI Settings tab ───────────────────────────────────────────────────────
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default  = Library.KeybindFrame.Visible,
    Text     = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text     = "Custom Cursor",
    Default  = Library.ShowCustomCursor,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values   = { "Left", "Right" },
    Default  = "Right",
    Text     = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroup:AddDropdown("DPIDropdown", {
    Values   = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default  = "100%",
    Text     = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        Library:SetDPIScale(tonumber(Value))
    end,
})

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- ── 14. Addons ────────────────────────────────────────────────────────────────
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("Flick")
SaveManager:SetFolder("Flick/configs")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    print("Flick unloaded.")
end)