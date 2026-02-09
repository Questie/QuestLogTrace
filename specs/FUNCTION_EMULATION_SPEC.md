# Function Emulation Spec

This spec explains how another project can reconstruct function/API outputs at time `t`.

## 1) Time Model

There are two timestamp styles:

- Absolute `GetTime()` samples:
  - `state.questHistory[*].t`
  - `state.questLogHistory[*].t`
  - `state.completedQuestsHistory[*].t`
- Session-relative samples (seconds since `session.startedAt`):
  - `state.questEventTriggers[*].t`
  - `state.positionSamples[*].t`
  - `state.levelEvents[*].t`
  - `trace.events[*].t` (relative to first captured trace event, not session start)

Recommended canonical timeline:
- Use session-relative seconds.
- Convert absolute state timestamps as:
  - `t_rel = snapshot.t - session.startedAt`

## 2) Lookup Rule

For a value at target time `t_rel`:
- Select the latest snapshot whose `snapshot_time <= t_rel`.
- If none exists, value is `unknown` (or API default for your emulator).

## 3) Function/Data Mapping

### Quest Log Membership
- `GetAllQuestIdsInLog()`
- Source: `state.questLogHistory[*].q`

### Quest Completion Flags
- `IsQuestComplete(questId)`
- Source: latest `state.questHistory[questId][*].c`

- `C_QuestLog.IsQuestFlaggedCompleted(questId)`
- Source: latest `state.questHistory[questId][*].f`

### Quest Title Tuple
- `GetQuestLogTitle(GetQuestLogIndexByID(questId))`
- Source: latest `state.questHistory[questId][*].title`

### Quest Objectives
- `C_QuestLog.GetQuestObjectives(questId)`
- Source: latest `state.questHistory[questId][*].objectives`

### Quest Tag Info
- `GetQuestTagInfo(questId)`
- Source: latest `state.questHistory[questId][*].tag`

### Completed Quest Lifetime Set
- `GetQuestsCompleted([table])`
- Source: latest `state.completedQuestsHistory[*].q`
- Rebuild as associative map `{ [questId] = true }`

### Player Level
- `UnitLevel("player")`
- Preferred source: latest `state.positionSamples[*].l`
- Level transition events available in `state.levelEvents`

### Player Map Position
- `C_Map.GetBestMapForUnit("player")` -> latest `state.positionSamples[*].m`
- `C_Map.GetPlayerMapPosition(map, "player"):GetXY()` -> latest `state.positionSamples[*].x`, `y`

### Zone Text APIs
- `GetZoneText()` -> latest `state.positionSamples[*].z`
- `GetSubZoneText()` -> latest `state.positionSamples[*].sz`
- `GetRealZoneText()` -> latest `state.positionSamples[*].rz`

### Player Static Identity
- `UnitRace("player")`, `UnitClass("player")`, `UnitSex("player")`
- Source: `session.player` (fallback `QuestLogTraceCharacter.player`)

### Event Feed (raw)
- `trace.events` + `trace.eventDict`
- `state.questEventTriggers`
- Use these for event-order replay and correlation with state transitions.

## 4) Replay Construction Strategy

1. Load one `SessionRecord`.
2. Build normalized streams:
   - convert absolute state times to `t_rel`.
3. Sort each stream by time.
4. For query APIs, answer from latest snapshot <= `t_rel`.
5. For event replay, iterate `trace.events` by index order and/or `t`.
6. Apply quest/position streams as authoritative state snapshots.

## 5) Known Limits

- Trace event time (`trace.events[*].t`) is anchored to first trace event, not exact session start.
- Not all WoW APIs are captured; only mapped APIs above can be emulated directly.
- `GetQuestsCompleted` can include daily/account-wide behaviors from game rules.
