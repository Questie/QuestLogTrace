-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_DeprecatedTradeInfo\Deprecated_TradeInfo.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- These are functions that were deprecated and will be removed in the future.
-- Please upgrade to the updated APIs as soon as possible.

if not GetCVarBool("loadDeprecationFallbacks") then
	return;
end

PickupTradeMoney = function(amount)
	C_TradeInfo.PickupTradeMoney(amount);
end
