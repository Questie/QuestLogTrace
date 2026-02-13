# Task: Auto-Start/Stop Capture

Automatically start capture on login and save on logout/reload, removing
the need for manual `/qlt start` and `/qlt save` in normal usage. Manual
commands remain available for early stop or named saves.

---

## 1) Behavior overview

### Login flow

```
ADDON_LOADED (QuestLogTrace)  →  EnsureSavedVariables (existing)
PLAYER_LOGIN                  →  Auto-start capture (if enabled)
PLAYER_ENTERING_WORLD         →  Recorded normally (already tracked)
SPELLS_CHANGED                →  Recorded normally (new event)
... gameplay ...
```

### Logout / reload flow

```
PLAYER_LEAVING_WORLD          →  Recorded in event stream (new event)
PLAYER_LOGOUT                 →  Record event, then auto-save session
```

On `/reload`: `PLAYER_LOGOUT` fires → session auto-saves → fresh load
→ `PLAYER_LOGIN` → new session auto-starts. Two separate sessions.

### Manual override

All existing commands still work:

- `/qlt stop` — stops capture early (no auto-save on logout since
  there's nothing to save)
- `/qlt save [name]` — stop + save with optional name, even if
  auto-started
- `/qlt start [name]` — manual start (e.g. after a manual stop, or if
  auto-start is disabled)

---

## 2) Settings

Add `autoStart` to `QuestLogTrace.settings`:

```lua
QuestLogTrace = {
  schemaVersion = 8,
  settings = {
    maxSessions = 20,
    autoStart = true,       -- NEW
  },
}
```

**Default:** `true` — auto-start unless explicitly disabled.

In `EnsureSavedVariables`, if `autoStart` is nil (fresh install or
migration), default to `true`:

```lua
if QuestLogTrace.settings.autoStart == nil then
  QuestLogTrace.settings.autoStart = true
end
```

Add a slash command to toggle:

- `/qlt auto` — toggles `autoStart` between true/false, prints status

### UI checkbox

Add an "Auto-start" checkbox to the control frame in
`QuestLogTrace_UI.lua`. Positioned below the status text area.

```lua
local autoCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  --[[@as CheckButton]]
autoCheck:SetSize(24, 24)
autoCheck:SetPoint("BOTTOMLEFT", 8, 6)
autoCheck:SetChecked(QuestLogTrace.settings.autoStart ~= false)
autoCheck:SetScript("OnClick", function(self)
  QuestLogTrace.settings.autoStart = self:GetChecked()
end)

local autoLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
autoLabel:SetPoint("LEFT", autoCheck, "RIGHT", 2, 0)
autoLabel:SetText("Auto-start on login")
```

The frame height should increase slightly to accommodate the checkbox
row (from 100 to ~120). The checkbox reads/writes
`QuestLogTrace.settings.autoStart` directly — no restart required, the
setting takes effect on the next login.

---

## 3) Event filtering

### Problem

`ADDON_LOADED` fires for every addon. We only want to record it for
ours.

### Solution

Add an event filter table in `QuestLogTrace.lua`:

```lua
local EVENT_FILTERS = {
  ADDON_LOADED = function(addonName)
    return addonName == ADDON_NAME
  end,
}
```

Check in `OnEvent` before `ProcessTrackedEvent`:

```lua
local filter = EVENT_FILTERS[event]
if filter and not filter(...) then return end
```

This is generic — more filters can be added later for other spammy
events if needed.

---

## 4) New events to register

### New event category: `initialization`

```lua
{
  name = "initialization",
  events = {
    "ADDON_LOADED",
    "SPELLS_CHANGED",
    "PLAYER_LOGOUT",
    "PLAYER_LEAVING_WORLD",
  },
},
```

`PLAYER_LOGIN` and `PLAYER_ENTERING_WORLD` are already registered in
`player_state`.

Note: `ADDON_LOADED` is filtered (see section 3) so only our addon's
event appears in the stream.

---

## 5) Modified OnEvent flow

The current `OnEvent` handles only `VARIABLES_LOADED` specially. The new
version adds auto-start and auto-save hooks:

```lua
local function OnEvent(_, event, ...)
  -- 1. Initialization (unchanged)
  if event == "VARIABLES_LOADED" then
    EnsureSavedVariables()
    if Core.BuildControlFrame then
      Core.BuildControlFrame()
    end
    if Core.UpdateControlFrameStatus then
      Core.UpdateControlFrameStatus()
    end
    return
  end

  -- 2. Event filtering (NEW)
  local filter = EVENT_FILTERS[event]
  if filter and not filter(...) then return end

  -- 3. Auto-start on PLAYER_LOGIN (NEW)
  --    StartCapture BEFORE ProcessTrackedEvent so PLAYER_LOGIN
  --    is recorded as the first event in the session.
  if event == "PLAYER_LOGIN" and not capture.active then
    local settings = QuestLogTrace and QuestLogTrace.settings
    if settings and settings.autoStart ~= false then
      Core.StartCapture()
    end
  end

  -- 4. Process the event (record + dispatch to trackers)
  ProcessTrackedEvent(event, ...)

  -- 5. Auto-save on PLAYER_LOGOUT (NEW)
  --    ProcessTrackedEvent runs first so the event is recorded
  --    in the session before saving.
  if event == "PLAYER_LOGOUT" and capture.active then
    Core.SaveCapture()
  end
end
```

### Ordering rationale

- **Auto-start before ProcessTrackedEvent:** `StartCapture()` sets
  `capture.active = true` and calls tracker `Init` (t=0 samples). Then
  `ProcessTrackedEvent` records `PLAYER_LOGIN` as the first event at
  t≈0 and dispatches to tracker `OnEvent` handlers.

- **Auto-save after ProcessTrackedEvent:** The `PLAYER_LOGOUT` event is
  recorded in the session's event stream before `SaveCapture()` persists
  it to SavedVariables.

---

## 6) Session naming for auto-started sessions

Auto-started sessions use the existing default name format:
`date("%Y-%m-%d_%H-%M-%S")`. This happens because `Core.StartCapture()`
is called with no name argument, and `SaveCapture` calls
`CreateSessionName(nil)` which falls through to the date format.

No changes needed to the naming logic.

---

## 7) Edge cases

### Already running on PLAYER_LOGIN

If a capture is already active (shouldn't normally happen, but
defensively): the `not capture.active` check in the auto-start block
prevents double-starting.

### Manual stop then logout

If the player does `/qlt stop` then logs out: `capture.active` is false
at `PLAYER_LOGOUT` time, so auto-save is skipped. The unsaved session
(if not manually saved) is lost, which matches current behavior — the
player chose to stop manually.

### Manual stop, then manual start, then logout

Works correctly: the manually-started session is auto-saved on logout.

### /reload rapid sequence

`PLAYER_LOGOUT` → auto-save → addon unloads → addon reloads →
`VARIABLES_LOADED` → `PLAYER_LOGIN` → auto-start new session. The two
sessions will have sequential timestamps. Future schema work could
enable splicing them together outside WoW.

---

## 8) Files to change

### `QuestLogTrace.lua`

- Add `EVENT_FILTERS` table
- Add `initialization` event category to `TRACKED_EVENT_CATEGORIES`
- Modify `OnEvent` for auto-start, event filtering, and auto-save
- Modify `EnsureSavedVariables` to default `autoStart = true`
- Add `/qlt auto` to slash command handler and help text

### `QuestLogTrace_UI.lua`

- Increase frame height from 100 to ~120
- Add `CheckButton` with `UICheckButtonTemplate` for auto-start toggle
- Add label `FontString` next to checkbox
- Checkbox reads/writes `QuestLogTrace.settings.autoStart` on click

### `specs/EVENT_CATALOG.md`

- Add `initialization` category section
- Document `ADDON_LOADED` filtering behavior
- Add `PLAYER_LOGOUT` and `PLAYER_LEAVING_WORLD` to recorded events
- Add `SPELLS_CHANGED` to recorded events

### `specs/SCHEMA_SPEC.md`

- Add `autoStart` to the settings example in section 1

---

## 9) Future considerations

### Tracker init-event sampling

Currently, tracker `Init` runs at capture start (during `PLAYER_LOGIN`),
giving t=0 samples. Some game data may be incomplete at this point.
Trackers could benefit from re-sampling on `PLAYER_ENTERING_WORLD` and
`SPELLS_CHANGED` to capture the "data settles" transition. This is a
separate per-tracker enhancement — each tracker would add these events
to its `events` array. Not in scope for this task but worth noting.

### Session continuation across reloads

The user wants future schema support for continuing a session across
`/reload` boundaries. For now, two separate sessions are created.
Splicing can be done externally by matching sequential timestamps.
