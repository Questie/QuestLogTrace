local safePack = function(...) -- Copied from Blizzard Code
  local tbl = { n = select("#", ...), ... };
  return tbl;
end

---comment
---@param event string
---@param displayEvent string
---@param displayMessage string
---@param prePendString string? @optional
---@param ... any
local function LogEvent(event, displayEvent, displayMessage, prePendString, ...)
  -- Prepend string to event
  event = prePendString and "_" .. event or event
  if QLTrace and QLTrace:CanLogEvent(event) then
    local elementData = {
      event = event,
      args = safePack(...),
      displayEvent = displayEvent,
      displayMessage = displayMessage,
    }
    QLTrace:LogLine(elementData);
  end
end

-- hello this is a test!

---Print to QLTrace
---@param message string
---@param ... any
---@diagnostic disable-next-line: lowercase-global
function printE(message, ...)
  -- if Questie.db.global.debugEnabled then
  ---@type string
  local d = debugstack(2, 1, 1) --[[@as string]]
  -- For some reason the VSCode ext doesn't show that this returns a string

  --? Get the lua filename and code line number
  local fileName, lineNr = d:match('(%w+%.lua)%"%]:(%d+)')
  if not fileName or not lineNr then
    -- The depth was too low
    d = debugstack(1, 1, 1) --[[@as string]]
    fileName, lineNr = d:match('(%w+%.lua)%"%]:(%d+)')
  end
  if fileName and lineNr and type(message) == "string" then
    -- Add a _ to sort better in the EventLog
    LogEvent(fileName, format("%s:%s", fileName, lineNr), format("%s:%s %s", fileName, lineNr, message), "_", ...)
  end
  -- end
end
