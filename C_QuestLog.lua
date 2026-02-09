C_QuestLogFix = {
  "AbandonQuest",
  "AddQuestWatch",
  "AddWorldQuestWatch",
  "CanAbandonQuest",
  "GetAbandonQuest",
  "GetAbandonQuestItems",
  "GetActiveThreatMaps",
  "GetAllCompletedQuestIDs",
  "GetBountiesForMapID",
  "GetBountySetInfoForMapID",
  "GetDistanceSqToQuest",
  "GetInfo",
  "GetLogIndexForQuestID",
  "GetMapForQuestPOIs",
  "GetMaxNumQuests",
  "GetMaxNumQuestsCanAccept",
  "GetNextWaypoint",
  "GetNextWaypointForMap",
  "GetNextWaypointText",
  "GetNumQuestLogEntries",
  "GetNumQuestObjectives",
  "GetNumQuestWatches",
  "GetNumWorldQuestWatches",
  "GetQuestAdditionalHighlights",
  "GetQuestDetailsTheme",
  "GetQuestDifficultyLevel",
  "GetQuestIDForLogIndex",
  "GetQuestIDForQuestWatchIndex",
  "GetQuestIDForWorldQuestWatchIndex",
  "GetQuestLogPortraitGiver",
  "GetQuestObjectives",
  "GetQuestTagInfo",
  "GetQuestType",
  "GetQuestWatchType",
  "GetQuestsOnMap",
  "GetRequiredMoney",
  "GetSelectedQuest",
  "GetSuggestedGroupSize",
  "GetTimeAllowed",
  "GetTitleForLogIndex",
  "GetTitleForQuestID",
  "GetZoneStoryInfo",
  "HasActiveThreats",
  "IsAccountQuest",
  "IsComplete",
  "IsFailed",
  "IsLegendaryQuest",
  "IsOnMap",
  "IsOnQuest",
  "IsPushableQuest",
  "IsQuestBounty",
  "IsQuestCalling",
  "IsQuestCriteriaForBounty",
  "IsQuestDisabledForSession",
  "IsQuestFlaggedCompleted",
  "IsQuestInvasion",
  "IsQuestReplayable",
  "IsQuestReplayedRecently",
  "IsQuestTask",
  "IsQuestTrivial",
  "IsRepeatableQuest",
  "IsThreatQuest",
  "IsUnitOnQuest",
  "IsWorldQuest",
  "QuestCanHaveWarModeBonus",
  "QuestHasQuestSessionBonus",
  "QuestHasWarModeBonus",
  "ReadyForTurnIn",
  "RemoveQuestWatch",
  "RemoveWorldQuestWatch",
  "RequestLoadQuestByID",
  "SetAbandonQuest",
  "SetMapForQuestPOIs",
  "SetSelectedQuest",
  "ShouldDisplayTimeRemaining",
  "ShouldShowQuestRewards",
  "SortQuestWatches",
}

-- This file is a copy of the C_QuestLog file from the wow-api-classic library.
-- It is used to test the functions in the QuestFunctions library.

local functions = ""
for _, funcName in ipairs(C_QuestLogFix) do
  if _G[funcName] then
    print("Function exists: " .. funcName)
    functions = functions .. funcName .. "\n"
  end
end



for funcName, value in pairs(_G) do
  local first = true
  if funcName:find("^C_") then
    if type(value) == "table" then
      for funcName2, func in pairs(_G[funcName]) do
        if _G[funcName2] and func == _G[funcName2] then
          if first then
            print(funcName)
            first = false
          end
          print("Function exists: " .. funcName2)
        end
      end
    end
  end
end

function CreateCopyFrame(text)
  local frame = CreateFrame("EditBox", nil, UIParent)
  frame:SetSize(200, 50)
  frame:SetPoint("CENTER")
  frame:SetText(text)
  frame:SetMultiLine(true)
  frame:SetFontObject("ChatFontNormal")
  frame:SetAutoFocus(false)
  frame:EnableMouse(true)
  frame:Show()
  return frame
end

CreateCopyFrame(functions)

-- CreateCopyFrame("Hello World")
