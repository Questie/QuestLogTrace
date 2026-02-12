-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_DeprecatedSpellBook\Deprecated_SpellBook.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- These are functions that were deprecated and will be removed in the future.
-- Please upgrade to the updated APIs as soon as possible.

if not GetCVarBool("loadDeprecationFallbacks") then
	return;
end

do
	HUNTER_DISMISS_PET = Constants.SpellBookSpellIDs.SPELL_ID_DISMISS_PET;

	---@deprecated
	---Deprecated by [C_SpellBook.IsSpellKnown](https://warcraft.wiki.gg/wiki/API_C_SpellBook.IsSpellKnown)
	---@param spellID number
	---@return boolean isKnown
	function IsPlayerSpell(spellID)
		local spellBank = Enum.SpellBookSpellBank.Player;
		return C_SpellBook.IsSpellKnown(spellID, spellBank);
	end

	---@deprecated
	---Deprecated by [C_SpellBook.IsSpellInSpellBook](https://warcraft.wiki.gg/wiki/API_C_SpellBook.IsSpellInSpellBook)
	---@param spellID number
	---@param isPet boolean?
	---@return boolean isInSpellBook
	function IsSpellKnown(spellID, isPet)
		local spellBank = isPet and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player;
		local includeOverrides = false;
		return C_SpellBook.IsSpellInSpellBook(spellID, spellBank, includeOverrides);
	end

	---@deprecated
	---Deprecated by [C_SpellBook.IsSpellInSpellBook](https://warcraft.wiki.gg/wiki/API_C_SpellBook.IsSpellInSpellBook)
	---@param spellID number
	---@param isPet boolean?
	---@return boolean isInSpellBook
	function IsSpellKnownOrOverridesKnown(spellID, isPet)
		local spellBank = isPet and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player;
		local includeOverrides = true;
		return C_SpellBook.IsSpellInSpellBook(spellID, spellBank, includeOverrides);
	end
end
