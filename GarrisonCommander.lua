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
local dump=ns.dump or print
--@debug@
ns.debugEnable('on')
--@end-debug@
-----------------------------------------------------------------
local followerIndexes
local followers
local compactTooltip=true
local GMF
local GMFFollowers
local GMFMissions
local GMFTab1
local GMFTab2
local GMFMissionsTab1
local GMFMissionsTab2
local GARRISON_FOLLOWER_WORKING=GARRISON_FOLLOWER_WORKING
local GARRISON_FOLLOWER_ON_MISSION=GARRISON_FOLLOWER_ON_MISSION
local AVAILABLE=AVAILABLE
local timers={}
function addon:AddLine(icon,name,status,r,g,b,...)
	local r2,g2,b2=C.Red()
	if (status==AVAILABLE) then
		r2,g2,b2=C.Green()
	elseif (status==GARRISON_FOLLOWER_WORKING) then
		r2,g2,b2=C.Orange()
	end
	--GameTooltip:AddDoubleLine(name, status or AVAILABLE,r,g,b,r2,g2,b2)
	--GameTooltip:AddTexture(icon)
	GameTooltip:AddDoubleLine(icon and "|T" .. tostring(icon) .. ":0|t  " .. name or name, status,r,g,b,r2,g2,b2)
end
function addon:GetDifficultyColor(perc)
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
	return QuestDifficultyColors[difficulty]
end
function addon:TooltipAdder(missionID)
--@debug@
	GameTooltip:AddLine("ID:" .. tostring(missionID))
--@end-debug@
	local perc=select(4,C_Garrison.GetPartyMissionInfo(missionID))
	local q=self:GetDifficultyColor(perc)
	GameTooltip:AddLine(format(GARRISON_MISSION_PERCENT_CHANCE,perc),q.r,q.g,q.b)
	local buffed=self:NewTable()
	local traited=self:NewTable()
	local buffs=self:NewTable()
	local traits=self:NewTable()
	for id,d in pairs(C_Garrison.GetBuffedFollowersForMission(missionID)) do
		buffed[id]=d
	end
	for id,d in pairs(C_Garrison.GetFollowersTraitsForMission(missionID)) do
		for x,y in pairs(d) do
			if (y.traitID~=236) then --Ignore hearthstone traits
				traited[id]=d
				break
			end
		end
	end
	local followerList=GarrisonMissionFrameFollowers.followersList
	for j=1,#followerList do
		local index=followerList[j]
		local follower=followers[index]
		if (not follower.isCollected) then break end
		if (follower.status and self:GetBoolean('IGM')) then
		else
			local id=follower.followerID
			local b=buffed[id]
			local t=traited[id]
			local followerBias = C_Garrison.GetFollowerBiasForMission(missionID,id);
			local formato=C("%3d","White")
			if (followerBias==-1) then
				formato=C("%3d","Red")
			elseif (followerBias < 0) then
				formato=C("%3d","Orange")
			end
			formato=formato.." %s"
--@debug@
			formato=formato .. " 0x+(0*8)  " .. id:sub(11)
--@end-debug
			if (b) then
				if (not buffs[id]) then
					buffs[id]={name=format(formato,follower.level,follower.name),status=(follower.status or AVAILABLE)}
				end
				for _,ability in pairs(b) do
					buffs[id].name=buffs[id].name .. " |T" .. tostring(ability.icon) .. ":0|t"
				end
			end
			if (t) then
				if (not traits[id]) then
					traits[id]={name=format(formato,follower.level,follower.name),status=follower.status or AVAILABLE}
				end
				for _,ability in pairs(t) do
					traits[id].name=traits[id].name .. " |T" .. tostring(ability.icon) .. ":0|t"
				end
			end
		end
	end
--@debug@
-- Working on calculating max possible success percent
	debug("Tooltip generation")
	_G.MISSION=select(8,C_Garrison.GetMissionInfo(missionID))
	_G.TRAITS=traited
	_G.BUFFS=buffed
--@end-debug@
	if (next(traits) or next(buffs) ) then
		GameTooltip:AddLine(GARRISON_FOLLOWER_CAN_COUNTER)
		for id,v in pairs(traits) do
			local status=(v.status == GARRISON_FOLLOWER_ON_MISSION and (timers[id] or GARRISON_FOLLOWER_ON_MISSION)) or v.status
			self:AddLine(nil,v.name,status,C.Silver())
		end
		for id,v in pairs(buffs) do
			local status=(v.status == GARRISON_FOLLOWER_ON_MISSION and (timers[id] or GARRISON_FOLLOWER_ON_MISSION)) or v.status
			self:AddLine(nil,v.name,status,C.Azure())
		end
	end
	self:DelTable(buffed)
	self:DelTable(traited)
	self:DelTable(buffs)
	self:DelTable(traits)
end
function addon:FillFollowersList()
	if (GarrisonFollowerList_UpdateFollowers) then
		GarrisonFollowerList_UpdateFollowers(GarrisonMissionFrame.FollowerList)
	end
end
function addon:CacheFollowers()
	followers=C_Garrison.GetFollowers()
	self:GetRunningMissionData()
end
function addon:GetRunningMissionData()
	local list=GarrisonMissionFrame.MissionTab.MissionList
	C_Garrison.GetInProgressMissions(list.inProgressMissions);
	--C_Garrison.GetAvailableMissions(list.availableMissions);
	wipe(timers)
	if (#list.inProgressMissions > 0) then
		for i,mission in pairs(list.inProgressMissions) do
			for _,id in pairs(mission.followers) do
				timers[id]=mission.timeLeft
			end
		end
	end
end
function addon:ADDON_LOADED(event,addon)
	if (addon=="Blizzard_GarrisonUI") then
		self:UnregisterEvent("ADDON_LOADED")
		self:Init()
	end
end

function addon:ApplyLMF(value)
	print("LMF",value)
	if (not GMF) then return end
	if (value) then
		GMF:SetScript("OnDragStart",nil)
		GMF:SetScript("OnDragStop",nil)
		GMF:ClearAllPoints()
		GMF:SetPoint("CENTER",UIParent)
		GMF:SetMovable(false)
	else
		GMF:SetMovable(true)
		GMF:ClearAllPoints()
		if (self.db.global.a1) then
			GMF:SetPoint(self.db.global.a1,db.global.ref or UIParent,self.db.global.a2,self.db.global.x,self.db.global.y)
		end
		GMF:SetClampedToScreen(true)
		GMF:RegisterForDrag("LeftButton")
		GMF:SetScript("OnDragStart",function(frame) frame:StartMoving() end)
		GMF:SetScript("OnDragStop",function(frame)
			frame:StopMovingOrSizing()
			self.db.global.a1,db.global.ref,self.db.global.a2,self.db.global.x,self.db.global.y=self:GetPoint(1)
		end)
	end
end
function addon:OnInitialized()
	self.OptionsTable.args.on=nil
	self.OptionsTable.args.off=nil
	self.OptionsTable.args.standby=nil
	self:RegisterEvent("ADDON_LOADED")
	self:AddToggle("LMF",false,L["Lock Garrison Mission Panel"]).width="full"
	self:AddToggle("IGM",false,L["Ignore followers On mission"]).width="full"
	self:loadHelp()
	return true
end
local hooks={
	"GarrisonMissionList_Update",
	"GarrisonMissionButton_OnEnter",
	"GarrisonFollowerList_OnShow",
}
function addon:ScriptTrace(hook,frame,...)
	print("Triggered script on",frame:GetName(),...)
	return self.hooks[frame][hook](frame)
end
function addon:postHookScript(frame,hook,method)
	if (method) then
		self:HookScript(frame,hook,
		function(frame,...)
			local t={self.hooks[frame][hook](frame,...)}
			self[method](self,frame,...)
			return unpack(t)
		end)
	else
		return self:HookScript(frame,hook,function(...) addon:ScriptTrace(hook,...) end)
	end
end
function addon:preHookScript(frame,hook,method)
	if (method) then
		self:HookScript(frame,hook,
		function(frame,...)
			self[method](self,frame,...)
			return self.hooks[frame][hook](frame,...)
		end)
	else
		return self:HookScript(frame,hook,function(...) addon:ScriptTrace(hook,...) end)
	end
end
function addon:Init()
	GMF=GarrisonMissionFrame
	GMFFollowers=GarrisonMissionFrameFollowers
	GMFMissions=GarrisonMissionFrameMissions
	GMFTab1=GarrisonMissionFrameTab1
	GMFTab2=GarrisonMissionFrameTab2
	GMFMissionsTab1=GarrisonMissionFrameMissionsTab1
	GMFMissionsTab2=GarrisonMissionFrameMissionsTab2
	self:FillFollowersList()
	self:CacheFollowers()
	for _,f in pairs(hooks) do
		self[f]=function(...) debug(f,...) end
		self:SecureHook(f,f)
	end
	self:SecureHook("GarrisonMissionButton_AddThreatsToTooltip","TooltipAdder")
	self:SecureHook("GarrisonFollowerList_UpdateFollowers","CacheFollowers")
	self:HookScript(GMFTab1,"OnClick","GarrisonMissionListTab_OnClick")
	self:HookScript(GMFTab2,"OnClick","GarrisonMissionListTab_OnClick")
	self:preHookScript(GMFMissions,"OnShow")
	self:preHookScript(GMFMissionsTab1,"OnClick")
	self:preHookScript(GMFMissionsTab2,"OnClick")
	if (not self:GetBoolean("LMF")) then
		self:ApplyLMF(false)
	end
	compactTooltip=self:GetBoolean("CT")
end

function addon:GarrisonMissionListTab_OnClick(frame, button)
	local id=frame:GetID()
	if (id==1) then
		self:CacheFollowers()
	end
	self.hooks[frame].OnClick(frame)
	GarrisonMissionFrame_SelectTab(id);
	if (true) then return end
	if (id == 1)  then
			GMF:SetWidth(1600)
			GMFMissions:SetWidth(890+1600-1250)
			GMFFollowers:Show()
			GMFMissions:ClearAllPoints()
			GMFMissions:SetPoint("TOPLEFT",GMF,"TOPLEFT",GMFFollowers:GetWidth()+35,-65)
	else
			GMF:SetWidth(930)
	end
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
--[[
Garrison page structure
Tab selection:
Managed by
GarrisonMissionFrameTab(1|2) onclick:
->GarrisonMissionFrameTab_OnClick(self)
--->GarrisonMissionFrame_SelectTab(self:GetID()) - 1 for Missions, 2 for followers

Main Container is GarrisonMissionFrame
Followers tab selected:
->GarrisonMissionFrameFollowers -> anchored GarrisonMissionFrame TOPLEFT 33,-64
-->GarrisonMissionFrameFollowersListScrollFrame
--->GarrisonMissionFrameFollowersListScrooFrameScrollChild
---->GarrisonMissionFrameFollowersListScrooFrameButton(1..9)
->GarrisonMissionFrame.FollowerTab -> abcuored GarrisonMissionFrame TOPRIGHT -35 -64
Missions tab selected
->GarrisonMissionFrameMissions -> anchored (parent)e TOPLEFT 35,-65




--]]
