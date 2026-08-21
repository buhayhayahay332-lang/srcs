local Settings = {
	AimEnabled = false,
	AimFOV = 10,
	AimDistance = 300,
	AimPart = "Head",
	TeamCheck = true,
	Wallbang = false,
	ShowFov = false,
	FovCircleColor = Color3.fromRGB(255, 255, 255),
}

local AIM_INDEX = { Head = 1, UpperTorso = 2 }

local Players = game:GetService("Players")
local newCclosure = newcclosure or function(f) return f end
local INSTANCE_TYPE = "Instance"

local targetCache = {
	active = false,
	humanoid = nil,
	head = nil,
	headPos = nil,
	headLook = nil,
	status = "waiting",
}

local function isEnemy(player, lp, lpTeam)
	if player == lp then return false end
	if not Settings.TeamCheck then return true end
	local pTeam = player.Team
	if pTeam and (pTeam.Name == "Spectator" or pTeam.Name == "Spec") then
		return false
	end
	if lpTeam == nil then
		return false
	end
	return pTeam ~= lpTeam
end

local function refreshTarget()
	targetCache.active = false
	if not Settings.AimEnabled then
		targetCache.status = "AimEnabled=false"
		return
	end
	local lp = Players.LocalPlayer
	if not lp then targetCache.status = "no LocalPlayer"; return end
	local lpChar = lp.Character
	local lpHum = lpChar and lpChar:FindFirstChildOfClass("Humanoid")
	if not (lpHum and lpHum.Health > 0) then targetCache.status = "you are not alive"; return end
	local lpTeam = lp.Team
	if Settings.TeamCheck and lpTeam == nil then targetCache.status = "warmup (no team)"; return end
	local camera = workspace.CurrentCamera
	if not camera then targetCache.status = "no camera"; return end
	local camPos = camera.CFrame.Position
	local camLook = camera.CFrame.LookVector
	local bestAngle = Settings.AimFOV
	local best = nil
	local enemiesScanned = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if isEnemy(player, lp, lpTeam) then
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					local head = char:FindFirstChild(Settings.AimPart)
					if head then
						enemiesScanned = enemiesScanned + 1
						local headPos = head.Position
						local dist = (headPos - camPos).Magnitude
						if dist <= Settings.AimDistance then
							local dir = (headPos - camPos).Unit
							local angle = math.deg(math.acos(math.clamp(camLook:Dot(dir), -1, 1)))
							if angle < bestAngle then
								bestAngle = angle
								best = { humanoid = hum, head = head, pos = headPos, look = head.CFrame.LookVector, name = player.Name }
							end
						end
					end
				end
			end
		end
	end
	if best then
		targetCache.active = true
		targetCache.humanoid = best.humanoid
		targetCache.head = best.head
		targetCache.headPos = best.pos
		targetCache.headLook = best.look
		targetCache.status = "LOCKED " .. best.name .. " @ " .. string.format("%.1f", bestAngle) .. "deg"
	else
		targetCache.status = "no enemy in cone (scanned " .. enemiesScanned .. " alive enemies)"
	end
end

local fovCircle = nil
local cachedDamageRemote = nil
local lastSession = nil
local lastGunName = nil
local lastGunConfig = nil
local lastAttConfig = nil
local lastWallbangLog = 0
local lastFireLog = 0
local lastRedirectLog = 0

local function Init()
	if getgenv().OpSiege_AimInstalled then return end
	getgenv().OpSiege_AimInstalled = true

	task.spawn(function()
		while true do
			task.wait(0.05)
			pcall(refreshTarget)
		end
	end)

	if getgenv().AimModFovCircle then
		pcall(function() getgenv().AimModFovCircle:Remove() end)
	end
	pcall(function()
		if Drawing and Drawing.new then
			fovCircle = Drawing.new("Circle")
			fovCircle.Visible = false
			fovCircle.Color = Settings.FovCircleColor
			fovCircle.Thickness = 1
			fovCircle.Filled = false
			fovCircle.NumSides = 64
			fovCircle.Transparency = 1
		end
	end)
	getgenv().AimModFovCircle = fovCircle

	task.spawn(function()
		while true do
			task.wait(0.1)
			local camera = workspace.CurrentCamera
			if fovCircle and camera then
				local vp = camera.ViewportSize
				if vp.X > 0 and vp.Y > 0 then
					local radius = (math.tan(math.rad(Settings.AimFOV)) / math.tan(math.rad(camera.FieldOfView / 2))) * (vp.Y / 2)
					fovCircle.Radius = radius
					fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
					fovCircle.Color = Settings.FovCircleColor
					fovCircle.Visible = Settings.AimEnabled and Settings.ShowFov
				else
					fovCircle.Visible = false
				end
			end
		end
	end)

	task.spawn(function()
		while not cachedDamageRemote do
			local ok, found = pcall(function()
				local rs = game:GetService("ReplicatedStorage")
				for _, container in ipairs(rs:GetChildren()) do
					local events = container:FindFirstChild("Events")
					if events then
						local dmg = events:FindFirstChild("Damage")
						if dmg then return dmg end
					end
				end
				return nil
			end)
			if ok and found then cachedDamageRemote = found end
			task.wait(0.25)
		end
	end)

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newCclosure(function(self, ...)
		local method = getnamecallmethod()
		if method == "FireServer" then
			if typeof(self) == INSTANCE_TYPE and self.ClassName == "RemoteEvent" then
				local parent = self.Parent
				if parent and parent.Name == "Events" then
					local name = self.Name
					if name == "Damage" or name == "HitEffect" then
						local args = { ... }
						local now = os.clock()
						if name == "Damage" and typeof(args[11]) == "string" then
							lastSession = args[9]
							lastGunName = args[11]
							lastGunConfig = args[5]
							lastAttConfig = args[6]
						end
						if now - lastFireLog > 1 then
							lastFireLog = now
						end
						if targetCache.active then
							if name == "Damage"
								and typeof(args[1]) == INSTANCE_TYPE
								and string.match(args[1].ClassName, "Part")
								and typeof(args[2]) == INSTANCE_TYPE and args[2].ClassName == "Humanoid"
								and typeof(args[11]) == "string" then
								args[1] = targetCache.head
								args[2] = targetCache.humanoid
								args[4] = AIM_INDEX[Settings.AimPart] or 1
								local results = { oldNamecall(self, table.unpack(args)) }
								return table.unpack(results)
							elseif name == "HitEffect"
								and typeof(args[5]) == "table" and args[5][1] == "Gun" then
								local originalHit = args[1]
								args[1] = targetCache.head
								args[2] = targetCache.headPos
								args[3] = targetCache.headLook
								local results = { oldNamecall(self, table.unpack(args)) }
								if Settings.Wallbang then
									if not cachedDamageRemote then
										cachedDamageRemote = self.Parent:FindFirstChild("Damage")
									end
									local isCharHit = false
									if originalHit and originalHit.Parent then
										isCharHit = originalHit.Parent:FindFirstChildOfClass("Humanoid") ~= nil
									end
									if not isCharHit and cachedDamageRemote and lastSession and lastGunName and lastGunConfig and lastAttConfig then
										pcall(function()
											cachedDamageRemote:FireServer(
												targetCache.head, targetCache.humanoid, 0,
												AIM_INDEX[Settings.AimPart] or 1,
												lastGunConfig, lastAttConfig, nil, nil,
												lastSession, false, lastGunName)
										end)
										local wNow = os.clock()
										if wNow - lastWallbangLog > 2 then
											lastWallbangLog = wNow
										end
									end
								end
								return table.unpack(results)
							end
						end
					end
				end
			end
		elseif method == "Raycast" and targetCache.active then
			local origin, direction, params = ...
			if params and params.CollisionGroup == "BulletCast" then
				local camera = workspace.CurrentCamera
				if camera then
					local camPos = camera.CFrame.Position
					local camLook = camera.CFrame.LookVector
					local odx = origin.X - camPos.X
					local ody = origin.Y - camPos.Y
					local odz = origin.Z - camPos.Z
					if math.sqrt(odx * odx + ody * ody + odz * odz) < 6 then
						local mag = direction.Magnitude
						if mag > 0.01 then
							local ux, uy, uz = direction.Unit.X, direction.Unit.Y, direction.Unit.Z
							local dot = camLook.X * ux + camLook.Y * uy + camLook.Z * uz
							if dot > 0.9 then
								local hx = targetCache.headPos.X - origin.X
								local hy = targetCache.headPos.Y - origin.Y
								local hz = targetCache.headPos.Z - origin.Z
								local hmag = math.sqrt(hx * hx + hy * hy + hz * hz)
								local newDir
								if hmag > 0.01 then
									newDir = Vector3.new(hx / hmag * mag, hy / hmag * mag, hz / hmag * mag)
								end
								if newDir then
									local results = { oldNamecall(self, origin, newDir, params) }
									local now = os.clock()
									if now - lastRedirectLog > 2 then
										lastRedirectLog = now
									end
									return table.unpack(results)
								end
							end
						end
					end
				end
			end
		end
		return oldNamecall(self, ...)
	end))
end

local function BuildTab(tab, Library)
	local Options = Library.Options

	local Left = tab:AddLeftGroupbox("Silent Aim")
	Left:AddToggle("AimEnabled", {
		Text = "Enabled",
		Default = Settings.AimEnabled,
		Callback = function(v) Settings.AimEnabled = v end,
	})
	Left:AddSlider("AimFOV", {
		Text = "FOV",
		Default = Settings.AimFOV, Min = 1, Max = 60, Rounding = 1,
		Callback = function(v) Settings.AimFOV = v end,
	})
	Left:AddSlider("AimDistance", {
		Text = "Max Distance",
		Default = Settings.AimDistance, Min = 50, Max = 1000, Rounding = 0,
		Callback = function(v) Settings.AimDistance = v end,
	})
	Left:AddDropdown("AimPart", {
		Text = "Target Part",
		Values = { "Head", "UpperTorso" },
		Default = Settings.AimPart,
		Callback = function(v) Settings.AimPart = v end,
	})
	Left:AddToggle("TeamCheck", {
		Text = "Team Check",
		Default = Settings.TeamCheck,
		Callback = function(v) Settings.TeamCheck = v end,
	})

	local Right = tab:AddRightGroupbox("Visuals / Wallbang")
	Right:AddToggle("Wallbang", {
		Text = "Wallbang",
		Default = Settings.Wallbang,
		Callback = function(v) Settings.Wallbang = v end,
	})
	Right:AddToggle("ShowFov", {
		Text = "Show FOV Circle",
		Default = Settings.ShowFov,
		Callback = function(v) Settings.ShowFov = v end,
	})
	Right:AddLabel("FOV Circle Color"):AddColorPicker("FovCircleColor", {
		Default = Settings.FovCircleColor,
		Callback = function(v) Settings.FovCircleColor = v end,
	})
	Right:AddDivider()
	Right:AddLabel("Status: waiting", false, "AimStatus")

	task.spawn(function()
		while task.wait(1) do
			if Library.Unloaded then break end
			pcall(function()
				if Options.AimStatus then
					Options.AimStatus:SetText("Status: " .. targetCache.status)
				end
			end)
		end
	end)
end

local function GetStatus()
	return targetCache.status
end

local M = {
	Settings = Settings,
	Init = Init,
	BuildTab = BuildTab,
	GetStatus = GetStatus,
	targetCache = targetCache,
}
getgenv().OperationSiege = getgenv().OperationSiege or {}
getgenv().OperationSiege.aimmod = M
return M
