---@type QuestLogTraceCore
local Core = QuestLogTraceCore
---@type fun(...): PackedArgs
local PackArgs = Core.PackArgs

---------------------------------------------------------------------------
-- WoW API return schemas (for trace analyzer display labels)
---------------------------------------------------------------------------
-- GetQuestLogTitle(questLogIndex) -> string  title,
--                                    number  level,
--                                    number  suggestedGroup,
--                                    boolean isHeader,
--                                    boolean isCollapsed,
--                                    number  isComplete,      -- 1=done, -1=failed, nil=in progress
--                                    number  frequency,       -- 1=normal, 2=daily, 3=weekly
--                                    number  questID,
--                                    boolean startEvent,
--                                    boolean displayQuestID,
--                                    boolean isOnMap,
--                                    boolean hasLocalPOI,
--                                    boolean isTask,
--                                    boolean isBounty,
--                                    boolean isStory,
--                                    boolean isHidden,
--                                    boolean isScaling
--
-- GetQuestLogQuestText(questLogIndex) -> string questDescription,
--                                        string questObjectives
--
-- GetQuestTagInfo(questID) -> number? tagID,
--                             string? tagName,
--                             number? worldQuestType,
--                             number  rarity,
--                             boolean isElite,
--                             number  tradeskillLineIndex,
--                             unknown displayTimeLeft
--
-- IsQuestComplete(questID)                    -> boolean isComplete
-- HaveQuestData(questID)                       -> boolean hasData
-- C_QuestLog.IsOnQuest(questID)                -> boolean isOnQuest
-- C_QuestLog.GetMaxNumQuestsCanAccept()        -> number maxNumQuestsCanAccept
-- C_QuestLog.IsQuestFlaggedCompleted(questID)  -> boolean isCompleted
-- C_QuestLog.GetQuestObjectives(questID)       -> QuestObjectiveInfo[] objectives
-- GetQuestLogTitle(questLogIndex)              -> packed title tuple keyed by questID
-- GetQuestLogQuestText(questLogIndex)          -> packed quest text tuple keyed by questID
-- GetQuestTimers[questID]                      -> number secondsLeft (derived from GetQuestTimers())
-- GetQuestLogTimeLeft[questID]                 -> number secondsLeft (same derived compatibility value)
-- GetNumQuestLogRewards(questID)               -> number numRewards
-- GetQuestLogRewardInfo(index, questID)        -> packed reward item tuple
-- GetQuestLogRewardMoney(questID)              -> number money
-- GetQuestLogIndexByID(questID)                -> number questLogIndex
--
-- QuestLog (custom stream) -> number[] questIDs  -- array of active quest IDs
---------------------------------------------------------------------------

---@type number[]
local SAMPLE_DELAYS = { 0, 0.10, 0.35, 0.55, 0.75, 1.00 }

---@type table<string, FunctionStream>
local functions   -- capture.session.functions
---@type number[]?
local prevQuestLog  -- last QuestLog value (array of quest IDs)
---@type table<string, any>
local prevFlat      -- [funcName] -> last value for flat stream change detection
---@type table<number, table<string, any>>
local prevQuest     -- [questId][funcName] -> last value for change detection
---@type table<string, table<string|number, table<string|number, any>>>
local prevNested    -- Mirrors nested stream parameters for change detection only.
---@type table<number, boolean>
local prevTimedQuestIds -- Timed quest IDs from the previous derived timer sample.
---@type table<number, number>
local prevRewardCounts -- Highest reward index previously captured for each active quest.

---------------------------------------------------------------------------
-- API helpers (logic preserved from existing implementation)
---------------------------------------------------------------------------

--- Get a quest ID at a quest log index.
---@param questLogIndex number
---@return number? questId
local function GetQuestIdAtLogIndex(questLogIndex)
  ---@type boolean, string?, any, any, any, any, any, any, number?
  local ok, title, _, _, _, _, _, _, questId = pcall(GetQuestLogTitle, questLogIndex)
  if not ok or not title then return nil end
  if questId and questId > 0 then return questId end
  return nil
end

--- Get all quest IDs currently in the quest log.
---@return number[] questIds Array of quest IDs
local function GetAllQuestIdsInLog()
  ---@type number[]
  local questIds = {}
  for questLogIndex = 1, 75 do
    local questId = GetQuestIdAtLogIndex(questLogIndex)
    if not questId then
      local ok, title = pcall(GetQuestLogTitle, questLogIndex)
      if not ok or not title then return questIds end
    else
      questIds[#questIds + 1] = questId
    end
  end
  return questIds
end

---------------------------------------------------------------------------
-- Streaming helpers
---------------------------------------------------------------------------

--- Get or create a flat function stream for a given function name.
---@param funcName string
---@return FunctionStreamEntry[]
local function GetOrCreateFlatStream(funcName)
  if not functions[funcName] then
    functions[funcName] = {}
  end
  local stream = functions[funcName]
  ---@cast stream FunctionStreamEntry[]
  return stream
end

--- Get or create a parameterized function stream for a given function name and key.
---@param funcName string
---@param key string|number
---@return FunctionStreamEntry[]
local function GetOrCreateParamStream(funcName, key)
  if not functions[funcName] then
    functions[funcName] = {}
  end
  local streams = functions[funcName]
  ---@cast streams table<string|number, FunctionStreamEntry[]>
  if not streams[key] then
    streams[key] = {}
  end
  return streams[key]
end

---Get or create a two-parameter stream in native API argument order.
---This is the canonical shape for true multi-argument APIs. It avoids composite
---string keys and lets consumers walk `functions[name][arg1][arg2]` generically.
---@param funcName string
---@param key1 string|number First native argument
---@param key2 string|number Second native argument
---@return FunctionStreamEntry[]
local function GetOrCreateNestedParamStream(funcName, key1, key2)
  if not functions[funcName] then
    functions[funcName] = {}
  end

  local firstLevel = functions[funcName]
  ---@cast firstLevel table<string|number, table<string|number, FunctionStreamEntry[]>>
  if not firstLevel[key1] then
    firstLevel[key1] = {}
  end
  if not firstLevel[key1][key2] then
    firstLevel[key1][key2] = {}
  end
  return firstLevel[key1][key2]
end

--- Append a value to a flat stream if it has changed from the previously recorded value.
---@param stream FunctionStreamEntry[]
---@param t number Relative time from GetTime()
---@param tp number Relative time from GetTimePreciseSec()
---@param v any The new value to compare and potentially append
---@param funcName string The function name for change tracking
local function AppendFlatIfChanged(stream, t, tp, v, funcName)
  local prev = prevFlat[funcName]
  local changed = false

  if prev == nil and v == nil then
    changed = #stream == 0
  elseif prev == nil or v == nil then
    changed = true
  elseif type(v) == "table" then
    changed = not DeepCompare(v, prev)
  else
    changed = v ~= prev
  end

  if changed then
    stream[#stream + 1] = { t = t, tp = tp, v = v }
    prevFlat[funcName] = v
  end
end

--- Append a value to the stream if it has changed from the previously recorded value.
---@param stream FunctionStreamEntry[]
---@param t number Relative time from GetTime()
---@param tp number Relative time from GetTimePreciseSec()
---@param v any The new value to compare and potentially append
---@param questId number The quest ID for change tracking
---@param funcName string The function name for change tracking
local function AppendIfChanged(stream, t, tp, v, questId, funcName)
  ---@type any
  local prev = prevQuest[questId] and prevQuest[questId][funcName]
  ---@type boolean
  local changed = false

  if prev == nil and v == nil then
    -- Both nil — only changed if this is the first entry for this quest+func
    changed = #stream == 0
  elseif prev == nil or v == nil then
    changed = true
  elseif type(v) == "table" then
    changed = not DeepCompare(v, prev)
  else
    changed = v ~= prev
  end

  if changed then
    stream[#stream + 1] = { t = t, tp = tp, v = v }
    if not prevQuest[questId] then prevQuest[questId] = {} end
    prevQuest[questId][funcName] = v
  end
end

--- Append a value to a nested parameterized stream if it changed.
---@param stream FunctionStreamEntry[]
---@param t number Relative time from GetTime()
---@param tp number Relative time from GetTimePreciseSec()
---@param v any The new value to compare and potentially append
---@param funcName string The function name for change tracking
---@param key1 string|number First native argument
---@param key2 string|number Second native argument
local function AppendNestedIfChanged(stream, t, tp, v, funcName, key1, key2)
  if not prevNested[funcName] then prevNested[funcName] = {} end
  if not prevNested[funcName][key1] then prevNested[funcName][key1] = {} end

  local previous = prevNested[funcName][key1][key2]
  local changed = false

  if previous == nil and v == nil then
    changed = #stream == 0
  elseif previous == nil or v == nil then
    changed = true
  elseif type(v) == "table" then
    changed = not DeepCompare(v, previous)
  else
    changed = v ~= previous
  end

  if changed then
    stream[#stream + 1] = { t = t, tp = tp, v = v }
    prevNested[funcName][key1][key2] = v
  end
end

---Return whether a nested stream has previously captured a non-nil value.
---@param funcName string
---@param key1 string|number
---@param key2 string|number
---@return boolean
local function HasNestedPrevious(funcName, key1, key2)
  return prevNested[funcName] ~= nil
    and prevNested[funcName][key1] ~= nil
    and prevNested[funcName][key1][key2] ~= nil
end

---Append nil tombstones for reward entries that are no longer present.
---Reward streams outlive the quest log membership stream during replay, so a
---removed reward index must write an explicit nil to avoid stale item data.
---@param t number
---@param tp number
---@param questId number
---@param fromRewardIndex number
---@param toRewardIndex number
local function TombstoneRewardInfoRange(t, tp, questId, fromRewardIndex, toRewardIndex)
  for rewardIndex = fromRewardIndex, toRewardIndex do
    if HasNestedPrevious("GetQuestLogRewardInfo", rewardIndex, questId) then
      AppendNestedIfChanged(
        GetOrCreateNestedParamStream("GetQuestLogRewardInfo", rewardIndex, questId),
        t, tp, nil, "GetQuestLogRewardInfo", rewardIndex, questId
      )
    end
  end
end

---Append reward tombstones for a quest leaving the quest log.
---Quest removal stops future per-quest reward sampling, so all reward-related
---latest values for that quest are invalidated in the same timestamp.
---@param t number
---@param tp number
---@param questId number
local function TombstoneRemovedQuestRewards(t, tp, questId)
  local questPrev = prevQuest[questId]
  if questPrev then
    if questPrev.GetNumQuestLogRewards ~= nil then
      AppendIfChanged(
        GetOrCreateParamStream("GetNumQuestLogRewards", questId),
        t, tp, nil, questId, "GetNumQuestLogRewards"
      )
    end
    if questPrev.GetQuestLogRewardMoney ~= nil then
      AppendIfChanged(
        GetOrCreateParamStream("GetQuestLogRewardMoney", questId),
        t, tp, nil, questId, "GetQuestLogRewardMoney"
      )
    end
  end

  local previousRewardCount = prevRewardCounts[questId] or 0
  if previousRewardCount > 0 then
    TombstoneRewardInfoRange(t, tp, questId, 1, previousRewardCount)
    prevRewardCounts[questId] = nil
  end
end

---Safely call a function and return the first result.
---@param fn function?
---@param ... any
---@return boolean ok
---@return any value
local function SafeScalarCall(fn, ...)
  if type(fn) ~= "function" then return false, nil end
  local ok, value = pcall(fn, ...)
  if not ok then return false, nil end
  return true, value
end

---Safely call a function and pack all returned values.
---@param fn function?
---@param ... any
---@return boolean ok
---@return PackedArgs? value
local function SafePackedCall(fn, ...)
  if type(fn) ~= "function" then return false, nil end
  local packed = PackArgs(pcall(fn, ...))
  if not packed[1] then return false, nil end

  local out = { n = packed.n - 1 }
  for i = 2, packed.n do
    out[i - 1] = packed[i]
  end
  return true, out
end

---Append explicit inactive state for quests removed from the quest log.
---Most quest streams are interpreted alongside the synthetic QuestLog membership
---stream, but `C_QuestLog.IsOnQuest` is a direct boolean API and must receive a
---false tombstone so replay does not keep the previous true value forever.
---@param t number
---@param tp number
---@param currentQuestIds number[]
local function SampleRemovedQuestState(t, tp, currentQuestIds)
  if not prevQuestLog then return end

  ---@type table<number, boolean>
  local currentSet = {}
  for i = 1, #currentQuestIds do
    currentSet[currentQuestIds[i]] = true
  end

  local canSampleIsOnQuest = type(C_QuestLog) == "table" and type(C_QuestLog.IsOnQuest) == "function"
  for i = 1, #prevQuestLog do
    local questId = prevQuestLog[i]
    if not currentSet[questId] then
      if canSampleIsOnQuest then
        AppendIfChanged(
          GetOrCreateParamStream("C_QuestLog.IsOnQuest", questId),
          t, tp, false, questId, "C_QuestLog.IsOnQuest"
        )
      end
      TombstoneRemovedQuestRewards(t, tp, questId)
    end
  end
end

---Sample native timer varargs and derive questId-keyed compatibility streams.
---Classic timer APIs are not questID-parameterized: `GetQuestTimers()` returns
---timer slots, and `GetQuestIndexForTimer(slot)` maps each slot to the current
---quest log index. We store the resolved seconds under questID so replay callers
---can answer Questie's questID-shaped timer queries without mutating quest-log
---selection via `SelectQuestLogEntry`.
---@param t number
---@param tp number
local function SampleQuestTimers(t, tp)
  if type(GetQuestTimers) ~= "function" or type(GetQuestIndexForTimer) ~= "function" then return end

  local ok, timers = SafePackedCall(GetQuestTimers)
  if not ok or not timers then return end

  ---@type table<number, boolean>
  local currentTimedQuestIds = {}

  for timerIndex = 1, timers.n do
    local secondsLeft = timers[timerIndex]
    local indexOk, questLogIndex = SafeScalarCall(GetQuestIndexForTimer, timerIndex)
    if indexOk and type(questLogIndex) == "number" then
      local questId = GetQuestIdAtLogIndex(questLogIndex)
      if questId then
        currentTimedQuestIds[questId] = true
        AppendIfChanged(
          GetOrCreateParamStream("GetQuestTimers", questId),
          t, tp, secondsLeft, questId, "GetQuestTimers"
        )
        AppendIfChanged(
          GetOrCreateParamStream("GetQuestLogTimeLeft", questId),
          t, tp, secondsLeft, questId, "GetQuestLogTimeLeft"
        )
      end
    end
  end

  for questId in pairs(prevTimedQuestIds) do
    if not currentTimedQuestIds[questId] then
      AppendIfChanged(
        GetOrCreateParamStream("GetQuestTimers", questId),
        t, tp, nil, questId, "GetQuestTimers"
      )
      AppendIfChanged(
        GetOrCreateParamStream("GetQuestLogTimeLeft", questId),
        t, tp, nil, questId, "GetQuestLogTimeLeft"
      )
    end
  end

  prevTimedQuestIds = currentTimedQuestIds
end

---------------------------------------------------------------------------
-- Core sampling
---------------------------------------------------------------------------

--- Sample the entire quest log and record changes.
---@param capture CaptureState
local function SampleQuestLog(capture)
  ---@type number
  local t  = GetTime()          - capture.startedAt
  ---@type number
  local tp = GetTimePreciseSec() - capture.startedAtPrecise

  ---@type number[]
  local questIds = GetAllQuestIdsInLog()

  -- QuestLog membership is the source of truth for which questID-keyed streams
  -- are currently meaningful. Tombstones for direct boolean/reward APIs are
  -- written before the membership update so both changes share the same sample.
  ---@type FunctionStreamEntry[]
  local questLogStream = functions["QuestLog"]
  if not prevQuestLog or not DeepCompare(questIds, prevQuestLog) then
    SampleRemovedQuestState(t, tp, questIds)

    ---@type number[]
    local copy = {}
    for i = 1, #questIds do copy[i] = questIds[i] end
    questLogStream[#questLogStream + 1] = { t = t, tp = tp, v = copy }
    prevQuestLog = copy
  end

  -- Timer APIs are native parameterless varargs; derive questId-keyed compatibility streams.
  SampleQuestTimers(t, tp)

  -- C_QuestLog.GetMaxNumQuestsCanAccept -- scalar number
  if type(C_QuestLog) == "table" and type(C_QuestLog.GetMaxNumQuestsCanAccept) == "function" then
    local ok, maxQuests = SafeScalarCall(C_QuestLog.GetMaxNumQuestsCanAccept)
    if ok then
      AppendFlatIfChanged(
        GetOrCreateFlatStream("C_QuestLog.GetMaxNumQuestsCanAccept"),
        t, tp, maxQuests, "C_QuestLog.GetMaxNumQuestsCanAccept"
      )
    end
  end

  -- Per-quest functions (parameterized by questId)
  for _, questId in ipairs(questIds) do
    -- IsQuestComplete -- scalar boolean
    ---@type boolean?
    local isComplete = IsQuestComplete(questId)
    if isComplete == nil then isComplete = false end
    AppendIfChanged(
      GetOrCreateParamStream("IsQuestComplete", questId),
      t, tp, isComplete, questId, "IsQuestComplete"
    )

    -- HaveQuestData -- scalar boolean/nil (older clients/addons use this to gate quest cache reads)
    if type(HaveQuestData) == "function" then
      ---@type boolean
      local ok
      ---@type boolean?
      local hasData
      ok, hasData = pcall(HaveQuestData, questId)
      if ok then
        AppendIfChanged(
          GetOrCreateParamStream("HaveQuestData", questId),
          t, tp, hasData, questId, "HaveQuestData"
        )
      end
    end

    -- C_QuestLog.IsOnQuest -- scalar boolean/nil
    if type(C_QuestLog) == "table" and type(C_QuestLog.IsOnQuest) == "function" then
      local ok, isOnQuest = SafeScalarCall(C_QuestLog.IsOnQuest, questId)
      if ok then
        AppendIfChanged(
          GetOrCreateParamStream("C_QuestLog.IsOnQuest", questId),
          t, tp, isOnQuest, questId, "C_QuestLog.IsOnQuest"
        )
      end
    end

    -- C_QuestLog.IsQuestFlaggedCompleted -- scalar boolean
    ---@type boolean?
    local isFlagged = C_QuestLog.IsQuestFlaggedCompleted(questId)
    if isFlagged == nil then isFlagged = false end
    AppendIfChanged(
      GetOrCreateParamStream("C_QuestLog.IsQuestFlaggedCompleted", questId),
      t, tp, isFlagged, questId, "C_QuestLog.IsQuestFlaggedCompleted"
    )

    -- C_QuestLog.GetQuestObjectives -- object/table (no n)
    ---@type table?
    local objectives = C_QuestLog.GetQuestObjectives(questId)
    AppendIfChanged(
      GetOrCreateParamStream("C_QuestLog.GetQuestObjectives", questId),
      t, tp, objectives, questId, "C_QuestLog.GetQuestObjectives"
    )

    -- GetQuestLogTitle -- tuple (needs questLogIndex lookup)
    ---@type number?
    local questLogIndex = GetQuestLogIndexByID(questId)
    if questLogIndex then
      ---@type PackedArgs
      local titleData = PackArgs(GetQuestLogTitle(questLogIndex))
      AppendIfChanged(
        GetOrCreateParamStream("GetQuestLogTitle", questId),
        t, tp, titleData, questId, "GetQuestLogTitle"
      )

      -- GetQuestLogQuestText -- tuple (n=2: questDescription, questObjectives)
      local textOk, questTextData = SafePackedCall(GetQuestLogQuestText, questLogIndex)
      if textOk then
        AppendIfChanged(
          GetOrCreateParamStream("GetQuestLogQuestText", questId),
          t, tp, questTextData, questId, "GetQuestLogQuestText"
        )
      end
    end

    -- Quest reward APIs are quest-scoped except GetQuestLogRewardInfo, which is
    -- a true two-argument API. Store it as [rewardIndex][questId] to preserve
    -- native argument order and tombstone stale reward indices when counts shrink.
    local rewardsOk, rewardCount = SafeScalarCall(GetNumQuestLogRewards, questId)
    if rewardsOk then
      AppendIfChanged(
        GetOrCreateParamStream("GetNumQuestLogRewards", questId),
        t, tp, rewardCount, questId, "GetNumQuestLogRewards"
      )

      local currentRewardCount = type(rewardCount) == "number" and math.max(0, math.floor(rewardCount)) or 0
      local previousRewardCount = prevRewardCounts[questId] or 0

      if currentRewardCount > 0 then
        for rewardIndex = 1, currentRewardCount do
          local rewardOk, rewardInfo = SafePackedCall(GetQuestLogRewardInfo, rewardIndex, questId)
          if rewardOk then
            AppendNestedIfChanged(
              GetOrCreateNestedParamStream("GetQuestLogRewardInfo", rewardIndex, questId),
              t, tp, rewardInfo, "GetQuestLogRewardInfo", rewardIndex, questId
            )
          end
        end
      end

      if previousRewardCount > currentRewardCount then
        TombstoneRewardInfoRange(t, tp, questId, currentRewardCount + 1, previousRewardCount)
      end
      prevRewardCounts[questId] = currentRewardCount
    end

    local moneyOk, rewardMoney = SafeScalarCall(GetQuestLogRewardMoney, questId)
    if moneyOk then
      AppendIfChanged(
        GetOrCreateParamStream("GetQuestLogRewardMoney", questId),
        t, tp, rewardMoney, questId, "GetQuestLogRewardMoney"
      )
    end

    -- GetQuestTagInfo -- tuple
    ---@type PackedArgs
    local tagData = PackArgs(GetQuestTagInfo(questId))
    AppendIfChanged(
      GetOrCreateParamStream("GetQuestTagInfo", questId),
      t, tp, tagData, questId, "GetQuestTagInfo"
    )
  end
end

---------------------------------------------------------------------------
-- Delayed re-sample scheduling
---------------------------------------------------------------------------

--- Schedule staggered re-samples to catch server lag.
---@param capture CaptureState
local function ScheduleDelayedSamples(capture)
  ---@type number
  local token = capture.token
  for i = 1, #SAMPLE_DELAYS do
    ---@type number
    local delay = SAMPLE_DELAYS[i]
    if delay > 0 then
      C_After(delay, function()
        if not capture.active or capture.token ~= token then return end
        SampleQuestLog(capture)
      end)
    end
  end
end

---------------------------------------------------------------------------
-- Tracker registration
---------------------------------------------------------------------------

Core.RegisterTracker({
  events = {
    "QUEST_LOG_UPDATE",
    "QUEST_ACCEPTED",
    "QUEST_REMOVED",
    "QUEST_TURNED_IN",
    "QUEST_WATCH_UPDATE",
    "UNIT_QUEST_LOG_CHANGED",
    "QUEST_AUTOCOMPLETE",
    "QUEST_POI_UPDATE",
    "QUEST_ITEM_UPDATE",
    "QUEST_LOG_CRITERIA_UPDATE",
    "QUEST_DATA_LOAD_RESULT",
    "QUEST_WATCH_LIST_CHANGED",
    "QUESTLINE_UPDATE",
    "TASK_PROGRESS_UPDATE",
    "PLAYER_ENTERING_WORLD",
    "SPELLS_CHANGED",
  },

  ---@param capture CaptureState
  Init = function(capture)
    functions = capture.session.functions
    functions["QuestLog"] = {}
    prevQuestLog = nil
    prevFlat = {}
    prevQuest = {}
    prevNested = {}
    prevTimedQuestIds = {}
    prevRewardCounts = {}

    -- Immediate sample at t=0
    SampleQuestLog(capture)

    -- Schedule delayed re-samples for initial capture (catches server lag)
    ScheduleDelayedSamples(capture)
  end,

  ---@param capture CaptureState
  OnEvent = function(capture)
    -- Immediate sample in this callstack (the 0-delay entry)
    SampleQuestLog(capture)

    -- Schedule staggered re-samples
    ScheduleDelayedSamples(capture)
  end,
})
