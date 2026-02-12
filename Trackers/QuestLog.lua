---@type QuestLogTraceCore
local Core = QuestLogTraceCore
---@type fun(...): PackedArgs
local PackArgs = Core.PackArgs

---@type number[]
local SAMPLE_DELAYS = { 0, 0.10, 0.35, 0.55, 0.75, 1.00 }

---@type table<string, FunctionStreamEntry[]|table<string|number, FunctionStreamEntry[]>>
local functions   -- capture.session.functions
---@type number[]?
local prevQuestLog  -- last QuestLog value (array of quest IDs)
---@type table<number, table<string, any>>
local prevQuest     -- [questId][funcName] -> last value for change detection

---------------------------------------------------------------------------
-- API helpers (logic preserved from existing implementation)
---------------------------------------------------------------------------

--- Get all quest IDs currently in the quest log.
---@return number[] questIds Array of quest IDs
local function GetAllQuestIdsInLog()
  ---@type number[]
  local questIds = {}
  for questLogIndex = 1, 75 do
    ---@type string?, any, any, any, any, any, any, number?
    local title, _, _, _, _, _, _, questId = GetQuestLogTitle(questLogIndex)
    if not title then return questIds end
    if questId and questId > 0 then
      questIds[#questIds + 1] = questId
    end
  end
  return questIds
end

---------------------------------------------------------------------------
-- Streaming helpers
---------------------------------------------------------------------------

--- Get or create a parameterized function stream for a given function name and key.
---@param funcName string
---@param key string|number
---@return FunctionStreamEntry[]
local function GetOrCreateParamStream(funcName, key)
  if not functions[funcName] then
    functions[funcName] = {}
  end
  if not functions[funcName][key] then
    functions[funcName][key] = {}
  end
  return functions[funcName][key]
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

  -- QuestLog membership (parameterless stream)
  ---@type FunctionStreamEntry[]
  local questLogStream = functions["QuestLog"]
  if not prevQuestLog or not DeepCompare(questIds, prevQuestLog) then
    ---@type number[]
    local copy = {}
    for i = 1, #questIds do copy[i] = questIds[i] end
    questLogStream[#questLogStream + 1] = { t = t, tp = tp, v = copy }
    prevQuestLog = copy
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
  },

  ---@param capture CaptureState
  Init = function(capture)
    functions = capture.session.functions
    functions["QuestLog"] = {}
    prevQuestLog = nil
    prevQuest = {}

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
