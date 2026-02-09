------@diagnostic disable: undefined-global
--! This code is not created by me
--! It is a 99% copy of the Blizzard_EventTrace addon
--! It can be found in third party repos on GitHub such as:
--!
--!
--!
local MinPanelWidth                     = 715;
local MinPanelHeight                    = 210;
local DefaultPanelWidth                 = MinPanelWidth;
local DefaultPanelHeight                = 400;
local MaxEvents                         = 1000;

local EVENTTRACE_HEADER                 = "Quest Log Trace";
local EVENTTRACE_LOG_START              = "QL - Logging started";
local EVENTTRACE_LOG_PAUSE_WHILE_HIDDEN = "Logging paused while hidden";
local EVENTTRACE_LOG_HEADER             = "Event Log";
local EVENTTRACE_FILTER_HEADER          = "Filters";
local EVENTTRACE_BUTTON_MARKER          = "Set Mark";
local EVENTTRACE_BUTTON_DISCARD_FILTER  = "Discard Filter";
local EVENTTRACE_LOG_DISCARD            = "Event Log discarded";
local EVENTTRACE_OPTIONS                = "Options";
local EVENTTRACE_LOG_PAUSE              = "QL - Logging paused";
local EVENTTRACE_TIMESTAMP              = "Timestamp";
local EVENTTRACE_BUTTON_PLAY            = "Play";
local EVENTTRACE_BUTTON_PAUSE           = "Pause";
local EVENTTRACE_MARKER                 = "QL - Marker";
local EVENTTRACE_BUTTON_ENABLE_FILTERS  = "Check All";
local EVENTTRACE_BUTTON_DISABLE_FILTERS = "Uncheck All";

--??
local EVENTTRACE_APPLY_DEFAULT_FILTER   = "Apply Default Filter";
local EVENTTRACE_LOG_WHEN_HIDDEN        = "Log when hidden";
local EVENTTRACE_SHOW_ARGUMENTS         = "Show arguments";
local EVENTTRACE_SHOW_TIMESTAMP         = "Show timestamp";
local EVENTTRACE_LOG_CR_EVENTS          = "Log CR events";

local EVENTTRACE_RESULTS                = "Results: %d";
local EVENTTRACE_ARG_FMT                = "Arg %d:";
local EVENTTRACE_MESSAGE_FORMAT         = "--- %s ---"

local GREEN_FONT_COLOR                  = CreateColor(0.098, 1.000, 0.098, 1.000)
local ORANGE_FONT_COLOR                 = CreateColor(1.000, 0.502, 0.251, 1.000)
local BRIGHTBLUE_FONT_COLOR             = CreateColor(0.400, 0.733, 1.000, 1.000)
local LIGHTYELLOW_FONT_COLOR            = CreateColor(1.000, 1.000, 0.600, 1.000)
local GRAY_FONT_COLOR                   = CreateColor(0.502, 0.502, 0.502, 1.000)

local function GetDisplayEvent(elementData)
  return elementData.displayEvent or elementData.event;
end

local function ApplyAlternateState(frame, alternate)
  frame:SetAlternateOverlayShown(alternate);
end

QLTraceSavedVars =
{
  LogEventsWhenHidden = true,
  ShowArguments = true,
  ShowTimestamp = true,
  LogCREvents = true,
  Filters =
  {
    User = {},
  },
  Size =
  {
    Width = DefaultPanelWidth,
    Height = DefaultPanelHeight,
  },
};

QLTraceButtonBehaviorMixin = {};

function QLTraceButtonBehaviorMixin:OnEnter()
  self.MouseoverOverlay:Show();
end

function QLTraceButtonBehaviorMixin:OnLeave()
  self.MouseoverOverlay:Hide();
end

function QLTraceButtonBehaviorMixin:SetAlternateOverlayShown(alternate)
  self.Alternate:SetShown(alternate);
end

QLTraceScrollBoxButtonMixin = {};

function QLTraceScrollBoxButtonMixin:Flash()
  self.FlashOverlay.Anim:Play();
end

---@class QLTracePanelMixin : ToolWindowOwnerMixin, Frame, { Log: any, TitleBar: PanelDragBarMixin, ResizeButton: PanelResizeButtonMixin, SubtitleBar: any, Filter: any }
QLTracePanelMixin = CreateFromMixins(ToolWindowOwnerMixin);

function QLTracePanelMixin:OnSetDebugToolVisible(addonName, showTool)
  if addonName == "Blizzard_EventTrace" then
    self:SetShown(showTool);
  end
end

function QLTracePanelMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)

  self.isLoggingPaused = false;
  self.loadTime = GetTime();
  self.showingArguments = true;

  self.logDataProvider = CreateDataProvider();
  self.searchDataProvider = CreateDataProvider();
  self.searchDataProvider:RegisterCallback(DataProviderMixin.Event.OnSizeChanged, self.OnSearchDataProviderChanged, self);

  self.filterDataProvider = CreateDataProvider();
  self.filterDataProvider:SetSortComparator(function(lhs, rhs)
    return lhs.event < rhs.event;
  end);

  self.idCounter = CreateCounter();
  self.frameCounter = 0;
  local timer = CreateFrame("FRAME");
  timer:SetScript("OnUpdate", function(o, elapsed)
    self.frameCounter = self.frameCounter + 1;
  end);

  self:InitializeSubtitleBar();
  self:InitializeLog();
  self:InitializeFilter();
  self:InitializeOptions();

  -- ! Logon Change - Register events instead of filter
  -- self:RegisterAllEvents();
  for _, event in ipairs(GetEventsToRegister()) do
    self:RegisterEvent(event);
  end

  self.TitleBar:Init(self);
  self.ResizeButton:Init(self, MinPanelWidth, MinPanelHeight);
  self:SetTitle(EVENTTRACE_HEADER);

  hooksecurefunc(EventRegistry, "TriggerEvent", function(registry, event, ...)
    QLTrace:LogCallbackRegistryEvent(registry, event, ...);
  end);

  self:UpdatePlaybackButton();

  EventRegistry:RegisterFrameEvent("SET_DEBUG_TOOL_VISIBLE");
  EventRegistry:RegisterCallback("SET_DEBUG_TOOL_VISIBLE", self.OnSetDebugToolVisible, self);
end

function QLTracePanelMixin:OnShow()
  self:MoveToNewWindow(EVENTTRACE_HEADER, 1000, 600, 930, 300);

  self.Log.Events.ScrollBox:ScrollToEnd();

  if not self:IsLoggingEventsWhenHidden() then
    self:LogMessage(EVENTTRACE_LOG_START);
  end
end

function QLTracePanelMixin:OnCloseClick()
  PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
  self:Hide();
  self.window:Close();
end

function QLTracePanelMixin:OnHide()
  if not self:IsLoggingEventsWhenHidden() then
    self:LogMessage(EVENTTRACE_LOG_PAUSE_WHILE_HIDDEN);
  end
end

function QLTracePanelMixin:SaveVariables()
  QLTraceSavedVars.Filters.User = {};
  for index, elementData in self.filterDataProvider:Enumerate() do
    tinsert(QLTraceSavedVars.Filters.User, elementData);
  end

  local width, height = self:GetSize();
  QLTraceSavedVars.Size.Width = width;
  QLTraceSavedVars.Size.Height = height;

  QLTraceSavedVars.LogEventsWhenHidden = self:IsLoggingEventsWhenHidden();
  QLTraceSavedVars.ShowArguments = self:IsShowingArguments();
  QLTraceSavedVars.ShowTimestamp = self:IsShowingTimestamp();
  QLTraceSavedVars.LogCREvents = self:IsLoggingCREvents();
end

function QLTracePanelMixin:LoadVariables()
  for index, elementData in ipairs(QLTraceSavedVars.Filters.User) do
    self.filterDataProvider:Insert(elementData);
  end

  self:SetSize(QLTraceSavedVars.Size.Width, QLTraceSavedVars.Size.Height);

  self:SetLoggingEventsWhenHidden(QLTraceSavedVars.LogEventsWhenHidden);
  self:SetShowingArguments(QLTraceSavedVars.ShowArguments);
  self:SetShowingTimestamp(QLTraceSavedVars.ShowTimestamp);
  self:SetLoggingCREvents(QLTraceSavedVars.LogCREvents);
end

function QLTracePanelMixin:InitializeSubtitleBar()
  self.SubtitleBar.ViewLog.Label:SetText(EVENTTRACE_LOG_HEADER);
  self.SubtitleBar.ViewLog:SetScript("OnClick", function()
    self:ViewLog();
  end);

  self.SubtitleBar.ViewFilter.Label:SetText(EVENTTRACE_FILTER_HEADER);
  self.SubtitleBar.ViewFilter:SetScript("OnClick", function()
    self:ViewFilter();
  end);
end

function QLTracePanelMixin:UpdatePlaybackButton()
  self.Log.Bar.PlaybackButton.Label:SetText(self:IsLoggingPaused() and EVENTTRACE_BUTTON_PLAY or EVENTTRACE_BUTTON_PAUSE);
end

local function SetScrollBoxButtonAlternateState(scrollBox)
  local index = scrollBox:GetDataIndexBegin();
  scrollBox:ForEachFrame(function(button)
    button:SetAlternateOverlayShown(index % 2 == 1);
    index = index + 1;
  end);
end

function QLTracePanelMixin:DisplayEvents()
  self.Log.Bar.Label:SetText(EVENTTRACE_LOG_HEADER);
  self.Log.Events:Show();
  self.Log.Search:Hide();
end

function QLTracePanelMixin:DisplaySearch()
  self.Log.Search:Show();
  self.Log.Events:Hide();
end

function QLTracePanelMixin:OnSearchDataProviderChanged(hasSortComparator)
  local size = self.searchDataProvider:GetSize();
  local text = (EVENTTRACE_RESULTS):format(size);
  self.Log.Bar.Label:SetText(text);
end

function QLTracePanelMixin:TryAddToSearch(elementData, search)
  local s = search:upper()

  if string.len(s) > 0 and (string.find(tostring(elementData.id), s) or
        (elementData.event and string.find(elementData.event, s)) or
        (elementData.arguments and string.find((elementData.arguments):upper(), s)) or
        (elementData.message and string.find((elementData.message):upper(), s))) then
    local shallow = true;
    self.searchDataProvider:Insert(CopyTable(elementData, shallow));
    return true;
  end
  return false;
end

function QLTracePanelMixin:InitializeLog()
  self.Log.Bar.Label:SetText(EVENTTRACE_LOG_HEADER);
  self.Log.Bar.MarkButton.Label:SetText(EVENTTRACE_BUTTON_MARKER);
  self.Log.Bar.MarkButton:SetScript("OnClick", function(button, buttonName)
    print("hej")
    self:LogMessage(EVENTTRACE_MARKER);
  end);

  self.Log.Bar.PlaybackButton:SetScript("OnClick", function(button, buttonName)
    self:TogglePause();
  end);

  self.Log.Bar.DiscardAllButton.Label:SetText(EVENTTRACE_BUTTON_DISCARD_FILTER);
  self.Log.Bar.DiscardAllButton:SetScript("OnClick", function(button, buttonName)
    self.logDataProvider:Flush();
    self.searchDataProvider:Flush();
    self:LogMessage(EVENTTRACE_LOG_DISCARD);
  end);

  self.Log.Bar.SearchBox:HookScript("OnTextChanged", function(o)
    self.searchDataProvider:Flush();

    local text = self.Log.Bar.SearchBox:GetText();
    local empty = string.len(text) == 0;
    if empty then
      self:DisplayEvents();
    else
      self:DisplaySearch();
      local words = {};
      for word in string.gmatch(text:upper(), "([^, ]+)") do
        tinsert(words, word);
      end

      for _, elementData in self.logDataProvider:Enumerate() do
        for _, word in ipairs(words) do
          if self:TryAddToSearch(elementData, word) then
            break;
          end
        end
      end

      local pendingSearch = self.pendingSearch;
      if pendingSearch then
        self.pendingSearch = nil;

        local found = self.Log.Search.ScrollBox:ScrollToElementDataByPredicate(function(elementData)
                                                                                 return elementData.id == pendingSearch.id;
                                                                               end, ScrollBoxConstants.AlignCenter);

        if found then
          local button = self.Log.Search.ScrollBox:FindFrame(found);
          if button then
            button:Flash();
          end
        end
      elseif self.Log.Search.ScrollBox:HasScrollableExtent() then
        self.Log.Search.ScrollBox:ScrollToEnd();
      end
    end
  end);

  ScrollUtil.RegisterAlternateRowBehavior(self.Log.Events.ScrollBox, ApplyAlternateState);
  ScrollUtil.RegisterAlternateRowBehavior(self.Log.Search.ScrollBox, ApplyAlternateState);

  local function AddEventToFilter(scrollBox, elementData)
    local found = self.filterDataProvider:FindElementDataByPredicate(function(filterData)
      return filterData.event == elementData.event;
    end);
    if found then
      found.enabled = true;

      local button = scrollBox:FindFrame(elementData);
      if button then
        button:UpdateEnabledState();
      end
    else
      self.filterDataProvider:Insert({ event = elementData.event:upper(), displayEvent = GetDisplayEvent(elementData), enabled = true });
    end
    self:RemoveEventFromDataProvider(self.logDataProvider, elementData.event);
    self:RemoveEventFromDataProvider(self.searchDataProvider, elementData.event);
  end

  do
    local function LocateInSearch(elementData, text)
      self.pendingSearch = elementData;
      self.Log.Bar.SearchBox:SetText(text);
    end

    local view = CreateScrollBoxListLinearView();
    view:SetElementFactory(function(factory, elementData)
      if elementData.event then
        factory("QLTraceLogEventButtonTemplate", function(button, elementData)
          button:Init(elementData, self:IsShowingArguments(), self:IsShowingTimestamp());

          button.HideButton:SetScript("OnMouseDown", function(button, buttonName)
            AddEventToFilter(self.Filter.ScrollBox, elementData);
          end);

          button:SetScript("OnClick", function(button, buttonName, down)
            if buttonName == "RightButton" then
              -- CopyToClipboard(elementData.event);
              print("CopyToClipboard is a protected function - NYI")
            end
          end);

          button:SetScript("OnDoubleClick", function(button, buttonName)
            if buttonName == "LeftButton" then
              LocateInSearch(elementData, elementData.event);
            end
          end);
        end);
      elseif elementData.message then
        factory("QLTraceLogMessageButtonTemplate", function(button, elementData)
          button:Init(elementData);

          button:SetScript("OnDoubleClick", function(button, buttonName)
            LocateInSearch(elementData, elementData.message);
          end);
        end);
      end
    end);

    local pad = 2;
    local spacing = 2;
    view:SetPadding(pad, pad, pad, pad, spacing);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.Log.Events.ScrollBox, self.Log.Events.ScrollBar, view);

    self.Log.Events.ScrollBox:SetDataProvider(self.logDataProvider);
  end

  do
    local function LocateInLog(elementData)
      self.Log.Bar.SearchBox:SetText("");
      self:DisplayEvents();

      local found = self.Log.Events.ScrollBox:ScrollToElementDataByPredicate(function(data)
                                                                               return data.id == elementData.id;
                                                                             end, ScrollBoxConstants.AlignCenter);

      local button = found and self.Log.Events.ScrollBox:FindFrame(found);
      if button then
        button:Flash();
      end
    end

    local view = CreateScrollBoxListLinearView();
    view:SetElementFactory(function(factory, elementData)
      if elementData.event then
        factory("QLTraceLogEventButtonTemplate", function(button, elementData)
          button:Init(elementData, self:IsShowingArguments());

          button.HideButton:SetScript("OnMouseDown", function(button, buttonName)
            AddEventToFilter(self.Log.Search.ScrollBox, elementData);
          end);

          button:SetScript("OnClick", function(button, buttonName, down)
            if buttonName == "RightButton" then
              CopyToClipboard(elementData.event);
            end
          end);

          button:SetScript("OnDoubleClick", function(button, buttonName)
            if buttonName == "LeftButton" then
              LocateInLog(elementData);
            end
          end);
        end);
      elseif elementData.message then
        factory("QLTraceLogMessageButtonTemplate", function(button, elementData)
          button:Init(elementData);

          button:SetScript("OnDoubleClick", function(button, buttonName)
            LocateInLog(elementData);
          end);
        end);
      end
    end);

    local pad = 2;
    local spacing = 2;
    view:SetPadding(pad, pad, pad, pad, spacing);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.Log.Search.ScrollBox, self.Log.Search.ScrollBar, view);

    self.Log.Search.ScrollBox:SetDataProvider(self.searchDataProvider);
  end
end

function QLTracePanelMixin:InitializeFilter()
  self.Filter.Bar.Label:SetText(EVENTTRACE_FILTER_HEADER);

  local function SetEventsEnabled(enabled)
    for index, elementData in self.filterDataProvider:Enumerate() do
      elementData.enabled = enabled;
    end

    self.Filter.ScrollBox:ForEachFrame(function(button)
      button:UpdateEnabledState();
    end);
  end

  local function InitializeCheckButton(button, text, enable)
    button.Label:SetText(text);
    button:SetScript("OnClick", function(button, buttonName)
      SetEventsEnabled(enable);
    end);
  end

  InitializeCheckButton(self.Filter.Bar.CheckAllButton, EVENTTRACE_BUTTON_ENABLE_FILTERS, true);
  InitializeCheckButton(self.Filter.Bar.UncheckAllButton, EVENTTRACE_BUTTON_DISABLE_FILTERS, false);

  self.Filter.Bar.DiscardAllButton.Label:SetText(EVENTTRACE_BUTTON_DISCARD_FILTER);
  self.Filter.Bar.DiscardAllButton:SetScript("OnClick", function(button, buttonName)
    self.filterDataProvider:Flush();
  end);

  ScrollUtil.RegisterAlternateRowBehavior(self.Filter.ScrollBox, ApplyAlternateState);

  local function RemoveEventFromFilter(elementData)
    self.filterDataProvider:Remove(elementData);
  end

  local view = CreateScrollBoxListLinearView();
  view:SetElementInitializer("QLTraceFilterButtonTemplate", function(button, elementData)
    button:Init(elementData, RemoveEventFromFilter);
  end);

  local pad = 2;
  local spacing = 2;
  view:SetPadding(pad, pad, pad, pad, spacing);

  ScrollUtil.InitScrollBoxListWithScrollBar(self.Filter.ScrollBox, self.Filter.ScrollBar, view);

  self.Filter.ScrollBox:SetDataProvider(self.filterDataProvider);
end

local loadOnce = true;
function QLTracePanelMixin:InitializeOptions()
  self.SubtitleBar.OptionsDropdown:SetText(EVENTTRACE_OPTIONS);
  self.SubtitleBar.OptionsDropdown:SetupMenu(function(dropdown, rootDescription)
    rootDescription:SetTag("MENU_EVENT_TRACE_FILTER");

    rootDescription:CreateButton(EVENTTRACE_APPLY_DEFAULT_FILTER, function()
      self.filterDataProvider:Flush();
      for index, elementData in ipairs(GetAllFiltersDisabled()) do
        self.filterDataProvider:Insert(CopyTable(elementData));
      end
    end);

    -- Logon Change - Always log when hidden
    self:SetLoggingEventsWhenHidden(true);

    -- if loadOnce then
    --   loadOnce = false;
    --   self.filterDataProvider:Flush();
    --   local filters = GetAllFiltersDisabled();
    --   for i = 1, #filters do
    --     local elementData = filters[i];
    --     self.filterDataProvider:Insert(elementData);
    --   end
    -- end

    rootDescription:CreateDivider();

    do
      local function IsSelected()
        return self:IsLoggingEventsWhenHidden();
      end

      local function SetSelected()
        self:SetLoggingEventsWhenHidden(not self:IsLoggingEventsWhenHidden());
      end

      rootDescription:CreateCheckbox(EVENTTRACE_LOG_WHEN_HIDDEN, IsSelected, SetSelected);
    end

    do
      local function IsSelected()
        return self:IsShowingArguments();
      end

      local function SetSelected()
        self:SetShowingArguments(not self:IsShowingArguments());
      end

      rootDescription:CreateCheckbox(EVENTTRACE_SHOW_ARGUMENTS, IsSelected, SetSelected);
    end

    do
      local function IsSelected()
        return self:IsShowingTimestamp();
      end

      local function SetSelected()
        self:SetShowingTimestamp(not self:IsShowingTimestamp());
      end

      rootDescription:CreateCheckbox(EVENTTRACE_SHOW_TIMESTAMP, IsSelected, SetSelected);
    end

    do
      local function IsSelected()
        return self:IsLoggingCREvents();
      end

      local function SetSelected()
        self:SetLoggingCREvents(not self:IsLoggingCREvents());
      end

      rootDescription:CreateCheckbox(EVENTTRACE_LOG_CR_EVENTS, IsSelected, SetSelected);
    end
  end);
end

function QLTracePanelMixin:IsLoggingEventsWhenHidden()
  return self.logEventsWhenHidden;
end

function QLTracePanelMixin:SetLoggingEventsWhenHidden(logEventsWhenHidden)
  self.logEventsWhenHidden = logEventsWhenHidden;
end

function QLTracePanelMixin:IsShowingArguments()
  return self.showingArguments;
end

function QLTracePanelMixin:SetShowingArguments(show)
  self.showingArguments = show;

  self:UpdateLogScrollBoxes(function(frame)
    frame:OnShowArgumentsChanged(frame:GetElementData(), show);
  end);
end

function QLTracePanelMixin:SetShowingTimestamp(show)
  self.showingTimestamp = show;

  self:UpdateLogScrollBoxes(function(frame)
    frame:OnShowTimestampChanged(frame:GetElementData(), show);
  end);
end

function QLTracePanelMixin:UpdateLogScrollBoxes(func)
  self.Log.Events.ScrollBox:ForEachFrame(func);
  self.Log.Search.ScrollBox:ForEachFrame(func);
end

function QLTracePanelMixin:IsShowingTimestamp()
  return self.showingTimestamp;
end

function QLTracePanelMixin:IsLoggingCREvents()
  return self.loggingCREvents;
end

function QLTracePanelMixin:SetLoggingCREvents(logging)
  self.loggingCREvents = logging;
end

function QLTracePanelMixin:ViewLog()
  self.Log:Show();
  self.Filter:Hide();
end

function QLTracePanelMixin:ViewFilter()
  self.Log.Bar.SearchBox:SetText("");
  self.Log:Hide();
  self.Filter:Show();
end

function QLTracePanelMixin:ProcessChatCommand(msg)
  if msg then
    local words = string.gmatch(msg, "([^ ]+)");
    for word in words do -- luacheck: ignore 512 (loop is executed at most once)
      local Mark = "MARK";
      if string.upper(word) == Mark then
        local index = string.find(msg, word);
        self:LogMessage(string.sub(msg, index + string.len(Mark)));
        return true;
      end

      break;
    end
  end
  return false;
end

function QLTracePanelMixin:IsLoggingPaused()
  return self.isLoggingPaused;
end

function QLTracePanelMixin:SetLoggingPaused(paused)
  self.isLoggingPaused = paused;

  self:LogMessage(paused and EVENTTRACE_LOG_PAUSE or EVENTTRACE_LOG_START);
  self:UpdatePlaybackButton();
end

function QLTracePanelMixin:CanLogEvent(event)
  return (self:IsShown() or self:IsLoggingEventsWhenHidden()) and not (self:IsLoggingPaused() or self:IsIgnoredEvent(event));
end

function QLTracePanelMixin:LogMessage(message)
  self:LogLine({ message = message });
end

local function CreateEventElementData(event, ...)
  return { event = event, args = SafePack(...) };
end

function QLTracePanelMixin:LogEvent(event, ...)
  if not self:CanLogEvent(event) then
    return;
  end

  self:LogLine(CreateEventElementData(event, ...));
end

function QLTracePanelMixin:LogCallbackRegistryEvent(sender, event, ...)
  if not self:CanLogEvent(event) or not self:IsLoggingCREvents() then
    return;
  end

  local elementData = CreateEventElementData(event:upper(), ...);
  elementData.displayEvent = string.format("%s %s", event, DARKYELLOW_FONT_COLOR:WrapTextInColorCode("(CR)"));

  local senderStr = DARKYELLOW_FONT_COLOR:WrapTextInColorCode(("(CR: %s)"):format(sender.GetDebugName and sender:GetDebugName() or tostring(sender)));
  elementData.displayMessage = string.format("%s %s", event, senderStr);
  self:LogLine(elementData);
end

function QLTracePanelMixin:LogLine(elementData)
  local preInsertAtScrollEnd = self.Log.Events.ScrollBox:IsAtEnd();
  local preInsertScrollable = self.Log.Events.ScrollBox:HasScrollableExtent();

  local systemTimestamp, relativeTimestamp, eventDelta = self:GenerateTimestampData();
  elementData.id = self.idCounter();
  elementData.systemTimestamp = systemTimestamp;
  elementData.relativeTimestamp = relativeTimestamp;
  elementData.frameCounter = self.frameCounter;
  elementData.eventDelta = eventDelta;

  self.logDataProvider:Insert(elementData);
  self:TrimDataProvider(self.logDataProvider);

  self:TryAddToSearch(elementData, self.Log.Bar.SearchBox:GetText())
  self:TrimDataProvider(self.searchDataProvider);

  if not IsAltKeyDown() and (preInsertAtScrollEnd or (not preInsertScrollable and self.Log.Events.ScrollBox:HasScrollableExtent())) then
    self.Log.Events.ScrollBox:ScrollToEnd();
  end
end

function QLTracePanelMixin:OnEvent(event, ...)
  if event == "IMGUI_RENDER_ENABLED" then
    return;
  end

  if event == "ADDONS_UNLOADING" then
    self:SaveVariables();
    return;
  end

  if event == "ADDON_LOADED" then
    local addon = ...;
    if addon == "Blizzard_EventTrace" then
      self:LoadVariables();
      self:UnregisterEvent("ADDON_LOADED");
      self:Show();
    end
  end

  self:LogEvent(event, ...);
end

function QLTracePanelMixin:TogglePause()
  self:SetLoggingPaused(not self.isLoggingPaused);
end

local function CalculateEventDelta(oldTimestamp, oldFrameCounter, currentTimestamp, currentFrameCounter)
  if oldTimestamp ~= currentTimestamp then
    return ("(%.3fs, %d)"):format(currentTimestamp - oldTimestamp, currentFrameCounter - oldFrameCounter);
  end
  return nil;
end

function QLTracePanelMixin:GenerateTimestampData()
  local systemTimestamp = GetTime();
  local relativeTimestamp = systemTimestamp - self.loadTime;

  local eventDelta;
  local endElement = self.logDataProvider:Find(self.logDataProvider:GetSize());
  if endElement then
    eventDelta = CalculateEventDelta(endElement.relativeTimestamp, endElement.frameCounter, relativeTimestamp, self.frameCounter);
  end
  return systemTimestamp, relativeTimestamp, eventDelta;
end

function QLTracePanelMixin:TrimDataProvider(dataProvider)
  local dataProviderSize = dataProvider:GetSize();
  if dataProviderSize > MaxEvents then
    local extra = 100;
    local overflow = dataProviderSize - MaxEvents;
    dataProvider:RemoveIndexRange(1, overflow + extra);
  end
end

function QLTracePanelMixin:IsIgnoredEvent(event)
  local e = event:upper();
  return self.filterDataProvider:ContainsByPredicate(function(elementData)
    return elementData.enabled and elementData.event == e;
  end);
end

function QLTracePanelMixin:RemoveEventFromDataProvider(dataProvider, event)
  local index = dataProvider:GetSize();
  while index >= 1 do
    local elementData = dataProvider:Find(index);
    if elementData.event == event then
      dataProvider:RemoveIndex(index);
    end
    index = index - 1;
  end
end

local function CreateClock(timestamp)
  local units = ConvertSecondsToUnits(timestamp);
  local seconds = units.seconds + units.milliseconds;
  if units.hours > 0 then
    return string.format("%.2d:%.2d:%06.3fs", units.hours, units.minutes, seconds);
  else
    return string.format("%.2d:%06.3fs", units.minutes, seconds);
  end
end

local ArgumentColors =
{
  ["string"] = GREEN_FONT_COLOR,
  ["number"] = ORANGE_FONT_COLOR,
  ["boolean"] = BRIGHTBLUE_FONT_COLOR,
  ["table"] = LIGHTYELLOW_FONT_COLOR,
  ["nil"] = GRAY_FONT_COLOR,
};

local function GetArgumentColor(arg)
  return ArgumentColors[type(arg)] or HIGHLIGHT_FONT_COLOR;
end

local function FormatArgument(arg)
  local color = GetArgumentColor(arg);
  local t = type(arg);
  if t == "string" then
    return color:WrapTextInColorCode(string.format('"%s"', arg));
  elseif t == "nil" then
    return color:WrapTextInColorCode(t);
  end
  return color:WrapTextInColorCode(tostring(arg));
end

local function FormatLogID(elementData)
  return GRAY_FONT_COLOR:WrapTextInColorCode(string.format("[%.3d]", (elementData.id % MaxEvents)));
end

local function FormatLine(id, message)
  return string.format("%s %s", id, message);
end

QLTraceLogEventButtonMixin = {};

local function AddTooltipArguments(...)
  local count = select("#", ...);
  for index = 1, count do
    local arg = select(index, ...);
    GameTooltip_AddColoredDoubleLine(QLTraceTooltip, EVENTTRACE_ARG_FMT:format(index), FormatArgument(arg), HIGHLIGHT_FONT_COLOR, GetArgumentColor(arg));
  end
end

function QLTraceLogEventButtonMixin:OnLoad()
  self.HideButton:ClearAllPoints();
  self.HideButton:SetPoint("LEFT", self, "LEFT", 3, 0);
end

function QLTraceLogEventButtonMixin:OnEnter()
  QLTraceButtonBehaviorMixin.OnEnter(self);
  QLTraceTooltip:SetOwner(self, "ANCHOR_RIGHT");
  local elementData = self:GetElementData();
  GameTooltip_AddHighlightLine(QLTraceTooltip, GetDisplayEvent(elementData), HIGHLIGHT_FONT_COLOR);
  GameTooltip_AddColoredDoubleLine(QLTraceTooltip, EVENTTRACE_TIMESTAMP, elementData.systemTimestamp, HIGHLIGHT_FONT_COLOR, HIGHLIGHT_FONT_COLOR);

  AddTooltipArguments(SafeUnpack(elementData.args));

  QLTraceTooltip:Show();
end

function QLTraceLogEventButtonMixin:OnLeave()
  QLTraceButtonBehaviorMixin.OnLeave(self)

  QLTraceTooltip:Hide();
end

local function AddLineArguments(...)
  local words = {};
  local count = select("#", ...);
  for index = 1, count do
    local arg = select(index, ...);
    table.insert(words, FormatArgument(arg));
  end

  local wordCount = #words;
  if wordCount == 0 then
    return "";
  elseif wordCount == 1 then
    return words[1];
  end
  return table.concat(words, ", ");
end

function QLTraceLogEventButtonMixin:Init(elementData, showArguments, showTimestamp)
  local id = FormatLogID(elementData);
  local message = elementData.displayMessage or elementData.event;
  elementData.lineWithoutArguments = FormatLine(id, message);

  elementData.arguments = AddLineArguments(SafeUnpack(elementData.args));
  elementData.formattedArguments = GREEN_FONT_COLOR:WrapTextInColorCode(elementData.arguments);
  self:SetLeftText(elementData, showArguments);

  local clock = CreateClock(elementData.relativeTimestamp);
  elementData.formattedTimestamp = string.format("%s %s", clock, elementData.eventDelta and elementData.eventDelta or "");
  self:SetRightText(elementData, showTimestamp);
end

function QLTraceLogEventButtonMixin:SetLeftText(elementData, showArguments)
  if showArguments then
    self.LeftLabel:SetText(string.format("%s %s", elementData.lineWithoutArguments, elementData.formattedArguments));
  else
    self.LeftLabel:SetText(elementData.lineWithoutArguments);
  end
end

function QLTraceLogEventButtonMixin:SetRightText(elementData, showTimestamp)
  if showTimestamp then
    self.RightLabel:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(elementData.formattedTimestamp));
  else
    self.RightLabel:SetText("");
  end
end

function QLTraceLogEventButtonMixin:OnShowArgumentsChanged(elementData, showArguments)
  self:SetLeftText(elementData, showArguments);
end

function QLTraceLogEventButtonMixin:OnShowTimestampChanged(elementData, showTimestamp)
  self:SetRightText(elementData, showTimestamp);
end

QLTraceLogMessageButtonMixin = {};

function QLTraceLogMessageButtonMixin:Init(elementData)
  local id = FormatLogID(elementData);
  local message = ORANGE_FONT_COLOR:WrapTextInColorCode(string.format(EVENTTRACE_MESSAGE_FORMAT, elementData.message));
  elementData.lineWithoutArguments = FormatLine(id, message);

  self:SetLeftText(elementData);
end

function QLTraceLogMessageButtonMixin:SetLeftText(elementData)
  self.LeftLabel:SetText(elementData.lineWithoutArguments);
end

function QLTraceLogMessageButtonMixin:OnShowArgumentsChanged(elementData, showArguments)
  self:SetLeftText(elementData);
end

function QLTraceLogMessageButtonMixin:OnShowTimestampChanged(elementData, showTimestamp)
end

function QLTraceLogMessageButtonMixin:SetRightText(elementData)
end

QLTraceFilterButtonMixin = {};

function QLTraceFilterButtonMixin:Init(elementData, hideCb)
  self.Label:SetText(GetDisplayEvent(elementData));

  self:UpdateEnabledState();

  self.HideButton:SetScript("OnMouseDown", function(button, buttonName)
    hideCb(elementData);
  end);

  self.CheckButton:SetScript("OnClick", function(button, buttonName)
    self:ToggleEnabledState();
  end);
end

function QLTraceFilterButtonMixin:UpdateEnabledState()
  local elementData = self:GetElementData();
  self.CheckButton:SetChecked(elementData.enabled);
  self:SetAlpha(elementData.enabled and 1 or .7);
  self:DesaturateHierarchy(elementData.enabled and 0 or 1);
end

function QLTraceFilterButtonMixin:OnDoubleClick()
  self:ToggleEnabledState();
end

function QLTraceFilterButtonMixin:ToggleEnabledState()
  local elementData = self:GetElementData();
  elementData.enabled = not elementData.enabled;
  self:UpdateEnabledState();
end
