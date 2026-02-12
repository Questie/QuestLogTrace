---@type QuestLogTraceCore
local Core = QuestLogTraceCore

---@type FunctionStreamEntry[]? Shortcut to functions["UnitLevel"]["player"]
local stream

Core.RegisterTracker({
  events = { "PLAYER_LEVEL_UP" },

  ---@param capture CaptureState
  Init = function(capture)
    ---@type number
    local level = UnitLevel("player")
    ---@type table<string, FunctionStreamEntry[]|table<string|number, FunctionStreamEntry[]>>
    local functions = capture.session.functions
    functions["UnitLevel"] = {
      ["player"] = { { t = 0, tp = 0, v = level } },
    }
    stream = functions["UnitLevel"]["player"]
  end,

  ---@param capture CaptureState
  ---@param event string
  ---@param ... any
  OnEvent = function(capture, event, ...)
    if not stream then return end
    ---@type number
    local level = UnitLevel("player")
    ---@type FunctionStreamEntry?
    local prev = stream[#stream]
    if prev and prev.v == level then return end

    ---@type number
    local t  = GetTime()          - capture.startedAt
    ---@type number
    local tp = GetTimePreciseSec() - capture.startedAtPrecise
    stream[#stream + 1] = { t = t, tp = tp, v = level }
  end,
})
