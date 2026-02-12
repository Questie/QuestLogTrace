-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SocialToast\SocialToast.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class DefaultAnimOutMixin
DefaultAnimOutMixin = {};

function DefaultAnimOutMixin:OnFinished()
	self:GetParent():Hide();
end

---@class SocialToastCloseButtonMixin : Button
SocialToastCloseButtonMixin = {};

function SocialToastCloseButtonMixin:OnEnter()
	self:GetParent():OnEnter();
end

function SocialToastCloseButtonMixin:OnLeave()
	self:GetParent():OnLeave();
end

function SocialToastCloseButtonMixin:OnClick()
	-- Currently all work is done in OnHide...possibly better to have a dedicated close method?
	self:GetParent():Hide();
end

---@class SocialToastMixin
SocialToastMixin = {};

function SocialToastMixin:OnEnter()
	AlertFrame_PauseOutAnimation(self);
end

function SocialToastMixin:OnLeave()
	AlertFrame_ResumeOutAnimation(self);
end