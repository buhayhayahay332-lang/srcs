local HubUI = {}

local function addToggle(group, id, text, settings, key)
	return group:AddToggle(id, {
		Default = settings[key],
		Text = text,
		Callback = function(value)
			settings[key] = value
		end,
	})
end

local function addSlider(group, id, text, settings, key, minimum, maximum, rounding)
	return group:AddSlider(id, {
		Default = settings[key],
		Min = minimum,
		Max = maximum,
		Rounding = rounding,
		Text = text,
		Callback = function(value)
			settings[key] = value
		end,
	})
end

function HubUI.build(obsidian, aimMod, gunMod)
	local Library = obsidian.Library
	local ThemeManager = obsidian.ThemeManager
	local SaveManager = obsidian.SaveManager
	local Options = Library.Options

	local window = Library:CreateWindow({
		Title = "Operation Siege",
		Footer = "AimMod + GunMod",
		Icon = "crosshair",
		NotifySide = "Right",
		ShowCustomCursor = true,
		AutoShow = true,
	})

	local tabs = {
		Aim = window:AddTab("Aim", "crosshair"),
		Gun = window:AddTab("Gun", "crosshair"),
		Scanner = window:AddTab("Scanner", "scan-search"),
		Visuals = window:AddTab("Visuals", "eye"),
		Settings = window:AddTab("UI Settings", "settings"),
	}

	local aim = aimMod.Settings
	local gun = gunMod.Settings

	local aimGroup = tabs.Aim:AddGroupbox({ Side = "Left", Name = "Silent Aim", IconName = "crosshair" })
	addToggle(aimGroup, "OS_AimEnabled", "Enabled", aim, "AimEnabled")
	addToggle(aimGroup, "OS_TeamCheck", "Team check", aim, "TeamCheck")
	addToggle(aimGroup, "OS_Wallbang", "Wallbang", aim, "Wallbang")
	addToggle(aimGroup, "OS_AimDebug", "Debug notifications", aim, "Debug")
	aimGroup:AddDropdown("OS_AimPart", {
		Values = { "Head", "UpperTorso" },
		Default = aim.AimPart,
		Text = "Target part",
		Callback = function(value)
			aim.AimPart = value
		end,
	})
	addSlider(aimGroup, "OS_AimFOV", "FOV radius", aim, "AimFOV", 1, 500, 0)
	addSlider(aimGroup, "OS_AimDistance", "Max distance", aim, "AimDistance", 25, 2000, 0)
	addSlider(aimGroup, "OS_TargetRefresh", "Target refresh", aim, "TargetRefreshRate", 0.01, 0.5, 2)

	local visualsGroup = tabs.Visuals:AddGroupbox({ Side = "Left", Name = "FOV Circle", IconName = "circle" })
	addToggle(visualsGroup, "OS_ShowFovCircle", "Show FOV circle", aim, "ShowFovCircle")
	visualsGroup:AddLabel("Circle color"):AddColorPicker("OS_FovCircleColor", {
		Default = aim.FovCircleColor,
		Title = "FOV circle color",
	})
	Options.OS_FovCircleColor:OnChanged(function()
		aim.FovCircleColor = Options.OS_FovCircleColor.Value
	end)

	local gunGroup = tabs.Gun:AddGroupbox({ Side = "Left", Name = "Weapon Patches", IconName = "crosshair" })
	addToggle(gunGroup, "OS_GunEnabled", "Enabled", gun, "Enabled")
	addToggle(gunGroup, "OS_NoRecoil", "No recoil", gun, "NoRecoil")
	addToggle(gunGroup, "OS_NoSpread", "No spread", gun, "NoSpread")
	addToggle(gunGroup, "OS_FireRateBoost", "Fire-rate boost", gun, "FireRateBoost")
	addToggle(gunGroup, "OS_MaxDamage", "Max damage", gun, "MaxDamage")
	addToggle(gunGroup, "OS_InfiniteAmmo", "Infinite ammo", gun, "InfiniteAmmo")
	addSlider(gunGroup, "OS_FireRateMultiplier", "Fire-rate multiplier", gun, "FireRateMultiplier", 1, 50, 1)

	local scannerGroup = tabs.Scanner:AddGroupbox({ Side = "Left", Name = "Scanner", IconName = "scan-search" })
	addToggle(scannerGroup, "OS_BackgroundScan", "Background scan", gun, "BackgroundScan")
	addToggle(scannerGroup, "OS_Verbose", "Verbose output", gun, "Verbose")
	addSlider(scannerGroup, "OS_ScanDelay", "Spawn scan delay", gun, "ScanDelay", 0, 5, 1)
	addSlider(scannerGroup, "OS_ScanInterval", "Scan interval", gun, "ScanInterval", 0.5, 15, 1)
	addSlider(scannerGroup, "OS_MinScanGap", "Minimum scan gap", gun, "MinScanGap", 0, 10, 1)
	scannerGroup:AddButton("Scan now", function()
		local count, reason = gunMod.Runtime:ScanNow()
		Library:Notify({
			Title = "Scanner",
			Description = reason or ("Patched " .. tostring(count) .. " table(s)."),
			Time = 3,
		})
	end)
	scannerGroup:AddButton("Reapply known tables", function()
		local count = gunMod.Runtime:ReapplyKnown()
		Library:Notify({
			Title = "GunMod",
			Description = "Updated " .. tostring(count) .. " known table(s).",
			Time = 3,
		})
	end)

	local menuGroup = tabs.Settings:AddGroupbox({ Side = "Left", Name = "Menu", IconName = "settings" })
	menuGroup:AddToggle("OS_KeybindMenuOpen", {
		Default = Library.KeybindFrame.Visible,
		Text = "Open keybind menu",
		Callback = function(value)
			Library.KeybindFrame.Visible = value
		end,
	})
	menuGroup:AddToggle("OS_ShowCustomCursor", {
		Default = Library.ShowCustomCursor,
		Text = "Show custom cursor",
		Callback = function(value)
			Library.ShowCustomCursor = value
		end,
	})
	menuGroup:AddToggle("OS_AlwaysOnTop", {
		Default = window.AlwaysOnTop,
		Text = "Always on top",
		Callback = function(value)
			window:SetAlwaysOnTop(value)
		end,
	})
	menuGroup:AddDropdown("OS_NotificationSide", {
		Values = { "Left", "Right" },
		Default = "Right",
		Text = "Notification side",
		Callback = function(value)
			Library:SetNotifySide(value)
		end,
	})
	menuGroup:AddDropdown("OS_DPI", {
		Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
		Default = "100%",
		Text = "UI scale",
		Callback = function(value)
			Library:SetDPIScale(tonumber(value:gsub("%%", "")))
		end,
	})
	menuGroup:AddSlider("OS_CornerRadius", {
		Text = "Corner radius",
		Default = Library.CornerRadius,
		Min = 0,
		Max = 12,
		Rounding = 0,
		Callback = function(value)
			window:SetCornerRadius(value)
		end,
	})
	menuGroup:AddLabel("Toggle UI"):AddKeyPicker("OS_MenuKeybind", {
		Default = "RightShift",
		NoUI = true,
		Text = "Menu keybind",
	})
	Library.ToggleKeybind = Options.OS_MenuKeybind
	menuGroup:AddButton("Unload Operation Siege", function()
		Library:Unload()
	end)

	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({ "OS_MenuKeybind" })
	ThemeManager:SetFolder("OperationSiege")
	SaveManager:SetFolder("OperationSiege")
	SaveManager:SetSubFolder("OpSiege")
	SaveManager:BuildConfigSection(tabs.Settings)
	ThemeManager:ApplyToTab(tabs.Settings)
	SaveManager:LoadAutoloadConfig()

	return window
end

return HubUI
