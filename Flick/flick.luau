local repo         = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local cfg = {
    silentAim   = false,
    fovSize     = 150,
    maxDistance = 500,

    fastReload = false,
    reloadSpeed = 0.1,

    rapidFire = false,
    fireRate = 0.05,

    noRecoil = false,
    autoFire = false,
    instantEquip = false,
    noGravity = false,

    espEnabled       = false,
    tracerEnabled    = false,
    distanceEnabled  = false,
    highlightEnabled = false,
    boxEnabled       = false,
    cornerBoxEnabled = false,
    healthBarEnabled = false,
    headDotEnabled   = false,

    fovCircleVisible = false,

    fovColor       = Color3.fromRGB(86, 245, 0),
    tracerColor    = Color3.fromRGB(255, 105, 180),
    boxColor       = Color3.fromRGB(255, 255, 255),
    cornerColor    = Color3.fromRGB(255, 105, 180),
    headDotColor   = Color3.fromRGB(255, 105, 180),
    distanceColor  = Color3.fromRGB(255, 255, 255),
    highlightColor = Color3.fromRGB(255, 105, 180),
}

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Camera        = workspace.CurrentCamera
local LocalPlayer   = Players.LocalPlayer
local BulletHandler = require(game:GetService("ReplicatedStorage").ModuleScripts.GunModules.BulletHandler)
local oldFire       = BulletHandler.Fire

local GunMods = {
    reloadTime = { Enabled = "fastReload",   Value = "reloadSpeed" },
    FireRate   = { Enabled = "rapidFire",    Value = "fireRate" },
    Recoil     = { Enabled = "noRecoil",     Static = Vector3.new(0, 0, 0) },
    isAuto     = { Enabled = "autoFire",     Static = true },
    EquipTime  = { Enabled = "instantEquip", Static = 0 },
    Gravity    = { Enabled = "noGravity",    Static = 0 },
}

local function applyGunMods(inst)
    if not inst:IsA("Tool") then return end

    for key, mod in pairs(GunMods) do
        local origKey = "__FlickOrig_" .. key

        if inst:GetAttribute(origKey) == nil and inst:GetAttribute(key) ~= nil then
            inst:SetAttribute(origKey, inst:GetAttribute(key))
        end

        if cfg[mod.Enabled] then
            inst:SetAttribute(key, mod.Static or cfg[mod.Value])
        else
            local orig = inst:GetAttribute(origKey)
            if orig ~= nil then
                inst:SetAttribute(key, orig)
            end
        end
    end
end

local function isFrameworkConfig(t)
    return type(t) == "table"
        and type(rawget(t, "reloadTime")) == "number"
        and (rawget(t, "Ammo") ~= nil or rawget(t, "FireRate") ~= nil or rawget(t, "spread") ~= nil)
end

local function patchConfig(t)
    if not isFrameworkConfig(t) then return end

    for key, mod in pairs(GunMods) do
        if rawget(t, key) == nil then
            continue
        end

        local origKey = "__FlickOrig_" .. key

        if rawget(t, origKey) == nil then
            rawset(t, origKey, t[key])
        end

        if cfg[mod.Enabled] then
            rawset(t, key, mod.Static or cfg[mod.Value])
        else
            rawset(t, key, rawget(t, origKey))
        end
    end
end

local function patchFrameworkConfig()
    local patched = false

    if filtergc then
        local ok = pcall(function()
            local r = filtergc("table", false, isFrameworkConfig)

            if type(r) == "table" then
                for _, t in ipairs(r) do
                    if isFrameworkConfig(t) then
                        patchConfig(t)
                        patched = true
                    end
                end
            end
        end)

        if not ok or not patched then
            pcall(function()
                local r = filtergc("table", isFrameworkConfig)

                if type(r) == "table" then
                    for _, t in ipairs(r) do
                        if isFrameworkConfig(t) then
                            patchConfig(t)
                            patched = true
                        end
                    end
                end
            end)
        end
    end

    if not patched and getgc then
        for _, obj in ipairs(getgc(true)) do
            if isFrameworkConfig(obj) then
                patchConfig(obj)
            end
        end
    end
end

local function updateEquippedGun()
    if LocalPlayer.Character then
        for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
            applyGunMods(item)
        end
    end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            applyGunMods(item)
        end
    end
    patchFrameworkConfig()
end

local function watchContainer(container)
    if not container then return end
    container.ChildAdded:Connect(applyGunMods)
    for _, item in ipairs(container:GetChildren()) do
        applyGunMods(item)
    end
end

local function watchPlayer(player)
    if player.Character then
        watchContainer(player.Character)
    end
    player.CharacterAdded:Connect(watchContainer)

    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        watchContainer(backpack)
    end
    player.ChildAdded:Connect(function(child)
        if child:IsA("Backpack") then
            watchContainer(child)
        end
    end)
end

watchPlayer(LocalPlayer)

local drawingWorks = pcall(function() return Drawing.new("Line") end)

local function getHealthColor(ratio)
    ratio = math.clamp(ratio, 0, 1)
    if ratio > 0.5 then
        return Color3.fromRGB(math.floor(255 * (1 - ratio) * 2), 255, 0)
    else
        return Color3.fromRGB(255, math.floor(255 * ratio * 2), 0)
    end
end

local activeESP = {}

local function createESP(player)
    if player == LocalPlayer then return end

    local tracer      = Drawing.new("Line")
    tracer.Color      = cfg.tracerColor
    tracer.Thickness  = 1

    local distanceText = drawingWorks and Drawing.new("Text") or nil
    if distanceText then
        distanceText.Color   = cfg.distanceColor
        distanceText.Size    = 13
        distanceText.Center  = true
        distanceText.Outline = true
    end

    local highlight = Instance.new("Highlight")
    highlight.FillColor           = cfg.highlightColor
    highlight.OutlineColor        = cfg.highlightColor
    highlight.FillTransparency    = 0.8
    highlight.OutlineTransparency = 0
    highlight.Parent              = game:GetService("CoreGui")

    local box      = Drawing.new("Square")
    box.Color      = cfg.boxColor
    box.Thickness  = 1
    box.Filled     = false

    local corners = {}
    for i = 1, 8 do
        corners[i]           = Drawing.new("Line")
        corners[i].Color     = cfg.cornerColor
        corners[i].Thickness = 1.5
    end

    local healthBg    = Drawing.new("Square")
    healthBg.Color    = Color3.fromRGB(0, 0, 0)
    healthBg.Filled   = true

    local healthFill  = Drawing.new("Square")
    healthFill.Filled = true

    local headDot      = Drawing.new("Circle")
    headDot.Color      = cfg.headDotColor
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

        local boxH = math.max(feetPos.Y - headPos.Y, 1)
        local boxW = boxH * 0.55
        local boxX = headPos.X - boxW / 2
        local boxY = headPos.Y

        tracer.From    = Vector2.new(Camera.ViewportSize.X / 2, 0)
        tracer.To      = Vector2.new(headPos.X, headPos.Y)
        tracer.Visible = cfg.espEnabled and cfg.tracerEnabled

        if distanceText then
            distanceText.Text     = math.floor(distance) .. " studs"
            distanceText.Position = Vector2.new(feetPos.X, feetPos.Y + 4)
            distanceText.Visible  = cfg.espEnabled and cfg.distanceEnabled
        end

        highlight.Adornee = character
        highlight.Enabled = cfg.espEnabled and cfg.highlightEnabled

        box.Position = Vector2.new(boxX, boxY)
        box.Size     = Vector2.new(boxW, boxH)
        box.Visible  = cfg.espEnabled and cfg.boxEnabled

        local cLen = math.min(boxW, boxH) * 0.25
        local cVis = cfg.espEnabled and cfg.cornerBoxEnabled

        corners[1].From = Vector2.new(boxX,        boxY);        corners[1].To = Vector2.new(boxX + cLen,        boxY)
        corners[2].From = Vector2.new(boxX,        boxY);        corners[2].To = Vector2.new(boxX,               boxY + cLen)
        corners[3].From = Vector2.new(boxX + boxW, boxY);        corners[3].To = Vector2.new(boxX + boxW - cLen, boxY)
        corners[4].From = Vector2.new(boxX + boxW, boxY);        corners[4].To = Vector2.new(boxX + boxW,        boxY + cLen)
        corners[5].From = Vector2.new(boxX,        boxY + boxH); corners[5].To = Vector2.new(boxX + cLen,        boxY + boxH)
        corners[6].From = Vector2.new(boxX,        boxY + boxH); corners[6].To = Vector2.new(boxX,               boxY + boxH - cLen)
        corners[7].From = Vector2.new(boxX + boxW, boxY + boxH); corners[7].To = Vector2.new(boxX + boxW - cLen, boxY + boxH)
        corners[8].From = Vector2.new(boxX + boxW, boxY + boxH); corners[8].To = Vector2.new(boxX + boxW,        boxY + boxH - cLen)

        for i = 1, 8 do corners[i].Visible = cVis end

        local hpRatio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
        local barX    = boxX - 6

        healthBg.Position = Vector2.new(barX, boxY)
        healthBg.Size     = Vector2.new(3, boxH)
        healthBg.Visible  = cfg.espEnabled and cfg.healthBarEnabled

        healthFill.Color    = getHealthColor(hpRatio)
        healthFill.Position = Vector2.new(barX, boxY + boxH * (1 - hpRatio))
        healthFill.Size     = Vector2.new(3, math.max(boxH * hpRatio, 1))
        healthFill.Visible  = cfg.espEnabled and cfg.healthBarEnabled

        headDot.Position = Vector2.new(headPos.X, headPos.Y)
        headDot.Visible  = cfg.espEnabled and cfg.headDotEnabled
    end)
end

for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
Players.PlayerAdded:Connect(createESP)

local fovCircle = drawingWorks and (function()
    local circle        = Drawing.new("Circle")
    circle.Color        = cfg.fovColor
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
}):AddColorPicker("FovColor", { Default = cfg.fovColor, Title = "FOV Circle Color" })

local GunBox = Tabs.Main:AddRightGroupbox("Gun Mods", "zap")

GunBox:AddToggle("FastReload", {
    Text    = "Fast Reload",
    Default = cfg.fastReload,
    Tooltip = "Overrides weapon reload duration",
})

GunBox:AddSlider("ReloadSpeed", {
    Text     = "Reload Time",
    Default  = cfg.reloadSpeed,
    Min      = 0,
    Max      = 3,
    Rounding = 2,
    Suffix   = "s",
    Tooltip  = "Set target reload duration in seconds",
})

GunBox:AddToggle("RapidFire", {
    Text    = "Rapid Fire",
    Default = cfg.rapidFire,
    Tooltip = "Overrides weapon fire rate",
})

GunBox:AddSlider("FireRate", {
    Text     = "Fire Rate",
    Default  = cfg.fireRate,
    Min      = 0.01,
    Max      = 0.5,
    Rounding = 2,
    Suffix   = "s",
    Tooltip  = "Seconds between shots (lower = faster)",
})

GunBox:AddToggle("NoRecoil", {
    Text    = "No Recoil",
    Default = cfg.noRecoil,
    Tooltip = "Removes camera kick and viewmodel recoil",
})

GunBox:AddToggle("AutoFire", {
    Text    = "Auto Fire",
    Default = cfg.autoFire,
    Tooltip = "Forces all guns to be full-auto",
})

GunBox:AddToggle("InstantEquip", {
    Text    = "Instant Equip",
    Default = cfg.instantEquip,
    Tooltip = "Removes weapon equip/switching time",
})

GunBox:AddToggle("NoGravity", {
    Text    = "No Bullet Gravity",
    Default = cfg.noGravity,
    Tooltip = "Bullets fly in a flat line",
})
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
}):AddColorPicker("TracerColor", { Default = cfg.tracerColor, Title = "Tracer Color" })
EspBox:AddToggle("BoxEnabled", {
    Text    = "Box",
    Default = cfg.boxEnabled,
    Tooltip = "Full 2D bounding box around enemy",
}):AddColorPicker("BoxColor", { Default = cfg.boxColor, Title = "Box Color" })
EspBox:AddToggle("CornerBoxEnabled", {
    Text    = "Corner Box",
    Default = cfg.cornerBoxEnabled,
    Tooltip = "Corner-style bounding box around enemy",
}):AddColorPicker("CornerColor", { Default = cfg.cornerColor, Title = "Corner Color" })
EspBox:AddToggle("HealthBarEnabled", {
    Text    = "Health Bar",
    Default = cfg.healthBarEnabled,
    Tooltip = "Vertical health bar left of the box (green → red)",
})

EspBox:AddToggle("HeadDotEnabled", {
    Text    = "Head Dot",
    Default = cfg.headDotEnabled,
    Tooltip = "Filled dot at the enemy head position",
}):AddColorPicker("HeadDotColor", { Default = cfg.headDotColor, Title = "Head Dot Color" })
EspBox:AddToggle("DistanceEnabled", {
    Text    = "Distance",
    Default = cfg.distanceEnabled,
    Tooltip = "Distance label below the enemy's feet",
}):AddColorPicker("DistanceColor", { Default = cfg.distanceColor, Title = "Distance Color" })
EspBox:AddToggle("HighlightEnabled", {
    Text    = "Chams",
    Default = cfg.highlightEnabled,
    Tooltip = "Highlight / glow on enemy models",
}):AddColorPicker("HighlightColor", { Default = cfg.highlightColor, Title = "Chams Color" })
Toggles.SilentAim:OnChanged(function()
    cfg.silentAim = Toggles.SilentAim.Value
end)

Toggles.FastReload:OnChanged(function()
    cfg.fastReload = Toggles.FastReload.Value
    updateEquippedGun()
end)

Options.ReloadSpeed:OnChanged(function()
    cfg.reloadSpeed = Options.ReloadSpeed.Value
    updateEquippedGun()
end)

Toggles.RapidFire:OnChanged(function()
    cfg.rapidFire = Toggles.RapidFire.Value
    updateEquippedGun()
end)

Options.FireRate:OnChanged(function()
    cfg.fireRate = Options.FireRate.Value
    updateEquippedGun()
end)

Toggles.NoRecoil:OnChanged(function()
    cfg.noRecoil = Toggles.NoRecoil.Value
    updateEquippedGun()
end)

Toggles.AutoFire:OnChanged(function()
    cfg.autoFire = Toggles.AutoFire.Value
    updateEquippedGun()
end)

Toggles.InstantEquip:OnChanged(function()
    cfg.instantEquip = Toggles.InstantEquip.Value
    updateEquippedGun()
end)

Toggles.NoGravity:OnChanged(function()
    cfg.noGravity = Toggles.NoGravity.Value
    updateEquippedGun()
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

Options.FovColor:OnChanged(function()
    cfg.fovColor = Options.FovColor.Value
    if fovCircle then fovCircle.Color = cfg.fovColor end
end)

Toggles.EspEnabled:OnChanged(function()
    cfg.espEnabled = Toggles.EspEnabled.Value
end)

Toggles.TracerEnabled:OnChanged(function()
    cfg.tracerEnabled = Toggles.TracerEnabled.Value
end)

Options.TracerColor:OnChanged(function()
    cfg.tracerColor = Options.TracerColor.Value
    for _, esp in pairs(activeESP) do
        if esp.tracer then esp.tracer.Color = cfg.tracerColor end
    end
end)

Toggles.BoxEnabled:OnChanged(function()
    cfg.boxEnabled = Toggles.BoxEnabled.Value
end)

Options.BoxColor:OnChanged(function()
    cfg.boxColor = Options.BoxColor.Value
    for _, esp in pairs(activeESP) do
        if esp.box then esp.box.Color = cfg.boxColor end
    end
end)

Toggles.CornerBoxEnabled:OnChanged(function()
    cfg.cornerBoxEnabled = Toggles.CornerBoxEnabled.Value
end)

Options.CornerColor:OnChanged(function()
    cfg.cornerColor = Options.CornerColor.Value
    for _, esp in pairs(activeESP) do
        if esp.corners then
            for i = 1, 8 do esp.corners[i].Color = cfg.cornerColor end
        end
    end
end)

Toggles.HealthBarEnabled:OnChanged(function()
    cfg.healthBarEnabled = Toggles.HealthBarEnabled.Value
end)

Toggles.HeadDotEnabled:OnChanged(function()
    cfg.headDotEnabled = Toggles.HeadDotEnabled.Value
end)

Options.HeadDotColor:OnChanged(function()
    cfg.headDotColor = Options.HeadDotColor.Value
    for _, esp in pairs(activeESP) do
        if esp.headDot then esp.headDot.Color = cfg.headDotColor end
    end
end)

Toggles.DistanceEnabled:OnChanged(function()
    cfg.distanceEnabled = Toggles.DistanceEnabled.Value
end)

Options.DistanceColor:OnChanged(function()
    cfg.distanceColor = Options.DistanceColor.Value
    for _, esp in pairs(activeESP) do
        if esp.distanceText then esp.distanceText.Color = cfg.distanceColor end
    end
end)

Toggles.HighlightEnabled:OnChanged(function()
    cfg.highlightEnabled = Toggles.HighlightEnabled.Value
end)

Options.HighlightColor:OnChanged(function()
    cfg.highlightColor = Options.HighlightColor.Value
    for _, esp in pairs(activeESP) do
        if esp.highlight then
            esp.highlight.FillColor = cfg.highlightColor
            esp.highlight.OutlineColor = cfg.highlightColor
        end
    end
end)

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

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("Flick")
SaveManager:SetFolder("ASTROFLICK/configs")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    print("Flick unloaded.")
end)
