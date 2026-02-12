-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedXMLBase\Color.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class ColorMixin
---[FrameXML](https://www.townlong-yak.com/framexml/go/ColorMixin)
ColorMixin = {};

---[FrameXML](https://www.townlong-yak.com/framexml/go/CreateColor)
---@param r number
---@param g number
---@param b number
---@param a? number
---@return colorRGBA
function CreateColor(r, g, b, a)
	local color = CreateFromMixins(ColorMixin);
	color:OnLoad(r, g, b, a);
	return color;
end

function ColorMixin:OnLoad(r, g, b, a)
	self:SetRGBA(r, g, b, a);
end

function ColorMixin:IsRGBEqualTo(otherColor)
	return self.r == otherColor.r 
		and self.g == otherColor.g 
		and self.b == otherColor.b;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/ColorMixin:IsEqualTo)
---@param otherColor colorRGBA
---@return boolean
function ColorMixin:IsEqualTo(otherColor)
	return self:IsRGBEqualTo(otherColor) and self.a == otherColor.a;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/ColorMixin:GetRGB)
---@return number r
---@return number g
---@return number b
function ColorMixin:GetRGB()
	return self.r, self.g, self.b;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/ColorMixin:GetRGBAsBytes)
---@return number r
---@return number g
---@return number b
function ColorMixin:GetRGBAsBytes()
	return Round(self.r * 255), Round(self.g * 255), Round(self.b * 255);
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/ColorMixin:GetRGBA)
---@return number r
---@return number g
---@return number b
---@return number? a
function ColorMixin:GetRGBA()
	return self.r, self.g, self.b, self.a;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/ColorMixin:GetRGBAAsBytes)
---@return number r
---@return number g
---@return number b
---@return number? a
function ColorMixin:GetRGBAAsBytes()
	return Round(self.r * 255), Round(self.g * 255), Round(self.b * 255), Round((self.a or 1) * 255);
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/ColorMixin:SetRGBA)
---@param r number
---@param g number
---@param b number
---@param a? number
function ColorMixin:SetRGBA(r, g, b, a)
	self.r = r;
	self.g = g;
	self.b = b;
	self.a = a or 1;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/ColorMixin:SetRGB)
---@param r number
---@param g number
---@param b number
function ColorMixin:SetRGB(r, g, b)
	self:SetRGBA(r, g, b, nil);
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/ColorMixin:GenerateHexColor)
---@return string
function ColorMixin:GenerateHexColor()
	return ("ff%.2x%.2x%.2x"):format(self:GetRGBAsBytes());
end

function ColorMixin:GenerateHexColorNoAlpha()
	return ("%.2X%.2X%.2X"):format(self:GetRGBAsBytes());
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/ColorMixin:GenerateHexColorMarkup)
---@return string
function ColorMixin:GenerateHexColorMarkup()
	return "|c"..self:GenerateHexColor();
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/ColorMixin:WrapTextInColorCode)
---@param text string
---@return string
function ColorMixin:WrapTextInColorCode(text)
	return WrapTextInColorCode(text, self:GenerateHexColor());
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/WrapTextInColorCode)
---@param text string
---@param colorHexString string
---@return string
function WrapTextInColorCode(text, colorHexString)
	return ("|c%s%s|r"):format(colorHexString, text);
end

function WrapTextInColor(text, color)
	return WrapTextInColorCode(text, color:GenerateHexColor());
end

do
	local envTbl = GetCurrentEnvironment();
	local DBColors = C_UIColor.GetColors();
	for _, dbColor in ipairs(DBColors) do
		local color = CreateColor(dbColor.color.r, dbColor.color.g, dbColor.color.b, dbColor.color.a);
		envTbl[dbColor.baseTag] = color;
		envTbl[dbColor.baseTag.."_CODE"] = color:GenerateHexColorMarkup();
	end
end