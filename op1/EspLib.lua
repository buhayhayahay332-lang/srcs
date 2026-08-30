pcall(function() setthreadidentity(8) end)
pcall(function() game:GetService("WebViewService"):Destroy() end)

local cloneref = cloneref or function(o) return o end

local Workspace  = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local Players    = cloneref(game:GetService("Players"))
local CoreGui    = cloneref(game:GetService("CoreGui"))
local GuiService = cloneref(game:GetService("GuiService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local TextService = cloneref(game:GetService("TextService"))

local PingObjectTemplate = ReplicatedStorage:FindFirstChild("Modules", true)
    and ReplicatedStorage.Modules:FindFirstChild("Effects")
    and ReplicatedStorage.Modules.Effects:FindFirstChild("PingObject")

local LocalPlayer = Players.LocalPlayer

local Global = getgenv and getgenv() or _G
if Global.__rage_radar_cleanup then
    pcall(Global.__rage_radar_cleanup)
end

local RadarState = {
    Drawings = {},
    Dots = {},
    Rings = {},
    Cardinals = {},
    ObjectLabels = {},
    Connections = {},
    Yaw = 0,
}

Global.__rage_radar_cleanup = function()
    for _, connection in ipairs(RadarState.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    for _, drawing in pairs(RadarState.Dots) do
        for _, obj in pairs(drawing) do
            pcall(function()
                obj:Remove()
            end)
        end
    end

    for _, drawing in pairs(RadarState.Rings) do
        pcall(function()
            drawing:Remove()
        end)
    end

    for _, drawing in pairs(RadarState.Cardinals) do
        pcall(function()
            drawing:Remove()
        end)
    end

    for _, drawing in pairs(RadarState.ObjectLabels) do
        pcall(function()
            drawing:Remove()
        end)
    end

    for _, drawing in ipairs(RadarState.Drawings) do
        pcall(function()
            drawing:Remove()
        end)
    end

    table.clear(RadarState.Connections)
    table.clear(RadarState.Dots)
    table.clear(RadarState.Rings)
    table.clear(RadarState.Cardinals)
    table.clear(RadarState.ObjectLabels)
    table.clear(RadarState.Drawings)
    RadarState.Yaw = 0
end

local ESP = {
    Enabled     = false,
    MaxDistance = 1000,
    FontSize    = 11,
    FadeOut = {
        OnDistance = false,
        OnDeath    = false,
        OnLeave    = false,
    },
    Drawing = {
        Chams = {
            Enabled              = false,
            Thermal              = false,
            FillRGB              = Color3.fromRGB(243, 116, 166),
            Fill_Transparency    = 50,
            OutlineRGB           = Color3.fromRGB(243, 116, 166),
            Outline_Transparency = 50,
            VisibleCheck         = false,
        },
        HealthBar = {
            Enabled = false,
        },
        Names = {
            Enabled = false,
            RGB     = Color3.fromRGB(255, 255, 255),
        },
        Distances = {
            Enabled = false,
            RGB     = Color3.fromRGB(255, 255, 255),
        },
        Weapons = {
            Enabled = false,
            RGB     = Color3.fromRGB(255, 255, 255),
            IconEnabled = false,
            IconSize = 40,
        },
        Boxes = {
            Animate          = false,
            RotationSpeed    = 300,
            Gradient         = true,
            GradientRGB1     = Color3.fromRGB(255, 255, 255),
            GradientRGB2     = Color3.fromRGB(0, 0, 0),
            GradientFill     = true,
            GradientFillRGB1 = Color3.fromRGB(255, 255, 255),
            GradientFillRGB2 = Color3.fromRGB(0, 0, 0),
            Filled = {
                Enabled      = false,
                Transparency = 0.75,
                RGB          = Color3.fromRGB(0, 0, 0),
            },
            Full = {
                Enabled = false,
                RGB     = Color3.fromRGB(255, 255, 255),
            },
            Corner = {
                Enabled   = false,
                RGB       = Color3.fromRGB(255, 255, 255),
                Thickness = 1,
                Length    = 15,
            },
        },
        Skeleton = {
            Enabled   = false,
            RGB       = Color3.fromRGB(255, 255, 255),
            Thickness = 1,
        },
        Tracers = {
            Enabled      = false,
            RGB          = Color3.fromRGB(255, 255, 255),
            Origin       = "Bottom",
            Thickness    = 1,
            Transparency = 1,
        },
        OffscreenArrows = {
            Enabled          = false,
            RGB              = Color3.fromRGB(255, 255, 255),
            Size             = 10,
            ShowDistance     = true,
            DistanceRGB      = Color3.fromRGB(255, 255, 255),
            DistanceFontSize = 12,
            Origin           = "Bottom",
            Thickness    = 1,
            Transparency = 1,
        },
        TeamCheck = {
            Enabled = false,
        },
    },
    Radar = {
        Enabled = true,
        Lines = true,
        LineDistance = 50,
        Scale = 1,
        Radius = 120,
        Range = 300,
        Position = Vector2.new(170, 170),
        Rotation = false,
        SmoothRot = true,
        SmoothRotAmnt = 30,
        CardinalDisplay = true,
        ShowOffscreen = true,
        DisplayTeammates = false,
        DisplayTeamColors = true,
        DisplayFriendColors = true,
        DisplayRGBColors = false,
        MarkerSize = 2,
        MarkerScaleBase = 1,
        MarkerScaleMax = 1,
        MarkerScaleMin = 0.75,
        MarkerFalloff = true,
        MarkerFalloffAmnt = 125,
        OffscreenTransparency = 0.3,
        UseFallback = false,
        UseQuads = true,
        UseTeamColors = false,
        VisibilityCheck = false,
        SelfDotSize = 2,
        Theme = {
            Outline = Color3.fromRGB(35, 35, 45),
            Background = Color3.fromRGB(25, 25, 35),
            DragHandle = Color3.fromRGB(50, 50, 255),
            Cardinal_Lines = Color3.fromRGB(110, 110, 120),
            Distance_Lines = Color3.fromRGB(65, 65, 75),
            Generic_Marker = Color3.fromRGB(255, 25, 115),
            Local_Marker = Color3.fromRGB(115, 25, 255),
            Team_Marker = Color3.fromRGB(25, 115, 255),
            Friend_Marker = Color3.fromRGB(25, 255, 115),
        },
    },
    ObjectChams = {
        RenderMethod = "Icon",
        Names = {
            Enabled = false,
            RGB = Color3.fromRGB(255, 255, 255),
        },
        Drones = {
            Enabled      = false,
            FillRGB      = Color3.fromRGB(255, 200, 0),
            FillTrans    = 0.5,
            OutlineRGB   = Color3.fromRGB(255, 200, 0),
            OutlineTrans = 0,
        },
        Claymores = {
            Enabled      = false,
            FillRGB      = Color3.fromRGB(255, 50, 50),
            FillTrans    = 0.5,
            OutlineRGB   = Color3.fromRGB(255, 50, 50),
            OutlineTrans = 0,
        },
        ProximityAlarm = {
        Enabled = false, FillRGB = Color3.fromRGB(255, 150, 0),
        FillTrans = 0.5, OutlineRGB = Color3.fromRGB(255, 150, 0), OutlineTrans = 0,
        },
        StickyCamera = {
            Enabled = false, FillRGB = Color3.fromRGB(0, 200, 255),
            FillTrans = 0.5, OutlineRGB = Color3.fromRGB(0, 200, 255), OutlineTrans = 0,
        },
        RemoteC4 = {
            Enabled = false, FillRGB = Color3.fromRGB(255, 50, 50),
            FillTrans = 0.5, OutlineRGB = Color3.fromRGB(255, 50, 50), OutlineTrans = 0,
        },
        ThermiteCharge = {
            Enabled = false, FillRGB = Color3.fromRGB(255, 120, 0),
            FillTrans = 0.5, OutlineRGB = Color3.fromRGB(255, 120, 0), OutlineTrans = 0,
        },
        ToxicCharge = {
            Enabled = false, FillRGB = Color3.fromRGB(80, 255, 80),
            FillTrans = 0.5, OutlineRGB = Color3.fromRGB(80, 255, 80), OutlineTrans = 0,
        },
        BreachCharge = {
            Enabled = false, FillRGB = Color3.fromRGB(255, 80, 80),
            FillTrans = 0.5, OutlineRGB = Color3.fromRGB(255, 80, 80), OutlineTrans = 0,
        },
        HardBreachCharge = {
            Enabled = false, FillRGB = Color3.fromRGB(200, 80, 255),
            FillTrans = 0.5, OutlineRGB = Color3.fromRGB(200, 80, 255), OutlineTrans = 0,
        },
        ShockBattery = {
            Enabled = false, FillRGB = Color3.fromRGB(255, 255, 0),
            FillTrans = 0.5, OutlineRGB = Color3.fromRGB(255, 255, 0), OutlineTrans = 0,
        },
        DeployableShield = {
            Enabled = false, FillRGB = Color3.fromRGB(100, 180, 255),
            FillTrans = 0.5, OutlineRGB = Color3.fromRGB(100, 180, 255), OutlineTrans = 0,
        },
        BarbedWire = {
            Enabled = false, FillRGB = Color3.fromRGB(180, 140, 80),
            FillTrans = 0.5, OutlineRGB = Color3.fromRGB(180, 140, 80), OutlineTrans = 0,
        },
        SignalDisruptor = {
            Enabled = false, FillRGB = Color3.fromRGB(80, 80, 255),
            FillTrans = 0.5, OutlineRGB = Color3.fromRGB(80, 80, 255), OutlineTrans = 0,
        },
        BulletproofCamera = {
            Enabled = false, FillRGB = Color3.fromRGB(0, 255, 200),
            FillTrans = 0.5, OutlineRGB = Color3.fromRGB(0, 255, 200), OutlineTrans = 0,
        },
        NeedleMine = {
            Enabled      = false,
            FillRGB      = Color3.fromRGB(192, 192, 192),
            FillTrans    = 0.5,
            OutlineRGB   = Color3.fromRGB(192, 192, 192),
            OutlineTrans = 0,
        },
        Camera = {
            Enabled      = false,
            FillRGB      = Color3.fromRGB(100, 100, 100),
            FillTrans    = 0.5,
            OutlineRGB   = Color3.fromRGB(100, 100, 100),
            OutlineTrans = 0,
        },
    },
}

local function attachObjectNameConfig(cfg)
    cfg.Name = cfg.Name or {
        Enabled = false,
        RGB = Color3.fromRGB(255, 255, 255),
    }
end

for _, key in ipairs({
    "Drones",
    "Claymores",
    "ProximityAlarm",
    "StickyCamera",
    "RemoteC4",
    "ThermiteCharge",
    "ToxicCharge",
    "BreachCharge",
    "HardBreachCharge",
    "ShockBattery",
    "DeployableShield",
    "BarbedWire",
    "SignalDisruptor",
    "BulletproofCamera",
    "NeedleMine",
    "Camera",
}) do
    attachObjectNameConfig(ESP.ObjectChams[key])
end

local Radar = ESP.Radar
Global.RadarSettings = Radar

local BONE_CONNECTIONS = {
    { "torso", "shoulder1" }, { "torso", "shoulder2" },
    { "torso", "hip1" },      { "torso", "hip2" },
    { "torso", "head" },
    { "shoulder1", "arm1" },  { "shoulder2", "arm2" },
    { "hip1", "leg1" },       { "hip2", "leg2" },
}


local ESPCounter         = 0
local ActiveESPs         = {}
local ActiveSkeletons    = {}
local TeamHighlightCache = {}
local ActiveObjectChams  = {}
local MasterConnection   = nil

local _Camera    = nil
local _CamPos    = nil
local _ViewSize  = nil
local _Tick      = nil
local _GuiInsetY = 0
local ScreenGui  = nil

local _Viewmodels = nil
local WeaponIconCache = {}
local WeaponIconCacheBuilt = false

local ActiveNames = {}

local VMtoChar             = {}
local CharToVM             = {}
local _proxyCacheDirty     = true
local _frameCount          = 0
local _lastCharRescan      = 0
local PROXY_REFRESH_INTERVAL = 30

local RealCharacterSet = {}

local _cb = {}
for i = 1, 8 do _cb[i] = Vector3.new() end

local function getRealPlayerFromCharacter(character)
    if not character then
        return nil
    end

    if typeof(character) ~= "Instance" or not character.GetAttribute then
        return nil
    end

    local id = character:GetAttribute("UserId") or character:GetAttribute("ID")
    if typeof(id) == "number" then
        return Players:GetPlayerByUserId(id)
    end
    return nil
end

local function isRealCharacter(model)
    if not model or not model:IsA("Model") then return false end
    if model.Archivable ~= false then return false end
    if model.Name == "LocalViewmodel" then return false end
    local id = model:GetAttribute("UserId") or model:GetAttribute("ID")
    if typeof(id) ~= "number" then return false end
    if id == LocalPlayer.UserId then return false end
    local hum  = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 then return false end
    if not root then return false end
    return true
end

local function markProxyCacheDirty()
    _proxyCacheDirty = true
end

local function rebuildProxyCache()
    VMtoChar = {}
    CharToVM = {}
    if not _Viewmodels then
        _proxyCacheDirty = false
        return
    end

    local chars = {}
    for character in pairs(RealCharacterSet) do
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            chars[#chars + 1] = { model = character, pos = root.Position }
        end
    end

    if #chars == 0 then
        _proxyCacheDirty = false
        return
    end

    for _, vm in pairs(_Viewmodels:GetChildren()) do
        local vmTorso = vm:FindFirstChild("torso")
        if vmTorso then
            local bestChar, bestDist = nil, math.huge
            local vmPos = vmTorso.Position
            for _, cd in ipairs(chars) do
                local d = (cd.pos - vmPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestChar = cd.model
                end
            end
            if bestChar and bestDist < 10 then
                VMtoChar[vm]       = bestChar
                CharToVM[bestChar] = vm
            end
        end
    end

    _proxyCacheDirty = false
end

local function getProjectedModelBounds(model)
    if not model then return nil end
    local minX, minY =  math.huge,  math.huge
    local maxX, maxY = -math.huge, -math.huge
    local any = false

    local head  = model:FindFirstChild("head")
    local torso = model:FindFirstChild("torso")

    local heightParts = {
        head, torso,
        model:FindFirstChild("hip1"),
        model:FindFirstChild("hip2"),
        model:FindFirstChild("leg1"),
        model:FindFirstChild("leg2"),
    }

    for _, d in ipairs(heightParts) do
        if d and d:IsA("BasePart") and d.Transparency < 1 then
            local cf   = d.CFrame
            local half = d.Size * 0.5
            local hx, hy, hz = half.X, half.Y, half.Z
            local isWidth = (d == head or d == torso)

            _cb[1] = cf * Vector3.new(-hx, -hy, -hz)
            _cb[2] = cf * Vector3.new(-hx, -hy,  hz)
            _cb[3] = cf * Vector3.new(-hx,  hy, -hz)
            _cb[4] = cf * Vector3.new(-hx,  hy,  hz)
            _cb[5] = cf * Vector3.new( hx, -hy, -hz)
            _cb[6] = cf * Vector3.new( hx, -hy,  hz)
            _cb[7] = cf * Vector3.new( hx,  hy, -hz)
            _cb[8] = cf * Vector3.new( hx,  hy,  hz)

            for i = 1, 8 do
                local p, on = _Camera:WorldToViewportPoint(_cb[i])
                if on and p.Z > 0 then
                    any = true
                    if p.Y < minY then minY = p.Y end
                    if p.Y > maxY then maxY = p.Y end
                    if isWidth then
                        if p.X < minX then minX = p.X end
                        if p.X > maxX then maxX = p.X end
                    end
                end
            end
        end
    end

    if minX == math.huge or maxX == -math.huge then
        if torso and torso:IsA("BasePart") then
            local p, on = _Camera:WorldToViewportPoint(torso.Position)
            if on and p.Z > 0 then
                minX = p.X - 8
                maxX = p.X + 8
            end
        end
    end

    if not any then return nil end
    return minX, minY, maxX, maxY
end

local function getRadarRoot(model)
    if not model then
        return nil
    end

    return model:FindFirstChild("torso")
        or model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
end

local function getLocalRadarRoot()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("torso")
        or character.PrimaryPart
end

local radarBackground = Drawing.new("Circle")
radarBackground.Filled = true
radarBackground.Thickness = 1
radarBackground.NumSides = 100
radarBackground.Radius = Radar.Radius
radarBackground.Color = Radar.Theme.Background
radarBackground.Transparency = 0.72
radarBackground.Visible = Radar.Enabled
radarBackground.ZIndex = 990
table.insert(RadarState.Drawings, radarBackground)

local radarOutline = Drawing.new("Circle")
radarOutline.Filled = false
radarOutline.Thickness = 1
radarOutline.NumSides = 100
radarOutline.Radius = Radar.Radius
radarOutline.Color = Radar.Theme.Outline
radarOutline.Transparency = 1
radarOutline.Visible = Radar.Enabled
radarOutline.ZIndex = 991
table.insert(RadarState.Drawings, radarOutline)

local radarCrossH = Drawing.new("Line")
radarCrossH.Color = Radar.Theme.Cardinal_Lines
radarCrossH.Thickness = 1
radarCrossH.Transparency = 0.7
radarCrossH.Visible = Radar.Enabled
radarCrossH.ZIndex = 991
table.insert(RadarState.Drawings, radarCrossH)

local radarCrossV = Drawing.new("Line")
radarCrossV.Color = Radar.Theme.Cardinal_Lines
radarCrossV.Thickness = 1
radarCrossV.Transparency = 0.7
radarCrossV.Visible = Radar.Enabled
radarCrossV.ZIndex = 991
table.insert(RadarState.Drawings, radarCrossV)

local radarSelf = Drawing.new("Circle")
radarSelf.Filled = true
radarSelf.Thickness = 1
radarSelf.NumSides = 100
radarSelf.Radius = Radar.SelfDotSize
radarSelf.Color = Radar.Theme.Local_Marker
radarSelf.Transparency = 1
radarSelf.Visible = Radar.Enabled
radarSelf.ZIndex = 992
table.insert(RadarState.Drawings, radarSelf)

local radarSelfQuad = Drawing.new("Quad")
radarSelfQuad.Filled = true
radarSelfQuad.Thickness = 1
radarSelfQuad.Transparency = 1
radarSelfQuad.Visible = false
radarSelfQuad.ZIndex = 992
table.insert(RadarState.Drawings, radarSelfQuad)

local function getRadarRing(index)
    local ring = RadarState.Rings[index]
    if ring then
        return ring
    end

    ring = Drawing.new("Circle")
    ring.Filled = false
    ring.Thickness = 1
    ring.NumSides = 100
    ring.Visible = false
    ring.ZIndex = 989
    RadarState.Rings[index] = ring
    table.insert(RadarState.Drawings, ring)
    return ring
end

local function getRadarCardinal(name)
    local item = RadarState.Cardinals[name]
    if item then
        return item
    end

    item = Drawing.new("Text")
    item.Center = true
    item.Outline = true
    item.Font = Drawing.Fonts.UI
    item.Size = 16
    item.Color = Radar.Theme.Cardinal_Lines
    item.Transparency = 1
    item.Visible = false
    item.ZIndex = 992
    RadarState.Cardinals[name] = item
    table.insert(RadarState.Drawings, item)
    return item
end

local RadarQuadA = Vector2.new(0, 5)
local RadarQuadB = Vector2.new(4, -5)
local RadarQuadC = Vector2.new(0, -3)
local RadarQuadD = Vector2.new(-4, -5)

local function rotate2D(vec, radians)
    local s = math.sin(radians)
    local c = math.cos(radians)
    return Vector2.new(
        (vec.X * c) - (vec.Y * s),
        (vec.X * s) + (vec.Y * c)
    )
end

local function projectRadarQuad(center, angle, scale)
    local s = math.sin(angle)
    local c = math.cos(angle)
    local function project(vec)
        vec = vec * scale
        return center + Vector2.new(
            (vec.X * s) - (vec.Y * c),
            (vec.X * c) + (vec.Y * s)
        )
    end

    return project(RadarQuadA), project(RadarQuadB), project(RadarQuadC), project(RadarQuadD)
end

local function dropRadarDot(model)
    local dot = RadarState.Dots[model]
    if not dot then
        return
    end

    RadarState.Dots[model] = nil
    for _, obj in pairs(dot) do
        pcall(function()
            obj:Remove()
        end)
    end
end

local function dropObjectLabel(instance)
    local label = RadarState.ObjectLabels[instance]
    if not label then
        return
    end

    RadarState.ObjectLabels[instance] = nil
    local idx = table.find(RadarState.Drawings, label)
    if idx then
        table.remove(RadarState.Drawings, idx)
    end
    pcall(function()
        label:Remove()
    end)
end

local function IsPlayerVisible(player)
    local character = player and player.Character
    local localCharacter = LocalPlayer.Character

    if not character or not localCharacter then
        return false
    end

    local targetRoot = getRadarRoot(character)
    if not targetRoot then
        return false
    end

    local origin = _Camera and _Camera.CFrame.Position or Workspace.CurrentCamera.CFrame.Position
    local direction = targetRoot.Position - origin
    if direction.Magnitude <= 0 then
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { localCharacter, character }

    local hit = Workspace:Raycast(origin, direction, params)
    return not hit or (hit.Position - targetRoot.Position).Magnitude <= 4
end

local function getRadarDot(model)
    local dot = RadarState.Dots[model]
    if dot then
        return dot
    end

    dot = {
        Circle = Drawing.new("Circle"),
        Quad = Drawing.new("Quad"),
    }

    dot.Circle.Filled = true
    dot.Circle.Thickness = 1
    dot.Circle.NumSides = 100
    dot.Circle.Radius = 4
    dot.Circle.Transparency = 1
    dot.Circle.Visible = false
    dot.Circle.ZIndex = 992

    dot.Quad.Filled = true
    dot.Quad.Thickness = 1
    dot.Quad.Transparency = 1
    dot.Quad.Visible = false
    dot.Quad.ZIndex = 992

    RadarState.Dots[model] = dot
    return dot
end

local function getObjectWorldPosition(instance)
    if not instance or not instance.Parent then
        return nil
    end

    if instance:IsA("BasePart") then
        return instance.Position
    end

    if instance:IsA("Model") then
        local ok, pivot = pcall(function()
            return instance:GetPivot()
        end)
        if ok and pivot then
            return pivot.Position
        end
    end

    local part = instance:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local GADGET_INFO = {
    Drone             = { Label = "Drone",               Icon = "rbxassetid://95428092249797" }, 
    Claymore          = { Label = "Claymore",            Icon = "rbxassetid://102628388684642" },
    ProximityAlarm    = { Label = "Proximity Alarm",     Icon = "rbxassetid://76330539011115" },
    StickyCamera      = { Label = "Sticky Camera",       Icon = "rbxassetid://107359883904453" },
    RemoteC4          = { Label = "Remote C4",           Icon = "rbxassetid://131938694361268" },
    ThermiteCharge    = { Label = "Thermite Charge",     Icon = "rbxassetid://130204034174754" },
    ToxicCharge       = { Label = "Toxic Charge",        Icon = "rbxassetid://94193535674650" },
    BreachCharge      = { Label = "Breach Charge",       Icon = "rbxassetid://107017238142850" },
    HardBreachCharge  = { Label = "Hard Breach Charge",  Icon = "rbxassetid://119785964628667" },
    ShockBattery      = { Label = "Shock Battery",       Icon = "rbxassetid://129045443792853" },
    DeployableShield  = { Label = "Deployable Shield",   Icon = "rbxassetid://125536230549191" },
    BarbedWire        = { Label = "Barbed Wire",         Icon = "rbxassetid://77385693201523" },
    SignalDisruptor   = { Label = "Signal Disruptor",    Icon = "rbxassetid://92127801205903" },
    BulletproofCamera = { Label = "Bulletproof Camera",  Icon = "rbxassetid://125200694361348" },
    NeedleMine        = { Label = "Needle Mine",         Icon = "rbxassetid://111112827848120" },
    Camera            = { Label = "Camera",              Icon = "rbxassetid://70956972762553" },
}

local function getObjectLabelText(name)
    return (GADGET_INFO[name] and GADGET_INFO[name].Label) or name
end

local function getObjectLabel(instance)
    local label = RadarState.ObjectLabels[instance]
    if label then
        return label
    end

    label = Drawing.new("Text")
    label.Center = true
    label.Outline = true
    label.Font = Drawing.Fonts.UI
    label.Size = 14
    label.Transparency = 1
    label.Visible = false
    label.ZIndex = 993
    RadarState.ObjectLabels[instance] = label
    table.insert(RadarState.Drawings, label)
    return label
end

local function updateRadar(deltaTime)
    if not Radar.Enabled then
        radarBackground.Visible = false
        radarOutline.Visible = false
        radarCrossH.Visible = false
        radarCrossV.Visible = false
        radarSelf.Visible = false
        radarSelfQuad.Visible = false

        for _, dot in pairs(RadarState.Dots) do
            dot.Circle.Visible = false
            dot.Quad.Visible = false
        end
        for _, ring in pairs(RadarState.Rings) do
            ring.Visible = false
        end
        for _, text in pairs(RadarState.Cardinals) do
            text.Visible = false
        end
        return
    end

    local root = getLocalRadarRoot()
    if not root or not _Camera then
        radarBackground.Visible = false
        radarOutline.Visible = false
        radarCrossH.Visible = false
        radarCrossV.Visible = false
        radarSelf.Visible = false
        radarSelfQuad.Visible = false
        for _, dot in pairs(RadarState.Dots) do
            dot.Circle.Visible = false
            dot.Quad.Visible = false
        end
        return
    end

    local center = Radar.Position
    local radius = Radar.Radius
    local mapRadius = radius * Radar.Scale
    local look = _Camera.CFrame.LookVector
    local targetYaw = math.atan2(look.X, look.Z)
    local camAngle = math.pi

    if Radar.Rotation then
        if Radar.SmoothRot then
            local currentYaw = RadarState.Yaw
            local alpha = 1 - math.exp(-Radar.SmoothRotAmnt * math.max(deltaTime or 0, 0))
            RadarState.Yaw = currentYaw + ((targetYaw - currentYaw) * alpha)
        else
            RadarState.Yaw = targetYaw
        end
        camAngle = RadarState.Yaw
    else
        RadarState.Yaw = math.pi
    end

    local rad90 = math.rad(90)
    local rad180 = math.rad(180)
    local sinYaw = math.sin(-camAngle)
    local cosYaw = math.cos(-camAngle)
    local rotate = function(vec)
        return Vector2.new(
            (vec.X * cosYaw) - (vec.Y * sinYaw),
            (vec.X * sinYaw) + (vec.Y * cosYaw)
        )
    end

    local function getQuadAngle(lookVec)
        return math.atan2(lookVec.X, lookVec.Z) - camAngle - rad90
    end

    radarBackground.Visible = true
    radarOutline.Visible = true
    radarSelf.Visible = true

    radarBackground.Position = center
    radarBackground.Radius = radius
    radarBackground.Color = Radar.Theme.Background
    radarOutline.Position = center
    radarOutline.Radius = radius
    radarOutline.Color = Radar.Theme.Outline
    radarSelf.Position = center
    radarSelf.Radius = Radar.SelfDotSize
    radarSelf.Color = Radar.Theme.Local_Marker
    radarSelfQuad.Visible = false

    radarCrossH.Color = Radar.Theme.Cardinal_Lines
    radarCrossV.Color = Radar.Theme.Cardinal_Lines
    radarCrossH.Visible = Radar.Lines
    radarCrossV.Visible = Radar.Lines

    if Radar.Lines then
        local left = center + rotate(Vector2.new(-radius, 0))
        local right = center + rotate(Vector2.new(radius, 0))
        local top = center + rotate(Vector2.new(0, -radius))
        local bottom = center + rotate(Vector2.new(0, radius))

        radarCrossH.From = left
        radarCrossH.To = right
        radarCrossV.From = top
        radarCrossV.To = bottom

        local ringCount = math.max(0, math.floor(Radar.Range / math.max(Radar.LineDistance, 1)))
        for i = 1, ringCount do
            local ring = getRadarRing(i)
            local dist = i * Radar.LineDistance
            ring.Position = center
            ring.Radius = (dist / math.max(Radar.Range, 1)) * mapRadius
            ring.Color = Radar.Theme.Distance_Lines
            ring.Transparency = 0.55
            ring.Visible = true
        end
        for i, ring in pairs(RadarState.Rings) do
            if i > ringCount then
                ring.Visible = false
            end
        end

        if Radar.CardinalDisplay then
            local north = getRadarCardinal("N")
            local east = getRadarCardinal("E")
            local south = getRadarCardinal("S")
            local west = getRadarCardinal("W")

            north.Text = "N"
            east.Text = "E"
            south.Text = "S"
            west.Text = "W"

            local labelPad = 16
            local function pushOut(point)
                local delta = point - center
                if delta.Magnitude <= 0 then
                    return point
                end
                return center + delta.Unit * (radius + labelPad)
            end

            north.Position = pushOut(top)
            east.Position = pushOut(right)
            south.Position = pushOut(bottom)
            west.Position = pushOut(left)

            for _, text in pairs(RadarState.Cardinals) do
                text.Color = Radar.Theme.Cardinal_Lines
                text.Visible = true
            end
        else
            for _, text in pairs(RadarState.Cardinals) do
                text.Visible = false
            end
        end
    else
        for _, ring in pairs(RadarState.Rings) do
            ring.Visible = false
        end
        for _, text in pairs(RadarState.Cardinals) do
            text.Visible = false
        end
    end

    if Radar.UseQuads then
        local selfLook = root.CFrame.LookVector
        local selfAngle = getQuadAngle(selfLook)
        local selfA, selfB, selfC, selfD = projectRadarQuad(center, selfAngle, Radar.SelfDotSize)

        radarSelfQuad.PointA = selfA
        radarSelfQuad.PointB = selfB
        radarSelfQuad.PointC = selfC
        radarSelfQuad.PointD = selfD
        radarSelfQuad.Color = Radar.Theme.Local_Marker
        radarSelfQuad.Visible = true
        radarSelf.Visible = false
    else
        radarSelfQuad.Visible = false
        radarSelf.Visible = true
    end

    local localPos = root.Position
    local localTeam = LocalPlayer.Team
    local hue = ((_Tick or tick()) / 20) % 1
    local rgbColor = Color3.fromHSV(hue, 0.9, 0.9)

    for model in pairs(ActiveESPs) do
        local dot = getRadarDot(model)
        local worldRoot = getRadarRoot(model)

        if not worldRoot then
            dot.Circle.Visible = false
            dot.Quad.Visible = false
            continue
        end

        local realPlayer = getRealPlayerFromCharacter(VMtoChar[model])
        if not realPlayer or realPlayer == LocalPlayer then
            dot.Circle.Visible = false
            dot.Quad.Visible = false
            continue
        end

        local sameTeam = realPlayer and localTeam and realPlayer.Team == localTeam
        if not Radar.DisplayTeammates and sameTeam then
            dot.Circle.Visible = false
            dot.Quad.Visible = false
            continue
        end

        local delta = worldRoot.Position - localPos
        local flatDist = math.sqrt((delta.X * delta.X) + (delta.Z * delta.Z))
        if flatDist <= 0 then
            dot.Circle.Visible = false
            dot.Quad.Visible = false
            continue
        end

        local angle = math.atan2(delta.Z, delta.X)
        local fixedRadius = (flatDist / math.max(Radar.Range, 1)) * mapRadius
        local offscreen = fixedRadius > mapRadius

        if offscreen then
            if not Radar.ShowOffscreen then
                dot.Circle.Visible = false
                dot.Quad.Visible = false
                continue
            end

            fixedRadius = mapRadius
        end

        angle += (camAngle + rad180)
        local pos = center + Vector2.new(
            fixedRadius * math.cos(angle),
            fixedRadius * math.sin(angle)
        )
        local dotColor = Radar.Theme.Generic_Marker
        local dotTransparency = 1

        local dotRadius = Radar.MarkerSize * Radar.MarkerScaleBase
        if Radar.MarkerFalloff then
            local falloff = math.clamp(Radar.MarkerFalloffAmnt / math.max(delta.Magnitude, 1), Radar.MarkerScaleMin, Radar.MarkerScaleMax)
            dotRadius *= falloff
        end

        local isFriend = false
        if realPlayer then
            pcall(function()
                isFriend = realPlayer:IsFriendsWith(LocalPlayer.UserId)
            end)
        end

        if Radar.DisplayFriendColors and isFriend then
            dotColor = Radar.Theme.Friend_Marker
        elseif Radar.DisplayTeamColors then
            if Radar.UseTeamColors and realPlayer then
                dotColor = realPlayer.TeamColor.Color
            elseif sameTeam then
                dotColor = Radar.Theme.Team_Marker
            end
        end

        if Radar.DisplayRGBColors then
            dotColor = rgbColor
        end

        if offscreen and Radar.ShowOffscreen then
            dotTransparency = math.min(dotTransparency, Radar.OffscreenTransparency)
        end
        if Radar.VisibilityCheck and realPlayer and not IsPlayerVisible(realPlayer) then
            dotTransparency = math.min(dotTransparency, 0.35)
        end

        if Radar.UseQuads then
            local quad = dot.Quad
            local lookVec = worldRoot.CFrame.LookVector
            local angle = math.atan2(lookVec.X, lookVec.Z) - camAngle - rad90
            local pA, pB, pC, pD = projectRadarQuad(pos, angle, dotRadius)

            quad.PointA = pA
            quad.PointB = pB
            quad.PointC = pC
            quad.PointD = pD
            quad.Color = dotColor
            quad.Transparency = dotTransparency
            quad.Visible = true
            dot.Circle.Visible = false
        else
            local circle = dot.Circle
            circle.Position = pos
            circle.Radius = dotRadius
            circle.Color = dotColor
            circle.Transparency = dotTransparency
            circle.Visible = true
            dot.Quad.Visible = false
        end
    end

    for model in pairs(RadarState.Dots) do
        if not ActiveESPs[model] then
            dropRadarDot(model)
        end
    end
end

local function updateObjectLabels()
    local oc = ESP.ObjectChams
    local masterNames = oc.Names and oc.Names.Enabled

    local nameToKey = {
        Drone = "Drones",
        Claymore = "Claymores",
        ProximityAlarm = "ProximityAlarm",
        StickyCamera = "StickyCamera",
        RemoteC4 = "RemoteC4",
        ThermiteCharge = "ThermiteCharge",
        ToxicCharge = "ToxicCharge",
        BreachCharge = "BreachCharge",
        HardBreachCharge = "HardBreachCharge",
        ShockBattery = "ShockBattery",
        DeployableShield = "DeployableShield",
        BarbedWire = "BarbedWire",
        SignalDisruptor = "SignalDisruptor",
        BulletproofCamera = "BulletproofCamera",
        NeedleMine = "NeedleMine",
    }

    local anyEnabled = false
    for _, key in pairs(nameToKey) do
        local cfg = oc[key]
        if cfg and (masterNames or (cfg.Name and cfg.Name.Enabled)) then
            anyEnabled = true
            break
        end
    end

    if not anyEnabled or not _Camera then
        for _, label in pairs(RadarState.ObjectLabels) do
            label.Visible = false
        end
        return
    end

    local cameraPos = _CamPos or _Camera.CFrame.Position

    for _, child in ipairs(Workspace:GetChildren()) do
        local key = nameToKey[child.Name]
        local cfg = key and oc[key]
        if not cfg or not (masterNames or (cfg.Name and cfg.Name.Enabled)) then
            dropObjectLabel(child)
            continue
        end

        local label = getObjectLabel(child)
        local worldPos = getObjectWorldPosition(child)
        if not worldPos then
            label.Visible = false
            continue
        end

        local screenPos, onScreen = _Camera:WorldToViewportPoint(worldPos)
        local dist = (cameraPos - worldPos).Magnitude
        if not onScreen or dist > ESP.MaxDistance then
            label.Visible = false
            continue
        end

        label.Text = getObjectLabelText(child.Name)
        label.Position = Vector2.new(screenPos.X, screenPos.Y - 18)
        label.Color = cfg.OutlineRGB or cfg.FillRGB
        label.Transparency = 1
        label.Visible = true
    end

    for instance in pairs(RadarState.ObjectLabels) do
        if not instance.Parent then
            dropObjectLabel(instance)
        end
    end
end

local function createNameLabel(character)
    if ActiveNames[character] then return end
    local label = Instance.new("TextLabel")
    label.Parent               = ScreenGui
    label.BackgroundTransparency = 1
    label.TextColor3           = ESP.Drawing.Names.RGB
    label.Font                 = Enum.Font.Code
    label.TextSize             = ESP.FontSize
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3     = Color3.fromRGB(0, 0, 0)
    label.RichText             = true
    label.Visible              = false
    label.Size                 = UDim2.new(0, 200, 0, ESP.FontSize + 4)
    label.AnchorPoint          = Vector2.new(0.5, 1)
    label.TextScaled           = false
    ActiveNames[character]     = label
end

local function updateNameLabel(character, label)
    local player = getRealPlayerFromCharacter(character)
    if not player then label.Visible = false return end
    if ESP.Drawing.TeamCheck.Enabled and player.Team == LocalPlayer.Team then
        label.Visible = false return
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then label.Visible = false return end
    local Pos, OnScreen = _Camera:WorldToViewportPoint(root.Position)
    local dist = (_CamPos - root.Position).Magnitude
    if not OnScreen or dist > ESP.MaxDistance then label.Visible = false return end

    local centerX, topY
    local matchedVM = CharToVM[character]
    if matchedVM then
        local x0, y0, x1 = getProjectedModelBounds(matchedVM)
        if x0 then
            centerX = x0 + (x1 - x0) * 0.5
            topY    = y0 - _GuiInsetY - 15
        end
    end
    centerX = centerX or Pos.X
    topY    = topY    or (Pos.Y - 50)

    local nameText = player.Name
    if ESP.Drawing.Distances.Enabled then
        nameText = string.format("%s [%d]", nameText, math.floor(dist))
    end
    label.Text       = nameText
    label.TextColor3 = ESP.Drawing.Names.RGB
    label.TextSize   = ESP.FontSize
    label.Position   = UDim2.new(0, centerX, 0, topY)
    label.Visible    = true
end

local function removeNameLabel(character)
    local label = ActiveNames[character]
    if label then
        label:Destroy()
        ActiveNames[character] = nil
    end
end

local Functions = {}

function Functions:Create(Class, Properties)
    local inst = typeof(Class) == "string" and Instance.new(Class) or Class
    for k, v in pairs(Properties) do inst[k] = v end
    return inst
end

local function hasTeamHighlight(model)
    if not model then return false end
    if TeamHighlightCache[model] ~= nil then return TeamHighlightCache[model] end
    for _, child in pairs(Workspace:GetChildren()) do
        if child:IsA("Highlight") and child.Adornee == model then
            local c = child.FillColor
            local r = math.round(c.R * 255)
            local g = math.round(c.G * 255)
            local b = math.round(c.B * 255)
            if r == 0 and g == 150 and b == 0 then
                TeamHighlightCache[model] = true
                return true
            end
        end
    end
    TeamHighlightCache[model] = false
    return false
end

Workspace.ChildAdded:Connect(function(child)
    if child:IsA("Highlight") then
        table.clear(TeamHighlightCache)
        return
    end
    task.defer(function()
        if isRealCharacter(child) then
            RealCharacterSet[child] = true
            markProxyCacheDirty()
        end
    end)
end)

Workspace.ChildRemoved:Connect(function(child)
    if child:IsA("Highlight") then
        table.clear(TeamHighlightCache)
        return
    end
        if RealCharacterSet[child] then
            RealCharacterSet[child] = nil
            CharToVM[child] = nil
            removeNameLabel(child)
            markProxyCacheDirty()
        end
        if ActiveObjectChams[child] then
            ActiveObjectChams[child]:Destroy()
            ActiveObjectChams[child] = nil
        end
        dropObjectLabel(child)
end)

local function isValidPlayer(model)
    if not model or not model.Parent then return false end
    if model.Name == "LocalViewmodel" then return false end
    if not _Viewmodels or model.Parent ~= _Viewmodels then return false end
    local torso = model:FindFirstChild("torso")
    if not torso or not torso:IsA("BasePart") then return false end
    return true
end

local function findWeaponInCharacter(character)
    if not character then return nil end
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("item_type") then
            return child
        end
    end
    return nil
end

local function normalizeWeaponIconKey(value)
    if type(value) ~= "string" then
        return nil
    end

    local key = string.lower(value)
    key = key:gsub("[%s%p]+", "")
    if key == "" then
        return nil
    end
    return key
end

local function cacheWeaponIcon(key, icon)
    key = normalizeWeaponIconKey(key)
    if not key then
        return
    end
    WeaponIconCache[key] = icon
end

local function buildWeaponIconCache()
    if WeaponIconCacheBuilt then
        return
    end

    local gunRoot = ReplicatedStorage
        and ReplicatedStorage:FindFirstChild("Modules")
        and ReplicatedStorage.Modules:FindFirstChild("Items")
        and ReplicatedStorage.Modules.Items:FindFirstChild("Item")
        and ReplicatedStorage.Modules.Items.Item:FindFirstChild("Gun")

    if not gunRoot then
        return
    end

    local function scan(node)
        for _, child in ipairs(node:GetChildren()) do
            if child:IsA("ModuleScript") then
                local ok, moduleData = pcall(require, child)
                if ok and type(moduleData) == "table" then
                    local icon = moduleData.icon
                    if type(icon) == "string" and icon ~= "" then
                        cacheWeaponIcon(child.Name, icon)
                        cacheWeaponIcon(moduleData.display_name, icon)
                    end
                end
            end
            if #child:GetChildren() > 0 then
                scan(child)
            end
        end
    end

    scan(gunRoot)
    WeaponIconCacheBuilt = true
end

local function getWeaponIconForName(name)
    if not WeaponIconCacheBuilt then
        buildWeaponIconCache()
    end

    local key = normalizeWeaponIconKey(name)
    if not key then
        return nil
    end
    return WeaponIconCache[key]
end

local function createSkeletonESP(character)
    if not character or ActiveSkeletons[character] then return end
    if not isValidPlayer(character) then return end
    local bones = {}
    local required = { "torso","head","shoulder1","shoulder2",
                       "arm1","arm2","hip1","hip2","leg1","leg2" }
    for _, name in ipairs(required) do
        local b = character:FindFirstChild(name)
        if not b or not b:IsA("BasePart") then return end
        bones[name] = b
    end
    local lines = {}
    for _ in ipairs(BONE_CONNECTIONS) do
        local line = Drawing.new("Line")
        line.Visible      = false
        line.Color        = ESP.Drawing.Skeleton.RGB
        line.Thickness    = ESP.Drawing.Skeleton.Thickness
        line.Transparency = 1
        table.insert(lines, line)
    end
    ActiveSkeletons[character] = { lines = lines, bones = bones }
end

local function removeSkeleton(character)
    local sd = ActiveSkeletons[character]
    if not sd then return end
    for _, line in ipairs(sd.lines) do
        line.Visible = false
        line:Remove()
    end
    ActiveSkeletons[character] = nil
end

function Functions:CleanAllSkeletons()
    for model in pairs(ActiveSkeletons) do
        removeSkeleton(model)
    end
end

local function ProcessSkeleton(character, skData)
    local lines = skData.lines
    local function hideLines()
        for _, l in ipairs(lines) do l.Visible = false end
    end
    if not ESP.Enabled or not ESP.Drawing.Skeleton.Enabled then hideLines() return end
    if not character or not character.Parent then
        hideLines()
        for _, l in ipairs(lines) do l:Remove() end
        ActiveSkeletons[character] = nil
        return
    end
    if ESP.Drawing.TeamCheck.Enabled and hasTeamHighlight(character) then hideLines() return end
    local torso = skData.bones["torso"]
    if not torso or torso.Transparency >= 1 then hideLines() return end
    local dist = (_CamPos - torso.Position).Magnitude
    if dist > ESP.MaxDistance then hideLines() return end
    local skColor = ESP.Drawing.Skeleton.RGB
    local skThick = ESP.Drawing.Skeleton.Thickness
    for i, conn in ipairs(BONE_CONNECTIONS) do
        local b1, b2 = skData.bones[conn[1]], skData.bones[conn[2]]
        local line   = lines[i]
        if b1 and b2 and line then
            local p1, on1 = _Camera:WorldToViewportPoint(b1.Position)
            local p2, on2 = _Camera:WorldToViewportPoint(b2.Position)
            if on1 and on2 then
                line.From      = Vector2.new(p1.X, p1.Y)
                line.To        = Vector2.new(p2.X, p2.Y)
                line.Color     = skColor
                line.Thickness = skThick
                line.Visible   = true
            else
                line.Visible = false
            end
        elseif line then
            line.Visible = false
        end
    end
end

local function applyObjectHighlight(instance, config)
    if not instance or not instance.Parent then
        if ActiveObjectChams[instance] then
            pcall(function() ActiveObjectChams[instance]:Destroy() end)
            ActiveObjectChams[instance] = nil
        end
        return
    end

    local h = ActiveObjectChams[instance]
    if not h or not h.Parent or h.ClassName ~= "Highlight" then
        if h then pcall(function() h:Destroy() end) end
        h = Instance.new("Highlight")
        h.Parent = ScreenGui
        ActiveObjectChams[instance] = h
    end

    h.Adornee             = instance
    h.Enabled             = config.Enabled
    h.FillColor           = config.FillRGB
    h.FillTransparency    = config.FillTrans
    h.OutlineColor        = config.OutlineRGB
    h.OutlineTransparency = config.OutlineTrans
    h.DepthMode           = "AlwaysOnTop"
end


local function applyObjectPing(instance, config, keyOverride)
    if not instance or not instance.Parent then
        if ActiveObjectChams[instance] then
            pcall(function() ActiveObjectChams[instance]:Destroy() end)
            ActiveObjectChams[instance] = nil
        end
        return
    end

    if not PingObjectTemplate or not _Camera then return end

    local ping = ActiveObjectChams[instance]
    if not ping or not ping.Parent or ping.ClassName ~= "BillboardGui" then
        if ping then pcall(function() ping:Destroy() end) end
        ping = PingObjectTemplate:Clone()
        ping.Parent = _Camera
        ActiveObjectChams[instance] = ping
    end

    ping.Adornee = instance
    ping.Enabled = config.Enabled

    pcall(function()
        local _, modelSize = instance:GetBoundingBox()
        ping.StudsOffset = Vector3.new(0, -modelSize.Y / 2 - 0.5, 0)
    end)

    local frame = ping:FindFirstChild("Frame")
    if frame then
        frame.BackgroundColor3 = config.FillRGB
        frame.BackgroundTransparency = config.FillTrans

        local imageLabel = frame:FindFirstChild("ImageLabel")
        if imageLabel and imageLabel:IsA("ImageLabel") then
            imageLabel.ImageColor3 = Color3.new(1, 1, 1)
            imageLabel.ImageTransparency = config.FillTrans
            local info = GADGET_INFO[keyOverride or instance.Name]
            if info and info.Icon then
                imageLabel.Image = info.Icon
            else
                imageLabel.Image = "rbxassetid://7095697276" 
            end
        end
    end

    local arrow = ping:FindFirstChild("Arrow")
    if arrow and arrow:IsA("ImageLabel") then
        arrow.ImageColor3 = config.OutlineRGB or config.FillRGB
        arrow.ImageTransparency = config.OutlineTrans
    end
end

local function updateObjectChams()
    local oc = ESP.ObjectChams

    local nameToKey = {
        Drone             = "Drones",
        Claymore          = "Claymores",
        ProximityAlarm    = "ProximityAlarm",
        StickyCamera      = "StickyCamera",
        RemoteC4          = "RemoteC4",
        ThermiteCharge    = "ThermiteCharge",
        ToxicCharge       = "ToxicCharge",
        BreachCharge      = "BreachCharge",
        HardBreachCharge  = "HardBreachCharge",
        ShockBattery      = "ShockBattery",
        DeployableShield  = "DeployableShield",
        BarbedWire        = "BarbedWire",
        SignalDisruptor   = "SignalDisruptor",
        BulletproofCamera = "BulletproofCamera",
        NeedleMine        = "NeedleMine",
    }

    local anyEnabled = false
    for _, key in pairs(nameToKey) do
        if oc[key] and oc[key].Enabled then
            anyEnabled = true
            break
        end
    end

    if not anyEnabled then
        for instance, h in pairs(ActiveObjectChams) do
            pcall(function() h:Destroy() end)
            ActiveObjectChams[instance] = nil
        end
        return
    end

    local allFoundGadgets = {}
    for _, child in ipairs(Workspace:GetChildren()) do
        if nameToKey[child.Name] then
            allFoundGadgets[child] = child.Name
        elseif child:IsA("Model") or child:IsA("Folder") then
            for _, subItem in ipairs(child:GetChildren()) do
                if nameToKey[subItem.Name] then
                    allFoundGadgets[subItem] = subItem.Name
                end
            end
        end
    end

    if oc.Camera and oc.Camera.Enabled then
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Model") then
                local folder = child:FindFirstChildWhichIsA("Folder")
                if folder then
                    local defaultCameras = folder:FindFirstChild("DefaultCameras")
                    if defaultCameras then
                        for _, cameraModel in ipairs(defaultCameras:GetChildren()) do
                            if cameraModel:IsA("Model") then
                                allFoundGadgets[cameraModel] = "Camera"
                            end
                        end
                    end
                end
            end
        end
    end

    for instance, key in pairs(allFoundGadgets) do
        local configKey = nameToKey[key] or key
        local config = oc[configKey]
        if config and config.Enabled then
            if oc.RenderMethod == "Chams" then
                applyObjectHighlight(instance, config)
            else
                applyObjectPing(instance, config, key)
            end
        end
    end

    for instance, h in pairs(ActiveObjectChams) do
        if not instance.Parent or not allFoundGadgets[instance] then
            pcall(function() h:Destroy() end)
            ActiveObjectChams[instance] = nil
        else
            local key = allFoundGadgets[instance]
            local configKey = nameToKey[key] or key
            if not configKey or not oc[configKey] or not oc[configKey].Enabled then
                pcall(function() h:Destroy() end)
                ActiveObjectChams[instance] = nil
            end
        end
    end
end

local function ProcessESP(model, espData)
    local el = espData.elements
    local weaponTransparency = 0

    local function Hide()
        el.Box.Visible         = false
        el.WeaponContainer.Visible = false
        el.Weapon.Visible      = false
        el.WeaponIcon.Visible  = false
        el.WeaponIcon.Image    = ""
        if el.Name then el.Name.Visible = false end
        el.Chams.Enabled       = false
        el.HealthBarBG.Visible = false
        el.LTH.Visible = false; el.LTV.Visible = false
        el.RTH.Visible = false; el.RTV.Visible = false
        el.LBH.Visible = false; el.LBV.Visible = false
        el.RBH.Visible = false; el.RBV.Visible = false
        if el.Tracer then el.Tracer.Visible = false end
        if el.OffscreenArrow then el.OffscreenArrow.Visible = false end
        if el.OffscreenDistance then el.OffscreenDistance.Visible = false end
    end

    if not ESP.Enabled then Hide() return end
    if not model or not model.Parent or not isValidPlayer(model) then
        task.defer(function()
            if espData.folder then espData.folder:Destroy() end
            if el.OffscreenArrow then el.OffscreenArrow:Remove() end
            if el.OffscreenDistance then el.OffscreenDistance:Remove() end
            if el.Tracer then el.Tracer:Remove() end
            ActiveESPs[model] = nil
            removeSkeleton(model)
        end)
        return
    end

    local torso = model:FindFirstChild("torso")
    if not torso or torso.Transparency >= 1 then Hide() return end
    if ESP.Drawing.TeamCheck.Enabled and hasTeamHighlight(model) then Hide() return end

    local Pos, OnScreen = _Camera:WorldToViewportPoint(torso.Position)
    local Dist = (_CamPos - torso.Position).Magnitude / 3.5714285714

    if Dist > ESP.MaxDistance then
        Hide()
        removeSkeleton(model)
        return
    end

    if not OnScreen or Pos.Z < 0 then
        Hide() 

        if ESP.Drawing.OffscreenArrows.Enabled then
            local arrow = el.OffscreenArrow
            local distText = el.OffscreenDistance
            local screenCenter = Vector2.new(_ViewSize.X / 2, _ViewSize.Y / 2)
            local arrowMargin = 40
            local arrowRadius = ESP.Drawing.OffscreenArrows.Size

            local targetScreenPos = Vector2.new(Pos.X, Pos.Y)
            if Pos.Z < 0 then
                targetScreenPos = screenCenter + (screenCenter - targetScreenPos).Unit * 1000
            end

            local vecToTarget = (targetScreenPos - screenCenter)
            local angle = math.atan2(vecToTarget.Y, vecToTarget.X)
            local halfWidth = _ViewSize.X / 2 - arrowMargin
            local halfHeight = _ViewSize.Y / 2 - arrowMargin
            local cosA, sinA = math.cos(angle), math.sin(angle)

            local xInter = halfHeight * cosA / math.abs(sinA)
            local yInter = halfWidth * sinA / math.abs(cosA)
            local intersection
            if math.abs(xInter) <= halfWidth then
                intersection = Vector2.new(xInter, halfHeight * math.sign(sinA))
            else
                intersection = Vector2.new(halfWidth * math.sign(cosA), yInter)
            end

            local arrowPos = screenCenter + intersection
            arrow.PointA = arrowPos + Vector2.new(cosA, sinA) * arrowRadius
            arrow.PointB = arrowPos + Vector2.new(math.cos(angle + math.rad(140)), math.sin(angle + math.rad(140))) * (arrowRadius * 0.8)
            arrow.PointC = arrowPos + Vector2.new(math.cos(angle - math.rad(140)), math.sin(angle - math.rad(140))) * (arrowRadius * 0.8)
            local dir = Vector2.new(cosA, sinA)
            local side = Vector2.new(-sinA, cosA)

            arrow.PointA = arrowPos + dir * arrowRadius
            arrow.PointB = arrowPos + side * (arrowRadius * 0.8) - dir * arrowRadius
            arrow.PointC = arrowPos - dir * (arrowRadius * 0.6)
            arrow.PointD = arrowPos - side * (arrowRadius * 0.8) - dir * arrowRadius

            arrow.Color = ESP.Drawing.OffscreenArrows.RGB
            arrow.Transparency = ESP.Drawing.OffscreenArrows.Transparency
            arrow.Visible = true

            if ESP.Drawing.OffscreenArrows.ShowDistance then
                distText.Text = math.floor(Dist) .. "m"
                distText.Position = arrowPos - (Vector2.new(cosA, sinA) * (arrowRadius + 15))
                distText.Color = ESP.Drawing.OffscreenArrows.DistanceRGB
                distText.Size = ESP.Drawing.OffscreenArrows.DistanceFontSize
                distText.Visible = true
            end
        end
        return 
    end

   
    el.OffscreenArrow.Visible = false
    el.OffscreenDistance.Visible = false

    local yInset = _GuiInsetY
    local iconSizeSetting = ESP.Drawing.Weapons.IconSize or (ESP.FontSize + 4)
    local iconSize = math.max(8, math.floor(iconSizeSetting + 0.5))
    local weaponRowHeight = math.max(iconSize, ESP.FontSize + 4)

    if ESP.FadeOut.OnDistance then
        local fade = math.max(0.1, 1 - (Dist / ESP.MaxDistance))
        local inv  = 1 - fade
        weaponTransparency = inv
        el.Outline.Transparency    = inv
        el.WeaponContainer.BackgroundTransparency = 1
        el.Weapon.TextTransparency = inv
        el.Weapon.TextStrokeTransparency = inv
        el.WeaponIcon.ImageTransparency = inv
        el.LTH.BackgroundTransparency = inv; el.LTV.BackgroundTransparency = inv
        el.RTH.BackgroundTransparency = inv; el.RTV.BackgroundTransparency = inv
        el.LBH.BackgroundTransparency = inv; el.LBV.BackgroundTransparency = inv
        el.RBH.BackgroundTransparency = inv; el.RBV.BackgroundTransparency = inv
    end

    local x0, y0, x1, y1 = getProjectedModelBounds(model)
    if not x0 then
        local scaleFactor = (torso.Size.Y * _ViewSize.Y) / (Pos.Z * 2)
        local fw = 2.5  * scaleFactor
        local fh = 4.75 * scaleFactor
        x0, y0 = Pos.X - fw * 0.5, Pos.Y - fh * 0.5
        x1, y1 = Pos.X + fw * 0.5, Pos.Y + fh * 0.5
    end
    local w = math.max(2, x1 - x0)
    local h = math.max(2, y1 - y0)
    local padX = math.max(2, w * 0.15)
    local padY = math.max(2, h * 0.07)
    x0 = x0 - padX; x1 = x1 + padX
    y0 = y0 - padY; y1 = y1 + padY
    w = math.max(2, x1 - x0)
    h = math.max(2, y1 - y0)

    local cLen   = ESP.Drawing.Boxes.Corner.Length
    local cThick = ESP.Drawing.Boxes.Corner.Thickness
    local dynCL  = math.min(cLen, w * 0.2, h * 0.2)
    local y0yi   = y0 - yInset
    local y1yi   = y1 - yInset

    local chams = el.Chams
    chams.Adornee      = model
    chams.Enabled      = ESP.Drawing.Chams.Enabled
    chams.FillColor    = ESP.Drawing.Chams.FillRGB
    chams.OutlineColor = ESP.Drawing.Chams.OutlineRGB
    chams.DepthMode    = ESP.Drawing.Chams.VisibleCheck and "Occluded" or "AlwaysOnTop"
    if ESP.Drawing.Chams.Thermal then
        local b = math.atan(math.sin(_Tick * 2)) * 2 / math.pi
        chams.FillTransparency    = (ESP.Drawing.Chams.Fill_Transparency    / 100) * (1 - b * 0.1)
        chams.OutlineTransparency = (ESP.Drawing.Chams.Outline_Transparency / 100)
    end

    local cv = ESP.Drawing.Boxes.Corner.Enabled
    local cc = ESP.Drawing.Boxes.Corner.RGB
    el.LTH.Visible = cv; el.LTH.Position = UDim2.new(0, x0,           0, y0yi);          el.LTH.Size = UDim2.new(0, dynCL,  0, cThick); el.LTH.BackgroundColor3 = cc
    el.LTV.Visible = cv; el.LTV.Position = UDim2.new(0, x0,           0, y0yi);          el.LTV.Size = UDim2.new(0, cThick, 0, dynCL);  el.LTV.BackgroundColor3 = cc
    el.RTH.Visible = cv; el.RTH.Position = UDim2.new(0, x1 - dynCL,  0, y0yi);          el.RTH.Size = UDim2.new(0, dynCL,  0, cThick); el.RTH.BackgroundColor3 = cc
    el.RTV.Visible = cv; el.RTV.Position = UDim2.new(0, x1 - cThick, 0, y0yi);          el.RTV.Size = UDim2.new(0, cThick, 0, dynCL);  el.RTV.BackgroundColor3 = cc
    el.LBH.Visible = cv; el.LBH.Position = UDim2.new(0, x0,           0, y1yi - cThick); el.LBH.Size = UDim2.new(0, dynCL,  0, cThick); el.LBH.BackgroundColor3 = cc
    el.LBV.Visible = cv; el.LBV.Position = UDim2.new(0, x0,           0, y1yi - dynCL);  el.LBV.Size = UDim2.new(0, cThick, 0, dynCL);  el.LBV.BackgroundColor3 = cc
    el.RBH.Visible = cv; el.RBH.Position = UDim2.new(0, x1 - dynCL,  0, y1yi - cThick); el.RBH.Size = UDim2.new(0, dynCL,  0, cThick); el.RBH.BackgroundColor3 = cc
    el.RBV.Visible = cv; el.RBV.Position = UDim2.new(0, x1 - cThick, 0, y1yi - dynCL);  el.RBV.Size = UDim2.new(0, cThick, 0, dynCL);  el.RBV.BackgroundColor3 = cc

    local full   = ESP.Drawing.Boxes.Full.Enabled
    local filled = ESP.Drawing.Boxes.Filled.Enabled
    el.Box.Position               = UDim2.new(0, x0, 0, y0 - yInset)
    el.Box.Size                   = UDim2.new(0, w,  0, h)
    el.Box.Visible                = full or (cv and filled)
    el.Box.BackgroundTransparency = filled and ESP.Drawing.Boxes.Filled.Transparency or 1
    el.Outline.Enabled            = full and ESP.Drawing.Boxes.Gradient

    el.Gradient1.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ESP.Drawing.Boxes.GradientFillRGB1),
        ColorSequenceKeypoint.new(1, ESP.Drawing.Boxes.GradientFillRGB2),
    })
    el.Gradient2.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ESP.Drawing.Boxes.GradientRGB1),
        ColorSequenceKeypoint.new(1, ESP.Drawing.Boxes.GradientRGB2),
    })

    if ESP.Drawing.Boxes.Animate then
        local dt = _Tick - espData.lastTick
        espData.rotAngle = espData.rotAngle + dt * ESP.Drawing.Boxes.RotationSpeed * math.cos(math.pi / 4 * _Tick - math.pi / 2)
        el.Gradient1.Rotation = espData.rotAngle
        el.Gradient2.Rotation = espData.rotAngle
    else
        el.Gradient1.Rotation = -45
        el.Gradient2.Rotation = -45
    end
    espData.lastTick = _Tick

    el.HealthBarBG.Visible          = ESP.Drawing.HealthBar.Enabled
    el.HealthBarBG.BackgroundColor3 = Color3.fromRGB(30, 10, 40)
    if ESP.Drawing.HealthBar.Enabled then
        local hp, maxHp = 100, 100
        local realChar  = VMtoChar[model]
        if realChar then
            local hum = realChar:FindFirstChildOfClass("Humanoid")
            if hum then
                hp    = hum.Health
                maxHp = hum.MaxHealth
            end
        end
        local hpPct    = math.clamp(hp / math.max(maxHp, 1), 0, 1)
        local barWidth = 4
        el.HealthBarBG.Position = UDim2.new(0, x0 - barWidth - 2, 0, y0yi)
        el.HealthBarBG.Size     = UDim2.new(0, barWidth, 0, h)
        el.HealthBar.Size       = UDim2.new(1, 0, hpPct, 0)
        el.HealthBar.Position   = UDim2.new(0, 0, 1 - hpPct, 0)
        el.HealthBar.BackgroundColor3 = Color3.fromRGB(
            255,
            math.floor(220 * hpPct),
            math.floor(200 * (1 - hpPct))
        )
    end

    el.WeaponContainer.Visible = ESP.Drawing.Weapons.Enabled
    if ESP.Drawing.Weapons.Enabled then
        local wm = findWeaponInCharacter(model)
        if wm then
            local weaponName = wm.Name or ""
            local iconId = getWeaponIconForName(weaponName)
            local padding = 4
            local textBounds = Vector2.new(0, 0)
            pcall(function()
                textBounds = TextService:GetTextSize(weaponName, ESP.FontSize, Enum.Font.Code, Vector2.new(1000, 1000))
            end)
            local textWidth = math.max(0, math.ceil(textBounds.X))
            local showIcon = ESP.Drawing.Weapons.IconEnabled and type(iconId) == "string" and iconId ~= ""
            local totalWidth = textWidth + (showIcon and (iconSize + padding) or 0)

            el.Weapon.Text               = weaponName
            el.Weapon.TextColor3         = ESP.Drawing.Weapons.RGB
            el.Weapon.TextTransparency   = weaponTransparency
            el.Weapon.TextStrokeTransparency = weaponTransparency
            el.Weapon.Visible             = true
            el.Weapon.Position            = UDim2.new(0, showIcon and (iconSize + padding) or 0, 0, 0)
            el.Weapon.Size                = UDim2.new(0, textWidth, 1, 0)

            el.WeaponContainer.Position   = UDim2.new(0, x0 + w * 0.5, 0, y1yi + 2)
            el.WeaponContainer.Size       = UDim2.new(0, math.max(totalWidth, textWidth), 0, weaponRowHeight)
            el.WeaponContainer.Visible    = true

            el.WeaponIcon.Visible         = showIcon
            el.WeaponIcon.Image           = showIcon and iconId or ""
            el.WeaponIcon.ImageTransparency = weaponTransparency
            el.WeaponIcon.Size            = UDim2.new(0, showIcon and iconSize or 0, 0, showIcon and iconSize or 0)
            el.WeaponIcon.BackgroundTransparency = 1
        else
            el.WeaponContainer.Visible = false
            el.Weapon.Visible = false
            el.WeaponIcon.Visible = false
            el.WeaponIcon.Image = ""
        end
    end

    if ESP.Drawing.Tracers.Enabled then
        local origin = ESP.Drawing.Tracers.Origin
        local startPos
        if origin == "Top" then
            startPos = Vector2.new(_ViewSize.X / 2, 0)
        elseif origin == "Center" then
            startPos = Vector2.new(_ViewSize.X / 2, _ViewSize.Y / 2)
        else  
            startPos = Vector2.new(_ViewSize.X / 2, _ViewSize.Y)
        end
        el.Tracer.From         = startPos
        el.Tracer.To           = Vector2.new(Pos.X, Pos.Y)
        el.Tracer.Color        = ESP.Drawing.Tracers.RGB
        el.Tracer.Thickness    = ESP.Drawing.Tracers.Thickness
        el.Tracer.Transparency = ESP.Drawing.Tracers.Transparency
        el.Tracer.Visible      = true
    else
        el.Tracer.Visible = false
    end

    if ESP.Drawing.Skeleton.Enabled and not ActiveSkeletons[model] then
        createSkeletonESP(model)
    end
end

local function st()
    if MasterConnection then
        MasterConnection:Disconnect()
        MasterConnection = nil
    end

    MasterConnection = RunService.RenderStepped:Connect(function(deltaTime)
        _Camera     = Workspace.CurrentCamera
        _CamPos     = _Camera.CFrame.Position
        _ViewSize   = _Camera.ViewportSize
        _Tick       = tick()
        _frameCount = _frameCount + 1

        local okInset, inset = pcall(function() return GuiService:GetGuiInset() end)
        if okInset and inset then
            _GuiInsetY = (ScreenGui and ScreenGui.IgnoreGuiInset) and 0 or inset.Y
        else
            _GuiInsetY = 0
        end

        if _proxyCacheDirty or (_frameCount % PROXY_REFRESH_INTERVAL == 0) then
            rebuildProxyCache()
        end

        if _Tick - _lastCharRescan > 3 then
            _lastCharRescan = _Tick
            for _, child in pairs(Workspace:GetChildren()) do
                if not RealCharacterSet[child] and isRealCharacter(child) then
                    RealCharacterSet[child] = true
                    markProxyCacheDirty()
                end
            end
        end

        for model, espData in pairs(ActiveESPs) do
            ProcessESP(model, espData)
        end

        for model, skData in pairs(ActiveSkeletons) do
            ProcessSkeleton(model, skData)
        end

        updateObjectChams()
        updateObjectLabels()
        updateRadar(deltaTime)

        if ESP.Enabled and ESP.Drawing.Names.Enabled then
            for character in pairs(RealCharacterSet) do
                if not ActiveNames[character] then
                    createNameLabel(character)
                end
                updateNameLabel(character, ActiveNames[character])
            end
        else
            for _, label in pairs(ActiveNames) do
                label.Visible = false
            end
        end
    end)
end

local guiHideName = "ESP_" .. tostring(math.random(100000000, 999999999))
local parentGui   = gethui and gethui() or CoreGui

local function cleanupESPGuids(container)
    if not container then return end
    for _, v in pairs(container:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name:sub(1, 4) == "ESP_" then
            v:Destroy()
        end
    end
end

cleanupESPGuids(CoreGui)
if parentGui ~= gethui then cleanupESPGuids(parentGui) end

ScreenGui = Functions:Create("ScreenGui", {
    Parent         = parentGui,
    Name           = guiHideName,
    ResetOnSpawn   = false,
    IgnoreGuiInset = true,
    DisplayOrder   = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui)
    elseif protect_gui then protect_gui(ScreenGui) end
end)

local function CreateESP(CharacterModel)
    if not CharacterModel then return end
    if not isValidPlayer(CharacterModel) then return end
    if ActiveESPs[CharacterModel] then return end

    ESPCounter = ESPCounter + 1
    local folder = Functions:Create("Folder", { Parent = ScreenGui, Name = "E_" .. ESPCounter })
    local iconSize = math.max(8, math.floor((ESP.Drawing.Weapons.IconSize or (ESP.FontSize + 4)) + 0.5))
    local weaponRowHeight = math.max(iconSize, ESP.FontSize + 4)

    local WeaponContainer = Functions:Create("Frame", {
        Parent               = folder, Name = "WC",
        Position             = UDim2.new(0.5, 0, 0, 0),
        Size                 = UDim2.new(0, 0, 0, weaponRowHeight),
        AnchorPoint          = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ClipsDescendants     = false,
    })

    local WeaponIcon = Functions:Create("ImageLabel", {
        Parent               = WeaponContainer, Name = "WI",
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Image                = "",
        ImageTransparency    = 0,
        ScaleType            = Enum.ScaleType.Fit,
        Size                 = UDim2.new(0, iconSize, 0, iconSize),
    })

    local Weapon = Functions:Create("TextLabel", {
        Parent               = WeaponContainer, Name = "W",
        Size                 = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3           = Color3.fromRGB(255, 255, 255),
        Font                 = Enum.Font.Code,
        TextSize             = ESP.FontSize,
        TextStrokeTransparency = 0,
        TextStrokeColor3     = Color3.fromRGB(0, 0, 0),
        RichText             = true,
        TextScaled           = false,
        TextXAlignment       = Enum.TextXAlignment.Left,
        LayoutOrder          = 2,
    })

    local WeaponLayout = Functions:Create("UIListLayout", {
        Parent               = WeaponContainer,
        FillDirection        = Enum.FillDirection.Horizontal,
        SortOrder            = Enum.SortOrder.LayoutOrder,
        VerticalAlignment    = Enum.VerticalAlignment.Center,
        Padding              = UDim.new(0, 4),
    })

    local Box = Functions:Create("Frame", {
        Parent               = folder, Name = "B",
        BackgroundColor3     = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.75,
        BorderSizePixel      = 0,
    })

    local Gradient1 = Functions:Create("UIGradient", {
        Parent  = Box,
        Enabled = ESP.Drawing.Boxes.GradientFill,
        Color   = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ESP.Drawing.Boxes.GradientFillRGB1),
            ColorSequenceKeypoint.new(1, ESP.Drawing.Boxes.GradientFillRGB2),
        }),
    })

    local Outline = Functions:Create("UIStroke", {
        Parent       = Box,
        Enabled      = ESP.Drawing.Boxes.Gradient,
        Transparency = 0,
        Color        = Color3.fromRGB(255, 255, 255),
        LineJoinMode = Enum.LineJoinMode.Miter,
    })

    local Gradient2 = Functions:Create("UIGradient", {
        Parent  = Outline,
        Enabled = ESP.Drawing.Boxes.Gradient,
        Color   = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ESP.Drawing.Boxes.GradientRGB1),
            ColorSequenceKeypoint.new(1, ESP.Drawing.Boxes.GradientRGB2),
        }),
    })

    local Chams = Functions:Create("Highlight", {
        Parent              = folder, Name = "C",
        FillTransparency    = 1,
        OutlineTransparency = 0,
        OutlineColor        = Color3.fromRGB(119, 120, 255),
        DepthMode           = "AlwaysOnTop",
    })

    local HealthBarBG = Functions:Create("Frame", {
        Parent               = folder, Name = "HBG",
        BackgroundColor3     = Color3.fromRGB(30, 10, 40),
        BackgroundTransparency = 0.3,
        BorderSizePixel      = 0,
    })

    local HealthBar = Functions:Create("Frame", {
        Parent               = HealthBarBG, Name = "HB",
        BackgroundColor3     = Color3.fromRGB(0, 255, 0),
        BackgroundTransparency = 0,
        BorderSizePixel      = 0,
        Position             = UDim2.new(0, 0, 0, 0),
        Size                 = UDim2.new(1, 0, 1, 0),
    })

    local cThick = ESP.Drawing.Boxes.Corner.Thickness
    local cLen   = ESP.Drawing.Boxes.Corner.Length
    local cc     = ESP.Drawing.Boxes.Corner.RGB

    local function mc(name, w, h)
        return Functions:Create("Frame", {
            Parent               = folder, Name = name,
            BackgroundColor3     = cc,
            BackgroundTransparency = 0,
            BorderSizePixel      = 0,
            Position             = UDim2.new(0, 0, 0, 0),
            Size                 = UDim2.new(0, w, 0, h),
        })
    end

    local Tracer = Drawing.new("Line")
    Tracer.Visible      = false
    Tracer.Color        = ESP.Drawing.Tracers.RGB
    Tracer.Thickness    = ESP.Drawing.Tracers.Thickness
    Tracer.Transparency = ESP.Drawing.Tracers.Transparency
    Tracer.ZIndex       = 1

    local OffscreenArrow = Drawing.new("Quad")
    OffscreenArrow.Visible      = false
    OffscreenArrow.Filled       = true
    OffscreenArrow.Color        = ESP.Drawing.OffscreenArrows.RGB
    OffscreenArrow.Transparency = ESP.Drawing.OffscreenArrows.Transparency
    OffscreenArrow.ZIndex       = 1

    local OffscreenDistance = Drawing.new("Text")
    OffscreenDistance.Visible      = false
    OffscreenDistance.Center       = true
    OffscreenDistance.Outline      = true
    OffscreenDistance.Font         = Drawing.Fonts.UI
    OffscreenDistance.Color        = ESP.Drawing.OffscreenArrows.DistanceRGB or Color3.new(1,1,1)
    OffscreenDistance.Size         = ESP.Drawing.OffscreenArrows.DistanceFontSize or 12

    ActiveESPs[CharacterModel] = {
        folder   = folder,
        rotAngle = -45,
        lastTick = tick(),
        elements = {
            OffscreenArrow    = OffscreenArrow,
            OffscreenDistance = OffscreenDistance,
            Tracer      = Tracer,
            WeaponContainer = WeaponContainer,
            WeaponIcon  = WeaponIcon,
            Weapon      = Weapon,
            WeaponLayout = WeaponLayout,
            Box         = Box,
            Gradient1   = Gradient1,
            Gradient2   = Gradient2,
            Outline     = Outline,
            Chams       = Chams,
            HealthBarBG = HealthBarBG,
            HealthBar   = HealthBar,
            LTH = mc("LTH", cLen,   cThick),
            LTV = mc("LTV", cThick, cLen),
            RTH = mc("RTH", cLen,   cThick),
            RTV = mc("RTV", cThick, cLen),
            LBH = mc("LBH", cLen,   cThick),
            LBV = mc("LBV", cThick, cLen),
            RBH = mc("RBH", cLen,   cThick),
            RBV = mc("RBV", cThick, cLen),
        },
    }
end

function Functions:CleanAllESPs()
    for model, espData in pairs(ActiveESPs) do
        if espData.folder then espData.folder:Destroy() end
        if espData.elements and espData.elements.OffscreenArrow then espData.elements.OffscreenArrow:Remove() end
        if espData.elements and espData.elements.OffscreenDistance then espData.elements.OffscreenDistance:Remove() end
        if espData.elements and espData.elements.Tracer then espData.elements.Tracer:Remove() end
        ActiveESPs[model] = nil
    end
    for model in pairs(RadarState.Dots) do
        dropRadarDot(model)
    end
    self:CleanAllSkeletons()
end

ESP.RefreshESPs = function()
    Functions:CleanAllESPs()
    if not _Viewmodels then return end
    for _, model in pairs(_Viewmodels:GetChildren()) do
        if model:IsA("Model") then
            task.defer(CreateESP, model)
        end
    end
end

ESP.CleanAllESPs = function() Functions:CleanAllESPs() end

local function mvm()
    _Viewmodels = Workspace:FindFirstChild("Viewmodels")
    if not _Viewmodels then return end

    for _, v in pairs(_Viewmodels:GetChildren()) do
        if v:IsA("Model") then task.defer(CreateESP, v) end
    end

    _Viewmodels.ChildAdded:Connect(function(v)
        if v:IsA("Model") then
            task.defer(CreateESP, v)
            if ESP.Drawing.Skeleton.Enabled then
                task.defer(createSkeletonESP, v)
            end
            markProxyCacheDirty()
        end
    end)

    _Viewmodels.ChildRemoved:Connect(function(v)
        local espData = ActiveESPs[v]
        if espData then
            if espData.folder then espData.folder:Destroy() end
            if espData.elements and espData.elements.OffscreenArrow then espData.elements.OffscreenArrow:Remove() end
            if espData.elements and espData.elements.OffscreenDistance then espData.elements.OffscreenDistance:Remove() end
            if espData.elements and espData.elements.Tracer then espData.elements.Tracer:Remove() end
            ActiveESPs[v] = nil
        end
        dropRadarDot(v)
        removeSkeleton(v)
        TeamHighlightCache[v] = nil
        local associatedChar = VMtoChar[v]
        if associatedChar then
            removeNameLabel(associatedChar)
            CharToVM[associatedChar] = nil 
        end
        VMtoChar[v] = nil
        markProxyCacheDirty()
    end)
end

local function watchRealCharacters()
    task.defer(function()
        for _, child in pairs(Workspace:GetChildren()) do
            if isRealCharacter(child) then
                RealCharacterSet[child] = true
                markProxyCacheDirty()
            end
        end
    end)
end

ESP.ToggleSkeleton = function(enabled)
    ESP.Drawing.Skeleton.Enabled = enabled
    if not enabled then
        Functions:CleanAllSkeletons()
    else
        if _Viewmodels then
            for _, model in pairs(_Viewmodels:GetChildren()) do
                if model:IsA("Model") and isValidPlayer(model) then
                    createSkeletonESP(model)
                end
            end
        end
    end
end

ESP.SetSkeletonColor = function(color)
    if typeof(color) ~= "Color3" then return end
    ESP.Drawing.Skeleton.RGB = color
    for _, sd in pairs(ActiveSkeletons) do
        if sd and sd.lines then
            for _, line in ipairs(sd.lines) do line.Color = color end
        end
    end
end

ESP.SetSkeletonThickness = function(thickness)
    if type(thickness) ~= "number" or thickness <= 0 then return end
    ESP.Drawing.Skeleton.Thickness = thickness
    for _, sd in pairs(ActiveSkeletons) do
        if sd and sd.lines then
            for _, line in ipairs(sd.lines) do line.Thickness = thickness end
        end
    end
end

ESP.ToggleTracers = function(enabled) ESP.Drawing.Tracers.Enabled = enabled end
ESP.SetTracersColor = function(color) if typeof(color) == "Color3" then ESP.Drawing.Tracers.RGB = color end end
ESP.SetTracersOrigin = function(origin)
    local origins = { Top = true, Center = true, Bottom = true }
    if origins[origin] then
        ESP.Drawing.Tracers.Origin = origin
    end
end

ESP.ToggleOffscreenArrows = function(enabled) ESP.Drawing.OffscreenArrows.Enabled = enabled end
ESP.SetOffscreenArrowsColor = function(color) if typeof(color) == "Color3" then ESP.Drawing.OffscreenArrows.RGB = color end end
ESP.SetOffscreenArrowsSize = function(size) if type(size) == "number" and size > 0 then ESP.Drawing.OffscreenArrows.Size = size end end
ESP.SetOffscreenArrowsTransparency = function(trans) if type(trans) == "number" and trans >= 0 and trans <= 1 then ESP.Drawing.OffscreenArrows.Transparency = trans end end
ESP.ToggleOffscreenArrowsDistance = function(enabled) ESP.Drawing.OffscreenArrows.ShowDistance = enabled end
ESP.SetOffscreenArrowsDistanceColor = function(color) if typeof(color) == "Color3" then ESP.Drawing.OffscreenArrows.DistanceRGB = color end end
ESP.SetOffscreenArrowsDistanceFontSize = function(size) if type(size) == "number" and size > 0 then ESP.Drawing.OffscreenArrows.DistanceFontSize = size end end

ESP.SetCornerColor     = function(c) if typeof(c) == "Color3" then ESP.Drawing.Boxes.Corner.RGB = c end end
ESP.SetCornerThickness = function(t) if type(t) == "number" and t > 0 then ESP.Drawing.Boxes.Corner.Thickness = t end end
ESP.SetCornerLength    = function(l) if type(l) == "number" and l > 0 then ESP.Drawing.Boxes.Corner.Length    = l end end

ESP.ToggleDroneChams = function(enabled)
    ESP.ObjectChams.Drones.Enabled = enabled
    if not enabled then
        for instance, h in pairs(ActiveObjectChams) do
            if instance.Name == "Drone" then
                h:Destroy()
                ActiveObjectChams[instance] = nil
            end
        end
    end
end

ESP.SetDroneChamsFill = function(color, trans)
    if typeof(color) == "Color3" then ESP.ObjectChams.Drones.FillRGB   = color end
    if type(trans)  == "number"  then ESP.ObjectChams.Drones.FillTrans = trans end
end

ESP.SetDroneChamsOutline = function(color, trans)
    if typeof(color) == "Color3" then ESP.ObjectChams.Drones.OutlineRGB   = color end
    if type(trans)  == "number"  then ESP.ObjectChams.Drones.OutlineTrans = trans end
end

ESP.ToggleClaymoreChams = function(enabled)
    ESP.ObjectChams.Claymores.Enabled = enabled
    if not enabled then
        for instance, h in pairs(ActiveObjectChams) do
            if instance.Name == "Claymore" then
                h:Destroy()
                ActiveObjectChams[instance] = nil
            end
        end
    end
end

ESP.SetClaymoreChamsFill = function(color, trans)
    if typeof(color) == "Color3" then ESP.ObjectChams.Claymores.FillRGB   = color end
    if type(trans)  == "number"  then ESP.ObjectChams.Claymores.FillTrans = trans end
end

ESP.SetClaymoreChamsOutline = function(color, trans)
    if typeof(color) == "Color3" then ESP.ObjectChams.Claymores.OutlineRGB   = color end
    if type(trans)  == "number"  then ESP.ObjectChams.Claymores.OutlineTrans = trans end
end

local function makeChamsAPI(key)
    ESP["Toggle" .. key .. "Chams"] = function(enabled)
        ESP.ObjectChams[key].Enabled = enabled
        if not enabled then
            for instance, h in pairs(ActiveObjectChams) do
                if instance.Name == key or
                   (key == "Drones" and instance.Name == "Drone") or
                   (key == "Claymores" and instance.Name == "Claymore") then
                    h:Destroy()
                    ActiveObjectChams[instance] = nil
                end
            end
        end
    end
    ESP["Set" .. key .. "ChamsFill"] = function(color, trans)
        if typeof(color) == "Color3" then ESP.ObjectChams[key].FillRGB   = color end
        if type(trans)  == "number"  then ESP.ObjectChams[key].FillTrans = trans end
    end
    ESP["Set" .. key .. "ChamsOutline"] = function(color, trans)
        if typeof(color) == "Color3" then ESP.ObjectChams[key].OutlineRGB   = color end
        if type(trans)  == "number"  then ESP.ObjectChams[key].OutlineTrans = trans end
    end
end

for _, key in ipairs({
    "ProximityAlarm", "StickyCamera", "RemoteC4", "ThermiteCharge",
    "ToxicCharge", "BreachCharge", "HardBreachCharge", "ShockBattery",
    "DeployableShield", "BarbedWire", "SignalDisruptor", "BulletproofCamera", "NeedleMine", "Camera",
}) do
    makeChamsAPI(key)
end

ESP.SetGadgetRenderMethod = function(method)
    if method == "Icon" or method == "Chams" then
        if ESP.ObjectChams.RenderMethod ~= method then
            for instance, espObject in pairs(ActiveObjectChams) do
                pcall(function() espObject:Destroy() end)
                ActiveObjectChams[instance] = nil
            end
        end
        ESP.ObjectChams.RenderMethod = method
    end
end

watchRealCharacters()
mvm()
st()

return ESP
