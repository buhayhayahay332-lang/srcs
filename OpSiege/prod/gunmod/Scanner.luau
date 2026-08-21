local Scanner = {}
Scanner.__index = Scanner

function Scanner.new(settings, patcher)
	return setmetatable({
		Settings = settings,
		Patcher = patcher,
		Patched = setmetatable({}, { __mode = "k" }),
		LastScanCount = 0,
	}, Scanner)
end

function Scanner:_getTables()
	local calls = {
		function()
			return filtergc("table", true)
		end,
		function()
			return filtergc("table")
		end,
		function()
			return getgc(true)
		end,
	}

	for _, request in ipairs(calls) do
		local ok, result = pcall(request)
		if ok and type(result) == "table" then
			return result
		end
	end

	return nil
end

function Scanner:Scan()
	if not self.Settings.Enabled then
		return 0, "disabled"
	end

	local tables = self:_getTables()
	if not tables then
		return 0, "filtergc/getgc unavailable"
	end

	local patched = 0
	for index, tableValue in ipairs(tables) do
		if index % 500 == 0 then
			task.wait()
		end

		if type(tableValue) == "table" and not self.Patched[tableValue] and self.Patcher:IsPatchable(tableValue) then
			local ok, didPatch = pcall(function()
				return self.Patcher:Apply(tableValue)
			end)

			if ok and didPatch then
				self.Patched[tableValue] = true
				patched = patched + 1
			end
		end
	end

	self.LastScanCount = patched
	if self.Settings.Verbose and patched > 0 then
		print("[GunMod] scan patched " .. tostring(patched) .. " config table(s)")
	end
	return patched
end

return Scanner
