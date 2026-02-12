-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_Colors\Shared\MaterialColors.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

function GetMaterialTextColors(material)
	local textColor = MATERIAL_TEXT_COLOR_TABLE[material];
	local titleColor = MATERIAL_TITLETEXT_COLOR_TABLE[material];
	if not (textColor and titleColor) then
		textColor = MATERIAL_TEXT_COLOR_TABLE["Default"];
		titleColor = MATERIAL_TITLETEXT_COLOR_TABLE["Default"];
	end
	return {textColor:GetRGB()}, {titleColor:GetRGB()};
end
