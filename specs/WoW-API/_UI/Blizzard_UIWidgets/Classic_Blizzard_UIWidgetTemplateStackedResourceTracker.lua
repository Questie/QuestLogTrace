-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_UIWidgets\Classic\Blizzard_UIWidgetTemplateStackedResourceTracker.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

local function GetStackedResourceTrackerVisInfoData(widgetID)
	local widgetInfo = C_UIWidgetManager.GetStackedResourceTrackerWidgetVisualizationInfo(widgetID);
	if widgetInfo and widgetInfo.shownState ~= Enum.WidgetShownState.Hidden then
		return widgetInfo;
	end
end

UIWidgetManager:RegisterWidgetVisTypeTemplate(Enum.UIWidgetVisualizationType.StackedResourceTracker, {frameType = "FRAME", frameTemplate = "UIWidgetTemplateStackedResourceTracker"}, GetStackedResourceTrackerVisInfoData);

---@class UIWidgetTemplateStackedResourceTrackerMixin : UIWidgetBaseTemplateMixin
UIWidgetTemplateStackedResourceTrackerMixin = CreateFromMixins(UIWidgetBaseTemplateMixin);

local frameTextureKitRegions = {
	["Frame"] = "%s-frame",
}

function UIWidgetTemplateStackedResourceTrackerMixin:Setup(widgetInfo)
	UIWidgetBaseTemplateMixin.Setup(self, widgetInfo);
	self.resourcePool:ReleaseAll();

	local previousResourceFrame;

	for index, resourceInfo in ipairs(widgetInfo.resources) do
		local resourceFrame = self.resourcePool:Acquire();
		resourceFrame:Show();

		resourceFrame:Setup(resourceInfo);

		if previousResourceFrame then
			resourceFrame:SetPoint("TOPLEFT", previousResourceFrame, "BOTTOMLEFT", 0, -6);
		else
			resourceFrame:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 49, -38);
		end

		if self.fontColor then
			resourceFrame:SetFontColor(self.fontColor);
		end

		previousResourceFrame = resourceFrame;
	end
	
	SetupTextureKits(widgetInfo.frameTextureKitID, self, frameTextureKitRegions, false, true);

	self:SetWidth(self.Frame:GetWidth() + 45);
	self:SetHeight(self.Frame:GetHeight());
end

function UIWidgetTemplateStackedResourceTrackerMixin:OnLoad()
	self.resourcePool = CreateFramePool("FRAME", self, "UIWidgetBaseResourceTemplate");
end

function UIWidgetTemplateStackedResourceTrackerMixin:OnReset()
	UIWidgetBaseTemplateMixin.OnReset(self);
	self.resourcePool:ReleaseAll();
	self.fontColor = nil;
end

function UIWidgetTemplateStackedResourceTrackerMixin:SetFontStringColor(fontColor)
	self.fontColor = fontColor;
end
