-- build/main.luau
-- Operation Siege — modular Obsidian loader.
--
-- Paste ONLY this file. It HttpGets the Obsidian library + the two modules
-- from GitHub (fully portable, no readfile). Set RAW_BASE to your repo's raw
-- URL (the folder that contains "modules/").
--
--   RAW_BASE should end with a "/" and point at the repo root, e.g.
--   https://raw.githubusercontent.com/<you>/<repo>/<branch>/

local RAW_BASE = "https://raw.githubusercontent.com/USER/REPO/BRANCH/"  -- <-- EDIT ME
local OBSIDIAN_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"

local function loadModule(name)
	local src = game:HttpGet(RAW_BASE .. "modules/" .. name .. ".luau")
	return loadstring(src)()
end

-- Load Obsidian UI library
local Library = loadstring(game:HttpGet(OBSIDIAN_URL))()
local Options = Library.Options

Library.ShowToggleFrameInKeybinds = true

-- Load modules (each returns { Settings, Init, BuildTab, ... })
local Aimbot = loadModule("aimmod")
local GunMod = loadModule("gunmod")

-- Build window
local Window = Library:CreateWindow({
	Title = "Operation Siege",
	Footer = "modular build",
	NotifySide = "Right",
	ShowCustomCursor = true,
	AutoShow = true,
})

local Tabs = {
	Aimbot = Window:AddTab("Aimbot", "crosshair"),
	Gun = Window:AddTab("Gun Mods", "zap"),
	Settings = Window:AddTab("Settings", "settings"),
}

-- Let each module build its own tab
Aimbot.BuildTab(Tabs.Aimbot, Library)
GunMod.BuildTab(Tabs.Gun, Library)

-- Settings tab (loader-level)
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

Tabs.Settings:AddRightGroupbox("Info"):AddLabel(
	"Operation Siege\nAimbot + Gun Mods\nGUI by Obsidian\n\nEnable mods in the\nAimbot / Gun Mods tabs.",
	true
)

-- Wire the menu toggle keybind
Library.ToggleKeybind = Options.MenuKeybind

-- Start module hooks / loops
Aimbot.Init()
GunMod.Init()

Library:Notify({
	Title = "Operation Siege",
	Description = "Loaded. Enable mods in the Aimbot / Gun Mods tabs.",
	Time = 4,
})
