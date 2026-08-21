--[[
	Loadstring bootstrap for the modular production build.

	The source is hosted at buhayhayahay332-lang/srcs, under OpSiege/prod.
]]

local baseUrl = "https://raw.githubusercontent.com/buhayhayahay332-lang/srcs/main/OpSiege/prod/"
local environment = type(getfenv) == "function" and getfenv() or _G

local modules = {
	["aimmod.Config"] = "aimmod/Config.luau",
	["aimmod.Targeting"] = "aimmod/Targeting.luau",
	["aimmod.FovCircle"] = "aimmod/FovCircle.luau",
	["aimmod.PayloadCache"] = "aimmod/PayloadCache.luau",
	["aimmod.Hook"] = "aimmod/Hook.luau",
	["aimmod.Obsidian"] = "aimmod/Obsidian.luau",
	["aimmod.UI"] = "aimmod/UI.luau",
	["aimmod.init"] = "aimmod/init.luau",
	["gunmod.Config"] = "gunmod/Config.luau",
	["gunmod.TableStore"] = "gunmod/TableStore.luau",
	["gunmod.Patcher"] = "gunmod/Patcher.luau",
	["gunmod.Scanner"] = "gunmod/Scanner.luau",
	["gunmod.Runtime"] = "gunmod/Runtime.luau",
	["gunmod.Obsidian"] = "gunmod/Obsidian.luau",
	["gunmod.UI"] = "gunmod/UI.luau",
	["gunmod.init"] = "gunmod/init.luau",
}

local tokens = {}
for moduleId in pairs(modules) do
	tokens[moduleId] = { __moduleId = moduleId }
end

local loaded = {}
local loading = {}

local function makeScriptProxy(moduleId)
	local container, moduleName = moduleId:match("^(.-)%.([^.]+)$")
	local proxy = { Name = moduleName }

	for candidateId, token in pairs(tokens) do
		local candidateContainer, candidateName = candidateId:match("^(.-)%.([^.]+)$")
		if candidateContainer == container then
			proxy[candidateName] = token
		end
	end

	return proxy
end

local function requireModule(token)
	local moduleId = type(token) == "table" and token.__moduleId
	assert(moduleId and modules[moduleId], "Invalid production module request")

	if loaded[moduleId] ~= nil then
		return loaded[moduleId]
	end
	assert(not loading[moduleId], "Circular production module dependency: " .. moduleId)
	loading[moduleId] = true

	local source = game:HttpGet(baseUrl .. modules[moduleId])
	local chunk, compileError = loadstring(source, "@OperationSiege/" .. moduleId)
	assert(chunk, compileError)

	local sandbox = setmetatable({
		script = makeScriptProxy(moduleId),
		require = requireModule,
	}, { __index = environment })
	setfenv(chunk, sandbox)

	local ok, result = pcall(chunk)
	loading[moduleId] = nil
	assert(ok, result)
	loaded[moduleId] = result
	return result
end

local started = {}

for _, name in ipairs({ "aimmod", "gunmod" }) do
	if name == "aimmod" then
		started.aimmod = requireModule(tokens["aimmod.init"]).start()
	elseif name == "gunmod" then
		started.gunmod = requireModule(tokens["gunmod.init"]).start()
	else
		warn("[OperationSiege] unknown production module:", name)
	end
end

return started
