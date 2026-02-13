// ============================================================
// Emulation engine — port of FUNCTION_EMULATION_SPEC v8
//
// Reconstructs WoW API function outputs at a target time `t`
// from QuestLogTrace session data.
// ============================================================

import type {
  SessionRecord,
  FunctionStream,
  FunctionStreamEntry,
  EventEntry,
  PackedArgs,
} from "./types.js";

/**
 * Detect if a function stream is parameterless (flat array)
 * or parameterized (record of param → entries).
 */
export function isParameterless(
  stream: FunctionStream
): stream is FunctionStreamEntry[] {
  return Array.isArray(stream);
}

/**
 * Get the list of parameter keys for a parameterized stream.
 * Returns empty array for parameterless streams.
 */
export function getParamKeys(stream: FunctionStream): string[] {
  if (Array.isArray(stream)) return [];
  return Object.keys(stream);
}

/**
 * Get the entry array for a function, optionally with a parameter.
 */
export function getStream(
  session: SessionRecord,
  name: string,
  param?: string | number
): FunctionStreamEntry[] | undefined {
  const fn = session.functions[name];
  if (!fn) return undefined;

  if (param !== undefined) {
    if (Array.isArray(fn)) return undefined;
    const paramMap = fn as Record<string | number, FunctionStreamEntry[]>;
    // Try the param as given, then as string (lua-state uses string keys)
    return paramMap[param] ?? paramMap[String(param)];
  }

  if (Array.isArray(fn)) return fn;
  return undefined;
}

/**
 * Binary search for the value at a target time.
 *
 * Returns the `v` field of the latest entry with `t <= targetT`.
 * Returns `undefined` if no entry exists at or before targetT.
 */
export function valueAt(
  stream: FunctionStreamEntry[],
  targetT: number
): unknown {
  if (stream.length === 0) return undefined;

  let lo = 0;
  let hi = stream.length - 1;
  let result = -1;

  while (lo <= hi) {
    const mid = (lo + hi) >>> 1;
    if (stream[mid].t <= targetT) {
      result = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }

  if (result === -1) return undefined;
  return stream[result].v;
}

/**
 * Find the index of the active entry at a target time.
 * Returns -1 if no entry exists at or before targetT.
 */
export function activeIndex(
  stream: FunctionStreamEntry[],
  targetT: number
): number {
  if (stream.length === 0) return -1;

  let lo = 0;
  let hi = stream.length - 1;
  let result = -1;

  while (lo <= hi) {
    const mid = (lo + hi) >>> 1;
    if (stream[mid].t <= targetT) {
      result = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }

  return result;
}

/**
 * Unpack a stored value for display.
 *
 * - Packed args (object with `n`): extract indices 1..n into array
 * - Other objects/scalars: return as-is
 */
export function emulate(v: unknown): unknown {
  if (v !== null && v !== undefined && typeof v === "object" && !Array.isArray(v)) {
    const obj = v as Record<string, unknown>;
    if (typeof obj.n === "number") {
      const result: unknown[] = [];
      for (let i = 1; i <= (obj.n as number); i++) {
        result.push(obj[i] ?? null);
      }
      return result;
    }
  }
  return v;
}

/**
 * Check if a value is packed args (has `n` field).
 */
export function isPackedArgs(v: unknown): v is PackedArgs {
  return (
    v !== null &&
    v !== undefined &&
    typeof v === "object" &&
    !Array.isArray(v) &&
    typeof (v as Record<string, unknown>).n === "number"
  );
}

/**
 * Replay delta stream to get the set at target time.
 */
export function getCompletedQuests(
  session: SessionRecord,
  targetT: number
): Set<number> {
  const data = session.functionsDelta["GetQuestsCompleted"];
  if (!data) return new Set();

  const set = new Set<number>(data.initial);

  for (const delta of data.delta) {
    if (delta.t > targetT) break;
    if (delta.add) {
      for (const id of delta.add) set.add(id);
    }
    if (delta.remove) {
      for (const id of delta.remove) set.delete(id);
    }
  }

  return set;
}

/**
 * Get events in a time range [t0, t1] using binary search.
 */
export function getEventsInRange(
  session: SessionRecord,
  t0: number,
  t1: number
): EventEntry[] {
  const events = session.events;
  // Binary search for first event with t >= t0
  let lo = 0;
  let hi = events.length;
  while (lo < hi) {
    const mid = (lo + hi) >>> 1;
    if (events[mid].t < t0) lo = mid + 1;
    else hi = mid;
  }

  const result: EventEntry[] = [];
  for (let i = lo; i < events.length && events[i].t <= t1; i++) {
    result.push(events[i]);
  }
  return result;
}

/**
 * Categorize an event name into a filter category.
 */
export type EventCategory =
  | "quest"
  | "loot"
  | "combat"
  | "chat"
  | "movement"
  | "target"
  | "zone"
  | "inventory"
  | "other";

export function categorizeEvent(name: string): EventCategory {
  if (
    name.startsWith("QUEST_") ||
    name === "UNIT_QUEST_LOG_CHANGED" ||
    name === "QUESTLINE_UPDATE"
  )
    return "quest";
  if (
    name.startsWith("LOOT_") ||
    name === "CHAT_MSG_LOOT" ||
    name === "CHAT_MSG_MONEY"
  )
    return "loot";
  if (name.startsWith("CHAT_MSG_COMBAT")) return "combat";
  if (name.startsWith("CHAT_MSG_")) return "chat";
  if (name === "PLAYER_STARTED_MOVING" || name === "PLAYER_STOPPED_MOVING")
    return "movement";
  if (name === "PLAYER_TARGET_CHANGED" || name.startsWith("NAME_PLATE_"))
    return "target";
  if (
    name.startsWith("ZONE_") ||
    name === "PLAYER_ENTERING_WORLD" ||
    name === "NEW_WMO_CHUNK"
  )
    return "zone";
  if (name.startsWith("BAG_") || name.startsWith("ITEM_")) return "inventory";
  return "other";
}

/**
 * Format a time value in seconds to MM:SS.mmm
 */
export function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  const whole = Math.floor(secs);
  const ms = Math.round((secs - whole) * 1000);
  return `${String(mins).padStart(2, "0")}:${String(whole).padStart(2, "0")}.${String(ms).padStart(3, "0")}`;
}
