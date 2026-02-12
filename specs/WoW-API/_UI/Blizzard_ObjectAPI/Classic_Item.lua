-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_ObjectAPI\Classic\Item.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class Item
Item = {};
---@class ItemMixin
---[Documentation](https://warcraft.wiki.gg/wiki/ItemMixin)
ItemMixin = {};

local ItemEventListener;

---@param itemLocation ItemLocation
---@return ItemMixin
function Item:CreateFromItemLocation(itemLocation)
	if type(itemLocation) ~= "table" or type(itemLocation.HasAnyLocation) ~= "function" or not itemLocation:HasAnyLocation() then
		error("Usage: Item:CreateFromItemLocation(notEmptyItemLocation)", 2);
	end
	local item = CreateFromMixins(ItemMixin);
	item:SetItemLocation(itemLocation);
	return item;
end

---@param bagID number
---@param slotIndex number
---@return ItemMixin
function Item:CreateFromBagAndSlot(bagID, slotIndex)
	if type(bagID) ~= "number" or type(slotIndex) ~= "number" then
		error("Usage: Item:CreateFromBagAndSlot(bagID, slotIndex)", 2);
	end
	local item = CreateFromMixins(ItemMixin);
	item:SetItemLocation(ItemLocation:CreateFromBagAndSlot(bagID, slotIndex));
	return item;
end

---@param equipmentSlotIndex number
---@return ItemMixin
function Item:CreateFromEquipmentSlot(equipmentSlotIndex)
	if type(equipmentSlotIndex) ~= "number" then
		error("Usage: Item:CreateFromEquipmentSlot(equipmentSlotIndex)", 2);
	end
	local item = CreateFromMixins(ItemMixin);
	item:SetItemLocation(ItemLocation:CreateFromEquipmentSlot(equipmentSlotIndex));
	return item;
end

---@param itemLink string
---@return ItemMixin
function Item:CreateFromItemLink(itemLink)
	if type(itemLink) ~= "string" then
		error("Usage: Item:CreateFromItemLink(itemLinkString)", 2);
	end
	local item = CreateFromMixins(ItemMixin);
	item:SetItemLink(itemLink);
	return item;
end

---@param itemID number
---@return ItemMixin
function Item:CreateFromItemID(itemID)
	if type(itemID) ~= "number" then
		error("Usage: Item:CreateFromItemID(itemID)", 2);
	end
	local item = CreateFromMixins(ItemMixin);
	item:SetItemID(itemID);
	return item;
end

---@param itemLocation ItemLocation
function ItemMixin:SetItemLocation(itemLocation)
	self:Clear();
	self.itemLocation = itemLocation;
end

---@param itemLink string
function ItemMixin:SetItemLink(itemLink)
	self:Clear();
	self.itemLink = itemLink;
end

---@param itemID number
function ItemMixin:SetItemID(itemID)
	self:Clear();
	self.itemID = itemID;
end

---@return ItemLocation
function ItemMixin:GetItemLocation()
	return self.itemLocation;
end

---@return boolean
function ItemMixin:HasItemLocation()
	return self.itemLocation ~= nil;
end

function ItemMixin:Clear()
	self.itemLocation = nil;
	self.itemLink = nil;
	self.itemID = nil;
end

---@return boolean
function ItemMixin:IsItemEmpty()
	if self:GetStaticBackingItem() then
		return not C_Item.DoesItemExistByID(self:GetStaticBackingItem());
	end

	return not self:IsItemInPlayersControl();
end

---@return string|number
function ItemMixin:GetStaticBackingItem()
	return self.itemLink or self.itemID;
end

---@return boolean
function ItemMixin:IsItemInPlayersControl()
	local itemLocation = self:GetItemLocation();
	return itemLocation and C_Item.DoesItemExist(itemLocation); 
end

-- Item API
-- Item API
---@return number
function ItemMixin:GetItemID()
	if self:GetStaticBackingItem() then
		return (C_Item.GetItemInfoInstant(self:GetStaticBackingItem()));
	end

	if not self:IsItemEmpty() then
		return C_Item.GetItemID(self:GetItemLocation());
	end
	return nil;
end

---@return boolean
function ItemMixin:IsItemLocked()
	return self:IsItemInPlayersControl() and C_Item.IsLocked(self:GetItemLocation());
end

function ItemMixin:LockItem()
	if self:IsItemInPlayersControl() then
		C_Item.LockItem(self:GetItemLocation());
	end
end

function ItemMixin:UnlockItem()
	if self:IsItemInPlayersControl() then
		C_Item.UnlockItem(self:GetItemLocation());
	end
end

---@return number
function ItemMixin:GetItemIcon() -- requires item data to be loaded
	if self:GetStaticBackingItem() then
		return C_Item.GetItemIconByID(self:GetStaticBackingItem());
	end

	if not self:IsItemEmpty() then
		return C_Item.GetItemIcon(self:GetItemLocation());
	end
end

---@return string
function ItemMixin:GetItemName() -- requires item data to be loaded
	if self:GetStaticBackingItem() then
		return C_Item.GetItemNameByID(self:GetStaticBackingItem());
	end

	if not self:IsItemEmpty() then
		return C_Item.GetItemName(self:GetItemLocation());
	end
	return nil;
end

---@return string
function ItemMixin:GetItemLink() -- requires item data to be loaded
	if self.itemLink then
		return self.itemLink;
	end

	if self.itemID then
		return (select(2, C_Item.GetItemInfo(self.itemID)));
	end

	if not self:IsItemEmpty() then
		return C_Item.GetItemLink(self:GetItemLocation());
	end
	return nil;
end

---@return Enum.ItemQuality
function ItemMixin:GetItemQuality() -- requires item data to be loaded
	if self:GetStaticBackingItem() then
		return C_Item.GetItemQualityByID(self:GetStaticBackingItem());
	end

	if not self:IsItemEmpty() then
		return C_Item.GetItemQuality(self:GetItemLocation());
	end
	return nil;
end

---@return number
function ItemMixin:GetCurrentItemLevel() -- requires item data to be loaded
	if self:GetStaticBackingItem() then
		return (C_Item.GetDetailedItemLevelInfo(self:GetStaticBackingItem()));
	end

	if not self:IsItemEmpty() then
		return C_Item.GetCurrentItemLevel(self:GetItemLocation());
	end
	return nil;
end

---@return table
function ItemMixin:GetItemQualityColor() -- requires item data to be loaded
	local itemQuality = self:GetItemQuality();
	return ITEM_QUALITY_COLORS[itemQuality]; -- may be nil if item data isn't loaded
end

---@return Enum.InventoryType
function ItemMixin:GetInventoryType()
	if self:GetStaticBackingItem() then
		return C_Item.GetItemInventoryTypeByID(self:GetStaticBackingItem());
	end

	if not self:IsItemEmpty() then
		return C_Item.GetItemInventoryType(self:GetItemLocation());
	end
	return nil;
end

---@return string
function ItemMixin:GetItemGUID()
	if self:GetStaticBackingItem() then
		return nil;
	end

	if not self:IsItemEmpty() then
		return C_Item.GetItemGUID(self:GetItemLocation());
	end
	return nil;
end

---@return string
function ItemMixin:GetInventoryTypeName()
	if not self:IsItemEmpty() then
		return select(4, C_Item.GetItemInfoInstant(self:GetItemID()));
	end
end

---@return boolean
function ItemMixin:IsItemDataCached()
	if self:GetStaticBackingItem() then
		return C_Item.IsItemDataCachedByID(self:GetStaticBackingItem());
	end

	if not self:IsItemEmpty() then
		return C_Item.IsItemDataCached(self:GetItemLocation());
	end
	return true; 
end

---@return boolean
function ItemMixin:IsDataEvictable()
	-- Item data could be evicted from the cache
	return true;
end

-- Add a callback to be executed when item data is loaded, if the item data is already loaded then execute it immediately
--- Add a callback to be executed when item data is loaded, if the item data is already loaded then execute it immediately
---@param callbackFunction function
function ItemMixin:ContinueOnItemLoad(callbackFunction)
	if type(callbackFunction) ~= "function" or self:IsItemEmpty() then
		error("Usage: NonEmptyItem:ContinueOnLoad(callbackFunction)", 2);
	end

	ItemEventListener:AddCallback(self:GetItemID(), callbackFunction);
end

-- Same as ContinueOnItemLoad, except it returns a function that when called will cancel the continue
--- Same as ContinueOnItemLoad, except it returns a function that when called will cancel the continue
---@param callbackFunction function
---@return function
function ItemMixin:ContinueWithCancelOnItemLoad(callbackFunction)
	if type(callbackFunction) ~= "function" or self:IsItemEmpty() then
		error("Usage: NonEmptyItem:ContinueWithCancelOnItemLoad(callbackFunction)", 2);
	end

	return ItemEventListener:AddCancelableCallback(self:GetItemID(), callbackFunction);
end

--[ Item Event Listener ]

ItemEventListener = CreateFrame("Frame");
ItemEventListener.callbacks = {};

ItemEventListener:SetScript("OnEvent", 
	function(self, event, ...)
		if event == "ITEM_DATA_LOAD_RESULT" then
			local itemID, success = ...;
			if success then
				self:FireCallbacks(itemID);
			else
				self:ClearCallbacks(itemID);
			end
		end
	end
);
ItemEventListener:RegisterEvent("ITEM_DATA_LOAD_RESULT");

local CANCELED_SENTINEL = -1;

function ItemEventListener:AddCallback(itemID, callbackFunction)
	local callbacks = self:GetOrCreateCallbacks(itemID);
	table.insert(callbacks, callbackFunction);
	C_Item.RequestLoadItemDataByID(itemID);
end

function ItemEventListener:AddCancelableCallback(itemID, callbackFunction)
	local callbacks = self:GetOrCreateCallbacks(itemID);
	table.insert(callbacks, callbackFunction);
	C_Item.RequestLoadItemDataByID(itemID);

	local index = #callbacks;
	return function()
		if #callbacks > 0 and callbacks[index] ~= CANCELED_SENTINEL then
			callbacks[index] = CANCELED_SENTINEL;
			return true;
		end
		return false;
	end;
end

function ItemEventListener:FireCallbacks(itemID)
	local callbacks = self:GetCallbacks(itemID);
	if callbacks then
		self:ClearCallbacks(itemID);
		for i, callback in ipairs(callbacks) do
			if callback ~= CANCELED_SENTINEL then
				xpcall(callback, CallErrorHandler);
			end
		end

		for i = #callbacks, 1, -1 do
			callbacks[i] = nil;
		end
	end
end

function ItemEventListener:ClearCallbacks(itemID)
	self.callbacks[itemID] = nil;
end

function ItemEventListener:GetCallbacks(itemID)
	return self.callbacks[itemID];
end

function ItemEventListener:GetOrCreateCallbacks(itemID)
	local callbacks = self.callbacks[itemID];
	if not callbacks then
		callbacks = {};
		self.callbacks[itemID] = callbacks;
	end
	return callbacks;
end