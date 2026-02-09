---@class QuestLog
QuestLog = select(2, ...)

QuestLogTraceCore = QuestLogTraceCore or {}
local Core = QuestLogTraceCore

local ADDON_NAME = "QuestLogTrace"
local SCHEMA_VERSION = 2
local DEFAULT_MAX_SESSIONS = 20
local SAMPLE_DELAYS = { 0, 0.10, 0.35, 0.55, 0.75, 1.00 }

local capture = {
  active = false,
  token = 0,
  current = nil,
}

local TRACKED_EVENT_CATEGORIES = {
  {
    name = "quest_state",
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
  },
  {
    name = "quest_dialog",
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
  },
  {
    name = "player_state",
    events = {
      "PLAYER_LOGIN",
      "PLAYER_ENTERING_WORLD",
      "PLAYER_ALIVE",
      "PLAYER_LEVEL_UP",
      "MODIFIER_STATE_CHANGED",
      "PLAYER_REGEN_DISABLED",
      "PLAYER_REGEN_ENABLED",
      "PLAYER_STARTED_MOVING",
      "PLAYER_STOPPED_MOVING",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_EQUIPMENT_CHANGED",
      "LOOT_OPENED",
      "NEW_RECIPE_LEARNED",
      "UI_INFO_MESSAGE",
    },
  },
  {
    name = "map_zone",
    events = {
      "ZONE_CHANGED",
      "ZONE_CHANGED_NEW_AREA",
      "ZONE_CHANGED_INDOORS",
      "MAP_EXPLORATION_UPDATED",
      "PLAYER_MAP_CHANGED",
      "WORLD_MAP_OPEN",
      "AREA_POIS_UPDATED",
      "NEW_WMO_CHUNK",
      "UPDATE_ALL_UI_WIDGETS",
    },
  },
  {
    name = "chat_system",
    events = {
      "CHAT_MSG_SYSTEM",
      "CHAT_MSG_LOOT",
      "CHAT_MSG_MONEY",
      "CHAT_MSG_SKILL",
      "CHAT_MSG_TRADESKILLS",
      "CHAT_MSG_COMBAT_FACTION_CHANGE",
      "CHAT_MSG_COMBAT_XP_GAIN",
    },
  },
  {
    name = "group_world",
    events = {
      "GROUP_JOINED",
      "GROUP_LEFT",
      "NAME_PLATE_UNIT_ADDED",
      "NAME_PLATE_UNIT_REMOVED",
      "ACHIEVEMENT_EARNED",
      "TRACKED_ACHIEVEMENT_LIST_CHANGED",
      "TRACKED_ACHIEVEMENT_UPDATE",
      "CRITERIA_UPDATE",
    },
  },
  {
    name = "inventory",
    events = {
      "BAG_UPDATE",
      "BAG_UPDATE_DELAYED",
      "ITEM_PUSH",
      "ITEM_LOCK_CHANGED",
      "ITEM_COUNT_CHANGED",
    },
  },
}

local TRACKED_EVENTS = {}
local EVENT_CATEGORY_BY_EVENT = {}
do
  for _, category in ipairs(TRACKED_EVENT_CATEGORIES) do
    for _, event in ipairs(category.events) do
      if not EVENT_CATEGORY_BY_EVENT[event] then
        EVENT_CATEGORY_BY_EVENT[event] = category.name
        TRACKED_EVENTS[#TRACKED_EVENTS + 1] = event
      end
    end
  end
end
Core.TRACKED_EVENT_CATEGORIES = TRACKED_EVENT_CATEGORIES

local playerStaticInfo = nil
local playerInfoRetryScheduled = false

local function Trim(s)
  if type(s) ~= "string" then
    return ""
  end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function CountTableKeys(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

local function ShallowCopyTable(input)
  if type(input) ~= "table" then
    return nil
  end

  local out = {}
  for k, v in pairs(input) do
    out[k] = v
  end
  return out
end

local function safePack(...)
  local tbl = { ... }
  tbl.n = select("#", ...)
  return tbl
end

local function CopyPackedArgs(args)
  if type(args) ~= "table" then
    return { n = 0 }
  end

  local out = {}
  local n = args.n or #args
  for i = 1, n do
    out[i] = args[i]
  end
  out.n = n
  return out
end

local function GetTraceCollection()
  if QLTrace and QLTrace.logDataProvider and QLTrace.logDataProvider.collection then
    return QLTrace.logDataProvider.collection
  end
  return nil
end

local function GetTraceCount()
  local collection = GetTraceCollection()
  if not collection then
    return 0
  end
  return #collection
end

local function EnsureSavedVariables()
  local globalDb = QuestLogTrace
  if type(globalDb) ~= "table" or globalDb.schemaVersion ~= SCHEMA_VERSION then
    QuestLogTrace = {
      schemaVersion = SCHEMA_VERSION,
      settings = {
        maxSessions = DEFAULT_MAX_SESSIONS,
      },
    }
  end

  QuestLogTrace.settings = type(QuestLogTrace.settings) == "table" and QuestLogTrace.settings or {}

  if type(QuestLogTrace.settings.maxSessions) ~= "number" or QuestLogTrace.settings.maxSessions < 1 then
    QuestLogTrace.settings.maxSessions = DEFAULT_MAX_SESSIONS
  end

  QuestLogTraceCharacter = type(QuestLogTraceCharacter) == "table" and QuestLogTraceCharacter or {}
  QuestLogTraceCharacter.sessions = type(QuestLogTraceCharacter.sessions) == "table" and QuestLogTraceCharacter.sessions or {}
end

local function CapturePlayerStaticInfo()
  local raceLocalized, raceEnglish, raceID = UnitRace("player")
  local classLocalized, classEnglish, classID = UnitClass("player")
  local sex = UnitSex("player")

  if not raceEnglish or not classEnglish or not sex or sex == 0 then
    return false
  end

  playerStaticInfo = {
    race = raceEnglish,
    raceLocalized = raceLocalized,
    raceID = raceID,
    class = classEnglish,
    classLocalized = classLocalized,
    classID = classID,
    sex = sex,
  }

  QuestLogTraceCharacter.player = ShallowCopyTable(playerStaticInfo)
  return true
end

local function EnsurePlayerStaticInfo(attempt)
  if playerStaticInfo then
    playerInfoRetryScheduled = false
    return
  end

  if CapturePlayerStaticInfo() then
    playerInfoRetryScheduled = false
    return
  end

  local currentAttempt = attempt or 1
  if currentAttempt >= 50 then
    playerInfoRetryScheduled = false
    print(ADDON_NAME, "Unable to resolve player race/class/sex yet.")
    return
  end

  if playerInfoRetryScheduled then
    return
  end

  playerInfoRetryScheduled = true
  C_After(0.20, function()
    playerInfoRetryScheduled = false
    EnsurePlayerStaticInfo(currentAttempt + 1)
  end)
end

local function BuildPositionState()
  local mapID = C_Map.GetBestMapForUnit("player")
  local x, y = nil, nil
  if mapID then
    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if position then
      x, y = position:GetXY()
    end
  end

  return {
    m = mapID,
    x = x,
    y = y,
    l = UnitLevel("player"),
    z = GetZoneText(),
    sz = GetSubZoneText(),
    rz = GetRealZoneText(),
  }
end

local function IsSamePositionState(lhs, rhs)
  if not lhs or not rhs then
    return false
  end

  return lhs.m == rhs.m and
      lhs.x == rhs.x and
      lhs.y == rhs.y and
      lhs.l == rhs.l and
      lhs.z == rhs.z and
      lhs.sz == rhs.sz and
      lhs.rz == rhs.rz
end

local function CapturePlayerPosition(eventName, delay, eventCategory)
  if not capture.active or not capture.current then
    return nil
  end

  local state = BuildPositionState()
  local lastIndex = capture.current.lastPositionSampleIndex
  local lastSample = lastIndex and capture.current.positionSamples[lastIndex] or nil

  if lastSample and IsSamePositionState(lastSample, state) then
    return lastIndex
  end

  local sample = {
    t = GetTime() - capture.current.startedAt,
    e = eventName,
    c = eventCategory,
    d = delay or 0,
    m = state.m,
    x = state.x,
    y = state.y,
    l = state.l,
    z = state.z,
    sz = state.sz,
    rz = state.rz,
  }

  table.insert(capture.current.positionSamples, sample)
  local newIndex = #capture.current.positionSamples
  capture.current.lastPositionSampleIndex = newIndex
  return newIndex
end

local function SerializeTraceEvents(startLogIndex, endLogIndex)
  local collection = GetTraceCollection()
  if not collection then
    return {}, {}
  end

  local dict = {}
  local dictMap = {}
  local rows = {}

  local firstIndex = math.max((startLogIndex or 0) + 1, 1)
  local lastIndex = math.min(endLogIndex or #collection, #collection)
  local firstRelativeTimestamp = nil

  for index = firstIndex, lastIndex do
    local eventData = collection[index]
    if eventData and eventData.event then
      local eventName = eventData.event
      local eventId = dictMap[eventName]
      if not eventId then
        eventId = #dict + 1
        dict[eventId] = eventName
        dictMap[eventName] = eventId
      end

      local relativeTimestamp = eventData.relativeTimestamp or 0
      if firstRelativeTimestamp == nil then
        firstRelativeTimestamp = relativeTimestamp
      end

      rows[#rows + 1] = {
        i = eventData.id or index,
        e = eventId,
        t = relativeTimestamp - firstRelativeTimestamp,
        f = eventData.frameCounter or 0,
        a = CopyPackedArgs(eventData.args),
      }
    end
  end

  return rows, dict
end

local function PruneSessionsIfNeeded()
  local maxSessions = QuestLogTrace.settings.maxSessions
  local sessions = QuestLogTraceCharacter.sessions
  while #sessions > maxSessions do
    table.remove(sessions, 1)
  end
end

local function CreateSessionName(override)
  local candidate = Trim(override)
  if candidate ~= "" then
    return candidate
  end
  return date("%Y-%m-%d_%H-%M-%S")
end

local function GetCurrentCapturedEventCount()
  if not capture.current then
    return 0
  end

  local start = capture.current.startLogIndex or 0
  local finish = capture.current.endLogIndex or GetTraceCount()
  if finish < start then
    return 0
  end

  return finish - start
end

function Core.GetStatusData()
  return {
    isRunning = capture.active,
    sessionName = capture.current and (capture.current.name or "(unnamed)") or "None",
    eventCount = GetCurrentCapturedEventCount(),
    snapshotCount = (Core.GetQuestSnapshotCount and Core.GetQuestSnapshotCount()) or 0,
    canSave = capture.current ~= nil,
  }
end

function Core.StartCapture(sessionName)
  if capture.active then
    print(ADDON_NAME, "Capture already running.")
    return
  end

  capture.token = capture.token + 1
  local token = capture.token

  if Core.ResetStateTracking then
    Core.ResetStateTracking()
  end

  capture.current = {
    token = token,
    name = Trim(sessionName) ~= "" and Trim(sessionName) or nil,
    startedAt = GetTime(),
    startLogIndex = GetTraceCount(),
    endLogIndex = nil,
    questEvents = {},
    positionSamples = {},
    lastPositionSampleIndex = nil,
    levelEvents = {},
    player = ShallowCopyTable(playerStaticInfo),
  }
  capture.active = true

  if Core.CaptureQuestState then
    Core.CaptureQuestState()
  end
  CapturePlayerPosition("CAPTURE_START", 0, "system")

  C_After(0.20, function()
    if capture.active and capture.current and capture.current.token == token then
      if Core.CaptureQuestState then
        Core.CaptureQuestState()
      end
      CapturePlayerPosition("CAPTURE_START_DELAY", 0.20, "system")
      if Core.UpdateControlFrameStatus then
        Core.UpdateControlFrameStatus()
      end
    end
  end)

  print(ADDON_NAME, "Capture started.")
  if Core.UpdateControlFrameStatus then
    Core.UpdateControlFrameStatus()
  end
end

function Core.StopCapture()
  if not capture.active or not capture.current then
    print(ADDON_NAME, "No active capture to stop.")
    return
  end

  capture.current.stoppedAt = GetTime()
  capture.current.endLogIndex = GetTraceCount()
  capture.active = false

  print(ADDON_NAME, "Capture stopped.")
  if Core.UpdateControlFrameStatus then
    Core.UpdateControlFrameStatus()
  end
end

function Core.SaveCapture(nameOverride)
  if capture.active then
    Core.StopCapture()
  end

  if not capture.current then
    print(ADDON_NAME, "Nothing to save. Start a capture first.")
    return
  end

  local session = capture.current
  local sessionName = CreateSessionName(nameOverride or session.name)
  local stopIndex = session.endLogIndex or GetTraceCount()

  local compactEvents, eventDict = SerializeTraceEvents(session.startLogIndex, stopIndex)
  local questHistory = Core.SerializeQuestHistory and Core.SerializeQuestHistory() or {}
  local questLogHistory = Core.SerializeQuestLogHistory and Core.SerializeQuestLogHistory() or {}
  local completedQuestsHistory = Core.SerializeCompletedQuestsHistory and Core.SerializeCompletedQuestsHistory() or {}

  local record = {
    schemaVersion = SCHEMA_VERSION,
    name = sessionName,
    startedAt = session.startedAt,
    stoppedAt = session.stoppedAt or GetTime(),
    duration = (session.stoppedAt or GetTime()) - session.startedAt,
    trace = {
      eventDict = eventDict,
      events = compactEvents,
      startLogIndex = session.startLogIndex,
      endLogIndex = stopIndex,
    },
    state = {
      questHistory = questHistory,
      questLogHistory = questLogHistory,
      completedQuestsHistory = completedQuestsHistory,
      questEventTriggers = session.questEvents,
      positionSamples = session.positionSamples,
      levelEvents = session.levelEvents,
    },
    player = session.player or ShallowCopyTable(playerStaticInfo),
    summary = {
      eventCount = #compactEvents,
      questCount = CountTableKeys(questHistory),
      questLogSnapshots = #questLogHistory,
      completedQuestSnapshots = #completedQuestsHistory,
      completedQuestCount = (Core.GetLatestCompletedQuestCount and Core.GetLatestCompletedQuestCount()) or 0,
      positionSampleCount = #session.positionSamples,
      levelEventCount = #session.levelEvents,
    },
  }

  QuestLogTraceCharacter.sessions[#QuestLogTraceCharacter.sessions + 1] = record
  QuestLogTraceCharacter.lastSavedSession = sessionName
  QuestLogTraceCharacter.lastSessionSummary = record.summary

  PruneSessionsIfNeeded()

  capture.current = nil
  print(ADDON_NAME, "Saved session:", sessionName, "events:", record.summary.eventCount)
  if Core.UpdateControlFrameStatus then
    Core.UpdateControlFrameStatus()
  end
end

local function ToggleQLTrace()
  if not QLTrace then
    print(ADDON_NAME, "QLTrace frame not loaded yet.")
    return
  end

  QLTrace:SetShown(not QLTrace:IsShown())
end

local function ProcessTrackedEvent(event, ...)
  if not capture.active or not capture.current then
    return
  end

  local eventCategory = EVENT_CATEGORY_BY_EVENT[event] or "uncategorized"
  local triggerRecord = {
    e = event,
    c = eventCategory,
    t = GetTime() - capture.current.startedAt,
    a = CopyPackedArgs(safePack(...)),
    pi = CapturePlayerPosition(event, 0, eventCategory),
  }
  table.insert(capture.current.questEvents, triggerRecord)

  if event == "PLAYER_LEVEL_UP" then
    table.insert(capture.current.levelEvents, {
      t = GetTime() - capture.current.startedAt,
      e = event,
      c = eventCategory,
      l = UnitLevel("player"),
      a = CopyPackedArgs(safePack(...)),
    })
  end

  -- When zero-delay sampling is configured, capture state immediately in this callstack
  -- and still keep the zero-delay timer sample in the loop below.
  local hasZeroDelay = false
  for i = 1, #SAMPLE_DELAYS do
    if SAMPLE_DELAYS[i] == 0 then
      hasZeroDelay = true
      break
    end
  end

  if hasZeroDelay and Core.CaptureQuestState then
    Core.CaptureQuestState()
  end

  local token = capture.current.token
  for i = 1, #SAMPLE_DELAYS do
    local delay = SAMPLE_DELAYS[i]
    C_After(delay, function()
      if capture.active and capture.current and capture.current.token == token then
        if Core.CaptureQuestState then
          Core.CaptureQuestState()
        end
        CapturePlayerPosition(event, delay, eventCategory)
        if Core.UpdateControlFrameStatus then
          Core.UpdateControlFrameStatus()
        end
      end
    end)
  end
end

local function PrintStatus()
  local state = Core.GetStatusData()
  local running = state.isRunning and "running" or "stopped"
  print(ADDON_NAME, "status:", running, "session:", state.sessionName, "events:", state.eventCount, "snapshots:",
    state.snapshotCount)
end

local function PrintHelp()
  print("/qlt start [name] - Start capture")
  print("/qlt stop - Stop active capture")
  print("/qlt save [name] - Save current capture")
  print("/qlt status - Show capture status")
  print("/qlt ui - Toggle control frame")
  print("/qltrace - Toggle QLTrace window")
end

SlashCmdList["QUESTLOGTRACE"] = function(msg)
  local action, argument = strsplit(" ", msg or "", 2)
  action = string.lower(action or "")

  if action == "" or action == "help" then
    PrintHelp()
    return
  end

  if action == "start" then
    Core.StartCapture(argument)
  elseif action == "stop" then
    Core.StopCapture()
  elseif action == "save" then
    Core.SaveCapture(argument)
  elseif action == "status" then
    PrintStatus()
  elseif action == "ui" then
    if Core.ToggleControlFrame then
      Core.ToggleControlFrame()
    end
  else
    print(ADDON_NAME, "Unknown command:", action)
    PrintHelp()
  end
end

SLASH_QUESTLOGTRACE1 = "/questlogtrace"
SLASH_QUESTLOGTRACE2 = "/qlt"

SlashCmdList["QLTRACE"] = function()
  ToggleQLTrace()
end
SLASH_QLTRACE1 = "/qltrace"

local function OnEvent(_, event, ...)
  if event == "VARIABLES_LOADED" then
    EnsureSavedVariables()
    EnsurePlayerStaticInfo(1)
    if Core.BuildControlFrame then
      Core.BuildControlFrame()
    end
    if Core.UpdateControlFrameStatus then
      Core.UpdateControlFrameStatus()
    end
    return
  end

  if event == "PLAYER_LOGIN" then
    EnsurePlayerStaticInfo(1)
  end

  ProcessTrackedEvent(event, ...)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED")
for i = 1, #TRACKED_EVENTS do
  local ok = pcall(eventFrame.RegisterEvent, eventFrame, TRACKED_EVENTS[i])
  if not ok then
    print(ADDON_NAME, "Skipping unsupported event:", TRACKED_EVENTS[i])
  end
end
eventFrame:SetScript("OnEvent", OnEvent)
