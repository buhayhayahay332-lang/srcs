local UI = {}

function UI.build(library, settings, runtime)
	local window = library:CreateWindow({
		Title = "Operation Siege",
		Footer = "Gun module",
		Icon = "crosshair",
		NotifySide = "Right",
		ShowCustomCursor = true,
	})

	local gunTab = window:AddTab("Gun", "crosshair")
	local scannerTab = window:AddTab("Scanner", "radar")
	local modsGroup = gunTab:AddGroupbox({ Side = "Left", Name = "Weapon Mods", IconName = "crosshair" })
	local fireGroup = gunTab:AddGroupbox({ Side = "Right", Name = "Fire Control", IconName = "gauge" })
	local scanGroup = scannerTab:AddGroupbox({ Side = "Left", Name = "GC Scanner", IconName = "radar" })

	modsGroup:AddToggle("OS_GunEnabled", { Text = "Enabled", Default = settings.Enabled })
	modsGroup:AddToggle("OS_GunNoRecoil", { Text = "No Recoil", Default = settings.NoRecoil })
	modsGroup:AddToggle("OS_GunNoSpread", { Text = "No Spread", Default = settings.NoSpread })
	modsGroup:AddToggle("OS_GunMaxDamage", { Text = "Max Damage", Default = settings.MaxDamage, Risky = true })
	modsGroup:AddToggle("OS_GunInfiniteAmmo", { Text = "Infinite Ammo", Default = settings.InfiniteAmmo, Risky = true })

	fireGroup:AddToggle("OS_GunFireRate", { Text = "Fire Rate Boost", Default = settings.FireRateBoost })
	fireGroup:AddSlider("OS_GunFireMultiplier", {
		Text = "Fire Rate Multiplier",
		Default = settings.FireRateMultiplier,
		Min = 1,
		Max = 50,
		Rounding = 1,
		Suffix = "x",
	})

	scanGroup:AddToggle("OS_GunBackgroundScan", { Text = "Background Scan", Default = settings.BackgroundScan })
	scanGroup:AddButton({
		Text = "Scan Now",
		Func = function()
			local patched, reason = runtime:ScanNow()
			library:Notify(string.format("Scanner: %s", reason or ("patched " .. patched .. " table(s)")))
		end,
	})
	scanGroup:AddButton({
		Text = "Reapply Known Tables",
		Func = function()
			local count = runtime:ReapplyKnown()
			library:Notify(string.format("Reapplied %d table(s)", count))
		end,
	})
	scanGroup:AddLabel("Scanner yields every 500 tables and only runs while alive.", true)

	local toggles = library.Toggles
	local options = library.Options
	local function reapply()
		runtime:ReapplyKnown()
	end

	toggles.OS_GunEnabled:OnChanged(function()
		settings.Enabled = toggles.OS_GunEnabled.Value
		reapply()
	end)
	toggles.OS_GunNoRecoil:OnChanged(function()
		settings.NoRecoil = toggles.OS_GunNoRecoil.Value
		reapply()
	end)
	toggles.OS_GunNoSpread:OnChanged(function()
		settings.NoSpread = toggles.OS_GunNoSpread.Value
		reapply()
	end)
	toggles.OS_GunMaxDamage:OnChanged(function()
		settings.MaxDamage = toggles.OS_GunMaxDamage.Value
		reapply()
	end)
	toggles.OS_GunInfiniteAmmo:OnChanged(function()
		settings.InfiniteAmmo = toggles.OS_GunInfiniteAmmo.Value
		reapply()
	end)
	toggles.OS_GunFireRate:OnChanged(function()
		settings.FireRateBoost = toggles.OS_GunFireRate.Value
		reapply()
	end)
	toggles.OS_GunBackgroundScan:OnChanged(function()
		settings.BackgroundScan = toggles.OS_GunBackgroundScan.Value
	end)
	options.OS_GunFireMultiplier:OnChanged(function()
		settings.FireRateMultiplier = options.OS_GunFireMultiplier.Value
		reapply()
	end)

	return window
end

return UI
