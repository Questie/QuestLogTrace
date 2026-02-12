-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedXML\StringUtil.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

function ConfirmationStringMatches(userInput, expectedText)
	return strupper(userInput) == strupper(expectedText);
end

function ConfirmationEditBoxMatches(editBox, expectedText)
	return ConfirmationStringMatches(editBox:GetText(), expectedText);
end

function UserInputNonEmpty(userInput)
	return strtrim(userInput) ~= "";
end

function UserEditBoxNonEmpty(editBox)
	return UserInputNonEmpty(editBox:GetText());
end

function StringSplitIntoTable(sep, string)
	return { strsplit(sep, string) };
end