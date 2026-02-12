---@meta _

-- ! These should be deprecated, but they work a bit differently in different versions of WoW.
-- ! So we let them throw warnings for now.
-- ---@deprecated
-- ---[Documentation](https://warcraft.wiki.gg/wiki/API_GetNumActiveQuests)<br>
-- --- Replaced by [C_GossipInfo.GetNumActiveQuests](https://warcraft.wiki.gg/wiki/API_C_GossipInfo.GetNumActiveQuests)
-- ---@return number numQuests
-- function GetNumActiveQuests() end

-- ---@deprecated
-- ---[Documentation](https://warcraft.wiki.gg/wiki/API_GetNumAvailableQuests)<br>
-- --- Replaced by [C_GossipInfo.GetNumAvailableQuests](https://warcraft.wiki.gg/wiki/API_C_GossipInfo.GetNumAvailableQuests)
-- ---@return number numQuests
-- function GetNumAvailableQuests() end

---@deprecated
---[Documentation](https://warcraft.wiki.gg/wiki/API_IsQuestFlaggedCompleted)<br>
--- Replaced by [C_QuestLog.IsQuestFlaggedCompleted](https://warcraft.wiki.gg/wiki/API_C_QuestLog.IsQuestFlaggedCompleted)
---@param questID number
---@return boolean completed
function IsQuestFlaggedCompleted(questID) end

---@deprecated
---[Documentation](https://warcraft.wiki.gg/wiki/API_GetAbandonQuestItems)<br>
--- Replaced by [C_QuestLog.GetAbandonQuestItems](https://warcraft.wiki.gg/wiki/API_C_QuestLog.GetAbandonQuestItems)
---@return number[] itemIDs
function GetAbandonQuestItems() end