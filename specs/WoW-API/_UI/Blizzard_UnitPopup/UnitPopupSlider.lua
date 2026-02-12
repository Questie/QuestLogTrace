-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_UnitPopup\UnitPopupSlider.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class UnitPopupSliderMixin : Slider
UnitPopupSliderMixin = {};

function UnitPopupSliderMixin:OnEnter()
	ExecuteFrameScript(self:GetParent(), "OnEnter");
	PropertyBindingMixin.OnEnter(self);
end

function UnitPopupSliderMixin:OnLeave()
	ExecuteFrameScript(self:GetParent(), "OnLeave");
	PropertyBindingMixin.OnLeave(self);
end