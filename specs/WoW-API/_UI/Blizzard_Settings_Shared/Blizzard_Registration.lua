-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_Settings_Shared\Blizzard_Registration.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

do
	if not C_Glue.IsOnGlueScreen() then
		local attributes = 
		{ 
			area = "center",
			pushable = 0,
			whileDead = 1,
			checkFit = 1,
		};
		RegisterUIPanel(SettingsPanel, attributes);
	end
end