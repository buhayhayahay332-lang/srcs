local FovCircle = {}
FovCircle.__index = FovCircle

local function getEnvironment()
	return type(getgenv) == "function" and getgenv() or _G
end

function FovCircle.new(settings)
	return setmetatable({
		Settings = settings,
		Circle = nil,
		_running = false,
	}, FovCircle)
end

function FovCircle:_create()
	local environment = getEnvironment()
	local previousCircle = environment.OperationSiegeAimFovCircle
	if previousCircle then
		pcall(function()
			previousCircle:Remove()
		end)
	end

	pcall(function()
		if Drawing and Drawing.new then
			self.Circle = Drawing.new("Circle")
			self.Circle.Filled = false
			self.Circle.NumSides = 64
			self.Circle.Thickness = 1
			self.Circle.Transparency = 1
			self.Circle.Visible = false
		end
	end)

	environment.OperationSiegeAimFovCircle = self.Circle
end

function FovCircle:_update()
	local circle = self.Circle
	local camera = workspace.CurrentCamera
	if not (circle and camera) then
		return
	end

	local viewport = camera.ViewportSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		circle.Visible = false
		return
	end

	local radius = (math.tan(math.rad(self.Settings.AimFOV)) / math.tan(math.rad(camera.FieldOfView / 2)))
		* (viewport.Y / 2)

	circle.Color = self.Settings.FovCircleColor
	circle.Radius = radius
	circle.Position = Vector2.new(viewport.X / 2, viewport.Y / 2)
	circle.Visible = self.Settings.AimEnabled and self.Settings.ShowFovCircle
end

function FovCircle:Start()
	if self._running then
		return
	end

	self._running = true
	self:_create()
	task.spawn(function()
		while self._running do
			pcall(function()
				self:_update()
			end)
			task.wait(0.1)
		end
	end)
end

function FovCircle:Stop()
	self._running = false
	if self.Circle then
		pcall(function()
			self.Circle:Remove()
		end)
		self.Circle = nil
	end
end

return FovCircle
