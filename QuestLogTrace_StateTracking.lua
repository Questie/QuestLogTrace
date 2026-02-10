---@class QuestLog
local QuestLog = select(2, ...)
QuestLogTraceCore = QuestLogTraceCore or {}
local Core = QuestLogTraceCore

---@type table<number, { timestamp: number, questIds: number[] }>
QuestLogHistory = QuestLogHistory or {}
---@type table<number, table<number, QuestHistory>>
QuestHistory = QuestHistory or {}
---@type table<number, { timestamp: number, added: number[], removed: number[], count: number }>
CompletedQuestsHistory = CompletedQuestsHistory or {}
---@type table<number, true>
CompletedQuestsState = CompletedQuestsState or {}
CompletedQuestsCount = CompletedQuestsCount or 0
---@type table<number, table>
LootHistory = LootHistory or {}
---@type table<number, table>
ReputationHistory = ReputationHistory or {}
---@type table<number, table>
ReputationMeta = ReputationMeta or {}
---@type table<number, table>
ReputationState = ReputationState or {}

local completedQuestScratch = {}

local function ArrayCopy(input)
  local out = {}
  for i = 1, #input do
    out[i] = input[i]
  end
  return out
end

local function PackValues(...)
  local out = { ... }
  out.n = select("#", ...)
  return out
end

local function CopyPacked(input)
  if type(input) ~= "table" then
    return { n = 0 }
  end

  local out = {}
  local n = input.n or #input
  for i = 1, n do
    out[i] = input[i]
  end
  out.n = n
  return out
end

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

local function GetCompletedQuestIds()
  local questIds = {}
  if type(GetQuestsCompleted) ~= "function" then
    return questIds
  end

  wipe(completedQuestScratch)
  local completed = GetQuestsCompleted(completedQuestScratch)
  if type(completed) ~= "table" then
    return questIds
  end

  for questId, isCompleted in pairs(completed) do
    if isCompleted == true then
      questIds[#questIds + 1] = questId
    end
  end
  table.sort(questIds)

  return questIds
end

local function BuildCompletedQuestSet(questIds)
  local set = {}
  for i = 1, #questIds do
    set[questIds[i]] = true
  end
  return set
end

local function ComputeSetDiff(previousSet, currentSet)
  local added, removed = {}, {}
  for questId in pairs(currentSet) do
    if not previousSet[questId] then
      added[#added + 1] = questId
    end
  end
  for questId in pairs(previousSet) do
    if not currentSet[questId] then
      removed[#removed + 1] = questId
    end
  end
  table.sort(added)
  table.sort(removed)
  return added, removed
end

local function CompletedQuestsDump()
  local questIds = GetCompletedQuestIds()
  local currentSet = BuildCompletedQuestSet(questIds)
  local added, removed = ComputeSetDiff(CompletedQuestsState, currentSet)

  if #added > 0 or #removed > 0 then
    CompletedQuestsHistory[#CompletedQuestsHistory + 1] = {
      timestamp = GetTime(),
      added = added,
      removed = removed,
      count = #questIds,
    }
  end

  CompletedQuestsState = currentSet
  CompletedQuestsCount = #questIds
end

local function LootDump(eventName)
  if type(GetNumLootItems) ~= "function" then
    return false
  end

  local itemCount = GetNumLootItems()
  if type(itemCount) ~= "number" or itemCount < 1 then
    return false
  end

  local snapshot = {
    timestamp = GetTime(),
    event = eventName,
    count = itemCount,
    slots = {},
  }

  for lootSlot = 1, itemCount do
    local lootSlotInfo = type(GetLootSlotInfo) == "function" and PackValues(GetLootSlotInfo(lootSlot)) or { n = 0 }
    local lootSources = type(GetLootSourceInfo) == "function" and PackValues(GetLootSourceInfo(lootSlot)) or { n = 0 }
    local lootLink = type(GetLootSlotLink) == "function" and GetLootSlotLink(lootSlot) or nil
    local lootType = type(GetLootSlotType) == "function" and GetLootSlotType(lootSlot) or nil
    snapshot.slots[#snapshot.slots + 1] = {
      index = lootSlot,
      info = lootSlotInfo,
      sources = lootSources,
      link = lootLink,
      slotType = lootType,
    }
  end

  LootHistory[#LootHistory + 1] = snapshot
  return true
end

local function CollectAllFactions()
  local factions = {}
  if type(GetNumFactions) ~= "function" or type(GetFactionInfo) ~= "function" then
    return factions
  end

  local numFactions = GetNumFactions() or 0
  local factionIndex = 1
  while factionIndex <= numFactions do
    local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar,
      isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canSetInactive =
      GetFactionInfo(factionIndex)

    if factionID then
      factions[factionID] = {
        name = name,
        description = description,
        standingID = standingID,
        barMin = barMin,
        barMax = barMax,
        barValue = barValue,
        atWarWith = atWarWith,
        canToggleAtWar = canToggleAtWar,
        isHeader = isHeader,
        isCollapsed = isCollapsed,
        hasRep = hasRep,
        isWatched = isWatched,
        isChild = isChild,
        hasBonusRepGain = hasBonusRepGain,
        canSetInactive = canSetInactive,
      }
    end

    if isHeader and isCollapsed and type(ExpandFactionHeader) == "function" then
      ExpandFactionHeader(factionIndex)
      numFactions = GetNumFactions() or numFactions
    end

    factionIndex = factionIndex + 1
  end

  return factions
end

local function CopyReputationDynamic(row)
  return {
    s = row.standingID,
    mn = row.barMin,
    mx = row.barMax,
    v = row.barValue,
    w = row.atWarWith,
    iw = row.isWatched,
  }
end

local function CaptureReputationDelta(eventName)
  local factions = CollectAllFactions()
  local timestamp = GetTime()
  local changed = false

  for factionID, row in pairs(factions) do
    if not ReputationMeta[factionID] then
      ReputationMeta[factionID] = {
        name = row.name,
        description = row.description,
        ctw = row.canToggleAtWar,
        h = row.isHeader,
        hr = row.hasRep,
        ch = row.isChild,
        br = row.hasBonusRepGain,
        csi = row.canSetInactive,
      }
    end

    local previous = ReputationState[factionID]
    local current = CopyReputationDynamic(row)
    local delta = nil

    if not previous then
      delta = {
        t = timestamp,
        e = eventName,
        s = current.s,
        mn = current.mn,
        mx = current.mx,
        v = current.v,
        w = current.w,
        iw = current.iw,
      }
    else
      local hasChange = false
      local out = { t = timestamp, e = eventName }
      if current.s ~= previous.s then out.s = current.s hasChange = true end
      if current.mn ~= previous.mn then out.mn = current.mn hasChange = true end
      if current.mx ~= previous.mx then out.mx = current.mx hasChange = true end
      if current.v ~= previous.v then out.v = current.v hasChange = true end
      if current.w ~= previous.w then out.w = current.w hasChange = true end
      if current.iw ~= previous.iw then out.iw = current.iw hasChange = true end
      if hasChange then
        delta = out
      end
    end

    if delta then
      ReputationHistory[factionID] = ReputationHistory[factionID] or {}
      ReputationHistory[factionID][#ReputationHistory[factionID] + 1] = delta
      changed = true
    end

    ReputationState[factionID] = current
  end

  return changed
end

function Core.ResetStateTracking()
  QuestHistory = {}
  QuestLogHistory = {}
  CompletedQuestsHistory = {}
  CompletedQuestsState = {}
  CompletedQuestsCount = 0
  LootHistory = {}
  ReputationHistory = {}
  ReputationMeta = {}
  ReputationState = {}
end

function Core.CaptureQuestState()
  local questIds = GetAllQuestIdsInLog()
  QuestLogDump()
  QuestDump(questIds)
  CompletedQuestsDump()
end

function Core.CaptureLootState(eventName)
  return LootDump(eventName)
end

function Core.CaptureReputationState(eventName)
  return CaptureReputationDelta(eventName)
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

function Core.SerializeCompletedQuestsHistory()
  local serialized = {}
  for i = 1, #CompletedQuestsHistory do
    local snapshot = CompletedQuestsHistory[i]
    serialized[i] = {
      t = snapshot.timestamp,
      a = ArrayCopy(snapshot.added),
      r = ArrayCopy(snapshot.removed),
      c = snapshot.count,
    }
  end
  return serialized
end

function Core.SerializeLootHistory()
  local serialized = {}
  for i = 1, #LootHistory do
    local snapshot = LootHistory[i]
    local outSlots = {}
    for j = 1, #snapshot.slots do
      local slot = snapshot.slots[j]
      outSlots[j] = {
        i = slot.index,
        l = CopyPacked(slot.info),
        s = CopyPacked(slot.sources),
        k = slot.link,
        t = slot.slotType,
      }
    end

    serialized[i] = {
      t = snapshot.timestamp,
      e = snapshot.event,
      n = snapshot.count,
      slots = outSlots,
    }
  end
  return serialized
end

function Core.SerializeReputationHistory()
  local historyOut = {}
  local factionIDs = {}
  local totalSnapshots = 0

  for factionID in pairs(ReputationHistory) do
    factionIDs[#factionIDs + 1] = factionID
  end
  table.sort(factionIDs)

  for i = 1, #factionIDs do
    local factionID = factionIDs[i]
    local snapshots = ReputationHistory[factionID]
    local outSnapshots = {}
    for j = 1, #snapshots do
      local row = snapshots[j]
      outSnapshots[j] = {
        t = row.t,
        e = row.e,
        s = row.s,
        mn = row.mn,
        mx = row.mx,
        v = row.v,
        w = row.w,
        iw = row.iw,
      }
    end
    totalSnapshots = totalSnapshots + #outSnapshots
    historyOut[factionID] = outSnapshots
  end

  local metaOut = {}
  for i = 1, #factionIDs do
    local factionID = factionIDs[i]
    local meta = ReputationMeta[factionID]
    if meta then
      metaOut[factionID] = {
        n = meta.name,
        d = meta.description,
        ctw = meta.ctw,
        h = meta.h,
        hr = meta.hr,
        ch = meta.ch,
        br = meta.br,
        csi = meta.csi,
      }
    end
  end

  return historyOut, metaOut, #factionIDs, totalSnapshots
end

function Core.GetQuestSnapshotCount()
  return #QuestLogHistory
end

function Core.GetCompletedQuestSnapshotCount()
  return #CompletedQuestsHistory
end

function Core.GetLatestCompletedQuestCount()
  return CompletedQuestsCount
end
