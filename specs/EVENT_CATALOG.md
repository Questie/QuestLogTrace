# Event Catalog (v9)

All events are recorded to `session.events` with full packed args. Events
are also used to trigger tracker sampling — each tracker registers which
events it cares about via `Core.RegisterTracker`.

---

## Events by tracker

### QuestLog tracker

Triggers quest log membership scan and per-quest function sampling.
Uses delayed re-samples at `{ 0, 0.10, 0.35, 0.55, 0.75, 1.00 }` seconds.

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
- `PLAYER_ENTERING_WORLD` *(login-time sampling)*
- `SPELLS_CHANGED` *(login-time sampling)*

### CompletedQuests tracker

Triggers `GetQuestsCompleted` delta capture. Uses the same 14 quest events
as the QuestLog tracker plus the two login-time sampling events, with the
same delayed re-sample schedule.

### Loot tracker

Triggers loot function sampling on open, resets to nil/0 on close.

- `LOOT_READY`
- `LOOT_CLOSED`

### UnitLevel tracker

Triggers `UnitLevel("player")` sampling.

- `PLAYER_LEVEL_UP`
- `PLAYER_ENTERING_WORLD` *(login-time sampling)*
- `SPELLS_CHANGED` *(login-time sampling)*

### Position tracker

Triggers position function sampling (in addition to 0.2s timer).
Also registers a private event frame for `PLAYER_STARTED_MOVING` and
`PLAYER_STOPPED_MOVING` — these trigger sampling but are NOT recorded
in the event stream (avoids spam).

- `ZONE_CHANGED`
- `ZONE_CHANGED_NEW_AREA`
- `ZONE_CHANGED_INDOORS`
- `PLAYER_ENTERING_WORLD`
- `PLAYER_ALIVE`
- `MAP_EXPLORATION_UPDATED`
- `PLAYER_MAP_CHANGED`
- `AREA_POIS_UPDATED`
- `NEW_WMO_CHUNK`
- `SPELLS_CHANGED` *(login-time sampling)*

### Reputation tracker

Triggers `GetFactionInfoByID` sampling and faction discovery. On
`QUEST_TURNED_IN`, runs full collection (discover new factions). On the
other events, samples existing factions only (including the login-time
sampling events).

- `CHAT_MSG_COMBAT_FACTION_CHANGE`
- `UPDATE_FACTION`
- `QUEST_TURNED_IN`
- `PLAYER_ENTERING_WORLD` *(login-time sampling)*
- `SPELLS_CHANGED` *(login-time sampling)*

### UnitInteraction tracker

Triggers `UnitGUID` and `UnitName` sampling for `"target"`, `"npc"`, and
`"questnpc"` tokens. All six streams are sampled on every event.

**From `player_state` (shared with other trackers):**
- `PLAYER_TARGET_CHANGED`
- `LOOT_OPENED`

**From `quest_dialog` (shared with other trackers):**
- `QUEST_DETAIL`
- `QUEST_PROGRESS`
- `QUEST_COMPLETE`
- `QUEST_GREETING`
- `QUEST_FINISHED`
- `QUEST_ACCEPT_CONFIRM`
- `GOSSIP_SHOW`
- `GOSSIP_CLOSED`

**From `quest_state` (shared with other trackers):**
- `QUEST_ACCEPTED`
- `QUEST_TURNED_IN`

**From `npc_interaction` (new category):**
- `MERCHANT_SHOW`
- `MERCHANT_CLOSED`
- `TRAINER_SHOW`
- `TRAINER_CLOSED`
- `MAIL_SHOW`
- `MAIL_CLOSED`
- `AUCTION_HOUSE_SHOW`
- `AUCTION_HOUSE_CLOSED`
- `BANKFRAME_OPENED`
- `BANKFRAME_CLOSED`
- `TAXIMAP_OPENED`
- `TAXIMAP_CLOSED`
- `GUILD_REGISTRAR_SHOW`
- `GUILD_REGISTRAR_CLOSED`
- `PET_STABLE_SHOW`
- `PET_STABLE_CLOSED`
- `BATTLEFIELDS_SHOW`
- `BATTLEFIELDS_CLOSED`
- `PETITION_SHOW`
- `PETITION_CLOSED`
- `GUILDBANKFRAME_OPENED`
- `GUILDBANKFRAME_CLOSED`

**Login-time sampling:**
- `PLAYER_ENTERING_WORLD`
- `SPELLS_CHANGED`

### PlayerIdentity tracker

No events. Sampled once at capture start (`t=0`).

---

## Events recorded but not routed to trackers

### Initialization

Events related to addon loading, login, and logout. `ADDON_LOADED` is
filtered so only the addon's own load event is recorded in the stream.

- `ADDON_LOADED` (filtered: only recorded when `addonName == "QuestLogTrace"`)
- `PLAYER_LOGOUT`
- `PLAYER_LEAVING_WORLD`

These events are captured in the event stream for replay/analysis but
do not trigger any tracker sampling.

Note: `SPELLS_CHANGED` was previously in this section but is now routed
to trackers for login-time data sampling (see tracker sections above).

### Player state

- `PLAYER_LOGIN`
- `MODIFIER_STATE_CHANGED`
- `PLAYER_REGEN_DISABLED`
- `PLAYER_REGEN_ENABLED`
- `PLAYER_EQUIPMENT_CHANGED`
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

---

## Notes

- All events are registered at addon load via `pcall`. Unsupported events
  are silently skipped at runtime.
- Event categories (quest_state, player_state, etc.) are organizational
  only — they are not persisted in SavedVariables.
- Some events are routed to trackers AND recorded in the event stream.
  For example, `QUEST_TURNED_IN` appears in both the event stream and
  triggers the QuestLog, CompletedQuests, Reputation, and UnitInteraction
  trackers. Quest dialog events and `PLAYER_TARGET_CHANGED` are now also
  routed to the UnitInteraction tracker.
- `LOOT_OPENED` and `LOOT_READY` are different events. The Loot tracker
  uses `LOOT_READY` (fires when loot data is available), not `LOOT_OPENED`
  (fires when the loot UI opens, data may not be ready).
- `ADDON_LOADED` fires for every addon. An event filter in `OnEvent`
  skips it unless `addonName == "QuestLogTrace"`, so only the addon's
  own load appears in the event stream.
- `PLAYER_LOGIN` triggers auto-start (if `autoStart` is enabled and no
  capture is active). Auto-start runs before `ProcessTrackedEvent` so
  `PLAYER_LOGIN` is recorded as the first event in the session.
- `PLAYER_LOGOUT` triggers auto-save (if a capture is active).
  `ProcessTrackedEvent` runs first so the event is recorded in the
  session before saving.
- `PLAYER_ENTERING_WORLD` and `SPELLS_CHANGED` are used for login-time
  data sampling. With auto-start capture on `PLAYER_LOGIN`, the tracker
  `Init` runs at t=0 but WoW API data may not be fully populated yet.
  These events fire later in the login sequence (`PLAYER_ENTERING_WORLD`
  fires after `PLAYER_LOGIN`; `SPELLS_CHANGED` fires when the spellbook
  populates) and trigger re-samples that capture the "data settling"
  transitions as each API starts returning valid data.
