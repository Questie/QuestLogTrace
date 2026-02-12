-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_CatalogShop\Blizzard_CatalogShop_Unsecure.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- DO NOT PUT ANY SENSITIVE CODE IN THIS FILE
-- This file does not have access to the secure (forbidden) code.  It is only called via Outbound and no function in this file should ever return values.
SwapToGlobalEnvironment();

function CatalogShopSetItemTooltip(itemID, left, top, point)
	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE");
	GameTooltip:SetPoint(point, UIParent, "BOTTOMLEFT", left, top);
	GameTooltip:SetItemByID(itemID);
	GameTooltip:Show();
end
