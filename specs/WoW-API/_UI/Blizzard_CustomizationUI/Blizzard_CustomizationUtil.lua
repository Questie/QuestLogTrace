-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_CustomizationUI\Blizzard_CustomizationUtil.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

local function GetShouldShowDebugTooltipInfo()
	return GetCVarBool("debugTargetInfo");
end
local showDebugTooltipInfo = GetShouldShowDebugTooltipInfo();

---@class CustomizationUtil
CustomizationUtil = {};

function CustomizationUtil.UpdateShowDebugTooltipInfo()
	showDebugTooltipInfo = GetShouldShowDebugTooltipInfo();
end

function CustomizationUtil.ShouldShowDebugTooltipInfo()
	return showDebugTooltipInfo;
end