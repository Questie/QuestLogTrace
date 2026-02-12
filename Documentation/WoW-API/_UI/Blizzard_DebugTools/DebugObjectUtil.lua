-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_DebugTools\DebugObjectUtil.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- This file is executed at the end of addon load
function CanAccessObject(obj)
	return issecure() or not obj:IsForbidden();
end
