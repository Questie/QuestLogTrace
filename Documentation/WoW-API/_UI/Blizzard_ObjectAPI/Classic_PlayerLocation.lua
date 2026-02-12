-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_ObjectAPI\Classic\PlayerLocation.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class PlayerLocation
PlayerLocation = {};
---@class PlayerLocationMixin
---[Documentation](https://warcraft.wiki.gg/wiki/PlayerLocationMixin)
PlayerLocationMixin = {};

---@param guid string
---@return PlayerLocationMixin
function PlayerLocation:CreateFromGUID(guid)
	local playerLocation = CreateFromMixins(PlayerLocationMixin);
	playerLocation:SetGUID(guid);
	return playerLocation;
end

---@param unit string
---@return PlayerLocationMixin
function PlayerLocation:CreateFromUnit(unit)
	local playerLocation = CreateFromMixins(PlayerLocationMixin);
	playerLocation:SetUnit(unit);
	return playerLocation;
end

---@param lineID number
---@return PlayerLocationMixin
function PlayerLocation:CreateFromChatLineID(lineID)
	local playerLocation = CreateFromMixins(PlayerLocationMixin);
	playerLocation:SetChatLineID(lineID);
	return playerLocation;
end

---@param clubID string
---@param streamID string
---@param epoch number
---@param position number
---@return PlayerLocationMixin
function PlayerLocation:CreateFromCommunityChatData(clubID, streamID, epoch, position)
	local playerLocation = CreateFromMixins(PlayerLocationMixin);
	playerLocation:SetCommunityData(clubID, streamID, epoch, position);
	return playerLocation;
end

---@param clubID string
---@param guid string
---@return PlayerLocationMixin
function PlayerLocation:CreateFromCommunityInvitation(clubID, guid)
	local playerLocation = CreateFromMixins(PlayerLocationMixin);
	playerLocation:SetCommunityInvitation(clubID, guid);
	return playerLocation;
end

---@param battlefieldScoreIndex number
---@return PlayerLocationMixin
function PlayerLocation:CreateFromBattlefieldScoreIndex(battlefieldScoreIndex)
	local playerLocation = CreateFromMixins(PlayerLocationMixin);
	playerLocation:SetBattlefieldScoreIndex(battlefieldScoreIndex);
	return playerLocation;
end

---@param memberID number
---@param channelID number
---@return PlayerLocationMixin
function PlayerLocation:CreateFromVoiceID(memberID, channelID)
	local playerLocation = CreateFromMixins(PlayerLocationMixin);
	playerLocation:SetVoiceID(memberID, channelID);
	return playerLocation;
end

---@param battleNetID number
---@return PlayerLocationMixin
function PlayerLocation:CreateFromBattleNetID(battleNetID)
	local playerLocation = CreateFromMixins(PlayerLocationMixin);
	playerLocation:SetBattleNetID(battleNetID);
	return playerLocation;
end

function PlayerLocation:CreateFromWhoIndex(whoIndex)
	local playerLocation = CreateFromMixins(PlayerLocationMixin);
	playerLocation:SetWhoIndex(whoIndex);
	return playerLocation;
end

--[[public api]]
--[[public api]]
---@param guid string
function PlayerLocationMixin:SetGUID(guid)
	self:ClearAndSetField("guid", guid);
end

---@return boolean
function PlayerLocationMixin:IsValid()
	if (self:IsCommunityData()) then
		return C_Club.CanResolvePlayerLocationFromClubMessageData(self.communityClubID, self.communityStreamID, self.communityEpoch, self.communityPosition);
	end

	return true;
end

---@return boolean
function PlayerLocationMixin:IsGUID()
	return self.guid ~= nil;
end

---@return boolean
function PlayerLocationMixin:IsBattleNetGUID()
	return self.guid and C_AccountInfo.IsGUIDBattleNetAccountType(self.guid);
end

---@return string
function PlayerLocationMixin:GetGUID()
	return self.guid or self.communityClubInviterGUID;
end

---@param unit string
function PlayerLocationMixin:SetUnit(unit)
	self:ClearAndSetField("unit", unit);
end

---@return boolean
function PlayerLocationMixin:IsUnit()
	return self.unit ~= nil;
end

---@return string
function PlayerLocationMixin:GetUnit()
	return self.unit;
end

---@param lineID number
function PlayerLocationMixin:SetChatLineID(lineID)
	self:ClearAndSetField("chatLineID", lineID);
end

---@return boolean
function PlayerLocationMixin:IsChatLineID()
	return self.chatLineID ~= nil;
end

---@return number
function PlayerLocationMixin:GetChatLineID()
	return self.chatLineID;
end

---@param index number
function PlayerLocationMixin:SetBattlefieldScoreIndex(index)
	self:ClearAndSetField("battlefieldScoreIndex", index);
end

---@return boolean
function PlayerLocationMixin:IsBattlefieldScoreIndex()
	return self.battlefieldScoreIndex ~= nil;
end

---@return number
function PlayerLocationMixin:GetBattlefieldScoreIndex()
	return self.battlefieldScoreIndex;
end

---@param memberID number
---@param channelID number
function PlayerLocationMixin:SetVoiceID(memberID, channelID)
	self:Clear();
	self.voiceMemberID = memberID;
	self.voiceChannelID = channelID;
end

---@return boolean
function PlayerLocationMixin:IsVoiceID()
	return self.voiceMemberID ~= nil and self.voiceChannelID ~= nil;
end

---@return number voiceMemberID
---@return number voiceChannelID
function PlayerLocationMixin:GetVoiceID()
	return self.voiceMemberID, self.voiceChannelID;
end

---@param battleNetID number
function PlayerLocationMixin:SetBattleNetID(battleNetID)
	self:Clear();
	self.battleNetID = battleNetID;
end

---@return boolean
function PlayerLocationMixin:IsBattleNetID()
	return self.battleNetID ~= nil;
end

---@return number
function PlayerLocationMixin:GetBattleNetID()
	return self.battleNetID;
end

function PlayerLocationMixin:SetWhoIndex(whoIndex)
	self:ClearAndSetField("whoIndex", whoIndex);
end

function PlayerLocationMixin:IsWhoIndex()
	return self.whoIndex ~= nil;
end

function PlayerLocationMixin:GetWhoIndex()
	return self.whoIndex;
end

---@param clubID string
---@param streamID string
---@param epoch number
---@param position number
function PlayerLocationMixin:SetCommunityData(clubID, streamID, epoch, position)
	self:Clear();
	self.communityClubID = clubID;
	self.communityStreamID = streamID;
	self.communityEpoch = epoch;
	self.communityPosition = position;
end

---@return boolean
function PlayerLocationMixin:IsCommunityData()
	return self.communityClubID ~= nil and self.communityStreamID ~= nil and self.communityEpoch ~= nil and self.communityPosition ~= nil;
end

---@param clubID string
---@param guid string
function PlayerLocationMixin:SetCommunityInvitation(clubID, guid)
	self:Clear();
	self.communityClubID = clubID;
	self.communityClubInviterGUID = guid;
end

---@return boolean
function PlayerLocationMixin:IsCommunityInvitation()
	return self.communityClubID ~= nil and self.communityClubInviterGUID ~= nil;
end

--[[private api]]
function PlayerLocationMixin:Clear()
	self.guid = nil;
	self.unit = nil;
	self.chatLineID = nil;
	self.battlefieldScoreIndex = nil;
	self.voiceMemberID = nil;
	self.voiceChannelID = nil;
	self.communityClubID = nil;
	self.communityStreamID = nil;
	self.communityEpoch = nil;
	self.communityPosition = nil;
	self.communityClubInviterGUID = nil;
	self.battleNetID = nil;
end

---@param fieldName string
---@param field any
function PlayerLocationMixin:ClearAndSetField(fieldName, field)
	self:Clear();
	self[fieldName] = field;
end