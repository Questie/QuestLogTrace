# UI Spec (v9)

Control frame and slash command interface for QuestLogTrace.

---

## 1) Capture states

| `capture.active` | `capture.session` | State | Label |
|---|---|---|---|
| `false` | `nil` | Idle | "Idle" |
| `true` | table | Running | "Running" |
| `false` | table | Stopped, unsaved | "Stopped (unsaved)" |

`Core.GetCaptureState()` returns `"idle"`, `"running"`, or `"stopped_unsaved"`.

---

## 2) Control frame

A movable frame at top center of the screen (`250x120`), created by `Core.BuildControlFrame()` on `VARIABLES_LOADED`.

### Elements

- **Title**: "QuestLogTrace"
- **Start/Reset button**: 72x22, top-left
- **Stop button**: 72x22, right of Start
- **Save button**: 72x22, right of Stop
- **Status text**: below buttons, left-aligned, 230px wide
- **Auto-start checkbox**: bottom-left; checked when `QuestLogTrace.settings.autoStart ~= false`; writes its checked state to `QuestLogTrace.settings.autoStart`
- **Auto-start label**: "Auto-start on login"

### Status text

`Core.UpdateControlFrameStatus()` formats status as three lines:

```text
Status: <Idle|Running|Stopped (unsaved)>
Session: <sessionName>
Events: <eventCount>
```

### Button state table

| State | Start button | Stop button | Save button |
|---|---|---|---|
| Idle | **Start** (enabled) | disabled | disabled |
| Running | Start (disabled) | **Stop** (enabled) | disabled |
| Stopped, unsaved | **Reset** (enabled) | disabled | **Save** (enabled) |

In `stopped_unsaved`, clicking **Reset** calls `Core.ResetCapture()` and discards the unsaved session.

### OnUpdate polling

The control frame polls `Core.UpdateControlFrameStatus()` every 0.5 seconds via `OnUpdate`.

### Frame properties

- Clamped to screen
- Movable via left-button drag
- Dark background with border texture and darker inner fill
- Toggle visibility with `/qlt ui`

---

## 3) Slash commands

Aliases: `/questlogtrace` and `/qlt`.

| Command | Action |
|---|---|
| `/qlt` or `/qlt help` | Print help text |
| `/qlt start [name]` | Start capture with optional session name |
| `/qlt stop` | Stop active capture |
| `/qlt save [name]` | Save session, auto-stopping if running |
| `/qlt reset` | Discard unsaved capture when not running |
| `/qlt status` | Print status to chat |
| `/qlt auto` | Toggle auto-start on login |
| `/qlt dumpmap` | Run map hierarchy dump provider, when registered |
| `/qlt ui` | Toggle control frame visibility |

### Behaviors

- `/qlt save [name]` overrides the session name set at start time.
- `/qlt reset` prints an error and does nothing while capture is running; otherwise it clears any unsaved session and prints `Session discarded.`
- `/qlt auto` toggles `QuestLogTrace.settings.autoStart` and prints `Auto-start on login: enabled` or `disabled`.
- If no name is provided, sessions are named with `YYYY-MM-DD_HH-MM-SS`.

---

## 4) Auto-start behavior

`QuestLogTrace.settings.autoStart` defaults to `true` on fresh settings and when missing. When `PLAYER_LOGIN` fires and no capture is active, the main event handler starts capture automatically unless `autoStart == false`. Auto-start happens before event processing, so `PLAYER_LOGIN` is recorded as the first event in the new session.

The checkbox and `/qlt auto` update the same setting.

---

## 5) StatusData

```lua
{
  captureState = "idle" | "running" | "stopped_unsaved",
  isRunning    = boolean,
  sessionName  = string,
  eventCount   = number,
  canSave      = boolean,
}
```
