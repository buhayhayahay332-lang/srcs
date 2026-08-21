local Config = {}

Config.Defaults = {
	Enabled = true,
	NoRecoil = true,
	NoSpread = true,
	FireRateBoost = true,
	FireRateMultiplier = 10,
	MaxDamage = true,
	InfiniteAmmo = true,
	BackgroundScan = true,
	Verbose = false,
	ScanDelay = 0.3,
	ScanInterval = 2,
	MinScanGap = 1.5,
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

return Config
