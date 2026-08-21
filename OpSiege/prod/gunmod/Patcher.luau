local Patcher = {}
Patcher.__index = Patcher

function Patcher.new(settings, tableStore)
	return setmetatable({
		Settings = settings,
		Store = tableStore,
	}, Patcher)
end

function Patcher:IsGunConfig(tableValue)
	if type(tableValue) ~= "table" then
		return false
	end

	if rawget(tableValue, "Type") ~= "Gun" then
		return false
	end

	if type(rawget(tableValue, "ShootRate")) ~= "number" then
		return false
	end

	if type(rawget(tableValue, "AmmoInGun")) ~= "number" then
		return false
	end

	local cameraRecoil = rawget(tableValue, "camRecoil")
	return type(cameraRecoil) == "table" and rawget(cameraRecoil, "camRecoilUp") ~= nil
end

function Patcher:IsAttachmentConfig(tableValue)
	if type(tableValue) ~= "table" or rawget(tableValue, "DamageMod") == nil then
		return false
	end

	local cameraRecoil = rawget(tableValue, "camRecoil")
	return type(cameraRecoil) == "table" and rawget(cameraRecoil, "RecoilUp") ~= nil
end

function Patcher:IsPatchable(tableValue)
	return self:IsGunConfig(tableValue) or self:IsAttachmentConfig(tableValue)
end

function Patcher:_set(tableValue, key, value)
	self.Store:MakeWritable(tableValue)
	rawset(tableValue, key, value)
end

function Patcher:_zeroAxis(tableValue, key)
	local value = rawget(tableValue, key)
	if type(value) == "table" then
		self.Store:MakeWritable(value)
		value[1] = 0
		value[2] = 0
	elseif value ~= nil then
		self:_set(tableValue, key, 0)
	end
end

function Patcher:_removeRecoil(tableValue)
	local cameraRecoil = rawget(tableValue, "camRecoil")
	if type(cameraRecoil) == "table" then
		self.Store:MakeWritable(cameraRecoil)
		if rawget(cameraRecoil, "RecoilUp") ~= nil then
			for _, key in ipairs({ "RecoilUp", "RecoilTilt", "RecoilLeft", "RecoilRight" }) do
				self:_zeroAxis(cameraRecoil, key)
			end
		else
			for _, key in ipairs({ "camRecoilUp", "camRecoilTilt", "camRecoilLeft", "camRecoilRight" }) do
				self:_zeroAxis(cameraRecoil, key)
			end
		end
	end

	local gunRecoil = rawget(tableValue, "gunRecoil")
	if type(gunRecoil) == "table" then
		self.Store:MakeWritable(gunRecoil)
		if rawget(gunRecoil, "RecoilUp") ~= nil then
			for _, key in ipairs({ "RecoilUp", "RecoilTilt", "RecoilLeft", "RecoilRight" }) do
				self:_zeroAxis(gunRecoil, key)
			end
		else
			for _, key in ipairs({ "gunRecoilUp", "gunRecoilTilt", "gunRecoilLeft", "gunRecoilRight" }) do
				self:_zeroAxis(gunRecoil, key)
			end
		end
	end
end

function Patcher:Apply(tableValue)
	if not self.Settings.Enabled then
		return false
	end

	local isGun = self:IsGunConfig(tableValue)
	local isAttachment = self:IsAttachmentConfig(tableValue)
	if not (isGun or isAttachment) then
		return false
	end

	self.Store:Remember(tableValue)
	self.Store:MakeWritable(tableValue)

	if self.Settings.NoRecoil then
		self:_removeRecoil(tableValue)
	end

	if self.Settings.NoSpread then
		self:_set(tableValue, "MinSpread", 0)
		self:_set(tableValue, "MaxSpread", 0)
	end

	if isGun and self.Settings.FireRateBoost then
		local original = self.Store.Originals[tableValue]
		local baseRate = original and rawget(original, "ShootRate") or rawget(tableValue, "ShootRate")
		if type(baseRate) == "number" then
			self:_set(tableValue, "ShootRate", baseRate * self.Settings.FireRateMultiplier)
		end
	end

	if isGun and self.Settings.MaxDamage then
		for _, key in ipairs({ "HeadDamage", "TorsoDamage", "LimbDamage" }) do
			local value = rawget(tableValue, key)
			if type(value) == "table" then
				self.Store:MakeWritable(value)
				value[1] = 99999
				value[2] = 99999
			elseif value ~= nil then
				self:_set(tableValue, key, 99999)
			end
		end
		self:_set(tableValue, "MinDamage", 99999)
	end

	if isGun and self.Settings.InfiniteAmmo then
		self:_set(tableValue, "Ammo", 999)
		self:_set(tableValue, "AmmoInGun", 999)
		self:_set(tableValue, "StoredAmmo", 9999)
		self:_set(tableValue, "MaxStoredAmmo", 9999)
	end

	return true
end

function Patcher:ReapplyAll()
	local patched = 0
	for tableValue in pairs(self.Store.Originals) do
		self.Store:Restore(tableValue)
		if self:Apply(tableValue) then
			patched = patched + 1
		end
	end
	return patched
end

return Patcher
