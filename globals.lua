---@class QuestLog
local QuestLog = select(2, ...)

local setmetatable = setmetatable
local l_C_After = C_Timer.After
C_After = C_Timer.After

--? Execute the next frame
--! Be careful with this because the order of defered functions is not guaranteed
Defer = function(func)
  l_C_After(0, func)
end

--- No Operation
---@param ... unknown
QuestLog.NOP = function(...)
  -- Print if there are any arguments
  if select("#", ...) > 0 then
    print("NOP", ...)
  end
end

--? Lazy load functions
do
  ---A function that initializes LazyLoad for a module
  --
  -- This loads the module when it is first accessed.
  ---@generic T
  ---@param moduleName `T` The name of the module, also the type
  ---@param createFunction fun(): `T` The function that creates the module on demand
  ---@return T
  function LazyLoad(moduleName, createFunction)
    -- Create the module if/when it is accessed
    return setmetatable({}, {
      __index = function(_, key)
        QuestLog[moduleName] = createFunction()
        return QuestLog[moduleName][key] or error(moduleName .. " does not have a " .. key .. " property")
      end
    })
  end

  ---A function that initializes LazyLoad for a module
  --
  -- This loads the module when it is first accessed or after a set time.
  ---@generic T
  ---@param moduleName `T` The name of the module, also the type
  ---@param alwaysLoadAfter number Number of seconds to wait before loading the module
  ---@param createFunction fun(): `T` The function that creates the module on demand
  ---@return T
  function LazyLoad_After(moduleName, alwaysLoadAfter, createFunction)
    -- Create the module if it is accessed before the timer
    -- local module = setmetatable({}, {
    --   __index = function(_, key)
    --     QuestLog[moduleName] = createFunction()
    --     return QuestLog[moduleName][key]
    --   end
    -- })
    local module = LazyLoad(moduleName, createFunction)
    l_C_After(alwaysLoadAfter, function()
      -- If the module has not been accessed yet, load it
      if QuestLog[moduleName] == module then
        QuestLog[moduleName] = createFunction()
      else
        return
      end
    end)
    return module
  end

  -- Put it in internal namespace
  QuestLog.LazyLoad = LazyLoad
  QuestLog.LazyLoad_After = LazyLoad_After
end


-- Event registration
-- Usage:
-- Register   an event: ReturnedObject["EVENT_NAME"] = func
-- Unregister an event: ReturnedObject["EVENT_NAME"] = nil
---@return table<FrameEvent, function>
function EventRegistrator()
  ---@type table<FrameEvent, function>
  local RegisteredEvents = {}
  local function OnEvent(_, event, ...)
    RegisteredEvents[event](...)
  end

  -- Create the event frame and register the OnEvent handler
  local eventFrame = CreateFrame("Frame")
  eventFrame:SetScript("OnEvent", OnEvent)

  ---@type table<string, function>
  return setmetatable({}, {
    __index = function(_, event)
      return RegisteredEvents[event]
    end,
    __newindex = function(_, event, func)
      if RegisteredEvents[event] and func == nil then
        print("Unregistering", event)
        eventFrame:UnregisterEvent(event)
        RegisteredEvents[event] = nil
      else
        print("Registering", event)
        eventFrame:RegisterEvent(event)
        RegisteredEvents[event] = func
      end
    end
  })
end
