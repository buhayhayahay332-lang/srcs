local TableStore = {}
TableStore.__index = TableStore

local LOADOUT_KEYS = {
	Primary = true,
	Secondary = true,
	Utility = true,
	Gadget = true,
	SightAtt = true,
	BarrelAtt = true,
	UnderBarrelAtt = true,
	OtherAtt = true,
	Charm = true,
	SkinTable = true,
	CustomAtt = true,
}

local function cloneValue(value, depth)
	if type(value) ~= "table" or depth > 3 then
		return value
	end

	local clone = {}
	for key, nestedValue in pairs(value) do
		clone[key] = cloneValue(nestedValue, depth + 1)
	end
	return clone
end

function TableStore.new()
	return setmetatable({ Originals = {} }, TableStore)
end

function TableStore:MakeWritable(tableValue)
	if type(isreadonly) ~= "function" or type(makewritable) ~= "function" then
		return
	end

	local ok, readonly = pcall(isreadonly, tableValue)
	if ok and readonly then
		pcall(makewritable, tableValue)
	end
end

function TableStore:Remember(tableValue)
	if not self.Originals[tableValue] then
		self.Originals[tableValue] = cloneValue(tableValue, 0)
	end
end

function TableStore:Restore(tableValue)
	local original = self.Originals[tableValue]
	if not original then
		return false
	end

	self:MakeWritable(tableValue)
	for key, value in pairs(original) do
		if not LOADOUT_KEYS[key] then
			if type(value) == "table" then
				local current = rawget(tableValue, key)
				if type(current) == "table" then
					self:MakeWritable(current)
					for nestedKey in pairs(current) do
						current[nestedKey] = nil
					end
					for nestedKey, nestedValue in pairs(value) do
						current[nestedKey] = cloneValue(nestedValue, 1)
					end
				else
					rawset(tableValue, key, cloneValue(value, 1))
				end
			else
				rawset(tableValue, key, value)
			end
		end
	end

	return true
end

function TableStore:RestoreAll()
	local restored = 0
	for tableValue in pairs(self.Originals) do
		if self:Restore(tableValue) then
			restored = restored + 1
		end
	end
	return restored
end

return TableStore
