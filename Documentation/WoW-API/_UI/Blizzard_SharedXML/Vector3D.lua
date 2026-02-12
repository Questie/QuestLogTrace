-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedXML\Vector3D.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- Protecting from addons since we use this in secure code.
local cos = math.cos;
local sin = math.sin;
local atan2 = math.atan2;
local asin = math.asin;
local sqrt = math.sqrt;

function Vector3D_ScaleBy(scalar, x, y, z)
	return x * scalar, y * scalar, z * scalar;
end

function Vector3D_DivideBy(divisor, x, y, z)
	return x / divisor, y / divisor, z / divisor;
end

function Vector3D_Add(leftX, leftY, leftZ, rightX, rightY, rightZ)
	return leftX + rightX, leftY + rightY, leftZ + rightZ;
end

function Vector3D_Subtract(leftX, leftY, leftZ, rightX, rightY, rightZ)
	return leftX - rightX, leftY - rightY, leftZ - rightZ;
end

function Vector3D_Cross(leftX, leftY, leftZ, rightX, rightY, rightZ)
	return leftY * rightZ - leftZ * rightY, leftZ * rightX - leftX * rightZ, leftX * rightY - leftY * rightX;
end

function Vector3D_Dot(leftX, leftY, leftZ, rightX, rightY, rightZ)
	return leftX * rightX + leftY * rightY + leftZ * rightZ;
end

function Vector3D_GetLengthSquared(x, y, z)
	return Vector3D_Dot(x, y, z, x, y, z);
end

function Vector3D_GetLength(x, y, z)
	return sqrt(Vector3D_GetLengthSquared(x, y, z));
end

function Vector3D_Normalize(x, y, z)
	return Vector3D_DivideBy(Vector3D_GetLength(x, y, z), x, y, z);
end

function Vector3D_AddVector(left, right)
	local clone = left:Clone();
	clone:Add(right);
	return clone;
end

function Vector3D_SubtractVector(left, right)
	local clone = left:Clone();
	clone:Subtract(right);
	return clone;
end

function Vector3D_NormalizeVector(vector)
	local clone = vector:Clone();
	clone:Normalize();
	return clone;
end

function Vector3D_ScaleVector(scalar, vector)
	local clone = vector:Clone();
	clone:ScaleBy(scalar);
	return clone;
end

function Vector3D_CalculateNormalFromYawPitch(yaw, pitch)
	return	cos(-pitch) * cos(yaw),
			cos(-pitch) * sin(yaw),
			sin(-pitch);
end

function Vector3D_CalculateYawPitchFromNormal(x, y, z)
	if x ~= 0 or y ~= 0 then
		return atan2(y, x), asin(-z);
	end

	return 0, asin(-z);
end

function Vector3D_CalculateYawPitchFromNormalVector(vector)
	return Vector3D_CalculateYawPitchFromNormal(vector:GetXYZ());
end


function Vector3D_CreateNormalVectorFromYawPitch(yawRadians, pitchRadians)
	return CreateVector3D(Vector3D_CalculateNormalFromYawPitch(yawRadians, pitchRadians));
end

---@class Vector3DMixin
---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin)
Vector3DMixin = {};

---[FrameXML](https://www.townlong-yak.com/framexml/go/CreateVector3D)
---@param x number
---@param y number
---@param z number
---@return Vector3DMixin
function CreateVector3D(x, y, z)
	local vector = CreateFromMixins(Vector3DMixin);
	vector:OnLoad(x, y, z);
	return vector;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/AreVector3DEqual)
---@param left Vector3DMixin
---@param right Vector3DMixin
---@return boolean
function AreVector3DEqual(left, right)
	if left and right then
		return left:IsEqualTo(right);
	end
	return left == right;
end

function Vector3DMixin:OnLoad(x, y, z)
	self:SetXYZ(x, y, z);
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:IsEqualTo)
---@param otherVector Vector3DMixin
---@return boolean
function Vector3DMixin:IsEqualTo(otherVector)
	return self.x == otherVector.x
	   and self.y == otherVector.y
	   and self.z == otherVector.z;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:GetXYZ)
---@return number x
---@return number y
---@return number z
function Vector3DMixin:GetXYZ()
	return self.x, self.y, self.z;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:SetXYZ)
---@param x number
---@param y number
---@param z number
function Vector3DMixin:SetXYZ(x, y, z)
	self.x = x;
	self.y = y;
	self.z = z;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:ScaleBy)
---@param scalar number
function Vector3DMixin:ScaleBy(scalar)
	self:SetXYZ(Vector3D_ScaleBy(scalar, self:GetXYZ()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:DivideBy)
---@param scalar number
function Vector3DMixin:DivideBy(scalar)
	self:SetXYZ(Vector3D_DivideBy(scalar, self:GetXYZ()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:Add)
---@param other Vector3DMixin
function Vector3DMixin:Add(other)
	self:SetXYZ(Vector3D_Add(self.x, self.y, self.z, other:GetXYZ()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:Subtract)
---@param other Vector3DMixin
function Vector3DMixin:Subtract(other)
	self:SetXYZ(Vector3D_Subtract(self.x, self.y, self.z, other:GetXYZ()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:Cross)
---@param other Vector3DMixin
function Vector3DMixin:Cross(other)
	self:SetXYZ(Vector3D_Cross(self.x, self.y, self.z, other:GetXYZ()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:Dot)
---@param other Vector3DMixin
---@return number
function Vector3DMixin:Dot(other)
	return Vector3D_Dot(self.x, self.y, self.z, other:GetXYZ());
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:GetLengthSquared)
---@return number
function Vector3DMixin:GetLengthSquared()
	return Vector3D_GetLengthSquared(self:GetXYZ());
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:GetLength)
---@return number
function Vector3DMixin:GetLength()
	return Vector3D_GetLength(self:GetXYZ());
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:Normalize)
function Vector3DMixin:Normalize()
	self:SetXYZ(Vector3D_Normalize(self:GetXYZ()));
	return self;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/Vector3DMixin:Clone)
---@return Vector3DMixin
function Vector3DMixin:Clone()
	return CreateVector3D(self:GetXYZ());
end
