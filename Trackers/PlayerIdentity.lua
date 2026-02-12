---@type QuestLogTraceCore
local Core = QuestLogTraceCore

Core.RegisterTracker({
  -- No events -- sampled once at t=0 only

  ---@param capture CaptureState
  Init = function(capture)
    ---@type table<string, FunctionStreamEntry[]|table<string|number, FunctionStreamEntry[]>>
    local functions = capture.session.functions
    ---@type string, string, number
    local raceL, raceE, raceID = UnitRace("player")
    ---@type string, string, number
    local classL, classE, classID = UnitClass("player")
    ---@type number
    local sex = UnitSex("player")

    functions["UnitRace"] = {
      ["player"] = { { t = 0, tp = 0, v = { raceL, raceE, raceID, n = 3 } } },
    }
    functions["UnitClass"] = {
      ["player"] = { { t = 0, tp = 0, v = { classL, classE, classID, n = 3 } } },
    }
    functions["UnitSex"] = {
      ["player"] = { { t = 0, tp = 0, v = sex } },
    }
  end,
})
