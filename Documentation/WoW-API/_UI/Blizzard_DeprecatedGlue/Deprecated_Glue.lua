-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_DeprecatedGlue\Deprecated_Glue.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- These are functions that were deprecated and will be removed in the future.
-- Please upgrade to the updated APIs as soon as possible.

if not GetCVarBool("loadDeprecationFallbacks") then
	return;
end

do
	IsOnGlueScreen = C_Glue.IsOnGlueScreen();
end