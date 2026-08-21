-- build/modules/gunmod.luau
-- Operation Siege GUN MODS (No Recoil / No Spread / Fire Rate / Max Damage /
-- Infinite Ammo) — modular, GUI-bound.
-- Loaded by build/main.luau via HttpGet. Exposes:
--   Settings, Init(), BuildTab(tab, Library), ApplyMods, ReapplyAll, GetStatus
--
-- v6 strategy (no GC scan -> no freeze): capture the engine's LIVE u81/u97
-- tables from the Equip/Damage remotes it fires, then re-apply mods to ONLY
-- those known tables on a cheap loop. Dispatch-first namecall hook.
-- NaN-safety kept: recoil/spread divisors never zeroed (0/0 = NaN CFrame).

local Settings = {
	Enabled = false,
	NoRecoil = false,
	NoSpread = false,
	FireRateBoost = false,
	FireRateMultiplier = 10,
	MaxDamage = false,
	InfiniteAmmo = false,
	Verbose = false,
	PatchInterval = 0.3,
}

local INSTANCE_TYPE = "Instance"
local newCclosure = newcclosure or function(f) return f end

local function Log(msg)
	if Settings.Verbose then print("[GunMod] " .. msg) end
end

-- ============================================================================
-- Strict detection (metatable-safe reads via rawget)
-- ============================================================================
local function IsGunConfig(t)
	if type(t) ~= "table" then return false end
	if rawget(t, "Type") ~= "Gun" then return false end
	if type(rawget(t, "ShootRate")) ~= "number" then return false end
	if type(rawget(t, "AmmoInGun")) ~= "number" then return false end
	local cam = rawget(t, "camRecoil")
	if type(cam) ~= "table" or rawget(cam, "camRecoilUp") == nil then return false end
	return true
end

local function IsAttachConfig(t)
	if type(t) ~= "table" then return false end
	if rawget(t, "DamageMod") == nil then return false end
	local cam = rawget(t, "camRecoil")
	if type(cam) ~= "table" or rawget(cam, "RecoilUp") == nil then return false end
	return true
end

-- ============================================================================
-- Original-value storage (keyed by table) + restore
-- ============================================================================
local originals = {}

local function CloneValue(v, depth)
	depth = depth or 0
	if type(v) ~= "table" or depth > 3 then
		return v
	end
	local clone = {}
	for k, val in pairs(v) do
		clone[k] = CloneValue(val, depth + 1)
	end
	return clone
end

local function StoreOriginals(t)
	if not originals[t] then
		originals[t] = CloneValue(t, 0)
	end
end

local LOADOUT_KEYS = {
	Primary = true, Secondary = true, Utility = true, Gadget = true,
	SightAtt = true, BarrelAtt = true, UnderBarrelAtt = true, OtherAtt = true,
	Charm = true, SkinTable = true, CustomAtt = true,
}

local function MakeWritable(tbl)
	if isreadonly(tbl) then
		pcall(makewritable, tbl)
	end
end

local function RestoreTable(t)
	local orig = originals[t]
	if not orig then return end
	MakeWritable(t)
	for k, v in pairs(orig) do
		if not LOADOUT_KEYS[k] then
			if type(v) == "table" then
				local cur = rawget(t, k)
				if type(cur) == "table" then
					MakeWritable(cur)
					for kk in pairs(cur) do cur[kk] = nil end
					for kk, vv in pairs(v) do
						if type(vv) == "table" then
							local newsub = {}
							for kkk, vvv in pairs(vv) do newsub[kkk] = vvv end
							cur[kk] = newsub
						else
							cur[kk] = vv
						end
					end
				else
					rawset(t, k, v)
				end
			else
				rawset(t, k, v)
			end
		end
	end
end

-- ============================================================================
-- Mod application (idempotent, in-place, rawset)
-- ============================================================================
local function ApplyMods(t)
	if not Settings.Enabled then
		return false
	end
	local isGun = IsGunConfig(t)
	local isAtt = IsAttachConfig(t)
	if not (isGun or isAtt) then
		return false
	end

	StoreOriginals(t)
	MakeWritable(t)

	local function set(tbl, key, val)
		MakeWritable(tbl)
		rawset(tbl, key, val)
	end

	local function zeroAxis(tbl, key)
		local v = rawget(tbl, key)
		if type(v) == "table" then
			MakeWritable(v)
			v[1] = 0
			v[2] = 0
		elseif v ~= nil then
			set(tbl, key, 0)
		end
	end

	if Settings.NoRecoil then
		local cam = rawget(t, "camRecoil")
		if type(cam) == "table" then
			MakeWritable(cam)
			if rawget(cam, "RecoilUp") ~= nil then
				zeroAxis(cam, "RecoilUp")
				zeroAxis(cam, "RecoilTilt")
				zeroAxis(cam, "RecoilLeft")
				zeroAxis(cam, "RecoilRight")
			else
				zeroAxis(cam, "camRecoilUp")
				zeroAxis(cam, "camRecoilTilt")
				zeroAxis(cam, "camRecoilLeft")
				zeroAxis(cam, "camRecoilRight")
			end
		end
		local gun = rawget(t, "gunRecoil")
		if type(gun) == "table" then
			MakeWritable(gun)
			if rawget(gun, "RecoilUp") ~= nil then
				zeroAxis(gun, "RecoilUp")
				zeroAxis(gun, "RecoilTilt")
				zeroAxis(gun, "RecoilLeft")
				zeroAxis(gun, "RecoilRight")
			else
				zeroAxis(gun, "gunRecoilUp")
				zeroAxis(gun, "gunRecoilTilt")
				zeroAxis(gun, "gunRecoilLeft")
				zeroAxis(gun, "gunRecoilRight")
			end
		end
	end

	if Settings.NoSpread then
		set(t, "MinSpread", 0)
		set(t, "MaxSpread", 0)
	end

	if isGun then
		if Settings.FireRateBoost then
			local base = rawget(originals[t], "ShootRate") or rawget(t, "ShootRate")
			if type(base) == "number" then
				set(t, "ShootRate", base * Settings.FireRateMultiplier)
			end
		end

		if Settings.MaxDamage then
			for _, key in ipairs({ "HeadDamage", "TorsoDamage", "LimbDamage" }) do
				local v = rawget(t, key)
				if v ~= nil then
					if type(v) == "table" then
						MakeWritable(v)
						v[1] = 99999
						v[2] = 99999
					else
						set(t, key, 99999)
					end
				end
			end
			set(t, "MinDamage", 99999)
		end

		if Settings.InfiniteAmmo then
			set(t, "Ammo", 999)
			set(t, "AmmoInGun", 999)
			set(t, "StoredAmmo", 9999)
			set(t, "MaxStoredAmmo", 9999)
		end
	end

	return true
end

local function ReapplyAll()
	local count = 0
	for t in pairs(originals) do
		RestoreTable(t)
		if ApplyMods(t) then
			count = count + 1
		end
	end
	return count
end

-- ============================================================================
-- Live config capture (from the engine's own remotes -> exact tables it uses)
-- ============================================================================
local liveGuns = {}
local liveAtts = {}

local function Capture(t, isGun)
	if type(t) ~= "table" then return end
	if isGun then
		if IsGunConfig(t) then
			StoreOriginals(t)
			liveGuns[t] = true
			Log("captured gun config")
		end
	else
		if IsAttachConfig(t) then
			StoreOriginals(t)
			liveAtts[t] = true
			Log("captured attach config")
		end
	end
end

local function Init()
	if getgenv().OpSiege_GunInstalled then return end
	getgenv().OpSiege_GunInstalled = true

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newCclosure(function(self, ...)
		local method = getnamecallmethod()
		if method == "FireServer" then
			if typeof(self) == INSTANCE_TYPE and self.ClassName == "RemoteEvent" then
				local parent = self.Parent
				if parent and parent.Name == "Events" then
					local name = self.Name
					if name == "Equip" or name == "Damage" then
						local args = { ... }
						if name == "Equip" then
							Capture(args[3], true)
							Capture(args[4], false)
							Capture(args[5], false)
						elseif name == "Damage" then
							Capture(args[5], true)
							Capture(args[6], false)
						end
					end
				end
			end
		end
		return oldNamecall(self, ...)
	end))

	-- Cheap patch loop: when enabled, restore+apply each tick (so toggling a
	-- mod OFF cleanly reverts). When disabled, revert once then idle.
	local wasEnabled = false
	task.spawn(function()
		while true do
			task.wait(Settings.PatchInterval)
			if Settings.Enabled then
				wasEnabled = true
				for t in pairs(liveGuns) do pcall(function() RestoreTable(t); ApplyMods(t) end) end
				for t in pairs(liveAtts) do pcall(function() RestoreTable(t); ApplyMods(t) end) end
			elseif wasEnabled then
				wasEnabled = false
				for t in pairs(liveGuns) do pcall(RestoreTable, t) end
				for t in pairs(liveAtts) do pcall(RestoreTable, t) end
			end
		end
	end)
end

-- ============================================================================
-- GUI
-- ============================================================================
local function BuildTab(tab, Library)
	local Options = Library.Options

	local Left = tab:AddLeftGroupbox("Mods")
	Left:AddToggle("GM_Enabled", {
		Text = "Enabled",
		Default = Settings.Enabled,
		Callback = function(v) Settings.Enabled = v end,
	})
	Left:AddToggle("GM_NoRecoil", {
		Text = "No Recoil",
		Default = Settings.NoRecoil,
		Callback = function(v) Settings.NoRecoil = v end,
	})
	Left:AddToggle("GM_NoSpread", {
		Text = "No Spread",
		Default = Settings.NoSpread,
		Callback = function(v) Settings.NoSpread = v end,
	})
	Left:AddToggle("GM_FireRate", {
		Text = "Fire Rate Boost",
		Default = Settings.FireRateBoost,
		Callback = function(v) Settings.FireRateBoost = v end,
	})
	Left:AddToggle("GM_MaxDamage", {
		Text = "Max Damage",
		Default = Settings.MaxDamage,
		Callback = function(v) Settings.MaxDamage = v end,
	})
	Left:AddToggle("GM_InfiniteAmmo", {
		Text = "Infinite Ammo",
		Default = Settings.InfiniteAmmo,
		Callback = function(v) Settings.InfiniteAmmo = v end,
	})

	local Right = tab:AddRightGroupbox("Tuning")
	Right:AddSlider("GM_FireRateMult", {
		Text = "Fire Rate Multiplier",
		Default = Settings.FireRateMultiplier, Min = 2, Max = 50, Rounding = 0,
		Callback = function(v) Settings.FireRateMultiplier = v end,
	})
	Right:AddSlider("GM_PatchInterval", {
		Text = "Patch Interval",
		Default = Settings.PatchInterval, Min = 0.1, Max = 1.0, Rounding = 2, Suffix = "s",
		Callback = function(v) Settings.PatchInterval = v end,
	})
	Right:AddDivider()
	Right:AddLabel("Captured: 0 guns / 0 atts", false, "GMStatus")

	task.spawn(function()
		while task.wait(1) do
			if Library.Unloaded then break end
			pcall(function()
				if Options.GMStatus then
					local g, a = 0, 0
					for _ in pairs(liveGuns) do g = g + 1 end
					for _ in pairs(liveAtts) do a = a + 1 end
					Options.GMStatus:SetText(string.format("Captured: %d guns / %d atts", g, a))
				end
			end)
		end
	end)
end

local function GetStatus()
	local g, a = 0, 0
	for _ in pairs(liveGuns) do g = g + 1 end
	for _ in pairs(liveAtts) do a = a + 1 end
	return string.format("%d guns / %d atts", g, a)
end

local M = {
	Settings = Settings,
	Init = Init,
	BuildTab = BuildTab,
	ApplyMods = ApplyMods,
	ReapplyAll = ReapplyAll,
	GetStatus = GetStatus,
	LiveGuns = liveGuns,
	LiveAtts = liveAtts,
}
getgenv().OperationSiege = getgenv().OperationSiege or {}
getgenv().OperationSiege.gunmod = M
return M
