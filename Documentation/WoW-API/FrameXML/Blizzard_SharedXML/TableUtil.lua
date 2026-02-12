---@meta _

local function ripairsiter(table, index)
	index = index - 1;
	if index > 0 then
		return index, table[index];
	end
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/ripairs)
-- Reverse iterates over a sequential table. Example:
-- ```
-- for i, v in ripairs(tbl) do body end
-- ```
---@param tbl table
---@return function iter
---@return table invariant
---@return number init
function ripairs(tbl)
	return ripairsiter, tbl, #tbl + 1;
end

---[FrameXML](https://www.townlong-yak.com/framexml/go/AccumulateIf)
---@param tbl table
---@param pred function
---@return number
function AccumulateIf(tbl, pred)
	local count = 0;
	for k, v in pairs(tbl) do
		if pred(v) then
			count = count + 1;
		end
	end
	return count;
end

