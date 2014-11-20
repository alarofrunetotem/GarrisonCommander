local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- MUST BE LINE 1
local toc=select(4,GetBuildInfo())
local me, ns = ...
local pp=print
if (LibDebug) then LibDebug() end
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local C=LibStub("AlarCrayon-3.0"):GetColorTable()
local addon=LibStub("AlarLoader-3.0")(__FILE__,me,ns):CreateAddon(me,true) --#Addon
local print=ns.print or print
local debug=ns.debug or print
--@debug@
ns.debugEnable('on')
--@end-debug@
-----------------------------------------------------------------
local followerIndexes
local followers
local GMF=GarrisonMissionFrame
local GMFFollowers=GarrisonMissionFrameFollowers
local GMFMissions=GarrisonMissionFrameMissions
local GMFTab1=GarrisonMissionFrameTab1
local GMFTab2=GarrisonMissionFrameTab2
function addon:dump(...)
	print("dump",...)
end
function addon:AddLine(icon,name,status,r,g,b,...)
	local r2,g2,b2=C.Green()
	if (status) then
		r2,g2,b2=C.Red()
	end
	--GameTooltip:AddDoubleLine(name, status or AVAILABLE,r,g,b,r2,g2,b2)
	--GameTooltip:AddTexture(icon)
	GameTooltip:AddDoubleLine("|T" .. tostring(icon) .. ":0|t  " .. name, status or AVAILABLE,r,g,b,r2,g2,b2)
end
function addon:TooltipAdder(missionID)
--@debug@
	GameTooltip:AddLine("ID:" .. tostring(missionID))
--@end-debug@
	local _,_,_,perc=C_Garrison.GetPartyMissionInfo(missionID)
	local difficulty='impossible'
	if (perc > 99) then
			difficulty='trivial'
	elseif(perc >64) then
			difficulty='standard'
	elseif (perc >49) then
			difficulty='difficult'
	elseif(perc>34) then
			difficulty='verydifficult'
	end
	local q=QuestDifficultyColors[difficulty]
	GameTooltip:AddLine(format(GARRISON_MISSION_PERCENT_CHANCE,perc),q.r,q.g,q.b)
	GameTooltip:AddLine(GARRISON_FOLLOWER_CAN_COUNTER)
	local buffed=self:NewTable()
	local traited=self:NewTable()
	for id,d in pairs(C_Garrison.GetBuffedFollowersForMission(missionID)) do
		buffed[id]=d
	end
	for id,d in pairs(C_Garrison.GetFollowersTraitsForMission(missionID)) do
		traited[id]=d
	end
	local followerList=GarrisonMissionFrameFollowers.followersList
	for j=1,#followerList do
		local index=followerList[j]
		local follower=followers[index]
		if (not follower.garrFollowerID) then return end
		local b=buffed[follower.followerID]
		if (b) then
			for _,ability in pairs(b) do
				self:AddLine(ability.icon,follower.name,follower.status,C.Azure())
			end
		end
		local t=traited[follower.followerID]
		if (t) then
			for _,ability in pairs(t) do
				self:AddLine(ability.icon,follower.name,follower.status,C.Orange())
			end
		end
	end
	self:DelTable(buffed)
end
function addon:FillFollowersList()
	if (GarrisonFollowerList_UpdateFollowers) then
		GarrisonFollowerList_UpdateFollowers(GarrisonMissionFrame.FollowerList)
	end
end
function addon:CacheFollowers()
	followers=C_Garrison.GetFollowers()
end

function addon:OnInitialized()
	self:FillFollowersList()
	self:CacheFollowers()
	self:loadHelp()
end
function addon:OnDisabled()
	self:UnhookAll()
end
local hooks={
	"GarrisonMissionList_Update",
	"GarrisonMissionButton_OnEnter",
	"GarrisonFollowerList_OnShow",
}
function addon:GarrisonMissionListTab_OnClick(frame, button)
	if (frame:GetID()==1) then
		self:CacheFollowers()
	end
	self.hooks[frame].OnClick(frame)
end
function addon:OnEnabled()
	for _,f in pairs(hooks) do
		self[f]=function(...) debug(f,...) end
		self:SecureHook(f,f)
	end
	self:SecureHook("GarrisonMissionButton_AddThreatsToTooltip","TooltipAdder")
	self:SecureHook("GarrisonFollowerList_UpdateFollowers","CacheFollowers")
	self:HookScript(GMFTab1,"OnClick","GarrisonMissionListTab_OnClick")
	self:HookScript(GMFTab2,"OnClick","GarrisonMissionListTab_OnClick")
	GMF:SetMovable(true)
	GMF:RegisterForDrag("LeftButton")
	GMF:SetScript("OnDragStart",function(self) self:StartMoving() end)
	GMF:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
end
--@do-not-package@
if (false) then
	local ga=GarrisonMissionFrame
	local gmm=GarrisonMissionFrameMissionsListScrollFrame
	local gmf=GarrisonMissionFrameFollowersListScrollFrame
	local gf=GarrisonMissionFrameFollowers
	local gm=GarrisonMissionFrameMissions
	local gfol=GarrisonMissionFrame.FollowerTab

	if (not ga:IsMovable()) then

		print(ga:GetWidth())
	end
	gm:ClearAllPoints()
	gm:SetPoint("TOPRIGHT",ga,"TOPRIGHT",-30,-60)
	gm:SetPoint("BOTTOMRIGHT",ga,"BOTTOMRIGHT",0,30)
	gf:SetPoint("TOPLEFT",ga,"TOPLEFT",30,-60)
	gf:SetPoint("BOTTOMLEFT",ga,"BOTTOMLEFT",0,60)
	ga:SetHeight(800)

	print(gm:GetName())
	for i=1,gm:GetNumPoints() do
		local a,f,r,x,y=gm:GetPoint(i)
		print(a,f:GetName(),r,x,y)
	end
	print(gm:IsShown(),gm:GetWidth())
	function GACTab(self)
		print("Selected")
		PlaySound("UI_Garrison_Nav_Tabs");
		local id=self:GetID()
		GarrisonMissionFrame_SelectTab(id);
		if (id == 1)  then
				ga:SetWidth(1600)
				gm:SetWidth(890+1600-1250)
				gf:Show()
		else
				ga:SetWidth(930)
		end
	end
	function GACClick(self,button)
		print(self:GetName(),self:GetID(),button)
		if ( IsModifiedClick("CHATLINK") ) then
				local missionLink = C_Garrison.GetMissionLink(self.info.missionID);
				if (missionLink) then
					ChatEdit_InsertLink(missionLink);
				end
				return;
		end
		if (self.info.inProgress) then
				return;
		end
		GarrisonMissionList_Update();
		PlaySound("UI_Garrison_CommandTable_SelectMission");
		GarrisonMissionFrame.MissionTab.MissionList:Hide();
		GarrisonMissionFrame.MissionTab.MissionPage:Show();
		GarrisonMissionPage_ShowMission(self.info);
		GarrisonMissionFrame.followerCounters = C_Garrison.GetBuffedFollowersForMission(self.info.missionID)
		GarrisonMissionFrame.followerTraits = C_Garrison.GetFollowersTraitsForMission(self.info.missionID);
		GarrisonFollowerList_UpdateFollowers(GarrisonMissionFrame.FollowerList);

	end
	for i=1,8 do
		local gname="GarrisonMissionFrameMissionsListScrollFrameButton"..i
		local gbutton=_G[gname]
		gbutton:SetScript("OnClick",GACClick)
		gbutton:SetWidth(1200)
		gbutton:SetHeight(80)
		print(gbutton:GetHeight())
			local f1=CreateFrame("Frame",gname..'Follower2',gbutton,"GarrisonMissionPageFollowerTemplate")
			f1:ClearAllPoints()
			f1:SetPoint("TOPLEFT",gbutton,"TOPLEFT",500,-10)
		gbutton.follower1=f1
		local f2=CreateFrame("Frame",gname..'Follower2',gbutton,"GarrisonMissionPageFollowerTemplate")
		gbutton.follower2=f2
		f2:SetPoint("TOPLEFT",f1,"TOPRIGHT",10,0)
		local f3=CreateFrame("Frame",gname..'Follower2',gbutton,"GarrisonMissionPageFollowerTemplate")
		gbutton.follower3=f3
		f3:SetPoint("TOPLEFT",f2,"TOPRIGHT",10,0)
	end
end
--@end-do-not-package@