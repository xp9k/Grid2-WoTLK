-- Roster management
local Grid2 = Grid2

local pairs, next = pairs, next
local UnitName, UnitGUID, UnitExists = UnitName, UnitGUID, UnitExists
local IsInRaid, IsInGroup, GetNumGroupMembers = Grid2.IsInRaid, Grid2.IsInGroup, Grid2.GetNumGroupMembers

-- realm name
local my_realm = GetRealmName()

-- indexed by unit ID
local roster_names = {}
local roster_realms = {}
local roster_guids = {}

-- indexed by GUID
local roster_units = {}

-- unit tables
local party_units = {}
local raid_units = {}
local pet_of_unit = {}
local owner_of_unit = {}

-- populate unit tables
do
	local function register_unit(tbl, unit, pet)
		tinsert(tbl, unit)
		pet_of_unit[unit] = pet
		owner_of_unit[pet] = unit
	end
	register_unit(party_units, "player", "pet")
	for i = 1, MAX_PARTY_MEMBERS do
		register_unit(party_units, ("party%d"):format(i), ("partypet%d"):format(i))
	end
	for i = 1, MAX_RAID_MEMBERS do
		register_unit(raid_units, ("raid%d"):format(i), ("raidpet%d"):format(i))
	end
end

-- roster query functions
function Grid2:GetUnitByFullName(fullName)
	local name, realm = fullName:match("^([^%-]+)%-(.*)$")
	name = name or fullName
	if realm == my_realm or realm == "" then
		realm = nil
	end
	for unit, unit_name in pairs(roster_names) do
		if name == unit_name and roster_realms[unit] == realm then
			return unit
		end
	end
end

function Grid2:GetUnitidByGUID(guid)
	return roster_units[guid]
end

function Grid2:GetOwnerUnitidByGUID(guid)
	return owner_of_unit[roster_units[guid]]
end

function Grid2:IsGUIDInRaid(guid)
	return roster_units[guid]
end

function Grid2:GetPetUnitByUnit(unit)
	return pet_of_unit[unit]
end

function Grid2:GetOwnerUnitByUnit(unit)
	return owner_of_unit[unit]
end

function Grid2:IsUnitInRaid(unit)
	return roster_guids[unit]
end

function Grid2:IsUnitNoPetInRaid(unit)
	return roster_guids[unit] and pet_of_unit[unit]
end

function Grid2:UnitIsPet(unit)
	return owner_of_unit[unit]
end

function Grid2:UnitIsParty(unit)
	for _, v in next, party_units do
		if unit == v then
			return true
		end
	end
end

function Grid2:UnitIsRaid(unit)
	for _, v in next, raid_units do
		if unit == v then
			return true
		end
	end
end

function Grid2:IterateRoster()
	return next, roster_units
end

function Grid2:IterateRosterUnits()
	return next, roster_guids
end

do
	function Grid2:PLAYER_ENTERING_WORLD(...)
		-- this is needed to trigger an update when switching from one BG directly to another
		self.groupType = nil
		self:GroupChanged("PLAYER_ENTERING_WORLD")
		if self.db.profile.hideBlizzardRaidFrames then
			Grid2:HideBlizzardRaidFrames()
		end
	end
	local function GetGroupType(...)
		local count = GetNumGroupMembers()
		if IsInRaid() then
			for i = select("#", ...) - 1, 1, -1 do
				if count > select(i, ...) then
					return "raid" .. select(i + 1, ...)
				end
			end
		end
		return count > 0 and "party" or "solo"
	end
	function Grid2:GroupChanged(event)
		self.instType = select(2, IsInInstance())
		if self.instType == "raid" and IsInRaid() then
			self.instType = select(5, GetInstanceInfo()) > 10 and "raid25" or "raid10"
		elseif self.instType == "pvp" then
			self.instType = GetGroupType(0, 10, 15, 40)
		elseif self.instType ~= "arena" then
			self.instType = GetGroupType(0, 10, 25, 40)
		end
		self:Debug("GroupChanged", self.groupType, "=>", self.instType)
		if self.groupType ~= self.instType then
			self.groupType = self.instType
			self:SendMessage("Grid_GroupTypeChanged", self.groupType)
		end
		self:UpdateRoster()
	end
end

-- roster updating
do
	local units_to_remove = {}
	local units_added = {}
	local units_changed = {}
	local units_updated = {}

	function Grid2:UNIT_NAME_UPDATE(_, unit)
		local name, realm = UnitName(unit)
		local guid = UnitGUID(unit)

		if realm == "" then
			realm = nil
		end

		local old_name = roster_names[unit]
		local old_realm = roster_realms[unit]

		roster_names[unit] = name
		roster_realms[unit] = realm

		if old_name ~= name or old_realm ~= realm then
			self:SendMessage("Grid_UnitChanged", unit, guid)
			self:SendMessage("Grid_UnitUpdated", unit, guid)
			self:SendMessage("Grid_UnitUpdate", unit, guid)
			self:SendMessage("Grid_RosterUpdated")
		end
	end

	function Grid2:UNIT_PET(_, owner)
		local unit = pet_of_unit[owner]
		if UnitExists(unit) then
			local name, realm = UnitName(unit)
			local guid = UnitGUID(unit)
			if realm == "" then
				realm = nil
			end
			local updated, exists = false, roster_guids[unit]
			if name ~= roster_names[unit] then
				roster_names[unit] = name
				updated = true
			end
			if realm ~= roster_realms[unit] then
				roster_realms[unit] = realm
				updated = true
			end
			local oldGuid = roster_guids[unit]
			if guid ~= oldGuid then
				roster_guids[unit] = guid
				if oldGuid then
					local oldUnit = roster_units[oldGuid]
					if (not UnitExists(oldUnit)) then
						roster_units[oldGuid] = nil
					elseif (UnitGUID(oldUnit) ~= oldGuid) then
						roster_units[oldGuid] = nil
					end
				end
				roster_units[guid] = unit
				updated = true
			end
			if updated then
				self:SendMessage(exists and "Grid_UnitChanged" or "Grid_UnitJoined", unit, guid)
				self:SendMessage("Grid_UnitUpdated", unit, guid)
				self:SendMessage("Grid_UnitUpdate", unit, guid)
				self:SendMessage("Grid_RosterUpdated")
			end
		else
			local oldGuid = roster_guids[unit]
			if oldGuid then
				roster_names[unit] = nil
				roster_realms[unit] = nil
				roster_guids[unit] = nil
				local oldUnit = roster_units[oldGuid]
				if (not UnitExists(oldUnit)) then
					roster_units[oldGuid] = nil
				elseif (UnitGUID(oldUnit) ~= oldGuid) then
					roster_units[oldGuid] = nil
				end
				self:SendMessage("Grid_UnitLeft", unit, oldGuid)
				self:SendMessage("Grid_RosterUpdated")
			end
		end
	end

	local function UpdateUnit(unit)
		local name, realm = UnitName(unit)
		local guid = UnitGUID(unit)

		if realm == "" then
			realm = nil
		end

		local oldGuid = units_to_remove[unit]
		local old_name = roster_names[unit]
		local old_realm = roster_realms[unit]

		units_to_remove[unit] = nil

		if not old_name then
			units_added[unit] = guid
		elseif old_name ~= name or old_realm ~= realm then
			units_changed[unit] = guid
		end

		roster_names[unit] = name
		roster_realms[unit] = realm
		roster_guids[unit] = guid
		roster_units[guid] = unit

		if (oldGuid and guid ~= oldGuid) then
			local oldUnit = roster_units[oldGuid]
			if (not UnitExists(oldUnit)) or (UnitGUID(oldUnit) ~= oldGuid) then
				roster_units[oldGuid] = nil
			end
		end
	end

	function Grid2:UpdateRoster()
		roster_guids, units_to_remove = units_to_remove, roster_guids

		local units = IsInRaid() and raid_units or party_units

		for i = 1, #units do
			local unit = units[i]
			if not UnitExists(unit) then
				break
			end
			UpdateUnit(unit)

			local unitpet = pet_of_unit[unit]
			if UnitExists(unitpet) then
				UpdateUnit(unitpet)
			end
		end

		local updated = false

		for unit, guid in pairs(units_to_remove) do
			updated = true
			roster_names[unit] = nil
			roster_realms[unit] = nil
			roster_guids[unit] = nil
			local oldUnit = roster_units[guid]
			if (not UnitExists(oldUnit)) then
				roster_units[guid] = nil
			end
			self:SendMessage("Grid_UnitLeft", unit, guid)
			units_to_remove[unit] = nil
		end

		for unit, guid in pairs(units_added) do
			updated = true
			self:SendMessage("Grid_UnitJoined", unit, guid)
			units_updated[unit] = guid
			units_added[unit] = nil
		end

		for unit, guid in pairs(units_changed) do
			updated = true
			self:SendMessage("Grid_UnitChanged", unit, guid)
			units_updated[unit] = guid
			units_changed[unit] = nil
		end

		for unit, guid in pairs(units_updated) do
			self:SendMessage("Grid_UnitUpdated", unit, guid) -- Used by some statuses
			self:SendMessage("Grid_UnitUpdate", unit, guid) --  Used internally by Grid2Frame to update indicators.
			units_updated[unit] = nil
		end

		if updated then
			self:SendMessage("Grid_RosterUpdated")
		end
	end
end

Grid2.party_units = party_units
Grid2.raid_units = raid_units
Grid2.roster_units = roster_units