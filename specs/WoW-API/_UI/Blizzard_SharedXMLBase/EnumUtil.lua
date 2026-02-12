-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedXMLBase\EnumUtil.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class EnumUtil
EnumUtil = {};

function EnumUtil.MakeEnum(...)
	return tInvert({...});
end

function EnumUtil.IsValid(enumClass, enumValue)
	return tContains(enumClass, enumValue);
end

function EnumUtil.GenerateNameTranslation(enum)
	return function (enumValue)
		for key, value in pairs(enum) do
			if value == enumValue then
				return key;
			end
		end

		return UNKNOWN..enumValue;
	end
end
