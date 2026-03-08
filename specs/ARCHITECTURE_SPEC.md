# Architecture Spec (v8)

File structure, load order, bootstrap sequence, and SavedVariables
management for QuestLogTrace.

---

## 1) File load order

Defined by `QuestLogTrace-Classic.toc`:

```
globals.lua                   -- Core namespace, utilities, RegisterTracker API
Trackers/PlayerIdentity.lua   -- UnitRace, UnitClass, UnitSex (t=0 only)
Trackers/UnitLevel.lua        -- UnitLevel["player"]
Trackers/Position.lua         -- Zone texts, map ID, player position
Trackers/Loot.lua             -- Loot window capture
Trackers/Reputation.lua       -- Faction reputation
Trackers/QuestLog.lua         -- Quest log membership + per-quest functions
Trackers/CompletedQuests.lua  -- GetQuestsCompleted delta stream
Dumps/MapHierarchy.lua        -- Static C_Map hierarchy dump (PLAYER_LOGIN + /qlt dumpmap)
QuestLogTrace_UI.lua          -- Control frame UI
QuestLogTrace.lua             -- Entry point: session lifecycle, event bus
```

### Load order rationale

1. `globals.lua` runs first, establishing the `QuestLogTraceCore`
   namespace and the `Core.RegisterTracker` function.
2. All tracker files run next. Each calls `Core.RegisterTracker` at file
   scope (not in a callback), building the `_trackerCallbacks` lookup
   table before the event frame exists.
3. Dump files run after trackers. Each calls `Core.RegisterDump` at file
   scope, building dump event/slash routing tables before the event frame
   and slash command handler execute.
4. `QuestLogTrace_UI.lua` defines `Core.BuildControlFrame` and
   `Core.UpdateControlFrameStatus`. These are nil-checked by the main
   file, so the UI is optional.
5. `QuestLogTrace.lua` runs last. It creates the event frame, registers
   all events, and sets up the `VARIABLES_LOADED` bootstrap handler.

---

## 2) Bootstrap sequence

On `VARIABLES_LOADED`:

1. `EnsureSavedVariables()` — validate/initialize saved data.
2. `Core.BuildControlFrame()` — create the control frame UI.
3. `Core.UpdateControlFrameStatus()` — set initial button states.

`VARIABLES_LOADED` is consumed by the bootstrap and does NOT pass through
to `ProcessTrackedEvent`.

---

## 3) Event registration

All events from `TRACKED_EVENT_CATEGORIES` are registered on the main
event frame at load time. Registration uses `pcall` to gracefully skip
events that exist in one Classic version but not another:

```lua
local ok = pcall(eventFrame.RegisterEvent, eventFrame, eventName)
if not ok then
  print(ADDON_NAME, "Skipping unsupported event:", eventName)
end
```

The event categories (quest_state, quest_dialog, player_state, map_zone,
chat_system, group_world, inventory) are organizational — they define
the full set of events the addon captures. Tracker routing is handled
separately by `Core._trackerCallbacks`.

---

## 4) SavedVariables

### Account-level: `QuestLogTrace`

```lua
QuestLogTrace = {
  schemaVersion = 8,
  settings = {
    maxSessions = 20,
  },
}
```

### Per-character: `QuestLogTraceCharacter`

```lua
QuestLogTraceCharacter = {
  lastSavedSession = "2026-02-10_12-34-56",  -- set on save only
  sessions = { SessionRecord, ... },
}
```

### Migration behavior

On `VARIABLES_LOADED`, `EnsureSavedVariables` checks the stored schema:

- If `QuestLogTrace` is not a table or `schemaVersion ~= 8`, the entire
  account-level table is **wiped and recreated** with defaults.
- If `QuestLogTraceCharacter` is not a table, it is reset to `{}`.
- The `sessions` array is ensured to exist.
- `lastSavedSession` is NOT initialized on migration — it is only set
  when the user explicitly saves a session.

There is no incremental migration from v7 to v8. Upgrading resets all
stored data.

---

## 5) Session pruning

After every save, `PruneSessionsIfNeeded` runs:

```lua
while #sessions > maxSessions do
  table.remove(sessions, 1)  -- remove oldest (FIFO)
end
```

Default `maxSessions` is 20. Configurable via `QuestLogTrace.settings.maxSessions`.

---

## 6) Session naming

If no name is provided at start or save time, sessions are named using:

```lua
date("%Y-%m-%d_%H-%M-%S")
```

A name provided at `/qlt save [name]` overrides the name set at
`/qlt start [name]`.

---

## 7) Shared utilities (globals.lua)

| Function | Purpose | Used by |
|---|---|---|
| `Core.RegisterTracker(def)` | Register a tracker definition | All tracker files |
| `Core.PackArgs(...)` | Pack varargs into `{..., n=count}` | Event recording, tuple-returning functions |
| `Core.CopyPacked(args)` | Deep-copy a packed-args table | Event recording |
| `Core.Round(num, decimals)` | Round a number | Position tracker (4 decimal places) |
| `DeepCompare(t1, t2)` | Recursive table comparison | Reputation, QuestLog change detection |
| `C_After` | Alias for `C_Timer.After` | Timer scheduling |
| `Defer(func)` | `C_Timer.After(0, func)` | Next-frame execution |
