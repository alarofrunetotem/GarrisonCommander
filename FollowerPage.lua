local me, ns = ...
local addon=ns.addon --#addon
local L=ns.L
local D=ns.D
local C=ns.C
local AceGUI=ns.AceGUI
local _G=_G
local new, del, copy =ns.new,ns.del,ns.copy
-- Courtesy of Motig
-- Concept and interface reused with permission
-- Mission building rewritten from scratch
--local GMC_G = {}
local factory=addon:GetFactory()
--GMC_G.frame = CreateFrame('FRAME')
local aMissions={}
local dbcache
local cache
local db
local GMC
local GMF=GarrisonMissionFrame
local G=C_Garrison
local GMCUsedFollowers={}
local wipe=wipe
local pairs=pairs
local tinsert=tinsert
local xprint=ns.xprint
local coroutine=coroutine
local GetItemInfo=GetItemInfo
local GarrisonMissionFrame_SetItemRewardDetails=GarrisonMissionFrame_SetItemRewardDetails
local GetItemCount=GetItemCount
local strsplit=strsplit
local GarrisonFollower_DisplayUpgradeConfirmation=GarrisonFollower_DisplayUpgradeConfirmation
local StaticPopup_Show=StaticPopup_Show
local CONFIRM_GARRISON_FOLLOWER_UPGRADE=CONFIRM_GARRISON_FOLLOWER_UPGRADE
local GameTooltip=GameTooltip
local StaticPopupDialogs=StaticPopupDialogs
local YES=YES
local NO=NO
--@debug@
_G.GAC=addon
if LibDebug then LibDebug() end
--@end-debug@
local dbg

function addon:ShowImprovements()
	local scroller=self:GetScroller("Items")
	scroller:AddRow("Follower Upgrades",C.Orange())
	for i,v in pairs(self:GetUpgrades()) do
		scroller:AddRow(i,C.Yellow())
		for itemID,_ in pairs(v) do
			local b=scroller:AddItem(itemID)
			b:SetUserData("item",itemID)
			b:SetCallback("OnEnter",function(this)
				print("Item:",this:GetUserData("item"))
				GameTooltip:SetOwner(this.frame,"ANCHOR_CURSOR")
				GameTooltip:AddLine("Reward")
				GameTooltip:SetItemByID(this:GetUserData("item"))
				GameTooltip:Show() end)
			b:SetCallback("OnLeave",function(this) GameTooltip:Hide() end)
			b:SetCallback("OnClick",function(this) print("Clicckete") end)
		end
	end
	scroller:AddRow("Item Tokens",C.Orange())
	for i,v in pairs(self:GetItems()) do
		local b=scroller:AddItem(i)
	end
end
local CONFIRM1=L["Upgrading to %d"].."\n" .. CONFIRM_GARRISON_FOLLOWER_UPGRADE
local CONFIRM2=L["Upgrading to %d"].."\n|cFFFF0000 "..L["You are wasting points!!!"].."|r\n" .. CONFIRM_GARRISON_FOLLOWER_UPGRADE
local function DoUpgradeFollower(this)
		G.CastSpellOnFollower(this.data);
end
local function UpgradeFollower(this)
	local follower=this:GetParent()
	local followerID=follower.followerID
	local level=this.rawlevel
	local genere=this.tipo:sub(1,1)
	local mylevel=genere=="w" and follower.ItemWeapon.itemLevel or  follower.ItemArmor.itemLevel
	local name = ITEM_QUALITY_COLORS[G.GetFollowerQuality(followerID)].hex..G.GetFollowerName(followerID)..FONT_COLOR_CODE_CLOSE;
	local losing=false
	if level > 600 and mylevel>600 then
		losing=mylevel
	elseif mylevel+level > GARRISON_FOLLOWER_MAX_ITEM_LEVEL then
		losing=(mylevel+level)-GARRISON_FOLLOWER_MAX_ITEM_LEVEL
	end
	if losing then
		addon:Popup(format(CONFIRM2,losing,name),0,DoUpgradeFollower,true,followerID,true)
	else
		if addon:GetToggle("NOCONFIRM") then
			G.CastSpellOnFollower(followerID);
		else
			addon:Popup(format(CONFIRM1,mylevel+level,name),0,DoUpgradeFollower,true,followerID,true)
		end
	end
end
local colors={
	[1]="Yellow",
	[3]="Uncommon",
	[6]="Rare",
	[9]="Epic",
	[615]="Uncommon",
	[630]="Rare",
	[645]="Epic"
}
function addon:ShowUpgradeButtons(force)
	local gf=GMF.FollowerTab
	if (not force and not gf:IsShown()) then return end
	if (not gf.showUpgrades) then
		gf.showUpgrades=self:GetFactory():Checkbox(gf.Model,self:GetToggle("UPG"),self:GetVarInfo("UPG"))
		gf.showUpgrades:SetPoint("TOPLEFT")
		gf.showUpgrades:Show()
		gf.showUpgrades:SetScript("OnClick",function(this)
			addon:SetBoolean("UPG",this:GetChecked())
			addon:ShowUpgradeButtons()
		end)
	end
	if (not gf.noConfirm) then
		gf.noConfirm=self:GetFactory():Checkbox(gf.Model,self:GetToggle("NOCONFIRM"),self:GetVarInfo("NOCONFIRM"))
		gf.noConfirm:SetPoint("TOPLEFT",0,-25)
		gf.noConfirm:Show()
		gf.noConfirm:SetScript("OnClick",function(this)
			addon:SetBoolean("NOCONFIRM",this:GetChecked())
		end)
	end
	if not gf.upgradeButtons then gf.upgradeButtons ={} end
	--if not gf.upgradeFrame then gf.upgradeFrame=CreateFrame("Frame",nil,gf.model) end
	local b=gf.upgradeButtons
	local upgrades=self:GetUpgrades()
	local axpos=243
	local wxpos=7
	local wypos=-135
	local aypos=-135
	local used=1
	if not gf.followerID then
		return self:DelayedRefresh(0.1)
	end
	local followerID=gf.followerID
	local followerInfo = followerID and G.GetFollowerInfo(followerID);
	if ( followerInfo and followerInfo.isCollected and not followerInfo.status and followerInfo.level == GARRISON_FOLLOWER_MAX_LEVEL ) then
		for i=1,#upgrades do
			if not b[used] then
				b[used]=CreateFrame("Button",nil,gf,"GarrisonCommanderUpgradeButton,SecureActionbuttonTemplate")
			end
			local tipo,itemID,level=strsplit(":",upgrades[i])
			level=tonumber(level)
			local A=b[used]
			local qt=GetItemCount(itemID)
			repeat
			if (qt>0) then
				A:ClearAllPoints()
				A.tipo=tipo
				local currentlevel=tipo:sub(1,1)=="w" and gf.ItemWeapon.itemLevel or  gf.ItemArmor.itemLevel
				if level > 600 and level <= currentlevel then
					break -- Pointless item for this toon
				end
				used=used+1
				if (tipo:sub(1,1)=="a") then
					A:SetPoint("TOPLEFT",axpos,aypos)
					aypos=aypos-45
				else
					A:SetPoint("TOPLEFT",wxpos,wypos)
					wypos=wypos-45
				end
				A:SetSize(40,40)
				A.Icon:SetSize(40,40)
				A.itemID=itemID
				GarrisonMissionFrame_SetItemRewardDetails(A)
				A.rawlevel=level
				A.Level:SetText(level < 600 and (currentlevel+level) or level)
				local c=colors[level]
				A.Level:SetTextColor(C[c]())
				A.Quantity:SetFormattedText("%d",qt)
				A.Quantity:SetTextColor(C.Yellow())
				A:SetFrameLevel(gf.Model:GetFrameLevel()+1)
				A.Quantity:Show()
				A.Level:Show()
				A:EnableMouse(true)
				A:RegisterForClicks("LeftButtonDown")
				A:SetAttribute("type","item")
				A:SetAttribute("item",select(2,GetItemInfo(itemID)))
				A:Show()
				if tipo=="at" or tipo =="wt" then
					A.Level:Hide()
					A:SetScript("PostClick",nil)
				else
					A.Level:Show()
					A:SetScript("PostClick",UpgradeFollower)
				end
			end
			until true -- Continue dei poveri
		end
	end
	for i=used,#b do
		b[i]:Hide()
	end
end
function addon:DelayedRefresh(delay)
	if GMF.FollowerTab:IsShown() then
		if not tonumber(delay) then delay=0.5 end
		return C_Timer.After(delay,function() addon:ShowUpgradeButtons() end)
	end
end
function addon:FollowerPageStartUp()
	self:RegisterEvent("GARRISON_FOLLOWER_UPGRADED","DelayedRefresh")
	self:RegisterEvent("CHAT_MSG_LOOT","DelayedRefresh")
end


