---@type QuestLogTraceCore
local Core = QuestLogTraceCore
---@type fun(...): PackedArgs
local PackArgs = Core.PackArgs

---@class LootSlotStreams
---@field info FunctionStreamEntry[]
---@field source FunctionStreamEntry[]
---@field link FunctionStreamEntry[]
---@field type FunctionStreamEntry[]

-- Stream references (set during Init)
---@type table<string, FunctionStreamEntry[]|table<string|number, FunctionStreamEntry[]>>
local functions
---@type table<number, LootSlotStreams>? [slot] -> { info=stream, source=stream, link=stream, type=stream }
local lootSlotStreams

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

--- Sample all loot slots when loot window opens.
---@param capture CaptureState
local function SampleLootOpen(capture)
  if type(GetNumLootItems) ~= "function" then return end

  ---@type number?
  local itemCount = GetNumLootItems()
  if type(itemCount) ~= "number" or itemCount < 1 then return end

  ---@type number
  local t  = GetTime()          - capture.startedAt
  ---@type number
  local tp = GetTimePreciseSec() - capture.startedAtPrecise

  -- GetNumLootItems (parameterless)
  ---@type FunctionStreamEntry[]
  local countStream = functions["GetNumLootItems"]
  ---@type FunctionStreamEntry?
  local prevCount = countStream[#countStream]
  if not prevCount or prevCount.v ~= itemCount then
    countStream[#countStream + 1] = { t = t, tp = tp, v = itemCount }
  end

  -- Per-slot functions
  lootSlotStreams = lootSlotStreams or {}

  for slot = 1, itemCount do
    if not lootSlotStreams[slot] then
      lootSlotStreams[slot] = {
        info   = GetOrCreateParamStream("GetLootSlotInfo", slot),
        source = GetOrCreateParamStream("GetLootSourceInfo", slot),
        link   = GetOrCreateParamStream("GetLootSlotLink", slot),
        type   = GetOrCreateParamStream("GetLootSlotType", slot),
      }
    end
    ---@type LootSlotStreams
    local streams = lootSlotStreams[slot]

    -- GetLootSlotInfo -- tuple
    if type(GetLootSlotInfo) == "function" then
      ---@type PackedArgs
      local v = PackArgs(GetLootSlotInfo(slot))
      streams.info[#streams.info + 1] = { t = t, tp = tp, v = v }
    end

    -- GetLootSourceInfo -- tuple
    if type(GetLootSourceInfo) == "function" then
      ---@type PackedArgs
      local v = PackArgs(GetLootSourceInfo(slot))
      streams.source[#streams.source + 1] = { t = t, tp = tp, v = v }
    end

    -- GetLootSlotLink -- scalar
    if type(GetLootSlotLink) == "function" then
      ---@type string?
      local v = GetLootSlotLink(slot)
      streams.link[#streams.link + 1] = { t = t, tp = tp, v = v }
    end

    -- GetLootSlotType -- scalar
    if type(GetLootSlotType) == "function" then
      ---@type number?
      local v = GetLootSlotType(slot)
      streams.type[#streams.type + 1] = { t = t, tp = tp, v = v }
    end
  end
end

--- Record loot window close by zeroing counts and nil-ing slot streams.
---@param capture CaptureState
local function SampleLootClose(capture)
  ---@type number
  local t  = GetTime()          - capture.startedAt
  ---@type number
  local tp = GetTimePreciseSec() - capture.startedAtPrecise

  -- GetNumLootItems -> 0
  ---@type FunctionStreamEntry[]
  local countStream = functions["GetNumLootItems"]
  ---@type FunctionStreamEntry?
  local prevCount = countStream[#countStream]
  if not prevCount or prevCount.v ~= 0 then
    countStream[#countStream + 1] = { t = t, tp = tp, v = 0 }
  end

  -- All known slots -> nil
  if lootSlotStreams then
    for _, streams in pairs(lootSlotStreams) do
      streams.info[#streams.info + 1]     = { t = t, tp = tp, v = nil }
      streams.source[#streams.source + 1] = { t = t, tp = tp, v = nil }
      streams.link[#streams.link + 1]     = { t = t, tp = tp, v = nil }
      streams.type[#streams.type + 1]     = { t = t, tp = tp, v = nil }
    end
  end
end

Core.RegisterTracker({
  events = { "LOOT_READY", "LOOT_CLOSED" },

  ---@param capture CaptureState
  Init = function(capture)
    functions = capture.session.functions
    functions["GetNumLootItems"] = { { t = 0, tp = 0, v = 0 } }
    lootSlotStreams = nil
  end,

  ---@param capture CaptureState
  ---@param event string
  ---@param ... any
  OnEvent = function(capture, event, ...)
    if event == "LOOT_READY" then
      SampleLootOpen(capture)
    elseif event == "LOOT_CLOSED" then
      SampleLootClose(capture)
    end
  end,
})
