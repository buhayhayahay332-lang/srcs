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
	["aimmod.init"] = "aimmod/init.luau",
	["gunmod.Config"] = "gunmod/Config.luau",
	["gunmod.TableStore"] = "gunmod/TableStore.luau",
	["gunmod.Patcher"] = "gunmod/Patcher.luau",
	["gunmod.Scanner"] = "gunmod/Scanner.luau",
	["gunmod.Runtime"] = "gunmod/Runtime.luau",
	["gunmod.init"] = "gunmod/init.luau",
	["MainUI"] = "MainUI.luau",
}

local loaded = {}
local loading = {}

local function requireModule(moduleId)
	assert(type(moduleId) == "string" and modules[moduleId], "Invalid production module request: " .. tostring(moduleId))

	if loaded[moduleId] ~= nil then
		return loaded[moduleId]
	end
	assert(not loading[moduleId], "Circular production module dependency: " .. moduleId)
	loading[moduleId] = true

	local source = game:HttpGet(baseUrl .. modules[moduleId])
	local chunk, compileError = loadstring(source, "@OperationSiege/" .. moduleId)
	assert(chunk, compileError)

	local sandbox = setmetatable({
		require = requireModule,
	}, { __index = environment })
	setfenv(chunk, sandbox)

	local ok, result = pcall(chunk)
	loading[moduleId] = nil
	assert(ok, result)
	loaded[moduleId] = result
	return result
end

if environment.OperationSiegeProductionHub and environment.OperationSiegeProductionHub.Active then
	return environment.OperationSiegeProductionHub
end

local started = {
	aimmod = requireModule("aimmod.init").start(),
	gunmod = requireModule("gunmod.init").start(),
	Active = true,
}

local obsidian = requireModule("aimmod.Obsidian").load()
started.Window = requireModule("MainUI").build(obsidian, started.aimmod, started.gunmod)

obsidian.Library:OnUnload(function()
	started.Active = false
	started.aimmod:Stop()
	started.gunmod:Stop()

	if environment.OperationSiegeProductionHub == started then
		environment.OperationSiegeProductionHub = nil
	end
end)

environment.OperationSiegeProductionHub = started
return started
