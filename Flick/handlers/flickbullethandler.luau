local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local t = {}

t.__index = t
function t.new(p1, p2, p3, p4) --[[ new | Line: 20 | Upvalues: t (copy), Players (copy) ]]
	local v2 = setmetatable({}, t)

	v2.Gravity = p1 or 0
	v2.Wind = p2 or Vector3.new(0, 0, 0)
	v2.DespawnTime = p3 or 5
	v2.ShouldVisualize = p4 or false
	v2.Params = RaycastParams.new()
	v2.Params.FilterType = Enum.RaycastFilterType.Exclude

	local bulletStorage = workspace:FindFirstChild("bulletStorage")

	if not bulletStorage then
		local bulletStorage2 = Instance.new("Folder")

		bulletStorage2.Name = "bulletStorage"
		bulletStorage2.Parent = workspace
		bulletStorage = bulletStorage2
	end

	v2.Params.FilterDescendantsInstances = { Players.LocalPlayer.Character, bulletStorage }

	return v2
end
function t.Cast(p1, p2, p3, p4, p5) --[[ Cast | Line: 55 | Upvalues: RunService (copy) ]]
	local v1 = p4 - p3

	if v1.Magnitude < 0.01 then
		return p2, nil
	end

	local v2 = v1.Unit * p5 * 20.224489795918366
	local v4 = Vector3.new(p1.Wind.X, -p1.Gravity * workspace.Gravity, p1.Wind.Z)
	local v5 = 0
	local v6 = p3
	local v7 = nil
	local v8 = false
	local v9 = RunService.Heartbeat:Connect(function(p12) --[[ Line: 79 | Upvalues: v8 (ref), v5 (ref), p3 (copy), v2 (copy), v4 (copy), v6 (ref), v7 (ref), p1 (copy) ]]
		if v8 then
			return
		end

		v5 = v5 + p12

		local v42 = Vector3.new(p3.X + v2.X * v5 + v4.X * 0.5 * v5 ^ 2, p3.Y + v2.Y * v5 + v4.Y * 0.5 * v5 ^ 2, p3.Z + v2.Z * v5 + v4.Z * 0.5 * v5 ^ 2)

		v7 = workspace:Raycast(v6, v42 - v6, p1.Params)
		v6 = v42

		if p1.ShouldVisualize and v7 then
			local Part = Instance.new("Part")

			Part.Size = Vector3.new(1, 1, 1)
			Part.Position = v7.Position
			Part.Anchored = true
			Part.CanCollide = false
			Part.Material = Enum.Material.Neon
			Part.Color = Color3.new(255/255, 0/255, 0/255)
			Part.Shape = "Ball"
			Part.Parent = workspace
			game:GetService("Debris"):AddItem(Part, 2)
		end

		if not (v7 or v5 > p1.DespawnTime) then
			return
		end

		v8 = true
	end)

	while not v8 do
		RunService.Heartbeat:Wait()
	end

	v9:Disconnect()

	return p2, v7
end

return t

-- // Function Dumper made by King.Kevin
-- // Script Path: ReplicatedStorage.ModuleScripts.GunModules.Projectile

--[[
Function Dump: Cast

Function Upvalues: Cast
		1 [Instance] = Run Service

Function Constants: Cast
		1 [string] = Magnitude
		2 [number] = 0.01
		3 [number] = 20.224489795918366
		4 [string] = Unit
		5 [string] = Wind
		6 [string] = X
		7 [string] = Gravity
		8 [string] = workspace
		9 [Instance] = Workspace
		10 [string] = Z
		11 [string] = Vector3
		12 [string] = new
		13 [userdata] = userdata: 0x9f7907da9df27dd1
		14 [string] = Heartbeat
		15 [string] = Connect
		16 [string] = Wait
		17 [string] = Disconnect

====================================================================================================

Function Dump: new

Function Upvalues: new
		1 [table]:
		1 [table] table: 0xd5545fe690e381d1
				1 [function] = Cast
				2 [table] (Recursive table detected)
				3 [function] = new
		2 [Instance] = Players

Function Constants: new
		1 [string] = setmetatable
		2 [userdata] = userdata: 0x492ab93926455921
		3 [number] = 0
		4 [string] = Gravity
		5 [Vector3] = 0, 0, 0
		6 [string] = Wind
		7 [number] = 5
		8 [string] = DespawnTime
		9 [boolean] = false
		10 [string] = ShouldVisualize
		11 [string] = RaycastParams
		12 [string] = new
		13 [userdata] = userdata: 0x349ad4674208af71
		14 [string] = Params
		15 [string] = Enum
		16 [string] = RaycastFilterType
		17 [string] = Exclude
		18 [EnumItem] = Enum.RaycastFilterType.Exclude
		19 [string] = FilterType
		20 [string] = workspace
		21 [Instance] = Workspace
		22 [string] = bulletStorage
		23 [string] = FindFirstChild
		24 [string] = Instance
		25 [userdata] = userdata: 0xd0ee43f06e6bf641
		26 [string] = Folder
		27 [string] = Name
		28 [string] = Parent
		29 [string] = LocalPlayer
		30 [string] = Character
		31 [string] = FilterDescendantsInstances

====================================================================================================
]]
