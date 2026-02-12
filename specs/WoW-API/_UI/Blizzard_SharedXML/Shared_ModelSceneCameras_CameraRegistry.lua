-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SharedXML\Shared\ModelSceneCameras\CameraRegistry.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

---@class CameraRegistry
CameraRegistry = { cameraTypeToFactoryFunction = {}, };

function CameraRegistry:AddCameraFactory(cameraTypeName, factoryFunction)
	self.cameraTypeToFactoryFunction[cameraTypeName] = factoryFunction;
end

function CameraRegistry:AddCameraFactoryFromMixin(cameraTypeName, mixin)
	self:AddCameraFactory(cameraTypeName, function() return CreateFromMixins(mixin); end);
end

function CameraRegistry:CreateCameraByType(cameraTypeName)
	if self.cameraTypeToFactoryFunction[cameraTypeName] then
		return self.cameraTypeToFactoryFunction[cameraTypeName]();
	end
end