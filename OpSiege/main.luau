local RAW_BASE = "https://raw.githubusercontent.com/buhayhayahay332-lang/srcs/main/OpSiege/"
local OBSIDIAN_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"

local function loadModule(name)
	local src = game:HttpGet(RAW_BASE .. "modules/" .. name .. ".luau")
	return loadstring(src)()
end


local Library = loadstring(game:HttpGet(OBSIDIAN_URL))()
local Options = Library.Options

Library.ShowToggleFrameInKeybinds = true



local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()


local Aimbot = loadModule("aimmod")
local GunMod = loadModule("gunmod")


local Window = Library:CreateWindow({
	Title = "Operation Siege",
	Icon  = 13129527031,
	Footer = "[ASTRO BETA v1]",
	NotifySide = "Right",
	ShowCustomCursor = false,
	AutoShow = true,
})

local Tabs = {
	Aimbot = Window:AddTab("Aimbot", "crosshair"),
	Gun = Window:AddTab("Gun Mods", "zap"),
	Settings = Window:AddTab("Settings", "settings"),
	UI = Window:AddTab("UI Settings", "palette"),
}


Aimbot.BuildTab(Tabs.Aimbot, Library)
GunMod.BuildTab(Tabs.Gun, Library)


local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Toggle UI",
})
MenuGroup:AddToggle("AlwaysOnTop", {
	Text = "Always On Top",
	Default = false,
	Callback = function(v) Window:SetAlwaysOnTop(v) end,
})
MenuGroup:AddToggle("CustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(v) Library.ShowCustomCursor = v end,
})
MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)



Library.ToggleKeybind = Options.MenuKeybind


Aimbot.Init()
GunMod.Init()


ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)


SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("OperationSiege")
SaveManager:SetFolder("OperationSiege")

ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:BuildConfigSection(Tabs.UI)


SaveManager:LoadAutoloadConfig()

Library:Notify({
	Title = "Operation Siege",
	Description = "GO CRAZY FURRY ASS BOI HAVE FUN.",
	Time = 4,
})
