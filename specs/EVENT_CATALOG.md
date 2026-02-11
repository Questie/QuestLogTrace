# Event Catalog (v8)

All events are recorded to `session.events` with full packed args. Events
are also used to trigger tracker sampling — each tracker registers which
events it cares about.

## Events by tracker

### QuestLog tracker

Triggers quest log membership scan and per-quest function sampling.

- `QUEST_LOG_UPDATE`
- `QUEST_ACCEPTED`
- `QUEST_REMOVED`
- `QUEST_TURNED_IN`
- `QUEST_WATCH_UPDATE`
- `UNIT_QUEST_LOG_CHANGED`
- `QUEST_AUTOCOMPLETE`
- `QUEST_POI_UPDATE`
- `QUEST_ITEM_UPDATE`
- `QUEST_LOG_CRITERIA_UPDATE`
- `QUEST_DATA_LOAD_RESULT`
- `QUEST_WATCH_LIST_CHANGED`
- `QUESTLINE_UPDATE`
- `TASK_PROGRESS_UPDATE`

### CompletedQuests tracker

Triggers `GetQuestsCompleted` delta capture. Uses the same events as
the QuestLog tracker.

### Loot tracker

Triggers loot function sampling on open, resets to nil on close.

- `LOOT_READY`
- `LOOT_CLOSED`

### UnitLevel tracker

Triggers `UnitLevel("player")` sampling.

- `PLAYER_LEVEL_UP`

### Position tracker

Triggers position function sampling (in addition to 0.2s timer).

- `ZONE_CHANGED`
- `ZONE_CHANGED_NEW_AREA`
- `ZONE_CHANGED_INDOORS`
- `PLAYER_ENTERING_WORLD`
- `PLAYER_STARTED_MOVING`
- `PLAYER_STOPPED_MOVING`
- `MAP_EXPLORATION_UPDATED`
- `PLAYER_MAP_CHANGED`
- `AREA_POIS_UPDATED`
- `NEW_WMO_CHUNK`

### Reputation tracker

Triggers `GetFactionInfoByID` sampling and faction discovery.

- `CHAT_MSG_COMBAT_FACTION_CHANGE`
- `UPDATE_FACTION`
- `QUEST_TURNED_IN`

### PlayerIdentity tracker

No events. Sampled once at capture start (`t=0`).

## Events recorded but not routed to trackers

These events are captured in the event stream for replay/analysis but
do not trigger any tracker sampling.

### Quest dialog

- `QUEST_DETAIL`
- `QUEST_PROGRESS`
- `QUEST_COMPLETE`
- `QUEST_FINISHED`
- `QUEST_GREETING`
- `QUEST_ACCEPT_CONFIRM`
- `GOSSIP_SHOW`
- `GOSSIP_CLOSED`

### Player state

- `PLAYER_LOGIN`
- `PLAYER_ALIVE`
- `MODIFIER_STATE_CHANGED`
- `PLAYER_REGEN_DISABLED`
- `PLAYER_REGEN_ENABLED`
- `PLAYER_TARGET_CHANGED`
- `PLAYER_EQUIPMENT_CHANGED`
- `LOOT_OPENED`
- `NEW_RECIPE_LEARNED`
- `UI_INFO_MESSAGE`

### Map/zone (not used by position tracker)

- `WORLD_MAP_OPEN`
- `UPDATE_ALL_UI_WIDGETS`

### Chat/system

- `CHAT_MSG_SYSTEM`
- `CHAT_MSG_LOOT`
- `CHAT_MSG_MONEY`
- `CHAT_MSG_SKILL`
- `CHAT_MSG_TRADESKILLS`
- `CHAT_MSG_COMBAT_XP_GAIN`

### Group/world

- `GROUP_JOINED`
- `GROUP_LEFT`
- `NAME_PLATE_UNIT_ADDED`
- `NAME_PLATE_UNIT_REMOVED`
- `ACHIEVEMENT_EARNED`
- `TRACKED_ACHIEVEMENT_LIST_CHANGED`
- `TRACKED_ACHIEVEMENT_UPDATE`
- `CRITERIA_UPDATE`

### Inventory

- `BAG_UPDATE`
- `BAG_UPDATE_DELAYED`
- `ITEM_PUSH`
- `ITEM_LOCK_CHANGED`
- `ITEM_COUNT_CHANGED`

## Notes

- All events are registered at addon load. Unsupported events are
  silently skipped at runtime.
- Event categories are for organization only — they are not persisted
  in SavedVariables.
- The tracker routing described above is the intended v8 design.
  Current v7 code routes differently (all events trigger all trackers).
