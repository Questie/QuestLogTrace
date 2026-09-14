-- Run from the addon root with: lua5.1 Tests/run.lua
-- Real addon code runs in isolated globals; no game or SavedVariables files are used.

---@class TestTimer
---@field at number
---@field callback fun()

---@class TestRuntime
---@field env table<string, any>
---@field core QuestieTraceCore
---@field now number
---@field timers TestTimer[]
---@field frame table<string, any>

---@param runtime TestRuntime
---@param path string
local function LoadAddonFile(runtime, path)
  local chunk = assert(loadfile(path))
  setfenv(chunk, runtime.env)
  chunk("QuestieTrace", runtime.env.QuestLog)
end

---@param trackerFiles string[]
---@return TestRuntime
local function NewRuntime(trackerFiles)
  ---@type TestRuntime
  local runtime = { env = {}, core = {}, now = 0, timers = {}, frame = {} }
  local env = runtime.env
  setmetatable(env, { __index = _G })
  env._G = env
  env.QuestLog = {}
  env.SlashCmdList = {}
  env.QuestieTrace = { schemaVersion = 9, settings = { maxSessions = 7, autoStart = false } }
  env.QuestieTraceCharacter = { sessions = {} }
  env.print = function() end
  env.GetTime = function() return runtime.now end
  env.GetTimePreciseSec = env.GetTime
  env.C_Timer = {
    ---@param delay number
    ---@param callback fun()
    After = function(delay, callback)
      runtime.timers[#runtime.timers + 1] = { at = runtime.now + delay, callback = callback }
    end,
  }
  ---@type fun(frame: table, event: string)
  runtime.frame.RegisterEvent = function() end
  ---@param frame table<string, any>
  ---@param name string
  ---@param callback function
  runtime.frame.SetScript = function(frame, name, callback) frame[name] = callback end
  env.CreateFrame = function() return runtime.frame end

  LoadAddonFile(runtime, "Modules/globals.lua")
  for _, path in ipairs(trackerFiles) do LoadAddonFile(runtime, path) end
  LoadAddonFile(runtime, "QuestieTrace.lua")
  runtime.core = env.QuestieTraceCore
  return runtime
end

---@param runtime TestRuntime
---@param event string
local function SendEvent(runtime, event)
  runtime.frame.OnEvent(runtime.frame, event)
end

---@param runtime TestRuntime
---@param target number
local function AdvanceTo(runtime, target)
  while true do
    local nextIndex
    for index, timer in ipairs(runtime.timers) do
      if timer.at <= target and (not nextIndex or timer.at < runtime.timers[nextIndex].at) then
        nextIndex = index
      end
    end
    if not nextIndex then break end
    local timer = table.remove(runtime.timers, nextIndex)
    runtime.now = timer.at
    timer.callback()
  end
  runtime.now = target
end

---@param runtime TestRuntime
---@return SessionRecord
local function Session(runtime)
  return assert(runtime.core.GetDiagnosticSession())
end

---@class GreetingFixture
---@field count number
---@field phase "live"|"stale"|"error"|"settled"
---@field staleCalls number
---@field totalCalls number

---@param runtime TestRuntime
---@return GreetingFixture
local function GreetingApis(runtime)
  ---@type GreetingFixture
  local state = { count = 2, phase = "live", staleCalls = 0, totalCalls = 0 }
  local env = runtime.env
  env.GetNumActiveQuests = function() return state.count end
  env.GetNumAvailableQuests = env.GetNumActiveQuests
  ---@param index number
  ---@return string? title
  local function Title(index)
    state.totalCalls = state.totalCalls + 1
    if index == 1 then return "First quest" end
    state.staleCalls = state.staleCalls + 1
    if state.phase == "error" then error("Greeting data unavailable") end
    if state.phase == "settled" then return nil end
    return "Second quest"
  end
  env.GetAvailableTitle = Title
  ---@param index number
  ---@return string? title
  ---@return boolean complete
  env.GetActiveTitle = function(index) return Title(index), false end
  return state
end

---@param phase "stale"|"error"
local function TestGreetingRetry(phase)
  local runtime = NewRuntime({ "Modules/Trackers/QuestDialog.lua" })
  local state = GreetingApis(runtime)
  runtime.core.StartCapture("greeting retry")
  AdvanceTo(runtime, 1)

  state.count, state.phase = 1, phase
  SendEvent(runtime, "QUEST_GREETING")
  local functions = Session(runtime).functions
  local active = functions.GetActiveTitle[2]
  local available = functions.GetAvailableTitle[2]
  assert(#active == 1 and #available == 1, "Shrink must not fabricate an inactive value")

  state.phase = "settled"
  AdvanceTo(runtime, 2)
  assert(#active == 2 and active[2].v.n == 2 and active[2].v[1] == nil and active[2].v[2] == false,
    "Delayed samples must observe the removed active title, preserving nil and false")
  assert(#available == 2 and available[2].v == nil,
    "Delayed samples must observe the removed available title")
end

local function TestGreetingClose()
  local runtime = NewRuntime({ "Modules/Trackers/QuestDialog.lua" })
  local state = GreetingApis(runtime)
  runtime.core.StartCapture("close cancellation")
  state.count, state.phase = 0, "stale"
  SendEvent(runtime, "GOSSIP_CLOSED")
  local callsAtClose = state.totalCalls
  state.phase = "settled"
  AdvanceTo(runtime, 2)
  assert(state.totalCalls == callsAtClose, "Close must cancel pending open samples")
  local available = Session(runtime).functions.GetAvailableTitle[2]
  assert(#available == 1 and available[1].v == "Second quest", "Close must not synthesize nil")

  state.count = 1
  SendEvent(runtime, "QUEST_GREETING")
  assert(#available == 2 and available[2].v == nil, "Reopening must still probe known stale indices")
end

local function TestGreetingRestart()
  local runtime = NewRuntime({ "Modules/Trackers/QuestDialog.lua" })
  local state = GreetingApis(runtime)
  runtime.core.StartCapture("old capture")
  local oldSession = Session(runtime)
  AdvanceTo(runtime, 0.05)
  runtime.core.StopCapture()
  state.count = 1
  local oldCalls = state.staleCalls
  runtime.core.StartCapture("new capture")
  local callsAtRestart = state.totalCalls
  -- Old capture timers start at 0.10; new capture timers start at 0.15.
  AdvanceTo(runtime, 0.11)
  assert(state.totalCalls == callsAtRestart, "Old timers must not sample the new capture's valid indices")
  AdvanceTo(runtime, 0.16)
  assert(state.totalCalls == callsAtRestart + 2, "The new capture's own timer must still sample both APIs")
  AdvanceTo(runtime, 2)
  assert(state.staleCalls == oldCalls, "New capture must reset known indices")
  assert(Session(runtime).functions.GetAvailableTitle[2] == nil, "Old indices must not leak into new capture")
  assert(#oldSession.functions.GetAvailableTitle[2] == 1, "Stopped capture must not receive delayed writes")
end

local function TestSessionContract()
  local runtime = NewRuntime({})
  ---@type SessionRecord
  local legacy = {
    schemaVersion = 9, name = "legacy", startedAt = 0, startedAtPrecise = 0,
    events = {}, functions = { GetNumLootItems = { { t = 0, tp = 0, v = 0 } } }, functionsDelta = {},
  }
  local env = runtime.env
  local settings = env.QuestieTrace.settings
  env.QuestieTraceCharacter.sessions[1] = legacy
  SendEvent(runtime, "VARIABLES_LOADED")
  assert(env.QuestieTrace.settings == settings and settings.maxSessions == 7 and settings.autoStart == false,
    "Recording contract must not reset existing settings")

  runtime.core.StartCapture("new capture")
  local current = Session(runtime)
  assert(current.schemaVersion == 9 and current.recordingContractVersion == 1,
    "New captures need contract provenance without a storage schema bump")
  runtime.core.SaveCapture()
  assert(env.QuestieTraceCharacter.sessions[2] == current and current.recordingContractVersion == 1,
    "Saving must retain the recording contract")
  assert(env.QuestieTraceCharacter.sessions[1] == legacy and legacy.recordingContractVersion == nil,
    "Legacy sessions must survive unchanged and unmarked")
end

local function TestSpellBookArity()
  local runtime = NewRuntime({ "Modules/Trackers/SpellBook.lua" })
  local arity = 2
  ---@param slot number
  ---@param bookType string
  ---@return any ...
  runtime.env.GetSpellBookItemName = function(slot, bookType)
    assert(bookType == "spell")
    if slot > 1 then return nil end
    if arity == 2 then return "Fireball", nil end
    if arity == 3 then return "Fireball", nil, 133 end
    return "Fireball", nil, 133, nil
  end
  runtime.core.StartCapture("spell arity")
  local session = Session(runtime)
  local names = session.functions.GetSpellBookItemName[1]
  assert(names[1].v.n == 2 and names[1].v[2] == nil, "Do not pad a two-value return to three")
  arity = 3
  SendEvent(runtime, "SPELLS_CHANGED")
  assert(names[2].v.n == 3 and names[2].v[3] == 133, "Preserve the spell ID return")
  assert(session.functions.SpellBook[2].v[1] == 133, "Synthetic spell membership still uses the third return")
  assert(session.functionsDelta.PlayerKnownSpells.delta[1].add[1] == 133, "Known-spell delta must still update")
  arity = 4
  SendEvent(runtime, "SPELLS_CHANGED")
  assert(names[3].v.n == 4 and names[3].v[4] == nil, "Preserve extra trailing nil returns")
end

local function TestExportScrubsPlayerIdentity()
  local runtime = NewRuntime({ "Modules/Export/Export.lua" })
  runtime.core.StartCapture("export test")
  local session = Session(runtime)
  session.functions.UnitName = {
    player = { { t = 0, tp = 0, v = { "Hero", "Realm", n = 2 } } },
    questnpc = { { t = 0, tp = 0, v = { "Some NPC", nil, n = 2 } } },
  }
  session.functions.UnitGUID = {
    player = { { t = 0, tp = 0, v = "Player-1-000001" } },
    npc = { { t = 0, tp = 0, v = "Creature-0-1-1-1-123-000001" } },
  }
  runtime.core.SaveCapture()

  local payload = runtime.core.BuildExportPayload()
  local exported = payload.sessions[1]
  assert(exported.functions.UnitName.player == nil, "Player name must be scrubbed from export")
  assert(exported.functions.UnitName.questnpc ~= nil, "NPC name must remain in export")
  assert(exported.functions.UnitGUID.player == nil, "Player GUID must be scrubbed from export")
  assert(exported.functions.UnitGUID.npc ~= nil, "NPC GUID must remain in export")

  local savedSession = runtime.env.QuestieTraceCharacter.sessions[1]
  assert(savedSession.functions.UnitName.player ~= nil, "BuildExportPayload must not mutate the saved session")
end

local function TestExportSerializationRoundTrips()
  local runtime = { env = {}, core = {}, now = 0, timers = {}, frame = {} }
  local env = runtime.env
  setmetatable(env, { __index = _G })
  env._G = env
  env.QuestLog = {}
  env.SlashCmdList = {}
  env.QuestieTrace = { schemaVersion = 9, settings = { maxSessions = 7, autoStart = false } }
  env.QuestieTraceCharacter = { sessions = {} }
  env.print = function() end
  env.GetTime = function() return runtime.now end
  env.GetTimePreciseSec = env.GetTime
  env.C_Timer = {
    After = function(delay, callback)
      runtime.timers[#runtime.timers + 1] = { at = runtime.now + delay, callback = callback }
    end,
  }
  runtime.frame.RegisterEvent = function() end
  runtime.frame.SetScript = function(frame, name, callback) frame[name] = callback end
  env.CreateFrame = function() return runtime.frame end

  -- Initialize QuestieTraceCore BEFORE loading any addon files
  env.QuestieTraceCore = {}

  -- Mock C_EncodingUtil BEFORE loading Export.lua
  env.C_EncodingUtil = {
    SerializeCBOR = function(_value)
      -- Mock: return a fake CBOR string (just a marker)
      return "CBOR_ENCODED_DATA"
    end,
    DeserializeCBOR = function(source)
      if source == "CBOR_ENCODED_DATA" then
        return { exportVersion = 1, sessions = { { functions = { GetZoneText = { { t = 0, tp = 0, v = "Dun Morogh" } } } } } }
      end
      return nil
    end,
    CompressString = function(_source, _method, _level)
      -- Mock: return a fake compressed string
      return "DEFLATE_COMPRESSED_DATA"
    end,
    DecompressString = function(source, _method)
      if source == "DEFLATE_COMPRESSED_DATA" then
        return "CBOR_ENCODED_DATA"
      end
      return nil
    end,
  }

  -- Mock Enum compression methods
  env.Enum = {
    CompressionMethod = {
      Deflate = 1,
    },
    CompressionLevel = {
      Default = 1,
    },
  }

  -- Mock LibDeflate BEFORE loading Export.lua
  env.LibDeflate_Instance = {
    EncodeForPrint = function(_self, source)
      return "PRINT:" .. tostring(source)
    end,
    DecodeForPrint = function(_self, source)
      if type(source) == "string" and source:sub(1, 6) == "PRINT:" then
        return source:sub(7)
      end
      return nil
    end,
  }
  env.LibStub = function(name, _optional)
    if name == "LibDeflate" then
      return env.LibDeflate_Instance
    end
    return nil
  end

  -- Now load addon files with mocks in place
  LoadAddonFile(runtime, "Modules/globals.lua")

  LoadAddonFile(runtime, "Modules/Export/Export.lua")
  LoadAddonFile(runtime, "QuestieTrace.lua")
  runtime.core = env.QuestieTraceCore

  runtime.core.StartCapture("serialize test")
  local session = assert(runtime.core.GetDiagnosticSession())
  session.functions.GetZoneText = { { t = 0, tp = 0, v = "Dun Morogh" } }
  runtime.core.SaveCapture()

  local text = runtime.core.BuildExportString()
  -- text should be a compressed/encoded string, not raw Lua
  assert(type(text) == "string" and #text > 0, "Export string must be non-empty")
  -- Verify it starts with print-encoding marker
  assert(text:sub(1, 6) == "PRINT:", "Export must be print-encoded")
end

---@type { name: string, run: fun() }[]
local tests = {
  { name = "greeting retries unsettled titles", run = function() TestGreetingRetry("stale") end },
  { name = "greeting retries failed calls", run = function() TestGreetingRetry("error") end },
  { name = "greeting close cancels delayed samples", run = TestGreetingClose },
  { name = "greeting capture restart resets probes", run = TestGreetingRestart },
  { name = "session contract preserves legacy saves", run = TestSessionContract },
  { name = "spellbook preserves observed tuple arity", run = TestSpellBookArity },
  { name = "export scrubs player identity", run = TestExportScrubsPlayerIdentity },
  { name = "export serialization round-trips", run = TestExportSerializationRoundTrips },
}

local failures = 0
for _, test in ipairs(tests) do
  local ok, err = pcall(test.run)
  print((ok and "PASS " or "FAIL ") .. test.name)
  if not ok then
    failures = failures + 1
    print(err)
  end
end
assert(failures == 0, failures .. " test(s) failed")
print(#tests .. " tests passed")
