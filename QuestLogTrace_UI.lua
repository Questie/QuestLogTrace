QuestLogTraceCore = QuestLogTraceCore or {}

---@class QuestLogTraceCore
local Core = QuestLogTraceCore

---@type Frame?
local controlFrame = nil

--- Update the control frame's status text and button states.
function Core.UpdateControlFrameStatus()
  if not controlFrame then return end

  ---@type StatusData
  local state = Core.GetStatusData and Core.GetStatusData() or {
    captureState = "idle",
    isRunning = false,
    sessionName = "None",
    eventCount = 0,
    canSave = false,
  }

  ---@type "running"|"stopped_unsaved"|"idle"
  local captureState = state.captureState or "idle"

  -- Status label
  ---@type string
  local statusLabel
  if captureState == "running" then
    statusLabel = "Running"
  elseif captureState == "stopped_unsaved" then
    statusLabel = "Stopped (unsaved)"
  else
    statusLabel = "Idle"
  end

  controlFrame.status:SetText(
    string.format("Status: %s\nSession: %s\nEvents: %d",
      statusLabel, state.sessionName, state.eventCount)
  )

  -- Button states per design doc section 13:
  -- idle:             Start=enabled,  Stop=disabled, Save=disabled
  -- running:          Start=disabled, Stop=enabled,  Save=disabled
  -- stopped_unsaved:  Reset=enabled,  Stop=disabled, Save=enabled
  if captureState == "idle" then
    controlFrame.startButton:SetText("Start")
    controlFrame.startButton:SetEnabled(true)
    controlFrame.stopButton:SetEnabled(false)
    controlFrame.saveButton:SetEnabled(false)
  elseif captureState == "running" then
    controlFrame.startButton:SetText("Start")
    controlFrame.startButton:SetEnabled(false)
    controlFrame.stopButton:SetEnabled(true)
    controlFrame.saveButton:SetEnabled(false)
  elseif captureState == "stopped_unsaved" then
    controlFrame.startButton:SetText("Reset")
    controlFrame.startButton:SetEnabled(true)
    controlFrame.stopButton:SetEnabled(false)
    controlFrame.saveButton:SetEnabled(true)
  end
end

--- Build the control frame UI for the addon.
function Core.BuildControlFrame()
  if controlFrame then return end

  ---@type Frame
  local frame = CreateFrame("Frame", "QuestLogTraceControlFrame", UIParent)
  frame:SetSize(250, 100)
  frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

  ---@type Texture
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(true)
  bg:SetColorTexture(0.05, 0.05, 0.05, 0.85)

  ---@type Texture
  local border = frame:CreateTexture(nil, "BORDER")
  border:SetAllPoints(true)
  border:SetColorTexture(0.20, 0.20, 0.20, 0.9)
  border:SetDrawLayer("BORDER", 1)

  ---@type Texture
  local inner = frame:CreateTexture(nil, "ARTWORK")
  inner:SetPoint("TOPLEFT", 1, -1)
  inner:SetPoint("BOTTOMRIGHT", -1, 1)
  inner:SetColorTexture(0.08, 0.08, 0.08, 0.9)

  ---@type FontString
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -8)
  title:SetText("QuestLogTrace")

  ---@type Button
  local startButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  startButton:SetSize(72, 22)
  startButton:SetPoint("TOPLEFT", 10, -26)
  startButton:SetText("Start")
  startButton:SetScript("OnClick", function()
    ---@type "running"|"stopped_unsaved"|"idle"
    local captureState = Core.GetCaptureState and Core.GetCaptureState() or "idle"
    if captureState == "stopped_unsaved" then
      -- Reset: discard unsaved session, then start fresh
      if Core.ResetCapture then Core.ResetCapture() end
    else
      if Core.StartCapture then Core.StartCapture() end
    end
  end)

  ---@type Button
  local stopButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  stopButton:SetSize(72, 22)
  stopButton:SetPoint("LEFT", startButton, "RIGHT", 8, 0)
  stopButton:SetText("Stop")
  stopButton:SetScript("OnClick", function()
    if Core.StopCapture then Core.StopCapture() end
  end)

  ---@type Button
  local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  saveButton:SetSize(72, 22)
  saveButton:SetPoint("LEFT", stopButton, "RIGHT", 8, 0)
  saveButton:SetText("Save")
  saveButton:SetScript("OnClick", function()
    if Core.SaveCapture then Core.SaveCapture() end
  end)

  ---@type FontString
  local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT", 10, -54)
  status:SetJustifyH("LEFT")
  status:SetWidth(230)
  status:SetText("Status: Idle")

  frame.startButton = startButton
  frame.stopButton = stopButton
  frame.saveButton = saveButton
  frame.status = status

  frame.elapsed = 0
  ---@param self Frame
  ---@param elapsed number
  frame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed >= 0.5 then
      self.elapsed = 0
      Core.UpdateControlFrameStatus()
    end
  end)

  controlFrame = frame
  Core.UpdateControlFrameStatus()
end

--- Toggle visibility of the control frame.
function Core.ToggleControlFrame()
  if not controlFrame then return end
  controlFrame:SetShown(not controlFrame:IsShown())
end
