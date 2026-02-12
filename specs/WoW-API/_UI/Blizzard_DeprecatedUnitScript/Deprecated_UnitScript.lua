-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_DeprecatedUnitScript\Deprecated_UnitScript.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- These are functions that were deprecated and will be removed in the future.
-- Please upgrade to the updated APIs as soon as possible.

if not GetCVarBool("loadDeprecationFallbacks") then
	return;
end

do
	---@deprecated
	---Deprecated by [UnitIsVisible](https://warcraft.wiki.gg/wiki/API_UnitIsVisible)
	---@param unit? UnitToken Default = WOWGUID_NULL
	---@return boolean result
	function ShowBossFrameWhenUninteractable(unit)
		return UnitIsVisible(unit);
	end
end
