// ============================================================
// Load WoW Lua SavedVariables files via lua-state
// ============================================================

import { LuaState } from "lua-state";
import { normalizeLuaValue } from "./normalize.js";
import type { TraceFile } from "./types.js";

/**
 * Load a QuestLogTrace SavedVariables file and return typed data.
 *
 * The file format is: `QuestLogTraceCharacter = { ... }`
 * lua-state executes the Lua, then we extract the global.
 */
export function loadTraceFile(filePath: string): TraceFile {
  const lua = new LuaState();
  lua.evalFile(filePath);

  const raw = lua.getGlobal("QuestLogTraceCharacter");

  if (raw === null || raw === undefined) {
    throw new Error(
      `No QuestLogTraceCharacter global found in ${filePath}. ` +
        `Is this a valid QuestLogTrace SavedVariables file?`
    );
  }

  const normalized = normalizeLuaValue(raw) as TraceFile;
  return normalized;
}
