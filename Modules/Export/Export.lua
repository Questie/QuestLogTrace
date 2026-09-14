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

-- LibDeflate for print-safe encoding of compressed binary payloads.
---@type LibDeflate
local LibDeflate = LibStub("LibDeflate", true)

--- Check whether the client has the required compression and encoding APIs.
--- Every supported WoW client should have these; if missing, fail loudly.
---@return boolean
local function _HasCodecSupport()
  local hasBlizzardEncoding = C_EncodingUtil ~= nil
    and C_EncodingUtil.SerializeCBOR ~= nil
    and C_EncodingUtil.DeserializeCBOR ~= nil
    and C_EncodingUtil.CompressString ~= nil
    and C_EncodingUtil.DecompressString ~= nil

  local hasDeflateEnums = Enum ~= nil
    and Enum.CompressionMethod ~= nil
    and Enum.CompressionMethod.Deflate ~= nil
    and Enum.CompressionLevel ~= nil
    and Enum.CompressionLevel.Default ~= nil

  local hasLibDeflate = LibDeflate ~= nil
    and LibDeflate.EncodeForPrint ~= nil
    and LibDeflate.DecodeForPrint ~= nil

  return hasBlizzardEncoding and hasDeflateEnums and hasLibDeflate
end

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
-- Serialization (CBOR + compression + print-safe encoding)
---------------------------------------------------------------------------

--- Encode a payload table into a compressed, print-safe string.
--- Pipeline: Lua table -> CBOR -> Deflate compress -> EncodeForPrint
---@param payload table
---@return string? encodedPayload Nil if codec support is missing or encoding fails.
local function EncodeExportPayload(payload)
  if (not _HasCodecSupport()) then
    return nil
  end

  local ok, encoded = pcall(function()
    local cbor = C_EncodingUtil.SerializeCBOR(payload)
    local compressed = C_EncodingUtil.CompressString(cbor, Enum.CompressionMethod.Deflate, Enum.CompressionLevel.Default)
    return LibDeflate:EncodeForPrint(compressed)
  end)

  if ok and type(encoded) == "string" then
    return encoded
  end

  return nil
end

--- Build the full exportable string for the current character's saved sessions.
---@return string
function Core.BuildExportString()
  local payload = Core.BuildExportPayload()
  local encoded = EncodeExportPayload(payload)
  if encoded then
    return encoded
  end
  -- Fallback: if codec is missing, return an error message instead of crashing.
  return "ERROR: Client does not have required codec support (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)"
end
