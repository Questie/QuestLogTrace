-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_StaticPopup_Glue\GlueDialogUserScaledTemplates.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class GlueDialogButtonMixin : Button
GlueDialogButtonMixin = {};

function GlueDialogButtonMixin:OnTextScaleUpdated(scale, registrationInfo)
	self:SetHeight(registrationInfo.baseHeight * scale);

	local dialogInfo = self:GetOwningDialogInfo();
	if dialogInfo and dialogInfo.buttonTextMargin then
		self:SetWidth(self:GetTextWidth() + dialogInfo.buttonTextMargin);
	else
		local weightedScale = TextSizeManager:GetWeightedScale(scale, registrationInfo);
		self:SetWidth(registrationInfo.baseWidth * weightedScale);
	end
end