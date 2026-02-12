-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_UIPanels_Game\Vanilla\Localization.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

local function AdjustFriendsFrameDropdown_132()
	FriendsFriendsFrameDropdown:SetWidth(132);
end

local function LocalizeButtonText_ptBR()
	-- truncate "share quest" string for ptBR. when enabled, the button will display a tooltip with the full text and description
	QuestFramePushQuestButton.Text:SetSize(QuestFramePushQuestButton:GetWidth()-3, QuestFramePushQuestButton:GetHeight())
end

local l10nTable = {
	deDE = {},
	enGB = {},
	enUS = {},
	esES = {
		localizeFrames = AdjustFriendsFrameDropdown_132,
	},
	esMX = {
		localizeFrames = AdjustFriendsFrameDropdown_132,
	},
	frFR = {},
	itIT = {},
	koKR = {},
	ptBR = {
		localizeFrames = AdjustFriendsFrameDropdown_132,
		localize = LocalizeButtonText_ptBR,
	},
	ptPT = {
		localizeFrames = AdjustFriendsFrameDropdown_132,
	},
	ruRU = {},
	zhCN = {},
	zhTW = {},
};

SetupLocalization(l10nTable);