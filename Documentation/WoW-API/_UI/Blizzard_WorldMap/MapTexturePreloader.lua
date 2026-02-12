-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_WorldMap\MapTexturePreloader.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

local PreloaderDriver = CreateFrame("Frame");

---@class preloadingRequests
local preloadingRequests = {};

local function PreloadPlayersMap()
	local mapID = C_Map.GetBestMapForUnit("player");
	if mapID and not preloadingRequests[mapID] then
		C_Map.RequestPreloadMap(mapID);

		preloadingRequests[mapID] = true;
	end
end

PreloaderDriver:SetScript("OnEvent", function(self, event, ...)
	if event == "ZONE_CHANGED" then
		PreloadPlayersMap();
	elseif event == "MAP_EXPLORATION_UPDATED" then
		PreloadPlayersMap();
	elseif event == "PLAYER_ENTERING_WORLD" then
		PreloadPlayersMap();
	end
end);

PreloaderDriver:RegisterEvent("ZONE_CHANGED");
PreloaderDriver:RegisterEvent("MAP_EXPLORATION_UPDATED");
PreloaderDriver:RegisterEvent("PLAYER_ENTERING_WORLD");