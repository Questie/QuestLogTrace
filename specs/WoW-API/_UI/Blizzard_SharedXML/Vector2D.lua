-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedXML\Vector2D.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- Protecting from addons since we use this in secure code.
local cos = math.cos;
local sin = math.sin;
local atan2 = math.atan2;
local sqrt = math.sqrt;

function Vector2D_ScaleBy(scalar, x, y)
	return x * scalar, y * scalar;
end

function Vector2D_DivideBy(divisor, x, y)
	return x / divisor, y / divisor;
end

function Vector2D_Add(leftX, leftY, rightX, rightY)
	return leftX + rightX, leftY + rightY;
end

function Vector2D_Subtract(leftX, leftY, rightX, rightY)
	return leftX - rightX, leftY - rightY;
end

function Vector2D_Cross(leftX, leftY, rightX, rightY)
	return leftX * rightY - leftY * rightX;
end

function Vector2D_Dot(leftX, leftY, rightX, rightY)
	return leftX * rightX + leftY * rightY;
end

function Vector2D_GetLengthSquared(x, y)
	return Vector2D_Dot(x, y, x, y);
end

function Vector2D_GetLength(x, y)
	return sqrt(Vector2D_GetLengthSquared(x, y));
end

function Vector2D_Normalize(x, y)
	return Vector2D_DivideBy(Vector2D_GetLength(x, y), x, y);
end

function Vector2D_CalculateAngleBetween(leftX, leftY, rightX, rightY)
	return atan2(Vector2D_Cross(leftX, leftY, rightX, rightY), Vector2D_Dot(leftX, leftY, rightX, rightY));
end

function Vector2D_RotateDirection(rotationRadians, x, y)
	local cosValue = cos(rotationRadians);
	local sinValue = sin(rotationRadians);
	return x * cosValue - y * sinValue, x * sinValue + y * cosValue;
end

---@class Vector2DMixin
---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin)
Vector2DMixin = {};

---[FrameXML](https://www.townlong-yak.com/framexml/go/CreateVector2D)
---@param x number
---@param y number
---@return Vector2DMixin
function CreateVector2D(x, y)
	local vector = CreateFromMixins(Vector2DMixin);
	vector:OnLoad(x, y);
	return vector;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/AreVector2DEqual)
---@param left Vector2DMixin
---@param right Vector2DMixin
---@return boolean
function AreVector2DEqual(left, right)
	if left and right then
		return left:IsEqualTo(right);
	end
	return left == right;
end

function Vector2DMixin:OnLoad(x, y)
	self:SetXY(x, y);
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:IsEqualTo)
---@param otherVector Vector2DMixin
---@return boolean
function Vector2DMixin:IsEqualTo(otherVector)
	return self.x == otherVector.x
	   and self.y == otherVector.y;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:GetXY)
---@return number x
---@return number y
function Vector2DMixin:GetXY()
	return self.x, self.y;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:SetXY)
---@param x number
---@param y number
function Vector2DMixin:SetXY(x, y)
	self.x = x;
	self.y = y;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:ScaleBy)
---@param scalar number
function Vector2DMixin:ScaleBy(scalar)
	self:SetXY(Vector2D_ScaleBy(scalar, self:GetXY()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:DivideBy)
---@param scalar number
function Vector2DMixin:DivideBy(scalar)
	self:SetXY(Vector2D_DivideBy(scalar, self:GetXY()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:Add)
---@param other Vector2DMixin
function Vector2DMixin:Add(other)
	self:SetXY(Vector2D_Add(self.x, self.y, other:GetXY()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:Subtract)
---@param other Vector2DMixin
function Vector2DMixin:Subtract(other)
	self:SetXY(Vector2D_Subtract(self.x, self.y, other:GetXY()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:Cross)
---@param other Vector2DMixin
function Vector2DMixin:Cross(other)
	self:SetXY(Vector2D_Cross(self.x, self.y, other:GetXY()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:Dot)
---@param other Vector2DMixin
---@return number
function Vector2DMixin:Dot(other)
	return Vector2D_Dot(self.x, self.y, other:GetXY());
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:IsZero)
---@return boolean
function Vector2DMixin:IsZero()
	return self.x == 0 and self.y == 0;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:GetLengthSquared)
---@return number
function Vector2DMixin:GetLengthSquared()
	return Vector2D_GetLengthSquared(self:GetXY());
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:GetLength)
---@return number
function Vector2DMixin:GetLength()
	return Vector2D_GetLength(self:GetXY());
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:Normalize)
function Vector2DMixin:Normalize()
	self:SetXY(Vector2D_Normalize(self:GetXY()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:RotateDirection)
---@param rotationRadians number
function Vector2DMixin:RotateDirection(rotationRadians)
	self:SetXY(Vector2D_RotateDirection(rotationRadians, self:GetXY()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector2DMixin:Clone)
---@return Vector2DMixin
function Vector2DMixin:Clone()
	return CreateVector2D(self:GetXY());
end