local UI = {}

function UI.build(library, settings)
	local window = library:CreateWindow({
		Title = "Operation Siege",
		Footer = "Aim module",
		Icon = "crosshair",
		NotifySide = "Right",
		ShowCustomCursor = true,
	})

	local aimTab = window:AddTab("Aim", "crosshair")
	local visualsTab = window:AddTab("Visuals", "circle")
	local aimGroup = aimTab:AddGroupbox({ Side = "Left", Name = "Targeting", IconName = "crosshair" })
	local behaviorGroup = aimTab:AddGroupbox({ Side = "Right", Name = "Behavior", IconName = "sliders-horizontal" })
	local visualsGroup = visualsTab:AddGroupbox({ Side = "Left", Name = "FOV Circle", IconName = "circle" })

	aimGroup:AddToggle("OS_AimEnabled", { Text = "Enabled", Default = settings.AimEnabled })
	aimGroup:AddToggle("OS_AimTeamCheck", { Text = "Team Check", Default = settings.TeamCheck })
	aimGroup:AddDropdown("OS_AimPart", {
		Text = "Target Part",
		Values = { "Head", "UpperTorso" },
		Default = settings.AimPart,
	})
	aimGroup:AddSlider("OS_AimFov", {
		Text = "Aim FOV",
		Default = settings.AimFOV,
		Min = 1,
		Max = 45,
		Rounding = 1,
		Suffix = " deg",
	})
	aimGroup:AddSlider("OS_AimDistance", {
		Text = "Target Distance",
		Default = settings.AimDistance,
		Min = 25,
		Max = 1000,
		Rounding = 0,
		Suffix = " studs",
	})

	behaviorGroup:AddToggle("OS_AimWallbang", { Text = "Wallbang", Default = settings.Wallbang })
	behaviorGroup:AddLabel("Shots redirect through the game's BulletCast ray path.", true)

	visualsGroup:AddToggle("OS_AimFovCircle", { Text = "Show FOV Circle", Default = settings.ShowFovCircle })
	visualsGroup:AddLabel("Circle Color"):AddColorPicker("OS_AimFovColor", {
		Default = settings.FovCircleColor,
		Title = "FOV Circle Color",
	})

	local toggles = library.Toggles
	local options = library.Options
	toggles.OS_AimEnabled:OnChanged(function()
		settings.AimEnabled = toggles.OS_AimEnabled.Value
	end)
	toggles.OS_AimTeamCheck:OnChanged(function()
		settings.TeamCheck = toggles.OS_AimTeamCheck.Value
	end)
	toggles.OS_AimWallbang:OnChanged(function()
		settings.Wallbang = toggles.OS_AimWallbang.Value
	end)
	toggles.OS_AimFovCircle:OnChanged(function()
		settings.ShowFovCircle = toggles.OS_AimFovCircle.Value
	end)
	options.OS_AimPart:OnChanged(function()
		settings.AimPart = options.OS_AimPart.Value
	end)
	options.OS_AimFov:OnChanged(function()
		settings.AimFOV = options.OS_AimFov.Value
	end)
	options.OS_AimDistance:OnChanged(function()
		settings.AimDistance = options.OS_AimDistance.Value
	end)
	options.OS_AimFovColor:OnChanged(function()
		settings.FovCircleColor = options.OS_AimFovColor.Value
	end)

	return window
end

return UI
