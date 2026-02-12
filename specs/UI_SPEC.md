# UI Spec (v8)

Control frame and slash command interface for QuestLogTrace.

---

## 1) Capture states

The addon has three states, derived from two fields:

| `capture.active` | `capture.session` | State | Label |
|---|---|---|---|
| `false` | `nil` | Idle | "Idle" |
| `true` | table | Running | "Running" |
| `false` | table | Stopped, unsaved | "Stopped (unsaved)" |

`Core.GetCaptureState()` returns one of: `"idle"`, `"running"`,
`"stopped_unsaved"`.

---

## 2) Control frame

A movable frame at top center of screen (`250x100`), created by
`Core.BuildControlFrame()` on `VARIABLES_LOADED`.

### Elements

- **Title**: "QuestLogTrace"
- **Start/Reset button**: 72x22, top-left
- **Stop button**: 72x22, right of Start
- **Save button**: 72x22, right of Stop
- **Status text**: below buttons, left-aligned, 230px wide

### Button state table

| State | Start button | Stop button | Save button |
|---|---|---|---|
| Idle | **Start** (enabled) | disabled | disabled |
| Running | Start (disabled) | **Stop** (enabled) | disabled |
| Stopped, unsaved | **Reset** (enabled) | disabled | **Save** (enabled) |

In `stopped_unsaved` state, the Start button text changes to **"Reset"**.
Clicking it calls `Core.ResetCapture()` (discards the unsaved session),
returning to idle state.

### OnUpdate polling

The control frame polls `Core.UpdateControlFrameStatus()` every 0.5
seconds via the `OnUpdate` script. This updates the status text and
button enable/disable states.

### Frame properties

- Clamped to screen
- Movable via left-button drag
- Dark background (0.05, 0.05, 0.05, 0.85)
- Toggle visibility with `/qlt ui`

---

## 3) Slash commands

Two aliases: `/questlogtrace` and `/qlt`.

| Command | Action |
|---|---|
| `/qlt` or `/qlt help` | Print help text |
| `/qlt start [name]` | Start capture with optional session name |
| `/qlt stop` | Stop active capture |
| `/qlt save [name]` | Save session (auto-stops if running) |
| `/qlt reset` | Discard unsaved session |
| `/qlt status` | Print status to chat |
| `/qlt ui` | Toggle control frame visibility |

### Behaviors

- `/qlt save` auto-stops a running capture before saving.
- `/qlt save [name]` overrides the session name set at start time.
- `/qlt reset` only works in `stopped_unsaved` state; prints error if
  capture is running.
- If no name is provided, sessions are named with the pattern
  `YYYY-MM-DD_HH-MM-SS`.

---

## 4) StatusData

`Core.GetStatusData()` returns a table consumed by the UI:

```lua
{
  captureState = "idle" | "running" | "stopped_unsaved",
  isRunning    = boolean,
  sessionName  = string,
  eventCount   = number,
  canSave      = boolean,  -- true when stopped_unsaved
}
```
