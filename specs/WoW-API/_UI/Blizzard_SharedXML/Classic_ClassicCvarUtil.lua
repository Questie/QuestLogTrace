-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedXML\Classic\ClassicCvarUtil.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

--Overrides the shared CvarUtil.lua SetCvar function. 10.0 refactor removed 'eventName' and other associated code on Mainline. Until Classic
--brings over those changes, we want the 'eventName' passed along in this function.
---[Documentation](https://warcraft.wiki.gg/wiki/API_C_CVar.SetCVar)
---@param name CVar
---@param value? boolean|string|number
---@return boolean success
function SetCVar(name, value, eventName)
	if type(value) == "boolean" then
		return C_CVar.SetCVar(name, value and "1" or "0", eventName);
	else
		return C_CVar.SetCVar(name, value and tostring(value) or nil, eventName);
	end
end