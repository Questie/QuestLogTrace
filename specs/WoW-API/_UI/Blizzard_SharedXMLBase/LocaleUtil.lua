-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedXMLBase\LocaleUtil.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class LocaleUtil
LocaleUtil = {};

function LocaleUtil.GetLanguageAtlas(localeName)
	return string.format("Lang-Regions-%s", localeName);
end

function LocaleUtil.GetLanguageRestartAtlas(localeName)
	return string.format("lang-alert-%s", localeName);
end