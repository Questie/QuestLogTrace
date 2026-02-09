# Schema Spec (v2)

This document specifies the SavedVariables layout produced by QuestLogTrace.

## 1) SavedVariables Tables

### `QuestLogTrace` (global/account-level)
- `schemaVersion: number`
- `settings: table`
  - `maxSessions: number`

Notes:
- No session payload is stored here.
- UI position is not persisted.

### `QuestLogTraceCharacter` (per-character)
- `sessions: SessionRecord[]`
- `player: PlayerStaticInfo?`
- `lastSavedSession: string?`
- `lastSessionSummary: SessionSummary?`

---

## 2) SessionRecord

Each `/qlt save` appends one `SessionRecord` to `QuestLogTraceCharacter.sessions`.

### SessionRecord fields
- `schemaVersion: number`
- `name: string`
- `startedAt: number`
- `stoppedAt: number`
- `duration: number`
- `trace: TraceStream`
- `state: StateStreams`
- `player: PlayerStaticInfo?`
- `summary: SessionSummary`

`startedAt`/`stoppedAt` are from `GetTime()`.

---

## 3) TraceStream

- `eventDict: string[]`
  - 1-based dictionary of event names.
- `events: CompactTraceEvent[]`
- `startLogIndex: number`
- `endLogIndex: number`

### CompactTraceEvent
- `i: number`
  - QLTrace row id (or fallback index).
- `e: number`
  - Event name id into `trace.eventDict`.
- `t: number`
  - Relative time from first captured trace event in this session (`0` for first row).
- `f: number`
  - Frame counter from QLTrace row.
- `a: PackedArgs`
  - Event args packed with `n` for nil-safe round-trip.

---

## 4) StateStreams

- `questHistory: table<questId, QuestSnapshot[]>`
- `questLogHistory: QuestLogSnapshot[]`
- `completedQuestsHistory: CompletedQuestsSnapshot[]`
- `questEventTriggers: TriggerRecord[]`
- `positionSamples: PositionSample[]`
- `levelEvents: LevelEvent[]`

### QuestSnapshot
- `t: number` (`GetTime()` when captured)
- `c: boolean` (`IsQuestComplete(questId)`)
- `f: boolean` (`C_QuestLog.IsQuestFlaggedCompleted(questId)`)
- `title: table` (raw tuple from `GetQuestLogTitle(GetQuestLogIndexByID(questId))`)
- `objectives: table` (raw return from `C_QuestLog.GetQuestObjectives(questId)`)
- `tag: table` (raw tuple from `GetQuestTagInfo(questId)`)

### QuestLogSnapshot
- `t: number` (`GetTime()` when captured)
- `q: number[]` (quest IDs currently in log)

### CompletedQuestsSnapshot
- `t: number` (`GetTime()` when captured)
- `q: number[]` (sorted quest IDs from `GetQuestsCompleted()`)

### TriggerRecord
- `e: string` (event name)
- `c: string` (event category)
- `t: number` (seconds since `session.startedAt`)
- `a: PackedArgs`
- `p: PositionSample?` (position captured immediately when trigger fired)

### PositionSample
- `t: number` (seconds since `session.startedAt`)
- `e: string` (source event name)
- `c: string` (source category)
- `d: number` (scheduled delay, e.g. `0`, `0.10`, `0.35`, ...)
- `m: number?` (`C_Map.GetBestMapForUnit("player")`)
- `x: number?` (map X from `GetPlayerMapPosition`)
- `y: number?` (map Y from `GetPlayerMapPosition`)
- `l: number` (`UnitLevel("player")`)
- `z: string` (`GetZoneText()`)
- `sz: string` (`GetSubZoneText()`)
- `rz: string` (`GetRealZoneText()`)

### LevelEvent
- `t: number` (seconds since `session.startedAt`)
- `e: string` (currently `PLAYER_LEVEL_UP`)
- `c: string` (category)
- `l: number` (`UnitLevel("player")`)
- `a: PackedArgs` (raw event payload)

---

## 5) PlayerStaticInfo

- `race: string`
- `raceLocalized: string`
- `raceID: number`
- `class: string`
- `classLocalized: string`
- `classID: number`
- `sex: number` (`UnitSex`)

Captured from:
- `UnitRace("player")`
- `UnitClass("player")`
- `UnitSex("player")`

---

## 6) SessionSummary

- `eventCount: number`
- `questCount: number`
- `questLogSnapshots: number`
- `completedQuestSnapshots: number`
- `completedQuestCount: number`
- `positionSampleCount: number`
- `levelEventCount: number`

---

## 7) PackedArgs Encoding

`PackedArgs` is a Lua table with:
- integer keys `1..n` for positional args
- `n: number` total argument count

This preserves explicit `nil` gaps in argument lists.

---

## 8) Change-Only Streams

These streams append snapshots only when value changes:
- `state.questHistory`
- `state.questLogHistory`
- `state.completedQuestsHistory`

These streams append on each trigger sample:
- `state.positionSamples`
- `state.questEventTriggers`
- `state.levelEvents` (only on level-up events)
