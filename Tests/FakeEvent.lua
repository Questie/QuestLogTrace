---@class QuestLog
local QuestLog = select(2, ...)

-- QuestLog.Event.test()

function RunAcceptedQuest()
  local startTime = QUEST_ACCEPTED_TEST[1]["systemTimestamp"]
  print("Running AcceptedQuest Events")
  for i = 2, #QUEST_ACCEPTED_TEST do
    local event = QUEST_ACCEPTED_TEST[i]
    local eventKey = event.event
    local time = ((event["systemTimestamp"] - startTime) / 10) + (i * 0.01)
    C_Timer.After(time, function()
      local args = {}
      for j = 1, #event["args"] do
        args[j] = event["args"][j]
      end
      print("|cFF00FAF6", math.floor(time * 100) / 100, "seconds - Event: " .. event.event, unpack(args), "|r")
      if QuestLog.Event.RegisteredEvents[eventKey] then
        QuestLog.Event.RegisteredEvents[eventKey](unpack(args))
      end
    end)
  end
end

function RunCompleteQuest()
  local startTime = QUEST_COMPLETE_TEST[1]["systemTimestamp"]
  print("Running CompleteQuest Events")
  for i = 2, #QUEST_COMPLETE_TEST do
    local event = QUEST_COMPLETE_TEST[i]
    local eventKey = event.event
    local time = ((event["systemTimestamp"] - startTime) / 10) + (i * 0.01)
    C_Timer.After(time, function()
      local args = {}
      for j = 1, #event["args"] do
        args[j] = event["args"][j]
      end
      print("|cFF00FAF6", math.floor(time * 100) / 100, "seconds - Event: " .. event.event, unpack(args), "|r")
      if QuestLog.Event.RegisteredEvents[eventKey] then
        QuestLog.Event.RegisteredEvents[eventKey](unpack(args))
      end
    end)
  end
end
