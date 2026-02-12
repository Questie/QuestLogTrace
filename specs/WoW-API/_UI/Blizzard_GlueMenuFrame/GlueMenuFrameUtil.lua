-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_GlueMenuFrame\GlueMenuFrameUtil.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class GlueMenuFrameUtil
GlueMenuFrameUtil = {};

GlueMenuFrameUtil.GlueMenuContextKey = "GlueMenuFrame";

function GlueMenuFrameUtil.ShowMenu()
	GlueMenuFrame:Show();
end

function GlueMenuFrameUtil.HideMenu()
	PlaySound(SOUNDKIT.IG_MAINMENU_CONTINUE);
	GlueMenuFrame:Hide();
end

function GlueMenuFrameUtil.ToggleMenu()
	if GlueMenuFrame:IsShown() then
		GlueMenuFrameUtil.HideMenu();
	else
		GlueMenuFrameUtil.ShowMenu();
	end
end