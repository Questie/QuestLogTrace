-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_Deprecated\Deprecated_1_14_2.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- These are functions are deprecated, and will be removed in the next expansion.
-- Please upgrade to the updated APIs as soon as possible.

if not GetCVarBool("loadDeprecationFallbacks") then
	return;
end

-- Unit Sex enum conversions
do
	Enum.Unitsex = Enum.UnitSex;
end
