// ============================================================
// Static return-value schemas for tracked WoW API functions.
//
// Maps function name → ordered list of return field names.
// Used by the UI to render labeled values instead of raw tuples.
//
// Source: Documentation/WoW-API + warcraft.wiki.gg
// Only functions tracked by QuestLogTrace are included.
// ============================================================

export interface ReturnField {
  /** Display name for this return value position */
  name: string;
  /** Lua type hint (for future formatting) */
  type: "string" | "number" | "boolean" | "table" | "unknown";
}

/**
 * Lookup a function's return schema.
 * Returns undefined for single-return or custom-stream functions
 * (where labeling adds no value).
 */
export function getSchema(functionName: string): ReturnField[] | undefined {
  return FUNCTION_SCHEMAS[functionName];
}

// ---------------------------------------------------------------------------
// Schemas — only multi-return functions need entries here.
// Single-return functions (GetZoneText, UnitLevel, etc.) are omitted
// because their value is self-explanatory.
// ---------------------------------------------------------------------------

const FUNCTION_SCHEMAS: Record<string, ReturnField[]> = {
  // -- Loot.lua ---------------------------------------------------------------

  "GetLootSlotInfo": [
    { name: "lootIcon", type: "string" },
    { name: "lootName", type: "string" },
    { name: "lootQuantity", type: "number" },
    { name: "currencyID", type: "number" },
    { name: "lootQuality", type: "number" },
    { name: "locked", type: "boolean" },
    { name: "isQuestItem", type: "boolean" },
    { name: "questID", type: "number" },
    { name: "isActive", type: "boolean" },
  ],

  "GetLootSourceInfo": [
    { name: "guid", type: "string" },
    { name: "quantity", type: "number" },
  ],

  // -- QuestLog.lua -----------------------------------------------------------

  "GetQuestLogTitle": [
    { name: "title", type: "string" },
    { name: "level", type: "number" },
    { name: "suggestedGroup", type: "number" },
    { name: "isHeader", type: "boolean" },
    { name: "isCollapsed", type: "boolean" },
    { name: "isComplete", type: "number" },       // 1=done, -1=failed, nil=in progress
    { name: "frequency", type: "number" },         // 1=normal, 2=daily, 3=weekly
    { name: "questID", type: "number" },
    { name: "startEvent", type: "boolean" },
    { name: "displayQuestID", type: "boolean" },
    { name: "isOnMap", type: "boolean" },
    { name: "hasLocalPOI", type: "boolean" },
    { name: "isTask", type: "boolean" },
    { name: "isBounty", type: "boolean" },
    { name: "isStory", type: "boolean" },
    { name: "isHidden", type: "boolean" },
    { name: "isScaling", type: "boolean" },
  ],

  "GetQuestTagInfo": [
    { name: "tagID", type: "number" },
    { name: "tagName", type: "string" },
    { name: "worldQuestType", type: "number" },
    { name: "rarity", type: "number" },
    { name: "isElite", type: "boolean" },
    { name: "tradeskillLineIndex", type: "number" },
    { name: "displayTimeLeft", type: "unknown" },
  ],

  // -- Reputation.lua ---------------------------------------------------------

  "GetFactionInfoByID": [
    { name: "name", type: "string" },
    { name: "description", type: "string" },
    { name: "standingID", type: "number" },        // 4=Neutral, 5=Friendly, 6=Honored...
    { name: "barMin", type: "number" },
    { name: "barMax", type: "number" },
    { name: "barValue", type: "number" },
    { name: "atWarWith", type: "boolean" },
    { name: "canToggleAtWar", type: "boolean" },
    { name: "isHeader", type: "boolean" },
    { name: "isCollapsed", type: "boolean" },
    { name: "hasRep", type: "boolean" },
    { name: "isWatched", type: "boolean" },
    { name: "isChild", type: "boolean" },
    { name: "factionID", type: "number" },
    { name: "hasBonusRepGain", type: "boolean" },
    { name: "canSetInactive", type: "boolean" },
  ],

  // -- PlayerIdentity.lua -----------------------------------------------------

  "UnitRace": [
    { name: "localizedRaceName", type: "string" },
    { name: "englishRaceName", type: "string" },
    { name: "raceID", type: "number" },
  ],

  "UnitClass": [
    { name: "className", type: "string" },
    { name: "classFilename", type: "string" },
    { name: "classID", type: "number" },
  ],
};
