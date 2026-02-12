-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_UIWidgets\Classic\Blizzard_UIWidgetTemplateDoubleIconAndText.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

local function GetDoubleIconAndTextVisInfoData(widgetID)
	local widgetInfo = C_UIWidgetManager.GetDoubleIconAndTextWidgetVisualizationInfo(widgetID);
	if widgetInfo and widgetInfo.shownState ~= Enum.WidgetShownState.Hidden then
		return widgetInfo;
	end
end

UIWidgetManager:RegisterWidgetVisTypeTemplate(Enum.UIWidgetVisualizationType.DoubleIconAndText, {frameType = "FRAME", frameTemplate = "UIWidgetTemplateDoubleIconAndText"}, GetDoubleIconAndTextVisInfoData);

---@class UIWidgetTemplateDoubleIconAndTextMixin : UIWidgetBaseTemplateMixin
UIWidgetTemplateDoubleIconAndTextMixin = CreateFromMixins(UIWidgetBaseTemplateMixin);

local textureKitRegions = {
	["LeftIcon"] = "%s-leftIcon",
	["RightIcon"] = "%s-rightIcon",
}

function UIWidgetTemplateDoubleIconAndTextMixin:Setup(widgetInfo)
	UIWidgetBaseTemplateMixin.Setup(self, widgetInfo);
	SetupTextureKits(widgetInfo.textureKitID, self, textureKitRegions, true);

	self.Label:SetText(widgetInfo.label);

	self.Left.Text:SetText(widgetInfo.leftText);
	self.Left:SetTooltip(widgetInfo.leftTooltip);
	self.Left:SetWidth(self.Left.Icon:GetWidth() + self.Left.Text:GetWidth() + 5)

	self.Right.Text:SetText(widgetInfo.rightText);
	self.Right:SetTooltip(widgetInfo.rightTooltip);
	self.Right:SetWidth(self.Right.Icon:GetWidth() + self.Right.Text:GetWidth() + 5)

	local totalWidth = self.Label:GetWidth() + 15 + self.Left:GetWidth() + 25 + self.Right:GetWidth();
	self:SetWidth(totalWidth);
end

function UIWidgetTemplateDoubleIconAndTextMixin:OnLoad()
	self.LeftIcon = self.Left.Icon;
	self.RightIcon = self.Right.Icon;
end
