---@class QuestieTraceCore
local Core = QuestieTraceCore

---@type l10n
local l10n = Core.l10n

---------------------------------------------------------------------------
-- Export payload building (data only -- no UI here)
---------------------------------------------------------------------------
-- This file is strictly about turning saved sessions into a shareable,
-- privacy-scrubbed payload/string. Encoding lives in Encoding.lua, and
-- window/frame code lives in ExportUI.lua.
---------------------------------------------------------------------------

---@type number
local EXPORT_VERSION = 1

--- Recursively copy a value (tables only; scalars are returned as-is).
---@param value any
---@return any
local function DeepCopy(value)
  if type(value) ~= "table" then
    return value
  end
  local out = {}
  for k, v in pairs(value) do
    out[k] = DeepCopy(v)
  end
  return out
end

--- Read the local player's GUID as observed on the "player" token of a session's UnitGUID stream.
---@param guidStream table<string, FunctionStreamEntry[]> UnitGUID function stream
---@return string? playerGuid
local function GetPlayerGuid(guidStream)
  local playerEntries = guidStream["player"]
  if type(playerEntries) ~= "table" or #playerEntries == 0 then
    return nil
  end
  return playerEntries[1].v
end

--- Remove entries whose value equals playerGuid from every token in the UnitGUID stream, in place.
---@param guidStream table<string, FunctionStreamEntry[]> UnitGUID function stream
---@param playerGuid string
---@return table<string, table<number, boolean>> scrubbedTimes Sample times (`t`) removed per token
local function RemovePlayerGuidObservations(guidStream, playerGuid)
  ---@type table<string, table<number, boolean>>
  local scrubbedTimes = {}

  for token, entries in pairs(guidStream) do
    if type(entries) == "table" then
      for i = #entries, 1, -1 do
        local entry = entries[i]
        if entry and entry.v == playerGuid then
          scrubbedTimes[token] = scrubbedTimes[token] or {}
          scrubbedTimes[token][entry.t] = true
          table.remove(entries, i)
        end
      end
    end
  end

  return scrubbedTimes
end

--- Remove UnitName entries matching the (token, sample time) pairs scrubbed from the UnitGUID stream, in place.
---@param nameStream table<string, FunctionStreamEntry[]> UnitName function stream
---@param scrubbedTimes table<string, table<number, boolean>> Result of RemovePlayerGuidObservations
local function RemoveMatchingNameObservations(nameStream, scrubbedTimes)
  for token, times in pairs(scrubbedTimes) do
    local entries = nameStream[token]
    if type(entries) == "table" then
      for i = #entries, 1, -1 do
        local entry = entries[i]
        if entry and times[entry.t] then
          table.remove(entries, i)
        end
      end
    end
  end
end

--- Drop token keys whose entry list has become empty, so an empty stream looks the same as one that was never recorded.
---@param stream table<string, FunctionStreamEntry[]>
local function PruneEmptyTokens(stream)
  for token, entries in pairs(stream) do
    if type(entries) == "table" and #entries == 0 then
      stream[token] = nil
    end
  end
end

--- Remove captured data that could reveal player identity from a copied
--- session's function streams, in place.
---
--- Any UnitGUID observation matching the local player's GUID is removed,
--- regardless of which token recorded it (e.g. "target" when the player
--- targets themselves), along with the UnitName observation for the same
--- token and sample time. Unrelated observations are left untouched.
---@param functions table<string, FunctionStream>?
local function ScrubFunctions(functions)
  if type(functions) ~= "table" then
    return
  end

  local guidStream = functions.UnitGUID
  local nameStream = functions.UnitName
  if type(guidStream) ~= "table" or type(nameStream) ~= "table" then
    return
  end

  local playerGuid = GetPlayerGuid(guidStream)
  if not playerGuid then return end

  local scrubbedTimes = RemovePlayerGuidObservations(guidStream, playerGuid)
  RemoveMatchingNameObservations(nameStream, scrubbedTimes)

  PruneEmptyTokens(guidStream)
  PruneEmptyTokens(nameStream)
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
-- Serialization
---------------------------------------------------------------------------

--- Build the full exportable string for the current character's saved sessions.
---@return string
function Core.BuildExportString()
  local payload = Core.BuildExportPayload()
  local encoded = Core.EncodeExportPayload(payload)
  if encoded then
    return encoded
  end
  -- Fallback: if codec is missing, return an error message instead of crashing.
  return l10n("ERROR: Client does not have required codec support (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)")
end
