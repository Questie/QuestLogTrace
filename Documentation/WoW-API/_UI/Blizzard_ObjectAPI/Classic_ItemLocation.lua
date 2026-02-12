-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_ObjectAPI\Classic\ItemLocation.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class ItemLocation
ItemLocation = {};
---@class ItemLocationMixin
---[Documentation](https://warcraft.wiki.gg/wiki/ItemLocationMixin)
ItemLocationMixin = {};

---@return ItemLocation
function ItemLocation:CreateEmpty()
	local itemLocation = CreateFromMixins(ItemLocationMixin);
	return itemLocation;
end

---@param bagID number
---@param slotIndex number
---@return ItemLocation
function ItemLocation:CreateFromBagAndSlot(bagID, slotIndex)
	local itemLocation = ItemLocation:CreateEmpty();
	itemLocation:SetBagAndSlot(bagID, slotIndex);
	return itemLocation;
end

---@param equipmentSlotIndex number
---@return ItemLocation
function ItemLocation:CreateFromEquipmentSlot(equipmentSlotIndex)
	local itemLocation = ItemLocation:CreateEmpty();
	itemLocation:SetEquipmentSlot(equipmentSlotIndex);
	return itemLocation;
end

function ItemLocationMixin:Clear()
	self.bagID = nil;
	self.slotIndex = nil;
	self.equipmentSlotIndex = nil;
end

---@param bagID number
---@param slotIndex number
function ItemLocationMixin:SetBagAndSlot(bagID, slotIndex)
	self:Clear();

	self.bagID = bagID;
	self.slotIndex = slotIndex;
end

---@return number bagID
---@return number slotIndex
function ItemLocationMixin:GetBagAndSlot()
	return self.bagID, self.slotIndex;
end

---@param equipmentSlotIndex number
function ItemLocationMixin:SetEquipmentSlot(equipmentSlotIndex)
	self:Clear();

	self.equipmentSlotIndex = equipmentSlotIndex;
end

---@return number
function ItemLocationMixin:GetEquipmentSlot()
	return self.equipmentSlotIndex;
end

---@return boolean
function ItemLocationMixin:IsEquipmentSlot()
	return self.equipmentSlotIndex ~= nil;
end

---@return boolean
function ItemLocationMixin:IsBagAndSlot()
	return self.bagID ~= nil and self.slotIndex ~= nil;
end

---@return boolean
function ItemLocationMixin:HasAnyLocation()
	return self:IsEquipmentSlot() or self:IsBagAndSlot();
end

---@return boolean
function ItemLocationMixin:IsValid()
	return C_Item.DoesItemExist(self);
end

---@param otherBagID number
---@param otherSlotIndex number
---@return boolean
function ItemLocationMixin:IsEqualToBagAndSlot(otherBagID, otherSlotIndex)
	local bagID, slotIndex = self:GetBagAndSlot();
	if bagID and slotIndex then
		return bagID == otherBagID and slotIndex == otherSlotIndex;
	end
	return false;
end

---@param otherEquipmentSlotIndex number
---@return boolean
function ItemLocationMixin:IsEqualToEquipmentSlot(otherEquipmentSlotIndex)
	local equipmentSlotIndex = self:GetEquipmentSlot();
	if equipmentSlotIndex then
		return equipmentSlotIndex == otherEquipmentSlotIndex;
	end
	return false;
end

---@param otherItemLocation ItemLocation
---@return boolean
function ItemLocationMixin:IsEqualTo(otherItemLocation)
	if otherItemLocation then
		local bagID, slotIndex = self:GetBagAndSlot();
		if bagID and slotIndex then
			local otherBagID, otherSlotIndex = otherItemLocation:GetBagAndSlot();
			return bagID == otherBagID and slotIndex == otherSlotIndex;
		end

		local equipmentSlotIndex = self:GetEquipmentSlot();
		if equipmentSlotIndex then
			local otherEquipmentSlotIndex = otherItemLocation:GetEquipmentSlot();
			return equipmentSlotIndex == otherEquipmentSlotIndex;
		end

		return not otherItemLocation:HasAnyLocation();
	end

	return false;
end