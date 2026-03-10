# Function Emulation Spec (v9)

How to reconstruct WoW API function outputs at a target time `t` from
QuestLogTrace saved data.

## 1) Generic lookup

All function streams use the same algorithm:

```lua
-- Get the stream for a function
function getStream(session, name, param)
  local fn = session.functions[name]
  if not fn then return nil end
  if param ~= nil then
    fn = fn[param]
  end
  return fn
end

-- Find value at target time
function valueAt(stream, target_t)
  local result = nil
  for i = 1, #stream do
    if stream[i].t > target_t then break end
    result = stream[i].v
  end
  return result
end

-- Return value to caller
function emulate(v)
  if type(v) == "table" and v.n then
    return unpack(v, 1, v.n)  -- tuple
  else
    return v                    -- scalar or object
  end
end
```

This covers every function in the catalog. No per-function logic needed.

## 2) Parameterless vs parameterized detection

```lua
local fn = session.functions[name]
local firstKey = next(fn)
if type(fn[firstKey]) == "table" and fn[firstKey].t then
  -- flat stream (parameterless)
else
  -- keyed by argument (parameterized), index into fn[param]
end
```

## 3) Function-to-stream mapping

Every function maps directly to `session.functions[key]` or
`session.functions[key][param]`. The key is the WoW API function name.

| WoW API call | Stream lookup |
|---|---|
| `GetZoneText()` | `functions["GetZoneText"]` |
| `GetSubZoneText()` | `functions["GetSubZoneText"]` |
| `GetRealZoneText()` | `functions["GetRealZoneText"]` |
| `GetNumLootItems()` | `functions["GetNumLootItems"]` |
| `UnitLevel("player")` | `functions["UnitLevel"]["player"]` |
| `UnitRace("player")` | `functions["UnitRace"]["player"]` |
| `UnitClass("player")` | `functions["UnitClass"]["player"]` |
| `UnitSex("player")` | `functions["UnitSex"]["player"]` |
| `C_Map.GetBestMapForUnit("player")` | `functions["C_Map.GetBestMapForUnit"]["player"]` |
| `C_Map.GetPlayerMapPosition(map, "player")` | `functions["C_Map.GetPlayerMapPosition"]["player"]` |
| `IsQuestComplete(questId)` | `functions["IsQuestComplete"][questId]` |
| `C_QuestLog.IsQuestFlaggedCompleted(questId)` | `functions["C_QuestLog.IsQuestFlaggedCompleted"][questId]` |
| `C_QuestLog.GetQuestObjectives(questId)` | `functions["C_QuestLog.GetQuestObjectives"][questId]` |
| `GetQuestLogTitle(questId)` | `functions["GetQuestLogTitle"][questId]` |
| `GetQuestTagInfo(questId)` | `functions["GetQuestTagInfo"][questId]` |
| `GetLootSlotInfo(slot)` | `functions["GetLootSlotInfo"][slot]` |
| `GetLootSourceInfo(slot)` | `functions["GetLootSourceInfo"][slot]` |
| `GetLootSlotLink(slot)` | `functions["GetLootSlotLink"][slot]` |
| `GetLootSlotType(slot)` | `functions["GetLootSlotType"][slot]` |
| `GetFactionInfoByID(factionID)` | `functions["GetFactionInfoByID"][factionID]` |
| `GetNumSkillLines()` | `functions["GetNumSkillLines"]` |
| `GetSkillLineInfo(index)` | `functions["GetSkillLineInfo"][index]` |
| `GetProfessions()` | `functions["GetProfessions"]` |
| `GetProfessionInfo(index)` | `functions["GetProfessionInfo"][index]` |
| `GetSpellBookItemName(slot)` | `functions["GetSpellBookItemName"][slot]` |
| `GetSpellBookItemInfo(slot)` | `functions["GetSpellBookItemInfo"][slot]` |
| `IsPassiveSpell(slot)` | `functions["IsPassiveSpell"][slot]` |

### Derived functions

These are not stored directly but reconstructed from other streams:

| WoW API call | Derivation |
|---|---|
| `GetFactionInfo(index)` | `factionID = valueAt(functions["FactionOrder"], t)[index]` → then `functions["GetFactionInfoByID"][factionID]` |
| `GetNumFactions()` | `#valueAt(functions["FactionOrder"], t)` |
| `QuestLog` (quest IDs in log) | `valueAt(functions["QuestLog"], t)` — returns full array |

## 4) Delta stream replay

`GetQuestsCompleted` and `PlayerKnownSpells` live in `functionsDelta`:

```lua
function getDeltaSet(session, key, target_t)
  local data = session.functionsDelta[key]
  local set = {}
  for _, id in ipairs(data.initial) do
    set[id] = true
  end
  for _, delta in ipairs(data.delta) do
    if delta.t > target_t then break end
    if delta.add then
      for _, id in ipairs(delta.add) do set[id] = true end
    end
    if delta.remove then
      for _, id in ipairs(delta.remove) do set[id] = nil end
    end
  end
  return set
end
```

Examples:

```lua
local completed = getDeltaSet(session, "GetQuestsCompleted", t)
local knownSpells = getDeltaSet(session, "PlayerKnownSpells", t)
```

## 5) Event replay

Iterate `session.events` in order. Each entry has `t`, `tp`, `e`, `a`.

```lua
for _, event in ipairs(session.events) do
  if event.t >= t0 and event.t <= t1 then
    fireEvent(event.e, unpack(event.a, 1, event.a.n))
  end
end
```

## 6) Known limits

- Only the functions listed above can be emulated. Other WoW APIs are
  not captured.
- `nil` values in function streams mean the function returned nil at
  that time (e.g. loot window closed). The emulator should return nil,
  not treat it as "no data".
- Position XY is rounded to 4 decimal places.
- Skill line IDs are not normalized during capture. Consumers must join
  `GetSkillLineInfo(index)` with external lookup data if they need stable
  numeric skill IDs beyond what `GetProfessionInfo(index)` exposes.
