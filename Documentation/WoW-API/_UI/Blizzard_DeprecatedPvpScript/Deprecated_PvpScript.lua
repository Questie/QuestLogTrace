-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_DeprecatedPvpScript\Deprecated_PvpScript.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- These are functions that were deprecated and will be removed in the future.
-- Please upgrade to the updated APIs as soon as possible.

if not GetCVarBool("loadDeprecationFallbacks") then
	return;
end

do
	IsSubZonePVPPOI = C_PvP.IsSubZonePVPPOI;
	GetZonePVPInfo = C_PvP.GetZonePVPInfo;
	TogglePVP = C_PvP.TogglePVP;
	SetPVP = C_PvP.SetPVP;
end