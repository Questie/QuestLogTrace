# Trace Analyzer

A dev/debug tool for loading, inspecting, and visualizing QuestieTrace session recordings.

## Status

| Phase | Status |
|-------|--------|
| Phase 1: Project scaffold + TypeScript types | :hourglass: Not Started |
| Phase 2: Lua loader (lua-state) | :hourglass: Not Started |
| Phase 3: Emulation engine | :hourglass: Not Started |
| Phase 4: React UI shell + timeline | :hourglass: Not Started |
| Phase 5: Function stream viewer | :hourglass: Not Started |
| Phase 6: Event log | :hourglass: Not Started |
| Phase 7: Simple position plot | :hourglass: Not Started |

---

## Problem Statement

We generate rich trace recordings of WoW game sessions (function streams, events, position data, quest progression, reputation changes) but have no way to inspect or visualize this data outside of reading raw Lua tables. We need tooling to:

- Load trace files (Lua SavedVariables) into structured TypeScript objects
- Reconstruct game state at any point in time via the emulation algorithm
- Browse and filter function streams and events
- Validate that traces are correct during tracker development

---

## Solution

A **local web app** using React + Vite + TypeScript, with a Node.js server layer that uses `lua-state` to parse Lua trace files. Single command to run (`npm run dev`).

### Architecture

```
Browser (React)                    Node.js (Vite middleware)
┌─────────────────────┐            ┌─────────────────────────┐
│  Timeline scrubber   │  fetch()   │  lua-state loads .lua    │
│  Stream viewer       │ ◄────────► │  Converts to typed JSON  │
│  Event log           │  /api/*    │  Serves via middleware   │
│  Position plot       │            │                          │
└─────────────────────┘            └─────────────────────────┘
```

**Why two layers:** `lua-state` is a Node.js N-API native addon — it cannot run in the browser. Vite's dev server middleware bridges this cleanly with zero extra processes.

### Directory Structure

```
tools/
  trace-analyzer/
    package.json
    tsconfig.json
    vite.config.ts
    index.html
    src/
      core/                    # Pure TS, no UI dependency
        types.ts               # SessionRecord, FunctionStream, EventEntry, etc.
        loader.ts              # lua-state → typed JS objects
        emulator.ts            # valueAt, getStream, emulate, delta replay
      server/
        middleware.ts          # Vite server middleware: /api/sessions, /api/session/:name
      ui/
        App.tsx                # Root layout + session selector
        components/
          Timeline.tsx         # Session timeline scrubber
          StreamViewer.tsx     # Function stream browser + value inspector
          EventLog.tsx         # Filterable event list
          PositionPlot.tsx     # Simple 2D XY scatter of player position
        hooks/
          useSession.ts        # Fetch + cache session data
          useEmulator.ts       # valueAt at current time, reactive
```

### Runtime

**Node.js + Vite**. TypeScript runs natively via Vite's built-in transform (browser) and `tsx`/`ts-node` (server middleware, which Vite handles internally). No separate compile step needed.

---

## Implementation Plan

### Phase 1: Project scaffold + TypeScript types

Create the project skeleton and define TypeScript types matching SCHEMA_SPEC v8.

**Steps:**
1. Create `tools/trace-analyzer/` directory
2. `npm init` + install deps: `react`, `react-dom`, `vite`, `@vitejs/plugin-react`, `lua-state`, `typescript`, `@types/react`, `@types/react-dom`
3. Create `tsconfig.json` (strict mode, ESNext target)
4. Create `vite.config.ts` with React plugin
5. Create `index.html` entry point
6. Create `src/core/types.ts` — all interfaces:

```typescript
/** Packed args: sparse array with authoritative n field */
interface PackedArgs {
  [index: number]: unknown;
  n: number;
}

interface FunctionStreamEntry {
  t: number;
  tp: number;
  v?: unknown;  // absent = nil (Lua serialization omits nil keys)
}

interface EventEntry {
  t: number;
  tp: number;
  e: string;
  a: PackedArgs;
}

interface DeltaStream {
  t: number;
  tp: number;
  initial: number[];
  delta: Array<{
    t: number;
    tp: number;
    add?: number[];
    remove?: number[];
  }>;
}

/** Parameterless: FunctionStreamEntry[]. Parameterized: Record<string|number, FunctionStreamEntry[]> */
type FunctionStream = FunctionStreamEntry[] | Record<string | number, FunctionStreamEntry[]>;

interface SessionRecord {
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

interface TraceFile {
  lastSavedSession?: string;
  sessions: SessionRecord[];
}
```

**Validate:** `npx tsc --noEmit` passes.

---

### Phase 2: Lua loader (lua-state)

Load Lua SavedVariables files and convert them to typed TypeScript objects.

**Steps:**
1. Create `src/core/loader.ts`
2. Use `lua-state` to load the trace file:

```typescript
import { LuaState } from "lua-state";

export function loadTraceFile(filePath: string): TraceFile {
  const lua = new LuaState();
  lua.evalFile(filePath);
  const data = lua.getGlobal("QuestieTraceCharacter") as TraceFile;
  return data;
}
```

3. Handle edge cases:
   - Missing `QuestieTraceCharacter` global → throw descriptive error
   - Multiple trace files → accept a directory path, glob for `.lua` files
4. Write a quick CLI smoke test: `npx tsx src/core/loader.ts ../../Traces/QuestieTrace.lua`

**Key detail:** lua-state converts Lua tables to JS objects. Lua arrays (1-indexed) become JS objects with numeric string keys (`{"1": ..., "2": ...}`), NOT JS arrays. The loader must normalize:
- Lua arrays → JS arrays (check for sequential numeric keys starting at 1)
- Preserve `n` field on packed args
- Absent `v` field stays `undefined` (matches our nil convention)

**Validate:** Load `Traces/QuestieTrace.lua`, verify `sessions[0].name === "2026-02-12_21-13-42"` and basic structure.

---

### Phase 3: Emulation engine

Port the FUNCTION_EMULATION_SPEC algorithms to TypeScript.

**Steps:**
1. Create `src/core/emulator.ts`
2. Implement core functions:

```typescript
/** Detect if a function stream is parameterless or parameterized */
function isParameterless(stream: FunctionStream): stream is FunctionStreamEntry[]

/** Get the stream for a function, optionally with a parameter */
function getStream(session: SessionRecord, name: string, param?: string | number): FunctionStreamEntry[] | undefined

/** Find the value at a target time using binary search */
function valueAt(stream: FunctionStreamEntry[], targetT: number): unknown

/** Unpack a stored value to its emulated form */
function emulate(v: unknown): unknown | unknown[]

/** Replay delta stream to get set at target time */
function getCompletedQuests(session: SessionRecord, targetT: number): Set<number>

/** Get all events in a time range */
function getEventsInRange(session: SessionRecord, t0: number, t1: number): EventEntry[]
```

3. `valueAt` should use binary search (streams are sorted by `t`) — the trace has ~12,800 position entries, linear scan is wasteful for scrubbing.

**Validate:** Unit tests against known trace data:
- `valueAt` on `GetZoneText` at t=0 → "Elwynn Forest"
- `valueAt` on `GetSubZoneText` at various times → correct subzones
- `getCompletedQuests` at t=400 → includes 3904
- `getStream` parameterized lookup for `UnitLevel["player"]` at t=0 → 5

---

### Phase 4: React UI shell + timeline

Create the base application layout and timeline scrubber.

**Steps:**
1. Create `src/server/middleware.ts` — Vite dev server middleware:
   - `GET /api/sessions` → list of `{ name, duration, startedAt }` for each session
   - `GET /api/session/:name` → full session JSON
   - Uses `lua-state` to load from configured trace directory (default: `../../Traces/`)
   - Caches parsed data in memory (reload on file change for DX)

2. Wire middleware into `vite.config.ts`:
```typescript
import { traceApiMiddleware } from "./src/server/middleware";

export default defineConfig({
  plugins: [react(), traceApiMiddleware()],
});
```

3. Create `src/ui/App.tsx`:
   - Session selector dropdown (fetches `/api/sessions`)
   - Session info header: name, duration, player identity (from `UnitRace`/`UnitClass`/`UnitSex` at t=0)
   - Tab layout for the different views (Streams, Events, Position)

4. Create `src/ui/components/Timeline.tsx`:
   - Range slider: 0 → `session.duration`
   - Displays current time in `MM:SS.ms` format
   - Play/pause button that auto-advances time
   - Fires `onTimeChange(t)` callback
   - Keyboard: left/right arrow keys for fine stepping

5. Create `src/ui/hooks/useSession.ts`:
   - Fetches session data from API
   - Returns typed `SessionRecord`

6. Create `src/ui/hooks/useEmulator.ts`:
   - Takes session + current time
   - Provides `valueAt`, `getStream`, etc. bound to current session

**Validate:** `npm run dev` opens browser, shows session selector, timeline scrubs correctly.

---

### Phase 5: Function stream viewer

Browse and inspect all function streams at the current time.

**Steps:**
1. Create `src/ui/components/StreamViewer.tsx`:
   - Left panel: tree/list of all function keys in `session.functions`
     - Parameterless functions listed flat
     - Parameterized functions expandable to show their parameter keys
   - Right panel: selected stream detail
     - Current value at timeline time `t` (formatted based on type: scalar, tuple table, object table)
     - Full stream history table: all entries with `t`, `tp`, formatted `v`
     - Highlight the active entry (the one `valueAt` returns)
   - Also show `functionsDelta` streams with current set state

2. Value formatting:
   - `undefined`/absent `v` → display as `nil` (grey/italic)
   - `PackedArgs` → display as tuple: `(value1, value2, ..., valueN)` using `n` for count
   - Object tables → JSON tree view
   - Scalars → direct display

3. Search/filter bar to find function keys by name

**Validate:** Select `GetSubZoneText`, scrub timeline, see zone changes. Select `GetLootSlotInfo[1]`, see loot values change according to observed API samples around `LOOT_READY`/`LOOT_CLOSED`.

---

### Phase 6: Event log

Filterable, scrollable event timeline.

**Steps:**
1. Create `src/ui/components/EventLog.tsx`:
   - Virtualized list (events can number in thousands)
   - Columns: `t` (formatted), `e` (event name), `a` (args summary)
   - Click event → expand to show full args
   - Filter bar: text search on event name
   - Category toggles: Quest events, Chat events, Loot events, NPC/init events, etc.
   - Auto-scroll to current timeline time (with toggle to disable)
   - Click an event timestamp → set timeline to that time

2. Event categorization (for filter toggles):
   - Quest: `QUEST_*`
   - Loot: `LOOT_*`, `CHAT_MSG_LOOT`, `CHAT_MSG_MONEY`
   - Combat: `CHAT_MSG_COMBAT_*`
   - Chat: `CHAT_MSG_*`
   - Movement: `PLAYER_STARTED_MOVING`, `PLAYER_STOPPED_MOVING`
   - Target: `PLAYER_TARGET_CHANGED`, `NAME_PLATE_*`
   - Other: everything else

**Validate:** Filter to quest events only, verify timeline matches known quest lifecycle.

---

### Phase 7: Simple position plot

Basic 2D visualization of player position over time.

**Steps:**
1. Create `src/ui/components/PositionPlot.tsx`:
   - Canvas-based 2D scatter/line plot
   - X axis = map X position, Y axis = map Y position (inverted: WoW Y increases downward on maps)
   - Draw full path as a faded line
   - Highlight current position at timeline time with a bright dot
   - Show coordinates as text overlay
   - Optional: color-code the path by time (gradient from start → end)

2. Data source: `session.functions["C_Map.GetPlayerMapPosition"]["player"]`
   - ~12,800 entries in the sample trace
   - Values are `{x, y}` objects rounded to 4 decimals

3. Simple zoom/pan via mouse wheel + drag (or just fit-to-content)

**Validate:** See a recognizable path through Northshire/Elwynn Forest. Scrub timeline, dot moves along path.

---

## File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `tools/trace-analyzer/package.json` | NEW | Project manifest + dependencies |
| `tools/trace-analyzer/tsconfig.json` | NEW | TypeScript configuration (strict) |
| `tools/trace-analyzer/vite.config.ts` | NEW | Vite + React + API middleware |
| `tools/trace-analyzer/index.html` | NEW | Entry HTML |
| `tools/trace-analyzer/src/core/types.ts` | NEW | All TypeScript interfaces |
| `tools/trace-analyzer/src/core/loader.ts` | NEW | lua-state Lua file → typed JS |
| `tools/trace-analyzer/src/core/emulator.ts` | NEW | valueAt, getStream, emulate, delta replay |
| `tools/trace-analyzer/src/server/middleware.ts` | NEW | Vite dev server API middleware |
| `tools/trace-analyzer/src/ui/App.tsx` | NEW | Root layout, session selector, tabs |
| `tools/trace-analyzer/src/ui/components/Timeline.tsx` | NEW | Timeline scrubber |
| `tools/trace-analyzer/src/ui/components/StreamViewer.tsx` | NEW | Function stream browser |
| `tools/trace-analyzer/src/ui/components/EventLog.tsx` | NEW | Filterable event list |
| `tools/trace-analyzer/src/ui/components/PositionPlot.tsx` | NEW | 2D position scatter plot |
| `tools/trace-analyzer/src/ui/hooks/useSession.ts` | NEW | Session data fetching |
| `tools/trace-analyzer/src/ui/hooks/useEmulator.ts` | NEW | Emulator bound to current time |
| `.gitignore` | MODIFY | Add `tools/trace-analyzer/node_modules/` |

---

## Testing Plan

- **Phase 1:** `npx tsc --noEmit` — types compile
- **Phase 2:** CLI script loads `Traces/QuestieTrace.lua`, prints session name + duration
- **Phase 3:** Unit tests for `valueAt`, `getStream`, `emulate`, `getCompletedQuests` against known trace values
- **Phase 4:** `npm run dev` → browser shows session info + functional timeline
- **Phase 5-7:** Manual verification by scrubbing timeline and cross-referencing with raw trace data

---

## Rollback Plan

Everything is in `tools/trace-analyzer/` — delete the directory. Only external change is a `.gitignore` entry.

---

## Dependencies

| Package | Purpose | Why |
|---------|---------|-----|
| `lua-state` | Load Lua SavedVariables | Native Lua 5.1 embedding, already tested by user |
| `react` + `react-dom` | UI framework | Largest ecosystem for data viz components |
| `vite` + `@vitejs/plugin-react` | Dev server + bundler | Zero-config TS, HMR, server middleware API |
| `typescript` | Type checking | Required for strict types |

No additional charting libraries planned initially — the position plot uses raw Canvas API, and stream/event views use HTML tables. Libraries can be added later if needed.

---

## Related Specs

- `specs/SCHEMA_SPEC.md` — Defines the exact data structure we're loading and visualizing
- `specs/FUNCTION_EMULATION_SPEC.md` — The emulation algorithm we're porting to TypeScript
- `specs/EVENT_CATALOG.md` — Event categories for the event log filter
