-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_AuctionHouseUI\Shared\Blizzard_AuctionHouseTab.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

local MIN_TAB_WIDTH = 70;
local TAB_PADDING = 20;


---@class AuctionHouseFrameTabMixin
AuctionHouseFrameTabMixin = {};

function AuctionHouseFrameTabMixin:OnShow()
	local absoluteSize = nil;
	PanelTemplates_TabResize(self, TAB_PADDING, absoluteSize, MIN_TAB_WIDTH);
end


---@class AuctionHouseFrameTopTabMixin : AuctionHouseFrameTabMixin
AuctionHouseFrameTopTabMixin = CreateFromMixins(AuctionHouseFrameTabMixin);

function AuctionHouseFrameTopTabMixin:OnClick()
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end


---@class AuctionHouseFrameDisplayModeTabMixin
AuctionHouseFrameDisplayModeTabMixin = {};

function AuctionHouseFrameDisplayModeTabMixin:OnClick()
	CallMethodOnNearestAncestor(self, "SetDisplayMode", self.displayMode);
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end