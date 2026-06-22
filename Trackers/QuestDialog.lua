---@type QuestLogTraceCore
local Core = QuestLogTraceCore
---@type fun(...): PackedArgs
local PackArgs = Core.PackArgs

---------------------------------------------------------------------------
-- WoW API return schemas (for trace analyzer display labels)
---------------------------------------------------------------------------
-- C_GossipInfo.GetOptions()         -> GossipOptionUIInfo[]
--
-- GetGossipAvailableQuests() -> repeated legacy 7-tuples:
--   title, questLevel, isTrivial, frequency, repeatable, isLegendary, isIgnored
-- GetGossipActiveQuests() -> repeated legacy 6-tuples:
--   title, questLevel, isTrivial, isComplete, isLegendary, isIgnored
--
-- GetActiveTitle(index)    -> title, isComplete
-- GetAvailableTitle(index) -> title
---------------------------------------------------------------------------

---@type number[]
local SAMPLE_DELAYS = { 0, 0.10, 0.35, 0.55, 0.75, 1.00 }

---@class QuestDialogStreamDef
---@field key string
---@field getter fun(): boolean, any

---@type table<string, FunctionStream>
local functions
---@type table<string, any>
local previousValues
---@type table<string, boolean>
local availableFlatStreams
---@type table<number, FunctionStreamEntry[]>
local activeTitleStreams
---@type table<number, FunctionStreamEntry[]>
local availableTitleStreams
---@type number
local previousActiveTitleCount = 0
---@type number
local previousAvailableTitleCount = 0
---@type number
local delayedSampleToken = 0 -- Invalidates pending delayed samples when transient UI state closes.

---Return whether a nested table function exists.
---@param namespace table?
---@param functionName string
---@return boolean
local function HasMethod(namespace, functionName)
  return type(namespace) == "table" and type(namespace[functionName]) == "function"
end

---Call a function with pcall and return all results packed, without the pcall status.
---@param fn function?
---@return boolean ok
---@return PackedArgs? results
local function SafePackedCall(fn)
  if type(fn) ~= "function" then return false, nil end

  ---@type PackedArgs
  local packed = PackArgs(pcall(fn))
  if not packed[1] then return false, nil end

  ---@type PackedArgs
  local results = { n = packed.n - 1 }
  for i = 2, packed.n do
    results[i - 1] = packed[i]
  end
  return true, results
end

---Call a function with pcall and return its first result.
---@param fn function?
---@return boolean ok
---@return any value
local function SafeScalarCall(fn)
  local ok, results = SafePackedCall(fn)
  if not ok or not results then return false, nil end
  return true, results[1]
end

---Call an indexed function with pcall and return all results packed.
---@param fn function?
---@param index number
---@return boolean ok
---@return PackedArgs? results
local function SafePackedIndexCall(fn, index)
  if type(fn) ~= "function" then return false, nil end

  ---@type PackedArgs
  local packed = PackArgs(pcall(fn, index))
  if not packed[1] then return false, nil end

  ---@type PackedArgs
  local results = { n = packed.n - 1 }
  for i = 2, packed.n do
    results[i - 1] = packed[i]
  end
  return true, results
end

---Call an indexed function with pcall and return its first result.
---@param fn function?
---@param index number
---@return boolean ok
---@return any value
local function SafeScalarIndexCall(fn, index)
  local ok, results = SafePackedIndexCall(fn, index)
  if not ok or not results then return false, nil end
  return true, results[1]
end

---Append a value to a stream if it differs from the previous value.
---@param stream FunctionStreamEntry[]
---@param t number
---@param tp number
---@param key string
---@param value any
local function AppendIfChanged(stream, t, tp, key, value)
  local previous = previousValues[key]
  local changed

  if previous == nil and value == nil then
    changed = #stream == 0
  elseif previous == nil or value == nil then
    changed = true
  elseif type(value) == "table" then
    changed = not DeepCompare(value, previous)
  else
    changed = value ~= previous
  end

  if changed then
    stream[#stream + 1] = { t = t, tp = tp, v = value }
    previousValues[key] = value
  end
end

---Get or create a parameterized function stream.
---@param functionName string
---@param key number
---@return FunctionStreamEntry[]
local function GetOrCreateIndexStream(functionName, key)
  if not functions[functionName] then
    functions[functionName] = {}
  end

  local streams = functions[functionName]
  ---@cast streams table<number, FunctionStreamEntry[]>
  if not streams[key] then
    streams[key] = {}
  end
  return streams[key]
end

---Create a stream only when its getter exists in this client.
---Dialog/gossip APIs vary across Classic flavors; absent APIs intentionally do
---not create empty streams, so replay can distinguish unavailable from nil.
---@param key string
local function EnsureFlatStream(key)
  functions[key] = {}
  availableFlatStreams[key] = true
end

---Sample one parameterless stream.
---@param t number
---@param tp number
---@param def QuestDialogStreamDef
local function SampleFlatStream(t, tp, def)
  if not availableFlatStreams[def.key] then return end

  local ok, value = def.getter()
  if not ok then return end

  local stream = functions[def.key]
  ---@cast stream FunctionStreamEntry[]
  AppendIfChanged(stream, t, tp, def.key, value)
end

---@return QuestDialogStreamDef[]
local function BuildFlatStreamDefs()
  ---@type QuestDialogStreamDef[]
  local defs = {}

  if HasMethod(C_GossipInfo, "GetNumAvailableQuests") then
    EnsureFlatStream("C_GossipInfo.GetNumAvailableQuests")
    defs[#defs + 1] = { key = "C_GossipInfo.GetNumAvailableQuests", getter = function() return SafeScalarCall(C_GossipInfo.GetNumAvailableQuests) end }
  end
  if HasMethod(C_GossipInfo, "GetNumActiveQuests") then
    EnsureFlatStream("C_GossipInfo.GetNumActiveQuests")
    defs[#defs + 1] = { key = "C_GossipInfo.GetNumActiveQuests", getter = function() return SafeScalarCall(C_GossipInfo.GetNumActiveQuests) end }
  end
  if HasMethod(C_GossipInfo, "GetText") then
    EnsureFlatStream("C_GossipInfo.GetText")
    defs[#defs + 1] = { key = "C_GossipInfo.GetText", getter = function() return SafeScalarCall(C_GossipInfo.GetText) end }
  end
  if HasMethod(C_GossipInfo, "GetOptions") then
    EnsureFlatStream("C_GossipInfo.GetOptions")
    defs[#defs + 1] = { key = "C_GossipInfo.GetOptions", getter = function() return SafeScalarCall(C_GossipInfo.GetOptions) end }
  end

  ---@type table<string, boolean>
  local scalarFunctions = {
    GetNumGossipAvailableQuests = true,
    GetNumGossipActiveQuests = true,
    GetGreetingText = true,
    GetNumActiveQuests = true,
    GetNumAvailableQuests = true,
    GetQuestID = true,
    GetTitleText = true,
    GetQuestText = true,
    GetObjectiveText = true,
    GetProgressText = true,
    GetRewardText = true,
    GetRewardXP = true,
    IsQuestCompletable = true,
    GetNumQuestChoices = true,
  }

  for functionName in pairs(scalarFunctions) do
    local fn = _G[functionName]
    if type(fn) == "function" then
      EnsureFlatStream(functionName)
      defs[#defs + 1] = { key = functionName, getter = function() return SafeScalarCall(fn) end }
    end
  end

  ---@type table<string, boolean>
  local packedFunctions = {
    GetGossipAvailableQuests = true,
    GetGossipActiveQuests = true,
  }

  for functionName in pairs(packedFunctions) do
    local fn = _G[functionName]
    if type(fn) == "function" then
      EnsureFlatStream(functionName)
      defs[#defs + 1] = { key = functionName, getter = function() return SafePackedCall(fn) end }
    end
  end

  return defs
end

---@type QuestDialogStreamDef[]
local flatStreamDefs

-- Inactive-state policy for close events. Each group writes the shape callers
-- expect outside a dialog instead of letting the last open-dialog value linger.
---@type table<string, boolean>
local tableResetStreams = {
  ["C_GossipInfo.GetOptions"] = true,
}

---@type table<string, boolean>
local zeroResetStreams = {
  ["C_GossipInfo.GetNumAvailableQuests"] = true,
  ["C_GossipInfo.GetNumActiveQuests"] = true,
  GetNumGossipAvailableQuests = true,
  GetNumGossipActiveQuests = true,
  GetNumActiveQuests = true,
  GetNumAvailableQuests = true,
  GetNumQuestChoices = true,
  GetQuestID = true,
}

---@type table<string, boolean>
local nilResetStreams = {
  ["C_GossipInfo.GetText"] = true,
  GetGreetingText = true,
  GetTitleText = true,
  GetQuestText = true,
  GetObjectiveText = true,
  GetProgressText = true,
  GetRewardText = true,
  GetRewardXP = true,
}

---@type table<string, boolean>
local emptyPackedResetStreams = {
  GetGossipAvailableQuests = true,
  GetGossipActiveQuests = true,
}

---Append an inactive value to a parameterless stream, but only if that stream exists.
---@param t number
---@param tp number
---@param key string
---@param value any
local function ResetFlatStream(t, tp, key, value)
  if not availableFlatStreams[key] then return end

  local stream = functions[key]
  ---@cast stream FunctionStreamEntry[]
  AppendIfChanged(stream, t, tp, key, value)
end

---Append deterministic inactive dialog state after close/finish events.
---Close events are hard boundaries for transient NPC UI state. The token bump
---cancels any delayed samples scheduled by the open/update event so stale API
---values cannot be reintroduced after these tombstones.
---@param t number
---@param tp number
local function ResetInactiveDialogState(t, tp)
  delayedSampleToken = delayedSampleToken + 1

  for key in pairs(tableResetStreams) do
    ResetFlatStream(t, tp, key, {})
  end
  for key in pairs(zeroResetStreams) do
    ResetFlatStream(t, tp, key, 0)
  end
  for key in pairs(nilResetStreams) do
    ResetFlatStream(t, tp, key, nil)
  end
  for key in pairs(emptyPackedResetStreams) do
    ResetFlatStream(t, tp, key, { n = 0 })
  end
  ResetFlatStream(t, tp, "IsQuestCompletable", false)

  for index, stream in pairs(activeTitleStreams) do
    AppendIfChanged(stream, t, tp, "GetActiveTitle:" .. index, nil)
  end
  for index, stream in pairs(availableTitleStreams) do
    AppendIfChanged(stream, t, tp, "GetAvailableTitle:" .. index, nil)
  end
  previousActiveTitleCount = 0
  previousAvailableTitleCount = 0
end

---Return whether an event closes transient dialog/gossip state.
---@param event string
---@return boolean
local function IsCloseEvent(event)
  return event == "GOSSIP_CLOSED" or event == "QUEST_FINISHED"
end

---Sample indexed greeting title APIs and reset stale indices when counts shrink.
---@param t number
---@param tp number
local function SampleTitleStreams(t, tp)
  if type(GetNumActiveQuests) == "function" and type(GetActiveTitle) == "function" then
    local ok, count = SafeScalarCall(GetNumActiveQuests)
    if ok and type(count) == "number" then
      for index = 1, count do
        local titleOk, titleData = SafePackedIndexCall(GetActiveTitle, index)
        if titleOk then
          local stream = GetOrCreateIndexStream("GetActiveTitle", index)
          activeTitleStreams[index] = stream
          AppendIfChanged(stream, t, tp, "GetActiveTitle:" .. index, titleData)
        end
      end
      for index = count + 1, previousActiveTitleCount do
        local stream = activeTitleStreams[index]
        if stream then
          AppendIfChanged(stream, t, tp, "GetActiveTitle:" .. index, nil)
        end
      end
      previousActiveTitleCount = count
    end
  end

  if type(GetNumAvailableQuests) == "function" and type(GetAvailableTitle) == "function" then
    local ok, count = SafeScalarCall(GetNumAvailableQuests)
    if ok and type(count) == "number" then
      for index = 1, count do
        local titleOk, title = SafeScalarIndexCall(GetAvailableTitle, index)
        if titleOk then
          local stream = GetOrCreateIndexStream("GetAvailableTitle", index)
          availableTitleStreams[index] = stream
          AppendIfChanged(stream, t, tp, "GetAvailableTitle:" .. index, title)
        end
      end
      for index = count + 1, previousAvailableTitleCount do
        local stream = availableTitleStreams[index]
        if stream then
          AppendIfChanged(stream, t, tp, "GetAvailableTitle:" .. index, nil)
        end
      end
      previousAvailableTitleCount = count
    end
  end
end

---Sample all quest-dialog streams.
---@param capture CaptureState
---@return number t Session-relative GetTime()
---@return number tp Session-relative GetTimePreciseSec()
local function SampleQuestDialog(capture)
  local t = GetTime() - capture.startedAt
  local tp = GetTimePreciseSec() - capture.startedAtPrecise

  for i = 1, #flatStreamDefs do
    SampleFlatStream(t, tp, flatStreamDefs[i])
  end
  SampleTitleStreams(t, tp)

  return t, tp
end

---Schedule staggered re-samples to catch dialog state settling after events.
---Quest and gossip frames may expose incomplete values in the event call stack;
---the token ties callbacks to the latest open/update event and lets close events
---invalidate all pending delayed reads.
---@param capture CaptureState
local function ScheduleDelayedSamples(capture)
  delayedSampleToken = delayedSampleToken + 1
  local sampleToken = delayedSampleToken
  local token = capture.token
  for i = 1, #SAMPLE_DELAYS do
    local delay = SAMPLE_DELAYS[i]
    if delay > 0 then
      C_After(delay, function()
        if not capture.active or capture.token ~= token or delayedSampleToken ~= sampleToken then return end
        SampleQuestDialog(capture)
      end)
    end
  end
end

Core.RegisterTracker({
  events = {
    "QUEST_DETAIL",
    "QUEST_PROGRESS",
    "QUEST_COMPLETE",
    "QUEST_FINISHED",
    "QUEST_GREETING",
    "QUEST_ACCEPT_CONFIRM",
    "GOSSIP_SHOW",
    "GOSSIP_CLOSED",
  },

  ---@param capture CaptureState
  Init = function(capture)
    functions = capture.session.functions
    previousValues = {}
    availableFlatStreams = {}
    activeTitleStreams = {}
    availableTitleStreams = {}
    previousActiveTitleCount = 0
    previousAvailableTitleCount = 0
    delayedSampleToken = 0
    flatStreamDefs = BuildFlatStreamDefs()

    SampleQuestDialog(capture)
    ScheduleDelayedSamples(capture)
  end,

  ---@param capture CaptureState
  ---@param event string
  OnEvent = function(capture, event)
    local t, tp = SampleQuestDialog(capture)
    if IsCloseEvent(event) then
      -- Do not schedule more reads after a close boundary; reset writes are the
      -- authoritative inactive state until a new dialog/gossip event opens UI.
      ResetInactiveDialogState(t, tp)
      return
    end
    ScheduleDelayedSamples(capture)
  end,
})
