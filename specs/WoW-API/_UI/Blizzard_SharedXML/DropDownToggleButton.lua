-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedXML\DropDownToggleButton.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class DropDownToggleButtonMixin : Button
DropDownToggleButtonMixin = {};

function DropDownToggleButtonMixin:OnLoad_Intrinsic()
	self:RegisterForMouse("LeftButtonDown","LeftButtonUp");
end

function DropDownToggleButtonMixin:HandlesGlobalMouseEvent(buttonName, event)
	return event == "GLOBAL_MOUSE_DOWN" and buttonName == "LeftButton";
end