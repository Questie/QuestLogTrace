-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_UnitPopupShared\UnitPopupSharedMenus.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

local PROJECT_IMPL_REQUIRED = "Add implementation in UnitPopupUtils.lua";

---@class UnitPopupTopLevelMenuMixin
UnitPopupTopLevelMenuMixin = { };

--[[
Inline menus' children are inserted into their parent. Inline menus can be used
to encapsulate a section of options and reuse that section in different menus.
- A
- B (inline menu)
  - W
  - X
- C

Will become:
- A
- W
- X
- C
]]--
function UnitPopupTopLevelMenuMixin:IsInlineMenu()
	return true; 
end 

function UnitPopupTopLevelMenuMixin:AssembleMenuEntries(contextData)
	local entries = {};
	local topLevelEntries = self:GetEntries();
	if topLevelEntries then
		for index, buttonMixin in ipairs(self:GetEntries()) do 
			if buttonMixin:IsInlineMenu() then 
				local mixinEntries = buttonMixin:GetEntries();
				if mixinEntries then
					tAppendAll(entries, buttonMixin:GetEntries());
				end
			else 
				table.insert(entries, buttonMixin);
			end
		end
	end
	return entries;
end

-- Submenus
---@class UnitPopupMenuFriendlyPlayer : UnitPopupTopLevelMenuMixin
UnitPopupMenuFriendlyPlayer = CreateFromMixins(UnitPopupTopLevelMenuMixin);
function UnitPopupMenuFriendlyPlayer:GetEntries()
	return {
		UnitPopupRaidTargetButtonMixin, 
		UnitPopupSetFocusButtonMixin,
		UnitPopupAddFriendButtonMixin,
		UnitPopupAddFriendMenuButtonMixin,
		UnitPopupInteractSubsectionTitle,
	}
end 

---@class UnitPopupMenuFriendlyPlayerInteract : UnitPopupTopLevelMenuMixin
UnitPopupMenuFriendlyPlayerInteract = CreateFromMixins(UnitPopupTopLevelMenuMixin);
function UnitPopupMenuFriendlyPlayerInteract:GetEntries()
	return {
		UnitPopupWhisperButtonMixin,
		UnitPopupInspectButtonMixin, 
		UnitPopupAchievementButtonMixin,
		UnitPopupTradeButtonMixin, 
		UnitPopupFollowButtonMixin,
		UnitPopupDuelButtonMixin,
		UnitPopupPetBattleDuelButtonMixin,
	}
end 

---@class UnitPopupMenuFriendlyPlayerInviteOptions : UnitPopupTopLevelMenuMixin
UnitPopupMenuFriendlyPlayerInviteOptions = CreateFromMixins(UnitPopupTopLevelMenuMixin)
function UnitPopupMenuFriendlyPlayerInviteOptions:GetEntries()
	return {
		UnitPopupInviteButtonMixin,
		UnitPopupSuggestInviteButtonMixin,
		UnitPopupRequestInviteButtonMixin,
	}
end

-- Root menus
---@class UnitPopupMenuSelf : UnitPopupTopLevelMenuMixin
UnitPopupMenuSelf = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("SELF", UnitPopupMenuSelf);
function UnitPopupMenuSelf:GetEntries()
end

---@class UnitPopupMenuPet : UnitPopupTopLevelMenuMixin
UnitPopupMenuPet = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("PET", UnitPopupMenuPet);
function UnitPopupMenuPet:GetEntries()
	return { 
		UnitPopupRaidTargetButtonMixin, 
		UnitPopupSetFocusButtonMixin, 
		UnitPopupInteractSubsectionTitle,
		UnitPopupPetRenameButtonMixin,
		UnitPopupPetDismissButtonMixin,
		UnitPopupPetAbandonButtonMixin,
		UnitPopupOtherSubsectionTitle,
		UnitPopupMovePlayerFrameButtonMixin,
		UnitPopupMoveTargetFrameButtonMixin,
		UnitPopupEnterEditModeMixin,
	}
end

---@class UnitPopupMenuOtherPet : UnitPopupTopLevelMenuMixin
UnitPopupMenuOtherPet = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("OTHERPET", UnitPopupMenuOtherPet);
function UnitPopupMenuOtherPet:GetEntries()
	return { 
		UnitPopupRaidTargetButtonMixin,
		UnitPopupSetFocusButtonMixin, 
		UnitPopupOtherSubsectionTitle,
		UnitPopupMovePlayerFrameButtonMixin,
		UnitPopupMoveTargetFrameButtonMixin,
		UnitPopupEnterEditModeMixin,
		UnitPopupReportPetButtonMixin,
	}
end 

---@class UnitPopupMenuBattlePet : UnitPopupTopLevelMenuMixin
UnitPopupMenuBattlePet = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("BATTLEPET", UnitPopupMenuBattlePet);
function UnitPopupMenuBattlePet:GetEntries()
	return { 
		UnitPopupPetShowInJournalButtonMixin, 
		UnitPopupSetFocusButtonMixin, 
		UnitPopupOtherSubsectionTitle,
		UnitPopupMovePlayerFrameButtonMixin,
		UnitPopupMoveTargetFrameButtonMixin,
		UnitPopupEnterEditModeMixin,
	}
end 

---@class UnitPopupMenuOtherBattlePet : UnitPopupTopLevelMenuMixin
UnitPopupMenuOtherBattlePet = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("OTHERBATTLEPET", UnitPopupMenuOtherBattlePet);
function UnitPopupMenuOtherBattlePet:GetEntries()
	return { 
		UnitPopupPetShowInJournalButtonMixin, 
		UnitPopupSetFocusButtonMixin, 
		UnitPopupOtherSubsectionTitle,
		UnitPopupMovePlayerFrameButtonMixin,
		UnitPopupMoveTargetFrameButtonMixin,
		UnitPopupEnterEditModeMixin,
		UnitPopupReportBattlePetButtonMixin,
	}
end 

---@class UnitPopupMenuParty : UnitPopupTopLevelMenuMixin
UnitPopupMenuParty = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("PARTY", UnitPopupMenuParty);
function UnitPopupMenuParty:GetEntries()
	error(PROJECT_IMPL_REQUIRED);
end

---@class UnitPopupMenuPlayer : UnitPopupTopLevelMenuMixin
UnitPopupMenuPlayer = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("PLAYER", UnitPopupMenuPlayer);
function UnitPopupMenuPlayer:GetEntries()
	return {
		UnitPopupMenuFriendlyPlayer, -- Submenu
		UnitPopupRafSummonButtonMixin,
		UnitPopupRafGrantLevelButtonMixin,
		UnitPopupMenuFriendlyPlayerInviteOptions, -- Submenu
		UnitPopupMenuFriendlyPlayerInteract, -- Submenu
		UnitPopupOtherSubsectionTitle,
		UnitPopupVoiceChatButtonMixin, 
		UnitPopupMovePlayerFrameButtonMixin,
		UnitPopupMoveTargetFrameButtonMixin,
		UnitPopupEnterEditModeMixin,
		UnitPopupReportInWorldButtonMixin,
		UnitPopupCopyCharacterNameButtonMixin,
	}
end

---@class UnitPopupMenuEnemyPlayer : UnitPopupTopLevelMenuMixin
UnitPopupMenuEnemyPlayer = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("ENEMY_PLAYER", UnitPopupMenuEnemyPlayer);
function UnitPopupMenuEnemyPlayer:GetEntries()
	error(PROJECT_IMPL_REQUIRED);
end

---@class UnitPopupMenuRaidPlayer : UnitPopupTopLevelMenuMixin
UnitPopupMenuRaidPlayer = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("RAID_PLAYER", UnitPopupMenuRaidPlayer);
function UnitPopupMenuRaidPlayer:GetEntries()
	error(PROJECT_IMPL_REQUIRED);
end

---@class UnitPopupMenuRaid : UnitPopupTopLevelMenuMixin
UnitPopupMenuRaid = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("RAID", UnitPopupMenuRaid);
function UnitPopupMenuRaid:GetEntries()
	return {
		UnitPopupSetFocusButtonMixin, 
		UnitPopupInteractSubsectionTitle,
		UnitPopupSetRaidLeaderButtonMixin,
		UnitPopupSetRaidAssistButtonMixin, 
		UnitPopupSetRaidMainTankButtonMixin,
		UnitPopupSetRaidMainAssistButtonMixin,
		UnitPopupSetRaidDemoteButtonMixin,
		UnitPopupLootPromoteButtonMixin,
		UnitPopupOtherSubsectionTitle,
		UnitPopupVoiceChatButtonMixin, 
		UnitPopupMovePlayerFrameButtonMixin,
		UnitPopupMoveTargetFrameButtonMixin,
		UnitPopupEnterEditModeMixin,
		UnitPopupReportGroupMemberButtonMixin,
		UnitPopupCopyCharacterNameButtonMixin,
		UnitPopupPvpReportAfkButtonMixin,
		UnitPopupVoteToKickButtonMixin,
		UnitPopupSetRaidRemoveButtonMixin,
	}
end

---@class UnitPopupMenuFriend : UnitPopupTopLevelMenuMixin
UnitPopupMenuFriend = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("FRIEND", UnitPopupMenuFriend);
function UnitPopupMenuFriend:GetEntries()
	return { 
		UnitPopupPopoutChatButtonMixin,
		UnitPopupTargetButtonMixin,
		UnitPopupSetNoteButtonMixin, 
		UnitPopupInteractSubsectionTitle,
		UnitPopupRafSummonButtonMixin,
		UnitPopupMenuFriendlyPlayerInviteOptions, --SubMenu
		UnitPopupWhisperButtonMixin,
		UnitPopupOtherSubsectionTitle,
		UnitPopupDeleteCommunityMessageButtonMixin,
		UnitPopupIgnoreButtonMixin,
		UnitPopupRemoveFriendButtonMixin,
		UnitPopupReportFriendButtonMixin,
		UnitPopupReportChatButtonMixin,
		UnitPopupCopyCharacterNameButtonMixin,
		UnitPopupPvpReportAfkButtonMixin,
	}
end 

---@class UnitPopupMenuFriendOffline : UnitPopupTopLevelMenuMixin
UnitPopupMenuFriendOffline = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("FRIEND_OFFLINE", UnitPopupMenuFriendOffline);
function UnitPopupMenuFriendOffline:GetEntries()
	return { 
		UnitPopupSetNoteButtonMixin, 
		UnitPopupOtherSubsectionTitle,
		UnitPopupIgnoreButtonMixin,
		UnitPopupRemoveFriendButtonMixin,
		UnitPopupCopyCharacterNameButtonMixin,
	}
end  

---@class UnitPopupMenuBnFriend : UnitPopupTopLevelMenuMixin
UnitPopupMenuBnFriend = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("BN_FRIEND", UnitPopupMenuBnFriend);
function UnitPopupMenuBnFriend:GetEntries()
	return nil;
end 

---@class UnitPopupMenuBnFriendOffline : UnitPopupTopLevelMenuMixin
UnitPopupMenuBnFriendOffline = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("BN_FRIEND_OFFLINE", UnitPopupMenuBnFriendOffline);
function UnitPopupMenuBnFriendOffline:GetEntries()
	return nil;
end

---@class UnitPopupMenuGlueFriend : UnitPopupTopLevelMenuMixin
UnitPopupMenuGlueFriend = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("GLUE_FRIEND", UnitPopupMenuGlueFriend);
function UnitPopupMenuGlueFriend:GetEntries()
	return {
		UnitPopupGlueInviteButtonMixin,
		UnitPopupRemoveBnetFriendButtonMixin,
		UnitPopupBnetBlockButtonMixin,
		UnitPopupGlueReportButtonMixin,
	}
end 

---@class UnitPopupMenuGlueFriendOffline : UnitPopupTopLevelMenuMixin
UnitPopupMenuGlueFriendOffline = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("GLUE_FRIEND_OFFLINE", UnitPopupMenuGlueFriendOffline);
function UnitPopupMenuGlueFriendOffline:GetEntries()
	return {
		UnitPopupRemoveBnetFriendButtonMixin,
		UnitPopupBnetBlockButtonMixin,
		UnitPopupGlueReportButtonMixin,
	}
end

---@class UnitPopupMenuGuild : UnitPopupTopLevelMenuMixin
UnitPopupMenuGuild = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("GUILD", UnitPopupMenuGuild);
function UnitPopupMenuGuild:GetEntries()
	return { 
		UnitPopupTargetButtonMixin, 
		UnitPopupAddGuildBtagFriendButtonMixin,
		UnitPopupInteractSubsectionTitle,
		UnitPopupMenuFriendlyPlayerInviteOptions, --submenu
		UnitPopupWhisperButtonMixin,
		UnitPopupGuildPromoteButtonMixin,
		UnitPopupOtherSubsectionTitle,
		UnitPopupVoiceChatButtonMixin,
		UnitPopupIgnoreButtonMixin,
		UnitPopupCopyCharacterNameButtonMixin,
		UnitPopupGuildLeaveButtonMixin,
	}
end 

---@class UnitPopupMenuGuildOffline : UnitPopupTopLevelMenuMixin
UnitPopupMenuGuildOffline = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("GUILD_OFFLINE", UnitPopupMenuGuildOffline);
function UnitPopupMenuGuildOffline:GetEntries()
	return { 
		UnitPopupAddGuildBtagFriendButtonMixin,
		UnitPopupInteractSubsectionTitle,
		UnitPopupGuildPromoteButtonMixin,
		UnitPopupOtherSubsectionTitle,
		UnitPopupIgnoreButtonMixin,
		UnitPopupCopyCharacterNameButtonMixin,
		UnitPopupGuildLeaveButtonMixin,
	}
end

---@class UnitPopupMenuChatRoster : UnitPopupTopLevelMenuMixin
UnitPopupMenuChatRoster = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("CHAT_ROSTER", UnitPopupMenuChatRoster);
function UnitPopupMenuChatRoster:GetEntries()
	return {
		UnitPopupVoiceChatMicrophoneVolumeButtonMixin, 
		UnitPopupVoiceChatSpeakerVolumeButtonMixin,
		UnitPopupVoiceChatUserVolumeButtonMixin,
		UnitPopupSubsectionSeperatorMixin,
		UnitPopupInteractSubsectionTitle,
		UnitPopupTargetButtonMixin,
		UnitPopupWhisperButtonMixin,
		UnitPopupChatOwnerButtonMixin,
		UnitPopupChatPromoteButtonMixin,
		UnitPopupChatDemoteButtonMixin,
		UnitPopupSubsectionSeperatorMixin,
		UnitPopupOtherSubsectionTitle, 
		UnitPopupReportChatButtonMixin,
		UnitPopupCopyCharacterNameButtonMixin,
		UnitPopupVoiceChatSettingsButtonMixin,
	}
end

---@class UnitPopupMenuVehicle : UnitPopupTopLevelMenuMixin
UnitPopupMenuVehicle = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("VEHICLE", UnitPopupMenuVehicle);
function UnitPopupMenuVehicle:GetEntries()
	return {
		UnitPopupRaidTargetButtonMixin, 
		UnitPopupSetFocusButtonMixin, 
		UnitPopupOtherSubsectionTitle, 
		UnitPopupVehicleLeaveButtonMixin,
		UnitPopupMovePlayerFrameButtonMixin,
		UnitPopupMoveTargetFrameButtonMixin,
		UnitPopupEnterEditModeMixin,
	}
end

---@class UnitPopupMenuTarget : UnitPopupTopLevelMenuMixin
UnitPopupMenuTarget = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("TARGET", UnitPopupMenuTarget);
function UnitPopupMenuTarget:GetEntries()
	return {
		UnitPopupRaidTargetButtonMixin, 
		UnitPopupSetFocusButtonMixin, 
		UnitPopupAddFriendButtonMixin, 
		UnitPopupAddFriendMenuButtonMixin,
		UnitPopupOtherSubsectionTitle, 
		UnitPopupVoiceChatButtonMixin,
		UnitPopupMovePlayerFrameButtonMixin,
		UnitPopupMoveTargetFrameButtonMixin,
		UnitPopupEnterEditModeMixin,
	}
end

---@class UnitPopupMenuArenaEnemy : UnitPopupTopLevelMenuMixin
UnitPopupMenuArenaEnemy = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("ARENAENEMY", UnitPopupMenuArenaEnemy);
function UnitPopupMenuArenaEnemy:GetEntries()
	return {
		UnitPopupSetFocusButtonMixin, 
		UnitPopupOtherSubsectionTitle, 
	}
end

---@class UnitPopupMenuFocus : UnitPopupTopLevelMenuMixin
UnitPopupMenuFocus = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("FOCUS", UnitPopupMenuFocus);
function UnitPopupMenuFocus:GetEntries()
	return {
		UnitPopupRaidTargetButtonMixin,
		UnitPopupClearFocusButtonMixin,
		UnitPopupOtherSubsectionTitle,
		UnitPopupVoiceChatButtonMixin,
		UnitPopupLargeFocusButtonMixin,
		UnitPopupMoveFocusButtonMixin,
		UnitPopupEnterEditModeMixin,
	}
end

---@class UnitPopupMenuBoss : UnitPopupTopLevelMenuMixin
UnitPopupMenuBoss = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("BOSS", UnitPopupMenuBoss);
function UnitPopupMenuBoss:GetEntries()
	return {
		UnitPopupRaidTargetButtonMixin,
		UnitPopupSetFocusButtonMixin,
		UnitPopupOtherSubsectionTitle,
		UnitPopupEnterEditModeMixin,
	}
end

---@class UnitPopupMenuCommunitiesWowMember : UnitPopupTopLevelMenuMixin
UnitPopupMenuCommunitiesWowMember = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("COMMUNITIES_WOW_MEMBER", UnitPopupMenuCommunitiesWowMember);
function UnitPopupMenuCommunitiesWowMember:GetEntries()
	error(PROJECT_IMPL_REQUIRED);
end

---@class UnitPopupMenuCommunitiesGuildMember : UnitPopupTopLevelMenuMixin
UnitPopupMenuCommunitiesGuildMember = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("COMMUNITIES_GUILD_MEMBER", UnitPopupMenuCommunitiesGuildMember);
function UnitPopupMenuCommunitiesGuildMember:GetEntries()
	error(PROJECT_IMPL_REQUIRED);
end

---@class UnitPopupGuildGuilds : UnitPopupTopLevelMenuMixin
UnitPopupGuildGuilds = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("GUILDS_GUILD", UnitPopupGuildGuilds);
function UnitPopupGuildGuilds:GetEntries()
	return {
		UnitPopupClearCommunityNotificationButtonMixin,
		UnitPopupGuildInviteButtonMixin, 
		UnitPopupGuildSettingButtonMixin, 
		UnitPopupGuildRecruitmentSettingButtonMixin, 
		UnitPopupCommunityNotificationButtonMixin,
		UnitPopupGuildGuildsLeaveButtonMixin,
	}
end

---@class UnitPopupMenuCommunitiesMember : UnitPopupTopLevelMenuMixin
UnitPopupMenuCommunitiesMember = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("COMMUNITIES_MEMBER", UnitPopupMenuCommunitiesMember);
function UnitPopupMenuCommunitiesMember:GetEntries()
	return {
		UnitPopupCommunitiesBtagFriendButtonMixin,
		UnitPopupSubsectionSeperatorMixin, 
		UnitPopupVoiceChatMicrophoneVolumeButtonMixin, 
		UnitPopupVoiceChatSpeakerVolumeButtonMixin,
		UnitPopupVoiceChatUserVolumeButtonMixin,
		UnitPopupSubsectionSeperatorMixin, 
		UnitPopupInteractSubsectionTitle,
		UnitPopupCommunitiesLeaveButtonMixin,
		UnitPopupCommunitiesKickFriendButtonMixin,
		UnitPopupCommunitiesMemberNoteButtonMixin,
		UnitPopupCommunitiesRoleButtonMixin,
		UnitPopupOtherSubsectionTitle,
		UnitPopupReportClubMemberButtonMixin,
	}
end

---@class UnitPopupMenuCommunitiesCommunity : UnitPopupTopLevelMenuMixin
UnitPopupMenuCommunitiesCommunity = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("COMMUNITIES_COMMUNITY", UnitPopupMenuCommunitiesCommunity);
function UnitPopupMenuCommunitiesCommunity:GetEntries()
	return {
		UnitPopupClearCommunityNotificationButtonMixin,
		UnitPopupCommunityInviteButtonMixin, 
		UnitPopupCommunitiesSettingButtonMixin, 
		UnitPopupCommunityNotificationButtonMixin, 
		UnitPopupCommunitiesFavoriteButtonMixin,
		UnitPopupCommunitiesLeaveButtonMixin,
	}
end

---@class UnitPopupMenuRaidTargetIcon : UnitPopupTopLevelMenuMixin
UnitPopupMenuRaidTargetIcon = CreateFromMixins(UnitPopupTopLevelMenuMixin);
UnitPopupManager:RegisterMenu("RAID_TARGET_ICON", UnitPopupMenuRaidTargetIcon);
function UnitPopupMenuRaidTargetIcon:GetEntries()
	return { 
		UnitPopupRaidTargetButtonMixin,
	}
end

---@class UnitPopupMenuWorldStateScore : UnitPopupTopLevelMenuMixin
UnitPopupMenuWorldStateScore = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("WORLD_STATE_SCORE", UnitPopupMenuWorldStateScore);
function UnitPopupMenuWorldStateScore:GetEntries()
	return {
		UnitPopupReportPvpScoreboardButtonMixin, 
	}
end

---@class UnitPopupMenuPvpScoreboard : UnitPopupTopLevelMenuMixin
UnitPopupMenuPvpScoreboard = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("PVP_SCOREBOARD", UnitPopupMenuPvpScoreboard);
function UnitPopupMenuPvpScoreboard:GetEntries()
	return {
		UnitPopupReportPvpScoreboardButtonMixin,
	}
end

---@class UnitPopupMenuGluePartyMember : UnitPopupTopLevelMenuMixin
UnitPopupMenuGluePartyMember = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("GLUE_PARTY_MEMBER", UnitPopupMenuGluePartyMember);
function UnitPopupMenuGluePartyMember:GetEntries()
	return {
		UnitPopupGlueLeavePartyButton,
		UnitPopupGlueRemovePartyButton, 
	}
end

---@class UnitPopupMenuRecentAlly : UnitPopupTopLevelMenuMixin
UnitPopupMenuRecentAlly = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("RECENT_ALLY", UnitPopupMenuRecentAlly);
function UnitPopupMenuRecentAlly:GetEntries()
	return {
		UnitPopupAddRecentAllyBattleTagFriendButtonMixin,
		UnitPopupTargetButtonMixin,
		UnitPopupRecentAllyNoteButtonMixin,
		UnitPopupInteractSubsectionTitle,
		UnitPopupWhisperButtonMixin,
		UnitPopupInviteButtonMixin,
		UnitPopupOtherSubsectionTitle,
		UnitPopupRecentAllyPinButtonMixin,
		UnitPopupIgnoreButtonMixin,
		UnitPopupReportRecentAllyButtonMixin,
		UnitPopupCopyCharacterNameButtonMixin,
	}
end

---@class UnitPopupMenuRecentAllyOffline : UnitPopupTopLevelMenuMixin
UnitPopupMenuRecentAllyOffline = CreateFromMixins(UnitPopupTopLevelMenuMixin)
UnitPopupManager:RegisterMenu("RECENT_ALLY_OFFLINE", UnitPopupMenuRecentAllyOffline);
function UnitPopupMenuRecentAllyOffline:GetEntries()
	return { 
		UnitPopupRecentAllyNoteButtonMixin, 
		UnitPopupOtherSubsectionTitle,
		UnitPopupRecentAllyPinButtonMixin,
		UnitPopupIgnoreButtonMixin,
		UnitPopupCopyCharacterNameButtonMixin,
	}
end  
