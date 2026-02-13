# Schema Spec (v8)

## 1) SavedVariables

### `QuestLogTrace` (account-level)

```lua
QuestLogTrace = {
  schemaVersion = 8,
  settings = {
    maxSessions = 20,
    autoStart = true,
  },
}
```

### `QuestLogTraceCharacter` (per-character)

```lua
QuestLogTraceCharacter = {
  lastSavedSession = "2026-02-10_12-34-56",
  sessions = { SessionRecord, ... },
}
```

`lastSavedSession` is only set on explicit save — it is not initialized
on fresh install or migration.

### Migration

If `schemaVersion ~= 8`, the account-level table is wiped and recreated
with defaults. Per-character sessions from older versions are lost. There
is no incremental migration from v7 to v8.

### Session pruning

After every save, sessions exceeding `maxSessions` are removed oldest
first (FIFO). Default limit is 20.

---

## 2) SessionRecord

Each `/qlt save` appends one record to `QuestLogTraceCharacter.sessions`.

```lua
SessionRecord = {
  schemaVersion = 8,
  name = "2026-02-10_12-34-56",

  startedAt        = 100000.000,     -- GetTime() at capture start
  startedAtPrecise = 4821.31204,     -- GetTimePreciseSec() at capture start
  stoppedAt        = 100333.150,     -- GetTime() at capture stop
  stoppedAtPrecise = 5154.46238,     -- GetTimePreciseSec() at capture stop
  duration         = 333.150,        -- stoppedAt - startedAt
  durationPrecise  = 333.15034,      -- stoppedAtPrecise - startedAtPrecise

  events         = EventEntry[],
  functions      = table<string, FunctionStream>,
  functionsDelta = table<string, DeltaStream>,
}
```

No `summary` block — consumers derive counts from the data.
No `player` block — player identity is stored as function streams
(`UnitRace`, `UnitClass`, `UnitSex`).

---

## 3) Time model

All timestamps in entries are **session-relative** (seconds since capture
start). Two clocks are stored on every entry:

- `t` — from `GetTime()`. Cached once per frame. All samples in the same
  frame share the same `t`.
- `tp` — from `GetTimePreciseSec()`. Monotonic, millisecond precision,
  unique per call.

Conversion from absolute to relative at capture time:

```lua
t  = GetTime()          - session.startedAt
tp = GetTimePreciseSec() - session.startedAtPrecise
```

The session envelope stores absolute baselines so consumers can convert
back if needed.

---

## 4) Events

```lua
{ t = 0.000, tp = 0.00012, e = "QUEST_ACCEPTED", a = { 101, 56789, n = 2 } }
```

- `t`: session-relative `GetTime()`
- `tp`: session-relative `GetTimePreciseSec()`
- `e`: event name string
- `a`: packed args (see section 7)

---

## 5) Function streams

All tracked WoW API return values are stored in `functions`. Two formats
exist, distinguished by the parser automatically.

### Parameterless — flat array

```lua
["GetZoneText"] = {
  { t = 0.000, tp = 0.00015, v = "Dun Morogh" },
  { t = 90.000, tp = 90.00022, v = "Stormwind City" },
}
```

### Parameterized — keyed by argument

```lua
["UnitLevel"] = {
  ["player"] = {
    { t = 0.000, tp = 0.00020, v = 12 },
    { t = 5.213, tp = 5.21350, v = 13 },
  },
}
```

### Parser detection

If the first entry in the table has a `t` field, it is a flat
(parameterless) stream. Otherwise, the keys are argument values and each
value is a `{t, tp, v}` array.

### Change-only

Entries are appended only when the value changes. The first entry is
always the full value at `t=0` (capture start). The latest entry before
a target time is the current value at that time.

### `nil` is a valid value

When a function returns `nil`, that is stored as a change. This is how
transient-window APIs (e.g. loot functions between `LOOT_READY` and
`LOOT_CLOSED`) return to their inactive state.

**Nil serialization note.** When code stores `{ t = t, tp = tp, v = nil }`,
Lua serialization omits the `v` key entirely. After deserialization, the
entry appears as `{ t = ..., tp = ... }` with no `v` field. This is
transparent to consumers because `entry.v == nil` evaluates to `true`
regardless of whether the key exists or was omitted. The emulation
algorithm handles this correctly with no special handling needed.

---

## 6) Delta streams

For functions that return large sets (e.g. `GetQuestsCompleted` —
thousands of quest IDs). Stored in `functionsDelta`.

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

- `initial`: full set at capture start.
- `delta`: ordered entries with `add` and/or `remove` arrays.
- Empty `add`/`remove` arrays are omitted during serialization.
- `GetQuestsCompleted` only ever grows in practice (quests cannot be
  uncompleted), but the format supports `remove` for generality.

---

## 7) Packed args encoding

Used in event args and tuple-returning function values.

```lua
{ value1, value2, ..., n = argCount }
```

`n` preserves the argument count even when `nil` appears in the middle.

**Sparse arrays after serialization.** When WoW API functions return `nil`
in middle positions, Lua serialization omits those values, creating gaps
in the stored array (e.g. indices jump from 3 to 5). The `n` field is
authoritative for the true argument count. Consumers must use
`unpack(v, 1, v.n)` to correctly reconstruct nils for missing indices.
This is expected behavior, not a bug.

---

## 8) Return value format

The stored `v` in a function entry is self-describing:

| `v` shape | Meaning | Emulator action |
|---|---|---|
| `type(v) == "table" and v.n` | Packed tuple | `return unpack(v, 1, v.n)` |
| `type(v) == "table"` (no `n`) | Object/table | `return v` |
| scalar (number, string, boolean, nil) | Single value | `return v` |

All tuple-returning functions MUST have `n` on every stored value.

---

## 9) Complete function catalog

> **API vs synthetic keys.** Most function keys in the tables below are
> direct WoW API names (e.g. `GetZoneText`, `UnitLevel`). Two keys are
> **synthetic** -- they are computed by our trackers rather than matching a
> single WoW API function. These are marked with *(synthetic)* below.

### Parameterless

| Function key | Return type | Notes |
|---|---|---|
| `GetZoneText` | scalar (string) | |
| `GetSubZoneText` | scalar (string) | |
| `GetRealZoneText` | scalar (string) | |
| `GetNumLootItems` | scalar (number) | 0 when no loot window |
| `QuestLog` | object (number[]) | *(synthetic)* Computed by iterating GetQuestLogTitle, not a WoW API function |
| `FactionOrder` | object (number[]) | *(synthetic)* Computed by iterating GetFactionInfo and expanding headers, not a WoW API function |

### Parameterized by `"player"`

| Function key | Return type | Notes |
|---|---|---|
| `UnitLevel` | scalar (number) | |
| `UnitRace` | tuple (n=3) | localizedName, englishName, raceID |
| `UnitClass` | tuple (n=3) | localizedName, englishName, classID |
| `UnitSex` | scalar (number) | |
| `C_Map.GetBestMapForUnit` | scalar (number) | map ID |
| `C_Map.GetPlayerMapPosition` | object ({x, y}) | rounded to 4 decimals |

### Parameterized by questId

| Function key | Return type | Notes |
|---|---|---|
| `IsQuestComplete` | scalar (boolean) | |
| `C_QuestLog.IsQuestFlaggedCompleted` | scalar (boolean) | |
| `C_QuestLog.GetQuestObjectives` | object (QuestObjectiveInfo[]) | |
| `GetQuestLogTitle` | tuple (n=17) | |
| `GetQuestTagInfo` | tuple (n varies) | |

### Parameterized by unit token (`"target"`, `"npc"`, `"questnpc"`)

| Function key | Return type | Notes |
|---|---|---|
| `UnitGUID` | scalar (string) or nil | GUID string; nil when no unit |
| `UnitName` | tuple (n=2) or nil | name, realm; nil when no unit |

### Parameterized by slot index

| Function key | Return type | Notes |
|---|---|---|
| `GetLootSlotInfo` | tuple (n=9) | nil when loot window closed |
| `GetLootSourceInfo` | tuple (n=2) | nil when loot window closed |
| `GetLootSlotLink` | scalar (string) | nil when loot window closed |
| `GetLootSlotType` | scalar (number) | nil when loot window closed |

### Parameterized by factionID

| Function key | Return type | Notes |
|---|---|---|
| `GetFactionInfoByID` | tuple (n=16) | Full 16-value API return |

### Delta streams (in `functionsDelta`)

| Function key | Notes |
|---|---|
| `GetQuestsCompleted` | Only grows (remove absent in practice) |

---

## 10) Complete annotated session example

Below is a single `SessionRecord` showing what a real saved session looks
like. Every format variant (parameterless streams, parameterized streams,
tuples, objects, scalars, delta streams) is represented with a small
number of entries.

```lua
{
  schemaVersion = 8,
  name = "2026-02-10_12-34-56",

  -- Session envelope: absolute clock baselines and derived durations
  startedAt        = 100000.000,     -- GetTime() at capture start
  startedAtPrecise = 4821.31204,     -- GetTimePreciseSec() at capture start
  stoppedAt        = 100333.150,     -- GetTime() at capture stop
  stoppedAtPrecise = 5154.46238,     -- GetTimePreciseSec() at capture stop
  duration         = 333.150,        -- stoppedAt - startedAt
  durationPrecise  = 333.15034,      -- stoppedAtPrecise - startedAtPrecise

  -----------------------------------------------------------------------
  -- Events: raw time-series of game signals
  -----------------------------------------------------------------------
  events = {
    { t = 0.000, tp = 0.00012, e = "PLAYER_ENTERING_WORLD", a = { n = 0 } },
    { t = 0.500, tp = 0.50021, e = "QUEST_ACCEPTED", a = { 101, 56789, n = 2 } },
    { t = 5.213, tp = 5.21347, e = "PLAYER_LEVEL_UP", a = { 13, 120, 40, 0, 0, 0, 1, 1, 1, 1, n = 10 } },
    { t = 45.200, tp = 45.20021, e = "LOOT_READY", a = { n = 0 } },
    { t = 48.100, tp = 48.10008, e = "LOOT_CLOSED", a = { n = 0 } },
    { t = 50.000, tp = 50.00005, e = "QUEST_TURNED_IN", a = { 56789, n = 1 } },
  },

  -----------------------------------------------------------------------
  -- Function streams
  -----------------------------------------------------------------------
  functions = {

    ---- Parameterless: flat {t, tp, v} arrays ----

    -- Zone text (scalar string)
    ["GetZoneText"] = {
      { t = 0.000, tp = 0.00015, v = "Dun Morogh" },
      { t = 90.000, tp = 90.00022, v = "Stormwind City" },
    },

    -- Loot item count (scalar number, 0 = no loot window)
    ["GetNumLootItems"] = {
      { t = 0.000, tp = 0.00018, v = 0 },
      { t = 45.200, tp = 45.20025, v = 2 },
      { t = 48.100, tp = 48.10012, v = 0 },
    },

    -- Quest log membership (synthetic: object, number[])
    ["QuestLog"] = {
      { t = 0.000, tp = 0.00019, v = { 12345 } },
      { t = 0.500, tp = 0.50025, v = { 12345, 56789 } },
      { t = 50.000, tp = 50.00010, v = { 12345 } },
    },

    -- Faction display order (synthetic: object, number[])
    ["FactionOrder"] = {
      { t = 0.000, tp = 0.00042, v = { 47, 72, 54, 69, 930, 509, 87, 21 } },
    },

    ---- Parameterized by "player" ----

    -- UnitLevel (scalar number)
    ["UnitLevel"] = {
      ["player"] = {
        { t = 0.000, tp = 0.00020, v = 12 },
        { t = 5.213, tp = 5.21350, v = 13 },
      },
    },

    -- UnitRace (tuple, n=3)
    ["UnitRace"] = {
      ["player"] = {
        { t = 0.000, tp = 0.00023, v = { "Dwarf", "Dwarf", 3, n = 3 } },
      },
    },

    -- Map position (object {x, y}, rounded to 4 decimals)
    ["C_Map.GetPlayerMapPosition"] = {
      ["player"] = {
        { t = 0.000, tp = 0.00022, v = { x = 0.5477, y = 0.5486 } },
        { t = 5.200, tp = 5.20010, v = { x = 0.5520, y = 0.5539 } },
        { t = 90.000, tp = 90.00027, v = { x = 0.6111, y = 0.7422 } },
      },
    },

    ---- Parameterized by questId ----

    -- IsQuestComplete (scalar boolean)
    ["IsQuestComplete"] = {
      [56789] = {
        { t = 0.500, tp = 0.50030, v = false },
        { t = 49.000, tp = 49.00015, v = true },
      },
    },

    -- Quest objectives (object, QuestObjectiveInfo[])
    ["C_QuestLog.GetQuestObjectives"] = {
      [56789] = {
        { t = 0.500, tp = 0.50032, v = {
          { text = "Tough Condor Meat: 0/8", type = "item", finished = false, numFulfilled = 0, numRequired = 8 },
        }},
        { t = 49.000, tp = 49.00020, v = {
          { text = "Tough Condor Meat: 8/8", type = "item", finished = true, numFulfilled = 8, numRequired = 8 },
        }},
      },
    },

    -- GetQuestLogTitle (tuple, n=17)
    -- Returns: title, level, suggestedGroup, isHeader, isCollapsed, isComplete,
    --          frequency, questID, startEvent, displayQuestID, isOnMap,
    --          hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling
    ["GetQuestLogTitle"] = {
      [56789] = {
        { t = 0.500, tp = 0.50033, v = { "A New Threat", 2, 0, false, false, false, 0, 56789, false, false, false, false, false, false, false, false, false, n = 17 } },
        { t = 49.000, tp = 49.00021, v = { "A New Threat", 2, 0, false, false, true, 0, 56789, false, false, false, false, false, false, false, false, false, n = 17 } },
      },
    },

    ---- Parameterized by slot index ----

    -- GetLootSlotInfo (tuple, n=9; nil when loot window closed)
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

    ---- Parameterized by factionID ----

    -- GetFactionInfoByID (tuple, n=16)
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
  },

  -----------------------------------------------------------------------
  -- Delta streams (functionsDelta)
  -----------------------------------------------------------------------
  functionsDelta = {
    -- GetQuestsCompleted: initial set + ordered delta entries
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
