-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_ObjectAPI\Classic\Spell.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class Spell
Spell = {};
---@class SpellMixin
---[Documentation](https://warcraft.wiki.gg/wiki/SpellMixin)
SpellMixin = {};

local SpellEventListener;

---@param spellID number
---@return SpellMixin
function Spell:CreateFromSpellID(spellID)
	local spell = CreateFromMixins(SpellMixin);
	spell:SetSpellID(spellID);
	return spell;
end

---@param spellID number
function SpellMixin:SetSpellID(spellID)
	self:Clear();
	self.spellID = spellID;
end

---@return number
function SpellMixin:GetSpellID()
	return self.spellID;
end

function SpellMixin:Clear()
	self.spellID = nil;
end

---@return boolean
function SpellMixin:IsSpellEmpty()
	local spellID = self:GetSpellID();
	return not spellID or not C_Spell.DoesSpellExist(spellID);
end

-- Spell API
---@return boolean
function SpellMixin:IsSpellDataCached()
	if not self:IsSpellEmpty() then
		return C_Spell.IsSpellDataCached(self:GetSpellID());
	end
	return true; 
end

---@return string
function SpellMixin:GetSpellName()
	return (GetSpellInfo(self:GetSpellID()));
end

---@return string
function SpellMixin:GetSpellSubtext()
	return C_Spell.GetSpellSubtext(self:GetSpellID());
end

---@return string
function SpellMixin:GetSpellDescription()
	return GetSpellDescription(self:GetSpellID());
end

-- Add a callback to be executed when spell data is loaded, if the spell data is already loaded then execute it immediately
-- Add a callback to be executed when spell data is loaded, if the spell data is already loaded then execute it immediately
---@param callbackFunction function
function SpellMixin:ContinueOnSpellLoad(callbackFunction)
	if type(callbackFunction) ~= "function" or self:IsSpellEmpty() then
		error("Usage: NonEmptySpell:ContinueOnLoad(callbackFunction)", 2);
	end

	SpellEventListener:AddCallback(self:GetSpellID(), callbackFunction);
end

-- Same as ContinueOnSpellLoad, except it returns a function that when called will cancel the continue
-- Same as ContinueOnSpellLoad, except it returns a function that when called will cancel the continue
---@param callbackFunction function
---@return function
function SpellMixin:ContinueWithCancelOnSpellLoad(callbackFunction)
	if type(callbackFunction) ~= "function" or self:IsSpellEmpty() then
		error("Usage: NonEmptySpell:ContinueWithCancelOnSpellLoad(callbackFunction)", 2);
	end

	return SpellEventListener:AddCancelableCallback(self:GetSpellID(), callbackFunction);
end

--[ Spell Event Listener ]

SpellEventListener = CreateFrame("Frame");
SpellEventListener.callbacks = {};

SpellEventListener:SetScript("OnEvent", 
	function(self, event, ...)
		if event == "SPELL_DATA_LOAD_RESULT" then
			local spellID, success = ...;
			if success then
				self:FireCallbacks(spellID);
			else
				self:ClearCallbacks(spellID);
			end
		end
	end
);
SpellEventListener:RegisterEvent("SPELL_DATA_LOAD_RESULT");

local CANCELED_SENTINEL = -1;

function SpellEventListener:AddCallback(spellID, callbackFunction)
	local callbacks = self:GetOrCreateCallbacks(spellID);
	table.insert(callbacks, callbackFunction);
	C_Spell.RequestLoadSpellData(spellID);
end

function SpellEventListener:AddCancelableCallback(spellID, callbackFunction)
	local callbacks = self:GetOrCreateCallbacks(spellID);
	table.insert(callbacks, callbackFunction);
	C_Spell.RequestLoadSpellData(spellID);

	local index = #callbacks;
	return function()
		if #callbacks > 0 and callbacks[index] ~= CANCELED_SENTINEL then
			callbacks[index] = CANCELED_SENTINEL;
			return true;
		end
		return false;
	end;
end

do
	local function CallErrorHandler(...)
		return geterrorhandler()(...);
	end

	function SpellEventListener:FireCallbacks(spellID)
		local callbacks = self:GetCallbacks(spellID);
		if callbacks then
			self:ClearCallbacks(spellID);
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
end

function SpellEventListener:ClearCallbacks(spellID)
	self.callbacks[spellID] = nil;
end

function SpellEventListener:GetCallbacks(spellID)
	return self.callbacks[spellID];
end

function SpellEventListener:GetOrCreateCallbacks(spellID)
	local callbacks = self.callbacks[spellID];
	if not callbacks then
		callbacks = {};
		self.callbacks[spellID] = callbacks;
	end
	return callbacks;
end