--// ESP Framework made by @publicmain, github.com/pubmain, just added shit
--// Why not open source?, don't want my script with 5k lines xd
--//Please credit if using - astral

if not IB_OBFUSCATED then
    getfenv().IB_NO_VIRTUALIZE = function(...) return ... end
end

local Players    = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace  = cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer

local esp = {
    Classes     = {},
    Objects     = {},
    Connections = {},
    Gui         = Instance.new("ScreenGui", gethui()),

    FontSize = 12,
    Font,

    UpdateRate = 0.05,

    Bones = {
        R15 = {
            {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
            {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
            {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
            {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
            {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
        },
        R6 = {
            {"Head","Torso"},
            {"Torso","Left Arm"},{"Left Arm","Left Forearm"},{"Left Forearm","Left Hand"},
            {"Torso","Right Arm"},{"Right Arm","Right Forearm"},{"Right Forearm","Right Hand"},
            {"Torso","Left Leg"},{"Left Leg","Left Foot"},
            {"Torso","Right Leg"},{"Right Leg","Right Foot"},
        },
    },

    Configuration = {
        Enabled = false,

        TeamCheck = {
            Enabled       = false,
            UseTeamColors = false,
        },

        Box = {
            Style = "Dynamic",
            Type  = "Full",

            Fill = {
                Enabled      = false,
                Color        = Color3.new(1, 1, 1),
                Transparency = { 0.3, 0.8 },
                Gradient = {
                    Enabled  = false,
                    Rotation = -90,
                    Color    = {
                        Color3.fromRGB(255, 255, 255),
                        Color3.fromRGB(255, 255, 255),
                    },
                },
            },

            Outline = {
                Enabled      = false,
                Color        = Color3.fromRGB(255, 255, 255),
                Thickness    = 1,
                CornerLength = 12,
            },

            Glow = {
                Enabled      = false,
                Image        = "rbxassetid://90231585382483",
                Transparency = 0,
                Color        = Color3.new(1, 1, 1),
                Gradient = {
                    Enabled  = false,
                    Rotation = 0,
                    Color    = {
                        Color3.new(1, 1, 1),
                        Color3.new(0.8, 0.8, 1),
                    },
                },
            },

            GetStyle = function(Type, cachedParts, camera)
                Type = Type or "Dynamic"
                if not camera or not cachedParts or #cachedParts == 0 then return nil, nil end

                local min_x, min_y, min_z =  math.huge,  math.huge,  math.huge
                local max_x, max_y, max_z = -math.huge, -math.huge, -math.huge

                if Type == "Static" then
                    for _, part in cachedParts do
                        if part.Name == "HumanoidRootPart" and part.Parent then
                            local p  = part.Position
                            local s  = part.Size
                            local hx = s.X * 0.5
                            local hy = s.Y * 0.5
                            local hz = s.Z * 0.5
                            min_x = p.X - hx; max_x = p.X + hx
                            min_y = p.Y - hy; max_y = p.Y + hy
                            min_z = p.Z - hz; max_z = p.Z + hz
                            break
                        end
                    end
                else
                    for _, part in cachedParts do
                        if part.Parent then
                            local p  = part.Position
                            local s  = part.Size
                            local hx = s.X * 0.5
                            local hy = s.Y * 0.5
                            local hz = s.Z * 0.5
                            if p.X - hx < min_x then min_x = p.X - hx end
                            if p.Y - hy < min_y then min_y = p.Y - hy end
                            if p.Z - hz < min_z then min_z = p.Z - hz end
                            if p.X + hx > max_x then max_x = p.X + hx end
                            if p.Y + hy > max_y then max_y = p.Y + hy end
                            if p.Z + hz > max_z then max_z = p.Z + hz end
                        end
                    end
                end

                if max_x == -math.huge then return nil, nil end

                local sc_min_x, sc_min_y =  math.huge,  math.huge
                local sc_max_x, sc_max_y = -math.huge, -math.huge
                local anyOn = false

                local function proj(x, y, z)
                    local sp = camera:WorldToViewportPoint(Vector3.new(x, y, z))
                    if sp.Z > 0 then -- in front of the camera (skip mirrored behind-camera points)
                        anyOn = true
                        if sp.X < sc_min_x then sc_min_x = sp.X end
                        if sp.Y < sc_min_y then sc_min_y = sp.Y end
                        if sp.X > sc_max_x then sc_max_x = sp.X end
                        if sp.Y > sc_max_y then sc_max_y = sp.Y end
                    end
                end

                proj(min_x, min_y, min_z); proj(min_x, min_y, max_z)
                proj(min_x, max_y, min_z); proj(min_x, max_y, max_z)
                proj(max_x, min_y, min_z); proj(max_x, min_y, max_z)
                proj(max_x, max_y, min_z); proj(max_x, max_y, max_z)

                if not anyOn then return nil, nil end

                -- clamp to the viewport so targets that fill the screen
                -- (or extend past the edges) still get a visible box
                local vp = camera.ViewportSize
                sc_min_x = math.clamp(sc_min_x, 0, vp.X)
                sc_min_y = math.clamp(sc_min_y, 0, vp.Y)
                sc_max_x = math.clamp(sc_max_x, 0, vp.X)
                sc_max_y = math.clamp(sc_max_y, 0, vp.Y)

                if sc_max_x - sc_min_x <= 0 or sc_max_y - sc_min_y <= 0 then return nil, nil end
                return Vector2.new(sc_min_x, sc_min_y), Vector2.new(sc_max_x - sc_min_x, sc_max_y - sc_min_y)
            end,
        },

        HealthBar = {
            Enabled   = false,
            Position  = "Left",
            Animated  = false,
            AnimSpeed = 1,

            Color = {
                High   = Color3.fromRGB(131, 245, 78),
                Medium = Color3.fromRGB(255, 255, 0),
                Low    = Color3.fromRGB(252, 71, 77),
            },

            GetHealth = function(humanoid)
                if not humanoid or humanoid.MaxHealth == 0 then return 1 end
                return math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            end,

            Text = {
                Enabled      = false,
                Color        = Color3.fromRGB(255, 255, 255),
                Transparency = 0,

                GetText = function(humanoid)
                    if not humanoid then return "0", false end
                    return tostring(math.floor(humanoid.Health)), humanoid.Health ~= humanoid.MaxHealth
                end,
            },
        },

        Name = {
            Enabled      = false,
            Color        = Color3.fromRGB(255, 255, 255),
            Transparency = 0,
        },

        Distance = {
            Enabled      = false,
            Color        = Color3.fromRGB(235, 235, 235),
            Transparency = 0,
            Format       = function(d) return string.format("%dst", d) end,
        },

        Tool = {
            Enabled      = false,
            Color        = Color3.fromRGB(235, 235, 235),
            Transparency = 0,
            NoToolText   = "none",
        },

        Flags = {
            Enabled = false,
            Offset  = 4,
        },
    },
}

if not isfile("main.ttf") then
    writefile(
        "main.ttf",
        game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/fs-tahoma-8px.ttf")
    )
end

local fontData = {
    name = "SmallestPixel7",
    faces = {
        {
            name    = "Regular",
            weight  = 400,
            style   = "normal",
            assetId = getcustomasset("main.ttf"),
        },
    },
}

if not isfile("main_encoded.ttf") then
    writefile("main_encoded.ttf", game:GetService("HttpService"):JSONEncode(fontData))
end

esp.Font = Font.new(getcustomasset("main_encoded.ttf"), Enum.FontWeight.Regular)

esp.Gui.ClipToDeviceSafeArea = false
esp.Gui.IgnoreGuiInset       = true
esp.Gui.Name                 = ""

local function makeLabel(parent)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3       = Color3.new(0, 0, 0)
    lbl.FontFace               = esp.Font
    lbl.TextSize               = esp.FontSize
    lbl.Size                   = UDim2.new(0, 100, 0, esp.FontSize + 2)
    lbl.Parent                 = parent
    return lbl
end

local function makeFrame(parent, z, color, transparency)
    local f = Instance.new("Frame", parent)
    f.BackgroundColor3       = color
    f.BackgroundTransparency = transparency or 0
    f.BorderSizePixel        = 0
    f.ZIndex                 = z
    return f
end

local function buildCorners(parent, thickness, length, color, shadowColor)
    local t   = thickness
    local cl  = length
    local out = {}

    local defs = {
        { ax = 0, ay = 0 },
        { ax = 1, ay = 0 },
        { ax = 0, ay = 1 },
        { ax = 1, ay = 1 },
    }

    for _, d in defs do
        local px = d.ax
        local py = d.ay
        local ox = d.ax == 0 and 0 or -cl
        local oy = d.ay == 0 and 0 or -cl

        local sh = makeFrame(parent, 1, shadowColor)
        sh.AnchorPoint = Vector2.new(d.ax, d.ay)
        sh.Size        = UDim2.new(0, cl + 1, 0, t + 2)
        sh.Position    = UDim2.new(px, ox - 1, py, oy - 1)

        local sv = makeFrame(parent, 1, shadowColor)
        sv.AnchorPoint = Vector2.new(d.ax, d.ay)
        sv.Size        = UDim2.new(0, t + 2, 0, cl + 1)
        sv.Position    = UDim2.new(px, ox - 1, py, oy - 1)

        local ch = makeFrame(parent, 2, color)
        ch.AnchorPoint = Vector2.new(d.ax, d.ay)
        ch.Size        = UDim2.new(0, cl, 0, t)
        ch.Position    = UDim2.new(px, ox, py, oy)

        local cv = makeFrame(parent, 2, color)
        cv.AnchorPoint = Vector2.new(d.ax, d.ay)
        cv.Size        = UDim2.new(0, t, 0, cl)
        cv.Position    = UDim2.new(px, ox, py, oy)

        table.insert(out, sh)
        table.insert(out, sv)
        table.insert(out, ch)
        table.insert(out, cv)
    end

    return out
end

function esp:Register(className, create, update, destroy, setVisible)
    if self.Classes[className] then error(`class "{className}" already exists`) end
    self.Classes[className] = {
        name        = className,
        create      = create,
        update      = update,
        destroy     = destroy,
        set_visible = setVisible,
    }
end

function esp:Create(className, instance)
    if self.Objects[instance] then return end
    local class = self.Classes[className]
    if not class then error(`no class "{className}"`) end
    local obj = class.create(instance)
    if not obj then return end
    obj.__class = class
    setmetatable(obj, { __index = class })
    self.Objects[instance] = obj
    return obj
end

function esp:ImplementCharacterClass()
    esp:Register(
        "character",

        function(character)
            local cfg     = esp.Configuration
            local hbCfg   = cfg.HealthBar
            local boxCfg  = cfg.Box
            local fillCfg = boxCfg.Fill
            local outCfg  = boxCfg.Outline
            local glowCfg = boxCfg.Glow

            local cachedParts = {}
            for _, v in character:GetDescendants() do
                if v:IsA("BasePart") and not v:FindFirstAncestorWhichIsA("Tool") then
                    cachedParts[#cachedParts + 1] = v
                end
            end

            local partConns = {}
            partConns[1] = character.DescendantAdded:Connect(function(d)
                if d:IsA("BasePart") and not d:FindFirstAncestorWhichIsA("Tool") then
                    cachedParts[#cachedParts + 1] = d
                end
            end)
            partConns[2] = character.DescendantRemoving:Connect(function(d)
                if d:IsA("BasePart") then
                    for i = #cachedParts, 1, -1 do
                        if cachedParts[i] == d then
                            table.remove(cachedParts, i)
                            break
                        end
                    end
                end
            end)

            local cachedHumanoid = character:FindFirstChildWhichIsA("Humanoid")
            local cachedHead     = character:FindFirstChild("Head")

            local holder = Instance.new("Frame", esp.Gui)
            holder.BackgroundTransparency = 1
            holder.ClipsDescendants       = false
            holder.ZIndex                 = 1

            local box = Instance.new("Frame", holder)
            box.Name            = ""
            box.Size            = UDim2.new(1, 0, 1, 0)
            box.BorderSizePixel = 0
            box.ZIndex          = 2

            local glow, glowGradient
            if glowCfg.Enabled then
                glow = Instance.new("ImageLabel", box)
                glow.Name                   = ""
                glow.Image                  = glowCfg.Image
                glow.BackgroundTransparency = 1
                glow.ImageTransparency      = glowCfg.Transparency
                glow.ImageColor3            = glowCfg.Color
                glow.ZIndex                 = 1
                glow.Size                   = UDim2.new(1, 45, 1, 45)
                glow.Position               = UDim2.new(0, -23, 0, -23)
                glow.ScaleType              = Enum.ScaleType.Slice
                glow.SliceCenter            = Rect.new(21, 21, 79, 79)

                if glowCfg.Gradient.Enabled then
                    glowGradient = Instance.new("UIGradient", glow)
                    local seq = {}
                    local colors = glowCfg.Gradient.Color
                    for i, c in ipairs(colors) do
                        table.insert(seq, ColorSequenceKeypoint.new((i-1) / math.max(#colors-1, 1), c))
                    end
                    glowGradient.Color    = ColorSequence.new(seq)
                    glowGradient.Rotation = glowCfg.Gradient.Rotation
                end
            end

            -- Build every box primitive up front. The configuration can change
            -- after a character object is created, so lazy creation here would
            -- leave existing players without boxes when the UI toggle changes.
            local boxGradient = Instance.new("UIGradient", box)
            boxGradient.Color = ColorSequence.new(fillCfg.Color)
            box.BackgroundColor3 = fillCfg.Color
            box.BackgroundTransparency = 1

            local boxOutline = Instance.new("UIStroke", box)
            boxOutline.Name         = "outline"
            boxOutline.Thickness    = outCfg.Thickness
            boxOutline.Color        = outCfg.Color
            boxOutline.LineJoinMode = Enum.LineJoinMode.Miter
            boxOutline.ZIndex       = 2
            boxOutline.Enabled      = false

            local boxBorder = Instance.new("UIStroke", box)
            boxBorder.Name         = "border"
            boxBorder.Color        = Color3.new(0, 0, 0)
            boxBorder.Thickness    = 3
            boxBorder.LineJoinMode = Enum.LineJoinMode.Miter
            boxBorder.ZIndex       = 1
            boxBorder.BorderOffset = UDim.new(0, -1)
            boxBorder.Enabled      = false

            local cornerFrames = buildCorners(holder, outCfg.Thickness, outCfg.CornerLength, outCfg.Color, Color3.new(0,0,0))
            for _, f in cornerFrames do f.Visible = false end

            local hbHolder = Instance.new("Frame", holder)
            hbHolder.Name             = "HealthbarHolder"
            hbHolder.BackgroundColor3 = Color3.new(0, 0, 0)
            hbHolder.BorderSizePixel  = 0
            hbHolder.ZIndex           = 5

            local hbOutline = Instance.new("UIStroke", hbHolder)
            hbOutline.Color        = Color3.new(0, 0, 0)
            hbOutline.Thickness    = 1
            hbOutline.LineJoinMode = Enum.LineJoinMode.Round

            local hbFill = Instance.new("Frame", hbHolder)
            hbFill.Name             = "Fill"
            hbFill.BackgroundColor3 = Color3.new(1, 1, 1)
            hbFill.BorderSizePixel  = 0
            hbFill.AnchorPoint      = Vector2.new(0, 1)
            hbFill.ZIndex           = 6

            local hbGradient = Instance.new("UIGradient", hbFill)
            hbGradient.Rotation = 90
            hbGradient.Color    = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   hbCfg.Color.High),
                ColorSequenceKeypoint.new(0.5, hbCfg.Color.Medium),
                ColorSequenceKeypoint.new(1,   hbCfg.Color.Low),
            })

            local hbText = makeLabel(holder)
            hbText.Name             = "HealthText"
            hbText.TextColor3       = hbCfg.Text.Color
            hbText.TextTransparency = hbCfg.Text.Transparency
            hbText.TextSize         = esp.FontSize
            hbText.Size             = UDim2.new(0, 30, 0, esp.FontSize + 2)
            hbText.ZIndex           = 8

            local topContainer = Instance.new("Frame", holder)
            topContainer.Name                   = "TopLabels"
            topContainer.BackgroundTransparency = 1
            topContainer.Size                   = UDim2.new(1, 0, 0, 0)
            topContainer.Position               = UDim2.new(0, 0, 0, -3)
            topContainer.ZIndex                 = 4
            local topLayout = Instance.new("UIListLayout", topContainer)
            topLayout.FillDirection       = Enum.FillDirection.Vertical
            topLayout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
            topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            topLayout.Padding             = UDim.new(0, 0)

            local nameLabel = makeLabel(topContainer)
            nameLabel.Name             = "NameLabel"
            nameLabel.TextXAlignment   = Enum.TextXAlignment.Center
            nameLabel.TextColor3       = cfg.Name.Color
            nameLabel.TextTransparency = cfg.Name.Transparency
            nameLabel.ZIndex           = 4

            local bottomContainer = Instance.new("Frame", holder)
            bottomContainer.Name                   = "BottomLabels"
            bottomContainer.BackgroundTransparency = 1
            bottomContainer.Size                   = UDim2.new(1, 0, 0, 0)
            bottomContainer.Position               = UDim2.new(0, 0, 1, 3)
            bottomContainer.ZIndex                 = 4
            local botLayout = Instance.new("UIListLayout", bottomContainer)
            botLayout.FillDirection       = Enum.FillDirection.Vertical
            botLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
            botLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            botLayout.Padding             = UDim.new(0, 0)

            local distLabel = makeLabel(bottomContainer)
            distLabel.Name             = "DistLabel"
            distLabel.TextXAlignment   = Enum.TextXAlignment.Center
            distLabel.TextColor3       = cfg.Distance.Color
            distLabel.TextTransparency = cfg.Distance.Transparency
            distLabel.ZIndex           = 4

            local toolLabel = makeLabel(bottomContainer)
            toolLabel.Name             = "ToolLabel"
            toolLabel.TextXAlignment   = Enum.TextXAlignment.Center
            toolLabel.TextColor3       = cfg.Tool.Color
            toolLabel.TextTransparency = cfg.Tool.Transparency
            toolLabel.ZIndex           = 4

            local flagsContainer = Instance.new("Frame", holder)
            flagsContainer.Name                   = "Flags"
            flagsContainer.BackgroundTransparency = 1
            flagsContainer.Size                   = UDim2.new(0, 80, 1, 0)
            flagsContainer.Position               = UDim2.new(1, cfg.Flags.Offset, 0, 0)
            flagsContainer.ZIndex                 = 10
            flagsContainer.ClipsDescendants       = false
            local flagLayout = Instance.new("UIListLayout", flagsContainer)
            flagLayout.FillDirection     = Enum.FillDirection.Vertical
            flagLayout.VerticalAlignment = Enum.VerticalAlignment.Top
            flagLayout.Padding           = UDim.new(0, 1)

            return {
                model          = character,
                holder         = holder,
                glow           = glow,
                glowGradient   = glowGradient,
                box            = box,
                boxGradient    = boxGradient,
                boxOutline     = boxOutline,
                boxBorder      = boxBorder,
                cornerFrames   = cornerFrames,
                hbHolder       = hbHolder,
                hbFill         = hbFill,
                hbGradient     = hbGradient,
                hbText         = hbText,
                nameLabel      = nameLabel,
                distLabel      = distLabel,
                toolLabel      = toolLabel,
                flagsContainer = flagsContainer,

                cachedParts    = cachedParts,
                partConns      = partConns,
                cachedHumanoid = cachedHumanoid,
                cachedHead     = cachedHead,

                lastUpdate     = 0,
                cachedFlags    = {},
                lastHealth     = 1,
                lastToolName   = "",
            }
        end,

        IB_NO_VIRTUALIZE(function(character, obj)
            local cfg      = esp.Configuration
            local boxCfg   = cfg.Box
            local outCfg   = boxCfg.Outline
            local fillCfg  = boxCfg.Fill
            local glowCfg  = boxCfg.Glow
            local hbCfg    = cfg.HealthBar
            local teamCfg  = cfg.TeamCheck

            local now = tick()
            local dt  = now - obj.lastUpdate

            local fullUpdate = dt >= esp.UpdateRate

            if not cfg.Enabled then
                obj.holder.Visible = false
                return false
            end

            local camera = Workspace.CurrentCamera
            if not camera then
                obj.holder.Visible = false
                return false
            end

            local humanoid = obj.cachedHumanoid
            local head     = obj.cachedHead

            if not head or not humanoid or humanoid.Health <= 0 then
                obj.holder.Visible = false
                return false
            end

            local player = Players:GetPlayerFromCharacter(obj.model)
            if teamCfg.Enabled and player and player ~= LocalPlayer then
                if LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
                    obj.holder.Visible = false
                    return false
                end
            end

            local _, onScreen = camera:WorldToViewportPoint(head.Position)
            if not onScreen then
                obj.holder.Visible = false
                return false
            end

            local position, size = boxCfg.GetStyle(boxCfg.Style, obj.cachedParts, camera)
            if not position or not size then
                obj.holder.Visible = false
                return false
            end

            obj.holder.Visible  = true
            obj.holder.Position = UDim2.new(0, position.X, 0, position.Y)
            obj.holder.Size     = UDim2.new(0, size.X, 0, size.Y)

            if fullUpdate then
                obj.lastUpdate = now

                local teamColor = nil
                if teamCfg.UseTeamColors and player and player.Team then
                    teamColor = player.TeamColor.Color
                end

                if obj.boxGradient then
                    if fillCfg.Gradient.Enabled then
                        local seq = {}
                        local colors = fillCfg.Gradient.Color
                        for i, color in ipairs(colors) do
                            if i == 1 then color = teamColor or color end
                            table.insert(seq, ColorSequenceKeypoint.new((i - 1) / math.max(#colors - 1, 1), color))
                        end
                        obj.boxGradient.Color = ColorSequence.new(seq)
                        obj.boxGradient.Rotation = fillCfg.Gradient.Rotation
                    else
                        local color = teamColor or fillCfg.Color
                        obj.boxGradient.Color = ColorSequence.new(color)
                        obj.boxGradient.Rotation = 0
                    end

                    local transparency = fillCfg.Transparency
                    if type(transparency) == "table" then
                        obj.boxGradient.Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, transparency[1]),
                            NumberSequenceKeypoint.new(1, transparency[2]),
                        })
                    else
                        obj.boxGradient.Transparency = NumberSequence.new(transparency)
                    end
                end

                if obj.boxOutline then
                    obj.boxOutline.Color     = teamColor or outCfg.Color
                    obj.boxOutline.Thickness = outCfg.Thickness
                end
            end

            if obj.boxGradient then
                if not fillCfg.Enabled then
                    obj.box.BackgroundTransparency = 1
                elseif type(fillCfg.Transparency) == "table" then
                    obj.box.BackgroundTransparency = 0
                else
                    obj.box.BackgroundTransparency = fillCfg.Transparency
                end
            end

            if obj.glow then
                obj.glow.Visible = glowCfg.Enabled
            end

            local isCorners = outCfg.Enabled and boxCfg.Type == "Corners"
            local isFull    = outCfg.Enabled and boxCfg.Type == "Full"
            obj.boxOutline.Enabled = isFull
            obj.boxBorder.Enabled  = isFull
            for _, f in obj.cornerFrames do
                f.Visible = isCorners
            end

            if hbCfg.Enabled then
                obj.hbHolder.Visible = true

                local pct = hbCfg.GetHealth(humanoid)
                local pos = hbCfg.Position
                local gap = 4

                if math.abs(pct - obj.lastHealth) > 0.01 or fullUpdate then
                    obj.lastHealth = pct

                    if pos == "Left" then
                        obj.hbHolder.AnchorPoint = Vector2.new(1, 0)
                        obj.hbHolder.Position    = UDim2.new(0, -gap, 0, -1)
                        obj.hbHolder.Size        = UDim2.new(0, 1, 1, 2)
                        obj.hbFill.AnchorPoint   = Vector2.new(0, 1)
                        obj.hbFill.Position      = UDim2.new(0, 0, 1, 0)
                        obj.hbFill.Size          = UDim2.new(1, 0, pct, 0)
                        obj.hbGradient.Rotation  = 90
                    elseif pos == "Right" then
                        obj.hbHolder.AnchorPoint = Vector2.new(0, 0)
                        obj.hbHolder.Position    = UDim2.new(1, gap, 0, -1)
                        obj.hbHolder.Size        = UDim2.new(0, 1, 1, 2)
                        obj.hbFill.AnchorPoint   = Vector2.new(0, 1)
                        obj.hbFill.Position      = UDim2.new(0, 0, 1, 0)
                        obj.hbFill.Size          = UDim2.new(1, 0, pct, 0)
                        obj.hbGradient.Rotation  = 90
                    elseif pos == "Top" then
                        obj.hbHolder.AnchorPoint = Vector2.new(0, 1)
                        obj.hbHolder.Position    = UDim2.new(0, 0, 0, -gap)
                        obj.hbHolder.Size        = UDim2.new(1, 0, 0, 4)
                        obj.hbFill.AnchorPoint   = Vector2.new(0, 0)
                        obj.hbFill.Position      = UDim2.new(0, 0, 0, 0)
                        obj.hbFill.Size          = UDim2.new(pct, 0, 1, 0)
                        obj.hbGradient.Rotation  = 0
                    elseif pos == "Bottom" then
                        obj.hbHolder.AnchorPoint = Vector2.new(0, 0)
                        obj.hbHolder.Position    = UDim2.new(0, 0, 1, gap)
                        obj.hbHolder.Size        = UDim2.new(1, 0, 0, 4)
                        obj.hbFill.AnchorPoint   = Vector2.new(0, 0)
                        obj.hbFill.Position      = UDim2.new(0, 0, 0, 0)
                        obj.hbFill.Size          = UDim2.new(pct, 0, 1, 0)
                        obj.hbGradient.Rotation  = 0
                    end

                    if hbCfg.Animated then
                        local hc1 = hbCfg.Color.High
                        local hc2 = hbCfg.Color.Medium
                        local hc3 = hbCfg.Color.Low
                        local spd = math.max(hbCfg.AnimSpeed or 1, 0.01)
                        local p   = (now * spd) % 3

                        local function sampleHealth(s)
                            s = s % 3
                            if s < 1 then     return hc1:Lerp(hc2, s)
                            elseif s < 2 then return hc2:Lerp(hc3, s - 1)
                            else              return hc3:Lerp(hc1, s - 2) end
                        end

                        obj.hbGradient.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0,   sampleHealth(p)),
                            ColorSequenceKeypoint.new(0.5, sampleHealth(p + 1)),
                            ColorSequenceKeypoint.new(1,   sampleHealth(p + 2)),
                        })
                    end

                    if hbCfg.Text.Enabled then
                        local hpText, showText = hbCfg.Text.GetText(humanoid)
                        obj.hbText.Text    = hpText
                        obj.hbText.Visible = showText
                        if showText then
                            if pos == "Left" then
                                obj.hbText.AnchorPoint    = Vector2.new(1, 0)
                                obj.hbText.TextXAlignment = Enum.TextXAlignment.Right
                                obj.hbText.Position       = UDim2.new(0, -2, 1 - pct, 0)
                            elseif pos == "Right" then
                                obj.hbText.AnchorPoint    = Vector2.new(0, 0)
                                obj.hbText.TextXAlignment = Enum.TextXAlignment.Left
                                obj.hbText.Position       = UDim2.new(1, 2, 1 - pct, 0)
                            elseif pos == "Top" then
                                obj.hbText.AnchorPoint    = Vector2.new(0, 1)
                                obj.hbText.TextXAlignment = Enum.TextXAlignment.Left
                                obj.hbText.Position       = UDim2.new(0, 2, 0, -2)
                            elseif pos == "Bottom" then
                                obj.hbText.AnchorPoint    = Vector2.new(0, 0)
                                obj.hbText.TextXAlignment = Enum.TextXAlignment.Left
                                obj.hbText.Position       = UDim2.new(0, 2, 1, 2)
                            end
                        end
                    else
                        obj.hbText.Visible = false
                    end
                end
            else
                obj.hbHolder.Visible = false
                obj.hbText.Visible   = false
            end

            if fullUpdate then
                if cfg.Name.Enabled then
                    obj.nameLabel.Visible = true
                    obj.nameLabel.Text    = obj.model.Name
                else
                    obj.nameLabel.Visible = false
                end

                if cfg.Distance.Enabled then
                    obj.distLabel.Visible = true
                    local dist = math.round((camera.CFrame.Position - head.Position).Magnitude)
                    obj.distLabel.Text    = cfg.Distance.Format(dist)
                else
                    obj.distLabel.Visible = false
                end

                if cfg.Tool.Enabled then
                    local tool     = obj.model:FindFirstChildWhichIsA("Tool")
                    local toolName = tool and tool.Name or cfg.Tool.NoToolText
                    if toolName ~= obj.lastToolName then
                        obj.lastToolName   = toolName
                        obj.toolLabel.Text = toolName
                    end
                    obj.toolLabel.Visible = true
                else
                    obj.toolLabel.Visible = false
                end

                if cfg.Flags.Enabled then
                    obj.flagsContainer.Visible  = true
                    obj.flagsContainer.Size     = UDim2.new(0, 80, 1, 0)
                    obj.flagsContainer.Position = UDim2.new(1, cfg.Flags.Offset, 0, 0)

                    local flags = {}

                    local state     = humanoid:GetState()
                    local stateStr  = tostring(state)
                    local stateName = stateStr:match("HumanoidStateType%.(.+)$")
                    if stateName and stateName ~= "Running" and stateName ~= "None" then
                        table.insert(flags, { text = stateName, color = Color3.fromRGB(255, 220, 80) })
                    end

                    local rootPart = obj.model:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local spd = math.round(Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z).Magnitude)
                        if spd > 24 then
                            table.insert(flags, { text = spd .. " spd", color = Color3.fromRGB(255, 100, 100) })
                        end
                    end

                    if player and player:GetAttribute("Cheating") then
                        table.insert(flags, { text = "Exploiting", color = Color3.fromRGB(255, 60, 60) })
                    end

                    for i, flag in ipairs(flags) do
                        local label = obj.cachedFlags[i]
                        if not label then
                            label = makeLabel(obj.flagsContainer)
                            label.TextXAlignment   = Enum.TextXAlignment.Left
                            label.TextSize         = esp.FontSize
                            label.Size             = UDim2.new(1, 0, 0, esp.FontSize + 2)
                            label.ZIndex           = 10
                            obj.cachedFlags[i]     = label
                        end
                        label.Text       = flag.text
                        label.TextColor3 = flag.color
                        label.Visible    = true
                    end

                    for i = #flags + 1, #obj.cachedFlags do
                        obj.cachedFlags[i].Visible = false
                    end
                else
                    obj.flagsContainer.Visible = false
                end
            end

            return false
        end),

        function(obj)
            for _, c in obj.partConns do
                pcall(function() c:Disconnect() end)
            end
            obj.holder:Destroy()
            table.clear(obj.cachedFlags)
        end,

        function(obj, visible)
            obj.holder.Visible = visible
        end
    )
end

function esp:ImplementPlayerESP(showLocal)
    if not esp.Classes.character then
        esp:ImplementCharacterClass()
    end

    local function onPlayerAdded(player)
        local obj

        local function onCharAdded(char)
            if obj then obj:destroy() end
            if not char or not char.Parent then return end

            local humanoid = char:FindFirstChildOfClass("Humanoid")
                or char:WaitForChild("Humanoid", 10)
            local head = char:FindFirstChild("Head")
                or char:WaitForChild("Head", 10)
            if not humanoid or not head or not char.Parent then return end

            obj = esp:Create("character", char)
        end

        table.insert(esp.Connections, player.CharacterAdded:Connect(onCharAdded))
        table.insert(esp.Connections, player.CharacterRemoving:Connect(function()
            if obj then obj:destroy() obj = nil end
        end))

        if player.Character then
            task.spawn(onCharAdded, player.Character)
        end
    end

    for _, p in Players:GetPlayers() do
        if not showLocal and p == LocalPlayer then continue end
        onPlayerAdded(p)
    end
    table.insert(esp.Connections, Players.PlayerAdded:Connect(onPlayerAdded))
end

function esp:Destroy()
    for _, c in esp.Connections do c:Disconnect() end
    table.clear(esp.Connections)
    for _, o in esp.Objects do o:destroy() end
    table.clear(esp.Objects)
    table.clear(esp.Classes)
    esp.Gui:Destroy()
end

table.insert(esp.Connections, RunService.Heartbeat:Connect(IB_NO_VIRTUALIZE(function()
    for instance, object in esp.Objects do
        local ok, result = pcall(object.update, instance, object)
        if not ok then
            esp.Objects[instance] = nil
            task.spawn(error, result)
            pcall(object.destroy, object)
        elseif result then
            esp.Objects[instance] = nil
            object:destroy()
        end
    end
end)))

esp:ImplementPlayerESP(false)

return esp
