-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedMapDataProviders\GarrisonPlotDataProvider.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class GarrisonPlotDataProviderMixin : MapCanvasDataProviderMixin
GarrisonPlotDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);

function GarrisonPlotDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("GarrisonPlotPinTemplate");
end

function GarrisonPlotDataProviderMixin:RefreshAllData(fromOnShow)
	self:RemoveAllData();

	local mapID = self:GetMap():GetMapID();
	local garrisonPlots = C_Garrison.GetGarrisonPlotsInstancesForMap(mapID);
	for i, garrisonPlotInfo in ipairs(garrisonPlots) do
		self:GetMap():AcquirePin("GarrisonPlotPinTemplate", garrisonPlotInfo);
	end
end

--[[ Pin ]]--
---@class GarrisonPlotPinMixin : BaseMapPoiPinMixin
GarrisonPlotPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_GARRISON_PLOT");