-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_SecureTransferUI\Blizzard_SecureTransferUIOutbound.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

-- Outbound loads under the global environment but needs to put the outbound table into the secure environment
local secureEnv = GetCurrentEnvironment();
SwapToGlobalEnvironment();
---@class SecureTransferOutbound
local SecureTransferOutbound = {};
secureEnv.SecureTransferOutbound = SecureTransferOutbound;
secureEnv = nil;	--This file shouldn't be calling back into secure code.

function SecureTransferOutbound.UpdateSendMailButton()
    securecall("SendMailFrame_EnableSendMailButton");
end
