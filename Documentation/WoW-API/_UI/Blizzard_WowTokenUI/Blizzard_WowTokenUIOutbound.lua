-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_WowTokenUI\Blizzard_WowTokenUIOutbound.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- Outbound loads under the global environment but needs to put the outbound table into the secure environment
local secureEnv = GetCurrentEnvironment();
SwapToGlobalEnvironment();
---@class WowTokenOutbound
local WowTokenOutbound = {};
secureEnv.WowTokenOutbound = WowTokenOutbound;
secureEnv = nil;	--This file shouldn't be calling back into secure code.

function WowTokenOutbound.RedeemFailed(result)
	securecall("RedeemFailed", result);
end

function WowTokenOutbound.AuctionWowTokenUpdate()
	securecall("AuctionWowToken_UpdateMarketPrice");
end

function WowTokenOutbound.RecruitAFriendTryPlayClaimRewardFanfare()
	securecall("RecruitAFriend_TryPlayClaimRewardFanfare");
end

function WowTokenOutbound.RecruitAFriendTryCancelAutoClaim()
	securecall("RecruitAFriend_TryCancelAutoClaim");
end