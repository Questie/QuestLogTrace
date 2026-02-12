-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SettingsDefinitions_Shared\AccessibilitySettingsPreview.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class AccessibilitySettingsPreviewMixin
AccessibilitySettingsPreviewMixin = { };

function AccessibilitySettingsPreviewMixin:SetValueAccessor(accessor)
	self.accessor = accessor;
end

function AccessibilitySettingsPreviewMixin:GetValue()
	return self.accessor();
end

function AccessibilitySettingsPreviewMixin:RegisterWithSettingInitializer(initializer)
	initializer.OnShow = function()
		self:Show();
	end

	initializer.OnHide = function()
		self:Hide();
	end
end

function AccessibilitySettingsPreviewMixin:OnShow()
	self:UpdatePreview(self:GetValue());
end

function AccessibilitySettingsPreviewMixin:UpdatePreview(_value)
	-- override if needed
end