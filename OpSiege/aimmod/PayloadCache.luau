local PayloadCache = {}
PayloadCache.__index = PayloadCache

function PayloadCache.new()
	return setmetatable({
		DamageRemote = nil,
		Session = nil,
		GunName = nil,
		GunConfig = nil,
		AttachmentConfig = nil,
		_running = false,
	}, PayloadCache)
end

function PayloadCache:Start()
	if self._running then
		return
	end

	self._running = true
	task.spawn(function()
		while self._running and not self.DamageRemote do
			pcall(function()
				local replicatedStorage = game:GetService("ReplicatedStorage")
				for _, container in ipairs(replicatedStorage:GetChildren()) do
					local events = container:FindFirstChild("Events")
					local damage = events and events:FindFirstChild("Damage")
					if damage then
						self.DamageRemote = damage
						return
					end
				end
			end)
			task.wait(0.25)
		end
	end)
end

function PayloadCache:Stop()
	self._running = false
end

function PayloadCache:CaptureDamage(args)
	if typeof(args[11]) == "string" then
		self.Session = args[9]
		self.GunName = args[11]
		self.GunConfig = args[5]
		self.AttachmentConfig = args[6]
	end
end

function PayloadCache:TryWallbang(events, state, partIndex)
	if not self.DamageRemote then
		self.DamageRemote = events and events:FindFirstChild("Damage")
	end

	if not (self.DamageRemote and self.Session and self.GunName and self.GunConfig and self.AttachmentConfig) then
		return false
	end

	local ok = pcall(function()
		self.DamageRemote:FireServer(
			state.part,
			state.humanoid,
			0,
			partIndex,
			self.GunConfig,
			self.AttachmentConfig,
			nil,
			nil,
			self.Session,
			false,
			self.GunName
		)
	end)

	return ok
end

return PayloadCache
