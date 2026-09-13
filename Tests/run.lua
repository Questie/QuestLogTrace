-- Run from the addon root with: lua5.1 Tests/run.lua
-- Real addon code runs in isolated globals; no game or SavedVariables files are used.

---@class TestTimer
---@field at number
---@field callback fun()

---@class TestRuntime
---@field env table<string, any>
---@field core QuestLogTraceCore
---@field now number
---@field timers TestTimer[]
---@field frame table<string, any>

---@param runtime TestRuntime
---@param path string
local function LoadAddonFile(runtime, path)
  local chunk = assert(loadfile(path))
  setfenv(chunk, runtime.env)
  chunk("QuestLogTrace", runtime.env.QuestLog)
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
  env.QuestLogTrace = { schemaVersion = 9, settings = { maxSessions = 7, autoStart = false } }
  env.QuestLogTraceCharacter = { sessions = {} }
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

  LoadAddonFile(runtime, "globals.lua")
  for _, path in ipairs(trackerFiles) do LoadAddonFile(runtime, path) end
  LoadAddonFile(runtime, "QuestLogTrace.lua")
  runtime.core = env.QuestLogTraceCore
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
  local runtime = NewRuntime({ "Trackers/QuestDialog.lua" })
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
  local runtime = NewRuntime({ "Trackers/QuestDialog.lua" })
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
  local runtime = NewRuntime({ "Trackers/QuestDialog.lua" })
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
  local settings = env.QuestLogTrace.settings
  env.QuestLogTraceCharacter.sessions[1] = legacy
  SendEvent(runtime, "VARIABLES_LOADED")
  assert(env.QuestLogTrace.settings == settings and settings.maxSessions == 7 and settings.autoStart == false,
    "Recording contract must not reset existing settings")

  runtime.core.StartCapture("new capture")
  local current = Session(runtime)
  assert(current.schemaVersion == 9 and current.recordingContractVersion == 1,
    "New captures need contract provenance without a storage schema bump")
  runtime.core.SaveCapture()
  assert(env.QuestLogTraceCharacter.sessions[2] == current and current.recordingContractVersion == 1,
    "Saving must retain the recording contract")
  assert(env.QuestLogTraceCharacter.sessions[1] == legacy and legacy.recordingContractVersion == nil,
    "Legacy sessions must survive unchanged and unmarked")
end

local function TestSpellBookArity()
  local runtime = NewRuntime({ "Trackers/SpellBook.lua" })
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

---@type { name: string, run: fun() }[]
local tests = {
  { name = "greeting retries unsettled titles", run = function() TestGreetingRetry("stale") end },
  { name = "greeting retries failed calls", run = function() TestGreetingRetry("error") end },
  { name = "greeting close cancels delayed samples", run = TestGreetingClose },
  { name = "greeting capture restart resets probes", run = TestGreetingRestart },
  { name = "session contract preserves legacy saves", run = TestSessionContract },
  { name = "spellbook preserves observed tuple arity", run = TestSpellBookArity },
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
