# Updated Design Notes (v8 direction)

This file captures the design discussion so it is not lost.

## 1) Core mental model

Three top-level concepts:

- `events` = raw time-series of game signals. Already good, no changes needed.
- `functions` = per-function value streams. A flat array of `{t, v}` entries.
  The first entry is the full value captured at session start. Subsequent entries
  appear only when the value changes. The latest entry is always the current value.
- `functionsDelta` = set-based function streams that are too large to store as
  full snapshots. Stored as an initial set + delta entries (`add`/`remove`).
  Must be replayed from initial to reconstruct state at a point in time.

Events drive _when_ a function gets sampled, but function data is not an event log.

**`nil` is a valid value.** When a function returns `nil` (or `0` for count
functions), that is recorded as a change just like any other value. This is
critical for the emulator to return to the correct state. It also means
transient-window APIs (like loot functions that only return values between
`LOOT_READY` and `LOOT_CLOSED`) are not a special case — they are regular
function streams that happen to be `nil`/`0` most of the time.

---

## 2) Function stream format

There is no separate `initial` field. The first entry in the array **is** the
initial value — just a full value at `t=0`. After that, entries appear whenever
the value changes. One flat list per function.

### Parameterless functions — flat array

Functions with no arguments are stored as a flat `{t, v}` array directly:

```lua
["GetZoneText"] = {
  { t = 0.000, v = "Dun Morogh" },
  { t = 90.000, v = "Stormwind City" },
}

["GetNumLootItems"] = {
  { t = 0.000, v = 0 },          -- session start, no loot window
  { t = 45.200, v = 2 },         -- LOOT_READY fired
  { t = 48.100, v = 0 },         -- LOOT_CLOSED fired
}
```

### Parameterized functions — keyed by argument

Functions that take arguments are stored as a table keyed by the argument
value. Each key maps to a `{t, v}` array. The key is the actual value you
would pass to the function (number, string, etc.).

```lua
["UnitLevel"] = {
  ["player"] = {
    { t = 0.000, v = 12 },
    { t = 5.213, v = 13 },
  },
}

["GetLootSlotInfo"] = {
  [1] = {
    { t = 45.200, v = { "Icon\\Path", "Copper Coin", 1, n = 9 } },
    { t = 48.100, v = nil },
  },
  [2] = {
    { t = 45.200, v = { "Icon\\Path", "Linen Cloth", 2, n = 9 } },
    { t = 48.100, v = nil },
  },
}

["C_Map.GetPlayerMapPosition"] = {
  ["player"] = {
    { t = 0.000, v = { x = 0.5477, y = 0.5486 } },
    { t = 0.200, v = { x = 0.5480, y = 0.5490 } },
    { t = 90.000, v = { x = 0.6111, y = 0.7422 } },
  },
}
```

### Parser detection

The parser can tell the two formats apart generically: if the first entry
has a `t` field, it is a flat stream. Otherwise, the keys are argument values
and each value is a stream. This means one generic lookup function covers
both cases — no special conventions or sentinel keys needed.

### Emulator lookup

- Parameterless: `functions[name]` → find latest `entry.t <= target_t`
- Parameterized: `functions[name][param]` → find latest `entry.t <= target_t`

Same algorithm once you have the stream. Same logic for every function.

---

## 2b) Delta stream format (`functionsDelta`)

For functions that return large sets where storing the full value each time
would be too expensive (e.g. `GetQuestsCompleted` — potentially thousands
of quest IDs). Stored as initial snapshot + ordered delta entries.

```lua
["GetQuestsCompleted"] = {
  t = 0,
  tp = 0,
  initial = { 123, 456, 789 },
  delta = {
    { t = 50.000, tp = 50.00012, add = { 56789 } },
    { t = 120.000, tp = 120.00034, add = { 67890, 11111 } },
  },
}
```

- `initial` is the full set at capture start.
- Each delta entry contains `add` and/or `remove` arrays.
- Omit `add` or `remove` if empty — no need to serialize empty tables.
- `GetQuestsCompleted` only ever grows (quests cannot be uncompleted),
  so `remove` will be absent in practice, but the format supports it.

### Emulator replay

```lua
state = set(initial)
for each delta in order:
  if delta.t > target: break
  for id in delta.add: state[id] = true
  for id in delta.remove: state[id] = nil
return state
```

---

## 3) Proposed `schemaVersion = 8` shape

```lua
Session = {
  schemaVersion = 8,
  name = "2026-02-10_12-34-56",

  -- Absolute clock baselines (reference anchors, not data points)
  startedAt        = 100000.000,     -- GetTime() at capture start
  startedAtPrecise = 4821.31204,     -- GetTimePreciseSec() at capture start
  stoppedAt        = 100333.150,     -- GetTime() at capture stop
  stoppedAtPrecise = 5154.46238,     -- GetTimePreciseSec() at capture stop
  duration         = 333.150,        -- stoppedAt - startedAt
  durationPrecise  = 333.15034,      -- stoppedAtPrecise - startedAtPrecise

  -- No summary block. Consumer counts #events, iterates function keys, etc.
  -- No player block. Player identity is in functions (UnitRace, UnitClass, UnitSex).

  events = {
    { t = 0.000, tp = 0.00012, e = "PLAYER_ENTERING_WORLD", a = { n = 0 } },
    { t = 0.500, tp = 0.50021, e = "QUEST_ACCEPTED", a = { 101, 56789, n = 2 } },
    { t = 5.213, tp = 5.21347, e = "PLAYER_LEVEL_UP", a = { 13, 120, 40, 0, 0, 0, 1, 1, 1, 1, n = 10 } },
    { t = 45.200, tp = 45.20021, e = "LOOT_READY", a = { n = 0 } },
    { t = 48.100, tp = 48.10008, e = "LOOT_CLOSED", a = { n = 0 } },
    { t = 50.000, tp = 50.00005, e = "QUEST_TURNED_IN", a = { 56789, n = 1 } },
  },

  functions = {
    -- Parameterless: flat arrays
    ["GetZoneText"] = {
      { t = 0.000, v = "Dun Morogh" },
      { t = 90.000, v = "Stormwind City" },
    },
    ["GetSubZoneText"] = {
      { t = 0.000, v = "Coldridge Valley" },
      { t = 90.000, v = "Trade District" },
    },
    ["GetRealZoneText"] = {
      { t = 0.000, v = "Dun Morogh" },
      { t = 90.000, v = "Stormwind City" },
    },
    ["GetNumLootItems"] = {
      { t = 0.000, v = 0 },
      { t = 45.200, v = 2 },
      { t = 48.100, v = 0 },
    },

    -- Quest log membership: full array, small enough to store each time
    ["QuestLog"] = {
      { t = 0.000, v = { 12345 } },
      { t = 0.500, v = { 12345, 56789 } },           -- quest accepted
      { t = 50.000, v = { 12345 } },                   -- quest turned in
    },

    -- Parameterized: keyed by argument
    ["UnitLevel"] = {
      ["player"] = {
        { t = 0.000, v = 12 },
        { t = 5.213, v = 13 },
      },
    },
    ["C_Map.GetBestMapForUnit"] = {
      ["player"] = {
        { t = 0.000, v = 1426 },
        { t = 90.000, v = 1453 },
      },
    },
    ["C_Map.GetPlayerMapPosition"] = {
      ["player"] = {
        { t = 0.000, v = { x = 0.5477, y = 0.5486 } },
        { t = 5.200, v = { x = 0.5520, y = 0.5539 } },
        { t = 90.000, v = { x = 0.6111, y = 0.7422 } },
      },
    },

    -- Per-quest functions: parameterized by questId
    ["IsQuestComplete"] = {
      [56789] = {
        { t = 0.500, v = false },
        { t = 49.000, v = true },
      },
    },
    ["C_QuestLog.IsQuestFlaggedCompleted"] = {
      [56789] = {
        { t = 0.500, v = false },
        { t = 50.000, v = true },
      },
    },
    ["C_QuestLog.GetQuestObjectives"] = {
      [56789] = {
        { t = 0.500, v = {
          { text = " : 0/8", type = "item", finished = false, numFulfilled = 0, numRequired = 8 },
        }},
        { t = 0.850, v = {
          { text = "Tough Condor Meat: 0/8", type = "item", finished = false, numFulfilled = 0, numRequired = 8 },
        }},
        { t = 30.000, v = {
          { text = "Tough Condor Meat: 5/8", type = "item", finished = false, numFulfilled = 5, numRequired = 8 },
        }},
        { t = 49.000, v = {
          { text = "Tough Condor Meat: 8/8", type = "item", finished = true, numFulfilled = 8, numRequired = 8 },
        }},
      },
    },
    ["GetQuestLogTitle"] = {
      [56789] = {
        { t = 0.500, v = { "A New Threat", 2, false, false, false, false, false, 56789 } },
        { t = 49.000, v = { "A New Threat", 2, true, false, false, false, false, 56789 } },
      },
    },
    ["GetQuestTagInfo"] = {
      [56789] = {
        { t = 0.500, v = {} },
      },
    },

    -- Loot functions: parameterized by slot index
    ["GetLootSlotInfo"] = {
      [1] = {
        { t = 45.200, v = { "Icon\\Path", "Copper Coin", 1, n = 9 } },
        { t = 48.100, v = nil },
      },
      [2] = {
        { t = 45.200, v = { "Icon\\Path", "Linen Cloth", 2, n = 9 } },
        { t = 48.100, v = nil },
      },
    },
    ["GetLootSourceInfo"] = {
      [1] = {
        { t = 45.200, v = { "Creature-0-0-0-0-197-0000000001", 1, n = 2 } },
        { t = 48.100, v = nil },
      },
      [2] = {
        { t = 45.200, v = { "Creature-0-0-0-0-197-0000000001", 1, n = 2 } },
        { t = 48.100, v = nil },
      },
    },
    ["GetLootSlotLink"] = {
      [1] = {
        { t = 45.200, v = "|cff...|Hitem:...|h[Copper Coin]|h|r" },
        { t = 48.100, v = nil },
      },
      [2] = {
        { t = 45.200, v = "|cff...|Hitem:...|h[Linen Cloth]|h|r" },
        { t = 48.100, v = nil },
      },
    },
    ["GetLootSlotType"] = {
      [1] = {
        { t = 45.200, v = 1 },
        { t = 48.100, v = nil },
      },
      [2] = {
        { t = 45.200, v = 1 },
        { t = 48.100, v = nil },
      },
    },

    -- Player identity: parameterized, sampled once at t=0, never changes
    ["UnitRace"] = {
      ["player"] = { { t = 0.000, v = { "Dwarf", "Dwarf", 3 } } },
    },
    ["UnitClass"] = {
      ["player"] = { { t = 0.000, v = { "Priest", "PRIEST", 5 } } },
    },
    ["UnitSex"] = {
      ["player"] = { { t = 0.000, v = 2 } },
    },
  },

  functionsDelta = {
    ["GetQuestsCompleted"] = {
      t = 0,
      tp = 0,
      initial = { 123, 456, 789 },
      delta = {
        { t = 50.000, tp = 50.00012, add = { 56789 } },
      },
    },
  },
}
```

---

## 4) Tracking lifecycle

On `StartCapture`:

- Sample each function once and write the first `{t=0, v=...}` entry.
- No synthetic events like `CAPTURE_START`.

On each game event:

- Append raw row to `events`.
- Call relevant trackers (not all of them — only those that care about the event).
- Each tracker samples its function(s) and appends only if value changed.
- When multiple functions are sampled in the same call stack, all resulting
  entries use the same `t` value.

---

## 5) Time model

Every entry stores two timestamps — both relative to session start:

- `t` — from `GetTime()`. Cached once per frame. All samples taken in the
  same frame get the exact same `t`. Good for correlating values that were
  sampled together (e.g. all position functions in one call stack).
- `tp` — from `GetTimePreciseSec()`. Monotonic, millisecond precision,
  changes on every call. Good for precise ordering within a frame (e.g.
  two events that fire in the same frame get distinct `tp` values).

Both are always saved. The consumer uses whichever fits their need.

```lua
-- Session captures both clock baselines at start
capture.startedAt        = GetTime()
capture.startedAtPrecise = GetTimePreciseSec()

-- And both at stop
capture.stoppedAt        = GetTime()
capture.stoppedAtPrecise = GetTimePreciseSec()

-- Durations derived from both clocks
duration        = stoppedAt        - startedAt
durationPrecise = stoppedAtPrecise - startedAtPrecise

-- Every entry gets both relative timestamps
{ t = 5.213, tp = 5.21347, ... }
```

No mixed absolute/relative timestamps in stored data. Convert at capture time:

```lua
t  = GetTime()          - capture.startedAt
tp = GetTimePreciseSec() - capture.startedAtPrecise
```

---

## 6) Position: separate streams, shared sample time

These are separate functions and should be stored separately:

- `C_Map.GetBestMapForUnit("player")` -> parameterized by `"player"` -> map ID
- `C_Map.GetPlayerMapPosition(map, "player")` -> parameterized by `"player"` -> `{x, y}`
- `GetZoneText()` -> parameterless -> zone string
- `GetSubZoneText()` -> parameterless -> subzone string
- `GetRealZoneText()` -> parameterless -> real zone string

They are sampled in one call stack (same `t`), but stored as independent
streams because they change at different rates. XY changes constantly while
zone text may stay the same for an hour.

No positionLookup indirection. Each stream is self-contained.

```lua
-- Parameterless position functions
["GetZoneText"]     = { { t = 0.0, v = "Dun Morogh" }, { t = 90.0, v = "Stormwind City" } }
["GetSubZoneText"]  = { { t = 0.0, v = "Coldridge Valley" }, { t = 90.0, v = "Trade District" } }
["GetRealZoneText"] = { { t = 0.0, v = "Dun Morogh" }, { t = 90.0, v = "Stormwind City" } }

-- Parameterized position functions
["C_Map.GetBestMapForUnit"]    = { ["player"] = { { t = 0.0, v = 1426 }, { t = 90.0, v = 1453 } } }
["C_Map.GetPlayerMapPosition"] = { ["player"] = { { t = 0.0, v = { x = 0.5477, y = 0.5486 } }, ... } }
```

---

## 7) File split (for isolation, not framework)

Split files so that once a tracker is correct, it stays correct. A change to
loot capture should never be near reputation code.

- `QuestLogTrace.lua` — session lifecycle, event bus, slash commands
- `QuestLogTrace_UI.lua` — control frame (already separate)
- `Trackers/Position.lua` — the 5 position functions, sampled together
- `Trackers/UnitLevel.lua` — one function, trivial
- `Trackers/Reputation.lua` — reputation functions
- `Trackers/Loot.lua` — loot capture (GetNumLootItems + per-slot functions)
- `Trackers/QuestLog.lua` — quest log membership + per-quest functions
- `Trackers/CompletedQuests.lua` — `GetQuestsCompleted` delta stream
- `Trackers/PlayerIdentity.lua` — `UnitRace`, `UnitClass`, `UnitSex` (sampled once at t=0)

No shared tracker interface. No registry. `QuestLogTrace.lua` calls into each
tracker file directly, the same way it already calls `Core.CaptureReputationState`.

---

## 8) Event routing improvement

Current code runs `CaptureQuestState()` on every single event including noisy
irrelevant ones (inventory, chat, nameplates). This should be gated so that
only relevant events trigger each tracker. The file split naturally supports
this — each tracker file knows which events it cares about.

---

## 9) Migration approach

1. Migrate `UnitLevel.player` and position functions first (simplest).
2. Migrate reputation and loot next.
3. Quest state is the most complex — discuss separately before migrating.
4. Keep existing working code until each tracker is migrated and validated.
5. No "compatibility wrapper" layer — just move one tracker at a time.

---

## 10) Quest state design

### Quest log membership

`QuestLog` is a parameterless function stream. The value is the full array of
quest IDs currently in the log. The quest log is small (max ~25 quests), so
storing the full array each time it changes is acceptable.

```lua
["QuestLog"] = {
  { t = 0.000, v = { 12345 } },
  { t = 0.500, v = { 12345, 56789 } },
  { t = 50.000, v = { 12345 } },
}
```

### Per-quest functions

These are parameterized by `questId` and live in `functions`:

- `IsQuestComplete(questId)` — boolean, returns false when quest not in log
- `C_QuestLog.IsQuestFlaggedCompleted(questId)` — boolean
- `C_QuestLog.GetQuestObjectives(questId)` — array of QuestObjectiveInfo
- `GetQuestLogTitle(questId)` — raw return tuple
- `GetQuestTagInfo(questId)` — raw return tuple

Their lifecycle is natural: values appear when a quest enters the log and
the functions start returning meaningful data. The delayed re-sampling
(0.10, 0.35, 0.55s etc.) captures server-lag states where the API initially
returns incomplete data (e.g. objective text shows `" : 0/8"` before the
server sends the real item name).

### GetQuestsCompleted

Lives in `functionsDelta`. Initial set at capture start + delta entries
with `add` arrays. Quests cannot be uncompleted, so `remove` is omitted
in practice (but the format supports it). See section 2b.

### Triggering

Quest functions should only be sampled on quest-relevant events
(`QUEST_LOG_UPDATE`, `QUEST_ACCEPTED`, `QUEST_REMOVED`, `QUEST_TURNED_IN`,
etc.). The delayed re-sampling schedule is kept for quest trackers
specifically. Noisy events (inventory, chat, nameplates) should not
trigger quest sampling.

---

## 11) Triggers — how and when functions get sampled

This section needs real design work. There are several distinct trigger
patterns and they vary per tracker.

### Trigger types

1. **Event-driven** — sample when a specific game event fires.
   Example: `UnitLevel("player")` samples on `PLAYER_LEVEL_UP`.

2. **Timer-driven** — sample on a repeating interval regardless of events.
   Example: `C_Map.GetPlayerMapPosition` samples every 0.2s for smooth
   movement tracking.

3. **Event + delayed re-samples** — sample immediately on event, then
   re-sample at staggered delays (0.10, 0.35, 0.55s, etc.) to catch
   server-lag states. Example: quest functions where the API may return
   incomplete data on the first call.

4. **Event-driven with index iteration** — when an event fires, the
   tracker needs to iterate over a dynamic set of keys to sample.
   Example: on `QUEST_LOG_UPDATE`, iterate all quest IDs currently in
   the quest log and sample each per-quest function for each ID.

5. **Event-driven with window lifecycle** — sample on open event, reset
   to nil/0 on close event. Example: loot functions sample on
   `LOOT_READY` (iterate slot indices 1..GetNumLootItems), reset on
   `LOOT_CLOSED`.

### Per-tracker trigger design (known so far)

| Tracker file | Functions | Trigger type | Events |
|---|---|---|---|
| `UnitLevel.lua` | `UnitLevel["player"]` | Event-driven | `PLAYER_LEVEL_UP` |
| `Position.lua` | `C_Map.GetBestMapForUnit["player"]`, `C_Map.GetPlayerMapPosition["player"]`, `GetZoneText`, `GetSubZoneText`, `GetRealZoneText` | Timer (0.2s) + event-driven | `ZONE_CHANGED`, `ZONE_CHANGED_NEW_AREA`, `ZONE_CHANGED_INDOORS`, `PLAYER_ENTERING_WORLD`, `PLAYER_STARTED_MOVING`, `PLAYER_STOPPED_MOVING`, etc. |
| `Loot.lua` | `GetNumLootItems`, `GetLootSlotInfo[slot]`, `GetLootSourceInfo[slot]`, `GetLootSlotLink[slot]`, `GetLootSlotType[slot]` | Event-driven with window lifecycle | `LOOT_READY` (sample all slots), `LOOT_CLOSED` (reset all to nil/0) |
| `QuestLog.lua` | `QuestLog`, `IsQuestComplete[qid]`, `C_QuestLog.IsQuestFlaggedCompleted[qid]`, `C_QuestLog.GetQuestObjectives[qid]`, `GetQuestLogTitle[qid]`, `GetQuestTagInfo[qid]` | Event + delayed re-samples + index iteration | `QUEST_LOG_UPDATE`, `QUEST_ACCEPTED`, `QUEST_REMOVED`, `QUEST_TURNED_IN`, etc. |
| `CompletedQuests.lua` | `GetQuestsCompleted` (functionsDelta) | Event + delayed re-samples | Quest-relevant events (same as QuestLog) |
| `Reputation.lua` | TBD | TBD | TBD |
| `PlayerIdentity.lua` | `UnitRace["player"]`, `UnitClass["player"]`, `UnitSex["player"]` | Once at capture start | None (sampled at t=0 only) |

### Open questions

- Should the delayed re-sample schedule (0, 0.10, 0.35, 0.55, 0.75, 1.00)
  be per-tracker or shared? Current code uses one global schedule.
- For quest index iteration: when `QUEST_LOG_UPDATE` fires, do we sample
  ALL quests in the log, or try to detect which quest changed?
  (Current code samples all — simple and safe, but more work per event.)
- Position timer: 0.2s is the current interval. Is this the right balance
  between data density and storage cost?
- Reputation trigger design still needs discussion.

### Player identity (static, one entry each)

`UnitRace("player")`, `UnitClass("player")`, `UnitSex("player")` are
parameterized function streams like everything else. They are sampled once
at `t=0` and never change during a session — but they use the same format
so there is no separate `player` metadata block or special case.
