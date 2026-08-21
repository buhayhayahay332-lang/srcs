local Hook = {}
Hook.__index = Hook

local INSTANCE_TYPE = "Instance"

local function getEnvironment()
	return type(getgenv) == "function" and getgenv() or _G
end

function Hook.new(settings, targetState, payloadCache, getAimPartIndex)
	return setmetatable({
		Settings = settings,
		TargetState = targetState,
		PayloadCache = payloadCache,
		GetAimPartIndex = getAimPartIndex,
		Installed = false,
		OldNamecall = nil,
		_lastRedirectLog = 0,
	}, Hook)
end

function Hook:Install()
	if self.Installed then
		return true
	end

	if type(hookmetamethod) ~= "function" then
		return false, "hookmetamethod is unavailable"
	end

	local environment = getEnvironment()
	if environment.OperationSiegeAimHookInstalled then
		return false, "an aim hook is already installed"
	end

	environment.OperationSiegeAimHookInstalled = true
	local newCclosure = newcclosure or function(callback)
		return callback
	end

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newCclosure(function(self, ...)
		local method = getnamecallmethod()

		if method == "FireServer" then
			if typeof(self) == INSTANCE_TYPE and self.ClassName == "RemoteEvent" then
				local events = self.Parent
				if events and events.Name == "Events" then
					local eventName = self.Name
					if eventName == "Damage" or eventName == "HitEffect" then
						local args = { ... }

						local target = Hook._activeInstance and Hook._activeInstance.TargetState
						local config = Hook._activeInstance and Hook._activeInstance.Settings
						local cache = Hook._activeInstance and Hook._activeInstance.PayloadCache
						local indexForPart = Hook._activeInstance and Hook._activeInstance.GetAimPartIndex

						if eventName == "Damage" and cache then
							cache:CaptureDamage(args)
						end

						if target and target.active and config and config.AimEnabled then
							if eventName == "Damage"
								and typeof(args[1]) == INSTANCE_TYPE
								and string.match(args[1].ClassName, "Part")
								and typeof(args[2]) == INSTANCE_TYPE
								and args[2].ClassName == "Humanoid"
								and typeof(args[11]) == "string" then
								args[1] = target.part
								args[2] = target.humanoid
								args[4] = indexForPart(config.AimPart)
								return oldNamecall(self, table.unpack(args))
							elseif eventName == "HitEffect"
								and typeof(args[5]) == "table"
								and args[5][1] == "Gun" then
								local originalHit = args[1]
								args[1] = target.part
								args[2] = target.position
								args[3] = target.lookVector
								local result = oldNamecall(self, table.unpack(args))

								if config.Wallbang and cache and originalHit and originalHit.Parent then
									local hitCharacter = originalHit.Parent:FindFirstChildOfClass("Humanoid") ~= nil
									if not hitCharacter then
										cache:TryWallbang(events, target, indexForPart(config.AimPart))
									end
								end

								return result
							end
						end
					end
				end
			end
		elseif method == "Raycast" then
			local active = Hook._activeInstance
			local target = active and active.TargetState
			local config = active and active.Settings
			if target and target.active and config and config.AimEnabled and self == workspace then
				local origin, direction, params = ...
				if params and params.CollisionGroup == "BulletCast" then
					local camera = workspace.CurrentCamera
					if camera then
						local cameraPosition = camera.CFrame.Position
						local cameraLook = camera.CFrame.LookVector
						local dx = origin.X - cameraPosition.X
						local dy = origin.Y - cameraPosition.Y
						local dz = origin.Z - cameraPosition.Z

						if math.sqrt(dx * dx + dy * dy + dz * dz) < 6 then
							local length = direction.Magnitude
							if length > 0.01 then
								local unit = direction.Unit
								local alignment = cameraLook.X * unit.X + cameraLook.Y * unit.Y + cameraLook.Z * unit.Z
								if alignment > 0.9 then
									local hx = target.position.X - origin.X
									local hy = target.position.Y - origin.Y
									local hz = target.position.Z - origin.Z
									local distance = math.sqrt(hx * hx + hy * hy + hz * hz)
									if distance > 0.01 then
										local redirected = Vector3.new(hx / distance * length, hy / distance * length, hz / distance * length)
										return oldNamecall(self, origin, redirected, params)
									end
								end
							end
						end
					end
				end
			end
		end

		return oldNamecall(self, ...)
	end))

	self.OldNamecall = oldNamecall
	self.Installed = true
	Hook._activeInstance = self
	return true
end

return Hook
