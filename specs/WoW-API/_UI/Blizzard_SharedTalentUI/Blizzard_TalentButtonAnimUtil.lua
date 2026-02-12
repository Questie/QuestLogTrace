-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedTalentUI\Blizzard_TalentButtonAnimUtil.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class TalentButtonAnimUtil
TalentButtonAnimUtil = {};

TalentButtonAnimUtil.TalentButtonAnimState = {
	None = 0,
	Increased = 1,
	Infinite = 2,
};

function TalentButtonAnimUtil.TalentButtonAnimationReset(pool, anim, isNew)
	if isNew then
		return;
	end
	
	anim:ResetAnim();
end
