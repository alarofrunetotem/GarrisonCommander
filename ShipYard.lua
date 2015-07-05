local me, ns = ...
ns.Configure()
local addon=addon --#addon
local over=over --#over
local _G=_G
local GSF=GarrisonShipyardFrame
local G=C_Garrison
local pairs=pairs
local format=format
local strsplit=strsplit
local generated
local GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY=GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY
local module=addon:NewSubClass('ShipYard') --#Module
function sprint(nome,this,...)
	print(nome,this:GetName(),...)
end
function module:OnInitialize()
	override("GarrisonFollowerButton_UpdateCounters")
--@debug@
	print("ShipYard Loaded")
	override("GarrisonShipyardMapMission_SetTooltip")
	override("GarrisonShipyardFrame","OnClickMission")
	self:SafeHookScript(GSF,"OnShow","Setup",true)
	self:SafeHookScript(GSF.MissionTab.MissionList.CompleteDialog,"OnShow",function(... ) sprint("CompleteDialog",...) end,true)
	self:SafeHookScript(GSF.MissionTab,"OnShow",function(... ) sprint("MissionTab",...) end,true)
	self:SafeHookScript(GSF.FollowerTab,"OnShow",function(... ) sprint("FollowerTab",...) end,true)
	--GarrisonShipyardFrameFollowersListScrollFrameButton1
	--GarrisonShipyardMapMission1
	local ref=GSFMissions.CompleteDialog.BorderFrame.ViewButton
	print(ref)
	local bt = CreateFrame('BUTTON','GCQuickShipMissionCompletionButton', ref, 'UIPanelButtonTemplate')
	bt:SetWidth(300)
	bt:SetText(L["Garrison Comander Quick Mission Completion"])
	bt:SetPoint("CENTER",0,-50)
	addon:ActivateButton(bt,"MissionComplete",L["Complete all missions without confirmation"])
--@end-debug@
end

local over=over --#over
function over.GarrisonShipyardFrame_OnClickMission(this,missionInfo)
	-- this = GarrisonShipyardframe
	local frame=GSF.MissionTab.MissionPage.Stage
	orig.GarrisonShipyardFrame_OnClickMission(this,missionInfo)
--@debug@
	if not frame.GCID then
		frame.GCID=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
		frame.GCID:SetPoint("TOPLEFT",frame.MissionTime,"TOPRIGHT",5,0)
	end
	frame.GCID:SetFormattedText("MissionID: %d",missionInfo.missionID)
	frame.GCID:Show()
--@end-debug@
end
function over.GarrisonFollowerButton_UpdateCounters(gsf,frame,follower,showcounter,lastupdate)
	orig.GarrisonFollowerButton_UpdateCounters(gsf,frame,follower,showcounter,lastupdate)
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
	print(follower)
--@end-debug@
end

function module:Setup(this,...)
	print("Doing one time initialization for",this:GetName(),...)
	self:SafeHookScript(GSF,"OnShow","OnShow",true)
	GSF:SetMovable(true)
end
function module:OnShow()
	print("Doing all time initialization")
end
function over.GarrisonShipyardMapMission_SetTooltip(info,inProgress)
	orig.GarrisonShipyardMapMission_SetTooltip(info,inProgress)
	local tooltipFrame = GarrisonShipyardMapMissionTooltip;
	tooltipFrame.Name:SetText(info.name .. " " .. info.missionID);
	tooltipFrame:SetHeight(tooltipFrame:GetHeight()+20)
	if (not tooltipFrame.dbg) then
		tooltipFrame.dbg=tooltipFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
		tooltipFrame.dbg:SetPoint("BOTTOMLEFT")
	end
	tooltipFrame.dbg:Show()
	tooltipFrame.dbg:SetFormattedText("Mission ID: %d" ,info.missionID);
end

--view mission button GSF.MissionTab.MissionList.CompleteDialog.BorderFrame.ViewButton