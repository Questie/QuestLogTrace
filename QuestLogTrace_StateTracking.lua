---@class QuestLog
local QuestLog = select(2, ...)
QuestLogTraceCore = QuestLogTraceCore or {}
local Core = QuestLogTraceCore

---@type table<number, { timestamp: number, questIds: number[] }>
QuestLogHistory = QuestLogHistory or {}
---@type table<number, table<number, QuestHistory>>
QuestHistory = QuestHistory or {}

--- Deep compare two values.
---@param t1 any
---@param t2 any
---@param ignore_mt boolean?
---@return boolean equal
function DeepCompare(t1, t2, ignore_mt, visited)
  if t1 == t2 then return true end

  local type1, type2 = type(t1), type(t2)
  if type1 ~= type2 then return false end

  if type1 ~= "table" then return t1 == t2 end

  visited = visited or {}
  if visited[t1] and visited[t1] == t2 then return true end
  visited[t1] = t2

  if not ignore_mt then
    local mt1, mt2 = getmetatable(t1), getmetatable(t2)
    if mt1 or mt2 then
      if not DeepCompare(mt1, mt2, ignore_mt, visited) then
        return false
      end
    end
  end

  for key, value in pairs(t1) do
    if key ~= "timestamp" then
      if t2[key] == nil or not DeepCompare(value, t2[key], ignore_mt, visited) then
        return false
      end
    end
  end

  for key in pairs(t2) do
    if key ~= "timestamp" then
      if t1[key] == nil then
        return false
      end
    end
  end

  return true
end

function TablesDiffer(t1, t2, ignore_mt)
  return not DeepCompare(t1, t2, ignore_mt)
end

---Gets all quest IDs in the quest log
---@return number[] questIds
function GetAllQuestIdsInLog()
  local questIds = {}
  for questLogIndex = 1, 75 do
    local title, _, _, _, _, _, _, questId = GetQuestLogTitle(questLogIndex)

    if not title then
      return questIds
    end

    if questId and questId > 0 then
      questIds[#questIds + 1] = questId
    end
  end

  return questIds
end

---@param questIds number[]
local function QuestDump(questIds)
  for qIndex = 1, #questIds do
    local questId = questIds[qIndex]

    local questLogTitleData = { GetQuestLogTitle(GetQuestLogIndexByID(questId)) }
    local questObjectivesData = C_QuestLog.GetQuestObjectives(questId)
    local questTagInfoData = { GetQuestTagInfo(questId) }

    if not QuestHistory[questId] then
      QuestHistory[questId] = {}

      table.insert(QuestHistory[questId], {
        timestamp = GetTime(),
        id = questId,
        IsQuestComplete = IsQuestComplete(questId),
        IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted(questId),
        GetQuestLogTitle = questLogTitleData,
        GetQuestObjectives = questObjectivesData,
        QuestTagInfo = questTagInfoData,
      })
    else
      local lastIndex = #QuestHistory[questId]
      local previous = QuestHistory[questId][lastIndex]

      local doObjectivesDiff = not DeepCompare(questObjectivesData, previous.GetQuestObjectives)
      local doQuestTitleDiff = not DeepCompare(questLogTitleData, previous.GetQuestLogTitle)
      local doQuestTagInfoDiff = not DeepCompare(questTagInfoData, previous.QuestTagInfo)
      local doQuestCompleteDiff = IsQuestComplete(questId) ~= previous.IsQuestComplete
      local doQuestFlaggedCompleteDiff = C_QuestLog.IsQuestFlaggedCompleted(questId) ~= previous.IsQuestFlaggedCompleted

      if doObjectivesDiff or doQuestTitleDiff or doQuestTagInfoDiff or doQuestCompleteDiff or doQuestFlaggedCompleteDiff then
        table.insert(QuestHistory[questId], {
          timestamp = GetTime(),
          id = questId,
          IsQuestComplete = IsQuestComplete(questId),
          IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted(questId),
          GetQuestLogTitle = questLogTitleData,
          GetQuestObjectives = questObjectivesData,
          QuestTagInfo = questTagInfoData,
        })
      end
    end
  end
end

local function QuestLogDump()
  local questLog = { timestamp = GetTime(), questIds = GetAllQuestIdsInLog() }
  local lastSnapshot = QuestLogHistory[#QuestLogHistory]

  if not lastSnapshot or not DeepCompare(questLog, lastSnapshot) then
    QuestLogHistory[#QuestLogHistory + 1] = questLog
  end
end

function Core.ResetStateTracking()
  QuestHistory = {}
  QuestLogHistory = {}
end

function Core.CaptureQuestState()
  QuestLogDump()
  QuestDump(GetAllQuestIdsInLog())
end

function Core.SerializeQuestHistory()
  local serialized = {}
  local questIds = {}

  for questId in pairs(QuestHistory) do
    questIds[#questIds + 1] = questId
  end
  table.sort(questIds)

  for i = 1, #questIds do
    local questId = questIds[i]
    local snapshots = QuestHistory[questId]
    local outSnapshots = {}

    for index = 1, #snapshots do
      local snapshot = snapshots[index]
      outSnapshots[index] = {
        t = snapshot.timestamp,
        c = snapshot.IsQuestComplete,
        f = snapshot.IsQuestFlaggedCompleted,
        title = snapshot.GetQuestLogTitle,
        objectives = snapshot.GetQuestObjectives,
        tag = snapshot.QuestTagInfo,
      }
    end

    serialized[questId] = outSnapshots
  end

  return serialized
end

local function ArrayCopy(input)
  local out = {}
  for i = 1, #input do
    out[i] = input[i]
  end
  return out
end

function Core.SerializeQuestLogHistory()
  local serialized = {}
  for i = 1, #QuestLogHistory do
    local snapshot = QuestLogHistory[i]
    serialized[i] = {
      t = snapshot.timestamp,
      q = ArrayCopy(snapshot.questIds),
    }
  end
  return serialized
end

function Core.GetQuestSnapshotCount()
  return #QuestLogHistory
end
