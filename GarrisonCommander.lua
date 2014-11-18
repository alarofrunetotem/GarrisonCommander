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
function addon:dump(...)
	print("dump",...)
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
	for id,d in pairs(C_Garrison.GetBuffedFollowersForMission(missionID)) do
		buffed[id]=true
	end
	local followerList=GarrisonMissionFrameFollowers.followersList
	for j=1,#followerList do
		local index=followerList[j]
		local follower=followers[index]
		if (not follower.garrFollowerID) then return end
		local b=buffed[follower.followerID]
		if (b) then
			if (follower.status) then
				GameTooltip:AddDoubleLine(follower.name, follower.status or AVAILABLE,1,1,0,1,0,0)
			else
				GameTooltip:AddDoubleLine(follower.name, follower.status or AVAILABLE,1,1,0,0,1,0)
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
end
function addon:OnDisabled()
	self:UnhookAll()
end
local hooks={
	"GarrisonMissionList_Update",
	"GarrisonMissionButton_OnEnter",
	"GarrisonFollowerList_OnShow",
}
function addon:OnEnabled()

	for _,f in pairs(hooks) do
		self[f]=function(...) debug(f,...) end
		self:SecureHook(f,f)
	end
	self:SecureHook("GarrisonMissionButton_AddThreatsToTooltip","TooltipAdder")
	self:SecureHook("GarrisonFollowerList_UpdateFollowers","CacheFollowers")
end
