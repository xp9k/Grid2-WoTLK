local Grid2 = Grid2

local next, pairs = next, pairs

Grid2.statuses = {}
Grid2.statusTypes = {}
Grid2.statusPrototype = {}

-- {{ status prototype
local status = Grid2.statusPrototype
status.__index = status

-- constructor
function status:new(name, embed)
	local e = setmetatable({}, self)
	if embed ~= false then
		LibStub("AceEvent-3.0"):Embed(e)
	end
	e.name = name
	e.indicators = {}
	return e
end

-- shading color: icon indicator
function status:GetVertexColor()
	return 1, 1, 1, 1
end

-- texture coords: icon indicator
function status:GetTexCoord()
	return 0.05, 0.95, 0.05, 0.95
end

-- stacks: text, bar indicators
function status:GetCount()
	return 1
end

-- max posible stacks: bar indicator
function status:GetCountMax()
	return 1
end

-- icon, square, text-color, bar-color indicators
function status:GetColor()
	return 0, 0, 0, 1
end
-- returns~=nil to colorize icon border with status GetColor(): icon indicator
status.GetBorder = Grid2.Dummy
-- text indicator
status.GetText = Grid2.Dummy
-- expiration time in seconds: bar, icon, text indicators
status.GetExpirationTime = Grid2.Dummy
-- duration in seconds: bar, icon, text indicators
status.GetDuration = Grid2.Dummy
-- percent value: alpha, bar indicators
status.GetPercent = Grid2.Dummy
-- texture: icon indicator
status.GetIcon = Grid2.Dummy
-- all indicators
status.OnEnable = Grid2.Dummy
-- all indicators
status.OnDisable = Grid2.Dummy
-- all indicators
status.Refresh = Grid2.Dummy
-- all indicators
status.UpdateAllIndicators = Grid2.statusLibrary.UpdateAllUnits
-- all indicators
status.Grid_Enabled = Grid2.statusLibrary.Grid_Enabled

function status:UpdateDB(dbx)
	if dbx then
		self.dbx = dbx
	end
end

function status:Inject(data)
	for k, f in next, data do
		self[k] = f
	end
end

function status:UpdateIndicators(unit)
	for parent in next, Grid2:GetUnitFrames(unit) do
		for indicator in pairs(self.indicators) do
			indicator:Update(parent, unit)
		end
	end
end

function status:RegisterIndicator(indicator)
	if self.indicators[indicator] then
		return
	end
	local enabled = next(self.indicators)
	self.indicators[indicator] = true
	if not enabled then
		self.enabled = true
		self:OnEnable()
	end
end

function status:UnregisterIndicator(indicator)
	if not self.indicators[indicator] then
		return
	end
	self.indicators[indicator] = nil
	local enabled = next(self.indicators)
	if not enabled then
		self.enabled = nil
		self:OnDisable()
	end
end

function Grid2:RegisterStatus(status, types, baseKey, dbx)
	local name = status.name
	if (baseKey and baseKey ~= name) then
		self.statuses[name] = nil
		status.name = baseKey
	else
		self.statuses[name] = status
		for _, stype in ipairs(types) do
			local t = self.statusTypes[stype]
			if not t then
				t = {}
				self.statusTypes[stype] = t
			end
			t[#t + 1] = status
		end
	end
	status.dbx = dbx
end

function Grid2:UnregisterStatus(status)
	for _, indicator in Grid2:IterateIndicators() do
		if self.indicators[indicator] then
			indicator:UnregisterStatus(status)
		end
	end
	if status.Destroy then
		status:Destroy()
	end
	local name = status.name
	self.statuses[name] = nil
	for _, t in pairs(self.statusTypes) do
		for i = 1, #t do
			if t[i] == status then
				table.remove(t, i)
				break
			end
		end
	end
end

function Grid2:IterateStatuses(stype)
	return next, stype and self.statusTypes[stype] or self.statuses
end

function Grid2:GetStatusByName(name)
	for key, status in Grid2:IterateStatuses() do
		if key == name then return status end
	end
end

-- function used by statuses that required LibGroupTalents
do
	local LibGroupTalents = LibStub("LibGroupTalents-1.0", true)
	local function InspectReady(self, event)
		self:UpdateAllUnits(event)
	end

	-- registers the status for when LGT update is complete
	function Grid2:RegisterInspect(status)
		if not LibGroupTalents then
			return
		end
		status.InspectReady = status.InspectReady or InspectReady
		LibGroupTalents.RegisterCallback(status, "LibGroupTalents_UpdateComplete", "InspectReady")
	end

	-- unregisters the status from LGT callbacks
	function Grid2:UnregisterInspect(status)
		if not LibGroupTalents or not status.InspectReady then
			return
		end
		LibGroupTalents.UnregisterAllCallbacks(status)
	end
end

function status:IsSuspended()
	return (self.dbx and self.dbx.playerClass and self.dbx.playerClass ~= Grid2.playerClass) or nil
end