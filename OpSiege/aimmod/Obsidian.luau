local Obsidian = {}

local LIBRARY_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"

function Obsidian.load()
	local environment = type(getgenv) == "function" and getgenv() or _G
	if environment.OperationSiegeObsidian then
		return environment.OperationSiegeObsidian
	end

	assert(type(loadstring) == "function", "loadstring is required to load Obsidian")
	local source = game:HttpGet(LIBRARY_URL)
	local library = loadstring(source)()
	environment.OperationSiegeObsidian = library
	return library
end

return Obsidian
