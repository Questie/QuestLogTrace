---@class QuestieTraceCore
local Core = QuestieTraceCore

---------------------------------------------------------------------------
-- Export payload building (data only -- no UI here)
---------------------------------------------------------------------------
-- This file is strictly about turning saved sessions into a shareable,
-- privacy-scrubbed payload/string. Any window/frame code lives in
-- Export/ExportUI.lua and must call only the functions defined here.
---------------------------------------------------------------------------

---@type number
local EXPORT_VERSION = 1

-- Unit tokens whose identity must never leave the client.
---@type table<string, boolean>
local SCRUB_TOKENS = { player = true }

-- Function streams keyed by unit token that could reveal player identity.
---@type table<string, boolean>
local SCRUB_FUNCTION_KEYS = { UnitName = true, UnitGUID = true }

--- Recursively copy a value (tables only; scalars are returned as-is).
---@param value any
---@return any
local function DeepCopy(value)
  if type(value) ~= "table" then return value end
  local out = {}
  for k, v in pairs(value) do
    out[k] = DeepCopy(v)
  end
  return out
end

--- Remove captured data that could reveal player identity from a copied
--- session's function streams, in place.
---@param functions table<string, FunctionStream>?
local function ScrubFunctions(functions)
  if type(functions) ~= "table" then return end
  for key in pairs(SCRUB_FUNCTION_KEYS) do
    ---@type table?
    local stream = functions[key]
    if type(stream) == "table" then
      for token in pairs(SCRUB_TOKENS) do
        stream[token] = nil
      end
    end
  end
end

--- Build a scrubbed, exportable copy of all saved sessions for this character.
---@return table payload
function Core.BuildExportPayload()
  ---@type SessionRecord[]
  local sessions = {}

  ---@type table?
  local characterDb = QuestieTraceCharacter
  ---@type SessionRecord[]
  local savedSessions = (type(characterDb) == "table" and type(characterDb.sessions) == "table") and characterDb.sessions or {}

  for i = 1, #savedSessions do
    ---@type SessionRecord
    local session = DeepCopy(savedSessions[i])
    ScrubFunctions(session.functions)
    sessions[#sessions + 1] = session
  end

  return {
    exportVersion = EXPORT_VERSION,
    generatedAt = (type(date) == "function") and date("%Y-%m-%d %H:%M:%S") or nil,
    sessions = sessions,
  }
end

---------------------------------------------------------------------------
-- Serialization (plain Lua table literal -- readable and re-loadable)
---------------------------------------------------------------------------

---@param str string
---@return string
local function QuoteString(str)
  return string.format("%q", str)
end

---@param value any
---@param buffer string[]
local function SerializeValue(value, buffer)
  ---@type type
  local t = type(value)
  if t == "string" then
    buffer[#buffer + 1] = QuoteString(value)
  elseif t == "number" or t == "boolean" then
    buffer[#buffer + 1] = tostring(value)
  elseif t == "table" then
    buffer[#buffer + 1] = "{"

    ---@type number
    local n = #value
    for i = 1, n do
      SerializeValue(value[i], buffer)
      buffer[#buffer + 1] = ","
    end

    ---@type (string|number)[]
    local keys = {}
    for k in pairs(value) do
      ---@type boolean
      local isEmittedArrayIndex = type(k) == "number" and k >= 1 and k <= n and k % 1 == 0
      if not isEmittedArrayIndex then
        keys[#keys + 1] = k
      end
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

    for i = 1, #keys do
      ---@type string|number
      local k = keys[i]
      if type(k) == "string" and k:match("^[%a_][%w_]*$") then
        buffer[#buffer + 1] = k .. "="
      elseif type(k) == "number" then
        buffer[#buffer + 1] = "[" .. tostring(k) .. "]="
      else
        buffer[#buffer + 1] = "[" .. QuoteString(tostring(k)) .. "]="
      end
      SerializeValue(value[k], buffer)
      buffer[#buffer + 1] = ","
    end

    buffer[#buffer + 1] = "}"
  else
    buffer[#buffer + 1] = "nil"
  end
end

--- Serialize a payload table into a plain Lua table literal string.
---@param payload table
---@return string
local function SerializeExportPayload(payload)
  ---@type string[]
  local buffer = {}
  SerializeValue(payload, buffer)
  return table.concat(buffer)
end

--- Build the full exportable string for the current character's saved sessions.
---@return string
function Core.BuildExportString()
  return SerializeExportPayload(Core.BuildExportPayload())
end
