-- QuestLogTrace SavedVariables validator
-- Usage:
--   lua scripts/validate_savedvars.lua QuestLogTrace_data_slim.lua

local path = arg[1]
if not path or path == "" then
  io.stderr:write("usage: lua scripts/validate_savedvars.lua <savedvars.lua>\n")
  os.exit(2)
end

local function is_array(t)
  if type(t) ~= "table" then return false end
  local n = #t
  for k, _ in pairs(t) do
    if type(k) ~= "number" or k < 1 or k > n or k % 1 ~= 0 then
      return false
    end
  end
  return true
end

local function count_keys(t)
  local c = 0
  for _ in pairs(t or {}) do c = c + 1 end
  return c
end

local function size_set(s)
  local c = 0
  for _ in pairs(s) do c = c + 1 end
  return c
end

local function has_dupe_values(arr)
  local seen = {}
  for i = 1, #arr do
    if seen[arr[i]] then
      return true
    end
    seen[arr[i]] = true
  end
  return false
end

local function is_packed_table(t)
  if type(t) ~= "table" then
    return false
  end
  local n = t.n
  return type(n) == "number" and n >= 0 and n % 1 == 0
end

local issues = {}
local warnings = {}

local function issue(msg)
  issues[#issues + 1] = msg
end

local function warn(msg)
  warnings[#warnings + 1] = msg
end

QuestLogTrace = nil
QuestLogTraceCharacter = nil
local ok, err = pcall(dofile, path)
if not ok then
  io.stderr:write("failed to load file: " .. tostring(err) .. "\n")
  os.exit(2)
end

local root = QuestLogTraceCharacter or QuestLogTrace
if type(root) ~= "table" then
  io.stderr:write("no QuestLogTraceCharacter/QuestLogTrace table found\n")
  os.exit(2)
end

if type(root.sessions) ~= "table" then
  issue("root.sessions missing or not a table")
end

local sessions = root.sessions or {}
if #sessions == 0 then
  warn("no sessions present")
end

for sIndex = 1, #sessions do
  local s = sessions[sIndex]
  local sPrefix = string.format("session[%d]", sIndex)

  if type(s) ~= "table" then
    issue(sPrefix .. " is not a table")
  else
    if type(s.trace) ~= "table" then issue(sPrefix .. ".trace missing") end
    if type(s.state) ~= "table" then issue(sPrefix .. ".state missing") end
    if type(s.summary) ~= "table" then issue(sPrefix .. ".summary missing") end

    local trace = s.trace or {}
    local state = s.state or {}
    local summary = s.summary or {}

    local events = trace.events or {}
    local eventDict = trace.eventDict or {}
    local eventRecords = state.eventRecords or state.questEventTriggers or {}
    local positionSamples = state.positionSamples or {}
    local levelEvents = state.levelEvents or {}
    local lootHistory = state.lootHistory or {}
    local reputationHistory = state.reputationHistory or {}
    local reputationMeta = state.reputationMeta or {}
    local questLogHistory = state.questLogHistory or {}
    local questHistory = state.questHistory or {}
    local completed = state.completedQuestsHistory or {}
    local positionLookup = state.positionLookup or nil

    if type(events) ~= "table" then issue(sPrefix .. ".trace.events not table") end
    if type(eventDict) ~= "table" then issue(sPrefix .. ".trace.eventDict not table") end
    if type(eventRecords) ~= "table" then issue(sPrefix .. ".state.eventRecords not table") end
    if type(positionSamples) ~= "table" then issue(sPrefix .. ".state.positionSamples not table") end
    if type(levelEvents) ~= "table" then issue(sPrefix .. ".state.levelEvents not table") end
    if type(lootHistory) ~= "table" then issue(sPrefix .. ".state.lootHistory not table") end
    if type(reputationHistory) ~= "table" then issue(sPrefix .. ".state.reputationHistory not table") end
    if type(reputationMeta) ~= "table" then issue(sPrefix .. ".state.reputationMeta not table") end
    if type(questLogHistory) ~= "table" then issue(sPrefix .. ".state.questLogHistory not table") end
    if type(questHistory) ~= "table" then issue(sPrefix .. ".state.questHistory not table") end
    if type(completed) ~= "table" then issue(sPrefix .. ".state.completedQuestsHistory not table") end

    local hasPositionLookup = type(positionLookup) == "table"
    local lookupStyle = "none"
    local lookupM, lookupZ, lookupSZ, lookupRZ = nil, nil, nil, nil
    local lookupCombined = nil

    if hasPositionLookup then
      local hasSplitKeys = (positionLookup.m ~= nil) or (positionLookup.z ~= nil) or (positionLookup.sz ~= nil) or (positionLookup.rz ~= nil)
      if hasSplitKeys then
        lookupStyle = "split"
        lookupM = type(positionLookup.m) == "table" and positionLookup.m or nil
        lookupZ = type(positionLookup.z) == "table" and positionLookup.z or nil
        lookupSZ = type(positionLookup.sz) == "table" and positionLookup.sz or nil
        lookupRZ = type(positionLookup.rz) == "table" and positionLookup.rz or nil
        if not lookupM then issue(sPrefix .. ".state.positionLookup.m not table") end
        if not lookupZ then issue(sPrefix .. ".state.positionLookup.z not table") end
        if not lookupSZ then issue(sPrefix .. ".state.positionLookup.sz not table") end
        if not lookupRZ then issue(sPrefix .. ".state.positionLookup.rz not table") end
      else
        local numericCount = 0
        local allNumericEntriesTables = true
        for k, v in pairs(positionLookup) do
          if type(k) == "number" then
            numericCount = numericCount + 1
            if type(v) ~= "table" then
              allNumericEntriesTables = false
              break
            end
          end
        end

        if numericCount > 0 and allNumericEntriesTables then
          lookupStyle = "combined"
          lookupCombined = positionLookup
        elseif next(positionLookup) ~= nil then
          issue(sPrefix .. ".state.positionLookup has unknown format")
        end
      end
    end

    -- trace checks
    do
    local prevT = -math.huge
    for i = 1, #events do
      local ev = events[i]
      if type(ev) ~= "table" then
        issue(sPrefix .. string.format(".trace.events[%d] not table", i))
      else
        local eId = ev.e
        if type(eId) ~= "number" or eId < 1 or eId % 1 ~= 0 then
          issue(sPrefix .. string.format(".trace.events[%d].e invalid", i))
        elseif eventDict[eId] == nil then
          issue(sPrefix .. string.format(".trace.events[%d].e out of eventDict range", i))
        end

        if type(ev.t) ~= "number" then
          issue(sPrefix .. string.format(".trace.events[%d].t not number", i))
        elseif ev.t < prevT then
          issue(sPrefix .. string.format(".trace.events[%d].t decreased", i))
        else
          prevT = ev.t
        end
      end
    end
    end

    -- tracked event record checks
    do
      local prevT = -math.huge
      for i = 1, #eventRecords do
        local tr = eventRecords[i]
        if type(tr) ~= "table" then
          issue(sPrefix .. string.format(".state.eventRecords[%d] not table", i))
        else
          if type(tr.t) == "number" then
            if tr.t < prevT then
              issue(sPrefix .. string.format(".state.eventRecords[%d].t decreased", i))
            else
              prevT = tr.t
            end
          else
            issue(sPrefix .. string.format(".state.eventRecords[%d].t not number", i))
          end

          if tr.p ~= nil then
            warn(sPrefix .. string.format(".state.eventRecords[%d] still has legacy p payload", i))
          end
          if tr.pi ~= nil then
            warn(sPrefix .. string.format(".state.eventRecords[%d] still has legacy pi payload", i))
          end
        end
      end
    end

    -- position checks
    do
    local prevT = -math.huge
    local lastPosKey = nil
    for i = 1, #positionSamples do
      local p = positionSamples[i]
      if type(p) ~= "table" then
        issue(sPrefix .. string.format(".state.positionSamples[%d] not table", i))
      else
        if type(p.t) ~= "number" then
          issue(sPrefix .. string.format(".state.positionSamples[%d].t not number", i))
        elseif p.t < prevT then
          issue(sPrefix .. string.format(".state.positionSamples[%d].t decreased", i))
        else
          prevT = p.t
        end

        local resolvedM, resolvedZ, resolvedSZ, resolvedRZ = p.m, p.z, p.sz, p.rz
        if lookupStyle == "split" then
          local function check_lookup_index(field, idx, lookup)
            if type(idx) ~= "number" or idx % 1 ~= 0 or idx < 0 then
              issue(sPrefix .. string.format(".state.positionSamples[%d].%s invalid lookup index", i, field))
              return nil
            end
            if idx > 0 and lookup and lookup[idx] == nil then
              issue(sPrefix .. string.format(".state.positionSamples[%d].%s index out of range", i, field))
            end
            if idx == 0 then
              return nil
            end
            return lookup and lookup[idx] or nil
          end

          resolvedM = check_lookup_index("m", p.m, lookupM)
          resolvedZ = check_lookup_index("z", p.z, lookupZ)
          resolvedSZ = check_lookup_index("sz", p.sz, lookupSZ)
          resolvedRZ = check_lookup_index("rz", p.rz, lookupRZ)
        elseif lookupStyle == "combined" then
          local pIndex = p.p
          if type(pIndex) ~= "number" or pIndex % 1 ~= 0 or pIndex < 1 then
            issue(sPrefix .. string.format(".state.positionSamples[%d].p invalid lookup index", i))
          else
            local entry = lookupCombined[pIndex]
            if type(entry) ~= "table" then
              issue(sPrefix .. string.format(".state.positionSamples[%d].p index out of range", i))
            else
              resolvedM = entry.m
              resolvedZ = entry.z
              resolvedSZ = entry.sz
              resolvedRZ = entry.rz
            end
          end
        end

        local key = table.concat({
          tostring(resolvedM), tostring(p.x), tostring(p.y), tostring(resolvedZ), tostring(resolvedSZ), tostring(resolvedRZ)
        }, "|")
        if lastPosKey and key == lastPosKey then
          warn(sPrefix .. string.format(".state.positionSamples[%d] duplicates previous position state", i))
        end
        lastPosKey = key
      end
    end
    end

    -- level event ordering checks
    do
      local prevT = -math.huge
      for i = 1, #levelEvents do
        local row = levelEvents[i]
        if type(row) ~= "table" or type(row.t) ~= "number" then
          issue(sPrefix .. string.format(".state.levelEvents[%d] invalid", i))
        else
          if row.t < prevT then
            issue(sPrefix .. string.format(".state.levelEvents[%d].t decreased", i))
          end
          prevT = row.t
        end
      end
    end

    -- completed quest delta checks
    do
    local prevT = -math.huge
    local set = {}
    for i = 1, #completed do
      local c = completed[i]
      if type(c) ~= "table" then
        issue(sPrefix .. string.format(".state.completedQuestsHistory[%d] not table", i))
      else
        if type(c.t) ~= "number" then
          issue(sPrefix .. string.format(".state.completedQuestsHistory[%d].t not number", i))
        elseif c.t < prevT then
          issue(sPrefix .. string.format(".state.completedQuestsHistory[%d].t decreased", i))
        else
          prevT = c.t
        end

        local added = c.a or {}
        local removed = c.r or {}
        if type(added) ~= "table" or not is_array(added) then
          issue(sPrefix .. string.format(".state.completedQuestsHistory[%d].a invalid", i))
          added = {}
        end
        if type(removed) ~= "table" or not is_array(removed) then
          issue(sPrefix .. string.format(".state.completedQuestsHistory[%d].r invalid", i))
          removed = {}
        end

        if has_dupe_values(added) then issue(sPrefix .. string.format(".state.completedQuestsHistory[%d].a has duplicates", i)) end
        if has_dupe_values(removed) then issue(sPrefix .. string.format(".state.completedQuestsHistory[%d].r has duplicates", i)) end

        for j = 1, #added do
          local q = added[j]
          if set[q] then
            issue(sPrefix .. string.format(".state.completedQuestsHistory[%d] adds already-completed questId %s", i, tostring(q)))
          end
          set[q] = true
        end

        for j = 1, #removed do
          local q = removed[j]
          if not set[q] then
            issue(sPrefix .. string.format(".state.completedQuestsHistory[%d] removes missing questId %s", i, tostring(q)))
          end
          set[q] = nil
        end

        if c.c ~= nil and type(c.c) == "number" then
          local realCount = size_set(set)
          if c.c ~= realCount then
            issue(sPrefix .. string.format(".state.completedQuestsHistory[%d].c mismatch (expected %d got %d)", i, realCount, c.c))
          end
        else
          issue(sPrefix .. string.format(".state.completedQuestsHistory[%d].c missing/invalid", i))
        end

        if c.q ~= nil then
          warn(sPrefix .. string.format(".state.completedQuestsHistory[%d] has legacy q payload", i))
        end
      end
    end
    end

    -- loot history checks
    do
      local prevT = -math.huge
      for i = 1, #lootHistory do
        local row = lootHistory[i]
        if type(row) ~= "table" then
          issue(sPrefix .. string.format(".state.lootHistory[%d] not table", i))
        else
          if type(row.t) ~= "number" then
            issue(sPrefix .. string.format(".state.lootHistory[%d].t not number", i))
          elseif row.t < prevT then
            issue(sPrefix .. string.format(".state.lootHistory[%d].t decreased", i))
          else
            prevT = row.t
          end

          if type(row.e) ~= "string" or row.e == "" then
            issue(sPrefix .. string.format(".state.lootHistory[%d].e invalid", i))
          end
          if type(row.n) ~= "number" or row.n < 1 or row.n % 1 ~= 0 then
            issue(sPrefix .. string.format(".state.lootHistory[%d].n invalid", i))
          end
          if type(row.slots) ~= "table" or not is_array(row.slots) then
            issue(sPrefix .. string.format(".state.lootHistory[%d].slots invalid", i))
          else
            if type(row.n) == "number" and row.n % 1 == 0 and row.n >= 0 and #row.slots > row.n then
              warn(sPrefix .. string.format(".state.lootHistory[%d].slots exceeds n", i))
            end
            for j = 1, #row.slots do
              local slot = row.slots[j]
              if type(slot) ~= "table" then
                issue(sPrefix .. string.format(".state.lootHistory[%d].slots[%d] not table", i, j))
              else
                if type(slot.i) ~= "number" or slot.i < 1 or slot.i % 1 ~= 0 then
                  issue(sPrefix .. string.format(".state.lootHistory[%d].slots[%d].i invalid", i, j))
                end
                if not is_packed_table(slot.l) then
                  issue(sPrefix .. string.format(".state.lootHistory[%d].slots[%d].l invalid packed args", i, j))
                end
                if not is_packed_table(slot.s) then
                  issue(sPrefix .. string.format(".state.lootHistory[%d].slots[%d].s invalid packed args", i, j))
                end
                if slot.k ~= nil and type(slot.k) ~= "string" then
                  issue(sPrefix .. string.format(".state.lootHistory[%d].slots[%d].k invalid link", i, j))
                end
                if slot.t ~= nil and (type(slot.t) ~= "number" or slot.t < 0 or slot.t % 1 ~= 0) then
                  issue(sPrefix .. string.format(".state.lootHistory[%d].slots[%d].t invalid slot type", i, j))
                end
              end
            end
          end
        end
      end
    end

    -- reputation history checks
    do
      local totalRepSnapshots = 0
      for factionID, arr in pairs(reputationHistory) do
        local fid = tonumber(factionID)
        if not fid then
          issue(sPrefix .. string.format(".state.reputationHistory has non-numeric factionID key %s", tostring(factionID)))
        end
        if type(arr) ~= "table" then
          issue(sPrefix .. string.format(".state.reputationHistory[%s] not table", tostring(factionID)))
        else
          local prevT = -math.huge
          totalRepSnapshots = totalRepSnapshots + #arr
          for i = 1, #arr do
            local row = arr[i]
            if type(row) ~= "table" then
              issue(sPrefix .. string.format(".state.reputationHistory[%s][%d] not table", tostring(factionID), i))
            else
              if type(row.t) ~= "number" then
                issue(sPrefix .. string.format(".state.reputationHistory[%s][%d].t invalid", tostring(factionID), i))
              elseif row.t < prevT then
                issue(sPrefix .. string.format(".state.reputationHistory[%s][%d].t decreased", tostring(factionID), i))
              else
                prevT = row.t
              end
              if type(row.e) ~= "string" or row.e == "" then
                issue(sPrefix .. string.format(".state.reputationHistory[%s][%d].e invalid", tostring(factionID), i))
              end
              if row.s ~= nil and type(row.s) ~= "number" then issue(sPrefix .. string.format(".state.reputationHistory[%s][%d].s invalid", tostring(factionID), i)) end
              if row.mn ~= nil and type(row.mn) ~= "number" then issue(sPrefix .. string.format(".state.reputationHistory[%s][%d].mn invalid", tostring(factionID), i)) end
              if row.mx ~= nil and type(row.mx) ~= "number" then issue(sPrefix .. string.format(".state.reputationHistory[%s][%d].mx invalid", tostring(factionID), i)) end
              if row.v ~= nil and type(row.v) ~= "number" then issue(sPrefix .. string.format(".state.reputationHistory[%s][%d].v invalid", tostring(factionID), i)) end
              if row.w ~= nil and type(row.w) ~= "boolean" then issue(sPrefix .. string.format(".state.reputationHistory[%s][%d].w invalid", tostring(factionID), i)) end
              if row.iw ~= nil and type(row.iw) ~= "boolean" then issue(sPrefix .. string.format(".state.reputationHistory[%s][%d].iw invalid", tostring(factionID), i)) end
            end
          end
        end
      end

      if summary.reputationFactionCount ~= nil and summary.reputationFactionCount ~= count_keys(reputationHistory) then
        warn(sPrefix .. ".summary.reputationFactionCount mismatch")
      end
      if summary.reputationSnapshotCount ~= nil and summary.reputationSnapshotCount ~= totalRepSnapshots then
        warn(sPrefix .. ".summary.reputationSnapshotCount mismatch")
      end
    end

    -- quest history ordering checks
    do
    for questId, arr in pairs(questHistory) do
      if type(arr) ~= "table" then
        issue(sPrefix .. string.format(".state.questHistory[%s] not table", tostring(questId)))
      else
        local prevT = -math.huge
        for i = 1, #arr do
          local snap = arr[i]
          if type(snap) ~= "table" or type(snap.t) ~= "number" then
            issue(sPrefix .. string.format(".state.questHistory[%s][%d] invalid", tostring(questId), i))
          else
            if snap.t < prevT then
              issue(sPrefix .. string.format(".state.questHistory[%s][%d].t decreased", tostring(questId), i))
            end
            prevT = snap.t
          end
        end
      end
    end
    end

    -- quest log history ordering checks
    do
    local prevT = -math.huge
    for i = 1, #questLogHistory do
      local row = questLogHistory[i]
      if type(row) ~= "table" or type(row.t) ~= "number" then
        issue(sPrefix .. string.format(".state.questLogHistory[%d] invalid", i))
      else
        if row.t < prevT then
          issue(sPrefix .. string.format(".state.questLogHistory[%d].t decreased", i))
        end
        prevT = row.t
      end
    end
    end

    -- summary consistency checks
    do
    local qCount = count_keys(questHistory)
    if summary.eventCount ~= nil and summary.eventCount ~= #events then
      warn(sPrefix .. ".summary.eventCount mismatch")
    end
    if summary.trackedEventCount ~= nil and summary.trackedEventCount ~= #eventRecords then
      warn(sPrefix .. ".summary.trackedEventCount mismatch")
    end
    if summary.questCount ~= nil and summary.questCount ~= qCount then
      warn(sPrefix .. ".summary.questCount mismatch")
    end
    if summary.questLogSnapshots ~= nil and summary.questLogSnapshots ~= #questLogHistory then
      warn(sPrefix .. ".summary.questLogSnapshots mismatch")
    end
    if summary.completedQuestSnapshots ~= nil and summary.completedQuestSnapshots ~= #completed then
      warn(sPrefix .. ".summary.completedQuestSnapshots mismatch")
    end
    if summary.lootSnapshotCount ~= nil and summary.lootSnapshotCount ~= #lootHistory then
      warn(sPrefix .. ".summary.lootSnapshotCount mismatch")
    end
    if summary.positionSampleCount ~= nil and summary.positionSampleCount ~= #positionSamples then
      warn(sPrefix .. ".summary.positionSampleCount mismatch")
    end
    if summary.levelEventCount ~= nil and summary.levelEventCount ~= #levelEvents then
      warn(sPrefix .. ".summary.levelEventCount mismatch")
    end
  end
  end
end

print(string.format("Validated: %s", path))
print(string.format("Sessions: %d", #sessions))
print(string.format("Issues: %d", #issues))
print(string.format("Warnings: %d", #warnings))

if #issues > 0 then
  print("--- Issues ---")
  for i = 1, #issues do
    print(string.format("%d. %s", i, issues[i]))
  end
end

if #warnings > 0 then
  print("--- Warnings ---")
  local maxWarn = math.min(#warnings, 40)
  for i = 1, maxWarn do
    print(string.format("%d. %s", i, warnings[i]))
  end
  if #warnings > maxWarn then
    print(string.format("... %d more warnings omitted", #warnings - maxWarn))
  end
end

if #issues > 0 then
  os.exit(1)
end
os.exit(0)
