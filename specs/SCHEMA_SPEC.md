# Schema Spec (v6)

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
- `eventRecords: EventRecord[]`
- `positionSamples: PositionSample[]`
- `positionLookup: PositionLookup`
- `levelEvents: LevelEvent[]`
- `lootHistory: LootSnapshot[]`
- `reputationHistory: table<factionID, ReputationDeltaSnapshot[]>`
- `reputationMeta: table<factionID, ReputationMeta>`

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
- `a: number[]` (quest IDs added since previous snapshot)
- `r: number[]` (quest IDs removed since previous snapshot)
- `c: number` (resulting completed-quest count after applying delta)

### EventRecord
- `e: string` (event name)
- `t: number` (seconds since `session.startedAt`)
- `a: PackedArgs`

### PositionSample
- `t: number` (seconds since `session.startedAt`)
- `p: number` (index into `positionLookup`)
- `x: number?` (map X from `GetPlayerMapPosition`)
- `y: number?` (map Y from `GetPlayerMapPosition`)

### PositionLookup
- `PositionContext[]` (1-based lookup table)

### PositionContext
- `m: number?` (map ID from `C_Map.GetBestMapForUnit("player")`)
- `z: string?` (zone name from `GetZoneText()`)
- `sz: string?` (subzone name from `GetSubZoneText()`)
- `rz: string?` (real zone name from `GetRealZoneText()`)

### LevelEvent
- `t: number` (seconds since `session.startedAt`)
- `e: string` (`CAPTURE_START` baseline or `PLAYER_LEVEL_UP`)
- `l: number` (`UnitLevel("player")`)
- `a: PackedArgs` (raw event payload)

### LootSnapshot
- `t: number` (`GetTime()` when captured)
- `e: string` (trigger event, currently `LOOT_READY`)
- `n: number` (`GetNumLootItems()` at capture time)
- `slots: LootSlotSnapshot[]`

### LootSlotSnapshot
- `i: number` (loot slot index)
- `l: PackedArgs` (raw return tuple of `GetLootSlotInfo(i)`)
- `s: PackedArgs` (raw return tuple of `GetLootSourceInfo(i)`)
- `k: string?` (return value of `GetLootSlotLink(i)`)
- `t: number?` (return value of `GetLootSlotType(i)`)

### ReputationDeltaSnapshot
- `t: number` (`GetTime()` when captured)
- `e: string` (`CAPTURE_START` baseline or `CHAT_MSG_COMBAT_FACTION_CHANGE`)
- `s: number?` (`standingID` if changed)
- `mn: number?` (`barMin` if changed)
- `mx: number?` (`barMax` if changed)
- `v: number?` (`barValue` if changed)
- `w: boolean?` (`atWarWith` if changed)
- `iw: boolean?` (`isWatched` if changed)

### ReputationMeta
- `n: string?` (faction name)
- `d: string?` (faction description)
- `ctw: boolean?` (`canToggleAtWar`)
- `h: boolean?` (`isHeader`)
- `hr: boolean?` (`hasRep`)
- `ch: boolean?` (`isChild`)
- `br: boolean?` (`hasBonusRepGain`)
- `csi: boolean?` (`canSetInactive`)

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
- `trackedEventCount: number`
- `questLogSnapshots: number`
- `completedQuestSnapshots: number`
- `lootSnapshotCount: number`
- `reputationFactionCount: number`
- `reputationSnapshotCount: number`
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

These streams append independently:
- `state.positionSamples`
- `state.eventRecords`
- `state.levelEvents`
- `state.lootHistory`
- `state.reputationHistory` (event-triggered, delta by `factionID`)

Notes:
- `state.positionSamples` is change-only for map/position/zone state.
- `state.eventRecords` is the tracked event stream and is not position-linked.
