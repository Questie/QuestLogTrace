-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SettingsDefinitions_Frame\Classic\ColorblindOverrides.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class ColorblindOverrides
ColorblindOverrides = {}

function ColorblindOverrides.CreateSettings(category, layout)
	-- Custom colorblind type and intensity
	local settings =
	{
		colorblindSimulator = colorblindSimulatorSetting,
		colorblindFactor = colorblindFactorSetting,
	};
	local data = { settings = settings };
	local initializer = Settings.CreatePanelInitializer("ColorblindSelectorTemplate", data);
	layout:AddInitializer(initializer);
end


---@class ColorblindSelectorMixin
ColorblindSelectorMixin = {};

function ColorblindSelectorMixin:OnLoad()
	local qualityIDs = 
	{
		Enum.ItemQuality.Good,
		Enum.ItemQuality.Rare,
		Enum.ItemQuality.Epic,
		Enum.ItemQuality.Legendary,
		Enum.ItemQuality.Heirloom,
	};

	for index, qualityID in ipairs(qualityIDs) do
		local itemQuality = self.ColorblindExamples.ItemQualities[index];
		itemQuality:SetText(_G["ITEM_QUALITY"..qualityID.."_DESC"]);
		itemQuality:SetTextColor(ITEM_QUALITY_COLORS[qualityID].color:GetRGB());
	end

	self.ColorblindExamples.ExampleIcon4:SetTexture("Interface\\Icons\\INV_Misc_Gem_Variety_02");
	self.ColorblindExamples.ExampleIcon6:SetTexture("Interface\\Icons\\Spell_Holy_SealOfRighteousness");
end

function Settings.GetColorblindSettingsLabel()
	return COLORBLIND_LABEL;
end
