local Players = game:GetService("Players")

local Targeting = {}
Targeting.__index = Targeting

function Targeting.new(settings)
	return setmetatable({
		Settings = settings,
		State = {
			active = false,
			humanoid = nil,
			part = nil,
			position = nil,
			lookVector = nil,
			player = nil,
			status = "waiting",
		},
		_running = false,
	}, Targeting)
end

function Targeting:_clear(status)
	local state = self.State
	state.active = false
	state.humanoid = nil
	state.part = nil
	state.position = nil
	state.lookVector = nil
	state.player = nil
	state.status = status or "no target"
end

function Targeting:_isEnemy(player, localPlayer, localTeam)
	if player == localPlayer then
		return false
	end

	if not self.Settings.TeamCheck then
		return true
	end

	local playerTeam = player.Team
	if playerTeam and (playerTeam.Name == "Spectator" or playerTeam.Name == "Spec") then
		return false
	end

	return localTeam ~= nil and playerTeam ~= localTeam
end

function Targeting:IsLocalPlayerAlive()
	local localPlayer = Players.LocalPlayer
	local character = localPlayer and localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

function Targeting:Refresh()
	if not self.Settings.AimEnabled then
		self:_clear("AimEnabled=false")
		return
	end

	local localPlayer = Players.LocalPlayer
	local character = localPlayer and localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (localPlayer and humanoid and humanoid.Health > 0) then
		self:_clear("you are not alive")
		return
	end

	local localTeam = localPlayer.Team
	if self.Settings.TeamCheck and localTeam == nil then
		self:_clear("warmup (no team)")
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		self:_clear("no camera")
		return
	end

	local cameraFrame = camera.CFrame
	local cameraPosition = cameraFrame.Position
	local cameraLook = cameraFrame.LookVector
	local bestAngle = self.Settings.AimFOV
	local bestTarget
	local enemiesScanned = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if self:_isEnemy(player, localPlayer, localTeam) then
			local playerCharacter = player.Character
			local playerHumanoid = playerCharacter and playerCharacter:FindFirstChildOfClass("Humanoid")
			local part = playerCharacter and playerCharacter:FindFirstChild(self.Settings.AimPart)

			if playerHumanoid and playerHumanoid.Health > 0 and part then
				enemiesScanned = enemiesScanned + 1
				local offset = part.Position - cameraPosition
				local distance = offset.Magnitude

				if distance > 0.01 and distance <= self.Settings.AimDistance then
					local direction = offset.Unit
					local dot = math.clamp(cameraLook:Dot(direction), -1, 1)
					local angle = math.deg(math.acos(dot))

					if angle < bestAngle then
						bestAngle = angle
						bestTarget = {
							humanoid = playerHumanoid,
							part = part,
							position = part.Position,
							lookVector = part.CFrame.LookVector,
							player = player,
						}
					end
				end
			end
		end
	end

	if not bestTarget then
		self:_clear(string.format("no enemy in cone (scanned %d)", enemiesScanned))
		return
	end

	local state = self.State
	state.active = true
	state.humanoid = bestTarget.humanoid
	state.part = bestTarget.part
	state.position = bestTarget.position
	state.lookVector = bestTarget.lookVector
	state.player = bestTarget.player
	state.status = string.format("LOCKED %s @ %.1f deg", bestTarget.player.Name, bestAngle)
end

function Targeting:Start()
	if self._running then
		return
	end

	self._running = true
	task.spawn(function()
		while self._running do
			local ok, err = pcall(function()
				self:Refresh()
			end)

			if not ok and self.Settings.Debug then
				warn("[AimMod.Targeting] refresh failed:", err)
			end

			task.wait(self.Settings.TargetRefreshRate)
		end
	end)
end

function Targeting:Stop()
	self._running = false
	self:_clear("stopped")
end

return Targeting
