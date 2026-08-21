local Players = game:GetService("Players")

local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(settings, scanner, patcher)
	return setmetatable({
		Settings = settings,
		Scanner = scanner,
		Patcher = patcher,
		LocalPlayer = Players.LocalPlayer,
		LastScan = 0,
		_running = false,
		_connections = {},
	}, Runtime)
end

function Runtime:IsAlive()
	local character = self.LocalPlayer and self.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

function Runtime:ScanNow()
	if not (self.Settings.Enabled and self:IsAlive()) then
		return 0, "not alive or disabled"
	end

	local now = os.clock()
	if now - self.LastScan < self.Settings.MinScanGap then
		return 0, "throttled"
	end

	self.LastScan = now
	return self.Scanner:Scan()
end

function Runtime:ReapplyKnown()
	if not self.Settings.Enabled then
		return self.Patcher.Store:RestoreAll()
	end
	return self.Patcher:ReapplyAll()
end

function Runtime:Start()
	if self._running then
		return
	end

	self._running = true
	task.delay(self.Settings.ScanDelay, function()
		if self._running then
			pcall(function()
				self:ScanNow()
			end)
		end
	end)

	if self.LocalPlayer then
		table.insert(self._connections, self.LocalPlayer.CharacterAdded:Connect(function()
			task.delay(self.Settings.ScanDelay, function()
				if self._running then
					pcall(function()
						self:ScanNow()
					end)
				end
			end)
		end))
	end

	task.spawn(function()
		while self._running do
			task.wait(self.Settings.ScanInterval)
			if self.Settings.BackgroundScan then
				pcall(function()
					self:ScanNow()
				end)
			end
		end
	end)
end

function Runtime:Stop()
	self._running = false
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

return Runtime
