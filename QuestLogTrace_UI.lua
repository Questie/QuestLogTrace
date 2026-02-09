QuestLogTraceCore = QuestLogTraceCore or {}
local Core = QuestLogTraceCore

local controlFrame = nil

function Core.UpdateControlFrameStatus()
  if not controlFrame then
    return
  end

  local state = Core.GetStatusData and Core.GetStatusData() or {
    isRunning = false,
    sessionName = "None",
    eventCount = 0,
    snapshotCount = 0,
    canSave = false,
  }

  local statusLabel = state.isRunning and "Running" or "Stopped"
  controlFrame.status:SetText(
    string.format("Status: %s\nSession: %s\nEvents: %d  Snapshots: %d", statusLabel, state.sessionName, state.eventCount,
      state.snapshotCount)
  )

  controlFrame.startButton:SetEnabled(not state.isRunning)
  controlFrame.stopButton:SetEnabled(state.isRunning)
  controlFrame.saveButton:SetEnabled(state.canSave)
end

function Core.BuildControlFrame()
  if controlFrame then
    return
  end

  local frame = CreateFrame("Frame", "QuestLogTraceControlFrame", UIParent)
  frame:SetSize(250, 100)
  frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
  end)

  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(true)
  bg:SetColorTexture(0.05, 0.05, 0.05, 0.85)

  local border = frame:CreateTexture(nil, "BORDER")
  border:SetAllPoints(true)
  border:SetColorTexture(0.20, 0.20, 0.20, 0.9)
  border:SetDrawLayer("BORDER", 1)

  local inner = frame:CreateTexture(nil, "ARTWORK")
  inner:SetPoint("TOPLEFT", 1, -1)
  inner:SetPoint("BOTTOMRIGHT", -1, 1)
  inner:SetColorTexture(0.08, 0.08, 0.08, 0.9)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -8)
  title:SetText("QuestLogTrace")

  local startButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  startButton:SetSize(72, 22)
  startButton:SetPoint("TOPLEFT", 10, -26)
  startButton:SetText("Start")
  startButton:SetScript("OnClick", function()
    if Core.StartCapture then
      Core.StartCapture()
    end
  end)

  local stopButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  stopButton:SetSize(72, 22)
  stopButton:SetPoint("LEFT", startButton, "RIGHT", 8, 0)
  stopButton:SetText("Stop")
  stopButton:SetScript("OnClick", function()
    if Core.StopCapture then
      Core.StopCapture()
    end
  end)

  local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  saveButton:SetSize(72, 22)
  saveButton:SetPoint("LEFT", stopButton, "RIGHT", 8, 0)
  saveButton:SetText("Save")
  saveButton:SetScript("OnClick", function()
    if Core.SaveCapture then
      Core.SaveCapture()
    end
  end)

  local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT", 10, -54)
  status:SetJustifyH("LEFT")
  status:SetWidth(230)
  status:SetText("Status: Stopped")

  frame.startButton = startButton
  frame.stopButton = stopButton
  frame.saveButton = saveButton
  frame.status = status

  frame.elapsed = 0
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

function Core.ToggleControlFrame()
  if not controlFrame then
    return
  end

  if controlFrame:IsShown() then
    controlFrame:Hide()
  else
    controlFrame:Show()
  end
end
