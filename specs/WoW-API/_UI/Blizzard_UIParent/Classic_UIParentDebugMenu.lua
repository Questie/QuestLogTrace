-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_UIParent\Classic\UIParentDebugMenu.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

function UpdateUIParentRelativeToDebugMenu()
	if (DebugMenu and DebugMenu.IsVisible()) then
		UIParent:SetPoint("TOPLEFT", 0, -DebugMenu.GetMenuHeight());
	else
		UIParent:SetPoint("TOPLEFT", 0, 0);
	end
end