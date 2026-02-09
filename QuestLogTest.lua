---@class QuestLog
QuestLog = select(2, ...)

-- Dump all functions in the global namespace

---@type table<number, { timestamp: number, questIds: number[] }>
QuestLogHistory = {}
---@type table<number, table<number, QuestHistory>>
QuestHistory = {}

-- Register slash command
SlashCmdList["QUESTLOGTEST"] = function(arg1)
  print(arg1)
  print("questlogtest")
  local action, argument = strsplit(" ", arg1, 2)
  if action == "save" then
    -- This dumps a event log to a character saved variable
    print("QuestLogTest", QuestLogTest)
    QuestLogTest = QuestLogTest or {}
    QuestLogTest[argument] = {}
    QuestLogTest[argument].events = QLTrace.logDataProvider.collection
    QuestLogTest[argument].questHistory = QuestHistory
    QuestLogTest[argument].questLogHistory = QuestLogHistory

    print("QuestLogTestCharacter", QuestLogTestCharacter)
    QuestLogTestCharacter = {}
    QuestLogTestCharacter.events = QLTrace.logDataProvider.collection
    QuestLogTestCharacter.questHistory = QuestHistory
    QuestLogTestCharacter.questLogHistory = QuestLogHistory
  elseif action == "test" then
    if argument == "accepted" then
      RunAcceptedQuest()
    elseif argument == "complete" then
      RunCompleteQuest()
    end
  end
end

SLASH_QUESTLOGTEST1 = "/questlogtest"
SLASH_QUESTLOGTEST2 = "/qlt"

-- local timestamp = GetTime()

--- deepCompare compares two values recursively.<br>
--- If both values are tables, it compares all keys and values.
--- If they are not tables, it compares them directly.
--- It also handles circular references.
--- Parameters:<br>
---   t1, t2: the two values (or tables) to compare.<br>
---   ignore_mt (optional): if true, ignores metatable comparisons.<br>
---   visited (internal): used to keep track of already compared tables.<br>

--- Deep compare two values.
---@param t1 any
---@param t2 any
---@param ignore_mt boolean?
---@return boolean equal Returns true if the tables are equal, false otherwise.
function DeepCompare(t1, t2, ignore_mt, visited)
  -- If they are exactly the same object, they are equal.
  if t1 == t2 then return true end

  local type1, type2 = type(t1), type(t2)
  -- Different types can't be equal.
  if type1 ~= type2 then return false end

  -- For non-tables, do a direct comparison.
  if type1 ~= "table" then return t1 == t2 end

  -- Handle circular references.
  visited = visited or {}
  if visited[t1] and visited[t1] == t2 then return true end
  visited[t1] = t2

  -- Optionally compare metatables.
  if not ignore_mt then
    local mt1, mt2 = getmetatable(t1), getmetatable(t2)
    if mt1 or mt2 then
      if not DeepCompare(mt1, mt2, ignore_mt, visited) then
        return false
      end
    end
  end

  -- Check that every key-value pair in t1 exists and is equal in t2.
  for key, value in pairs(t1) do
    if key ~= "timestamp" then
      if t2[key] == nil or not DeepCompare(value, t2[key], ignore_mt, visited) then
        print("Key", key, "does not match", t2[key])
        return false
      end
    end
  end

  -- Also check that t2 does not have extra keys.
  for key in pairs(t2) do
    if key ~= "timestamp" then
      if t1[key] == nil then
        return false
      end
    end
  end

  return true
end

-- Example usage:
-- local table1 = { a = 1, b = { c = 2 } }
-- local table2 = { a = 1, b = { c = 2 } }
-- local table3 = { a = 1, b = { c = 3 } }

-- print(DeepCompare(table1, table2)) --> true  (they are the same)
-- print(DeepCompare(table1, table3)) --> false (there is a difference)

-- If you need a function that returns true when there is a difference,
-- you can simply write:
function TablesDiffer(t1, t2, ignore_mt)
  return not DeepCompare(t1, t2, ignore_mt)
end

-- print(TablesDiffer(table1, table3)) --> true (they differ)
local function GetQuestIdFromIndex(questLogIndex)
  local title, _, _, isHeader, _, _, _, questId = GetQuestLogTitle(questLogIndex)
  if not title then
    return nil
  end
  return questId
end


---Gets all quest IDs in the quest log
---@return number[] questIds
function GetAllQuestIdsInLog()
  ---@type number[]
  local questIds = {}
  for questLogIndex = 1, 75 do -- 3 * (Max possible number of quests in game quest log), won't effect performance
    local title, _, _, _, _, _, _, questId = GetQuestLogTitle(questLogIndex)

    if not title then
      return questIds -- We exceeded the data in the quest log
    end

    if questId and questId > 0 then -- QuestId can be 0 for headers
      questIds[#questIds + 1] = questId
    end
  end

  return questIds
end

-- Creates a history of a quests data
---@param questIds number[]
local function QuestDump(questIds)
  for qIndex = 1, #questIds do
    local questId = questIds[qIndex]

    -- Fetch data
    local QuestLogTitleData = { GetQuestLogTitle(GetQuestLogIndexByID(questId)) }
    local QuestObjectivesData = C_QuestLog.GetQuestObjectives(questId)
    local QuestTagInfoData = { GetQuestTagInfo(questId) }

    -- Check if quest is new
    if not QuestHistory[questId] then
      print("QuestLogTest", "Adding new quest to history", QuestLogTitleData[1], questId)
      QuestHistory[questId] = {}

      ---@class QuestHistory
      local questHistoryObject = {
        timestamp = GetTime(),
        id = questId,
        IsQuestComplete = IsQuestComplete(questId),
        IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted(questId),
        GetQuestLogTitle = QuestLogTitleData,
        GetQuestObjectives = QuestObjectivesData,
        QuestTagInfo = QuestTagInfoData
      }

      table.insert(QuestHistory[questId], questHistoryObject)
    else
      local lastIndex = #QuestHistory[questId]
      -- Diff
      local doObjectivesDiff = not DeepCompare(QuestObjectivesData, QuestHistory[questId][lastIndex].GetQuestObjectives)
      local doQuestTitleDiff = not DeepCompare(QuestLogTitleData, QuestHistory[questId][lastIndex].GetQuestLogTitle)
      local doQuestTagInfoDiff = not DeepCompare(QuestTagInfoData, QuestHistory[questId][lastIndex].QuestTagInfo)
      local doQuestCompleteDiff = IsQuestComplete(questId) ~= QuestHistory[questId][lastIndex].IsQuestComplete
      local doQuestFlaggedCompleteDiff = C_QuestLog.IsQuestFlaggedCompleted(questId) ~= QuestHistory[questId][lastIndex].IsQuestFlaggedCompleted
      if doObjectivesDiff or
          doQuestTitleDiff or
          doQuestTagInfoDiff or
          doQuestCompleteDiff or
          doQuestFlaggedCompleteDiff then
        if doQuestTitleDiff then
          print("QuestLogTest", "Title differs for quest", questId)
        end
        if doObjectivesDiff then
          print("QuestLogTest", "Objectives differ for quest", questId)
        end
        table.insert(QuestHistory[questId], {
          timestamp = GetTime(),
          id = questId,
          IsQuestComplete = IsQuestComplete(questId),
          IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted(questId),
          GetQuestLogTitle = QuestLogTitleData,
          GetQuestObjectives = QuestObjectivesData,
          QuestTagInfo = QuestTagInfoData
        })
      end
    end
  end
end

-- Create a history of the quest log
local function QuestLogDump()
  local questLog = { timestamp = GetTime(), questIds = GetAllQuestIdsInLog() }
  if not DeepCompare(questLog, QuestLogHistory) then
    print("QuestLogTest", "Quest log differs")
    QuestLogHistory[#QuestLogHistory + 1] = questLog
  end
end


local function OnEvent(self, event, ...)
  if event == "VARIABLES_LOADED" then
    C_After(1, QuestLogDump)
  elseif event == "QUEST_LOG_UPDATE" then
    print("QUEST_LOG_UPDATE")
    QuestDump(GetAllQuestIdsInLog())
  else
    print("Event", event)
    QuestLogDump()
    local allQuestIds = {}
    for questId in pairs(QuestHistory) do
      table.insert(allQuestIds, questId)
    end
    QuestDump(allQuestIds)
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_REMOVED")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("QUEST_WATCH_UPDATE")
frame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
-- frame:RegisterEvent("PLAYER_LEVEL_UP")
-- frame:RegisterEvent("MODIFIER_STATE_CHANGED")

frame:SetScript("OnEvent", OnEvent)

frame:SetScript("OnUpdate", function() QuestDump(GetAllQuestIdsInLog()) end)

-- C_After(0, function()
--   QLTrace:SetShown(not QLTrace:IsShown());
-- end)
-- QLTrace:Show()
local safePack = function(...) -- Copied from Blizzard Code
  local tbl = { ... };
  tbl.n = select("#", ...);
  return tbl;
end
SlashCmdList["QLTRACE"] = function()
  -- local elementData = {
  --   event = "a",
  --   args = safePack("1", "2", "3"),
  --   displayEvent = "b",
  --   displayMessage = "c",
  -- }
  -- QLTrace:LogLine(elementData);
  QLTrace:SetShown(not QLTrace:IsShown())
end
SLASH_QLTRACE1 = "/qltrace"

-- local function QuestDump()
--   -- local questLog = GetNumQuestLogEntries()
--   for questLogIndex = 1, MAX_QUEST_LOG_INDEX do
--     -- * Short way (Less performant)
--     local questId = GetQuestIDFromLogIndex(questLogIndex)

--     -- * Long way
--     local title, _, _, isHeader, _, _, _, questId2 = GetQuestLogTitle(questLogIndex)

--     if not title then
--       break -- We exceeded the data in the quest log
--     end

--     if questId ~= questId2 then
--       print("QuestLogTest", "Quest ID mismatch", questId, questId2)
--       break
--     end

--     if questId ~= 0 and not isHeader then
--       -- * From Index
--       local returnDataIndex = { GetQuestLogTitle(questLogIndex) }
--       -- * From ID
--       local returnDataId = { GetQuestLogTitle(GetQuestLogIndexByID(questId)) }

--       if not DeepCompare(returnDataIndex, returnDataId) then
--         print("QuestLogTest", "Data does not match", returnDataIndex[1], questId)
--       end

--       local returnData = returnDataIndex

--       if not QuestHistory[questId] then
--         print("QuestLogTest", "Adding new quest to history", returnData[1], questId)
--         QuestHistory[questId] = {}

--         table.insert(QuestHistory[questId], {
--           timestamp = GetTime(),
--           -- index = questLogIndex,
--           id = questId,
--           GetQuestLogTitle = returnData,
--           GetQuestObjectives = C_QuestLog.GetQuestObjectives(questId)
--         })
--       else
--         local objectives = C_QuestLog.GetQuestObjectives(questId)
--         local lastIndex = #QuestHistory[questId]
--         if not DeepCompare(objectives, QuestHistory[questId][lastIndex].GetQuestObjectives) then
--           print("QuestLogTest", "Objectives differ for quest", questId)
--           table.insert(QuestHistory[questId], {
--             timestamp = GetTime(),
--             -- index = questLogIndex,
--             id = questId,
--             GetQuestLogTitle = returnData,
--             GetQuestObjectives = objectives
--           })
--         end
--       end
--     end
--   end
-- end
