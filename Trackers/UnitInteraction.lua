---@type QuestLogTraceCore
local Core = QuestLogTraceCore
---@type fun(...): PackedArgs
local PackArgs = Core.PackArgs

---------------------------------------------------------------------------
-- WoW API return schemas (for trace analyzer display labels)
---------------------------------------------------------------------------
-- UnitGUID(unit)  -> string guid (or nil)
-- UnitName(unit)  -> string name, string realm (or nil when no unit)
---------------------------------------------------------------------------

---@type string[]
local TOKENS = { "target", "npc", "questnpc" }

-- Stream references (set during Init)
---@type table<string, FunctionStreamEntry[]>?
local guidStreams
---@type table<string, FunctionStreamEntry[]>?
local nameStreams

--- Sample all six streams (UnitGUID + UnitName for each token).
---@param t number Session-relative GetTime()
---@param tp number Session-relative GetTimePreciseSec()
local function SampleAll(t, tp)
  if not guidStreams or not nameStreams then return end

  for _, token in ipairs(TOKENS) do
    -- UnitGUID (scalar string or nil)
    ---@type string?
    local guid = UnitGUID(token)
    ---@type FunctionStreamEntry[]
    local guidStream = guidStreams[token]
    ---@type FunctionStreamEntry?
    local prevGuid = guidStream[#guidStream]
    if not prevGuid or prevGuid.v ~= guid then
      guidStream[#guidStream + 1] = { t = t, tp = tp, v = guid }
    end

    -- UnitName (tuple n=2 or nil)
    ---@type PackedArgs?
    local nameVal = UnitExists(token) and PackArgs(UnitName(token)) or nil
    ---@type FunctionStreamEntry[]
    local nameStream = nameStreams[token]
    ---@type FunctionStreamEntry?
    local prevName = nameStream[#nameStream]
    if not prevName or not DeepCompare(prevName.v, nameVal) then
      nameStream[#nameStream + 1] = { t = t, tp = tp, v = nameVal }
    end
  end
end

Core.RegisterTracker({
  events = {
    -- player_state (already registered)
    "PLAYER_TARGET_CHANGED",
    -- quest_dialog (already registered)
    "QUEST_DETAIL",
    "QUEST_PROGRESS",
    "QUEST_COMPLETE",
    "QUEST_GREETING",
    "QUEST_FINISHED",
    "QUEST_ACCEPT_CONFIRM",
    "GOSSIP_SHOW",
    "GOSSIP_CLOSED",
    -- quest_state (already registered)
    "QUEST_ACCEPTED",
    "QUEST_TURNED_IN",
    -- player_state (already registered)
    "LOOT_OPENED",
    -- npc_interaction (new category)
    "MERCHANT_SHOW",
    "MERCHANT_CLOSED",
    "TRAINER_SHOW",
    "TRAINER_CLOSED",
    "MAIL_SHOW",
    "MAIL_CLOSED",
    "AUCTION_HOUSE_SHOW",
    "AUCTION_HOUSE_CLOSED",
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
    "TAXIMAP_OPENED",
    "TAXIMAP_CLOSED",
    "GUILD_REGISTRAR_SHOW",
    "GUILD_REGISTRAR_CLOSED",
    "PET_STABLE_SHOW",
    "PET_STABLE_CLOSED",
    "BATTLEFIELDS_SHOW",
    "BATTLEFIELDS_CLOSED",
    "PETITION_SHOW",
    "PETITION_CLOSED",
    "GUILDBANKFRAME_OPENED",
    "GUILDBANKFRAME_CLOSED",
    "PLAYER_ENTERING_WORLD",
    "SPELLS_CHANGED",
  },

  ---@param capture CaptureState
  Init = function(capture)
    ---@type table<string, FunctionStreamEntry[]|table<string|number, FunctionStreamEntry[]>>
    local functions = capture.session.functions
    if not functions["UnitGUID"] then functions["UnitGUID"] = {} end
    if not functions["UnitName"] then functions["UnitName"] = {} end

    guidStreams = {}
    nameStreams = {}
    for _, token in ipairs(TOKENS) do
      functions["UnitGUID"][token] = {}
      functions["UnitName"][token] = {}
      guidStreams[token] = functions["UnitGUID"][token]
      nameStreams[token] = functions["UnitName"][token]
    end

    -- Initial sample at t=0
    SampleAll(0, 0)
  end,

  ---@param capture CaptureState
  OnEvent = function(capture)
    ---@type number
    local t  = GetTime()          - capture.startedAt
    ---@type number
    local tp = GetTimePreciseSec() - capture.startedAtPrecise
    SampleAll(t, tp)
  end,
})
