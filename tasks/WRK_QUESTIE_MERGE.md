# wrk-questie Merge Notes

Source branch: `origin/wrk-questie` / sibling worktree `../QuestLogTrace-wrk-questie`.

## Original intent from `MERGE.md`

`Tests/human_rogue_1to5.lua` was treated by the wrk-questie branch as a manifest for an unpushed schema-v8 trace branch. The branch intentionally avoided duplicating streams expected to arrive from that trace branch so the variants could be reconciled later with fewer conflicts.

### Streams wrk-questie intentionally left to the trace/master merge

- `GetInstanceInfo`
- `IsInInstance`
- `IsInGroup`
- `GetNumGroupMembers`
- `GetQuestGreenRange`
- `UnitFactionGroup`

### Overlap streams removed from wrk-questie

These were present in the trace manifest, so wrk-questie did not treat them as new work:

- `C_GossipInfo.GetAvailableQuests`
- `C_GossipInfo.GetActiveQuests`
- `GetQuestLogQuestText`

### New streams retained by wrk-questie

- `HaveQuestData`
- `UnitClassBase`
- `C_QuestLog.GetMaxNumQuestsCanAccept`
- `C_QuestLog.IsOnQuest`
- `GetQuestTimers`
- `GetQuestLogTimeLeft`
- `GetNumQuestLogRewards`
- `GetQuestLogRewardInfo`
- `GetQuestLogRewardMoney`
- `GetServerTime`
- `GetQuestResetTime`
- `C_GossipInfo.GetNumAvailableQuests`
- `C_GossipInfo.GetNumActiveQuests`
- `C_GossipInfo.GetText`
- `C_GossipInfo.GetOptions`
- `GetNumGossipAvailableQuests`
- `GetNumGossipActiveQuests`
- `GetGossipAvailableQuests`
- `GetGossipActiveQuests`
- quest greeting/dialog streams including `GetQuestID`, `GetActiveTitle`, `GetAvailableTitle`, `GetTitleText`, `GetQuestText`, `GetObjectiveText`, `GetProgressText`, `GetRewardText`, `GetRewardXP`, `IsQuestCompletable`, and `GetNumQuestChoices`

## Reconciliation status

Merged into `merge/wrk-questie-reconcile`:

- Added `Trackers/QuestDialog.lua` for gossip, greeting, and current quest-dialog API streams.
- Added `Trackers/ResetTime.lua` for low-frequency `GetServerTime` and `GetQuestResetTime` snapshots.
- Added `UnitClassBase["player"]` capture while preserving `UnitFactionGroup["player"]`.
- Expanded `Trackers/QuestLog.lua` with Questie replay streams, timer compatibility streams, reward streams, tombstones, and nested `GetQuestLogRewardInfo[rewardIndex][questId]` storage.
- Added recursive/nested function stream support to Lua annotations and trace analyzer lookup/UI.
- Kept movement start/stop as private Position sampling triggers, not recorded trace events.
- Added `Core.GetDiagnosticSession()` so bridge/tests can inspect the live unsaved session or newest saved session read-only by convention.
- Preserved existing per-character saved sessions on load instead of resetting `QuestLogTraceCharacter.sessions`.

Preserved from current master:

- `QuestLogTraceDumps`, dump registry APIs, dump slash/event routing, and `Dumps/MapHierarchy.lua`.
- `GroupState`, `SkillLines`, and `SpellBook` trackers.
- `UnitFactionGroup`, `GetQuestGreenRange`, instance streams, group streams, skill/profession streams, spellbook streams, and `PlayerKnownSpells` delta stream.
- `C_GossipInfo.GetAvailableQuests`, `C_GossipInfo.GetActiveQuests`, and `GetQuestLogQuestText` documentation/implementation.
- Login-time tracker events such as `PLAYER_ENTERING_WORLD` and `SPELLS_CHANGED`.

Deferred areas:

- Arbitrary call-observation or bounded discovery for inventory/item APIs.
- Broad arbitrary quest/faction/achievement API expansion beyond active/discovered IDs.
- Party replay APIs such as `UnitInParty` and `UnitInRaid`.
- In-game smoke validation of the reconciled QuestDialog/QuestLog reward/timer behavior.
