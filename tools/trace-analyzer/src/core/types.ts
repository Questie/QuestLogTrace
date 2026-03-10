// ============================================================
// TypeScript types matching SCHEMA_SPEC v9
// ============================================================

/**
 * Packed args: sparse object with authoritative `n` field.
 * Indices 1..n hold values (some may be null/undefined for Lua nil).
 * The `n` field gives the true argument count.
 */
export interface PackedArgs {
  [index: number]: unknown;
  n: number;
}

/** A single entry in a function stream */
export interface FunctionStreamEntry {
  t: number;
  tp: number;
  /** absent means nil (Lua serialization omits nil keys) */
  v?: unknown;
}

/** A single event in the events timeline */
export interface EventEntry {
  t: number;
  tp: number;
  e: string;
  a: PackedArgs;
}

/** A single delta entry (add/remove from a set) */
export interface DeltaEntry {
  t: number;
  tp: number;
  add?: number[];
  remove?: number[];
}

/** Delta stream: initial set + ordered delta entries */
export interface DeltaStream {
  t: number;
  tp: number;
  initial: number[];
  delta: DeltaEntry[];
}

/**
 * A function stream is either:
 * - Parameterless: a flat array of FunctionStreamEntry
 * - Parameterized: a record mapping param key → array of FunctionStreamEntry
 */
export type FunctionStream =
  | FunctionStreamEntry[]
  | Record<string | number, FunctionStreamEntry[]>;

/** A complete session recording */
export interface SessionRecord {
  schemaVersion: number;
  name: string;
  startedAt: number;
  startedAtPrecise: number;
  stoppedAt: number;
  stoppedAtPrecise: number;
  duration: number;
  durationPrecise: number;
  events: EventEntry[];
  functions: Record<string, FunctionStream>;
  functionsDelta: Record<string, DeltaStream>;
}

/** Top-level per-character SavedVariables */
export interface TraceFile {
  lastSavedSession?: string;
  sessions: SessionRecord[];
}

/** Summary of a trace file in the Traces directory */
export interface TraceFileSummary {
  name: string;
  sessionCount: number | null;
  error: string | null;
}

/** Summary sent to browser for session list */
export interface SessionSummary {
  name: string;
  duration: number;
  startedAt: number;
  eventCount: number;
  functionCount: number;
}

/** Event category for filtering */
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
