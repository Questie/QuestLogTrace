---@type QuestLogTraceCore
local Core = QuestLogTraceCore
---@type fun(...): PackedArgs
local PackArgs = Core.PackArgs

---------------------------------------------------------------------------
-- WoW API return schemas (for trace analyzer display labels)
---------------------------------------------------------------------------
-- GetSpellBookItemName(slot, "spell") -> string name,
--                                        string subName,
--                                        number spellID
--
-- GetSpellBookItemInfo(slot, "spell") -> string spellType,  -- "SPELL", "FUTURESPELL", "PETACTION"
--                                        number id
--
-- IsPassiveSpell(slot, "spell") -> 1|nil isPassive
--
-- C_SpellBook.IsSpellKnown(spellID)             -> boolean isKnown
-- C_SpellBook.IsSpellInSpellBook(spellID)        -> boolean isInSpellBook
-- C_SpellBook.IsSpellKnownOrInSpellBook(spellID) -> boolean isKnownOrInSpellBook
--
-- SpellBook (custom stream) -> number[] spellIDs  -- ordered known spell IDs
---------------------------------------------------------------------------

---@type table<string, FunctionStreamEntry[]|table<string|number, FunctionStreamEntry[]>>
local functions       -- capture.session.functions
---@type number[]
local spellOrder      -- ordered array of discovered spellIDs
---@type table<number, PackedArgs>
local prevName        -- [spellID] -> last PackedArgs(name, subName)
---@type table<number, PackedArgs>
local prevInfo        -- [spellID] -> last PackedArgs(spellType, id)
---@type table<number, boolean>
local prevPassive     -- [spellID] -> last isPassive
---@type table<number, boolean>
local prevKnown       -- [spellID] -> last C_SpellBook.IsSpellKnown
---@type table<number, boolean>
local prevInBook      -- [spellID] -> last C_SpellBook.IsSpellInSpellBook
---@type table<number, boolean>
local prevKnownOrIn   -- [spellID] -> last C_SpellBook.IsSpellKnownOrInSpellBook

--- Discover all spellIDs by iterating all spellbook tabs.
---@return number[] ids Ordered array of spellIDs
local function CollectSpellIDs()
  if type(GetNumSpellTabs) ~= "function" or type(GetSpellTabInfo) ~= "function"
    or type(GetSpellBookItemName) ~= "function" then
    return {}
  end

  ---@type number[]
  local ids = {}
  ---@type number
  local numTabs = GetNumSpellTabs() or 0

  for tab = 1, numTabs do
    local _, _, offset, numSlots = GetSpellTabInfo(tab)
    if offset and numSlots then
      for i = 1, numSlots do
        ---@type number
        local slot = offset + i
        local _, _, spellID = GetSpellBookItemName(slot, "spell")
        if spellID then
          ids[#ids + 1] = spellID
        end
      end
    end
  end

  return ids
end

--- Sample all per-spell functions. Appends {t,tp,v} only when value changed.
---@param capture CaptureState
local function SampleSpells(capture)
  ---@type number
  local t  = GetTime()          - capture.startedAt
  ---@type number
  local tp = GetTimePreciseSec() - capture.startedAtPrecise

  for i = 1, #spellOrder do
    ---@type number
    local spellID = spellOrder[i]

    -- GetSpellBookItemName
    if type(GetSpellBookItemName) == "function" then
      ---@type PackedArgs
      local v = PackArgs(GetSpellBookItemName(spellID))
      ---@type PackedArgs?
      local prev = prevName[spellID]
      if not prev or not DeepCompare(v, prev) then
        ---@type FunctionStreamEntry[]
        local stream = functions["GetSpellBookItemName"][spellID]
        if not stream then
          stream = {}
          functions["GetSpellBookItemName"][spellID] = stream
        end
        stream[#stream + 1] = { t = t, tp = tp, v = v }
        prevName[spellID] = v
      end
    end

    -- GetSpellBookItemInfo
    if type(GetSpellBookItemInfo) == "function" then
      ---@type PackedArgs
      local v = PackArgs(GetSpellBookItemInfo(spellID))
      ---@type PackedArgs?
      local prev = prevInfo[spellID]
      if not prev or not DeepCompare(v, prev) then
        ---@type FunctionStreamEntry[]
        local stream = functions["GetSpellBookItemInfo"][spellID]
        if not stream then
          stream = {}
          functions["GetSpellBookItemInfo"][spellID] = stream
        end
        stream[#stream + 1] = { t = t, tp = tp, v = v }
        prevInfo[spellID] = v
      end
    end

    -- IsPassiveSpell
    if type(IsPassiveSpell) == "function" then
      ---@type boolean
      local v = IsPassiveSpell(spellID) == 1
      ---@type boolean?
      local prev = prevPassive[spellID]
      if prev == nil or prev ~= v then
        ---@type FunctionStreamEntry[]
        local stream = functions["IsPassiveSpell"][spellID]
        if not stream then
          stream = {}
          functions["IsPassiveSpell"][spellID] = stream
        end
        stream[#stream + 1] = { t = t, tp = tp, v = v }
        prevPassive[spellID] = v
      end
    end

    -- C_SpellBook.IsSpellKnown
    if type(C_SpellBook) == "table" and type(C_SpellBook.IsSpellKnown) == "function" then
      ---@type boolean
      local v = C_SpellBook.IsSpellKnown(spellID) and true or false
      ---@type boolean?
      local prev = prevKnown[spellID]
      if prev == nil or prev ~= v then
        ---@type FunctionStreamEntry[]
        local stream = functions["C_SpellBook.IsSpellKnown"][spellID]
        if not stream then
          stream = {}
          functions["C_SpellBook.IsSpellKnown"][spellID] = stream
        end
        stream[#stream + 1] = { t = t, tp = tp, v = v }
        prevKnown[spellID] = v
      end
    end

    -- C_SpellBook.IsSpellInSpellBook
    if type(C_SpellBook) == "table" and type(C_SpellBook.IsSpellInSpellBook) == "function" then
      ---@type boolean
      local v = C_SpellBook.IsSpellInSpellBook(spellID) and true or false
      ---@type boolean?
      local prev = prevInBook[spellID]
      if prev == nil or prev ~= v then
        ---@type FunctionStreamEntry[]
        local stream = functions["C_SpellBook.IsSpellInSpellBook"][spellID]
        if not stream then
          stream = {}
          functions["C_SpellBook.IsSpellInSpellBook"][spellID] = stream
        end
        stream[#stream + 1] = { t = t, tp = tp, v = v }
        prevInBook[spellID] = v
      end
    end

    -- C_SpellBook.IsSpellKnownOrInSpellBook
    if type(C_SpellBook) == "table" and type(C_SpellBook.IsSpellKnownOrInSpellBook) == "function" then
      ---@type boolean
      local v = C_SpellBook.IsSpellKnownOrInSpellBook(spellID) and true or false
      ---@type boolean?
      local prev = prevKnownOrIn[spellID]
      if prev == nil or prev ~= v then
        ---@type FunctionStreamEntry[]
        local stream = functions["C_SpellBook.IsSpellKnownOrInSpellBook"][spellID]
        if not stream then
          stream = {}
          functions["C_SpellBook.IsSpellKnownOrInSpellBook"][spellID] = stream
        end
        stream[#stream + 1] = { t = t, tp = tp, v = v }
        prevKnownOrIn[spellID] = v
      end
    end
  end
end

--- Full collection + sample. Updates SpellBook membership if the set changed.
---@param capture CaptureState
local function CollectAndSample(capture)
  ---@type number[]
  local ids = CollectSpellIDs()

  -- Update SpellBook stream if changed
  ---@type FunctionStreamEntry[]
  local orderStream = functions["SpellBook"]
  ---@type FunctionStreamEntry?
  local prevOrder = orderStream[#orderStream]
  if not prevOrder or not DeepCompare(prevOrder.v, ids) then
    ---@type number
    local t  = GetTime()          - capture.startedAt
    ---@type number
    local tp = GetTimePreciseSec() - capture.startedAtPrecise
    ---@type number[]
    local copy = {}
    for i = 1, #ids do copy[i] = ids[i] end
    orderStream[#orderStream + 1] = { t = t, tp = tp, v = copy }
  end

  spellOrder = ids
  SampleSpells(capture)
end

Core.RegisterTracker({
  events = {
    "SPELLS_CHANGED",
    "LEARNED_SPELL_IN_TAB",
    "PLAYER_ENTERING_WORLD",
  },

  ---@param capture CaptureState
  Init = function(capture)
    functions = capture.session.functions
    functions["SpellBook"]                            = {}
    functions["GetSpellBookItemName"]                 = {}
    functions["GetSpellBookItemInfo"]                 = {}
    functions["IsPassiveSpell"]                       = {}
    functions["C_SpellBook.IsSpellKnown"]             = {}
    functions["C_SpellBook.IsSpellInSpellBook"]       = {}
    functions["C_SpellBook.IsSpellKnownOrInSpellBook"] = {}
    prevName    = {}
    prevInfo    = {}
    prevPassive = {}
    prevKnown   = {}
    prevInBook  = {}
    prevKnownOrIn = {}
    spellOrder  = {}

    CollectAndSample(capture)
  end,

  ---@param capture CaptureState
  OnEvent = function(capture)
    CollectAndSample(capture)
  end,
})
