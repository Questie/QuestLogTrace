---@class QuestLog
local QuestLog = select(2, ...)

QuestLogTraceCore = QuestLogTraceCore or {}

---@class QuestLogTraceCore
local Core = QuestLogTraceCore

---@type fun(table: table, metatable: table?): table
local setmetatable = setmetatable
---@type fun(delay: number, callback: function)
local l_C_After = C_Timer.After
C_After = C_Timer.After

---------------------------------------------------------------------------
-- Shared type definitions (used across all trackers)
---------------------------------------------------------------------------

---@class FunctionStreamEntry
---@field t number Relative time from GetTime()
---@field tp number Relative time from GetTimePreciseSec()
---@field v any The value at this point in time

---@class EventRecord
---@field t number Relative time from GetTime()
---@field tp number Relative time from GetTimePreciseSec()
---@field e string Event name
---@field a PackedArgs Event arguments

---@class PackedArgs
---@field n number Number of arguments
---@field [number] any Positional arguments

---@class DeltaStreamEntry
---@field t number Relative time from GetTime()
---@field tp number Relative time from GetTimePreciseSec()
---@field add number[]? Added IDs
---@field remove number[]? Removed IDs

---@class DeltaStream
---@field t number Initial timestamp
---@field tp number Initial precise timestamp
---@field initial number[] Initial set of IDs
---@field delta DeltaStreamEntry[] Ordered delta entries

---@class SessionRecord
---@field schemaVersion number
---@field name string?
---@field startedAt number
---@field startedAtPrecise number
---@field stoppedAt number?
---@field stoppedAtPrecise number?
---@field duration number?
---@field durationPrecise number?
---@field events EventRecord[]
---@field functions table<string, FunctionStreamEntry[]|table<string|number, FunctionStreamEntry[]>>
---@field functionsDelta table<string, DeltaStream>

---@class CaptureState
---@field active boolean
---@field token number
---@field startedAt number?
---@field startedAtPrecise number?
---@field session SessionRecord?

---@class TrackerDef
---@field events string[]?
---@field Init fun(capture: CaptureState)?
---@field OnEvent fun(capture: CaptureState, event: string, ...)?
---@field OnCaptureStopped fun(capture: CaptureState)?

---@class StatusData
---@field captureState "running"|"stopped_unsaved"|"idle"
---@field isRunning boolean
---@field sessionName string
---@field eventCount number
---@field canSave boolean

---@class EventCategory
---@field name string
---@field events string[]

--? Execute the next frame
--! Be careful with this because the order of defered functions is not guaranteed
---@param func function The function to execute on the next frame
Defer = function(func)
  l_C_After(0, func)
end

--- No Operation
---@param ... unknown
QuestLog.NOP = function(...)
  if select("#", ...) > 0 then
    print("NOP", ...)
  end
end

---------------------------------------------------------------------------
-- Deep compare
---------------------------------------------------------------------------

--- Deep compare two values (ignores "timestamp" keys for backwards compat).
---@param t1 any
---@param t2 any
---@param ignore_mt boolean?
---@param visited table<table, table>? Internal cycle-detection table
---@return boolean equal
function DeepCompare(t1, t2, ignore_mt, visited)
  if t1 == t2 then return true end

  local type1, type2 = type(t1), type(t2)
  if type1 ~= type2 then return false end
  if type1 ~= "table" then return false end

  visited = visited or {}
  if visited[t1] and visited[t1] == t2 then return true end
  visited[t1] = t2

  if not ignore_mt then
    local mt1, mt2 = getmetatable(t1), getmetatable(t2)
    if mt1 or mt2 then
      if not DeepCompare(mt1, mt2, ignore_mt, visited) then
        return false
      end
    end
  end

  for key, value in pairs(t1) do
    if t2[key] == nil or not DeepCompare(value, t2[key], ignore_mt, visited) then
      return false
    end
  end

  for key in pairs(t2) do
    if t1[key] == nil then
      return false
    end
  end

  return true
end

---------------------------------------------------------------------------
-- Shared helpers used by multiple trackers
---------------------------------------------------------------------------

--- Pack varargs into a table with n field.
---@param ... any The arguments to pack
---@return PackedArgs
function Core.PackArgs(...)
  local tbl = { ... }
  tbl.n = select("#", ...)
  return tbl
end

--- Copy a packed-args table (table with n field).
---@param args PackedArgs?
---@return PackedArgs
function Core.CopyPacked(args)
  if type(args) ~= "table" then
    return { n = 0 }
  end
  local out = {}
  local n = args.n or #args
  for i = 1, n do
    out[i] = args[i]
  end
  out.n = n
  return out
end

--- Round a number to the given decimal places.
---@param num number?
---@param decimals number?
---@return number?
function Core.Round(num, decimals)
  if type(num) ~= "number" then return num end
  local mult = 10 ^ (decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

---------------------------------------------------------------------------
-- Tracker registration
---------------------------------------------------------------------------

---@type table<string, fun(capture: CaptureState, event: string, ...)[]>
Core._trackerCallbacks = {}
---@type TrackerDef[]
Core._trackers = {}

--- Register a tracker with the event routing system.
---@param tracker TrackerDef
function Core.RegisterTracker(tracker)
  Core._trackers[#Core._trackers + 1] = tracker
  if tracker.events then
    for _, event in ipairs(tracker.events) do
      if not Core._trackerCallbacks[event] then
        Core._trackerCallbacks[event] = {}
      end
      local cbs = Core._trackerCallbacks[event]
      cbs[#cbs + 1] = tracker.OnEvent
    end
  end
end

---------------------------------------------------------------------------
-- Lazy loading (preserved from original)
---------------------------------------------------------------------------

do
  ---@generic T
  ---@param moduleName `T`
  ---@param createFunction fun(): `T`
  ---@return T
  function LazyLoad(moduleName, createFunction)
    return setmetatable({}, {
      __index = function(_, key)
        QuestLog[moduleName] = createFunction()
        return QuestLog[moduleName][key] or error(moduleName .. " does not have a " .. key .. " property")
      end
    })
  end

  ---@generic T
  ---@param moduleName `T`
  ---@param alwaysLoadAfter number
  ---@param createFunction fun(): `T`
  ---@return T
  function LazyLoad_After(moduleName, alwaysLoadAfter, createFunction)
    local module = LazyLoad(moduleName, createFunction)
    l_C_After(alwaysLoadAfter, function()
      if QuestLog[moduleName] == module then
        QuestLog[moduleName] = createFunction()
      end
    end)
    return module
  end

  QuestLog.LazyLoad = LazyLoad
  QuestLog.LazyLoad_After = LazyLoad_After
end

---------------------------------------------------------------------------
-- Event registration helper (preserved from original)
---------------------------------------------------------------------------

---@return table<string, function>
function EventRegistrator()
  ---@type table<string, function>
  local RegisteredEvents = {}
  ---@param _ Frame
  ---@param event string
  ---@param ... any
  local function OnEvent(_, event, ...)
    RegisteredEvents[event](...)
  end

  local eventFrame = CreateFrame("Frame")
  eventFrame:SetScript("OnEvent", OnEvent)

  return setmetatable({}, {
    __index = function(_, event)
      return RegisteredEvents[event]
    end,
    __newindex = function(_, event, func)
      if RegisteredEvents[event] and func == nil then
        eventFrame:UnregisterEvent(event)
        RegisteredEvents[event] = nil
      else
        eventFrame:RegisterEvent(event)
        RegisteredEvents[event] = func
      end
    end
  })
end
