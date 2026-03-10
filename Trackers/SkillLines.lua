---@type QuestLogTraceCore
local Core = QuestLogTraceCore
---@type fun(...): PackedArgs
local PackArgs = Core.PackArgs

---------------------------------------------------------------------------
-- WoW API return schemas (for trace analyzer display labels)
---------------------------------------------------------------------------
-- GetNumSkillLines() -> number numberOfSkillLines
--
-- GetSkillLineInfo(index) -> string skillName,
--                            number header,
--                            number isExpanded,
--                            number skillRank,
--                            number numTempPoints,
--                            number skillModifier,
--                            number skillMaxRank,
--                            number isAbandonable,
--                            number stepCost,
--                            number rankCost,
--                            number minLevel,
--                            number skillCostType,
--                            string skillDescription
--
-- GetProfessions() -> number prof1,
--                     number prof2,
--                     number archaeology,
--                     number fishing,
--                     number cooking
--
-- GetProfessionInfo(index) -> string name,
--                             string icon,
--                             number skillLevel,
--                             number maxSkillLevel,
--                             number numAbilities,
--                             number spelloffset,
--                             number skillLine,
--                             number skillModifier,
--                             number specializationIndex,
--                             number specializationOffset
---------------------------------------------------------------------------

---@type table<string, FunctionStreamEntry[]|table<string|number, FunctionStreamEntry[]>>
local functions
---@type FunctionStreamEntry[]?
local streamNumSkillLines
---@type FunctionStreamEntry[]?
local streamProfessions
---@type table<number, PackedArgs?>
local prevSkillLineInfo
---@type table<number, PackedArgs?>
local prevProfessionInfo
---@type table<number, boolean>
local knownSkillLineIndices
---@type table<number, boolean>
local knownProfessionIndices
---@type boolean
local expandingSkillHeaders

--- Expand all skill headers so all visible rows can be sampled.
local function ExpandAllSkillHeaders()
  if type(ExpandSkillHeader) ~= "function" then return end

  expandingSkillHeaders = true
  ExpandSkillHeader(0)
  expandingSkillHeaders = false
end

--- Append a value to a parameterized stream only when it changed.
---@param funcName string
---@param key number
---@param prev table<number, PackedArgs?>
---@param t number
---@param tp number
---@param value PackedArgs?
local function AppendPackedIfChanged(funcName, key, prev, t, tp, value)
  local old = prev[key]
  local changed = false

  if old == nil and value == nil then
    changed = functions[funcName][key] == nil or #functions[funcName][key] == 0
  elseif old == nil or value == nil then
    changed = true
  else
    changed = not DeepCompare(old, value)
  end

  if not changed then return end

  local stream = functions[funcName][key]
  if not stream then
    stream = {}
    functions[funcName][key] = stream
  end
  stream[#stream + 1] = { t = t, tp = tp, v = value }
  prev[key] = value
end

--- Append a scalar to a parameterless stream when it changed.
---@param stream FunctionStreamEntry[]
---@param t number
---@param tp number
---@param value number
local function AppendScalarIfChanged(stream, t, tp, value)
  local prev = stream[#stream]
  if not prev or prev.v ~= value then
    stream[#stream + 1] = { t = t, tp = tp, v = value }
  end
end

--- Append a tuple to a parameterless stream when it changed.
---@param stream FunctionStreamEntry[]
---@param t number
---@param tp number
---@param value PackedArgs
local function AppendTupleIfChanged(stream, t, tp, value)
  local prev = stream[#stream]
  if not prev or not DeepCompare(prev.v, value) then
    stream[#stream + 1] = { t = t, tp = tp, v = value }
  end
end

--- Sample the skill window and profession APIs.
---@param capture CaptureState
local function SampleSkills(capture)
  if not streamNumSkillLines or not streamProfessions then return end

  ExpandAllSkillHeaders()

  ---@type number
  local t = GetTime() - capture.startedAt
  ---@type number
  local tp = GetTimePreciseSec() - capture.startedAtPrecise

  local numSkillLines = type(GetNumSkillLines) == "function" and (GetNumSkillLines() or 0) or 0
  AppendScalarIfChanged(streamNumSkillLines, t, tp, numSkillLines)

  ---@type table<number, boolean>
  local seenSkillLineIndices = {}
  if type(GetSkillLineInfo) == "function" then
    for index = 1, numSkillLines do
      local value = PackArgs(GetSkillLineInfo(index))
      seenSkillLineIndices[index] = true
      knownSkillLineIndices[index] = true
      AppendPackedIfChanged("GetSkillLineInfo", index, prevSkillLineInfo, t, tp, value)
    end
  end

  for index in pairs(knownSkillLineIndices) do
    if not seenSkillLineIndices[index] then
      AppendPackedIfChanged("GetSkillLineInfo", index, prevSkillLineInfo, t, tp, nil)
    end
  end

  if type(GetProfessions) == "function" then
    local professions = PackArgs(GetProfessions())
    AppendTupleIfChanged(streamProfessions, t, tp, professions)

    ---@type table<number, boolean>
    local seenProfessionIndices = {}
    if type(GetProfessionInfo) == "function" then
      for i = 1, professions.n do
        local professionIndex = professions[i]
        if type(professionIndex) == "number" then
          seenProfessionIndices[professionIndex] = true
          knownProfessionIndices[professionIndex] = true
          local value = PackArgs(GetProfessionInfo(professionIndex))
          AppendPackedIfChanged("GetProfessionInfo", professionIndex, prevProfessionInfo, t, tp, value)
        end
      end
    end

    for professionIndex in pairs(knownProfessionIndices) do
      if not seenProfessionIndices[professionIndex] then
        AppendPackedIfChanged("GetProfessionInfo", professionIndex, prevProfessionInfo, t, tp, nil)
      end
    end
  end
end

Core.RegisterTracker({
  events = {
    "SKILL_LINES_CHANGED",
    "PLAYER_ENTERING_WORLD",
    "SPELLS_CHANGED",
  },

  ---@param capture CaptureState
  Init = function(capture)
    functions = capture.session.functions
    functions["GetNumSkillLines"] = {}
    functions["GetSkillLineInfo"] = {}
    functions["GetProfessions"] = {}
    functions["GetProfessionInfo"] = {}

    streamNumSkillLines = functions["GetNumSkillLines"]
    streamProfessions = functions["GetProfessions"]
    prevSkillLineInfo = {}
    prevProfessionInfo = {}
    knownSkillLineIndices = {}
    knownProfessionIndices = {}
    expandingSkillHeaders = false

    SampleSkills(capture)
  end,

  ---@param capture CaptureState
  ---@param event string
  OnEvent = function(capture, event)
    if event == "SKILL_LINES_CHANGED" and expandingSkillHeaders then
      return
    end
    SampleSkills(capture)
  end,
})
