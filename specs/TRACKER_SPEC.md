# Tracker Spec (v9)

How trackers are structured, registered, and dispatched. This is the core
architecture pattern for capturing WoW API function data.

---

## 1) TrackerDef interface

Every tracker file calls `Core.RegisterTracker(def)` once at file scope.
The definition table has four optional fields:

```lua
Core.RegisterTracker({
  events = { "EVENT_NAME", ... },                -- optional
  Init = function(capture) ... end,              -- optional
  OnEvent = function(capture, event, ...) end,   -- optional
  OnCaptureStopped = function(capture) end,      -- optional
})
```

| Field | Called when | Purpose |
|---|---|---|
| `events` | File load time | List of WoW events this tracker cares about |
| `Init` | `Core.StartCapture()` | Create initial function streams at t=0 |
| `OnEvent` | Event fires during capture | Sample functions, append if changed |
| `OnCaptureStopped` | `Core.StopCapture()` | Final sampling or cleanup |

If `events` is nil or absent, the tracker receives no event dispatches
(e.g. PlayerIdentity, which only samples at t=0).

---

## 2) Registration and event routing

`Core.RegisterTracker` (in `globals.lua`) does two things:

1. Appends the tracker to `Core._trackers` (ordered list).
2. For each event in `events`, appends `OnEvent` to
   `Core._trackerCallbacks[event]` (an `event -> callback[]` lookup).

At runtime, `ProcessTrackedEvent` in `QuestLogTrace.lua`:

1. Records the raw event to `capture.session.events`.
2. Looks up `Core._trackerCallbacks[event]`.
3. Calls each registered callback with `(capture, event, ...)`.

Only trackers that registered for a given event run when it fires.

---

## 3) CaptureState object

The `capture` object passed to all tracker callbacks:

```lua
capture = {
  active          = true,       -- false after StopCapture
  token           = 1,          -- monotonically increasing, for timer invalidation
  startedAt       = 100000.0,   -- GetTime() at capture start (absolute)
  startedAtPrecise = 4821.312,  -- GetTimePreciseSec() at capture start (absolute)
  session         = {           -- the SessionRecord being built
    schemaVersion  = 8,
    name           = "session-name" or nil,
    startedAt      = 100000.0,
    startedAtPrecise = 4821.312,
    events         = {},
    functions      = {},
    functionsDelta = {},
  },
}
```

### Three-state machine

| `capture.active` | `capture.session` | State |
|---|---|---|
| `false` | `nil` | Idle — no session |
| `true` | table | Running — capture active |
| `false` | table | Stopped, unsaved |

### Token-based timer invalidation

`capture.token` increments on every `StartCapture`. Trackers that schedule
delayed callbacks (via `C_Timer.After`) capture the token at schedule time
and check it in the callback:

```lua
local token = capture.token
C_After(delay, function()
  if not capture.active or capture.token ~= token then return end
  -- safe to sample
end)
```

This ensures stale timers from a previous capture session are discarded.

---

## 4) Zero-copy architecture

Trackers write directly into `capture.session.functions` and
`capture.session.functionsDelta`. During `Init`, each tracker creates its
stream tables inside the session object and holds local references:

```lua
-- In Init:
capture.session.functions["UnitLevel"] = {
  ["player"] = { { t = 0, tp = 0, v = 12 } },
}
stream = capture.session.functions["UnitLevel"]["player"]

-- In OnEvent:
stream[#stream + 1] = { t = t, tp = tp, v = 13 }
```

There is no serialization step on save. The session object built by
trackers IS the SessionRecord stored in SavedVariables.

---

## 5) Tracker lifecycle

### On StartCapture

1. `capture.token` increments.
2. `capture.startedAt` and `capture.startedAtPrecise` are set.
3. `capture.session` is created (empty `events`, `functions`, `functionsDelta`).
4. `capture.active = true`.
5. `Init` is called on every registered tracker (in registration order).
6. No synthetic events are emitted.

### On each game event

1. Raw event is appended to `capture.session.events` with `{t, tp, e, a}`.
2. Registered tracker callbacks run.
3. Each tracker samples its functions and appends only if value changed.
4. All entries produced in the same call stack share the same `t` value
   (from `GetTime() - capture.startedAt`).

### On StopCapture

1. Stop timestamps are recorded on the session.
2. `capture.active = false`.
3. `OnCaptureStopped` is called on every registered tracker.
4. Timer-based trackers stop naturally (their callbacks check `capture.active`).

### On SaveCapture

1. Auto-stops if still running.
2. Session is appended directly to `QuestLogTraceCharacter.sessions`.
3. `capture.session` is set to `nil`.

### On ResetCapture

1. Only works when not active (stopped_unsaved state).
2. `capture.session` is set to `nil`, discarding the unsaved data.

---

## 6) Trigger patterns

Five distinct patterns exist across trackers:

### Pattern 1: Event-driven

Sample when a specific game event fires.

**Example:** UnitLevel — samples `UnitLevel("player")` on `PLAYER_LEVEL_UP`.

### Pattern 2: Timer-driven

Sample on a repeating interval regardless of events.

**Example:** Position — samples every 0.2 seconds via `C_Timer.After`.
The timer is started in `Init` and self-schedules until `capture.active`
becomes false.

### Pattern 3: Event + delayed re-samples

Sample immediately on event, then re-sample at staggered delays to catch
server-lag states where the API initially returns incomplete data.

**Schedule:** `{ 0, 0.10, 0.35, 0.55, 0.75, 1.00 }` seconds.

The 0-delay entry samples in the same call stack as the event. Subsequent
entries use `C_Timer.After` with token-based invalidation.

**Example:** QuestLog — quest objective text may show `" : 0/8"` before
the server sends the real item name. The delayed re-samples catch the
correct text when it arrives.

### Pattern 4: Event-driven with index iteration

When an event fires, the tracker iterates a dynamic set of keys to sample.

**Example:** QuestLog — iterates all quest IDs in the log and samples
each per-quest function for every ID. Reputation — iterates all known
factionIDs.

### Pattern 5: Event-driven with window lifecycle

Sample on open event, reset to nil/0 on close event.

**Example:** Loot — samples all slot functions on `LOOT_READY`, resets
everything to nil/0 on `LOOT_CLOSED`.

---

## 7) Per-tracker design

| Tracker | File | Functions | Trigger | Events |
|---|---|---|---|---|
| PlayerIdentity | `Trackers/PlayerIdentity.lua` | `UnitRace["player"]`, `UnitClass["player"]`, `UnitSex["player"]`, `UnitFactionGroup["player"]` | Init only (t=0) | None |
| UnitLevel | `Trackers/UnitLevel.lua` | `UnitLevel["player"]`, `GetQuestGreenRange` | Event-driven | `PLAYER_LEVEL_UP`, `PLAYER_ENTERING_WORLD`, `SPELLS_CHANGED` |
| Position | `Trackers/Position.lua` | `GetZoneText`, `GetSubZoneText`, `GetRealZoneText`, `C_Map.GetBestMapForUnit["player"]`, `C_Map.GetPlayerMapPosition["player"]`, `IsInInstance`, `GetInstanceInfo` | Timer (0.2s) + event-driven + private frame | `ZONE_CHANGED`, `ZONE_CHANGED_NEW_AREA`, `ZONE_CHANGED_INDOORS`, `PLAYER_ENTERING_WORLD`, `PLAYER_ALIVE`, `MAP_EXPLORATION_UPDATED`, `PLAYER_MAP_CHANGED`, `AREA_POIS_UPDATED`, `NEW_WMO_CHUNK`, `SPELLS_CHANGED` + private: `PLAYER_STARTED_MOVING`, `PLAYER_STOPPED_MOVING` |
| Loot | `Trackers/Loot.lua` | `GetNumLootItems`, `GetLootSlotInfo[slot]`, `GetLootSourceInfo[slot]`, `GetLootSlotLink[slot]`, `GetLootSlotType[slot]` | Event + window lifecycle | `LOOT_READY` (sample), `LOOT_CLOSED` (reset) |
| Reputation | `Trackers/Reputation.lua` | `FactionOrder`, `GetFactionInfoByID[factionID]` | Event + index iteration | `CHAT_MSG_COMBAT_FACTION_CHANGE`, `UPDATE_FACTION`, `QUEST_TURNED_IN`, `PLAYER_ENTERING_WORLD`, `SPELLS_CHANGED` |
| QuestLog | `Trackers/QuestLog.lua` | `QuestLog`, `IsQuestComplete[qid]`, `C_QuestLog.IsQuestFlaggedCompleted[qid]`, `C_QuestLog.GetQuestObjectives[qid]`, `GetQuestLogTitle[qid]`, `GetQuestLogQuestText[qid]`, `GetQuestTagInfo[qid]` | Event + delayed re-samples + index iteration | 14 quest events + `PLAYER_ENTERING_WORLD`, `SPELLS_CHANGED` (see EVENT_CATALOG) |
| CompletedQuests | `Trackers/CompletedQuests.lua` | `GetQuestsCompleted` (functionsDelta) | Event + delayed re-samples | Same 14 quest events + `PLAYER_ENTERING_WORLD`, `SPELLS_CHANGED` |
| UnitInteraction | `Trackers/UnitInteraction.lua` | `UnitGUID["target","npc","questnpc"]`, `UnitName["target","npc","questnpc"]`, `C_GossipInfo.GetAvailableQuests`, `C_GossipInfo.GetActiveQuests` | Event-driven | `PLAYER_TARGET_CHANGED`, 8 quest dialog, `QUEST_ACCEPTED`, `QUEST_TURNED_IN`, `LOOT_OPENED`, 22 npc_interaction, `PLAYER_ENTERING_WORLD`, `SPELLS_CHANGED` (37 total) |
| GroupState | `Trackers/GroupState.lua` | `IsInGroup`, `GetNumGroupMembers` | Event-driven | `GROUP_JOINED`, `GROUP_LEFT`, `GROUP_ROSTER_UPDATE`, `PLAYER_ENTERING_WORLD`, `SPELLS_CHANGED` |

---

## 8) Reputation tracker behavior

The Reputation tracker has unique complexity that warrants explicit
documentation.

### Collection vs sampling

Two distinct phases:

**CollectFactionIDs** (has side effects):
- Iterates `GetFactionInfo(1..GetNumFactions())`.
- Expands collapsed headers to discover children.
- Returns ordered array of factionIDs.
- Updates `FactionOrder` if the set changed.

**SampleReputation** (pure reads):
- For each known factionID, calls `GetFactionInfoByID(factionID)`.
- Compares full 16-value tuple against previous value (DeepCompare).
- Appends `{t, tp, v}` only if changed.

### Event-to-action mapping

| Event | Action |
|---|---|
| Capture start (Init) | CollectAndSample (both phases) |
| `QUEST_TURNED_IN` | CollectAndSample (quest rewards can reveal new factions) |
| `CHAT_MSG_COMBAT_FACTION_CHANGE` | SampleReputation only (values changed, set unchanged) |
| `UPDATE_FACTION` | SampleReputation only (same) |
| `PLAYER_ENTERING_WORLD` | SampleReputation only (login-time sampling) |
| `SPELLS_CHANGED` | SampleReputation only (login-time sampling) |

### Expand-only policy

After our first collection pass, all faction headers are expanded.
ExpandFactionHeader is called on collapsed headers but headers are never
re-collapsed. This is intentional — it simplifies the collection logic.

### Recursion guard

`ExpandFactionHeader` fires `UPDATE_FACTION`, which would re-enter the
tracker. A `collecting` flag prevents re-entry:

```lua
local collecting = false

function CollectFactionIDs()
  collecting = true
  -- ... iterate and expand ...
  collecting = false
end

OnEvent = function(capture, event, ...)
  if collecting then return end
  -- ...
end
```

### No delayed re-samples

Unlike quest functions, reputation changes are atomic — `GetFactionInfoByID`
returns the correct value immediately when the event fires. No staggered
re-sampling is needed.

---

## 9) Change detection

Trackers only append entries when values change. The comparison method
depends on the value type:

| Value type | Comparison | Used by |
|---|---|---|
| Scalar (number, string, boolean) | `==` | UnitLevel, Position zone texts, loot scalars |
| Table/object | `DeepCompare()` | Reputation tuples, quest objectives, quest log membership |
| Nil | Explicit nil check | Loot (always append on close) |

`DeepCompare` performs recursive key-by-key comparison with cycle
detection and optional metatable comparison.
