-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_DeprecatedCurrencyScript\Deprecated_CurrencyScript.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- These are functions that were deprecated and will be removed in the future.
-- Please upgrade to the updated APIs as soon as possible.

if not GetCVarBool("loadDeprecationFallbacks") then
	return;
end

do
	GetCoinIcon = C_CurrencyInfo.GetCoinIcon;
	GetCoinText = C_CurrencyInfo.GetCoinText;
	GetCoinTextureString = C_CurrencyInfo.GetCoinTextureString;
end