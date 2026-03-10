---@type QuestLogTraceCore
local Core = QuestLogTraceCore
---@type fun(...): PackedArgs
local PackArgs = Core.PackArgs

---------------------------------------------------------------------------
-- WoW API return schemas (for trace analyzer display labels)
---------------------------------------------------------------------------
-- GetSpellBookItemName(slot, "spell") -> string spellName,
--                                        string spellSubName,
--                                        number spellID
--
-- GetSpellBookItemInfo(slot, "spell") -> string spellType,
--                                        number id
--
-- IsPassiveSpell(slot, "spell") -> 1|nil isPassive
--
-- SpellBook (custom stream) -> number[] spellIDs  -- ordered known spell IDs
--
-- PlayerKnownSpells (delta stream) -> set<number> spellIDs
---------------------------------------------------------------------------

---@type string
local BOOK_TYPE = "spell"

---@type table<string, FunctionStreamEntry[]|table<string|number, FunctionStreamEntry[]>>
local functions
---@type table<string, DeltaStream>
local functionsDelta
---@type table<number, PackedArgs?>
local prevName
---@type table<number, PackedArgs?>
local prevInfo
---@type table<number, number?>
local prevPassive
---@type table<number, boolean>
local knownSlots
---@type table<number, boolean>
local currentKnownSpells

--- Append a parameterized packed value only when it changed.
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

--- Append a parameterized scalar only when it changed.
---@param funcName string
---@param key number
---@param prev table<number, number?>
---@param t number
---@param tp number
---@param value number?
local function AppendScalarIfChanged(funcName, key, prev, t, tp, value)
  local old = prev[key]
  local stream = functions[funcName][key]
  local hasEntries = stream ~= nil and #stream > 0
  if old == value and hasEntries then return end

  if not stream then
    stream = {}
    functions[funcName][key] = stream
  end
  stream[#stream + 1] = { t = t, tp = tp, v = value }
  prev[key] = value
end

--- Append the ordered spell list when it changed.
---@param t number
---@param tp number
---@param ids number[]
local function AppendSpellBookIfChanged(t, tp, ids)
  local stream = functions["SpellBook"]
  local prev = stream[#stream]
  if not prev or not DeepCompare(prev.v, ids) then
    local copy = {}
    for i = 1, #ids do
      copy[i] = ids[i]
    end
    stream[#stream + 1] = { t = t, tp = tp, v = copy }
  end
end

--- Diff and append PlayerKnownSpells delta entries.
---@param capture CaptureState
---@param newSet table<number, boolean>
local function AppendKnownSpellDelta(capture, newSet)
  local added, removed = {}, {}
  for spellID in pairs(newSet) do
    if not currentKnownSpells[spellID] then
      added[#added + 1] = spellID
    end
  end
  for spellID in pairs(currentKnownSpells) do
    if not newSet[spellID] then
      removed[#removed + 1] = spellID
    end
  end

  if #added > 0 or #removed > 0 then
    table.sort(added)
    table.sort(removed)

    local delta = {
      t = GetTime() - capture.startedAt,
      tp = GetTimePreciseSec() - capture.startedAtPrecise,
    }
    if #added > 0 then delta.add = added end
    if #removed > 0 then delta.remove = removed end

    functionsDelta["PlayerKnownSpells"].delta[#functionsDelta["PlayerKnownSpells"].delta + 1] = delta
  end

  currentKnownSpells = newSet
end

--- Enumerate the entire player spellbook, including profession tabs.
---@param capture CaptureState
local function SampleSpellBook(capture)
  local t = GetTime() - capture.startedAt
  local tp = GetTimePreciseSec() - capture.startedAtPrecise

  local seenSlots = {}
  local orderedSpellIDs = {}
  local seenSpellIDs = {}
  local newKnownSpells = {}

  if type(GetSpellBookItemName) == "function" then
    local slot = 1
    while true do
      local spellName, spellSubName, spellID = GetSpellBookItemName(slot, BOOK_TYPE)
      if spellName == nil then break end

      seenSlots[slot] = true
      knownSlots[slot] = true

      local nameValue = { spellName, spellSubName, spellID, n = 3 }
      AppendPackedIfChanged("GetSpellBookItemName", slot, prevName, t, tp, nameValue)

      if type(GetSpellBookItemInfo) == "function" then
        local infoValue = PackArgs(GetSpellBookItemInfo(slot, BOOK_TYPE))
        AppendPackedIfChanged("GetSpellBookItemInfo", slot, prevInfo, t, tp, infoValue)
      end

      if type(IsPassiveSpell) == "function" then
        local passiveValue = IsPassiveSpell(slot, BOOK_TYPE)
        AppendScalarIfChanged("IsPassiveSpell", slot, prevPassive, t, tp, passiveValue)
      end

      if type(spellID) == "number" then
        newKnownSpells[spellID] = true
        if not seenSpellIDs[spellID] then
          seenSpellIDs[spellID] = true
          orderedSpellIDs[#orderedSpellIDs + 1] = spellID
        end
      end

      slot = slot + 1
    end
  end

  for slot in pairs(knownSlots) do
    if not seenSlots[slot] then
      AppendPackedIfChanged("GetSpellBookItemName", slot, prevName, t, tp, nil)
      if functions["GetSpellBookItemInfo"] then
        AppendPackedIfChanged("GetSpellBookItemInfo", slot, prevInfo, t, tp, nil)
      end
      if functions["IsPassiveSpell"] then
        AppendScalarIfChanged("IsPassiveSpell", slot, prevPassive, t, tp, nil)
      end
    end
  end

  AppendSpellBookIfChanged(t, tp, orderedSpellIDs)
  AppendKnownSpellDelta(capture, newKnownSpells)
end

Core.RegisterTracker({
  events = {
    "SPELLS_CHANGED",
    "PLAYER_ENTERING_WORLD",
  },

  ---@param capture CaptureState
  Init = function(capture)
    functions = capture.session.functions
    functionsDelta = capture.session.functionsDelta

    functions["SpellBook"] = {}
    functions["GetSpellBookItemName"] = {}
    functions["GetSpellBookItemInfo"] = {}
    functions["IsPassiveSpell"] = {}

    prevName = {}
    prevInfo = {}
    prevPassive = {}
    knownSlots = {}

    ---@type table<number, boolean>
    local initialKnownSpells = {}
    currentKnownSpells = initialKnownSpells
    functionsDelta["PlayerKnownSpells"] = {
      t = 0,
      tp = 0,
      initial = {},
      delta = {},
    }

    SampleSpellBook(capture)
    functionsDelta["PlayerKnownSpells"].initial = {}
    for spellID in pairs(currentKnownSpells) do
      functionsDelta["PlayerKnownSpells"].initial[#functionsDelta["PlayerKnownSpells"].initial + 1] = spellID
    end
    table.sort(functionsDelta["PlayerKnownSpells"].initial)
    functionsDelta["PlayerKnownSpells"].delta = {}
  end,

  ---@param capture CaptureState
  OnEvent = function(capture)
    SampleSpellBook(capture)
  end,
})
