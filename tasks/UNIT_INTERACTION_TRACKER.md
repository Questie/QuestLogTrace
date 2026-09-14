# Task: UnitInteraction Tracker

Unified tracker for player target changes and NPC/GameObject interactions.
Samples three unit tokens (`"target"`, `"npc"`, `"questnpc"`) on every
event, recording both GUID and Name for each.

---

## 1) New file

**`Trackers/UnitInteraction.lua`**

---

## 2) Function streams

All six streams are **parameterized** by unit token. Every event samples
all six; change detection skips the append when the value hasn't changed.

| Function key | Token | Return type | Comparison |
|---|---|---|---|
| `UnitGUID` | `"target"` | scalar (string or nil) | `==` |
| `UnitGUID` | `"npc"` | scalar (string or nil) | `==` |
| `UnitGUID` | `"questnpc"` | scalar (string or nil) | `==` |
| `UnitName` | `"target"` | packed observed returns (n varies) | `DeepCompare` |
| `UnitName` | `"npc"` | packed observed returns (n varies) | `DeepCompare` |
| `UnitName` | `"questnpc"` | packed observed returns (n varies) | `DeepCompare` |

### Return shapes

- **`UnitGUID(token)`** returns a single string
  (`"Creature-0-1234-0-5678-1234-00001A2B3C"`) or `nil` when no unit.
  Stored as scalar `v`.

- **`UnitName(token)`** is stored as the packed observed return values from
  directly calling `UnitName(token)`. Commonly this is `name, realm` with
  `n = 2`, e.g. `{ "Innkeeper Farley", nil, n = 2 }`, but no-unit or
  client-specific returns may have a different `n`.

### Init (t = 0)

Sample all six streams once. Most will be `nil` at session start (no
interaction open, possibly no target). That's fine — `nil` is a valid
first entry.

### Shared function tables

`UnitGUID` and `UnitName` may already exist in `functions` from other
trackers (e.g. PlayerIdentity does not use them currently, but future
trackers might). Use **get-or-create** to avoid clobbering:

```lua
if not functions["UnitGUID"] then functions["UnitGUID"] = {} end
if not functions["UnitName"] then functions["UnitName"] = {} end
```

This tracker owns the `"target"`, `"npc"`, and `"questnpc"` keys under
those tables.

---

## 3) Events

### Trigger pattern

**Pattern 1: Event-driven.** Sample all six streams on every event.
No timers, no delayed re-samples, no index iteration.

### Events the tracker registers for

The tracker's `events` array includes events from several categories.
Some are already registered in `TRACKED_EVENT_CATEGORIES`; some are new.

**From `player_state` (already registered):**
- `PLAYER_TARGET_CHANGED`

**From `quest_dialog` (already registered):**
- `QUEST_DETAIL`
- `QUEST_PROGRESS`
- `QUEST_COMPLETE`
- `QUEST_GREETING`
- `QUEST_FINISHED`
- `QUEST_ACCEPT_CONFIRM`
- `GOSSIP_SHOW`
- `GOSSIP_CLOSED`

**From `quest_state` (already registered):**
- `QUEST_ACCEPTED`
- `QUEST_TURNED_IN`

**From `player_state` (already registered):**
- `LOOT_OPENED`

**New category `npc_interaction` (must be added to `TRACKED_EVENT_CATEGORIES`):**
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

Total: **35 events** in the tracker's `events` array.

---

## 4) Implementation sketch

```lua
local Core = QuestieTraceCore
local PackArgs = Core.PackArgs

local TOKENS = { "target", "npc", "questnpc" }

-- Stream references (set during Init)
local guidStreams   -- { [token] = FunctionStreamEntry[] }
local nameStreams   -- { [token] = FunctionStreamEntry[] }

--- Sample all six streams.
local function SampleAll(capture)
  local t  = GetTime()          - capture.startedAt
  local tp = GetTimePreciseSec() - capture.startedAtPrecise

  for _, token in ipairs(TOKENS) do
    -- UnitGUID (scalar)
    local guid = UnitGUID(token)
    local guidStream = guidStreams[token]
    local prevGuid = guidStream[#guidStream]
    if not prevGuid or prevGuid.v ~= guid then
      guidStream[#guidStream + 1] = { t = t, tp = tp, v = guid }
    end

    -- UnitName (tuple n=2)
    local nameVal = PackArgs(UnitName(token))
    local nameStream = nameStreams[token]
    local prevName = nameStream[#nameStream]
    if not prevName or not DeepCompare(prevName.v, nameVal) then
      nameStream[#nameStream + 1] = { t = t, tp = tp, v = nameVal }
    end
  end
end

Core.RegisterTracker({
  events = { --[[ all 35 events ]] },

  Init = function(capture)
    local functions = capture.session.functions
    if not functions["UnitGUID"] then functions["UnitGUID"] = {} end
    if not functions["UnitName"] then functions["UnitName"] = {} end

    guidStreams = {}
    nameStreams = {}
    for _, token in ipairs(TOKENS) do
      functions["UnitGUID"][token] = {}
      functions["UnitName"][token] = {}
      guidStreams[token] = functions["UnitGUID"][token]
      nameStreams[token] = functions["UnitName"][token]
    end

    -- Initial sample at t=0
    SampleAll(capture)
  end,

  OnEvent = function(capture, event, ...)
    SampleAll(capture)
  end,
})
```

### Notes

- **No event dispatch logic.** Every event triggers the same `SampleAll`.
  The event itself is already recorded in the event stream with its name
  and timestamp, so consumers can correlate function changes with events.

- **`nil` handling for `UnitName`.** When `UnitName(token)` is called on
  a token with no unit, it returns `nil`. `PackArgs(nil)` produces
  `{ n = 1 }` (one nil argument). However, comparing `{ n = 1 }` against
  a previous `{ "Name", nil, n = 2 }` via `DeepCompare` will correctly
  detect the change because the `n` fields differ.

  **Edge case:** When there is no unit, `UnitName` returns exactly one
  `nil`, not two. So the packed result is `{ n = 1 }`. When a unit
  exists, it returns `name, realm` so the packed result is
  `{ "Name", nil, n = 2 }`. The `n` difference ensures change detection
  works.

  Do not guard with `UnitExists(token)` to synthesize plain `nil` for
  `UnitName`. `UnitName(token)` is a raw API stream, so the tracker calls it
  directly and stores the packed observed return values. This preserves whether
  the API returned one nil, two values, or another client-specific shape.

---

## 5) Changes to existing files

### `QuestieTrace.lua`

Add new event category to `TRACKED_EVENT_CATEGORIES`:

```lua
{
  name = "npc_interaction",
  events = {
    "MERCHANT_SHOW",
    "MERCHANT_CLOSED",
    "TRAINER_SHOW",
    "TRAINER_CLOSED",
    "MAIL_SHOW",
    "MAIL_CLOSED",
    "AUCTION_HOUSE_SHOW",
    "AUCTION_HOUSE_CLOSED",
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
    "TAXIMAP_OPENED",
    "TAXIMAP_CLOSED",
    "GUILD_REGISTRAR_SHOW",
    "GUILD_REGISTRAR_CLOSED",
    "PET_STABLE_SHOW",
    "PET_STABLE_CLOSED",
    "BATTLEFIELDS_SHOW",
    "BATTLEFIELDS_CLOSED",
    "PETITION_SHOW",
    "PETITION_CLOSED",
    "GUILDBANKFRAME_OPENED",
    "GUILDBANKFRAME_CLOSED",
  },
},
```

These events are registered via `pcall` so unsupported events in
different Classic versions are silently skipped.

### `QuestieTrace-Classic.toc`

Add `Trackers\UnitInteraction.lua` to the file list (before
`QuestieTrace.lua` since trackers must load before the main file
registers events and calls Init).

### `specs/EVENT_CATALOG.md`

Add new section for UnitInteraction tracker and new `npc_interaction`
category. Move `PLAYER_TARGET_CHANGED` and `LOOT_OPENED` from
"recorded but not routed" to showing they are also routed to this
tracker.

### `specs/TRACKER_SPEC.md`

Add UnitInteraction to the per-tracker table in section 7.

### `specs/SCHEMA_SPEC.md`

Add new entries to the function catalog in section 9:

**Parameterized by unit token (`"target"`, `"npc"`, `"questnpc"`):**

| Function key | Return type | Notes |
|---|---|---|
| `UnitGUID` | scalar (string) or nil | GUID string; nil when no unit |
| `UnitName` | packed tuple (n varies) | observed `UnitName(token)` returns; no synthetic `UnitExists` mapping |

---

## 6) Design decisions

### Why one tracker, not two?

Target changes and NPC interactions are different in frequency but share
the same function set (UnitGUID/UnitName on unit tokens). A single
tracker avoids duplicating the sampling logic and ensures all tokens are
sampled consistently at every interesting moment. The event stream
already tells consumers whether a sample was triggered by
`PLAYER_TARGET_CHANGED` vs `MERCHANT_SHOW`.

### Why sample all tokens on every event?

- Cheap: all calls are client-side lookups, no server traffic.
- Avoids missing correlations (e.g. player targets the NPC they're
  buying from — we capture both `"target"` and `"npc"` on
  `MERCHANT_SHOW`).
- Change detection means most events produce zero or one append per
  stream, not six.

### Why no `UnitExists` guard for `UnitName`?

`UnitName(token)` is a raw API stream. The tracker calls `UnitName(token)`
directly and stores the packed observed return values instead of mapping
`UnitExists(token) == false` to a synthetic nil. This keeps the trace faithful
to the API behavior of mutable unit tokens such as `"target"`, `"npc"`, and
`"questnpc"` at the event timestamp.
