--[[ Miscelaneous/shared functions and variables ]]--
local Grid2 = Grid2
local Grid2Options = Grid2Options
local L = Grid2Options.L
local LG = Grid2Options.LG

local AceGUI = LibStub("AceGUI-3.0", true)

-------------------------------------------------------------------------------------------------
-- Modified Multiline Editbox that vertical fills the parent container even in AceConfigDialog Flow layouts.
-- The multiline editbox must be the last defined element in an AceConfigTable.
-------------------------------------------------------------------------------------------------
do
	local WidgetType, container = "Grid2ExpandedEditBox"
	local function Resize(frame, width, height)
		if not container then -- container used as recursion lock
			container = frame.obj.parent
			frame.obj:SetHeight(frame:GetTop() - container.frame:GetBottom() - 2)
			container = nil
		end
	end
	AceGUI:RegisterWidgetType(WidgetType, function()
		local widget = AceGUI:Create("MultiLineEditBox")
		widget.type = WidgetType
		widget.frame:HookScript("OnSizeChanged", Resize)
		return widget
	end, 1)
end

-- Helper points tables
Grid2Options.pointMap = {
	TOPLEFT = "1",
	LEFT = "2",
	BOTTOMLEFT = "3",
	TOP = "4",
	CENTER = "5",
	BOTTOM = "6",
	TOPRIGHT = "7",
	RIGHT = "8",
	BOTTOMRIGHT = "9",
	["1"] = "TOPLEFT",
	["2"] = "LEFT",
	["3"] = "BOTTOMLEFT",
	["4"] = "TOP",
	["5"] = "CENTER",
	["6"] = "BOTTOM",
	["7"] = "TOPRIGHT",
	["8"] = "RIGHT",
	["9"] = "BOTTOMRIGHT"
}

Grid2Options.pointMapText = {
	LEFTTOP = "1",
	LEFTMIDDLE = "2",
	LEFTBOTTOM = "3",
	CENTERTOP = "4",
	CENTERMIDDLE = "5",
	CENTERBOTTOM = "6",
	RIGHTTOP = "7",
	RIGHTMIDDLE = "8",
	RIGHTBOTTOM = "9",
	["1"] = {"LEFT", "TOP"},
	["2"] = {"LEFT", "MIDDLE"},
	["3"] = {"LEFT", "BOTTOM"},
	["4"] = {"CENTER", "TOP"},
	["5"] = {"CENTER", "MIDDLE"},
	["6"] = {"CENTER", "BOTTOM"},
	["7"] = {"RIGHT", "TOP"},
	["8"] = {"RIGHT", "MIDDLE"},
	["9"] = {"RIGHT", "BOTTOM"}
}

Grid2Options.pointValueList = {
	["1"] = L["TOPLEFT"],
	["2"] = L["LEFT"],
	["3"] = L["BOTTOMLEFT"],
	["4"] = L["TOP"],
	["5"] = L["CENTER"],
	["6"] = L["BOTTOM"],
	["7"] = L["TOPRIGHT"],
	["8"] = L["RIGHT"],
	["9"] = L["BOTTOMRIGHT"]
}

Grid2Options.pointValueListExtra = {
	["0"] = L["None"],
	["1"] = L["TOPLEFT"],
	["2"] = L["LEFT"],
	["3"] = L["BOTTOMLEFT"],
	["4"] = L["TOP"],
	["5"] = L["CENTER"],
	["6"] = L["BOTTOM"],
	["7"] = L["TOPRIGHT"],
	["8"] = L["RIGHT"],
	["9"] = L["BOTTOMRIGHT"]
}

-- Font Flags and Shadow
do
	local fontFlagsValues = {
		["NONE"] = L["Soft"],
		["OUTLINE"] = string.format("%s,%s", L["Soft"], L["Thin"]),
		["THICKOUTLINE"] = string.format("%s,%s", L["Soft"], L["Thick"]),
		["MONOCHROME"] = L["Sharp"],
		["MONOCHROME, OUTLINE"] = string.format("%s,%s", L["Sharp"], L["Thin"]),
		["MONOCHROME, THICKOUTLINE"] = string.format("%s,%s", L["Sharp"], L["Thick"])
	}
	local fontFlagsShadowValues = {
		["0;NONE"] = L["Soft"],
		["0;OUTLINE"] = string.format("%s,%s", L["Soft"], L["Thin"]),
		["0;THICKOUTLINE"] = string.format("%s,%s", L["Soft"], L["Thick"]),
		["0;MONOCHROME"] = L["Sharp"],
		["0;MONOCHROME, OUTLINE"] = string.format("%s,%s", L["Sharp"], L["Thin"]),
		["0;MONOCHROME, THICKOUTLINE"] = string.format("%s,%s", L["Sharp"], L["Thick"]),
		["1;NONE"] = string.format("%s+%s", L["Soft"], L["Shadow"]),
		["1;OUTLINE"] = string.format("%s,%s+%s", L["Soft"], L["Thin"], L["Shadow"]),
		["1;THICKOUTLINE"] = string.format("%s,%s+%s", L["Soft"], L["Thick"], L["Shadow"]),
		["1;MONOCHROME"] = string.format("%s+%s", L["Sharp"], L["Shadow"]),
		["1;MONOCHROME, OUTLINE"] = string.format("%s,%s+%s", L["Sharp"], L["Thin"], L["Shadow"]),
		["1;MONOCHROME, THICKOUTLINE"] = string.format("%s,%s+%s", L["Sharp"], L["Thick"], L["Shadow"])
	}
	local FONT_FLAGS_DEFAULT = "0"
	local fontFlagsShadowDefValues = Grid2.CopyTable(fontFlagsShadowValues)
	fontFlagsShadowDefValues[FONT_FLAGS_DEFAULT] = string.format("*%s*", L["Default"])
	-- public
	Grid2Options.fontFlagsValues = fontFlagsValues
	Grid2Options.fontFlagsShadowValues = fontFlagsShadowValues
	Grid2Options.fontFlagsShadowDefValues = fontFlagsShadowDefValues
	Grid2Options.FONT_FLAGS_DEFAULT = FONT_FLAGS_DEFAULT
end

-- Grid2Option:UnpackColor()
function Grid2Options:UnpackColor(color, colorKey)
	color = color or Grid2.defaultColors[colorKey or "TRANSPARENT"]
	return color.r, color.g, color.b, color.a
end

-- Grid2Option:PackColor()
function Grid2Options:PackColor(r, g, b, a, dbx, key)
	if dbx then
		local c = dbx[key] or {}
		c.r, c.g, c.b, c.a = r, g, b, a
		dbx[key] = c
		return c
	end
	return {r = r, g = g, b = b, a = a}
end

-- Refresh AceConfig options window
function Grid2Options:NotifyChange() -- do not use self variable inside this function (self can be nil or ~=Grid2Options)
	LibStub("AceConfigRegistry-3.0"):NotifyChange("Grid2")
end
-- Grid2Options:EnableLoadOnDemand()
-- Delays the creation of indicators and statuses options, until the user clicks on each option,
-- reducing initial memory usage and load time. Instead of the real options, a "description" type option
-- is inserted in the options table. When the user clicks on the parent option, the "hidden" callback
-- of our "description" option is called, and at this point the module creates the real options.
-- This function can be safety removed, Grid2Option will continue working without this feature.
do
	local openManager = {
		type = "description",
		name = "",
		hidden = function(info)
			local self = Grid2Options
			local key = info[#info - 1]
			if key == "statuses" then
				self:MakeStatusesOptions_()
			elseif key == "indicators" then
				self:MakeIndicatorsOptions_()
			elseif info[1] == "statuses" then
				self:MakeStatusChildOptions_(Grid2.statuses[key])
			elseif info[1] == "indicators" then
				self:MakeIndicatorChildOptions_(Grid2.indicators[key])
			end
			Grid2Options:NotifyChange()
		end
	}
	function Grid2Options:EnableLoadOnDemand(enabled)
		if enabled then
			local Hook = function(self, options, extraOptions)
				options = extraOptions or options
				wipe(options)
				options.openManager = openManager
			end
			for _, f in ipairs(
				{"MakeIndicatorsOptions", "MakeStatusesOptions", "MakeIndicatorChildOptions", "MakeStatusChildOptions"}
			) do
				self[f .. "_"] = self[f]
				self[f] = Hook
			end
		end
		self.EnableLoadOnDemand = nil
	end
end

-- Grid2Options.Tooltip generic tooltip to parse hiperlinks
do
	local tip
	tip = CreateFrame("GameTooltip", "Grid2OptionsTooltip", nil, "GameTooltipTemplate")
	tip:SetOwner(UIParent, "ANCHOR_NONE")
	for i = 1, 5 do
		tip[i] = _G["Grid2OptionsTooltipTextLeft" .. i]
		if not tip[i] then
			tip[i] = tip:CreateFontString()
			tip:AddFontStrings(tip[i], tip:CreateFontString())
		end
	end
	Grid2Options.Tooltip = tip
end

-- Grid2Options:MakeHeaderOptions()
do
	local headers = {
		-- shared headers
		Delete = {type = "header", order = 250, name = ""},
		-- indicators headers
		Location = {type = "header", order = 2, name = L["Location"]},
		Appearance = {type = "header", order = 10, name = L["Appearance"]},
		Border = {type = "header", order = 20, name = L["Border"]},
		Display = {type = "header", order = 80, name = L["Display"]},
		StackText = {type = "header", order = 90, name = L["Stack Text"]},
		Cooldown = {type = "header", order = 125, name = L["Cooldown"]},
		Animation = {type = "header", order = 150, name = L["Animations"]},
		-- statuses headers
		Colors = {type = "header", order = 10, name = L["Colors"]},
		Thresholds = {type = "header", order = 50, name = L["Thresholds"]},
		Misc = {type = "header", order = 100, name = L["Misc"]},
		Auras = {type = "header", order = 150, name = L["Auras"]},
		DebuffFilter = {type = "header", order = 175, name = L["Filtered debuffs"]},
		ClassFilter = {type = "header", order = 200, name = L["Class Filter"]}
	}
	function Grid2Options:MakeHeaderOptions(options, key)
		options["header" .. key] = headers[key]
	end
end

-- Grid2Options:MakeSpacerOptions()
do
	local spacers = {}
	function Grid2Options:MakeSpacerOptions(options, order)
		local header = spacers[order]
		if not header then
			header = {type = "header", order = order, name = ""}
			spacers[order] = header
		end
		options["spacer" .. order] = header
	end
end

-- Grid2:MakeTitleOptions(options, title, subtitle, desc, icon, coords)
do
	local titleCoords = {0.05, 0.95, 0.05, 0.95}
	local titleMask = NORMAL_FONT_COLOR_CODE .. "%s|r\n%s"
	local titleSep = {type = "header", order = 1.5, width = "full", name = ""}
	function Grid2Options:MakeTitleOptions(options, title, subtitle, desc, icon, coords)
		options.title = {
			type = "description",
			order = 0,
			width = "full",
			fontSize = "large",
			image = icon,
			imageWidth = 30,
			imageHeight = 30,
			imageCoords = coords or titleCoords,
			name = string.format(titleMask, title, subtitle)
		}
		if desc then
			options.titleDesc = {type = "description", order = 1.2, fontSize = "small", name = desc}
		end
		options.titleSep = titleSep
	end
end

-- Grid2Options.LocalizeStatus()
do
	local fmt = string.format
	local HexDigits = "0123456789ABCDEF"
	local prefixes = {"color-", "buff-", "debuff-", "aoe-"}
	local suffixes = {"-mine", "-not-mine"}
	local prefixes_colors = {
		["buff-"] = "|cFF00ff00%s|r",
		["debuff-"] = "|cFFff0000%s|r",
		["aoe-"] = "|cFF0080ff%s|r",
		["color-"] = "|cFFffff00%s|r"
	}
	local function byteToHex(byte)
		local L = byte % 16 + 1
		local H = math.floor(byte / 16) + 1
		return HexDigits:sub(H, H) .. HexDigits:sub(L, L)
	end
	local function rgbToHex(c)
		return byteToHex(math.floor(c.r * 255)) .. byteToHex(math.floor(c.g * 255)) .. byteToHex(math.floor(c.b * 255))
	end
	local function SplitStatusName(name)
		local prefix = ""
		local suffix = ""
		local body
		for _, value in ipairs(prefixes) do
			if strsub(name, 1, strlen(value)) == value then
				prefix = value
				break
			end
		end
		for _, value in ipairs(suffixes) do
			if strsub(name, -strlen(value)) == value then
				suffix = value
				break
			end
		end
		body = strsub(name, strlen(prefix) + 1, strlen(name) - strlen(suffix))
		return prefix, body, suffix
	end
	function Grid2Options.LocalizeStatus(status, RemovePrefix)
		local name = status.name
		local prefix, body, suffix = SplitStatusName(name)
		if RemovePrefix then
			prefix = ""
		end
		if prefix == "color-" then
			body = "|cFF" .. rgbToHex(status.dbx.color1) .. L[body] .. "|r"
		else
			body = L[body]
		end
		if prefix ~= "" then
			prefix = fmt(prefixes_colors[prefix] or "%s", L[prefix])
		end
		if suffix ~= "" then
			suffix = L[suffix]
		end
		return prefix .. body .. suffix
	end
end

-- checking that the status provides at least one of the required indicator types
function Grid2Options:IsCompatiblePair(indicator, status)
	for type, list in pairs(Grid2.indicatorTypes) do
		if list[indicator.name] then
			for _, s in Grid2:IterateStatuses(type) do
				if s == status then
					return type
				end
			end
		end
	end
end

-- Grid2Options:GetAvailableStatusValues()
function Grid2Options:GetAvailableStatusValues(indicator, statusAvailable)
	statusAvailable = statusAvailable or {}
	wipe(statusAvailable)
	for statusKey, status in Grid2:IterateStatuses() do
		if self:IsCompatiblePair(indicator, status) and status.name ~= "test" and not status:IsSuspended() then
			statusAvailable[statusKey] = self.LocalizeStatus(status)
		end
	end
	for _, status in ipairs(indicator.statuses) do
		statusAvailable[status.name] = nil
	end
	return statusAvailable
end

-- Reload indicator database configuration and refresh the indicator frames.
-- indicator:UpdateDB() is always called to reload indicator database config
-- method = "Create" | "Update" | key | nil
-- 	"Create" > Recreate the indicator
--  "Update" > Update all indicators in all registered frame units
--  nil      > Only indicator:UpdateDB() is called
--  key      > method defined inside indicator to execute after loading config
-- extraAction
-- 	"Update" > Update all indicators in all registered frame units
function Grid2Options:RefreshIndicator(indicator, method, extraAction)
	if method == "Create" then
		Grid2Frame:WithAllFrames(indicator, "Disable")
	end
	if indicator.UpdateDB then
		indicator:UpdateDB()
	end
	if method and method ~= "Update" then
		Grid2Frame:WithAllFrames(indicator, method)
	end
	if method == "Create" then
		Grid2Frame:WithAllFrames(indicator, "Layout")
	end
	if method == "Create" or method == "Update" or extraAction == "Update" then
		Grid2Frame:UpdateIndicators()
	end
end

-- Grid2Options:GetLayouts()
function Grid2Options:GetLayouts(meta)
	local list = {}
	for name, layout in pairs(Grid2Layout.layoutSettings) do
		if layout.meta[meta] == true then
			list[name] = LG[name]
		end
	end
	return list
end

-- Grid2Options:GetValidatedName()
function Grid2Options:GetValidatedName(name)
	name = name:gsub('["%.]', "")
	name = name:gsub(" ", "-")
	return name
end

-- Copy elements of a table into another table,
-- Does not wipe the destination table
-- Does not do a deep copy, only root keys are copied
-- If dst is not specified creates an empty table to copy src into
-- If src is not specified returns an empty table
function Grid2Options:CopyOptionsTable(src, dst)
	dst = dst or {}
	if src then
		for k, v in pairs(src) do
			dst[k] = v
		end
	end
	return dst
end

-- Goto the specified options section.
function Grid2Options:SelectGroup(...)
	LibStub("AceConfigDialog-3.0"):SelectGroup("Grid2", ...)
end

-- Grid2Options.MEDIA_FONT_DEFAULT
-- Grid2Options.MEDIA_VALUE_DEFAULT
-- Grid2Options.GetFontsValues()
-- Grid2Optoins.GetStatusBarValues()
do
	local fonts, bars
	local self = Grid2Options
	local media = LibStub("LibSharedMedia-3.0", true)
	-- Calculate and save libSharedMedia font key for STANDARD_TEXT_FONT
	for key, font in pairs(media:HashTable("font") or {}) do
		if font == STANDARD_TEXT_FONT then
			Grid2Options.MEDIA_FONT_DEFAULT = key
			break
		end
	end
	Grid2Options.MEDIA_VALUE_DEFAULT = string.format("*%s*", L["Default"])
	Grid2Options.GetFontValues = function()
		fonts = fonts or self:CopyOptionsTable(AceGUIWidgetLSMlists.font)
		fonts[self.MEDIA_VALUE_DEFAULT] =
			media:Fetch("font", Grid2Frame.db.profile.font or self.MEDIA_FONT_DEFAULT) or STANDARD_TEXT_FONT
		return fonts
	end
	Grid2Options.GetStatusBarValues = function()
		bars = bars or self:CopyOptionsTable(AceGUIWidgetLSMlists.statusbar)
		bars[self.MEDIA_VALUE_DEFAULT] =
			media:Fetch("statusbar", Grid2Frame.db.profile.barTexture or "Gradient") or "Gradient"
		return bars
	end
end

-- Grid2Options:ConfirmDialog()
-- Grid2Options:ShowEditDialog()
do
	StaticPopupDialogs["GRID2OPTIONS_GENERAL_DIALOG"] = {
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
		button1 = ACCEPT,
		button2 = CANCEL
	}

	local function ShowDialog(message, textDefault, funcAccept, funcCancel, textAccept, textCancel)
		local t = StaticPopupDialogs["GRID2OPTIONS_GENERAL_DIALOG"]
		t.OnShow = function(self)
			if textDefault then
				self.editBox:SetText(textDefault)
			end
			self:SetFrameStrata("TOOLTIP")
		end
		t.OnHide = function(self)
			self:SetFrameStrata("DIALOG")
		end
		t.hasEditBox = textDefault and true or nil
		t.text = message
		t.button1 = funcAccept and (textAccept or ACCEPT) or nil
		t.button2 = funcCancel and (textCancel or CANCEL) or nil
		t.OnCancel = funcCancel
		t.OnAccept = funcAccept and function(self)
				funcAccept(textDefault and self.editBox:GetText())
			end or nil
		StaticPopup_Show("GRID2OPTIONS_GENERAL_DIALOG")
	end

	function Grid2Options:MessageDialog(message, funcAccept)
		ShowDialog(message, nil, funcAccept or Grid2.Dummy)
	end

	function Grid2Options:ConfirmDialog(message, funcAccept, funcCancel, textAccept, textCancel)
		ShowDialog(message, nil, funcAccept, funcCancel or Grid2.Dummy, textAccept, textCancel)
	end

	function Grid2Options:ShowEditDialog(message, text, funcAccept, funcCancel)
		ShowDialog(message, text or "", funcAccept, funcCancel or Grid2.Dummy)
	end
end