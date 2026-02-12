-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedXML\NewFeatureLabel.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class NewFeatureLabelMixin
NewFeatureLabelMixin = {};

function NewFeatureLabelMixin:OnLoad()
	self.BGLabel:SetTextToFit(self.label);
	self.Label:SetTextToFit(self.label);
	self.Label:SetJustifyH(self.justifyH);
	self.BGLabel:SetJustifyH(self.justifyH);
end

function NewFeatureLabelMixin:ClearAlert()
	-- derive
	self:SetShown(false);
end

function NewFeatureLabelMixin:NewFeatureLabel_OnShow()
	if self.animateGlow then
		self.Fade:Play();
	end

	self:MarkDirty();
end

function NewFeatureLabelMixin:OnHide()
	if self.animateGlow then
		self.Fade:Stop();
	end
end

function NewFeatureLabelMixin:GetTextWidth()
	return self.Label:GetWidth();
end
