# Updated Design Notes (v8 direction)

This file captures the design discussion so it is not lost.

## 1) Core mental model

Three top-level concepts:

- `events` = raw time-series of game signals. Already good, no changes needed.
- `functions` = per-function value streams. A flat array of `{t, tp, v}` entries.
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

Functions with no arguments are stored as a flat `{t, tp, v}` array directly:

```lua
["GetZoneText"] = {
  { t = 0.000, tp = 0.00015, v = "Dun Morogh" },
  { t = 90.000, tp = 90.00022, v = "Stormwind City" },
}

["GetNumLootItems"] = {
  { t = 0.000, tp = 0.00018, v = 0 },          -- session start, no loot window
  { t = 45.200, tp = 45.20025, v = 2 },         -- LOOT_READY fired
  { t = 48.100, tp = 48.10012, v = 0 },         -- LOOT_CLOSED fired
}
```

### Parameterized functions — keyed by argument

Functions that take arguments are stored as a table keyed by the argument
value. Each key maps to a `{t, tp, v}` array. The key is the actual value you
would pass to the function (number, string, etc.).

```lua
["UnitLevel"] = {
  ["player"] = {
    { t = 0.000, tp = 0.00020, v = 12 },
    { t = 5.213, tp = 5.21350, v = 13 },
  },
}

["GetLootSlotInfo"] = {
  [1] = {
    { t = 45.200, tp = 45.20030, v = { "Icon\\Path", "Copper Coin", 1, n = 9 } },
    { t = 48.100, tp = 48.10015, v = nil },
  },
  [2] = {
    { t = 45.200, tp = 45.20031, v = { "Icon\\Path", "Linen Cloth", 2, n = 9 } },
    { t = 48.100, tp = 48.10016, v = nil },
  },
}

["C_Map.GetPlayerMapPosition"] = {
  ["player"] = {
    { t = 0.000, tp = 0.00025, v = { x = 0.5477, y = 0.5486 } },
    { t = 0.200, tp = 0.20010, v = { x = 0.5480, y = 0.5490 } },
    { t = 90.000, tp = 90.00030, v = { x = 0.6111, y = 0.7422 } },
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

### Return value format — tuples vs objects vs scalars

The stored `v` tells the emulator how to return it:

- **Tuple** (old-style APIs like `GetFactionInfoByID`, `UnitRace`, `GetQuestLogTitle`):
  stored as a packed-args table with `n`. The emulator returns `unpack(v, 1, v.n)`.
- **Object/table** (newer APIs like `C_QuestLog.GetQuestObjectives`, `C_Map.GetPlayerMapPosition`):
  stored as a plain table without `n`. The emulator returns `v` directly.
- **Scalar** (single values like `UnitLevel`, `GetZoneText`, `IsQuestComplete`):
  stored as the raw value (number, string, boolean, nil). The emulator returns `v` directly.

The `n` field is the discriminator. If `type(v) == "table" and v.n` then it is
a packed tuple; otherwise return `v` as-is.

```lua
-- Generic emulator return:
if type(v) == "table" and v.n then
  return unpack(v, 1, v.n)   -- tuple
else
  return v                     -- scalar or object
end
```

**All tuple-returning functions MUST store `n` on every value.** This is what
makes the format self-describing — no function registry needed.

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
      { t = 0.000, tp = 0.00015, v = "Dun Morogh" },
      { t = 90.000, tp = 90.00022, v = "Stormwind City" },
    },
    ["GetSubZoneText"] = {
      { t = 0.000, tp = 0.00016, v = "Coldridge Valley" },
      { t = 90.000, tp = 90.00023, v = "Trade District" },
    },
    ["GetRealZoneText"] = {
      { t = 0.000, tp = 0.00017, v = "Dun Morogh" },
      { t = 90.000, tp = 90.00024, v = "Stormwind City" },
    },
    ["GetNumLootItems"] = {
      { t = 0.000, tp = 0.00018, v = 0 },
      { t = 45.200, tp = 45.20025, v = 2 },
      { t = 48.100, tp = 48.10012, v = 0 },
    },

    -- Quest log membership: full array, small enough to store each time
    ["QuestLog"] = {
      { t = 0.000, tp = 0.00019, v = { 12345 } },
      { t = 0.500, tp = 0.50025, v = { 12345, 56789 } },           -- quest accepted
      { t = 50.000, tp = 50.00010, v = { 12345 } },                  -- quest turned in
    },

    -- Parameterized: keyed by argument
    ["UnitLevel"] = {
      ["player"] = {
        { t = 0.000, tp = 0.00020, v = 12 },
        { t = 5.213, tp = 5.21350, v = 13 },
      },
    },
    ["C_Map.GetBestMapForUnit"] = {
      ["player"] = {
        { t = 0.000, tp = 0.00021, v = 1426 },
        { t = 90.000, tp = 90.00026, v = 1453 },
      },
    },
    ["C_Map.GetPlayerMapPosition"] = {
      ["player"] = {
        { t = 0.000, tp = 0.00022, v = { x = 0.5477, y = 0.5486 } },
        { t = 5.200, tp = 5.20010, v = { x = 0.5520, y = 0.5539 } },
        { t = 90.000, tp = 90.00027, v = { x = 0.6111, y = 0.7422 } },
      },
    },

    -- Per-quest functions: parameterized by questId
    ["IsQuestComplete"] = {
      [56789] = {
        { t = 0.500, tp = 0.50030, v = false },
        { t = 49.000, tp = 49.00015, v = true },
      },
    },
    ["C_QuestLog.IsQuestFlaggedCompleted"] = {
      [56789] = {
        { t = 0.500, tp = 0.50031, v = false },
        { t = 50.000, tp = 50.00015, v = true },
      },
    },
    ["C_QuestLog.GetQuestObjectives"] = {
      [56789] = {
        { t = 0.500, tp = 0.50032, v = {
          { text = " : 0/8", type = "item", finished = false, numFulfilled = 0, numRequired = 8 },
        }},
        { t = 0.850, tp = 0.85010, v = {
          { text = "Tough Condor Meat: 0/8", type = "item", finished = false, numFulfilled = 0, numRequired = 8 },
        }},
        { t = 30.000, tp = 30.00018, v = {
          { text = "Tough Condor Meat: 5/8", type = "item", finished = false, numFulfilled = 5, numRequired = 8 },
        }},
        { t = 49.000, tp = 49.00020, v = {
          { text = "Tough Condor Meat: 8/8", type = "item", finished = true, numFulfilled = 8, numRequired = 8 },
        }},
      },
    },
    ["GetQuestLogTitle"] = {
      [56789] = {
        { t = 0.500, tp = 0.50033, v = { "A New Threat", 2, false, false, false, false, false, 56789, n = 8 } },
        { t = 49.000, tp = 49.00021, v = { "A New Threat", 2, true, false, false, false, false, 56789, n = 8 } },
      },
    },
    ["GetQuestTagInfo"] = {
      [56789] = {
        { t = 0.500, tp = 0.50034, v = { n = 0 } },
      },
    },

    -- Loot functions: parameterized by slot index
    ["GetLootSlotInfo"] = {
      [1] = {
        { t = 45.200, tp = 45.20030, v = { "Icon\\Path", "Copper Coin", 1, n = 9 } },
        { t = 48.100, tp = 48.10015, v = nil },
      },
      [2] = {
        { t = 45.200, tp = 45.20031, v = { "Icon\\Path", "Linen Cloth", 2, n = 9 } },
        { t = 48.100, tp = 48.10016, v = nil },
      },
    },
    ["GetLootSourceInfo"] = {
      [1] = {
        { t = 45.200, tp = 45.20032, v = { "Creature-0-0-0-0-197-0000000001", 1, n = 2 } },
        { t = 48.100, tp = 48.10017, v = nil },
      },
      [2] = {
        { t = 45.200, tp = 45.20033, v = { "Creature-0-0-0-0-197-0000000001", 1, n = 2 } },
        { t = 48.100, tp = 48.10018, v = nil },
      },
    },
    ["GetLootSlotLink"] = {
      [1] = {
        { t = 45.200, tp = 45.20034, v = "|cff...|Hitem:...|h[Copper Coin]|h|r" },
        { t = 48.100, tp = 48.10019, v = nil },
      },
      [2] = {
        { t = 45.200, tp = 45.20035, v = "|cff...|Hitem:...|h[Linen Cloth]|h|r" },
        { t = 48.100, tp = 48.10020, v = nil },
      },
    },
    ["GetLootSlotType"] = {
      [1] = {
        { t = 45.200, tp = 45.20036, v = 1 },
        { t = 48.100, tp = 48.10021, v = nil },
      },
      [2] = {
        { t = 45.200, tp = 45.20037, v = 1 },
        { t = 48.100, tp = 48.10022, v = nil },
      },
    },

    -- Reputation: faction order (for index-based lookup)
    ["FactionOrder"] = {
      { t = 0.000, tp = 0.00042, v = { 47, 72, 54, 69, 930, 509, 87, 21 } },
    },

    -- Reputation: parameterized by factionID, full 16-value tuple as returned by API
    ["GetFactionInfoByID"] = {
      [47] = {  -- Ironforge
        { t = 0.000, tp = 0.00043, v = {
          "Ironforge", "Home city of the Dwarves.", 5, 3000, 9000, 4500,
          false, false, false, false, true, false, 47, true, false, false,
          n = 16,
        }},
        { t = 120.500, tp = 120.50018, v = {
          "Ironforge", "Home city of the Dwarves.", 5, 3000, 9000, 4520,
          false, false, false, false, true, false, 47, true, false, false,
          n = 16,
        }},
      },
      [72] = {  -- Stormwind
        { t = 0.000, tp = 0.00044, v = {
          "Stormwind", "Alliance capital.", 6, 9000, 21000, 15200,
          false, false, false, false, true, false, 72, false, false, false,
          n = 16,
        }},
      },
    },

    -- Player identity: parameterized, sampled once at t=0, never changes
    ["UnitRace"] = {
      ["player"] = { { t = 0.000, tp = 0.00023, v = { "Dwarf", "Dwarf", 3, n = 3 } } },
    },
    ["UnitClass"] = {
      ["player"] = { { t = 0.000, tp = 0.00024, v = { "Priest", "PRIEST", 5, n = 3 } } },
    },
    ["UnitSex"] = {
      ["player"] = { { t = 0.000, tp = 0.00025, v = 2 } },
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

- Sample each function once and write the first `{t=0, tp=0, v=...}` entry.
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
["GetZoneText"]     = { { t = 0.0, tp = 0.00015, v = "Dun Morogh" }, { t = 90.0, tp = 90.00022, v = "Stormwind City" } }
["GetSubZoneText"]  = { { t = 0.0, tp = 0.00016, v = "Coldridge Valley" }, { t = 90.0, tp = 90.00023, v = "Trade District" } }
["GetRealZoneText"] = { { t = 0.0, tp = 0.00017, v = "Dun Morogh" }, { t = 90.0, tp = 90.00024, v = "Stormwind City" } }

-- Parameterized position functions
["C_Map.GetBestMapForUnit"]    = { ["player"] = { { t = 0.0, tp = 0.00021, v = 1426 }, { t = 90.0, tp = 90.00026, v = 1453 } } }
["C_Map.GetPlayerMapPosition"] = { ["player"] = { { t = 0.0, tp = 0.00022, v = { x = 0.5477, y = 0.5486 } }, ... } }
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

## 8) Event routing

Each tracker file registers which events it cares about. The event bus in
`QuestLogTrace.lua` dispatches incoming events only to trackers that
registered for them. This replaces the current approach where
`CaptureQuestState()` runs on every single event including noisy irrelevant
ones.

Each tracker exposes a registration function (e.g. `Core.RegisterTracker`)
that declares its event list and callback. The main file builds an
`event → { callback1, callback2, ... }` lookup at load time. When an event
fires, only the registered callbacks run.

The implementation for each tracker will be different — some are simple
callbacks, some need delayed re-samples, some iterate indices. That's fine.
The routing layer just dispatches; each tracker handles its own logic.

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
  { t = 0.000, tp = 0.00019, v = { 12345 } },
  { t = 0.500, tp = 0.50025, v = { 12345, 56789 } },
  { t = 50.000, tp = 50.00010, v = { 12345 } },
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
| `Reputation.lua` | `FactionOrder`, `GetFactionInfoByID[factionID]` | Event-driven with index iteration | `CHAT_MSG_COMBAT_FACTION_CHANGE`, `UPDATE_FACTION`, `QUEST_TURNED_IN` |
| `PlayerIdentity.lua` | `UnitRace["player"]`, `UnitClass["player"]`, `UnitSex["player"]` | Once at capture start | None (sampled at t=0 only) |

### Decisions

- **Delayed re-sample schedule**: keep the current global schedule
  (0, 0.10, 0.35, 0.55, 0.75, 1.00) as-is. Keep it simple.
- **Quest sampling scope**: sample ALL quests in the log on every quest
  event. Many different events can affect quest state, and detecting
  which quest changed adds complexity for little gain.
- **Position timer**: keep 0.2s. Current value works, optimize later if
  needed.

### Player identity (static, one entry each)

`UnitRace("player")`, `UnitClass("player")`, `UnitSex("player")` are
parameterized function streams like everything else. They are sampled once
at `t=0` and never change during a session — but they use the same format
so there is no separate `player` metadata block or special case.

---

## 12) Reputation design

### API landscape

`GetFactionInfoByID(factionID)` returns 16 values — the same as
`GetFactionInfo(factionIndex)` but keyed by stable ID instead of
UI-dependent index. Both must be supported by the emulator.

The 16 return values (all stored as-is, `n = 16`):

| # | Name | Notes |
|---|------|-------|
| 1 | name | faction name |
| 2 | description | detail pane text |
| 3 | standingID | standing level (4=Neutral, 5=Friendly, etc.) |
| 4 | barMin | changes when standing changes |
| 5 | barMax | changes when standing changes |
| 6 | barValue | the actual rep number |
| 7 | atWarWith | player can toggle |
| 8 | canToggleAtWar | capability flag |
| 9 | isHeader | hierarchy flag |
| 10 | isCollapsed | always false after expand-only collection |
| 11 | hasRep | whether header has own rep bar |
| 12 | isWatched | player can toggle |
| 13 | isChild | second-level header or child |
| 14 | factionID | also the table key |
| 15 | hasBonusRepGain | Grand Commendation purchased |
| 16 | canSetInactive | can be set inactive |

### What we store

Two function streams:

**`GetFactionInfoByID[factionID]`** — parameterized by factionID. Each value
is the full 16-value tuple exactly as the API returns it (`n = 16`). Nothing
is omitted — `isCollapsed` and `factionID` are included for simplicity. The
emulator just does `unpack(v, 1, v.n)` with no manipulation. Static fields
repeat but are cheap (Lua interns strings in SavedVariables). Can be
optimized later if storage becomes a concern.

**`FactionOrder`** — parameterless. The value is an ordered array of
factionIDs in their fully-expanded display order. This captures the index
mapping so the emulator can serve `GetFactionInfo(index)` lookups.

The emulator derives:
- `GetFactionInfoByID(factionID)` → direct lookup, `unpack(v, 1, v.n)`
- `GetFactionInfo(index)` → `factionID = FactionOrder[index]` →
  return `GetFactionInfoByID(factionID)` data
- `GetNumFactions()` → `#FactionOrder`

### The expand problem

`GetNumFactions()` returns visible rows, which depends on header
expand/collapse state. To discover all factions, we must iterate
`GetFactionInfo(index)` and call `ExpandFactionHeader(index)` on collapsed
headers. This has two side effects:

1. **Fires `UPDATE_FACTION`** — could trigger our own capture (recursion).
2. **Mutates the player's UI** — expanded headers stay expanded.

Policy (unchanged from WP-19): **expand-only, never re-collapse.** After
our first collection pass, all headers are expanded.

### Collection vs sampling

The collection step (discovering faction IDs) is separated from the
sampling step (reading current values):

**CollectFactionIDs** (has side effects):
- Iterates `GetFactionInfo(1..GetNumFactions())`
- Expands collapsed headers to discover children
- Returns ordered array of factionIDs
- Updates `FactionOrder` if the set changed
- Run at: capture start, `QUEST_TURNED_IN` (quest rewards can reveal new
  factions)

**SampleReputation** (pure reads):
- For each known factionID, calls `GetFactionInfoByID(factionID)`
- Compares against previous value (DeepCompare)
- Appends `{t, tp, v}` only if changed
- Run at: `CHAT_MSG_COMBAT_FACTION_CHANGE`, `UPDATE_FACTION`,
  `QUEST_TURNED_IN`

Guard against recursion: if `ExpandFactionHeader` fires `UPDATE_FACTION`
during collection, the handler should check a `collecting` flag and skip
re-entry.

### No delayed re-samples

Unlike quest functions where the server lags behind, reputation changes
are atomic — `GetFactionInfoByID` returns the correct value immediately
when the event fires. No staggered re-sampling needed.

---

## 13) Unsaved capture protection

When a session has been stopped but not saved, the Start button should
change to **Reset**. Pressing Reset discards the unsaved session and
starts fresh. This eliminates silent data loss from stop → start without
save (WP-16).

UI states:

| Capture state | Start button | Stop button | Save button |
|---|---|---|---|
| Idle (no session) | **Start** (enabled) | disabled | disabled |
| Running | disabled | **Stop** (enabled) | disabled |
| Stopped, unsaved | **Reset** (enabled) | disabled | **Save** (enabled) |
