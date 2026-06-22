# Architecture Spec (v9)

File structure, load order, bootstrap sequence, SavedVariables management, and event/dump routing for QuestLogTrace.

---

## 1) File load order

Defined by `QuestLogTrace-Classic.toc`:

```text
globals.lua                   -- Core namespace, utilities, RegisterTracker/RegisterDump APIs
Trackers/PlayerIdentity.lua   -- UnitRace, UnitClass, UnitClassBase, UnitSex, UnitFactionGroup (t=0 only)
Trackers/UnitLevel.lua        -- UnitLevel["player"], GetQuestGreenRange
Trackers/Position.lua         -- Zone texts, map ID, player position, instance state
Trackers/Loot.lua             -- Loot window capture
Trackers/Reputation.lua       -- Faction reputation
Trackers/QuestLog.lua         -- Quest log membership + per-quest/reward/timer functions
Trackers/CompletedQuests.lua  -- GetQuestsCompleted delta stream
Trackers/QuestDialog.lua      -- Gossip, greeting, and current quest-dialog APIs
Trackers/UnitInteraction.lua  -- UnitGUID/UnitName and gossip quest-list APIs
Trackers/GroupState.lua       -- IsInGroup, GetNumGroupMembers
Trackers/SkillLines.lua       -- Skill window + profession tabs
Trackers/SpellBook.lua        -- Raw spellbook slots + PlayerKnownSpells
Trackers/ResetTime.lua        -- GetServerTime and GetQuestResetTime
Dumps/MapHierarchy.lua        -- Static C_Map hierarchy dump (PLAYER_LOGIN + /qlt dumpmap)
QuestLogTrace_UI.lua          -- Control frame UI
QuestLogTrace.lua             -- Entry point: session lifecycle, event bus, slash commands
```

### Load order rationale

1. `globals.lua` establishes `QuestLogTraceCore`, shared types, utility helpers, tracker registration, and dump registration.
2. Tracker files call `Core.RegisterTracker` at file scope so event routing tables exist before the event frame is created.
3. Dump files call `Core.RegisterDump` at file scope so dump event/slash routing exists before bootstrap.
4. `QuestLogTrace_UI.lua` defines optional UI functions used by the main file.
5. `QuestLogTrace.lua` runs last, creates the event frame, registers tracked events, and handles slash commands.

---

## 2) Bootstrap sequence

On `VARIABLES_LOADED`:

1. `EnsureSavedVariables()` validates/initializes saved data and settings.
2. `Core.BuildControlFrame()` creates the optional control frame.
3. `Core.UpdateControlFrameStatus()` sets initial UI state.

`VARIABLES_LOADED` is consumed by bootstrap and is not recorded as a normal trace event.

After bootstrap:

- `PLAYER_LOGIN` starts capture automatically when `QuestLogTrace.settings.autoStart ~= false`; this happens before event processing so `PLAYER_LOGIN` is the first event in an auto-started session.
- `PLAYER_LOGOUT` is processed first, then an active capture is saved, so logout is included in the saved session.

---

## 3) Event registration

All events from `TRACKED_EVENT_CATEGORIES` are registered on the main event frame with `pcall`, allowing Classic-version differences to be skipped safely.

Current categories are organizational only and are not persisted:

- `quest_state`
- `quest_dialog`
- `npc_interaction`
- `initialization`
- `player_state`
- `map_zone`
- `chat_system`
- `group_world`
- `inventory`

Tracker routing is separate: `Core._trackerCallbacks[event]` controls which trackers sample for a specific event. `ADDON_LOADED` is filtered so only `QuestLogTrace`'s own load event is recorded.

---

## 4) SavedVariables

### Account-level: `QuestLogTrace`

```lua
QuestLogTrace = {
  schemaVersion = 9,
  settings = {
    maxSessions = 20,
    autoStart = true,
  },
}
```

### Account-level: `QuestLogTraceDumps`

```lua
QuestLogTraceDumps = {
  schemaVersion = 1,
  dumps = {
    map_hierarchy = MapHierarchyDumpData,
  },
}
```

### Per-character: `QuestLogTraceCharacter`

```lua
QuestLogTraceCharacter = {
  lastSavedSession = "2026-02-10_12-34-56", -- set on save only
  sessions = { SessionRecord, ... },
}
```

### Migration behavior

- If `QuestLogTrace` is missing or has a non-v9 schema, the account settings table is recreated with defaults.
- Missing/invalid `settings.maxSessions` resets to 20.
- Missing `settings.autoStart` defaults to `true`.
- `QuestLogTraceDumps` and its `dumps` table are ensured.
- Existing `QuestLogTraceCharacter.sessions` data is preserved when it is already a table; otherwise it is initialized to an empty table.

---

## 5) Session pruning and naming

After every save, sessions over `QuestLogTrace.settings.maxSessions` are pruned oldest-first. If no name is supplied at start/save, sessions use `date("%Y-%m-%d_%H-%M-%S")`; `/qlt save [name]` overrides a start-time name.

---

## 6) Auto-start and control surface

`QuestLogTrace.settings.autoStart` controls login capture. It defaults to `true` and can be toggled by `/qlt auto` or the control-frame checkbox.

Slash command aliases are `/questlogtrace` and `/qlt`:

| Command | Purpose |
|---|---|
| `/qlt start [name]` | Start a capture session |
| `/qlt stop` | Stop the active capture session |
| `/qlt save [name]` | Save the current capture, auto-stopping first if needed |
| `/qlt reset` | Discard an unsaved stopped session |
| `/qlt status` | Print capture status |
| `/qlt auto` | Toggle auto-start on login |
| `/qlt dumpmap` | Run the map hierarchy dump provider |
| `/qlt ui` | Toggle the control frame |

For bridge-based diagnostics and tests, `Core.GetDiagnosticSession()` returns
`(session, source)` where `source` is `"active"`, `"stopped_unsaved"`,
`"saved"`, or `"none"`. It prefers the live capture session, then the newest
saved session. The returned table is not copied and must be treated as read-only
by callers.

---

## 7) Tracker summary

| Tracker | Purpose |
|---|---|
| PlayerIdentity | Player race/class/base-class/sex/faction at capture start |
| UnitLevel | Level and green quest range |
| Position | Zone, map, XY, instance state |
| Loot | Loot window count and per-slot APIs |
| Reputation | Faction order and faction detail streams |
| QuestLog | Quest membership, per-quest data, text, timers, rewards |
| CompletedQuests | Completed quest set as a delta stream |
| UnitInteraction | Target/NPC/quest NPC identity and C_Gossip quest-list APIs |
| GroupState | Group membership/count |
| SkillLines | Skill rows and profession tabs |
| SpellBook | Raw spellbook slots and known spell set |
| QuestDialog | Gossip, greeting, and current quest dialog APIs |
| ResetTime | Server/reset-time snapshots |

---

## 8) Shared utilities (globals.lua)

| Function | Purpose | Used by |
|---|---|---|
| `Core.RegisterTracker(def)` | Register a tracker definition | All trackers |
| `Core.RegisterDump(def)` | Register dump providers | Dump files |
| `Core.RunDumpsForEvent(event, ...)` | Run event-triggered dumps | Main event handler |
| `Core.RunDumpBySlash(action, ...)` | Run slash-triggered dumps | Slash commands |
| `Core.GetDumpHelpLines()` | Contribute dump help text | `/qlt help` |
| `Core.PackArgs(...)` | Pack varargs into `{..., n=count}` | Events and tuple streams |
| `Core.CopyPacked(args)` | Copy packed args | Event recording |
| `Core.Round(num, decimals)` | Round numbers | Position tracker |
| `DeepCompare(t1, t2)` | Recursive table comparison | Change detection |
| `C_After` / `Defer` | Timer helpers | Delayed sampling |
