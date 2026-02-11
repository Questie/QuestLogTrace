# Schema Spec (v8)

## 1) SavedVariables

### `QuestLogTrace` (account-level)

```lua
QuestLogTrace = {
  schemaVersion = 8,
  settings = {
    maxSessions = 20,
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

---

## 7) Packed args encoding

Used in event args and tuple-returning function values.

```lua
{ value1, value2, ..., n = argCount }
```

`n` preserves the argument count even when `nil` appears in the middle.

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

### Parameterless

| Function key | Return type | Notes |
|---|---|---|
| `GetZoneText` | scalar (string) | |
| `GetSubZoneText` | scalar (string) | |
| `GetRealZoneText` | scalar (string) | |
| `GetNumLootItems` | scalar (number) | 0 when no loot window |
| `QuestLog` | object (number[]) | Full array of quest IDs in log |
| `FactionOrder` | object (number[]) | Ordered factionIDs for index lookup |

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
| `GetQuestLogTitle` | tuple (n=8) | |
| `GetQuestTagInfo` | tuple (n varies) | |

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
