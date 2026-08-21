local Config = require("gunmod.Config")
local TableStore = require("gunmod.TableStore")
local Patcher = require("gunmod.Patcher")
local Scanner = require("gunmod.Scanner")
local Runtime = require("gunmod.Runtime")

local GunMod = {}
GunMod.__index = GunMod

local function getEnvironment()
	return type(getgenv) == "function" and getgenv() or _G
end

function GunMod.new(overrides)
	local settings = Config.new(overrides)
	local tableStore = TableStore.new()
	local patcher = Patcher.new(settings, tableStore)
	local scanner = Scanner.new(settings, patcher)
	local runtime = Runtime.new(settings, scanner, patcher)

	return setmetatable({
		Settings = settings,
		TableStore = tableStore,
		Patcher = patcher,
		Scanner = scanner,
		Runtime = runtime,
		Started = false,
	}, GunMod)
end

function GunMod:Start()
	if self.Started then
		return self
	end

	self.Runtime:Start()
	self.Started = true
	return self
end

function GunMod:Stop()
	self.Settings.Enabled = false
	self.Runtime:Stop()
	self.TableStore:RestoreAll()
	self.Started = false
end

function GunMod.start(overrides)
	local environment = getEnvironment()
	if environment.OperationSiegeProductionGunMod then
		return environment.OperationSiegeProductionGunMod:Start()
	end

	local instance = GunMod.new(overrides)
	environment.OperationSiegeProductionGunMod = instance
	return instance:Start()
end

return GunMod
