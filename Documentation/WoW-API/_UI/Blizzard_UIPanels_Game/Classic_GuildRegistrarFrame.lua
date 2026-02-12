-- Original Path: .\WoWUI\Interface\AddOns\Blizzard_UIPanels_Game\Classic\GuildRegistrarFrame.lua
-- Auto-generated LuaLS Annotations, do not edit manually
---@meta _

function GuildRegistrar_OnShow()
	GuildRegistrarGreetingFrame:Show();
	GuildRegistrarPurchaseFrame:Hide();
	SetPortraitTexture(GuildRegistrarFramePortrait, "NPC");
	GuildRegistrarFrameNpcNameText:SetText(UnitName("NPC"));
end

function GuildRegistrar_ShowPurchaseFrame()
	GuildRegistrarPurchaseFrame:Show();
	GuildRegistrarGreetingFrame:Hide();
	MoneyFrame_Update("GuildRegistrarMoneyFrame", GetGuildCharterCost());
end

function GuildRegistrar_PurchaseCharter(hasConfirmed)
	BuyGuildCharter(GuildRegistrarFrameEditBox:GetText());
	HideUIPanel(GuildRegistrarFrame);
	ChatEdit_FocusActiveWindow();
	GuildRegistrarFrameEditBox:SetText("");
end