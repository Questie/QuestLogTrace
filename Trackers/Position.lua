---@type QuestLogTraceCore
local Core = QuestLogTraceCore
---@type fun(num: number?, decimals: number?): number?
local Round = Core.Round

---------------------------------------------------------------------------
-- WoW API return schemas (for trace analyzer display labels)
---------------------------------------------------------------------------
-- GetZoneText()    -> string text
-- GetSubZoneText() -> string text
-- GetRealZoneText() -> string text
--
-- C_Map.GetBestMapForUnit(unit)              -> number? uiMapID
-- C_Map.GetPlayerMapPosition(uiMapID, unit)  -> vector2? position  -- stored as {x, y}
---------------------------------------------------------------------------

---@type number
local POSITION_DECIMALS = 4
---@type number
local TIMER_INTERVAL = 0.20

-- Stream references (set during Init)
---@type FunctionStreamEntry[], FunctionStreamEntry[], FunctionStreamEntry[]
local streamZone, streamSubZone, streamRealZone
---@type FunctionStreamEntry[], FunctionStreamEntry[]
local streamMapID, streamPosition

--- Sample all position-related data and append changed entries to streams.
---@param capture CaptureState
local function SampleAll(capture)
  ---@type number
  local t  = GetTime()          - capture.startedAt
  ---@type number
  local tp = GetTimePreciseSec() - capture.startedAtPrecise

  -- Zone texts (parameterless)
  ---@type string
  local zone = GetZoneText()
  if not streamZone[#streamZone] or streamZone[#streamZone].v ~= zone then
    streamZone[#streamZone + 1] = { t = t, tp = tp, v = zone }
  end

  ---@type string
  local subZone = GetSubZoneText()
  if not streamSubZone[#streamSubZone] or streamSubZone[#streamSubZone].v ~= subZone then
    streamSubZone[#streamSubZone + 1] = { t = t, tp = tp, v = subZone }
  end

  ---@type string
  local realZone = GetRealZoneText()
  if not streamRealZone[#streamRealZone] or streamRealZone[#streamRealZone].v ~= realZone then
    streamRealZone[#streamRealZone + 1] = { t = t, tp = tp, v = realZone }
  end

  -- Map ID (parameterized by "player")
  ---@type number?
  local mapID = C_Map.GetBestMapForUnit("player")
  ---@type FunctionStreamEntry?
  local prevMap = streamMapID[#streamMapID]
  if not prevMap or prevMap.v ~= mapID then
    streamMapID[#streamMapID + 1] = { t = t, tp = tp, v = mapID }
  end

  -- Position (parameterized by "player")
  ---@type number?, number?
  local x, y = nil, nil
  if mapID then
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then
      x, y = pos:GetXY()
      x = Round(x, POSITION_DECIMALS)
      y = Round(y, POSITION_DECIMALS)
    end
  end

  ---@type FunctionStreamEntry?
  local prevPos = streamPosition[#streamPosition]
  ---@type {x: number, y: number}?
  local posVal = (x and y) and { x = x, y = y } or nil
  ---@type boolean
  local changed = false
  if not prevPos then
    changed = true
  elseif prevPos.v == nil and posVal == nil then
    changed = false
  elseif prevPos.v == nil or posVal == nil then
    changed = true
  else
    changed = prevPos.v.x ~= posVal.x or prevPos.v.y ~= posVal.y
  end

  if changed then
    streamPosition[#streamPosition + 1] = { t = t, tp = tp, v = posVal }
  end
end

--- Schedule a repeating timer to sample position data.
---@param capture CaptureState
local function ScheduleTimer(capture)
  ---@type number
  local token = capture.token
  C_After(TIMER_INTERVAL, function()
    if not capture.active or capture.token ~= token then return end
    SampleAll(capture)
    ScheduleTimer(capture)
  end)
end

---------------------------------------------------------------------------
-- Private movement event frame
-- PLAYER_STARTED_MOVING / PLAYER_STOPPED_MOVING fire frequently. We use
-- them as position sampling triggers but keep them out of the main event
-- stream to avoid bloat.
---------------------------------------------------------------------------

---@type CaptureState?
local captureRef

---@type Frame
local movementFrame = CreateFrame("Frame")
movementFrame:RegisterEvent("PLAYER_STARTED_MOVING")
movementFrame:RegisterEvent("PLAYER_STOPPED_MOVING")
movementFrame:SetScript("OnEvent", function()
  if not captureRef or not captureRef.active then return end
  SampleAll(captureRef)
end)

Core.RegisterTracker({
  events = {
    "ZONE_CHANGED",
    "ZONE_CHANGED_NEW_AREA",
    "ZONE_CHANGED_INDOORS",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_ALIVE",
    "MAP_EXPLORATION_UPDATED",
    "PLAYER_MAP_CHANGED",
    "AREA_POIS_UPDATED",
    "NEW_WMO_CHUNK",
    "SPELLS_CHANGED",
  },

  ---@param capture CaptureState
  Init = function(capture)
    captureRef = capture

    ---@type table<string, FunctionStreamEntry[]|table<string|number, FunctionStreamEntry[]>>
    local functions = capture.session.functions

    functions["GetZoneText"]    = {}
    functions["GetSubZoneText"] = {}
    functions["GetRealZoneText"] = {}
    functions["C_Map.GetBestMapForUnit"]    = { ["player"] = {} }
    functions["C_Map.GetPlayerMapPosition"] = { ["player"] = {} }

    streamZone     = functions["GetZoneText"]
    streamSubZone  = functions["GetSubZoneText"]
    streamRealZone = functions["GetRealZoneText"]
    streamMapID    = functions["C_Map.GetBestMapForUnit"]["player"]
    streamPosition = functions["C_Map.GetPlayerMapPosition"]["player"]

    -- Initial sample at t=0
    SampleAll(capture)

    -- Start repeating timer
    ScheduleTimer(capture)
  end,

  ---@param capture CaptureState
  OnEvent = function(capture)
    SampleAll(capture)
  end,

  ---@param capture CaptureState
  OnCaptureStopped = function(capture)
    SampleAll(capture)
    captureRef = nil
  end,
})
