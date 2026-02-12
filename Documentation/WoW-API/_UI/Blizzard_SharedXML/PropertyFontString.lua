-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedXML\PropertyFontString.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- NOTE: This is a read-only property, it reflects the state of a property with text output.

---@class PropertyFontStringMixin
PropertyFontStringMixin = {};

function PropertyFontStringMixin:SetMutator()
	error("PropertyFontStringMixin cannot change a property, only read it.");
end

function PropertyFontStringMixin:SetMutatorFunctionThroughSelf()
	error("PropertyFontStringMixin cannot change a property, only read it.");
end

function PropertyFontStringMixin:SetText(...)
	self.Text:SetText(...);
end
