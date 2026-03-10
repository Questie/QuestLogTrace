# QuestLogTrace Specs

Agent-facing index for understanding QuestLogTrace data capture and emulation system.
QuestLogTrace is a WoW Classic Era addon that records quest and gameplay events for
offline replay. Schema version 9.

---

## Quick Start (Read Order)

1. [ARCHITECTURE_SPEC.md](./ARCHITECTURE_SPEC.md) - File structure, load order, bootstrap
2. [SCHEMA_SPEC.md](./SCHEMA_SPEC.md) - SavedVariables structure and time model
3. [TRACKER_SPEC.md](./TRACKER_SPEC.md) - Tracker architecture, lifecycle, trigger patterns
4. [EVENT_CATALOG.md](./EVENT_CATALOG.md) - Event registration by tracker
5. [FUNCTION_EMULATION_SPEC.md](./FUNCTION_EMULATION_SPEC.md) - Reconstruct WoW API calls from captured data
6. [UI_SPEC.md](./UI_SPEC.md) - Control frame, slash commands, button states
7. [LuaLS_annotations.md](./LuaLS_annotations.md) - Lua type annotation reference

---

## System Map

```
┌─────────────────────────────────────────────────────────┐
│  globals.lua          Core namespace, utilities,        │
│                       RegisterTracker API               │
├─────────────────────────────────────────────────────────┤
│  Trackers/            10 isolated tracker files         │
│    PlayerIdentity     UnitRace, UnitClass, UnitSex      │
│    UnitLevel          UnitLevel["player"]               │
│    Position           Zone texts, map, XY position      │
│    Loot               Loot window functions             │
│    Reputation         FactionOrder, GetFactionInfoByID  │
│    QuestLog           Quest membership + per-quest data │
│    CompletedQuests    GetQuestsCompleted delta stream   │
│    GroupState         Party membership state            │
│    SkillLines         Skill window + profession tabs    │
│    SpellBook          Raw slot state + known spell set  │
├─────────────────────────────────────────────────────────┤
│  QuestLogTrace_UI     Control frame (Start/Stop/Save)   │
├─────────────────────────────────────────────────────────┤
│  QuestLogTrace        Event bus, session lifecycle,     │
│                       slash commands, bootstrap         │
└─────────────────────────────────────────────────────────┘
```

Primary JTBDs:
- Capture quest progression and gameplay events in WoW Classic Era
- Save detailed session data for offline analysis
- Enable replay/emulation of WoW API function calls at any timestamp

---

## Spec Layout

```
specs/
  README.md                    # This file
  ARCHITECTURE_SPEC.md         # File structure, load order, bootstrap, migration
  SCHEMA_SPEC.md               # SavedVariables schema (v9), time model, data formats
  TRACKER_SPEC.md              # Tracker interface, lifecycle, trigger patterns
  EVENT_CATALOG.md             # Events by tracker, unrouted events
  FUNCTION_EMULATION_SPEC.md   # Generic lookup algorithm for function replay
  UI_SPEC.md                   # Control frame, slash commands, button states
  LuaLS_annotations.md         # Lua type annotation guide
```

---

## Spec Summary

| Spec | Purpose |
|------|---------|
| [ARCHITECTURE_SPEC](./ARCHITECTURE_SPEC.md) | File load order, bootstrap sequence, SavedVariables management, migration, session pruning, shared utilities |
| [SCHEMA_SPEC](./SCHEMA_SPEC.md) | SessionRecord format, time model (t/tp), events, function streams, delta streams, packed args, return value encoding, function catalog |
| [TRACKER_SPEC](./TRACKER_SPEC.md) | TrackerDef interface, RegisterTracker API, CaptureState object, tracker lifecycle, 5 trigger patterns, per-tracker design table, reputation behavior |
| [EVENT_CATALOG](./EVENT_CATALOG.md) | Events tracked by each tracker, events captured but not routed, notes on LOOT_OPENED vs LOOT_READY |
| [FUNCTION_EMULATION_SPEC](./FUNCTION_EMULATION_SPEC.md) | Generic lookup algorithm (getStream/valueAt/emulate), function-to-stream mapping, derived functions, delta replay, event replay |
| [UI_SPEC](./UI_SPEC.md) | Three capture states (idle/running/stopped_unsaved), button state table, slash commands, StatusData type |
| [LuaLS_annotations](./LuaLS_annotations.md) | @param, @return, @class, @field, @alias, @type syntax reference |

---

## Tracker Summary

| Tracker | Events | Trigger Pattern | Purpose |
|---------|--------|-----------------|---------|
| PlayerIdentity | None | Init only (t=0) | `UnitRace`, `UnitClass`, `UnitSex` |
| UnitLevel | `PLAYER_LEVEL_UP` | Event-driven | `UnitLevel["player"]` |
| Position | 11 events + 0.2s timer | Timer + event-driven | Zone texts, map ID, XY position |
| Loot | `LOOT_READY`, `LOOT_CLOSED` | Window lifecycle | Loot count + per-slot functions |
| Reputation | 3 events | Event + index iteration | `FactionOrder`, `GetFactionInfoByID` |
| QuestLog | 14 quest events | Event + delayed re-samples + iteration | Quest membership + per-quest functions |
| CompletedQuests | 14 quest events | Event + delayed re-samples | `GetQuestsCompleted` delta stream |
| GroupState | 5 events | Event-driven | `IsInGroup`, `GetNumGroupMembers` |
| SkillLines | 3 events | Event + index iteration | `GetNumSkillLines`, `GetSkillLineInfo`, `GetProfessions`, `GetProfessionInfo` |
| SpellBook | 2 events | Event + slot iteration | `GetSpellBookItemName`, `GetSpellBookItemInfo`, `IsPassiveSpell`, `PlayerKnownSpells` |

---

## When You Need X, Read Y

| Need | Read |
|------|------|
| File structure and load order | [ARCHITECTURE_SPEC](./ARCHITECTURE_SPEC.md) |
| SavedVariables structure | [SCHEMA_SPEC](./SCHEMA_SPEC.md) |
| How trackers work | [TRACKER_SPEC](./TRACKER_SPEC.md) |
| What events trigger what | [EVENT_CATALOG](./EVENT_CATALOG.md) |
| How to replay function calls at time `t` | [FUNCTION_EMULATION_SPEC](./FUNCTION_EMULATION_SPEC.md) |
| UI behavior and slash commands | [UI_SPEC](./UI_SPEC.md) |
| Lua type annotation syntax | [LuaLS_annotations](./LuaLS_annotations.md) |
| Reputation collection vs sampling | [TRACKER_SPEC](./TRACKER_SPEC.md) section 8 |
| Delayed re-sample schedule | [TRACKER_SPEC](./TRACKER_SPEC.md) section 6 |
| Token-based timer invalidation | [TRACKER_SPEC](./TRACKER_SPEC.md) section 3 |

---

## Conventions

- Schema version is always 9 (current).
- All timestamps are session-relative (not absolute).
- All Lua code must use LuaLS annotations.
- `specs/` defines expected behavior; update it when implementation changes.
- Function streams can be parameterless or parameterized; detect automatically.
- Packed args use `{ ..., n = count }` format.
- `GetQuestsCompleted` and `PlayerKnownSpells` use delta streams, not standard function streams.

---

## Example Quest IDs (Classic Era)

| QuestID | Quest Name |
|---------|------------|
| 789 | Echo Ridge Mine |
| 6 | Bounty on Garrick Padfoot |
| 40 | Kobold Candles |
