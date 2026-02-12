-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_GuildControlUI\Localization.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- luacheck: ignore 111 (setting non-standard global variable)

local l10nTable = {
	deDE = {},
	enGB = {},
	enUS = {},
	esES = {},
	esMX = {},
	frFR = {},
	itIT = {},
	koKR = {},
	ptBR = {},
	ptPT = {},
	ruRU = {},
	zhCN = {
		localize = function()
			GuildControlUIRankSettingsFrameBankLabel:SetPoint("TOPLEFT", GuildControlUIRankSettingsFrameBankBg, 7, -4);
		end,
	},
	zhTW = {
		localize = function()
			GuildControlUI_LocalizeBankTab = function(frame)
				_G[frame:GetName().."OwnedStackBoxLabelText"]:SetFontObject("AchievementDescriptionFont");
			end

			GuildControlUIRankSettingsFrameBankLabel:SetPoint("TOPLEFT", GuildControlUIRankSettingsFrameBankBg, 7, -4);
		end,
	},
};

SetupLocalization(l10nTable);