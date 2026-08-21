local Config = require("aimmod.Config")
local Targeting = require("aimmod.Targeting")
local FovCircle = require("aimmod.FovCircle")
local PayloadCache = require("aimmod.PayloadCache")
local Hook = require("aimmod.Hook")
local Obsidian = require("aimmod.Obsidian")
local UI = require("aimmod.UI")

local AimMod = {}
AimMod.__index = AimMod

local function getEnvironment()
	return type(getgenv) == "function" and getgenv() or _G
end

function AimMod.new(overrides)
	local settings = Config.new(overrides)
	local targeting = Targeting.new(settings)
	local payloadCache = PayloadCache.new()
	local fovCircle = FovCircle.new(settings)
	local hook = Hook.new(settings, targeting.State, payloadCache, Config.getAimPartIndex)

	return setmetatable({
		Settings = settings,
		Targeting = targeting,
		PayloadCache = payloadCache,
		FovCircle = fovCircle,
		Hook = hook,
		Window = nil,
		Started = false,
	}, AimMod)
end

function AimMod:Start()
	if self.Started then
		return self
	end

	self.Targeting:Start()
	self.FovCircle:Start()
	self.PayloadCache:Start()

	local installed, reason = self.Hook:Install()
	if not installed then
		warn("[AimMod] hook not installed:", reason)
	end

	local library = Obsidian.load()
	self.Window = UI.build(library, self.Settings)
	self.Started = true
	return self
end

function AimMod:Stop()
	self.Settings.AimEnabled = false
	self.Targeting:Stop()
	self.FovCircle:Stop()
	self.PayloadCache:Stop()
	self.Started = false
end

function AimMod.start(overrides)
	local environment = getEnvironment()
	if environment.OperationSiegeProductionAimMod then
		return environment.OperationSiegeProductionAimMod
	end

	local instance = AimMod.new(overrides)
	environment.OperationSiegeProductionAimMod = instance
	return instance:Start()
end

return AimMod
