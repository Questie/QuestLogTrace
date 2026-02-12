-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_UIParentPanelManager\Shared\UpdateUIPanelPositions.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

if not IsInGlobalEnvironment() then
	return;
end

UIParent:SetScript("OnAttributeChanged", UpdateUIPanelPositions);