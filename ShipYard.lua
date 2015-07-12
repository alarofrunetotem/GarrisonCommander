local me, ns = ...
ns.Configure()
local addon=addon --#addon
local over=over --#over
local _G=_G
local GSF=GSF
local G=C_Garrison
local pairs=pairs
local format=format
local strsplit=strsplit
local generated
local GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY=GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY
local GARRISON_CURRENCY=GARRISON_CURRENCY
local GARRISON_SHIP_OIL_CURRENCY=GARRISON_SHIP_OIL_CURRENCY
local GARRISON_FOLLOWER_MAX_LEVEL=GARRISON_FOLLOWER_MAX_LEVEL
local LE_FOLLOWER_TYPE_GARRISON_6_0=LE_FOLLOWER_TYPE_GARRISON_6_0
local LE_FOLLOWER_TYPE_SHIPYARD_6_2=LE_FOLLOWER_TYPE_SHIPYARD_6_2
local module=addon:NewSubClass('ShipYard') --#Module
function sprint(nome,this,...)
	print(nome,this:GetName(),...)
end
function module:OnInitialize()
	self:SafeSecureHook("GarrisonFollowerButton_UpdateCounters")
	self:SafeSecureHook(GSF,"OnClickMission","HookedGSF_OnClickMission")
	local ref=GSFMissions.CompleteDialog.BorderFrame.ViewButton
	print(ref)
	local bt = CreateFrame('BUTTON','GCQuickShipMissionCompletionButton', ref, 'UIPanelButtonTemplate')
	bt.missionType=LE_FOLLOWER_TYPE_SHIPYARD_6_2
	bt:SetWidth(300)
	bt:SetText(L["Garrison Comander Quick Mission Completion"])
	bt:SetPoint("CENTER",0,-50)
	addon:ActivateButton(bt,"MissionComplete",L["Complete all missions without confirmation"])
--@debug@
	print("ShipYard Loaded")
	self:SafeSecureHook("GarrisonShipyardMapMission_SetTooltip")
	self:SafeSecureHook("GarrisonShipyardMap_UpdateMissions")
	self:SafeHookScript(GSF,"OnShow","Setup",true)
	self:SafeHookScript(GSF.MissionTab.MissionList.CompleteDialog,"OnShow",function(... ) sprint("CompleteDialog",...) end,true)
	self:SafeHookScript(GSF.MissionTab,"OnShow",function(... ) sprint("MissionTab",...) end,true)
	self:SafeHookScript(GSF.FollowerTab,"OnShow",function(... ) sprint("FollowerTab",...) end,true)
	--GarrisonShipyardFrameFollowersListScrollFrameButton1
	--GarrisonShipyardMapMission1
--@end-debug@
end
function module:HookedGarrisonShipyardMap_UpdateMissions()
	local self = GarrisonShipyardFrame.MissionTab.MissionList
	print("Could manage",#self.missions)
end
function module:HookedGSF_OnClickMission(this,missionInfo)
	self:FillMissionPage(missionInfo)
end
function module:HookedGarrisonFollowerButton_UpdateCounters(gsf,frame,follower,showcounter,lastupdate)
	if follower.followerTypeID~=LE_FOLLOWER_TYPE_SHIPYARD_6_2 then return end
	if not frame.GCXp then
		frame.GCXp=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
	end
	if follower.isCollected and follower.quality < GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY  then
		frame.GCXp:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,-5)
		frame.GCXp:SetFormattedText("Xp to go: %d",follower.levelXP-follower.xp)
		frame.GCXp:Show()
	else
		frame.GCXp:Hide()
	end
--@debug@
	--print(follower)
--@end-debug@
end

function module:Setup(this,...)
	print("Doing one time initialization for",this:GetName(),...)
	self:SafeHookScript(GSF,"OnShow","OnShow",true)
	GSF:EnableMouse(true)
	GSF:SetMovable(true)
	GSF:RegisterForDrag("LeftButton")
	GSF:SetScript("OnDragStart",function(frame)if (self:GetBoolean("MOVEPANEL")) then frame:StartMoving() end end)
	GSF:SetScript("OnDragStop",function(frame) frame:StopMovingOrSizing() end)
end
function module:OnShow()
	print("Doing all time initialization")
end
function module:HookedGarrisonShipyardMapMission_SetTooltip(info,inProgress)
	local tooltipFrame = GarrisonShipyardMapMissionTooltip;
	tooltipFrame:SetHeight(tooltipFrame:GetHeight()+20)
	if (not tooltipFrame.dbg) then
		tooltipFrame.dbg=tooltipFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
		tooltipFrame.dbg:SetPoint("BOTTOMLEFT",10,10)
	end
	tooltipFrame.dbg:Show()
	tooltipFrame.dbg:SetFormattedText("Mission ID: %d" ,info.missionID);
end

function module:OpenLastTab()
print("Should restore tab")
end
--[[
displayHeight = 0.25
followerTypeID = 2
iLevel = 600
isCollected = true
classAtlas = Ships_TroopTransport-List
garrFollowerID = 0x00000000000001E2
displayScale = 95
level = 100
quality = 3
portraitIconID = 0
isFavorite = false
xp = 1500
texPrefix = Ships_TroopTransport
className = Transport
classSpec = 53
name = Chen's Favorite Brew
followerID = 0x00000000011E4D8F
height = 0.30000001192093
displayID = 63894
scale = 110
levelXP = 40000
--]]
--view mission button GSF.MissionTab.MissionList.CompleteDialog.BorderFrame.ViewButton