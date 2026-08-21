local Obsidian = {}

local REPOSITORY_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

function Obsidian.load()
	local environment = type(getgenv) == "function" and getgenv() or _G
	if environment.OperationSiegeObsidianBundle then
		return environment.OperationSiegeObsidianBundle
	end

	assert(type(loadstring) == "function", "loadstring is required to load Obsidian")

	local bundle = {
		Library = loadstring(game:HttpGet(REPOSITORY_URL .. "Library.lua"))(),
		ThemeManager = loadstring(game:HttpGet(REPOSITORY_URL .. "addons/ThemeManager.lua"))(),
		SaveManager = loadstring(game:HttpGet(REPOSITORY_URL .. "addons/SaveManager.lua"))(),
	}

	environment.OperationSiegeObsidianBundle = bundle
	bundle.Library:OnUnload(function()
		if environment.OperationSiegeObsidianBundle == bundle then
			environment.OperationSiegeObsidianBundle = nil
		end
	end)

	return bundle
end

return Obsidian
