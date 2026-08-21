local Config = {}

Config.Defaults = {
	AimEnabled = false,
	AimFOV = 10,
	AimDistance = 300,
	AimPart = "Head",
	TeamCheck = false,
	Wallbang = false,
	ShowFovCircle = false,
	FovCircleColor = Color3.fromRGB(255, 255, 255),
	TargetRefreshRate = 0.05,
	Debug = false,
}

Config.AimPartIndex = {
	Head = 1,
	UpperTorso = 2,
}

function Config.new(overrides)
	local settings = {}
	for key, value in pairs(Config.Defaults) do
		settings[key] = value
	end

	for key, value in pairs(overrides or {}) do
		if settings[key] ~= nil then
			settings[key] = value
		end
	end

	return settings
end

function Config.getAimPartIndex(partName)
	return Config.AimPartIndex[partName] or Config.AimPartIndex.Head
end

return Config
