-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_FrameXML\CustomBindingHandler.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class CustomBindingHandler
CustomBindingHandler = {};
---@class CustomBindingHandlerMixin
CustomBindingHandlerMixin = {};

function CustomBindingHandler:CreateHandler(customBindingType)
	local handler = CreateFromMixins(CustomBindingHandlerMixin);
	handler:OnLoad(customBindingType);
	return handler;
end

function CustomBindingHandlerMixin:OnLoad(customBindingType)
	self.customBindingType = customBindingType;
end

function CustomBindingHandlerMixin:CallOnBindingModeActivatedCallback(isActive)
	if self.bindingModeActivatedCallback then
		self.bindingModeActivatedCallback(isActive);
	end
end

function CustomBindingHandlerMixin:CallOnBindingCompletedCallback(completedSuccessfully, keys)
	if self.bindingCompletedCallback then
		self.bindingCompletedCallback(completedSuccessfully, keys);
	end
end

function CustomBindingHandlerMixin:SetOnBindingModeActivatedCallback(callback)
	self.bindingModeActivatedCallback = callback;
end

function CustomBindingHandlerMixin:SetOnBindingCompletedCallback(callback)
	self.bindingCompletedCallback = callback;
end

function CustomBindingHandlerMixin:GetCustomBindingType()
	return self.customBindingType;
end