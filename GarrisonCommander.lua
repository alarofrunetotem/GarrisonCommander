local me, ns = ...
local _G=_G
--@debug@
	LoadAddOn("Blizzard_DebugTools")
--@end-debug@
local addon=LibStub("LibInit"):NewAddon(me,'AceHook-3.0','AceTimer-3.0','AceEvent-3.0','AceBucket-3.0') --#Addon
local AceGUI=LibStub("AceGUI-3.0")
local D=LibStub("LibDeformat-3.0")
local C=addon:GetColorTable()
local L=addon:GetLocale()
local print=addon:Wrap("Print")
local trace=addon:Wrap("Trace")
local xprint=function() end
local xdump=function() end
local xtrace=function() end
--@debug@
xprint=function(...) print("DBG",...) end
xdump=function(d,t) print(t) DevTools_Dump(d) end
xtrace=trace
--@end-debug@
local pairs=pairs
local select=select
local next=next
local tinsert=tinsert
local tremove=tremove
local setmetatable=setmetatable
local getmetatable=getmetatable
local type=type
local GetAddOnMetadata=GetAddOnMetadata
local CreateFrame=CreateFrame
local wipe=wipe
local format=format
local tostring=tostring
local collectgarbage=collectgarbage
local bigscreen=true
local GMM=false
local MP=false
local MPGoodGuy=false
local ttcalled=false
local rendercalled=false
local MPPage
local dbg=false

--@debug@
if (LibDebug) then LibDebug() end
local function tcopy(obj, seen)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do res[tcopy(k, s)] = tcopy(v, s) end
	return res
end
--@end-debug@
-----------------------------------------------------------------
-- Recycling function from ACE3
----newcount, delcount,createdcount,cached = 0,0,0


local new, del, copy
do
	local pool = setmetatable({},{__mode="k"})
	function new()
		--newcount = newcount + 1
		local t = next(pool)
		if t then
			pool[t] = nil
			return t
		else
			--createdcount = createdcount + 1
			return {}
		end
	end
	function copy(t)
		local c = new()
		for k, v in pairs(t) do
			c[k] = v
		end
		return c
	end
	function del(t)
		--delcount = delcount + 1
		wipe(t)
		pool[t] = true
	end
--	function cached()
--		local n = 0
--		for k in pairs(pool) do
--			n = n + 1
--		end
--		return n
--	end
end
local function capitalize(s)
	s=tostring(s)
	return strupper(s:sub(1,1))..strlower(s:sub(2))
end
--- upvalues
--
local AVAILABLE=AVAILABLE -- "Available"
local BUTTON_INFO=GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS.. " " .. GARRISON_MISSION_PERCENT_CHANCE
local ENVIRONMENT_SUBHEADER=ENVIRONMENT_SUBHEADER -- "Environment"
local G=C_Garrison
--local GARRISON_BUILDING_SELECT_FOLLOWER_TITLE=GARRISON_BUILDING_SELECT_FOLLOWER_TITLE -- "Select a Follower";
--local GARRISON_BUILDING_SELECT_FOLLOWER_TOOLTIP=GARRISON_BUILDING_SELECT_FOLLOWER_TOOLTIP -- "Click here to assign a Follower";
--local GARRISON_FOLLOWERS=GARRISON_FOLLOWERS -- "Followers"
--local GARRISON_FOLLOWER_CAN_COUNTER=GARRISON_FOLLOWER_CAN_COUNTER -- "This follower can counter:"
--local GARRISON_FOLLOWER_EXHAUSTED=GARRISON_FOLLOWER_EXHAUSTED -- "Recovering (1 Day)"
--local GARRISON_FOLLOWER_INACTIVE=GARRISON_FOLLOWER_INACTIVE --"Inactive"
--local GARRISON_FOLLOWER_IN_PARTY=GARRISON_FOLLOWER_IN_PARTY
--local GARRISON_FOLLOWER_ON_MISSION=GARRISON_FOLLOWER_ON_MISSION -- "On Mission"
--local GARRISON_FOLLOWER_WORKING=GARRISON_FOLLOWER_WORKING -- "Working
local GARRISON_MISSION_PERCENT_CHANCE="%d%%"-- GARRISON_MISSION_PERCENT_CHANCE
local GARRISON_MISSION_SUCCESS=GARRISON_MISSION_SUCCESS -- "Success"
local GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS=GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS -- "%d Follower mission";
local GARRISON_PARTY_NOT_FULL_TOOLTIP=GARRISON_PARTY_NOT_FULL_TOOLTIP -- "You do not have enough followers on this mission."
local GARRISON_MISSION_CHANCE=GARRISON_MISSION_CHANCE -- Chanche
local GARRISON_FOLLOWER_BUSY_COLOR=GARRISON_FOLLOWER_BUSY_COLOR
local GARRISON_FOLLOWER_INACTIVE_COLOR=GARRISON_FOLLOWER_INACTIVE_COLOR
local GARRISON_CURRENCY=GARRISON_CURRENCY  --824
local GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY=GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY -- 4
local GARRISON_FOLLOWER_MAX_LEVEL=GARRISON_FOLLOWER_MAX_LEVEL -- 100

local LEVEL=LEVEL -- Level
local NOT_COLLECTED=NOT_COLLECTED -- not collected
local GMF=GarrisonMissionFrame
local GMFFollowerPage=GMF.FollowerTab
local GMFFollowers=GarrisonMissionFrameFollowers
local GMFMissionPage=GMF.MissionTab.MissionPage
local GMFMissionPageFollowers = GMFMissionPage.Followers
local GMFMissions=GarrisonMissionFrameMissions
local GMFMissionsTab1=GarrisonMissionFrameMissionsTab1
local GMFMissionsTab2=GarrisonMissionFrameMissionsTab2
local GMFMissionsTab3=GarrisonMissionFrameMissionsTab2
local GMFRewardPage=GMF.MissionComplete
local GMFRewardSplash=GMFMissions.CompleteDialog
local GMFMissionsListScrollFrameScrollChild=GarrisonMissionFrameMissionsListScrollFrameScrollChild
local GMFMissionsListScrollFrame=GarrisonMissionFrameMissionsListScrollFrame
local GMFFollowersListScrollFrameScrollChild=GarrisonMissionFrameFollowersListScrollFrameScrollChild
local GMFFollowersListScrollFrame=GarrisonMissionFrameFollowersListScrollFrame
local GMFMissionListButtons=GMF.MissionTab.MissionList.listScroll.buttons
local GMFTab1=GarrisonMissionFrameTab1
local GMFTab2=GarrisonMissionFrameTab2
local GMFTab3=_G.GarrisonMissionFrameTab3
local GarrisonFollowerTooltip=GarrisonFollowerTooltip
local GarrisonMissionFrameMissionsListScrollFrame=GarrisonMissionFrameMissionsListScrollFrame
local IGNORE_UNAIVALABLE_FOLLOWERS=IGNORE.. ' ' .. UNAVAILABLE
local IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL=IGNORE.. ' ' .. GARRISON_FOLLOWER_INACTIVE .. ',' .. GARRISON_FOLLOWER_ON_MISSION ..',' .. GARRISON_FOLLOWER_WORKING.. ' ' .. GARRISON_FOLLOWERS
local PARTY=PARTY -- "Party"
local SPELL_TARGET_TYPE1_DESC=capitalize(SPELL_TARGET_TYPE1_DESC) -- any
local SPELL_TARGET_TYPE4_DESC=capitalize(SPELL_TARGET_TYPE4_DESC) -- party member
local ANYONE='('..SPELL_TARGET_TYPE1_DESC..')'
local UNKNOWN_CHANCE=GARRISON_MISSION_PERCENT_CHANCE:gsub('%%d%%%%',UNKNOWN)
IGNORE_UNAIVALABLE_FOLLOWERS=capitalize(IGNORE_UNAIVALABLE_FOLLOWERS)
IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL=capitalize(IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL)
local UNKNOWN=UNKNOWN -- Unknown
local TYPE=TYPE -- Type
local ALL=ALL -- All
local MAXMISSIONS=8
local MINPERC=20
local BUSY_MESSAGE_FORMAT=L["Only first %1$d missions with over %2$d%% chance of success are shown"]
local BUSY_MESSAGE=format(BUSY_MESSAGE_FORMAT,MAXMISSIONS,MINPERC)

local function splitFormat(base)
	local i,s=base:find("|4.*:.*;")
	if (not i) then
		return base,base
	end
	local m0,m1=base:match("|4(.*):(.*);")
	local G=base
	local G1=G:sub(1,i-1)..m0..G:sub(s+1)
	local G2=G:sub(1,i-1)..m1..G:sub(s+1)
	return G1,G2
end

local GARRISON_DURATION_DAY,GARRISON_DURATION_DAYS=splitFormat(GARRISON_DURATION_DAYS) -- "%d |4day:days;";
local GARRISON_DURATION_DAY_HOURS,GARRISON_DURATION_DAYS_HOURS=splitFormat(GARRISON_DURATION_DAYS_HOURS) -- "%d |4day:days; %d hr";
local GARRISON_DURATION_HOURS=GARRISON_DURATION_HOURS -- "%d hr";
local GARRISON_DURATION_HOURS_MINUTES=GARRISON_DURATION_HOURS_MINUTES -- "%d hr %d min";
local GARRISON_DURATION_MINUTES=GARRISON_DURATION_MINUTES -- "%d min";
local GARRISON_DURATION_SECONDS=GARRISON_DURATION_SECONDS -- "%d sec";
local AGE_HOURS="Expires in " .. GARRISON_DURATION_HOURS_MINUTES
local AGE_DAYS="Expires in " .. GARRISON_DURATION_DAYS_HOURS


-- Panel sizes
local BIGSIZEW=1220
local BIGSIZEH=662
local SIZEW=950
local SIZEH=662
local SIZEV
local GCSIZE=700
local FLSIZE=400
local BIGBUTTON=BIGSIZEW-GCSIZE
local SMALLBUTTON=BIGSIZEW-GCSIZE
local GCF
local GMC
local GMCUsedFollowers={}
local GCFMissions
local GCFBusyStatus
local GameTooltip=GameTooltip
-- Want to know what I call!!
--local GarrisonMissionButton_OnEnter=GarrisonMissionButton_OnEnter
local GarrisonFollowerList_UpdateFollowers=GarrisonFollowerList_UpdateFollowers
local GarrisonMissionList_UpdateMissions=GarrisonMissionList_UpdateMissions
local GarrisonMissionPage_ClearFollower=GarrisonMissionPage_ClearFollower
local GarrisonMissionPage_UpdateMissionForParty=GarrisonMissionPage_UpdateMissionForParty
local GarrisonMissionPage_SetFollower=GarrisonMissionPage_SetFollower
local GarrisonMissionButton_SetRewards=GarrisonMissionButton_SetRewards
local GetItemInfo=GetItemInfo
local type=type
local ITEM_QUALITY_COLORS=ITEM_QUALITY_COLORS
function addon:GetDifficultyColors(perc,usePurple)
	local q=self:GetDifficultyColor(perc,usePurple)
	return q.r,q.g,q.b
end
function addon:GetDifficultyColor(perc,usePurple)
	if(perc >90) then
		return QuestDifficultyColors['standard']
	elseif (perc >74) then
		return QuestDifficultyColors['difficult']
	elseif(perc>49) then
		return QuestDifficultyColors['verydifficult']
	elseif(perc >20) then
		return QuestDifficultyColors['impossible']
	else
		return not usePurple and C.Silver or C.Fuchsia
	end
end
if (LibDebug) then LibDebug() end
----- Local variables
--
-- Forces a table to countain other tables,
local t1={
	__index=function(t,k) rawset(t,k,{}) return t[k] end
}
local t2={
	__index=function(t,k) rawset(t,k,setmetatable({},t1)) return t[k] end
}
local followersCache={}
local followersCacheIndex={}
local dirty=false
local cache
local dbcache
local db
local n=setmetatable({},{
	__index = function(t,k)
		local name=addon:GetFollowerData(k,'fullname')
		if (name) then rawset(t,k,name) return name else return k end
	end
})

-- Counter system
local function cleanicon(stringa)
	return (stringa:lower():gsub("%.blp$",""))
end
local counters=setmetatable({},t2)
local counterThreatIndex=setmetatable({},t2)
local counterFollowerIndex=setmetatable({},t2)
local function genIteratorByFollower(missionID,followerID,tbl)
	do
		local tt=counters[missionID]
		local tx=counterFollowerIndex[missionID][followerID]
		setmetatable(tbl,{
			__index=function(t,k) return tt[tx[k]] end,
			__call=function(t) return #tx end
			}
		)
		return tbl
	end
end
local function genIteratorByThreat(missionID,threat,tbl)
	do
		local tt=counters[missionID]
		local tx=counterThreatIndex[missionID][threat]
		setmetatable(tbl,{
			__index=function(t,k) return tt[tx[k]] end,
			__call=function(t)  return #tx end
			}
		)
		return tbl
	end
end

--- Quick backdrop
--
local function addBackdrop(f)
	local backdrop = {
		bgFile="Interface\\TutorialFrame\\TutorialFrameBackground",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
		tile=true,
		tileSize=16,
		edgeSize=16,
		insets={bottom=7,left=7,right=7,top=7}
	}
	f:SetBackdrop(backdrop)
end

--generic table scan

local function inTable(table, value)
	if (type(table)~='table') then return false end
	if (#table > 0) then
		for i=1,#table do
			if (value==table[i]) then return true end
		end
	else
		for k,v in pairs(table) do
			if v == value then
				return true
			end
		end
	end
	return false
end


--- Parties storage
--
--
local parties=setmetatable({},{
	__index=function(t,k) rawset(t,k,{members={},perc=0,full=false}) return t[k] end
})
local function inParty(missionID,followerID)
	return inTable(parties[missionID].members,followerID)
end
--- Follower Missions Info
--
local followerMissions=setmetatable({},{
	__index=function(t,k) rawset(t,k,{}) return t[k] end
})

--
-- Temporary party management
local openParty,isInParty,pushFollower,removeFollower,closeParty,roomInParty,storeFollowers,dumpParty

do
	local ID,frames,members,maxFollowers=0,{},{},1
	---@function [parent=#party] openParty
	function openParty(missionID,followers)
		if (#frames > 0 or #members > 0) then
			error(format("Unbalanced openParty/closeParty %d %d",#frames,#members))
		end
		maxFollowers=followers
		frames={GetFramesRegisteredForEvent('GARRISON_FOLLOWER_LIST_UPDATE')}
		for i=1,#frames do
			frames[i]:UnregisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
		end
		ID=missionID
	end
	---@function [parent=#party] isInParty
	function isInParty(followerID)
		return inTable(members,followerID)
	end

	---@function [parent=#party] roomInParty
	function roomInParty()
		return maxFollowers-#members
	end

	---@function [parent=#party] dumpParty
	function dumpParty()
		for i=1,3 do
			if (members[i]) then
				xprint(i,addon:GetFollowerData(members[i],'fullname'))
			end
		end
	end

	---@function [parent=#party] pushFollower
	function pushFollower(followerID)
		if (followerID:sub(1,2) ~= '0x') then trace(followerID .. "is not an id") end
		if (roomInParty()>0) then
			local rc,code=pcall (C_Garrison.AddFollowerToMission,ID,followerID)
			if (rc and code) then
				tinsert(members,followerID)
				return true
--@debug@
			else
				xprint("Unable to add", n[followerID],"to",ID,code)
--@end-debug@
			end
		end
	end
	---@function [parent=#party] removeFollowers
	function removeFollower(followerID)
		for i=1,maxFollowers do
			if (followerID==members[i]) then
				tremove(members,i)
				local rc,code=pcall(C_Garrison.RemoveFollowerFromMission,ID,followerID)
--@debug@
				if (not rc) then trace("Unable to remove", n[members[i]],"from",ID,code) end
--@end-debug@
			return true end
		end
	end

	---@function [parent=#party] storeFollowers
	function storeFollowers(table)
		wipe(table)
		for i=1,#members do
			tinsert(table,members[i])
		end
		return #table
	end

	---@function [parent=#party] closeParty
	function closeParty()
		local perc=select(4,G.GetPartyMissionInfo(ID))
		for i=1,3 do
			if (members[i]) then
				local rc,code=pcall(C_Garrison.RemoveFollowerFromMission,ID,members[i])
--@debug@
				if (not rc) then trace("Unable to pop", members[i]," from ",ID,code) end
--@end-debug@

			else
				break
			end
		end
		for i=1,#frames do
			frames[i]:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")

		end
		wipe(frames)
		wipe(members)
		return perc or 0
	end
end
--
--@debug@
local origGarrisonMissionButton_OnEnter = _G.GarrisonMissionButton_OnEnter
function _G.GarrisonMissionButton_OnEnter(this,button)
	origGarrisonMissionButton_OnEnter(this,button)
	--@debug@
	if (this.info.inProgress) then
		GameTooltip:AddDoubleLine("ID:",this.info.missionID)
		GameTooltip:Show()
	end
	--@end-debug@
end
--@end-debug@
-- These local will became conf var
-- locally upvalued, doing my best to not interfere with other sorting modules,
-- First time i am called to verride it I save it, so I give other modules a chance to hook it, too
-- Could even do a trick and secureHook it at the expense of a double sort...
local origGarrison_SortMissions

function addon.Garrison_SortMissions_Chance(missionsList)
	local comparison
	do
		function comparison(mission1, mission2)
			local p1=parties[mission1.missionID]
			local p2=parties[mission2.missionID]
			if (p2.full and not p1.full) then return false end
			if (p1.full and not p2.full) then return true end
			if (p1.perc==p2.perc) then
				return strcmputf8i(mission1.name, mission2.name) < 0
			else
				return p1.perc > p2.perc
			end
		end
	end
	table.sort(missionsList, comparison);
end
function addon.Garrison_SortMissions_Age(missionsList)
	local comparison
	do
		function comparison(mission1, mission2)
			local p1=parties[mission1.missionID]
			local p2=parties[mission2.missionID]
			if (p2.full and not p1.full) then return false end
			if (p1.full and not p2.full) then return true end
			local age1=tonumber(dbcache.seen[mission1.missionID]) or 0
			local age2=tonumber(dbcache.seen[mission2.missionID]) or 0
			if (age1==age2) then
				return strcmputf8i(mission1.name, mission2.name) < 0
			else
				return age1 < age2
			end
		end
	end
	table.sort(missionsList, comparison);
end
function addon.Garrison_SortMissions_Followers(missionsList)
	local comparison
	do
		function comparison(mission1, mission2)
			local p1=mission1.numFollowers
			local p2=mission2.numFollowers
			if (p1==p2) then
				return strcmputf8i(mission1.name, mission2.name) < 0
			else
				return p1 < p2
			end
		end
	end
	table.sort(missionsList, comparison);
end
function addon.Garrison_SortMissions_Xp(missionsList)
	local comparison
	do
		function comparison(mission1, mission2)
			local p1=addon:GetMissionData(mission1.missionID,'globalXp')
			local p2=addon:GetMissionData(mission2.missionID,'globalXp')
			if (p1==p2) then
				return strcmputf8i(mission1.name, mission2.name) < 0
			else
				return p2 < p1
			end
		end
	end
	table.sort(missionsList, comparison);
end

function addon:OnInitialized()
--@debug@
	xprint("OnInitialized")
	self:DebugEvents()
--@end-debug@
	for _,b in ipairs(GMFMissionsListScrollFrame.buttons) do
		local scale=0.8
		local f,h,s=b.Title:GetFont()
		b.Title:SetFont(f,h*scale,s)
		local f,h,s=b.Summary:GetFont()
		b.Summary:SetFont(f,h*scale,s)
	end
	self:CreatePrivateDb()
	db=self.db.global
	self:SafeRegisterEvent("GARRISON_MISSION_STARTED")
	self:SafeRegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE")
	self:SafeRegisterEvent("GARRISON_MISSION_NPC_CLOSED",function(...) GCF:Hide() end)
	self:SafeHookScript("GarrisonMissionFrame","OnShow","SetUp",true)
	self:AddToggle("MOVEPANEL",true,L["Unlock Panel"])
	self:AddToggle("IGM",true,IGNORE_UNAIVALABLE_FOLLOWERS,IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL)
	self:AddToggle("IGP",true,L['Ignore "maxed"'],L["Level 100 epic followers are not used for xp only missions."])
	self:AddToggle("NOFILL",false,L["Do not prefill mission page"],L["Disables automatic population of mission page screen. You can also press control while clicking to disable it for a single mission"])
	self:AddSelect("MSORT","Garrison_SortMissions_Original",
	{
		Garrison_SortMissions_Original=L["Original method"],
		Garrison_SortMissions_Chance=L["Success Chance"],
		Garrison_SortMissions_Followers=L["Number of followers"],
		Garrison_SortMissions_Age=L["Days since first seen"],
		Garrison_SortMissions_Xp=L["Global approx. xp reward"],
	},
	L["Sort missions by:"],L["Original sort restores original sorting method, whatever it was (If you have another addon sorting mission, it should kick in again)"])
	self:AddToggle("BIGSCREEN",true,L["Use big screen"],L["Disabling this will give you the interface from 1.1.8, given or taken. Need to reload interface"])
	bigscreen=self:GetBoolean("BIGSCREEN")
	self:AddSlider("MAXMISSIONS",5,1,8,L["Mission shown for follower"],nil,1)
	self:AddSlider("MINPERC",50,0,100,L["Minimun chance success under which ignore missions"],nil,5)
	self:AddPrivateAction("ShowMissionControl",L["Mission control"],L["You can choose some criteria and have GC autosumbit missions for you"])
--@debug@
	self:AddToggle("DBG",false, "Enable Debug")
--@end-debug@

	self:Trigger("MSORT")
	return true
end
function addon:CheckMP()
	if (IsAddOnLoaded("MasterPlan")) then
		if (GetAddOnMetadata("MasterPlan","Version")=="0.18") then
		-- Last well behavioured version
			MPGoodGuy=true
			return
		end
		MP=true
		self:AddToggle("CKMP",true,L["Use GC Interface"],L["Switches between Garrison Commander and Master Plan mission interface. This also allow you to see Garrison Mission Manager buttons.\n If doesnt work, tell me, and I will try to discover which new way of hiding GC and GMM had MP found....."])
		if (GarrisonMissionFrameTab3) then -- Active Missions
			GarrisonMissionFrameTab3:HookScript("OnClick",function(this)
			GarrisonMissionList_SetTab(GarrisonMissionFrameMissionsTab2)
			MPPage=3
			end)
		end
		if (GarrisonMissionFrameTab1) then --Available Missions
			GarrisonMissionFrameTab1:HookScript("OnClick",function(this)
			GarrisonMissionList_SetTab(GarrisonMissionFrameMissionsTab1)
			MPPage=1
			end)
		end
		if (GarrisonMissionFrameTab2) then -- Followers list
			GarrisonMissionFrameTab2:HookScript("OnClick",function(this)
			GarrisonMissionFrame_SelectTab(2)
			MPPage=2
			end)
		end
	end
end
function addon:CheckGMM()
	if (IsAddOnLoaded("GarrisonMissionManager")) then
		GMM=true
		self:RefreshMission()
	end
end
function addon:ApplyIGM(value)
	self:BuildMissionsCache(false,true)
	self:RefreshMission()
end
function addon:ApplyCKMP(value)
	self:Clock()
	self:RefreshMission()
end
function addon:ApplyDBG(value)
	dbg=value
end
function addon:ApplyBIGSCREEN(value)
		if (value) then
			wipe(dbcache.ignored) -- we no longer have an interface to change this settings
		end
		self:Popup(L["Must reload interface to apply"],0,
			function(this)
				addon:SetBoolean("BIGSCREEN",value)
				ReloadUI()
			end
		)
end
function addon:ApplyIGP(value)
	self:BuildMissionsCache(false,true)
	self:RefreshMission()
end
function addon:ApplyMSORT(value)
	if (not origGarrison_SortMissions) then
		origGarrison_SortMissions=Garrison_SortMissions
	end
	local func=self[value]
	if (type(func)=="function") then
		_G.Garrison_SortMissions=self[value]
	else
		_G.Garrison_SortMissions=origGarrison_SortMissions
	end
	self:RefreshMission()
end
function addon:ApplyMAXMISSIONS(value)
	MAXMISSIONS=value
	BUSY_MESSAGE=format(BUSY_MESSAGE_FORMAT,MAXMISSIONS,MINPERC)
end
function addon:ApplyMINPERC(value)
	MINPERC=value
	BUSY_MESSAGE=format(BUSY_MESSAGE_FORMAT,MAXMISSIONS,MINPERC)
end



function addon:RestoreTooltip()
	local self = GMF.MissionTab.MissionList;
	local scrollFrame = self.listScroll;
	local buttons = scrollFrame.buttons;
	for i =1,#buttons do
		buttons[i]:SetScript("OnEnter",GarrisonMissionButton_OnEnter)
	end
end

--[[
	[12]={
		description="Iron Horde raiders have descended on nearby draenei villages. Find the raiders' camp and raid it. Turnabout, they say, is fair play.",
		cost=15,
		duration="4 hr",
		slots={
			["Minion Swarms"]=1,
			Type=1,
			["Deadly Minions"]=1
		},
		durationSeconds=14400,
		party={
			party2="<empty>",
			party1="<empty>"
		},
		level=100,
		type="Combat",
		counters={
			["0x00000000001BE95D"]={
				[1]={
					counterIcon="Interface\\ICONS\\Ability_Rogue_FanofKnives.blp",
					name="Minion Swarms",
					counterName="Fan of Knives",
					icon="Interface\\ICONS\\Spell_DeathKnight_ArmyOfTheDead.blp",
					description="An enemy with many allies.  Susceptible to area-of-effect damage."
				}
			},
			["0x00000000002D61EB"]={
				[1]={
					counterIcon="Interface\\ICONS\\Spell_Shaman_Hex.blp",
					name="Deadly Minions",
					counterName="Hex",
					icon="Interface\\ICONS\\Achievement_Boss_TwinOrcBrutes.blp",
					description="An enemy with powerful allies that should be neutralized."
				}
			}
		},
		traits={
			["0x00000000001BE95D"]={
				[1]={
					traitID=236,
					icon="Interface\\ICONS\\Item_Hearthstone_Card.blp"
				}
			}
		},
		locPrefix="GarrMissionLocation-Nagrand",
		rewards={
			[795]={
				itemID=120301,
				quantity=1
			}
		},
		numRewards=1,
		numFollowers=2,
		state=-2,
		iLevel=0,
		name="Raiding the Raiders",
		followers={
		},
		location="Nagrand",
		isRare=false,
		typeAtlas="GarrMission_MissionIcon-Combat",
		missionID=380
	}
}
--]]
-- True manda a davani
local function cmp(a,b)

	if (a.mechanic and b.trait) then return true end
	if (a.trait and b.mechanic) then return false end
	if (a.name==a.name) then
		if a.bias==b.bias then
			if (a.rank==b.rank) then
				return a.quality < b.quality
			else
				return a.rank < b.rank
			end
		else
			return a.bias > b.bias
		end
	else
		return a.name < b.name
	end
	--if (a.name~=b.name) then return a.name < b.name end
	--if (a.bias==-1) then return false end
	--if (b.bias==-1) then return true end
	--if (a.bias~=b.bias) then return (a.bias>b.bias) end
	--if (a.rank ~= b.rank) then return (a.rank < b.rank) end
	return a.quality < b.quality
end


function addon:FillCounters(missionID,mission)
	if (not mission) then mission=self:GetMissionData(missionID) end
	local slots=mission.slots
	local missioncounters=counters[missionID]
	wipe(missioncounters)
	local t=G.GetBuffedFollowersForMission(missionID)
	if t then
		for id,d in pairs(t) do
			local rank=self:GetFollowerData(id,'rank')
			local quality=self:GetFollowerData(id,'quality')
			local bias= G.GetFollowerBiasForMission(missionID,id);
			for i,l in pairs(d) do
				-- i is meaningful
				-- l.counterIcon
				-- l.name
				-- l.counterName
				-- l.icon
				-- l.description
				tinsert(missioncounters,{k=cleanicon(l.icon),mechanic=true,name=l.name,followerID=id,bias=bias,rank=rank,quality=quality,icon=l.icon})
				followerMissions[id][missionID]=1+ (tonumber(followerMissions[id][missionID]) or 0)
			end
		end
	end
	t= G.GetFollowersTraitsForMission(missionID)
	if t then
		for id,d in pairs(t) do
			local bias= G.GetFollowerBiasForMission(missionID,id);
			local rank=self:GetFollowerData(id,'rank')
			local quality=self:GetFollowerData(id,'quality')
			for i,l in pairs(d) do
				--l.traitID
				--l.icon
				followerMissions[id][missionID]=1+ (tonumber(followerMissions[id][missionID]) or 0)
				tinsert(missioncounters,{k=cleanicon(l.icon),trait=true,name=l.traitID,followerID=id,bias=bias,rank=rank,quality=quality,icon=l.icon})
			end
		end
		table.sort(missioncounters,cmp)
		local cf=wipe(counterFollowerIndex[missionID])
		local ct=wipe(counterThreatIndex[missionID])
		for i=1,#missioncounters do
			tinsert(cf[missioncounters[i].followerID],i)
			tinsert(ct[missioncounters[i].k],i)
		end
	end
end

--[[
Matchmaker debug for Spell Check
Slots
["Danger Zones"]=1,
Type="Interface\\ICONS\\Achievement_Reputation_Ogre.blp",
["Interface\\ICONS\\Achievement_Reputation_Ogre.blp"]=1,
["Powerful Spell"]=1
[1]={
	name="Danger Zones",
	icon="Interface\\ICONS\\spell_Shaman_Earthquake.blp",
	quality=4,
	bias=-0.66666668653488,
	follower="0x00000000002D57C4",
	rank=96
},
[2]={
	name="Interface\\ICONS\\Achievement_Reputation_Ogre.blp",
	icon="Interface\\ICONS\\Achievement_Reputation_Ogre.blp",
	quality=4,
	bias=0.66666668653488,
	follower="0x00000000001978B6",
	rank=600
},
[3]={
	name="Interface\\ICONS\\Achievement_Reputation_Ogre.blp",
	icon="Interface\\ICONS\\Achievement_Reputation_Ogre.blp",
	quality=4,
	bias=-0.66666668653488,
	follower="0x00000000002D57C4",
	rank=96
},
[4]={
	name="Interface\\ICONS\\Item_Hearthstone_Card.blp",
	icon="Interface\\ICONS\\Item_Hearthstone_Card.blp",
	quality=2,
	bias=0.66666668653488,
	follower="0x00000000001BE95D",
	rank=600
}
Preparying party
Considering  Shelly Hamby for Danger Zones
Considering  Qiana Moonshadow for Interface\ICONS\Achievement_Reputation_Ogre.blp
Considering  Shelly Hamby for Interface\ICONS\Achievement_Reputation_Ogre.blp
Considering  Bruma Swiftstone for Interface\ICONS\Item_Hearthstone_Card.blp
Dopo check per nil
["Danger Zones"]={
},
["Interface\\ICONS\\Achievement_Reputation_Ogre.blp"]={
},
["Interface\\ICONS\\Item_Hearthstone_Card.blp"]={
}
Party filling
Party is not full
Verifying Delvar Ironfist 0 600 3
Verifying Rangari Chel 0 91 3
Party filling
Party is not full
Verifying Rangari Chel 0 91 3
Party filling
Matchmaker end

--]]
--[[
Button fields
LocBG table
HighlightBR table
Highlight table
inProgressFresh boolean
Party table
gcPANEL table
HighlightB table
HighlightTR table
Level table
Expire table
MissionType table
Overlay table
info table
ItemLevel table
id number
HighlightBL table
Rewards table
Threats table
HighlightT table
0 userdata
RareText table
IconBG table
Title table
Projections table
RareOverlay table
Summary table
HighlightTL table
--]]
local function best(fid1,fid2,counters)
	if (not fid1) then return fid2 end
	if (not fid2) then return fid1 end
	local f1,f2=counters[fid1],counters[fid2]
	if (dbg) then
		print("Current",fid1,n[f1.followerID]," vs Candidate",fid2,n[f2.followerID])
	end
	if (isInParty(f1.followerID)) then return fid1 end
	if (f2.bias<0) then return fid1 end
	if (f2.bias>f1.bias) then return fid2 end
	if (f1.bias == f2.bias) then
		if (f2.quality < f1.quality or f2.rank < f1.rank) then return fid2 end
	end
	return fid1
end
function addon:CompleteParty(missionID,mission,skipBusy,skipMaxed)
	local perc=select(4,G.GetPartyMissionInfo(missionID)) -- If percentage is already 100, I'll try and add the most useless character
	local candidateMissions=10000
	local candidateRank=10000
	local candidateQuality=9999
	if (dbg) then
		print("Attemptin to fill party, so far:")
		dumpParty()
	end
	for x=1,roomInParty() do
		local candidate
		local candidatePerc=perc
		local totFollowers=#followersCache
		for i=1,totFollowers do
			local data=followersCache[i]
			local followerID=data.followerID
			if (not self:IsIgnored(followerID,missionID) and not(skipMaxed and data.maxed) and not isInParty(followerID) and self:GetFollowerStatusForMission(followerID,skipBusy)) then
				local missions=#followerMissions[followerID]
				local rank=data.rank
				local quality=data.quality
				repeat
					if (perc<100) then
						pushFollower(followerID)
						local newperc=select(4,G.GetPartyMissionInfo(missionID))
						removeFollower(followerID)
						if (newperc > candidatePerc) then
							candidatePerc=newperc
							candidate=followerID
							candidateMissions=missions
							candidateRank=rank
							candidateQuality=quality
							break -- continue
						elseif (newperc < candidatePerc) then
							break --continue
						end
					end
					-- This candidate is not improving success chance, minimize
					if (i < totFollowers  and data.maxed) then
						break  -- Pointless using a maxed follower if we  have more follower to try
					end
					if (missions<candidateMissions) then
						candidate=followerID
						candidateMissions=missions
						candidateRank=rank
						candidateQuality=quality
					elseif(missions==candidateMissions and rank<candidateRank) then
						candidate=followerID
						candidateMissions=missions
						candidateRank=rank
						candidateQuality=quality
					elseif(missions==candidateMissions and rank==candidateRank and quality<candidateQuality) then
						candidate=followerID
						candidateMissions=missions
						candidateRank=rank
						candidateQuality=quality
					elseif (not candidate) then
						candidate=followerID
						candidateMissions=missions
						candidateRank=rank
						candidateQuality=quality
					end
				until true -- A poor man continue implementation using break
			end
		end
		if (candidate) then
			pushFollower(candidate)
			if (dbg) then
				print("Added member to party")
				dumpParty()
			end
			perc=select(4,G.GetPartyMissionInfo(missionID))
		end
	end
end
function addon:MatchMaker(missionID,mission,party)
	if (GMFRewardSplash:IsShown()) then return end
	if (not mission) then mission=self:GetMissionData(missionID) end
	if (not party) then party=parties[missionID] end
	local skipBusy=self:GetBoolean("IGM")
	local skipMaxed=self:GetBoolean("IGP")
	dbg=dbg or missionID==(tonumber(_G.MW) or 0)
	local slots=mission.slots
	local missionCounters=counters[missionID]
	local ct=counterThreatIndex[missionID]
	local maxedSkipped=new()
	local ignoredSkipped=new()
	openParty(missionID,mission.numFollowers)
	if (type(slots)=='table') then
		for i=1,#slots do
			local threat=cleanicon(slots[i].icon)
			local candidates=ct[threat]
			local choosen
			for i=1,#candidates do
				local followerID=missionCounters[candidates[i]].followerID
				if followerID then
					if(not addon:GetFollowerStatusForMission(followerID,skipBusy)) then
						if (dbg) then print("Skipped",n[followerID],"due to skipbusy" ) end
					elseif (self:IsIgnored(followerID,missionID)) then
						tinsert(ignoredSkipped,followerID)
						if (dbg) then print("Skipped",n[followerID],"due to ignored" ) end
					elseif (skipMaxed and mission.xpOnly and self:GetFollowerData(followerID,'maxed')) then
						tinsert(maxedSkipped,followerID)
						if (dbg) then print("Skipped",n[followerID],"due to maxed" ) end
					else
						choosen=best(choosen,candidates[i],missionCounters)
						if (dbg) then print("Taken",n[missionCounters[choosen].followerID]) end
					end
				end
			end
			if (choosen) then
				if (type(missionCounters[choosen]) ~="table") then
					trace(format("%s %s %d %d",mission.name,threat,missionID,tonumber(choosen) or 0))
				end
				pushFollower(missionCounters[choosen].followerID)
			end
			if (roomInParty()==0) then
				break
			end
		end
	else
		xprint("Mission",missionID,"has no slots????")
	end
	self:CompleteParty(missionID,mission,skipBusy,skipMaxed)
	if (roomInParty()>0) then
		--We try to use maxed, then ignored followers
		for i=1,#maxedSkipped do
			pushFollower(maxedSkipped[i])
			if (roomInParty()==0) then
				break
			end
		end
		for i=1,#ignoredSkipped do
			pushFollower(ignoredSkipped[i])
			if (roomInParty()==0) then
				break
			end
		end
	end
	storeFollowers(party.members)
	party.full= roomInParty()==0
	party.perc=closeParty()
end
function addon:IsIgnored(followerID,missionID)
	if (dbcache.ignored[missionID][followerID]) then return true end
	if (dbcache.totallyignored[followerID]) then return true end
end
function addon:GetAllCounters(missionID,threat,table)
	wipe(table)
	local iter=genIteratorByThreat(missionID,cleanicon(tostring(threat)),new())
	for i=1,iter() do
		if (iter[i]) then
			tinsert(table,iter[i].followerID)
		end
	end
	del(iter)
end
function addon:GetCounterBias(missionID,threat)
	local bias=-1
	local who=""
	local iter=genIteratorByThreat(missionID,cleanicon(tostring(threat)),new())
	for i=1,iter() do
		if (iter[i]) then
			if ((tonumber(iter[i].bias) or -1) > bias) then
				if (dbg) then print("Countered by",self:GetFollowerData(iter[i].followerID,'fullname'),iter[i].bias) end
				if (inParty(missionID,iter[i].followerID)) then
					if (dbg) then print("   Choosen",self:GetFollowerData(iter[i].followerID,'fullname')) end
					bias=iter[i].bias
					who=iter[i].name
				end
			end
		end
	end
	del(iter)
	return bias,who
end
function addon:AddLine(name,status)
	local r2,g2,b2=C.Red()
	if (status==AVAILABLE) then
		r2,g2,b2=C.Green()
	elseif (status==GARRISON_FOLLOWER_WORKING) then
		r2,g2,b2=C.Orange()
	end
	GameTooltip:AddDoubleLine(name, status,nil,nil,nil,r2,g2,b2)
end
function addon:SetThreatColor(obj,missionID)
	if (dbg) then print("Evaluating ",missionID,obj.Icon:GetTexture()) end
	local bias=self:GetCounterBias(missionID,obj.Icon:GetTexture())
	local color=self:GetBiasColor(bias,nil,"Green")
	local c=C[color]
	obj.Border:SetVertexColor(c())
end

function addon:HookedGarrisonMissionButton_AddThreatsToTooltip(missionID)
	self:RenderTooltip(missionID)
end
function addon:RenderTooltip(missionID)
--@debug@
	GameTooltip:AddLine("ID:" .. tostring(missionID))
--@end-debug@
	local mission=self:GetMissionData(missionID)
	if (not mission) then
--@debug@
		GameTooltip:AddLine("E dove minchia è finita??")
--@end-debug@
		return
	end
	local f=GarrisonMissionListTooltipThreatsFrame
	if (not f.Env) then
		f.Env=CreateFrame("Frame",nil,f,"GarrisonAbilityCounterTemplate")
		f.Env:SetWidth(20)
		f.Env:SetHeight(20)
		f.Env:SetPoint("LEFT",f)
	end
	local t=f.EnvIcon:GetTexture();
	f.EnvIcon:Hide()
	f.Env.Icon:SetTexture(t)
	f.Env.Icon:SetWidth(20)
	f.Env.Icon:SetHeight(20)
	self:SetThreatColor(f.Env,missionID)
	--local bias,who=self:GetCounterBias(missionID,t)
	--local color=self:GetBiasColor(bias,nil,"Green")
	--local c=C[color]
	--f.Env.Border:SetVertexColor(c())
	for i=1,#f.Threats do
		local th=f.Threats[i]
		self:SetThreatColor(th,missionID)
	end
	-- Adding All available followers
	local fullnames=new()
	local party=new()
	local biascolors=new()
	local partystring=strjoin("|",tostringall(unpack(parties[missionID].members)))
	for followerID,refs in pairs(counterFollowerIndex[missionID]) do
		local fullname= self:GetFollowerData(followerID,'fullname')
		for i=1,#refs do
			fullname=fullname .." |T" .. tostring(counters[missionID][refs[i]].icon) ..":16|t"
		end
		if (not partystring:find(followerID)) then
			tinsert(fullnames,fullname)
		else
			tinsert(party,fullname)
		end
		biascolors[fullname]={self:GetBiasColor(followerID,missionID,"White"),self:GetFollowerStatus(followerID,true)}
	end
	table.sort(fullnames)
	GameTooltip:AddLine(L["Other useful followers"])
	for i=1,#fullnames do
		local fullname=fullnames[i]
		local info=biascolors[fullname]
		self:AddLine(fullname,info[2],info[1])
	end

	del(party)
	del(fullnames)
	del(biascolors)
	local perc=parties[missionID].perc
	local q=self:GetDifficultyColor(perc)
	GameTooltip:AddDoubleLine(GARRISON_MISSION_SUCCESS,format(GARRISON_MISSION_PERCENT_CHANCE,perc),nil,nil,nil,q.r,q.g,q.b)
	for _,i in pairs (dbcache.ignored[missionID]) do
		GameTooltip:AddLine(L["You have ignored followers"])
		break;
	end
end

function addon:FillFollowersList()
	if (GarrisonFollowerList_UpdateFollowers) then
		GarrisonFollowerList_UpdateFollowers(GMF.FollowerList)
	end
end
local function switch(flag)
	if (GCF[flag]) then
		local b=GCF[flag]
		if (b:GetChecked()) then
			b.text:SetTextColor(C.Green())
		else
			b.text:SetTextColor(C.Silver())
		end
	end
end
function addon:RefreshMission(missionID)
	if (self:IsAvailableMissionPage()) then
		if (tonumber(missionID)) then
			self:FillCounters(missionID)
			self:MatchMaker(missionID)
		end
		GarrisonMissionList_UpdateMissions()
	end
end

function addon:BuildMissionsCache(fc,mm,OnEvent)
--cache.missions
--@debug@
	local start=GetTime()
	xprint("Start Full Cache Rebuild")
--@end-debug@
	local t=new()
	G.GetAvailableMissions(t)
	for index=1,#t do
		local missionID=t[index].missionID
		if (not	dbcache.seen[missionID]) then
			dbcache.seen[missionID]=OnEvent and time() or dbcache.lastseen
		end
		self:BuildMissionCache(missionID,t[index])
		if fc then self:FillCounters(missionID) end
		if mm then self:MatchMaker(missionID) end
	end
	for k,v in pairs(dbcache.seen) do
		if (not cache.missions[k]) then
			local span=time()-tonumber(v) or time()
			if (span > db.lifespan[k]) then
				db.lifespan[k]=span
			end
			dbcache.seen[k]=nil
		end
	end
	del(t)
	collectgarbage("step",10)
--@debug@
	xprint("Done in",GetTime()-start)
--@end-debug@
end
--[[
GARRISON_DURATION_DAYS = "%d |4day:days;"; changed to dual form
GARRISON_DURATION_DAYS_HOURS = "%d |4day:days; %d hr"; changed to dual form
GARRISON_DURATION_HOURS = "%d hr";
GARRISON_DURATION_HOURS_MINUTES = "%d hr %d min";
GARRISON_DURATION_MINUTES = "%d min";
GARRISON_DURATION_SECONDS = "%d sec";
--]]
local function GarrisonTimeStringToSeconds(text)
	local s = D.Deformat(text,GARRISON_DURATION_SECONDS)
	if (s) then return s end
	local m  = D.Deformat(text,GARRISON_DURATION_MINUTES)
	if m then return m end
	local h,m= D.Deformat(text,GARRISON_DURATION_HOURS_MINUTES)
	if (h) then return h*3600+m*60 end
	local h= D.Deformat(text,GARRISON_DURATION_HOURS)
	if (h) then return h*3600 end
	local d,h=D:Deformat(GARRISON_DURATION_DAY_HOURS)
	if (d) then return d*3600*24 + h*3600 end
	local d,h=D:Deformat(GARRISON_DURATION_DAYS_HOURS)
	if (d) then return d*3600*24 + h*3600 end
	local d=D:Deformat(GARRISON_DURATION_DAYS)
	if (d) then return d*3600*24 end
	local d=D:Deformat(GARRISON_DURATION_DAY)
	if (d) then return d*3600*24 end
	return 3600*24

end
function addon:BuildRunningMissionsCache()
	local t=new()
	G.GetInProgressMissions(t)
	for index=1,#t do
		local mission=t[index]
		local missionID=mission.missionID
		local running =dbcache.running[missionID]
		running.duration=mission.durationSeconds
		running.timeLeft=mission.timeLeft
		if ((tonumber(running.started) or 0)==0) then running.started = time() - GarrisonTimeStringToSeconds(mission.timeLeft) end
		running.followers={}
		for i=1,mission.numFollowers do
			running.followers[i]=mission.followers[i]
			dbcache.runningIndex[mission.followers[i]]=missionID
		end
	end
	del(t)
end
--[[
{
	missionID=0,
	counters={}, calculated
	countered={ calculated
		["*"]={}
	},
	counterers={ calculated
		["*"]={}
	},
	slots={  calculated
		["*"]=0
	},
	numFollowers=0, -> GetMissionMaxFollowers()
	name="<newmission>", GetMissionName
	basePerc=0, 		GetPartyMissionInfo
	durationSeconds=0,  GePartyMissionInfo()
	rewards={},
	level=0,
	iLevel=0,
	rank=0,
	locPrefix=false
}
GetBasicInfo Table Format={
	description="With infernals and felguard invading Talador, the rest of the Burning Legion can't be far behind. Defeat them, and try to find their source.",
	cost=15,
	duration="8 hr",
	durationSeconds=28800,
	level=100,
	type="Combat",
	locPrefix="GarrMissionLocation-Talador",
	rewards={
		[248]={
			itemID=114057,
			quantity=1
		}
	},
	numRewards=1,
	numFollowers=3,
	state=-2,
	iLevel=0,
	name="Burning Legion Vanguard",
	followers={
	},
	location="Talador",
	isRare=false,
	typeAtlas="GarrMission_MissionIcon-Combat",
	missionID=113
}

--]]
function addon:BuildMissionCache(id,data)
	local mission=cache.missions[id]
	if (not mission) then
--@dedbug@
		xprint("Generating new data for ",id)
--@end-debug@
		mission = data or G.GetBasicMissionInfo(id)
		if (not mission) then return end
		cache.missions[id]=mission
		if dbg then print("Retrieved",id,mission.name) end
		local _,xp,type,typeDesc,typeIcon,locPrefix,_,enemies=G.GetMissionInfo(id)
		mission.rank=mission.level < 100 and mission.level or mission.iLevel
		mission.xp=xp
		mission.xpBonus=0
		mission.resources=0
		mission.gold=0
		mission.followerUpgrade=0
		mission.itemLevel=0
		for k,v in pairs(mission.rewards) do
			if (v.followerXP) then mission.xpBonus=mission.xpBonus+v.followerXP end
			if (v.currencyID and v.currencyID==GARRISON_CURRENCY) then mission.resources=v.quantity end
			if (v.currencyID and v.currencyID==0) then mission.gold =mission.gold+v.quantity/10000 end
			if (v.itemID) then
				if (v.itemID~=120205) then
					local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(v.itemID)
					if (itemName) then
						if (itemLevel > 1 ) then
							mission.itemLevel=itemLevel
						else
							mission.followerUpgrade=1
						end
					end
				end
			end
		end
		mission.totalXp=(tonumber(mission.xp) or 0) + (tonumber(mission.xpBonus) or 0)
		mission.globalXp=mission.totalXp*mission.numFollowers
		if (mission.resources==0 and mission.gold==0 and mission.itemLevel==0 and mission.followerUpgrade==0) then
			mission.xpOnly=true
		else
			mission.xpOnly=false
		end
		mission.locPrefix=locPrefix
		if (not type) then
--@debug@
			xprint("No type",id,data.name)
--@end-debug@
		else
			self.db.global.types[type]={name=type,description=typeDesc,icon=typeIcon}
		end
		mission.slots={}
		local slots=mission.slots

		for i=1,#enemies do
			local mechanics=enemies[i].mechanics
			for i,mechanic in pairs(mechanics) do
				tinsert(slots,mechanic)
				self.db.global.abilities[mechanic.name]=mechanic
			end
		end
		if (type) then
			tinsert(slots,{name=TYPE,key=type,icon=typeIcon})
		end
	end
	mission.basePerc=select(4,G.GetPartyMissionInfo(id))
end
function addon:SetDbDefaults(default)
	default.global=default.global or {}
	default.global["*"]={
	}
	default.global.lifespan={["*"]=0}
end
function addon:CreatePrivateDb()
	self.privatedb=self:RegisterDatabase(
		GetAddOnMetadata(me,"X-Database")..'perChar',
		{
			profile={
				seen={},
				ignored={
					["*"]={
					}
				},
				totallyignored={
				},
				history={
					['*']={
					}
				},
				running={
					["*"]={
						followers={},
						started=0,
						duration=0
					}
				},
				runningIndex={
					["*"]=0
				},
				missionControl={
					allowedRewards = {["*"]=true},
					rewardChance={["*"]=100},
					useOneChance=true,
					itemPrio = {},
					minimumChance = 100,
					minDuration = 0,
					maxDuration = 24,
					epicExp = false,
					skipRare=true
				}
			}
		},
		true)
	self.private=self:RegisterDatabase(
		"GACPrivateVolatile",
		{
			profile={
				missions={}
			}
		}
	,
	true)
	dbcache=self.privatedb.profile
	cache=self.private.profile
end
function addon:SetClean()
	dirty=false
end

function addon:WipeMission(missionID)
	cache.missions[missionID]=nil
	counters[missionID]=nil
	dbcache.seen[missionID]=nil
	parties[missionID]=nil
	collectgarbage("step")


end

---
--@param #string event GARRISON_MISSION_NPC_OPENED
-- Fires after GarrisonMissionFrame OnShow. Pretty useless

function addon:EventGARRISON_MISSION_NPC_OPENED(event,...)
--@debug@
	xprint(event,...)
--@end-debug@
	if (GCF) then GCF:Show() end
end
function addon:EventGARRISON_MISSION_NPC_CLOSED(event,...)
--@debug@
	xprint(event,...)
--@end-debug@
	if (GCF) then GCF:Hide() end
end
function addon:EventGARRISON_MISSION_LIST_UPDATE(event)
	local n=0
	for _,k in pairs(event) do n=n+1 end
	print("GARRISON_MISSION_LIST_UPDATE",n,date("%d/%m/%y %H:%M:%S"))
	local t=new()
	G.GetAvailableMissions(t)
	local justseen={}
	local now=time()
	for i=1,#t do
		justseen[t[i].missionID]=true
	end
	for missionID,_ in pairs(justseen) do
		if (not tonumber(db.seen[missionID])) then db.seen[missionID]=now end
	end
	self:BuildMissionsCache(false,false,true)
	del(t)
end
---
--@param #string event GARRISON_MISSION_STARTED
--@param #number missionID Numeric mission id
-- After this events fires also GARRISON_MISSION_LIST_UPDATE and GARRISON_FOLLOWER_LIST_UPDATE

function addon:EventGARRISON_MISSION_STARTED(event,missionID,...)
--@debug@
	xprint(event,missionID,...)
--@end-debug@
--				running={
--					["*"]={
--						followers={},
--						started=0,
--						duration=0
--					}
--				},
	dbcache.running[missionID].started=time()
	dbcache.running[missionID].duration=select(2,G.GetPartyMissionInfo(missionID))
	wipe(dbcache.running[missionID].followers)
	for i=1,3 do
		local m=parties[missionID].members[i]
		if (m) then
			tinsert(dbcache.running.followers,m)
			dbcache.runningIndex[m]=missionID
		end
	end
	local v=dbcache.seen[missionID]
	local span=time()-tonumber(v) or time()
	if (span > db.lifespan[missionID]) then
		db.lifespan[missionID]=span
		-- IF we started it.. it was alive, so it's expire time is at least the time we waited before starting it
	end
	dbcache.seen[missionID]=nil
	counters[missionID]=nil
	parties[missionID]=nil
	self:BuildMissionsCache(true,true)
end
---
--@param #string event GARRISON_MISSION_FINISHED
--@param #number missionID Numeric mission id
-- Thsi is just a notification, nothing get really changed
-- GetMissionINfo still returns data
-- but GetPartyMissionInfo does no longer return followers.
-- Also timeleft is false
--

function addon:EventGARRISON_MISSION_FINISHED(event,missionID,...)
--@debug@
	xprint(event,missionID,...)
	xdump(G.GetPartyMissionInfo(missionID))
--@end-debug@
end

function addon:EventGARRISON_FOLLOWER_ADDED(event)
	wipe(followersCache)
	wipe(followersCacheIndex)
end
function addon:EventGARRISON_FOLLOWER_REMOVED(event)
	wipe(followersCache)
	wipe(followersCacheIndex)
end

function addon:EventGARRISON_MISSION_BONUS_ROLL_COMPLETE(event,missionID,completed,success)
--@debug@
	xprint(event,missionID,completed,success)
--@end-debug@
end
---
--@param #number missionID mission identifier
--@param #boolean completed I suppose it always be true...
--@oaram #boolean success Mission was succesfull
--Mission complete Sequence is:
--GARRISON_MISSION_COMPLETE_RESPONSE
--GARRISON_MISSION_BONUS_ROLL_COMPLETE missionID true
--GARRISON_FOLLOWER_XP_CHANGED (1 or more times
--GARRISON_MISSION_NPC_OPENED ??
--GARRISON_MISSION_BONUS_ROLL_COMPLETE missionID nil
--
function addon:EventGARRISON_MISSION_COMPLETE_RESPONSE(event,missionID,completed,success)
--@debug@
	xprint(event,missionID)
--@end-debug@
	dbcache.history[missionID][time()]={result=100,success=success}
	dbcache.seen[missionID]=nil
	dbcache.running[missionID]=nil
	dbcache.seen[missionID]=nil
	counters[missionID]=nil
	parties[missionID]=nil
end
function addon:EventGARRISON_FOLLOWER_REMOVED()
	wipe(followersCache)
	wipe(followersCacheIndex)
end
function addon:EventGARRISON_FOLLOWER_REMOVED()
	wipe(followersCache)
	wipe(followersCacheIndex)
end
-----------------------------------------------------
-- Coroutines data and clock management
-----------------------------------------------------
local coroutines={
	Timers={
		func=false,
		elapsed=60,
		interval=60,
		paused=false
	},
}

local lastmin=0
local MPShown=nil
local dbgFrame
-- Keeping it as a nice example of coroutine management.. but not using it anymore
function addon:Clock()
	collectgarbage("step",20)
--@debug@
	if (not dbgFrame) then
		dbgFrame=AceGUI:Create("Window")
		dbgFrame:SetTitle("GC Performance")
		dbgFrame:SetPoint("TOP")
		dbgFrame:SetHeight(80)
		dbgFrame:SetWidth(200)
		dbgFrame:SetLayout("fill")
		dbgFrame.Text=AceGUI:Create("Label")
		dbgFrame.Text:SetColor(1,0,0)
		dbgFrame:AddChild(dbgFrame.Text)
	end
	local h,m=GetGameTime()
	if (m~=lastmin) then
		lastmin=m
	end
	UpdateAddOnCPUUsage()
	UpdateAddOnMemoryUsage()
	dbgFrame.Text:SetText(format("GC Cpu %3.2f Mem %4.3f ",GetAddOnCPUUsage("GarrisonCommander"),GetAddOnMemoryUsage("GarrisonCommander")/1024))
--@end-debug@
	dbcache.lastseen=time()
	if (not MP) then return end
	MPShown=not self:GetBoolean("CKMP")
	local children={GMFMissions:GetChildren()}
	for i=1,#children do
		local child=children[i]
		if (child:GetObjectType()=="ScrollFrame") then
			if (child:GetName() ~= "GarrisonMissionFrameMissionsListScrollFrame") then
				if (MPShown) then child:Show() else child:Hide() end
			end
			if (child:GetName() == "GarrisonMissionFrameMissionsListScrollFrame") then
				if (MPShown) then child:Hide() else child:Show() end
			end
		end
	end
	if (MPShown) then
		GarrisonMissionFrameMissionsListScrollFrame:Hide()
	else
		GarrisonMissionFrameMissionsListScrollFrame:Show()
		GarrisonMissionFrameMissionsListScrollFrame:SetParent(GarrisonMissionFrameMissions)
	end
--@debug@
	for k,d in pairs(coroutines) do
		local  co=coroutines[k]
		if (not co.func) then
			co.func=self["Generate"..k.."Periodic"](self)
			if (type(co.func) ~="function") then
				co.func=function() end
			end
		end
		co.elapsed=co.elapsed+1
		if not co.paused and co.elapsed > co.interval then
			co.elapsed=0
			co.paused=co.func(self)
		end
	end
--@end-debug@
end
function addon:ActivateButton(button,OnClick,Tooltiptext,persistent)
	button:SetScript("OnClick",function(...) self[OnClick](self,...) end )
	if (Tooltiptext) then
		button.tooltip=Tooltiptext
		button:SetScript("OnEnter",function(...) self:ShowTT(...) end )
		button:SetScript("OnLeave",function() GameTooltip:FadeOut() end)
	else
		button:SetScript("OnEnter",nil)
		button:SetScript("OnLeave",nil)
	end
end
function addon:ShowTT(this)
	GameTooltip:SetOwner(this, "ANCHOR_CURSOR_RIGHT")
	GameTooltip:SetText(this.tooltip)
	GameTooltip:Show()
end
function addon:Shrink(button)
	local f=button.Toggle
	local name=f:GetName() or "Unnamed"
	if (f:GetHeight() > 200) then
		f.savedHeight=f:GetHeight()
		f:SetHeight(200)
	else
		f:SetHeight(f.savedHeight)
	end
end

function addon:ShowMissionControl()
	if (not GMC:IsShown()) then
		GarrisonMissionFrame_SelectTab(999)
		GarrisonMissionFrame.FollowerTab:Hide()
		GarrisonMissionFrame.FollowerList:Hide()
		GarrisonMissionFrame.MissionTab:Hide()
		GarrisonMissionFrame.TitleText:SetText("Garrison Commander Mission Control")
		GMC:Show()
		GMC.startButton:Click()
		GMC.tabMC:SetChecked(true)
	else
		GMC:Hide()
		GMC.tabMC:SetChecked(false)
		GarrisonMissionFrame_SelectTab(1)
	end
end
local helpwindow -- pseudo static
function addon:ShowHelpWindow(button)
	if (not helpwindow) then
		local backdrop = {
				--bgFile="Interface\\TutorialFrame\\TutorialFrameBackground",
				bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
				edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
				tile=true,
				tileSize=16,
				edgeSize=16,
				insets={bottom=7,left=7,right=7,top=7}
		}
		local dialog = {
			bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
			tile=true,
			tileSize=32,
			edgeSize=32,
			insets={bottom=5,left=5,right=5,top=5}
		}
		helpwindow=CreateFrame("Frame",nil,GCF)
		helpwindow:EnableMouse(true)
		helpwindow:SetBackdrop(backdrop)
		helpwindow:SetBackdropColor(1,1,1,1)
		helpwindow:SetFrameStrata("TOOLTIP")
		helpwindow:Show()
		local html=CreateFrame("SimpleHTML",nil,helpwindow)
		html:SetFontObject('h1',MovieSubtitleFont);
		local f=MailTextFontNormal_KO
		html:SetFontObject('h2',f);
		html:SetFontObject('h3',f);
		html:SetFontObject('p',f);
		html:SetTextColor('h1',C.Blue())
		html:SetTextColor('h2',C.Orange())
		html:SetTextColor('h3',C.Red())
		html:SetTextColor('p',C.Yellow())
		local text=[[<html><body>
<h1 align="center">Garrison Commander Help</h1>
<br/>
<p align="center">GC enhances standard Garrison UI by adding a Menu header and useful information in mission button and tooltip.
Since 2.0.2, the "big screen" mode became optional. If you choosed to disable it, some feature described here will not be available
</p>
<br/>
<h2>  Button list:</h2>
<p>
* Success percent with the current followers selection guidelines<br/>
* Time since the first time we saw this mission in log<br/>
* A "Good" party composition. on each member countered mechanics are shown.<br/>
*** Green border means full counter, Orange border low level counter<br/>
</p>
<h2>Tooltip:</h2>
<p>
* Overall mission status<br/>
* All members which can possibly play a role in the mission<br/>
</p>
<h2>Button enhancement:</h2>
<p>
* In rewards, actual quantity is shown (xp, money and resources) ot iLevel (item rewards)<br/>
* Countered status<br/>
</p>
<h2>Menu Header:</h2>
<p>
* Quick selection of which follower ignore for match making<br/>
* Quick mission list order selection<br/>
</p>
<h2>Mission Control:</h2>
<p>Thanks to Motig which donated the code, we have an auto lancher for mission<br/>
You specify some criteria mission should satisfy (success chance, rewards type etc) and matching missions will be autosubmitted<br/>
BE WARNED, FEATURE IS |cffff0000EXPERIMENTAL|r
</p>
]]
if (MP) then
text=text..[[
<p><br/></p>
<h3>Master Plan 0.20 or above detected</h3>
<p>Master Plan hides Garrison Commander interface for available missions<br/>
You can still use Garrison Commander Mission Control<br/>
You can switch between MP and GC interface for missions checking and unchecking "Use GC Interface" checkbox. It usually works :)
</p>
]]
end
if (MPGoodGuy) then
text=text..[[
<p><br/></p>
<h3>Master Plan 0.18 Detected</h3>
<p>This the last known version of Master Plan which leaves Blizzard UI available to other addons<br/>
You loose Garrison Commander Active Mission page, but the one provided by MP is good enough.<br/>
In order to see enhanced tooltips you need to hover on extra button.
</p>
]]
end
if (GMM) then
text=text..[[
<p><br/></p>
<h3>Garrison Mission Manager Detected</h3>
<p>Garrison Mission Manager and Garrison Commander plays reasonably well together.<br/>
The red button to the right of rewards is from GMM. It spills out of button, Yes, it's designed this way. Dunno why. Ask GMM author :)<br/>
Same thing for the three red buttons in mission page.
</p>
]]
end
text=text.."</body></html>"
		--html:SetTextColor('h1',C.Red())
		--html:SetTextColor('h2',C.Orange())
		helpwindow:SetWidth(800)
		helpwindow:SetHeight(590 + ((MP or MPGoodGuy) and 160 or 0) + (GMM and 120 or 0))
		helpwindow:SetPoint("TOPRIGHT",button,"TOPLEFT",0,0)
		html:ClearAllPoints()
		html:SetWidth(helpwindow:GetWidth()-20)
		html:SetHeight(helpwindow:GetHeight()-20)
		html:SetPoint("TOPLEFT",helpwindow,"TOPLEFT",10,-10)
		html:SetPoint("BOTTOMRIGHT",helpwindow,"BOTTOMRIGHT",-10,10)
		html:SetText(text)
		helpwindow:Show()
		return
	end
	if (helpwindow:IsShown()) then helpwindow:Hide() else helpwindow:Show() end
end
function addon:Toggle(button)
	local f=button.Toggle
	local name=f:GetName() or "Unnamed"
	if (f:IsShown()) then  f:Hide() else  f:Show() end
	if (button.SetChecked) then
		button:SetChecked(f:IsShown())
	end
end
-- Unused, experimenting with acegui
function addon:GenerateMissionsWidgets()
	self:GenerateMissionContainer()
	self:GenerateMissionButton()
end
function addon:GenerateMissionContainer()
	do
		local Type="GMCLayer"
		local Version=1
		local function OnRelease(self)
			wipe(self.childs)
		end
		local function OnAcquire(self)
			self.frame:SetParent(UIParent)
			self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
			self.frame:SetHeight(50)
			self.frame:SetWidth(100)
			self.frame:Show()
			self.frame:SetPoint("LEFT")
		end
		local function Show(self)
			self.frame:Show()
		end
		local function Hide(self)
			self.frame:Hide()
			self:Release()
		end
		local function SetScript(self,...)
			self.frame:SetScript(...)
		end
		local function SetParent(self,...)
			self.frame:SetParent(...)
		end
		local function PushChild(self,child,index)
			self.childs[index]=child
			self.scroll:AddChild(child)
		end
		local function RemoveChild(self,index)
			local child=self.childs[index]
			if (child) then
				self.childs[index]=nil
				child:Hide()
				self:DoLayout()
			end
		end
		local function ClearChildren(self)
			wipe(self.childs)
			self:AddScroll()
		end
		local function AddScroll(self)
			if (self.scroll) then
				self:ReleaseChildren()
				self.scroll=nil
			end
			self.scroll=AceGUI:Create("ScrollFrame")
			local scroll=self.scroll
			self:AddChild(scroll)
			scroll:SetLayout("List") -- probably?
			scroll:SetFullWidth(true)
			scroll:SetFullHeight(true)
			scroll:SetPoint("TOPLEFT",self.title,"BOTTOMLEFT",0,0)
			scroll:SetPoint("TOPRIGHT",self.title,"BOTTOMRIGHT",0,0)
			scroll:SetPoint("BOTTOM",self.content,"BOTTOM",0,0)
		end
		local function Constructor()
			local frame=CreateFrame("Frame")
			local title=frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalHugeBlack")
			title:SetJustifyH("CENTER")
			title:SetJustifyV("CENTER")
			title:SetPoint("TOPLEFT")
			title:SetPoint("TOPRIGHT")
			title:SetHeight(0)
			title:SetWidth(0)
			addBackdrop(frame)
			local widget={childs={}}
			widget.title=title
			widget.type=Type
			widget.SetTitle=function(self,...) self.title:SetText(...) end
			widget.SetTitleColor=function(self,...) self.title:SetTextColor(...) end
			widget.SetFormattedTitle=function(self,...) self.title:SetFormattedText(...) end
			widget.SetTitleWidth=function(self,...) self.title:SetWidth(...) end
			widget.SetTitleHeight=function(self,...) self.title:SetHeight(...) end
			widget.frame=frame
			frame.obj=widget
			widget.OnAcquire=OnAcquire
			widget.OnRelease=OnRelease
			widget.Show=Show
			widget.Hide=Hide
			widget.SetScript=SetScript
			widget.SetParent=SetParent
			frame:SetScript("OnHide",function(self) self.obj:Fire('OnClose') end)
			--Container Support
			local content = CreateFrame("Frame",nil,frame)
			widget.content = content
			content.obj = self
			content:SetPoint("TOPLEFT",title,"BOTTOMLEFT")
			content:SetPoint("BOTTOMRIGHT")
			AceGUI:RegisterAsContainer(widget)
			widget.PushChild=PushChild
			widget.RemoveChild=RemoveChild
			widget.ClearChildren=ClearChildren
			widget.AddScroll=AddScroll
			return widget
		end
		AceGUI:RegisterWidgetType(Type,Constructor,Version)
	end
end

function addon:GenerateMissionButton()
	do
		local Type="GMCMissionButton"
		local Version=1
		local unique=0
		local function OnAcquire(self)
			local frame=self.frame
			frame.info=nil
			frame:SetHeight(80)
			self.frame:SetAlpha(1)
			self.frame:Enable()
		end
		local function Show(self)
			self.frame:Show()
		end
		local function Hide(self)
			self.frame:SetHeight(1)
			self.frame:SetAlpha(0)
			self.frame:Disable()
		end
		local function SetScript(self,...)
			self.frame:SetScript(...)
		end
		local function SetMission(self,mission,missionID)
			self.frame.info=mission
			addon:FillMissionButton(self.frame,true)
			self.frame:SetScript("OnEnter",GarrisonMissionButton_OnEnter)
			self.frame:SetScript("OnLeave",function() GameTooltip:FadeOut() end)
			local party
			for i=1,#GMC.ml.Parties do
				party=GMC.ml.Parties[i]
				if party.missionID==missionID then
					break
				end
			end
			self.frame.Percent:SetFormattedText("%d%%",party.perc)
			self.frame.Percent:SetTextColor(addon:GetDifficultyColors(party.perc))
			local x=1
			for i=1,#party.members do
				x=i+1
				addon:FillFollowerButton(self.frame.members[i],party.members[i],missionID)
				self.frame.members[i]:Show()
			end
			for i=x,3 do
				self.frame.members[i]:Hide()
			end
		end

		local function Constructor()
			unique=unique+1
			local frame=CreateFrame("Button","Pippo"..unique,nil,"GarrisonMissionListButtonTemplate") --"GarrisonCommanderMissionListButtonTemplate")
			local indicators=CreateFrame("Frame",nil,frame,"GarrisonCommanderIndicators")
			indicators:SetPoint("LEFT",65,0)
			indicators.Age:Hide()
			frame.Percent=indicators.Percent
			frame:SetScript("OnEnter",nil)
			frame:SetScript("OnLeave",nil)
			frame:SetScript("OnClick",function(self,button) self.obj:Fire("OnClick",self,button) end)
			frame.LocBG:SetPoint("LEFT")
			frame.MissionType:SetPoint("TOPLEFT",5,-2)
			frame.members={}
			for i=1,3 do
				local f=CreateFrame("Button",nil,frame,"GarrisonCommanderMissionPageFollowerTemplateSmall" )
				frame.members[i]=f
				f:SetPoint("BOTTOMRIGHT",-65 -65 *i,5)
				f:SetScale(0.8)
			end
			local widget={}
			setmetatable(widget,{__index=frame})
			widget.type=Type
			widget.frame=frame
			frame.obj=widget
			widget.OnAcquire=OnAcquire
			widget.Show=Show
			widget.Hide=Hide
			widget.SetScript=SetScript
			widget.SetMission=SetMission
			return AceGUI:RegisterAsWidget(widget)

		end
		AceGUI:RegisterWidgetType(Type,Constructor,Version)
	end
end
function addon:GMCBuildMiniMissionButton(frame,i,mission,scale,perc,offset)
	offset=offset or 20
	scale=scale or 0.6
	local panel=frame.Missions[i]
	if (not panel) then
		panel=CreateFrame("Button",nil,frame,"GarrisonCommanderMissionListButtonTemplate")
		panel:SetPoint("TOPLEFT",frame,1,-((i-1)*panel:GetHeight() +offset))
		panel:SetPoint("TOPRIGHT",frame,-1,-((i-1)*panel:GetHeight()-offset))
		panel.orderId=i
		tinsert(frame.Missions,panel)
		--Creo una riga nuova
		panel:SetScale(scale)
		panel.LocBG:SetPoint("LEFT")
	end
	panel.info=mission
	--panel.id=index[missionID]
	self:FillMissionButton(panel)
	local q=self:GetDifficultyColor(perc)
	panel.Percent:SetFormattedText(GARRISON_MISSION_PERCENT_CHANCE,perc)
	panel.Percent:SetTextColor(q.r,q.g,q.b)
	panel.NumMembers:SetFormattedText(GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS,mission.numFollowers)
	panel:Show()
	return panel
end


local function GFC_Constructor()
	local widget=setmetatable({},{__index=AceGUI:Create("SimpleGroup")})
	function widget:DrawOn(frame,l,r)
		self.frame:ClearAllPoints()
		self.frame:SetPoint("TOPLEFT",frame,"TOPLEFT",l,0)
		self.frame:SetPoint("BOTTOMRIGHT",frame,"TOPRIGHT",r,0)
	end
	function widget:OnRelease()
		self.frame:ClearAllPoints()
	end
	if (false) then
		AceGUI:RegisterWidgetType("GarrisonCommanderHeader",GFC_Constructor,1)
		local layer=AceGUI:Create("GarrisonCommanderHeader")
		layer:DrawOn(GCF)
		layer:SetLayout("flow")
		LibStub("AceConfigDialog-3.0"):Open(me,layer)
	end
	return widget
end

function addon:CreateOptionsLayer(...)
	local o=AceGUI:Create("SimpleGroup") -- a transparent frame
	o:SetLayout("Flow")
	o:SetCallback("OnClose",function(widget) widget.frame:SetScale(1.0) widget:Release() end)
	for i=1,select('#',...) do
		self:AddOptionToOptionsLayer(o,select(i,...))
	end
	_G.TEST=o
	local me=setmetatable({},{__index=o})
	function me:Show() self.frame:Show() end
	function me:SetFrameStrata(...) self.frame:SetFrameStrata(...) end
	function me:SetFrameLevel(...) self.frame:SetFrameLevel(...) end
	return me
end
function addon:AddOptionToOptionsLayer(o,flag,maxsize)
	maxsize=tonumber(maxsize) or 150
	if (not flag) then return end
	local info=self:GetVarInfo(flag)
	if (info) then
		local data={option=info}
		local widget
		if (info.type=="toggle") then
			widget=AceGUI:Create("CheckBox")
			local value=self:GetBoolean(flag)
			widget:SetValue(value)
			local color=value and "Green" or "Silver"
			widget:SetLabel(C(info.name,color))
			widget:SetWidth(max(widget.text:GetStringWidth(),maxsize))
		elseif(info.type=="select") then
			widget=AceGUI:Create("Dropdown")
			widget:SetValue(self:GetVar(flag))
			widget:SetLabel(info.name)
			widget:SetText(info.values[self:GetVar(flag)])
			widget:SetList(info.values)
			widget:SetWidth(maxsize)
		elseif (info.type=="execute") then
			widget=AceGUI:Create("Button")
			widget:SetText(info.name)
			widget:SetWidth(maxsize)
			widget:SetCallback("OnClick",function(widget,event,value)
				self[info.func](self,data,value)
			end)
		else
			widget=AceGUI:Create("Label")
			widget:SetText(info.name)
			widget:SetWidth(maxsize)
		end
		widget:SetCallback("OnValueChanged",function(widget,event,value)
			if (type(value=='boolean')) then
				local color=value and "Green" or "Silver"
				widget:SetLabel(C(info.name,color))
			end
			self[info.set](self,data,value)
		end)
		widget:SetCallback("OnEnter",function(widget)
			GameTooltip:SetOwner(widget.frame,"ANCHOR_CURSOR")
			GameTooltip:AddLine(info.desc)
			GameTooltip:Show()
		end)
		widget:SetCallback("OnLeave",function(widget)
			GameTooltip:FadeOut()
		end)
		o:AddChildren(widget)
	end
end
function addon:Options()
	-- Main Garrison Commander Header
	GCF=CreateFrame("Frame","GCF",UIParent,"GarrisonCommanderTitle")
	-- Removing wood corner. I do it here to not derive an xml frame. This shoud play better with ui extensions
	for _,f in pairs({GCF:GetRegions()}) do
		if (f:GetObjectType()=="Texture" and f:GetAtlas()=="Garr_WoodFrameCorner") then f:Hide() end
	end
	GCF:SetFrameStrata(GMF:GetFrameStrata())
	GCF:SetFrameLevel(GMF:GetFrameLevel()-1)
	GCF.CloseButton:SetScript("OnClick",nil)
	GCF:SetWidth(BIGSIZEW)
	GCF:SetPoint("TOP",UIParent,0,-60)
	if (not bigscreen) then GCF:SetHeight(GCF:GetHeight()+30) end
	GCF:EnableMouse(true)
	GCF:SetMovable(true)
	GCF:RegisterForDrag("LeftButton")
	GCF:SetScript("OnDragStart",function(frame)if (self:GetBoolean("MOVEPANEL")) then frame:StartMoving() end end)
	GCF:SetScript("OnDragStop",function(frame) frame:StopMovingOrSizing() end)
	GCF.Help:SetScript("OnEnter",function(this)
		GameTooltip:SetOwner(this,"ANCHOR_TOPLEFT")
		GameTooltip:AddLine("Check the three tabs next to top right corner of this panel for Garrison Commander new features")
		GameTooltip:Show()
	end
	)
	GCF.Help:Show()


	if (bigscreen) then
		--MinimizeButton
		-- It's not working well, now I dont have time to fix it
		if (false) then
		local h=CreateFrame("Button",nil,base,"UIPanelCloseButton")
		h:SetFrameLevel(999)
		h:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Up")
		h:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Down")
		h:SetHeight(32)
		h:SetWidth(32)
		h.Toggle=GMF
		h:SetPoint("TOPRIGHT")
		self:ActivateButton(h,"Shrink",L["Click to toggle Garrison Mission Frame"])
		GCF.gcHIDE=h
		end
		-- Mission list on follower panels
		local ml=CreateFrame("Frame","GCFMissions",GMFFollowers,"GarrisonCommanderFollowerMissionList")
		ml:SetPoint("TOPLEFT",GMFFollowers,"TOPRIGHT")
		ml:SetPoint("BOTTOMLEFT",GMFFollowers,"BOTTOMRIGHT")
		--ml:SetWidth(450)
		ml:Show()
		GCFMissions=ml
		local fs=GMFFollowers:CreateFontString(nil, "BACKGROUND", "GameFontNormalHugeBlack")
		fs:SetPoint("TOPLEFT",GMFFollowers,"TOPRIGHT")
		fs:SetText(AVAILABLE)
		fs:SetWidth(250)
		fs:Show()
		GCFBusyStatus=fs
	end
	self:Trigger("MOVEPANEL")
	self.Options=function() end
end

function addon:ScriptTrace(hook,frame,...)
--@debug@
	xprint("Triggered " .. C(hook,"red").." script on",C(frame,"Azure"),...)
--@end-debug@
end
function addon:IsProgressMissionPage()
	return GMF:IsShown() and GMFMissions:IsShown() and GMFMissions.showInProgress and not GMFFollowers:IsShown() and not GMF.MissionComplete:IsShown()
end
function addon:IsAvailableMissionPage()
	return GMF:IsShown() and GMFMissions:IsShown() and not GMFMissions.showInProgress  and not GMFFollowers:IsShown() and not GMF.MissionComplete:IsShown()
end
function addon:IsFollowerList()
	return GMF:IsShown() and GMFFollowers:IsShown()
end
--GMFMissions.CompleteDialog
function addon:IsRewardPage()
	return GMF:IsShown() and GMF.MissionComplete:IsShown()

end
function addon:IsMissionPage()
	return GMF:IsShown() and GMFMissionPage:IsShown() and GMFFollowers:IsShown()
end
function addon:HookedGarrisonMissionFrame_SelectTab(id)
	GMC:Hide()
	GMC.tabMC:SetChecked(false)
	wipe(GMCUsedFollowers)
end
function addon:HookedGarrisonMissionFrame_HideCompleteMissions()
	self:BuildMissionsCache(true,true)
end


function addon:HookedGarrisonFollowerTooltipTemplate_SetGarrisonFollower(...)
	local h=GarrisonFollowerTooltip:GetHeight()
	local ft=GarrisonFollowerTooltip.ft
	if (not ft) then
		local backdrop = {
			bgFile="Interface\\TutorialFrame\\TutorialFrameBackground",
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
			tile=true,
			tileSize=16,
			edgeSize=16,
			insets={bottom=3,left=3,right=3,top=3}
		}
		ft=CreateFrame("Frame",nil,GarrisonFollowerTooltip)
		ft:SetBackdrop(backdrop)
		ft:SetBackdropColor(1,1,1,1)
		local fs=ft:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		GarrisonFollowerTooltip.ft=ft
		fs:SetWidth(0)
		fs:SetHeight(0)
		fs:SetText(L["Left Click to see available missions"].."\n"..L["Right click to open ignore menu"])
		fs:SetTextColor(C.Green())
		ft:SetPoint("TOPLEFT",GarrisonFollowerTooltip,"BOTTOMLEFT",5,5)
		ft:SetPoint("TOPRIGHT",GarrisonFollowerTooltip,"BOTTOMRIGHT",-5,5)
		ft:SetHeight(45)
		fs:SetAllPoints()
	end
	if (self:IsMissionPage()) then
		ft:Hide()
	else
		ft:Show()
	end
end
function addon:HookedGarrisonFollowerButton_UpdateCounters(frame,follower,showCounters)
	if MP then self:Unhook("GarrisonFollowerButton_UpdateCounters") return end
	if not frame.GCTime then
		frame.GCTime=frame:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
		frame.GCTime:SetPoint("TOPLEFT",frame.Status,"TOPRIGHT",5,0)
	end
	if not frame.GCXp then
		frame.GCXp=frame:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
		frame.GCXp:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,2)
	end
	if not frame.isCollected then
		frame.GCTime:Hide()
		frame.GCXp:Hide()
		return
	end
	if (frame.Status:GetText() == GARRISON_FOLLOWER_ON_MISSION) then
		frame.GCTime:SetText(self:GetFollowerStatus(follower.followerID,true,true))
		frame.GCTime:Show()
	else
		frame.GCTime:Hide()
	end
	if (follower.level >= GARRISON_FOLLOWER_MAX_LEVEL and follower.quality >= GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY) then
		frame.GCXp:Hide()
	else
		frame.GCXp:SetFormattedText("Xp to next upgrade: %d",follower.levelXP-follower.xp)
		frame.GCXp:Show()
	end

end
function addon:HookedGarrisonFollowerListButton_OnClick(frame,button)
--@debug@
	trace("Click",frame:GetName(),button,GarrisonMissionFrame.FollowerTab.Model:IsShown())
--@end-debug@
	if (button=="LeftButton" and GarrisonMissionFrame.FollowerTab.FollowerID ~= frame.info.followerID) then
		if (frame.info.isCollected) then
			self:HookedGarrisonFollowerPage_ShowFollower(frame.info,frame.info.followerID)
		end
	end
end
-- Shamelessly stolen from Blizzard Code
function addon:FillMissionButton(button,gmc,...)
	local mission=button.info
	if (not mission or not mission.name) then
		if (button.missionID) then
			mission=self:GetMissionData(button.missionID)
		end
	end
	if gmc then print("Arrivo da Mission control") end
	if (not mission) then return end
	button.Title:SetWidth(0);
	button.Title:SetText(mission.name);
	button.Level:SetText(mission.level);
	if ( mission.durationSeconds >= GARRISON_LONG_MISSION_TIME ) then
		local duration = format(GARRISON_LONG_MISSION_TIME_FORMAT, mission.duration);
		button.Summary:SetFormattedText(PARENS_TEMPLATE, duration);
	else
		button.Summary:SetFormattedText(PARENS_TEMPLATE, mission.duration);
	end
	local tw=button:GetWidth() -165
	if ( button.Title:GetWidth() + button.Summary:GetWidth() + 8 < tw - mission.numRewards * 65 ) then
		button.Title:SetPoint("LEFT", 165, 0);
		button.Summary:ClearAllPoints();
		button.Summary:SetPoint("BOTTOMLEFT", button.Title, "BOTTOMRIGHT", 8, 0);
	else
		button.Title:SetPoint("LEFT", 165, 10);
		button.Title:SetWidth(tw - mission.numRewards * 65);
		button.Summary:ClearAllPoints();
		button.Summary:SetPoint("TOPLEFT", button.Title, "BOTTOMLEFT", 0, -4);
	end
	if gmc then button.Title:SetPoint("LEFT",70,25) end
	if ( mission.locPrefix ) then
		button.LocBG:Show();
		button.LocBG:SetAtlas(mission.locPrefix.."-List");
	else
		button.LocBG:Hide();
	end
	if (mission.isRare) then
		button.RareOverlay:Show();
		button.RareText:Show();
		button.IconBG:SetVertexColor(0, 0.012, 0.291, 0.4)
	else
		button.RareOverlay:Hide();
		button.RareText:Hide();
		button.IconBG:SetVertexColor(0, 0, 0, 0.4)
	end
	local showingItemLevel = false;
	if ( mission.level == GARRISON_FOLLOWER_MAX_LEVEL and mission.iLevel > 0 ) then
		button.ItemLevel:SetFormattedText(NUMBER_IN_PARENTHESES, mission.iLevel);
		button.ItemLevel:Show();
		showingItemLevel = true;
	else
		button.ItemLevel:Hide();
	end
	if ( showingItemLevel and mission.isRare ) then
		button.Level:SetPoint("CENTER", button, "TOPLEFT", 40, -22);
	else
		button.Level:SetPoint("CENTER", button, "TOPLEFT", 40, -36);
	end

	--button:Enable();
	if (mission.inProgress) then
		button.Overlay:Show();
		button.Summary:SetText(mission.timeLeft.." "..RED_FONT_COLOR_CODE..GARRISON_MISSION_IN_PROGRESS..FONT_COLOR_CODE_CLOSE);
	else
		button.Overlay:Hide();
	end
	button.MissionType:SetAtlas(mission.typeAtlas);
	GarrisonMissionButton_SetRewards(button,mission.rewards, mission.numRewards);
	button:Show();

end
-- Ripped bleeding from Blizzard code. In mini buttons I cant suffer MP staff
function addon:ClonedGarrisonMissionButton_SetRewards(rewards, numRewards)
	if (numRewards > 0) then
		local index = 1;
		for id, reward in pairs(rewards) do
			if (not self.Rewards[index]) then
				self.Rewards[index] = CreateFrame("Frame", nil, self, "GarrisonMissionListButtonRewardTemplate");
				self.Rewards[index]:SetPoint("RIGHT", self.Rewards[index-1], "LEFT", 0, 0);
			end
			local Reward = self.Rewards[index];
			Reward.Quantity:Hide();
			Reward.itemID = nil;
			Reward.currencyID = nil;
			Reward.tooltip = nil;
			if (reward.itemID) then
				Reward.itemID = reward.itemID;
				GarrisonMissionFrame_SetItemRewardDetails(Reward);
				if ( reward.quantity > 1 ) then
					Reward.Quantity:SetText(reward.quantity);
					Reward.Quantity:Show();
				end
			else
				Reward.Icon:SetTexture(reward.icon);
				Reward.title = reward.title
				if (reward.currencyID and reward.quantity) then
					if (reward.currencyID == 0) then
						Reward.tooltip = GetMoneyString(reward.quantity);
					else
						Reward.currencyID = reward.currencyID;
						Reward.Quantity:SetText(reward.quantity);
						Reward.Quantity:Show();
					end
				else
					Reward.tooltip = reward.tooltip;
				end
			end
			Reward:Show();
			index = index + 1;
		end
	end

	for i = (numRewards + 1), #self.Rewards do
		self.Rewards[i]:Hide();
	end
end
function addon:ClonedGarrisonMissionMechanic_OnEnter(missionID,this,...)
	local tip=GameTooltip
	tip:SetOwner(this, "ANCHOR_CURSOR_RIGHT");
	tip:AddLine(this.info.name,C.White())
	--tip:AddTexture(this.Icon:GetTexture())
	tip:AddLine(this.info.description,C.Orange())
	local t=new()
	self:GetAllCounters(missionID,this.Icon:GetTexture(),t)
	if( #t > 0) then
		tip:AddLine(GARRISON_MISSION_COUNTER_FROM)
		for i=1,#t do
			tip:AddLine(self:GetFollowerData(t[i],'fullname'),C[self:GetBiasColor(t[i],missionID,C.White())]())
		end
	end
	tip:Show()
end
local Busystatusmessage
function addon:HookedGarrisonFollowerPage_ShowFollower(frame,followerID)
	local i=0
	if (not self:IsFollowerList()) then return end
	if (not GCFMissions.Missions) then GCFMissions.Missions={} end
	if (not Busystatusmessage) then Busystatusmessage=C(BUSY_MESSAGE,"Red)") end
	-- frame has every info you can need on a follower, but here I dont really need them, maybe just counters
	--xdump(table.Counters)
	local followerName=self:GetFollowerData(followerID,'name')
	repeat -- a poor man goto
		if (type(frame.followerID)=="number") then
			GCFBusyStatus:SetText(NOT_COLLECTED)
			GCFBusyStatus:SetTextColor(C.Red())
			break
		end

		local index=new()
		local partyIndex=new()

		local status=self:GetFollowerStatus(followerID)
		local list
		local m1,m2,m3,perc,numFollowers=nil,nil,nil,0,""
		if (status ~= AVAILABLE and status ~= GARRISON_FOLLOWER_IN_PARTY) then
			if (status==GARRISON_FOLLOWER_ON_MISSION) then
				local missionID=dbcache.runningIndex[followerID]
				if (not missionID) then return end
				list=GMF.MissionTab.MissionList.inProgressMissions
				m1=followerID
				perc=select(4,G.GetPartyMissionInfo(missionID))
				for j=1,#list do
					index[list[j].missionID]=j
				end
				local pos=index[missionID]
				if (not pos) then return end
				numFollowers=#list[index[missionID]].followers
				tinsert(partyIndex,-missionID)
				GCFBusyStatus:SetText(GARRISON_FOLLOWER_ON_MISSION)
			else
				GCFBusyStatus:SetText(self:GetFollowerStatus(followerID,false,true)) -- no time, colored
			end
			GCFBusyStatus:SetTextColor(C.Red())

		else
			GCFBusyStatus:SetText(Busystatusmessage)
			list=GMF.MissionTab.MissionList.availableMissions
			for j=1,#list do
				index[list[j].missionID]=j
			end
			for k,_ in pairs(parties) do
				tinsert(partyIndex,k)
			end
			table.sort(partyIndex,function(a,b) return parties[a].perc > parties[b].perc end)
		end
		self:FillFollowerButton(GCFMissions.Header,followerID)
		-- Scanning mission list
		for z = 1,#partyIndex do
			local missionID=partyIndex[z]
			if not(tonumber(missionID)) then
--@debug@
				xprint("missionid not a number",missionID)
				self:Dump("partyIndex table",partyIndex)
--@end-debug@
				perc=-1 --(lowering perc  to ignore this mission
			end

			if (missionID>0) then
				local p=parties[missionID]
				m1,m2,m3,perc=p.members[1],p.members[2],p.members[3],tonumber(p.perc) or 0
				if (m3) then
					numFollowers=3
				elseif(m2) then
					numFollowers=2
				else
					numFollowers=1
				end
			else
				missionID=abs(missionID)
			end
			if (perc>MINPERC and ( m1 == followerID or m2==followerID or m3==followerID)) then
				i=i+1
				local mission=list[index[missionID]]
				local panel=GCFMissions.Missions[i]
				if (not panel) then
					panel=CreateFrame("Button",nil,GCFMissions,"GarrisonCommanderMissionListButtonTemplate")
					self:SafeHookScript(panel,"OnClick","OnClick_GarrisonMissionButton",true)

					if (i==1) then
						panel:SetPoint("TOPLEFT",GCFMissions.Header,"BOTTOMLEFT")
					else
						panel:SetPoint("TOPLEFT",GCFMissions.Missions[i-1],"BOTTOMLEFT")
						panel:SetPoint("TOPRIGHT",GCFMissions.Missions[i-1],"BOTTOMRIGHT")
					end
					tinsert(GCFMissions.Missions,panel)
					--Creo una riga nuova
					panel:SetScale(0.6)
					panel.fromFollowerPage=true
					panel.LocBG:SetPoint("LEFT")
				end
				panel.info=mission
				--panel.id=index[missionID]
				self:FillMissionButton(panel)
				local q=self:GetDifficultyColor(perc)
				panel.Percent:SetFormattedText(GARRISON_MISSION_PERCENT_CHANCE,perc)
				panel.Percent:SetTextColor(q.r,q.g,q.b)
				panel.NumMembers:SetFormattedText(GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS,numFollowers)
				panel:Show()
				if (i>= MAXMISSIONS) then break end
			end
		end
		del(partyIndex)
		del(index)
	until true
	if (i>0) then
		GCFBusyStatus:SetPoint("TOPLEFT",GCFMissions.Missions[i],"BOTTOMLEFT",0,-5)
	else
		GCFBusyStatus:SetPoint("TOPLEFT",GCFMissions.Header,"BOTTOMLEFT",0,-5)
	end
	i=i+1
	for x=i,#GCFMissions.Missions do GCFMissions.Missions[x]:Hide() end
end
---
--Initial one time setup
function addon:SetUp(...)
--@debug@
	xprint("Setup")
--@end-debug@
	SIZEV=GMF:GetHeight()
	self:CheckMP()
	self:CheckGMM()
	self:Options()
	self:GenerateMissionsWidgets()
	self:GMCBuildPanel()
	local tabMC=CreateFrame("CheckButton",nil,GMF,"SpellBookSkillLineTabTemplate")
	tabMC.tooltip="Open Garrison Commander Mission Control"
	--tab:SetNormalTexture("World\\Dungeon\\Challenge\\clockRunes.blp")
	--tab:SetNormalTexture("Interface\\Timer\\Challenges-Logo.blp")
	tabMC:SetNormalTexture("Interface\\ICONS\\ACHIEVEMENT_GUILDPERK_WORKINGOVERTIME.blp")
	tabMC:Show()
	GMC.tabMC=tabMC
	local tabCF=CreateFrame("Button",nil,GMF,"SpellBookSkillLineTabTemplate")
	tabCF.tooltip="Open Garrison Commander Configuration Screen"
	tabCF:SetNormalTexture("Interface\\ICONS\\Trade_Engineering.blp")
	tabCF:SetPushedTexture("Interface\\ICONS\\Trade_Engineering.blp")
	tabCF:Show()
	local tabHP=CreateFrame("Button",nil,GMF,"SpellBookSkillLineTabTemplate")
	tabHP.tooltip="Open Garrison Commander Help"
	tabHP:SetNormalTexture("Interface\\ICONS\\INV_Misc_QuestionMark.blp")
	tabHP:SetPushedTexture("Interface\\ICONS\\INV_Misc_QuestionMark.blp")
	tabHP:Show()
	tabMC:SetScript("OnClick",function(this,...) addon:ShowMissionControl() end)
	tabCF:SetScript("OnClick",function(this,...) addon:Gui() end)
	tabHP:SetScript("OnClick",function(this,button) addon:ShowHelpWindow(this,button) end)
	tabHP:SetPoint('TOPLEFT',GCF,'TOPRIGHT',0,-10)
	tabCF:SetPoint('TOPLEFT',GCF,'TOPRIGHT',0,-60)
	tabMC:SetPoint('TOPLEFT',GCF,'TOPRIGHT',0,-110)
	self:StartUp()
	collectgarbage("step",10)
--/Interface/FriendsFrame/UI-Toast-FriendOnlineIcon
end
---
-- Additional setup
-- This method is called every time garrison mission panel is open because
-- when it closes, I remove most of used hooks
function addon:StartUp(...)
--@debug@
	xprint("Startup")
--@end-debug@
	self:Unhook(GMF,"OnShow")
	self:PermanentEvents()
	GCF.Menu=self:CreateOptionsLayer(MP and 'CKMP' or nil,'BIGSCREEN','MOVEPANEL','IGM','IGP','NOFILL')
	self:AddOptionToOptionsLayer(GCF.Menu,'MSORT',200)
	self:AddOptionToOptionsLayer(GCF.Menu,'ShowMissionControl',200)
--@debug@
	self:AddOptionToOptionsLayer(GCF.Menu,'DBG')
--@end-debug@
	GCF.Menu:SetParent(GCF)
	GCF.Menu:SetFrameStrata(GCF:GetFrameStrata())
	GCF.Menu:SetFrameLevel(GCF:GetFrameLevel()+1)
	GCF.Menu.frame:SetScale(0.6)
	GCF.Menu:SetPoint("TOPLEFT",GCF,"TOPLEFT",25,-25)
	GCF.Menu:SetPoint("BOTTOMRIGHT",GCF,"BOTTOMRIGHT",-25,25)
	GCF.Menu:Show()
	self:GrowPanel()
	self:SafeSecureHook("GarrisonMissionButton_AddThreatsToTooltip")
	self:SafeSecureHook("GarrisonMissionButton_SetRewards")
	if (bigscreen) then
		self:SafeSecureHook("GarrisonFollowerListButton_OnClick")--,function(...) xprint("GarrisonFollowerListButton_OnClick",...) end)
		self:SafeSecureHook("GarrisonFollowerPage_ShowFollower")--,function(...) xprint("GarrisonFollowerPage_ShowFollower",...) end)
		self:SafeSecureHook("GarrisonFollowerTooltipTemplate_SetGarrisonFollower")
	end
	self:SafeSecureHook("GarrisonMissionFrame_HideCompleteMissions")	-- Mission reward completed
	self:SafeSecureHook("GarrisonMissionPage_ShowMission")
	self:SafeSecureHook("GarrisonMissionList_UpdateMissions")
	self:SafeSecureHook("GarrisonMissionFrame_SelectTab")

	self:SafeHookScript(GMFMissions,"OnShow")--,"GrowPanel")
	self:SafeHookScript(GMFFollowers,"OnShow")--,"GrowPanel")
	self:SafeHookScript(GCF,"OnHide","CleanUp",true)
	-- Follower button enhancement in follower list
	self:SafeSecureHook("GarrisonFollowerButton_UpdateCounters")
	-- Mission management
	self:SafeHookScript(GMF.MissionComplete.NextMissionButton,"OnClick","OnClick_GarrisonMissionFrame_MissionComplete_NextMissionButton",true)
	self:SafeSecureHook("GarrisonMissionFrame_ShowCompleteMissions")
	self:SafeSecureHook("GarrisonMissionFrame_CheckCompleteMissions")
	self:SafeSecureHook("MissionCompletePreload_LoadMission")
	-- Hooking mission buttons on click
	for i=1,#GMFMissionListButtons do
		local b=GMFMissionListButtons[i]
		self:SafeHookScript(b,"OnClick","OnClick_GarrisonMissionButton",true)
	end
	self:ScheduleRepeatingTimer("Clock",1)
	self:BuildMissionsCache(true,true)
	self:BuildRunningMissionsCache()
	self:Trigger("MSORT")
end
-- probably not really needed, haven seen yet them firing out of garrison
function addon:PermanentEvents()
	self:SafeRegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE")
	self:SafeRegisterEvent("GARRISON_MISSION_STARTED")
	self:SafeRegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE")
	self:SafeRegisterEvent("GARRISON_MISSION_NPC_CLOSED")
	self:SafeRegisterEvent("GARRISON_FOLLOWER_XP_CHANGED")
	self:SafeRegisterEvent("GARRISON_FOLLOWER_ADDED")
	self:SafeRegisterEvent("GARRISON_FOLLOWER_REMOVED")
	self:RegisterBucketEvent("GARRISON_MISSION_LIST_UPDATE",2,"EventGARRISON_MISSION_LIST_UPDATE")

--@debug@
	self:DebugEvents()
--@end-debug@
end
function addon:DebugEvents()
	self:SafeRegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE") -- Should be used only when has true as parameter
	self:SafeRegisterEvent("GARRISON_MISSION_BONUS_ROLL_LOOT")
	self:SafeRegisterEvent("GARRISON_MISSION_FINISHED")
	self:SafeRegisterEvent("GARRISON_UPDATE")
	self:SafeRegisterEvent("GARRISON_USE_PARTY_GARRISON_CHANGED")
	self:SafeRegisterEvent("GARRISON_MISSION_NPC_OPENED")
end
function addon:checkMethod(method,hook)
	if (type(self[method])=="function") then
--@debug@
		--xprint("Hooking ",hook,"to self:" .. method)
--@end-debug@
		return true
--@debug@
	else
		--xprint("Hooking ",hook,"to print")
--@end-debug@
	end
end
function addon:SafeRegisterEvent(event)
	local method="Event"..event
	if (self:checkMethod(method,event)) then
		return self:RegisterEvent(event,method)
--@debug@
	else
		return self:RegisterEvent(event,xprint)
--@end-debug@
	end
end
function addon:SafeSecureHook(tobehooked,method)
	method=method or "Hooked"..tobehooked
	if (self:checkMethod(method,tobehooked)) then
		return self:SecureHook(tobehooked,method)
--@debug@
	else
		do
			local hooked=tobehooked
			return self:SecureHook(tobehooked,function(...) print(hooked,...) end)
		end
--@end-debug@
	end
end
function addon:SafeHookScript(frame,hook,method,postHook)
	local name="Unknown"
	if (type(frame)=="string") then
		name=frame
		frame=_G[frame]
	else
		if (frame and frame.GetName) then
			name=frame:GetName()
		end
	end
	if (frame) then
		if (method) then
			if (postHook) then
				self:SecureHookScript(frame,hook,method)
			else
				self:HookScript(frame,hook,method)
			end
		else
			if (postHook) then
				self:SecureHookScript(frame,hook,function(...) self:ScriptTrace(name,hook,...) end)
			else
				self:HookScript(frame,hook,function(...) self:ScriptTrace(name,hook,...) end)
			end
		end
	end
end

function addon:CleanUp()
	self:UnhookAll()
	self:CancelAllTimers()
	GCF.Menu:Release()
	self:HookScript(GMF,"OnSHow","StartUp",true)
	self:PermanentEvents() -- Reattaching permanent events
	if (GarrisonFollowerTooltip.fs) then
		GarrisonFollowerTooltip.fs:Hide()
	end
	collectgarbage("collect")
--@debug@
	xprint("Cleaning up")
--@end-debug@
end
function addon:EventGARRISON_FOLLOWER_XP_CHANGED(event,followerID,iLevel,xp,level,quality)
	local i=followersCacheIndex[followerID]
	if (i) then
		local follower=followersCache[i]
		if follower and follower.checkID and follower.checkID==followerID then
			follower.iLevel=iLevel
			follower.xp=xp
			follower.level=level
			follower.quality=quality
			follower.rank=follower.level==100 and follower.iLevel or follower.level
			follower.coloredname=C(follower.name,tostring(follower.quality))
			follower.fullname=format("%3d %s",follower.rank,follower.coloredname)
			follower.maxed=follower.quality >= GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY and follower.level >=GARRISON_FOLLOWER_MAX_LEVEL
			return -- single updated
		end
	end
	wipe(followersCache)
	self:GetFollowerData(followerID)  -- triggering a full cache refresh
end

function addon:GetFollowerData(key,subkey)
	local k=followersCacheIndex[key]
	if (not followersCache[1]) then
		followersCache=G.GetFollowers()
		for i,follower in pairs(followersCache) do
			if (not follower.isCollected) then
				followersCache[i]=nil
			else
			follower.rank=follower.level==100 and follower.iLevel or follower.level
			follower.coloredname=C(follower.name,tostring(follower.quality))
			follower.fullname=format("%3d %s",follower.rank,follower.coloredname)
			follower.maxed=follower.quality >= GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY and follower.level >=GARRISON_FOLLOWER_MAX_LEVEL
			end
		end
	end
	local t=followersCache
	if (not k) then
		for i=1,#t do
			if (t[i] and (t[i].followerID == key or t[i].name==key)) then
				followersCacheIndex[t[i].followerID]=i
				followersCacheIndex[t[i].name]=i
				k=i
				break
			end
		end
	end
	if (k) then
		if (subkey) then
			return t[k][subkey]
		else
			return t[k]
		end
	else
		return nil
	end
end
function addon:GetMissionData(missionID,subkey)
	local missionCache=cache.missions[missionID]
	if (not missionCache) then
--@debug@
		xprint("Found a new mission",missionID,G.GetMissionName(missionID),"Refreshing it")
--@end-debug@
		self:BuildMissionCache(missionID)
		self:FillCounters(missionID,cache.missions[missionID])
		self:MatchMaker(missionID,cache.missions[missionID])
	end
	if not missionCache then return end
	if (subkey) then
		return missionCache[subkey]
	end
	return missionCache
end
function addon:GetFollowerStatusForMission(followerID,skipbusy)
	if (GMCUsedFollowers[followerID]) then
		return false
	end
	if (not skipbusy) then
		return true
	else
		return self:GetFollowerStatus(followerID) == AVAILABLE
	end
end
function addon:GetFollowerStatus(followerID,withTime,colored)
	local status=G.GetFollowerStatus(followerID)
	if (status and status== GARRISON_FOLLOWER_ON_MISSION and withTime) then
		local running=dbcache.running[dbcache.runningIndex[followerID]]
		status=SecondsToTime(running.started + running.duration - time() ,true)
	end
-- The only case a follower appears in party is after a refused mission due to refresh triggered before GARRISON_FOLLOWER_LIST_UPDATE
	if (status and status~=GARRISON_FOLLOWER_IN_PARTY) then
		return colored and C(status,"Red") or status
	else
		return colored and C(AVAILABLE,"Green") or AVAILABLE
	end
end
function addon:FillMissionPage(missionInfo)
	if( IsControlKeyDown()) then xprint("Shift key, ignoring mission prefill") return end
	if (self:GetBoolean("NOFILL")) then return end
	local missionID=missionInfo.missionID
--@debug@
	xprint("UpdateMissionPage for",missionID,missionInfo.name,missionInfo.numFollowers)
--@end-debug@
	--xdump(missionInfo)
	--self:BuildMissionData(missionInfo.missionID.missionInfo)
	GarrisonMissionPage_ClearParty()
	local party=parties[missionID]
	if (party) then
		local members=party.members
		for i=1,missionInfo.numFollowers do
			local followerID=members[i]
			if (followerID) then
				if false then
				local info=self:GetFollowerData(followerID)
--@debug@
				xprint("Adding follower",info.name)
--@end-debug@
				GarrisonMissionPage_SetFollower(GMFMissionPageFollowers[i],info)
				else
					GarrisonMissionPage_AddFollower(followerID)
				end
			end
		end
	end
	GarrisonMissionPage_UpdateMissionForParty()
end
local firstcall=true

---@function GrowPanel
-- Enforce the new panel sizes
--
function addon:GrowPanel()
	GCF:Show()
	if (bigscreen) then
--		GMF:ClearAllPoints()
--		GMF:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT")
--		GMF:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT")
		GMFRewardSplash:ClearAllPoints()
		GMFRewardSplash:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT")
		GMFRewardSplash:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT")
		GMFRewardPage:ClearAllPoints()
		GMFRewardPage:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT")
		GMFRewardPage:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT")
		GMF:SetHeight(BIGSIZEH)
		GMFMissions:SetPoint("BOTTOMRIGHT",GMF,-25,35)
		GMFFollowers:SetPoint("BOTTOMLEFT",GMF,-35,65)
		GMFMissionsListScrollFrameScrollChild:ClearAllPoints()
		GMFMissionsListScrollFrameScrollChild:SetPoint("TOPLEFT",GMFMissionsListScrollFrame)
		GMFMissionsListScrollFrameScrollChild:SetPoint("BOTTOMRIGHT",GMFMissionsListScrollFrame)
		GMFFollowersListScrollFrameScrollChild:SetPoint("BOTTOMLEFT",GMFFollowersListScrollFrame,-35,35)
		GMF.MissionCompleteBackground:SetWidth(BIGSIZEW)
	else
		GCF:SetWidth(GMF:GetWidth())
--		GMF:ClearAllPoints()
--		GMF:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT",0,-25)
--		GMF:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT",0,-25)
	end
	GMF:ClearAllPoints()
	GMF:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT",0,25)
	GMF:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT",0,25)
	GMF.CloseButton:SetAllPoints(GCF.CloseButton)
	GCF.CloseButton:Hide()
end
---@function
-- Return bias color for follower and mission
-- @param #number bias bias as returned by blizzard interface [optional]
-- @param #string followerID
-- @param #number missionID
function addon:GetBiasColor(followerID,missionID,goodcolor)
	goodcolor=goodcolor or "White"
	local bias=followerID or 0
	if (missionID) then
		local rc,followerBias = pcall(G.GetFollowerBiasForMission,missionID,followerID)
		if (not rc) then
			return goodcolor
		else
			bias=followerBias
		end
	end
	if not tonumber(bias) then return "Yellow" end
	if (bias==-1) then
		return "Red"
	elseif (bias < 0) then
		return "Orange"
	end
	return goodcolor
end
function addon:FillFollowerButton(frame,followerID,missionID)
	if (not frame) then return end
	if (frame.Threats) then
		for i=1,#frame.Threats do
			if (frame.Threats[i]) then frame.Threats[i]:Hide() end
		end
		frame.NotFull:Hide()
	end
	if (not followerID) then
		frame.PortraitFrame.Empty:Show()
		if (frame.Name) then
			frame.Name:Hide()
			frame.Class:Hide()
			frame.Status:Hide()
		end
		frame.PortraitFrame.LevelBorder:SetAtlas("GarrMission_PortraitRing_LevelBorder");
		frame.PortraitFrame.LevelBorder:SetWidth(58);
		frame.PortraitFrame.Level:SetText("")
		--frame:SetScript("OnEnter",nil)
		GarrisonFollowerPortrait_Set(frame.PortraitFrame.Portrait)
		frame.info=nil
		return
	end
	local info=G.GetFollowerInfo(followerID)
	--local info=followers[ID]
	frame.info=info
	frame.missionID=missionID
	if (frame.Name) then
		frame.Name:Show()
		frame.Name:SetText(info.name);
		local color=missionID and self:GetBiasColor(followerID,missionID,"White") or "Yellow"
		frame.Name:SetTextColor(C[color]())
		frame.Status:SetText(self:GetFollowerStatus(followerID,true,true))
		frame.Status:Show()
	end
	if (frame.Class) then
		frame.Class:Show();
		frame.Class:SetAtlas(info.classAtlas);
	end
	frame.PortraitFrame.Empty:Hide();

	local showItemLevel;
	if (info.level == GarrisonMissionFrame.followerMaxLevel ) then
		frame.PortraitFrame.LevelBorder:SetAtlas("GarrMission_PortraitRing_iLvlBorder");
		frame.PortraitFrame.LevelBorder:SetWidth(70);
		showItemLevel = true;
	else
		frame.PortraitFrame.LevelBorder:SetAtlas("GarrMission_PortraitRing_LevelBorder");
		frame.PortraitFrame.LevelBorder:SetWidth(58);
		showItemLevel = false;
	end
	GarrisonMissionFrame_SetFollowerPortrait(frame.PortraitFrame, info, showItemLevel);
	-- Counters icon
	if (frame.Name) then
		if (missionID and not GMF.MissionTab.MissionList.showInProgress) then
			local tohide=1
			local missionCounters=counters[missionID]
			local index=counterFollowerIndex[missionID][followerID]
			for i=1,#index do
				local k=index[i]
				local t=frame.Threats[i]
				local tx=missionCounters[k].icon
				t.Icon:SetTexture(tx)
				local color=self:GetBiasColor(missionCounters[k].bias,nil,"Green")
				t.Border:SetVertexColor(C[color]())
				t:Show()
				tohide=i+1
			end
		else
			frame.Status:Hide()
		end
	end
end
-- pseudo static
local scale=0.9
local BFBCount=0
function addon:BuildFollowersButtons(button,bg,limit)
	if (bg.Party) then return end
	bg.Party={}
	for numMembers=1,3 do
		local f=CreateFrame("Button",nil,bg,bigscreen and "GarrisonCommanderMissionPageFollowerTemplate" or "GarrisonCommanderMissionPageFollowerTemplateSmall" )
		if (numMembers==1) then
			f:SetPoint("BOTTOMLEFT",button.Rewards[1],"BOTTOMRIGHT",10,0)
		else
			if (bigscreen) then
				f:SetPoint("LEFT",bg.Party[numMembers-1],"RIGHT",10,0)
			else
				f:SetPoint("LEFT",bg.Party[numMembers-1],"LEFT",65,0)
			end
		end
		tinsert(bg.Party,f)
		f:EnableMouse(true)
		f:SetScript("OnEnter",GarrisonMissionPageFollowerFrame_OnEnter)
		f:SetScript("OnLeave",GarrisonMissionPageFollowerFrame_OnLeave)
		f:RegisterForClicks("AnyUp")
		f:SetScript("OnClick",function(...) self:OnClick_PartyMember(...) end)
		if (bigscreen) then
			for numThreats=1,4 do
				local threatFrame =f.Threats[numThreats];
				if ( not threatFrame ) then
					threatFrame = CreateFrame("Frame", nil, f, "GarrisonAbilityCounterTemplate");
					threatFrame:SetPoint("LEFT", f.Threats[numThreats - 1], "RIGHT", 10, 0);
					tinsert(f.Threats, threatFrame);
				end
				threatFrame:Hide()
			end
		end
	end
	for i=1,3 do bg.Party[i]:SetScale(0.9) end
	-- Making room for both GC and MP
	if (button.Expire) then
		button.Expire:ClearAllPoints()
		button.Expire:SetPoint("TOPRIGHT")
	end
	if (button.Threats and button.Threats[1]) then
		button.Threats[1]:ClearAllPoints()
		button.Threats[1]:SetPoint("TOPLEFT",165,0)
	end
	BFBCount=BFBCount+1
	if (BFBCount > 8) then print ("OPS BFBcount=",BFBCount) end

end
function addon:RenderExtraButton(button,numRewards)
	local panel=button.gcINDICATOR
	local missionInfo=button.info
	local missionID=missionInfo.missionID
	panel.missionID=missionID
	local mission=self:GetMissionData(missionID)
	if not mission then return end -- something went wrong while refreshing
	if (not bigscreen) then
		local index=mission.numFollowers+numRewards-3
		local position=(index * -65) - 130
		button.gcPANEL.Party[1]:ClearAllPoints()
		button.gcPANEL.Party[1]:SetPoint("BOTTOMLEFT",button.Rewards[1],"BOTTOMLEFT", position,0)
	end
	if (GMF.MissionTab.MissionList.showInProgress) then
		local perc=select(4,G.GetPartyMissionInfo(missionID))
		panel.Percent:SetFormattedText(GARRISON_MISSION_PERCENT_CHANCE,perc)
		panel.Age:Hide()
		local q=self:GetDifficultyColor(perc)
		panel.Percent:SetTextColor(q.r,q.g,q.b)
		for i=1,3 do
			local frame=button.gcPANEL.Party[i]
			if (missionInfo.followers[i]) then
				self:FillFollowerButton(frame,missionInfo.followers[i],missionID)
				frame:Show()
			else
				frame:Hide()
			end
		end
		return
	end
	local party=parties[missionID]
	if (#party.members==0) then
		self:FillCounters(missionID,mission)
		self:MatchMaker(missionID,mission,party)
	end
	local perc=party.perc
	local age=tonumber(dbcache.seen[missionID])
	local notFull=false
	for i=1,3 do
		local frame=button.gcPANEL.Party[i]
		if (i>mission.numFollowers) then
			frame:Hide()
		else
			if (party.members[i]) then
				self:FillFollowerButton(frame,party.members[i],missionID)
				if (bigscreen) then frame.NotFull:Hide() end
			else
				self:FillFollowerButton(frame,false)
				if (bigscreen) then frame.NotFull:Show() end
			end
			frame:Show()
		end
	end
	panel=button.gcINDICATOR
	panel.Percent:SetFormattedText(GARRISON_MISSION_PERCENT_CHANCE,perc)
	local q=self:GetDifficultyColor(perc)
	panel.Percent:SetTextColor(q.r,q.g,q.b)
	panel.Percent:SetWidth(80)
	panel.Percent:SetJustifyH("RIGHT")
	if (age) then
		local expire=ns.wowhead[missionID]
		if expire then expire=expire.cd else expire =9999999 end
		if (expire==9999999) then
			panel.Age:SetText("Expires: Far far away")
			panel.Age:SetTextColor(C.White())
		elseif (expire==0) then
			panel.Age:SetText("Expires: " .. UNKNOWN)
			panel.Age:SetTextColor(C.White())
		else
			local age=(age+expire-time())/60
			if age < 0 then age=0 end
			local hours=(floor((age/60)/6)+1)*6
			local q=self:GetDifficultyColor(hours+20,true)
			panel.Age:SetFormattedText("Expires in less than %d hr",hours)
			panel.Age:SetTextColor(q.r,q.g,q.b)
		end
	else
		panel.Age:SetText(UNKNOWN)
	end
	panel.Age:Show()
	panel.Percent:Show()
end
function addon:CheckExpire(missionID)
	local age=tonumber(dbcache.seen[missionID])
	local expire=ns.wowhead[missionID].cd
	print("Age",date("%m/%d/%y %H:%M:%S",age))
	print("Now",date("%m/%d/%y %H:%M:%S"))
	print("Expire",expire,ns.expire[missionID])
	print("Age+expire",date("%m/%d/%y %H:%M:%S",age+expire))
	print("Delta",age+expire-time())
end
local BEXCount=0
function addon:BuildExtraButton(button)
	local bg=CreateFrame("Button",nil,button,"GarrisonCommanderMissionButton")
	local indicators=CreateFrame("Frame",nil,button,"GarrisonCommanderIndicators")
	indicators:SetPoint("LEFT",70,0)
	bg:SetPoint("RIGHT")
	bg.button=button
	bg:SetScript("OnEnter",function(this) GarrisonMissionButton_OnEnter(this.button) end)
	bg:SetScript("OnLeave",function() GameTooltip:FadeOut() end)
	bg:RegisterForClicks("AnyUp")
	bg:SetScript("OnClick",function(...) self:OnClick_GCMissionButton(...) end)
	button.gcPANEL=bg
	button.gcINDICATOR=indicators
	if (not bg.Party) then self:BuildFollowersButtons(button,bg,3) end
	BEXCount=BEXCount+1
	if (BEXCount > 8) then print ("OPS Bexcount=",BEXCount) end
end
--function addon:GarrisonMissionButton_SetRewards(button,rewards,numrewards)
--end
do
	local menuFrame = CreateFrame("Frame", "GCFollowerDropDOwn", nil, "UIDropDownMenuTemplate")
	local func=function(...) addon:IgnoreFollower(...) end
	local func2=function(...) addon:UnignoreFollower(...) end
	local menu= {
	{ text="Follower", notClickable=true,notCheckable=true,isTitle=true },
	{ text=L["Ignore for this mission"],checked=false, func=func, arg1=0, arg2="none"},
--	{ text=L["Ignore for all missions"],checked=false, func=func, arg1=0, arg2="none"},
	{ text=L["Consider again"], notClickable=true,notCheckable=true,isTitle=true },
	}
	function addon:OnClick_PartyMember(frame,button,down,...)
		local followerID=frame.info and frame.info.followerID or nil
		local missionID=frame.missionID
		if (not followerID) then return end
		if (button=="LeftButton") then
			self:OpenFollowersTab()
			GMF.selectedFollower=followerID
			if (GMF.FollowerTab) then
				GarrisonFollowerPage_ShowFollower(GMF.FollowerTab,followerID)
			end
		else
		local ignore=self.privatedb.profile.ignored

			menu[1].text=frame.info.name
			menu[2].arg1=missionID
			menu[2].arg2=followerID
			--menu[3].arg2=followerID
			local i=4
			for k,r in pairs(dbcache.ignored[missionID]) do
				if (r) then
					local v=menu[i] or {}
					v.text=self:GetFollowerData(k,'name')
					v.func=func2
					v.arg1=missionID
					v.arg2=k
					menu[i]=v
					i=i+1
				else
					dbcache.ignored[missionID]=nil
				end
			end
			if (i>4) then
				i=i+1
				menu[i]={text=ALL,func=func2,arg1=missionID,arg2='all'}
			end
			for x=#menu,i,-1 do tremove(menu) end
			EasyMenu(menu,menuFrame,"cursor",0,0,"MENU",5)
		end

	end
end
function addon:IgnoreFollower(table,missionID,followerID,flag)
	if (missionID==0) then
		dbcache.totallyignored[followerID]=true
	else
		dbcache.ignored[missionID][followerID]=true
	end
	-- full ignore disabled for now
	dbcache.totallyignored[followerID]=nil
	self:RefreshMission(missionID)
end
function addon:UnignoreFollower(table,missionID,followerID,flag)
	if (followerID=='all') then
		wipe(dbcache.ignored[missionID])
	else
		dbcache.ignored[missionID][followerID]=nil
	end
	self:RefreshMission(missionID)
end
function addon:OpenFollowersTab()
	GarrisonMissionFrame_SelectTab(2)
end
function addon:OpenMissionsTab()
	GarrisonMissionFrame_SelectTab(1)
end
function addon:OnClick_GarrisonMissionFrame_MissionComplete_NextMissionButton(this,button)
	local frame = GMF.MissionComplete
	if (not frame:IsShown()) then
		self:Trigger("MSORT")
	end
end
function addon:OnClick_GarrisonMissionButton(tab,button)
	if (GMF.MissionTab.MissionList.showInProgress) then
		return
	end
--@debug@
	xprint("Clicked GarrisonMissionButto")
--@end-debug@
	if (tab.fromFollowerPage) then
		GarrisonMissionFrame_SelectTab(1)
		self:FillMissionPage(tab.info)
	else
--@debug@
		xdump(tab.info)
--@end-debug@
		self:FillMissionPage(tab.info)
	end
end
function addon:OnClick_GCMissionButton(frame,button)
	if (button=="RightButton") then
		self:HookedGarrisonMissionButton_SetRewards(frame:GetParent(),{},0)
	else
		frame.button:Click()
	end
end

function addon:HookedGarrisonMissionButton_SetRewards(button,rewards,numRewards)
	self:RenderButton(button,rewards,numRewards)
end
function addon:RenderButton(button,rewards,numRewards)
	if (not button or not button.Title) then
--@debug@
		error(strconcat("Called on I dunno what ",tostring(button)," ", tostring(button:GetName())))
		return
--@end-debug@
	end
	local missionID=button.info.missionID
	--if (GMF.MissionTab.MissionList.showInProgress) then return end
	if (bigscreen) then
		local width=GMF.MissionTab.MissionList.showInProgress and BIGBUTTON or SMALLBUTTON
		button:SetWidth(width+600)
		button.Rewards[1]:SetPoint("RIGHT",button,"RIGHT",-500 - (GMM and 40 or 0),0)
	end
	local tw=button:GetWidth() - 165 - 2  + select(4,button.Rewards[1]:GetPoint(1))
	if (not button.xp) then
		button.xp=button:CreateFontString(nil, "ARTWORK", "QuestMaprewardsFont")
		button.xp:SetPoint("TOPRIGHT",button.Rewards[1],"TOPRIGHT")
		button.xp:SetJustifyH("RIGHT")
		button.xp:Show()

	end
	button.MissionType:SetPoint("TOPLEFT",5,-2)
	button.xp:SetWidth(0)
	if (not GMF.MissionTab.MissionList.showInProgress) then
		button.xp:SetFormattedText("Xp: %d (approx)",self:GetMissionData(missionID,'globalXp'))
		button.xp:SetTextColor(self:GetDifficultyColors(self:GetMissionData(missionID,'totalXp')/3000*100))
	end
	--button.Title:SetText("123456789012345678901234567890123456789012345678901234567890") -- Used for design
	if (button.Title:GetWidth() + button.Summary:GetWidth() + button.xp:GetWidth() < tw - numRewards * 65 ) then
		button.Title:SetPoint("LEFT", 165, bigscreen and 20 or 30);
		button.Summary:ClearAllPoints();
		button.Summary:SetPoint("BOTTOMLEFT", button.Title, "BOTTOMRIGHT", 8, 0);
	else
		button.Title:SetPoint("LEFT", 165, 30);
		button.Title:SetWidth(tw - numRewards * 65);
		button.Summary:ClearAllPoints();
		button.Summary:SetPoint("TOPLEFT", button.Title, "BOTTOMLEFT", 0, -4);
	end
	local threatIndex=1
	if (not GMF.MissionTab.MissionList.showInProgress) then
		if (not button.Threats) then -- I am a good guy. If MP present, I dont make my own threat indicator (Only MP <= 1.8)
			if (not button.Env) then
				button.Env=CreateFrame("Frame",nil,button,"GarrisonAbilityCounterTemplate")
				button.Env:SetWidth(20)
				button.Env:SetHeight(20)
				button.Env:SetPoint("BOTTOMLEFT",button,165,8)
				button.GcThreats={}
			end
			local slots=self:GetMissionData(missionID,'slots')
			if (not GMF.MissionTab.MissionList.showInProgress) then
				button.Env:Show()
				if (dbg) then self:DumpParty(missionID) end
				for i=1,#slots do
					local slot=slots[i]
					if (slot.name==TYPE) then
						button.Env.Icon:SetTexture(slot.icon)
						self:SetThreatColor(button.Env,missionID)
						button.Env.info=self.db.global.types[slot.key]
						button.Env:SetScript("OnEnter",function(...) addon:ClonedGarrisonMissionMechanic_OnEnter(missionID,...) end)
						button.Env:SetScript("OnLeave",function() GameTooltip:Hide() end)
					else
						local th=button.GcThreats[threatIndex]
						if (not th) then
							th=CreateFrame("Frame",nil,button,"GarrisonAbilityCounterTemplate")
							th:SetWidth(20)
							th:SetHeight(20)
							th:SetPoint("BOTTOMLEFT",button,165 + 35 * threatIndex,8)
							button.GcThreats[threatIndex]=th
						end
						th.info=slot
						threatIndex=threatIndex+1
						th.Icon:SetTexture(slot.icon)
						self:SetThreatColor(th,missionID)
						th:Show()
						th:SetScript("OnEnter",function(...) addon:ClonedGarrisonMissionMechanic_OnEnter(missionID,...) end)
						th:SetScript("OnLeave",function() GameTooltip:Hide() end)
					end
				end
			else
				button.Env:Hide()
			end
		end
	else
		if (button.Env) then button.Env:Hide() end
	end
	if (button.GcThreats) then
		for i=threatIndex,#button.GcThreats do
			button.GcThreats[i]:Hide()
		end
	end
	if (numRewards > 0) then
		local index=1
		for id,reward in pairs(rewards) do
			local Reward = button.Rewards[index];
			Reward.Quantity:SetTextColor(C.Yellow())
			if (reward.followerXP) then
				Reward.Quantity:SetText(reward.followerXP)
				Reward.Quantity:Show()
			elseif (reward.currencyID==0) then
				Reward.Quantity:SetFormattedText("%d",reward.quantity/10000)
				Reward.Quantity:Show()
			elseif (reward.itemID and reward.itemID==120205) then
				Reward.Quantity:SetFormattedText("%d",self:GetMissionData(missionID,'xp') or 1)
				Reward.Quantity:Show()
			elseif (reward.itemID and reward.quantity==1) then
				local _,_,q,i=GetItemInfo(reward.itemID)
				Reward.Quantity:SetText(i)
				local c=ITEM_QUALITY_COLORS[q]
				if (not c) then
					Reward.Quantity:SetTextColor(1,1,1)
				else
					Reward.Quantity:SetTextColor(c.r,c.g,c.b)
				end
				Reward.Quantity:Show()
			end
			index=index+1
		end
	end
	if (button.fromFollowerPage) then
		--button.Title:ClearAllPoints()
		--button.Title:SetPoint("TOPLEFT",165,-5)
		--button.Summary:ClearAllPoints()
		--button.Summary:SetPoint("BOTTOMLEFT",165,5)
		--button:SetHeight(70)
		return
	end
	if (not button.gcPANEL) then
		self:BuildExtraButton(button)
	end
	self:RenderExtraButton(button,numRewards)
end

--@do-not-package@
_G.GAC=addon
--[[

GMFMissions.CompleteDialog.BorderFrame.CompleteAll
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




GarrisonMissionFrameMissionsListScrollFrameButtonx.info:
Dump: value=GarrisonMissionFrameMissionsListScrollFrameButton1.info
[1]={
	description="In a remote corner of Talador, a small faction of draenei has embraced the worship of Sargeras. Stop their cult before it spreads.",
	cost=10,
	duration="4 hr",
	durationSeconds=14400,
	level=100,
	type="Combat",
	locPrefix="GarrMissionLocation-Talador",
	rewards={
		[290]={
			title="Money Reward",
			quantity=600000,
			icon="Interface\\Icons\\inv_misc_coin_01",
			currencyID=0
		}
	},
	numRewards=1,
	numFollowers=2,
	state=-2,
	iLevel=0,
	name="Cult of Sargeras",
	followers={
	},
	location="Talador",
	isRare=false,
	typeAtlas="GarrMission_MissionIcon-Combat",
	missionID=126
}
Dump: value=G.GetFollowerInfo("0x000000000002F5E1")
[1]={
	displayHeight=0.5,
	iLevel=600,
	scale=0.60000002384186,
	classAtlas="GarrMission_ClassIcon-Druid",
	garrFollowerID="0x0000000000000022",
	displayScale=1,
	status="On Mission",
	level=100,
	quality=4,
	portraitIconID=1066112,
	isFavorite=false,
	xp=0,
	className="Guardian Druid",
	classSpec=8,
	name="Qiana Moonshadow",
	followerID="0x000000000002F5E1",
	height=1.3999999761581,
	displayID=55047,
	levelXP=0,
	isCollected=true
}
value=GarrisonMissionFrame.MissionTab.MissionList.availableMissions[13]
[1]={
	description="Scouts report a many-headed beast named Festerbloom waylaying travelers crossing the Murkbog.  Clear the path for everyone's sake.",
	cost=20,
	duration="10 hr",
	durationSeconds=36000,
	level=96,
	type="Combat",
	locPrefix="GarrMissionLocation-SpiresofArak",
	rewards={
		[778]={
			title="Bonus Follower XP",
			followerXP=1400,
			tooltip="+1,400 XP",
			icon="Interface\\Icons\\XPBonus_Icon",
			name="+1,400 XP"
		}
	},
	numRewards=1,
	numFollowers=3,
	state=-2,
	iLevel=0,
	name="Murkbog Terror",
	followers={
	},
	location="Spires of Arak",
	isRare=false,
	typeAtlas="GarrMission_MissionIcon-Combat",
	missionID=374
}
Dump: value=GarrisonMissionFrame.MissionTab.MissionList.inProgressMissions
[1]={
	description="The voidlords and voidcallers plaguing Shadowmoon Valley are being summoned by someone. Find and kill whoever is responsible.",
	cost=15,
	duration="6 hr",
	durationSeconds=21600,
	level=100,
	timeLeft="1 hr 12 min",
	type="Combat",
	inProgress=true,
	locPrefix="GarrMissionLocation-ShadowmoonValley",
	rewards={
		[251]={
			title="Bonus Follower XP",
			followerXP=8000,
			tooltip="+8,000 XP",
			icon="Interface\\Icons\\XPBonus_Icon",
			name="+8,000 XP"
		}
	},
	numRewards=1,
	numFollowers=3,
	state=-1,
	iLevel=0,
	name="Twisting the Nether",
	followers={
		[1]="0x000000000002F5E1",
		[2]="0x0000000000079D62",
		[3]="0x00000000001307EF"
	},
	location="Shadowmoon Valley",
	isRare=false,
	typeAtlas="GarrMission_MissionIcon-Combat",
	missionID=114
}
Dump: value=G.GetMissionInfo(119)
local location, xp, environment, environmentDesc, environmentTexture, locPrefix, isExhausting, enemies = C_Garrison.GetMissionInfo(missionID);
[1]="Nagrand",
[2]=1500,
[3]="Orc",
[4]="Lok'tar ogar!",
[5]="Interface\\ICONS\\Achievement_Boss_General_Nazgrim.blp",
[6]="GarrMissionLocation-Nagrand",
[7]=false,
[8]={
	[1]={
		portraitFileDataID=1067358,
		displayID=56189,
		name="Warsong Earthcaller",
		mechanics={
			[4]={
				description="A dangerous harmful effect that should be dispelled.",
				name="Magic Debuff",
				icon="Interface\\ICONS\\Spell_Shadow_ShadowWordPain.blp"
			},
			[8]={
				description="A dangerous spell that should be interrupted.",
				name="Powerful Spell",
				icon="Interface\\ICONS\\Spell_Shadow_ShadowBolt.blp"
			}
		}
	}
}
local totalTimeString, totalTimeSeconds, isMissionTimeImproved, successChance, partyBuffs, isEnvMechanicCountered, xpBonus, materialMultiplier = C_Garrison.GetPartyMissionInfo(MISSION_PAGE_FRAME.missionInfo.missionID);
Dump: value=C_Garrison.GetPartyMissionInfo(118)
[1]="8 hr",
[2]=28800,
[3]=false,
[4]=0,
[5]={
},
[6]=false,
[7]=0,
[8]=1
Dump: value=table returned by GetFollowerInfo for a collected follower
[1]={
	displayHeight=0.5,
	iLevel=600,
	isCollected=true,
	classAtlas="GarrMission_ClassIcon-Druid",
	garrFollowerID="0x0000000000000022",
	displayScale=1,
	level=100,
	quality=4,
	portraitIconID=1066112,
	isFavorite=false,
	xp=0,
	className="Guardian Druid",
	classSpec=8,
	name="Qiana Moonshadow",
	followerID="0x000000000002F5E1",
	height=1.3999999761581,
	displayID=55047,
	scale=0.60000002384186,
	levelXP=0
}
	local location, xp, environment, environmentDesc, environmentTexture, locPrefix, isExhausting, enemies = G.GetMissionInfo(missionID)
--]]
function addon:GetScroller(title,type)
	type=type or "Frame"
	local scrollerWindow=AceGUI:Create("Frame")
	scrollerWindow:SetTitle(title)
	scrollerWindow:SetLayout("Fill")
	--local scrollcontainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
	--scrollcontainer:SetFullWidth(true)
	--scrollcontainer:SetFullHeight(true) -- probably?
	--scrollcontainer:SetLayout("Fill") -- important!
	--scrollerWindow:AddChild(scrollcontainer)
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow") -- probably?
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	scrollerWindow:AddChild(scroll)
	scrollerWindow:SetCallback("OnClose","Release")
	scrollerWindow:SetHeight(800)
	scrollerWindow:SetWidth(400)
	scrollerWindow:SetPoint("CENTER")
	scrollerWindow:Show()
	return scroll
end
function addon:AddLabel(obj,text,...)
		local l=AceGUI:Create("Label")
		l:SetText(text)
		l:SetColor(...)
		l:SetFullWidth(true)
		obj:AddChild(l)
end
function addon:cutePrint(scroll,level,k,v)
	if (type(level)=="table") then
		for k,v in pairs(level) do
			self:cutePrint(scroll,"",k,v)
		end
		return
	end
	if (type(v)=="table") then
		self:AddLabel(scroll,level..C(k,"Azure")..":" ..C("Table","Orange"))
		for kk,vv in pairs(v) do
			self:cutePrint(scroll,level .. "  ",kk,vv)
		end
	else
		if (type(v)=="string" and v:sub(1,2)=='0x') then
			v=v.. " " ..tostring(self:GetFollowerData(v,'name'))
		end
		self:AddLabel(scroll,level..C(k,"White")..":" ..C(v,"Yellow"))
	end
end
function addon:DumpFollowerMissions(missionID)
	local scroll=self:GetScroller("FollowerMissions " .. self:GetMissionData(missionID,'name'))
	self:cutePrint(scroll,followerMissions.missions[missionID])
end
function addon:DumpIfnored()
	local scroll=self:GetScroller("Ignored")
	self:cutePrint(scroll,self.privatedb.profile.ignored)
end
function addon:DumpMission(missionID)
	local scroll=self:GetScroller("MissionCache " .. self:GetMissionData(missionID,'name'))
	self:cutePrint(scroll,cache.missions[missionID])
end
function addon:DumpMissions()
	local scroll=self:GetScroller("MissionCache")
	for id,data in pairs(cache.missions) do
		self:cutePrint(scroll,id .. '.'..data.name)
	end
end
---
-- Debug function
--@param missionID Identificativo missione
function addon:DumpCounters(missionID)
	local scroll=self:GetScroller("Counters " .. self:GetMissionData(missionID,'name'))
	self:cutePrint(scroll,counters[missionID])
	self:cutePrint(scroll,"Lista per follower","","")
	self:cutePrint(scroll,counterFollowerIndex[missionID])
	self:cutePrint(scroll,"Lista per threat","","")
	self:cutePrint(scroll,counterThreatIndex[missionID])
end
function addon:Dump(title,data)
	local scroll=self:GetScroller(title)
	self:cutePrint(scroll,data)

end
function addon:DumpCounterers(missionID)
	local scroll=self:GetScroller("Counterers " .. self:GetMissionData(missionID,'name'))
	self:cutePrint(scroll,cache.missions[missionID].counterers)
end
function addon:DumpParty(missionID)
	local scroll=self:GetScroller("Party " .. self:GetMissionData(missionID,'name'))
	self:cutePrint(scroll,parties[missionID])
end
function addon:GenerateTimersPeriodic()
	return coroutine.wrap(
		function(self)
			repeat
				local t=new()
				G.GetInProgressMissions(t)
				for index=1,#t do
					local mission=t[index]
					for i=1,mission.numFollowers do
					end
				end
				coroutine.yield()
			until false
		end
	)
end
function addon:GMF_OnDragStart(frame)
	if (not self:GetBoolean('MOVEPANEL')) then return end
	frame.IsSizingOrMoving=true
	if (IsShiftKeyDown()) then
		frame.IsSizing=true
		frame:StartSizing("BOTTOMRIGHT")
		frame:SetScript("OnUpdate",function(frame,elapsed)
			if (frame.timepassed and frame.timepassed >1) then
				GarrisonMissionList_UpdateMissions()
			else
				frame.timepassed=frame.timepassed or 0
				frame.timepassed=frame.timepassed +elapsed
			end
		end)
	else
		frame.IsSizing=nil
		frame:StartMoving()
	end
end
function addon:GMF_OnDragStop(frame)
	frame:StopMovingOrSizing()
	frame:SetScript("OnUpdate",nil)
	if (frame.IsSizing) then
		BIGSIZEW=frame:GetWidth()
		SIZEV=frame:GetHeight()
		BIGBUTTON=min(BIGSIZEW*0.55,BIGSIZEW-GCSIZE)
		SMALLBUTTON=BIGBUTTON
		if (not self:IsFollowerList()) then
			HybridScrollFrame_CreateButtons(frame.MissionTab.MissionList.listScroll, "GarrisonMissionListButtonTemplate", 13, -8, nil, nil, nil, -4);
			GarrisonMissionList_Update();
		else
			HybridScrollFrame_CreateButtons(frame.FollowerList.listScroll, "GarrisonMissionFollowerButtonTemplate", 7, -7, nil, nil, nil, -6);
		end
	end
	frame.IsSizing=nil
	frame.IsSizingOrMoving=nil
end

--@end-do-not-package@
-- Courtesy of Motig
-- Concept and interface reused with permission
-- Mission building rewritten from scratch
local GMC_G = {}
--GMC_G.frame = CreateFrame('FRAME')
local aMissions={}

function addon:GMCCreateMissionList(workList)
	--First get rid of unwanted rewards and missions that are too long
	local settings=self.privatedb.profile.missionControl
	local ar=settings.allowedRewards
	wipe(workList)
	for missionID,mission in pairs(cache.missions) do
		local discarded=false
		repeat
			if (mission.durationSeconds > settings.maxDuration * 3600 or mission.durationSeconds <  settings.minDuration * 3600) then
				xprint(missionID,"discarded due to len",mission.durationSeconds /3600)
				break
			end -- Mission too long, out of here
			if (mission.isRare and settings.skipRare) then
				xprint(missionID,"discarded due to rarity")
				break
			end
			for k,v in pairs(ar) do
				if (not v) then
					if (mission[k] and mission[k]~=0) then -- we have a forbidden reward
						discarded=true
						break
					end
				end
			end
			if (not discarded) then
				tinsert(workList,missionID)
			end
		until true
	end
	local function msort(i1,i2)
		local m1=addon:GetMissionData(i1)
		local m2=addon:GetMissionData(i2)
		for i=1,#GMC.settings.itemPrio do
			local criterium=GMC.settings.itemPrio[i]
			xprint("Checking",criterium)
			if (criterium) then
				xprint(i1,i2,"Sorting on ",criterium,m1[criterium] , m2[criterium])
				if (m1[criterium] ~= m2[criterium]) then
					xprint(i1,i2,"Sorted on ",criterium,m1[criterium] , m2[criterium])
					return m1[criterium] > m2[criterium]
				end
			end
		end
		xprint(i1,i2,"Sorted on level",m1.level , m2.level)
		return m1.level > m2.level
	end
	table.sort(workList,msort)
end
local factory={} --#factory
do
	local nonce=0
	local GetTime=GetTime
	function factory:Slider(father,min,max,current,message)
		local name=tostring(self)..GetTime()*1000 ..nonce
		nonce=nonce+1
		local sl = CreateFrame('Slider',name, father, 'OptionsSliderTemplate')
		sl:SetWidth(128)
		sl:SetHeight(20)
		sl:SetOrientation('HORIZONTAL')
		sl:SetMinMaxValues(min, max)
		sl:SetValue(current)
		sl:SetValueStep(1)
		sl.Low=_G[name ..'Low']
		sl.Low:SetText(min)
		sl.High=_G[name .. 'High']
		sl.High:SetText(max)
		sl.Text=_G[name.. 'Text']
		sl.Text:SetText(message)
		sl.OnValueChanged=function(this,value)
			if (not this.unrounded) then
				value = math.floor(value)
			end
			if (this.isPercent) then
				this.Text:SetFormattedText('%d%%',value)
			else
				this.Text:SetText(value)
			end
			return value
		end
		sl:SetScript("OnValueChanged",sl.OnValueChanged)
		return sl
	end
	function factory:Checkbox(father,current,message)
		local name=tostring(self)..GetTime()*1000 ..nonce
		nonce=nonce+1
		local ck=CreateFrame("CheckButton",name,father,"ChatConfigCheckButtonTemplate")
		ck.Text=_G[name..'Text']
		ck.Text:SetText(message)
		ck:SetChecked(current)
		return ck
	end
end
--- This routine can be called both as coroutin and as a standard one
-- In standard version, delay between group building and submitting is done via a self schedule
--@param #integer missionID Optional, to run a single mission
--@param #bool start Optional, tells that follower already are on mission and that we need just to start it
function addon:GMCRunMission(missionID,start)
	xprint("Asked to start mission",missionID)
	if (start) then
		G.StartMission(missionID)
		PlaySound("UI_Garrison_CommandTable_MissionStart")
		return
	end
	for i=1,#GMC.ml.Parties do
		local party=GMC.ml.Parties[i]
		xprint("Checking",party.missionID)
		if (missionID and party.missionID==missionID or not missionID) then
			GMC.ml.widget:RemoveChild(party.missionID)
			GMC.ml.widget:DoLayout()
			if (party.full) then
				for j=1,#party.members do
					G.AddFollowerToMission(party.missionID, party.members[j])
				end
				if (not missionID) then
					coroutine.yield(true)
					G.StartMission(party.missionID)
					PlaySound("UI_Garrison_CommandTable_MissionStart")
					coroutine.yield(true)
				else
					self:ScheduleTimer("GMCRunMission",0.25,party.missionID,true)
				end
			end
		end
	end
end
do
	local timeElapsed=0
	local currentMission=0
	local x=0
	function addon:GMCCalculateMissions(this,elapsed)
		timeElapsed = timeElapsed + elapsed
		if (#aMissions == 0 ) then
			if timeElapsed >= 1 then
				currentMission=0
				x=0
				self:Unhook(this,"OnUpdate")
				GMC.ml.widget:SetTitle(READY)
				GMC.ml.widget:SetTitleColor(C.Green())
				this:Enable()
				if (#GMC.ml.Parties>0) then
					GMC.runButton:Enable()
				end
			end
			return
		end
		if (timeElapsed >=0.10) then
			currentMission=currentMission+1
			if (currentMission > #aMissions) then
				wipe(aMissions)
				currentMission=0
				x=0
				timeElapsed=0.9
			else
				GMC.ml.widget:SetFormattedTitle("Processing mission %d of %d",currentMission,#aMissions)
				local missionID=aMissions[currentMission]
				if (dbg) then print(C("Processing ","Red"),missionID) end
				local party={members={},perc=0}
				local mission=self:GetMissionData(missionID)
				if (not mission ) then
					if dbg then print ("NO data for",missionID) end
					return
				end
				self:MatchMaker(missionID,mission,party) -- I need my mission data
				local minimumChance=0
				if (GMC.settings.useOneChance) then
					minimumChance=GMC.settings.minimumChance
				end
				for prio,enabled in pairs(GMC.settings.allowedRewards) do
					if (dbg) then print("Chance from ",prio,"=",GMC.settings.rewardChance[prio],enabled) end
					if (enabled and (tonumber(self:GetMissionData(missionID,prio)) or 0) >0) then
						minimumChance=math.max(GMC.settings.rewardChance[prio],minimumChance)
					end
				end
				if (dbg) then print ("Missionid",missionID,"Chance",minimumChance,"chance",party.perc) end
				if ( party.full and party.perc >= minimumChance) then
					if (dbg) then print("Preparing button for",missionID) end
					local mb=AceGUI:Create("GMCMissionButton")
					for i=1,#party.members do
						GMCUsedFollowers[party.members[i]]=true
					end
					party.missionID=missionID
					tinsert(GMC.ml.Parties,party)
					mb:SetMission(mission)
					GMC.ml.widget:PushChild(mb,missionID)
					mb:SetFullWidth(true)
					mb:SetCallback("OnClick",function(...)
						addon:GMCRunMission(missionID)
						GMC.ml.widget:RemoveChild(missionID)
					end
					)
				end
				timeElapsed=0
			end
		end
	end
end

function addon:GMC_OnClick_Run(this,button)
	this:Disable()
	do
	local elapsed=0
	local co=coroutine.wrap(self.GMCRunMission)
	self:RawHookScript(GMC.runButton,'OnUpdate',function(this,ts)
		elapsed=elapsed+ts
		if (elapsed>0.25) then
			elapsed=0
			local rc=co(self)
			if (not rc) then
				self:Unhook(GMC.runButton,'OnUpdate')
			end
		end
	end
	)
	end
end
function addon:GMC_OnClick_Start(this,button)
	xprint(C("-------------------------------------------------","Yellow"))
	this:Disable()
	GMC.ml.widget:ClearChildren()
	addon:GMCCreateMissionList(aMissions)
	wipe(GMCUsedFollowers)
	wipe(GMC.ml.Parties)
	if (#aMissions>0) then
		GMC.ml.widget:SetFormattedTitle(L["Processing mission %d of %d"],1,#aMissions)
	else
		GMC.ml.widget:SetTitle("No mission matches your criteria")
		GMC.ml.widget:SetTitleColor(C.Red())
	end
	self:RawHookScript(GMC.startButton,'OnUpdate',"GMCCalculateMissions")

end
local chestTexture
function addon:GMCBuildPanel()
	--PanelTemplates_SetNumTabs(GarrisonMissionFrame, 4)
	--PanelTemplates_UpdateTabs(GarrisonMissionFrame)
	chestTexture='GarrMission-'..UnitFactionGroup('player').. 'Chest'
	GMC = CreateFrame('FRAME', 'GMCOptions', GarrisonMissionFrame)
	GMC.settings=dbcache.missionControl
	GMC:SetPoint('CENTER')
	GMC:SetSize(GarrisonMissionFrame:GetWidth(), GarrisonMissionFrame:GetHeight())
	GMC:Hide()
	local chance=self:GMCBuildChance()
	local duration=self:GMCBuildDuration()
	local rewards=self:GMCBuildRewards()
	local priorities=self:GMCBuildPriorities()
	local list=self:GMCBuildMissionList()
	duration:SetPoint("TOPLEFT",0,-50)
	chance:SetPoint("TOPLEFT",duration,"TOPRIGHT",bigscreen and 50 or 10,0)
	priorities:SetPoint("TOPLEFT",duration,"BOTTOMLEFT",10,-40)
	rewards:SetPoint("TOPLEFT",priorities,"TOPRIGHT",bigscreen and 50 or 15,0)
	list:SetPoint("TOPLEFT",chance,"TOPRIGHT",10,0)
	list:SetPoint("BOTTOMRIGHT",GMF,"BOTTOMRIGHT",-25,25)
	GMC.skipRare=factory:Checkbox(GMC,GMC.settings.skipRare,L["Ignore rare missions"])
	GMC.skipRare:SetPoint("TOPLEFT",priorities,"BOTTOMLEFT",0,-10)
	GMC.startButton = CreateFrame('BUTTON',nil,  list.frame, 'GameMenuButtonTemplate')
	GMC.startButton:SetText('Calculate')
	GMC.startButton:SetWidth(148)
	GMC.startButton:SetPoint('TOPLEFT',15,25)
	GMC.startButton:SetScript('OnClick', function(this,button) self:GMC_OnClick_Start(this,button) end)
	GMC.startButton:SetScript('OnEnter', function() GameTooltip:SetOwner(GMC.startButton, 'ANCHOR_TOPRIGHT') GameTooltip:AddLine('Assign your followers to missions.') GameTooltip:Show() end)
	GMC.startButton:SetScript('OnLeave', function() GameTooltip:Hide() end)
	GMC.runButton = CreateFrame('BUTTON', nil,list.frame, 'GameMenuButtonTemplate')
	GMC.runButton:SetText('Send all mission at once')
	GMC.runButton:SetScript('OnEnter', function() GameTooltip:SetOwner(GMC.runButton, 'ANCHOR_TOPRIGHT') GameTooltip:AddLine('Submit all yopur mission at once. No question asked.') GameTooltip:Show() end)
	GMC.runButton:SetScript('OnLeave', function() GameTooltip:Hide() end)
	GMC.runButton:SetWidth(148)
	GMC.runButton:SetPoint('TOPRIGHT',-15,25)
	GMC.runButton:SetScript('OnClick',function(this,button) self:GMC_OnClick_Run(this,button) end)
	GMC.runButton:Disable()
	GMC.Credits=GMC:CreateFontString(nil,"ARTWORK","ReputationDetailFont")
	GMC.Credits:SetWidth(0)
	GMC.Credits:SetFormattedText("Original concept and interface by %s",C("Motig","Red") )
	GMC.Credits:SetPoint("BOTTOMLEFT",25,25)
end
local rewardRefresh
do
	---@function [parent=#GMC] rewardRefresh
	function rewardRefresh()
		for i=1,#GMC.ignoreFrames do
			local frame=GMC.ignoreFrames[i]
			local allowed=GMC.settings.allowedRewards[frame.key]
			frame.chest:SetDesaturated(not allowed)
			frame.icon:SetDesaturated(not allowed)
			if (GMC.settings.useOneChance) then
				frame.slider:Disable()
				frame.slider.Text:SetTextColor(C.Silver())
			else
				frame.slider:Enable()
				frame.slider.Text:SetTextColor(C.Green())
			end
		end
		if (GMC.settings.useOneChance) then
			GMC.ct:SetTextColor(C.Green())
			GMC.cs:Enable()
		else
			GMC.ct:SetTextColor(C.Silver())
			GMC.cs:Disable()
		end

	end
end
function addon:GMCBuildChance()
	_G['GMC']=GMC
	--Chance
	GMC.cf = CreateFrame('FRAME', nil, GMC)
	GMC.cf:SetSize(256, 150)

	GMC.cp = GMC.cf:CreateTexture(nil, 'BACKGROUND')
	GMC.cp:SetTexture('Interface\\Garrison\\GarrisonMissionUI2.blp')
	GMC.cp:SetAtlas(chestTexture)
	GMC.cp:SetSize((209-(209*0.25))*0.60, (155-(155*0.25))*0.60)
	GMC.cp:SetPoint('CENTER', 0, 20)

	GMC.cc = GMC.cf:CreateFontString()
	GMC.cc:SetFontObject('GameFontNormalHuge')
	GMC.cc:SetText('Success Chance')
	GMC.cc:SetPoint('TOP', 0, 0)
	GMC.cc:SetTextColor(1, 1, 1)

	GMC.ct = GMC.cf:CreateFontString()
	GMC.ct:SetFontObject('ZoneTextFont')
	GMC.ct:SetFormattedText('%d%%',GMC.settings.minimumChance)
	GMC.ct:SetPoint('TOP', 0, -40)
	GMC.ct:SetTextColor(0, 1, 0)

	GMC.cs = factory:Slider(GMC.cf,0,100,GMC.settings.minimumChance,'Minumum chance to start a mission')
	GMC.cs:SetPoint('BOTTOM', 10, 0)
	GMC.cs:SetScript('OnValueChanged', function(self, value)
			local value = math.floor(value)
			GMC.ct:SetText(value..'%')
			GMC.settings.minimumChance = value
	end)
	GMC.cs:SetValue(GMC.settings.minimumChance)
	GMC.ck=factory:Checkbox(GMC.cs,GMC.settings.useOneChance,"Use this percentage for all missions")
	GMC.ck.tooltip="Unchecking this will allow you to set specific success chance for each reward type"
	GMC.ck:SetPoint("TOPLEFT",GMC.cs,"BOTTOMLEFT",-60,-10)
	GMC.ck:SetScript("OnClick",function(this)
		GMC.settings.useOneChance=this:GetChecked()
		rewardRefresh()
	end)
	return GMC.cf
end
local function timeslidechange(this,value)
	local value = math.floor(value)
	if (this.max) then
		GMC.settings.maxDuration = max(value,GMC.settings.minDuration)
		if (value~=GMC.settings.maxDuration) then this:SetValue(GMC.settings.maxDuration) end
	else
		GMC.settings.minDuration = min(value,GMC.settings.maxDuration)
		if (value~=GMC.settings.minDuration) then this:SetValue(GMC.settings.minDuration) end
	end
	local c = 1-(value*(1/24))
	if c < 0.3 then c = 0.3 end
	GMC.mt:SetTextColor(1, c, c)
	GMC.mt:SetFormattedText("%d-%dh",GMC.settings.minDuration,GMC.settings.maxDuration)
end
function addon:GMCBuildDuration()
	-- Duration
	GMC.tf = CreateFrame('FRAME', nil, GMC)
	GMC.tf:SetSize(256, 180)
	GMC.tf:SetPoint('LEFT', 80, 120)

	GMC.bg = GMC.tf:CreateTexture(nil, 'BACKGROUND')
	GMC.bg:SetTexture('Interface\\Timer\\Challenges-Logo.blp')
	GMC.bg:SetSize(100, 100)
	GMC.bg:SetPoint('CENTER', 0, 0)
	GMC.bg:SetBlendMode('ADD')

	GMC.tcf = GMC.tf:CreateTexture(nil, 'BACKGROUND')
	--bb:SetTexture('Interface\\Timer\\Challenges-Logo.blp')
	--bb:SetTexture('dungeons\\textures\\devices\\mm_clockface_01.blp')
	GMC.tcf:SetTexture('World\\Dungeon\\Challenge\\clockRunes.blp')
	GMC.tcf:SetSize(110, 110)
	GMC.tcf:SetPoint('CENTER', 0, 0)
	GMC.tcf:SetBlendMode('ADD')

	GMC.mdt = GMC.tf:CreateFontString()
	GMC.mdt:SetFontObject('GameFontNormalHuge')
	GMC.mdt:SetText('Mission Duration')
	GMC.mdt:SetPoint('TOP', 0, 0)
	GMC.mdt:SetTextColor(1, 1, 1)

	GMC.mt = GMC.tf:CreateFontString()
	GMC.mt:SetFontObject('ZoneTextFont')
	GMC.mt:SetFormattedText('%d-%dh',GMC.settings.minDuration,GMC.settings.maxDuration)
	GMC.mt:SetPoint('CENTER', 0, 0)
	GMC.mt:SetTextColor(1, 1, 1)

	GMC.ms1 = factory:Slider(GMC.tf,0,24,GMC.settings.minDuration,'Minimum mission duration.')
	GMC.ms2 = factory:Slider(GMC.tf,0,24,GMC.settings.maxDuration,'Maximum mission duration.')
	GMC.ms1:SetPoint('BOTTOM', 0, 0)
	GMC.ms2:SetPoint('TOP', GMC.ms1,"BOTTOM",0, -25)
	GMC.ms2.max=true
	GMC.ms1:SetScript('OnValueChanged', timeslidechange)
	GMC.ms2:SetScript('OnValueChanged', timeslidechange)
	timeslidechange(GMC.ms1,GMC.settings.minDuration)
	timeslidechange(GMC.ms2,GMC.settings.maxDuration)
	return GMC.tf
end
function addon:GMCBuildRewards()
	--Allowed rewards
	GMC.aif = CreateFrame('FRAME', nil, GMC)
	GMC.aif:SetPoint('CENTER', 0, 120)

	GMC.itf = GMC.aif:CreateFontString()
	GMC.itf:SetFontObject('GameFontNormalHuge')
	GMC.itf:SetText('Allowed Rewards')
	GMC.itf:SetPoint('TOP', 0, -10)
	GMC.itf:SetTextColor(1, 1, 1)

	GMC.itf2 = GMC.aif:CreateFontString()
	GMC.itf2:SetFontObject('GameFontHighlight')
	GMC.itf2:SetText('Click to enable/disable a reward.')
	GMC.itf2:SetTextColor(1, 1, 1)


	local t = {
		{t = 'Enable/Disable money rewards.', i = 'Interface\\Icons\\inv_misc_coin_01', key = 'gold'},
		{t = 'Enable/Disable other currency awards. (Resources/Seals)', i= 'Interface\\Icons\\inv_garrison_resource', key = 'resources'},
		{t = 'Enable/Disable Follower XP Bonus rewards.', i = 'Interface\\Icons\\XPBonus_Icon', key = 'xpBonus'},
		{t = 'Enable/Disable follower equip enhancement.', i = 'Interface\\ICONS\\Garrison_ArmorUpgrade', key = 'followerUpgrade'},
		{t = 'Enable/Disable item tokens.', i = "Interface\\ICONS\\INV_Bracer_Cloth_Reputation_C_01", key = 'itemLevel'}
	}
	local scale=1.1
	GMC.ignoreFrames = {}
	local ref
	local h=37 -- itemButtonTemplate standard size
	local gap=5
	for i = 1, #t do
			local frame = CreateFrame('BUTTON', nil, GMC.aif, 'ItemButtonTemplate')
			frame:SetScale(scale)
			frame:SetPoint('TOPLEFT', 0,(i) * (-h -gap) * scale)
			frame.icon:SetTexture(t[i].i)
			frame.key=t[i].key
			frame.tooltip=t[i].t
			local allowed=GMC.settings.allowedRewards[frame.key]
			local chance=GMC.settings.rewardChance[frame.key]
			-- Need to resave them asap in order to populate the array for future scans
			GMC.settings.allowedRewards[frame.key]=allowed
			GMC.settings.rewardChance[frame.key]=chance
			frame.slider=factory:Slider(frame,0,100,chance or 100,chance or 100)
			frame.slider:SetWidth(128)
			frame.slider:SetPoint('BOTTOMLEFT',60,0)
			frame.slider.Text:SetTextColor(C.Green())
			frame.slider.Text:SetFontObject('NumberFont_Outline_Med')
			frame.slider.isPercent=true
			frame.slider:SetScript("OnValueChanged",function(this,value)
				GMC.settings.rewardChance[this:GetParent().key]=this:OnValueChanged(value)
				end
			)
			frame.chest = frame:CreateTexture(nil, 'BACKGROUND')
			frame.chest:SetTexture('Interface\\Garrison\\GarrisonMissionUI2.blp')
			frame.chest:SetAtlas(chestTexture)
			frame.chest:SetSize((209-(209*0.25))*0.30, (155-(155*0.25)) * 0.30)
			frame.chest:SetPoint('CENTER',frame.slider, 0, 25)
			frame.icon:SetDesaturated(not allowed)
			frame.chest:SetDesaturated(not allowed)
			rewardRefresh()
			frame:SetScript('OnClick', function(this)
				local allowed=  this.icon:IsDesaturated() -- ID it was desaturated, I want it allowed, now
				GMC.settings.allowedRewards[this.key] = allowed
				rewardRefresh()
			end)
			frame:SetScript('OnEnter', function(this)
				GameTooltip:SetOwner(this, 'ANCHOR_BOTTOMRIGHT')
				GameTooltip:AddLine(this.tooltip);
				GameTooltip:Show()
			end)

			frame:SetScript('OnLeave', function() GameTooltip:Hide() end)
			GMC.ignoreFrames[i] = frame
			ref=frame
	end
	GMC.aif:SetSize(256, (scale*h+gap) * #t)
	GMC.itf2:SetPoint('TOPLEFT',ref,'BOTTOMLEFT', 0, -15)
	return GMC.aif
end
local addPriorityRule,prioRefresh,removePriorityRule,prioMenu,prioTitles,prioCheck,prioVoices
do
-- 1 = item, 2 = folitem, 3 = exp, 4 = money, 5 = resource
	prioTitles={
		itemLevel="Gear Items",
		followerUpgrade="Upgrade Items",
		xpBonus="Follower XP Bonus",
		gold="Gold Reward",
		resources="Resource Rewards"
	}
	prioVoices=0
	for _ in pairs(prioTitles) do prioVoices=prioVoices+1 end
	prioMenu={}

	---@function [parent=#GMC] prioRefresh
	function prioRefresh()
		for i=1,prioVoices do
			local group=GMC.prioFrames[i]
			local code=GMC.settings.itemPrio[i]
			if (not code) then
				group.text:Hide()
				group.xbutton:Hide()
				group.nr:Hide()
			else
				group.text:Show()
				group.text:SetText(prioTitles[code])
				group.xbutton:Show()
				group.nr:Show()
			end
		end
		GMC.abutton:Hide()
		for i=1,prioVoices do
			local group=GMC.prioFrames[i]
			if (not group.text:IsShown()) then
				group.nr:Show()
				GMC.abutton:SetPoint("TOPLEFT",group.text)
				GMC.abutton:Show()
				break
			end
		end
	end
	---@function [parent=#GMC] addPriorityRule
	function addPriorityRule(this,key)
		tinsert(GMC.settings.itemPrio,key)
		prioRefresh()
	end
	---@function [parent=#GMC] removePriorityRule
	function removePriorityRule(index)
		tremove(GMC.settings.itemPrio,index)
		prioRefresh()
	end

end
function addon:GMCBuildPriorities()
	--Prio
	GMC.pf = CreateFrame('FRAME', nil, GMC)
	GMC.pf:SetSize(256, 240)

	GMC.pft = GMC.pf:CreateFontString()
	GMC.pft:SetFontObject('GameFontNormalHuge')
	GMC.pft:SetText('Item Priority')
	GMC.pft:SetPoint('TOP', 0, -10)
	GMC.pft:SetTextColor(1, 1, 1)

	GMC.pft2 = GMC.pf:CreateFontString()
	GMC.pft2:SetFontObject('GameFontNormal')
	GMC.pft2:SetText('Prioritize missions with certain a reward.')
	GMC.pft2:SetPoint('BOTTOM', 0, 16)
	GMC.pft2:SetTextColor(1, 1, 1)
	GMC.pmf = CreateFrame("FRAME", "GMC_PRIO_MENU", GMC.pf, "UIDropDownMenuTemplate")


	GMC.prioFrames = {}
	GMC.prioFrames.selected = 0
	for i = 1, prioVoices do
		GMC.prioFrames[i] = {}
		local this = GMC.prioFrames[i]
		this.f = CreateFrame('FRAME', nil, GMC.pf)
		this.f:SetSize(255, 32)
		this.f:SetPoint('TOP', 0, -38-((i-1)*32))

		this.nr = this.f:CreateFontString()
		this.nr:SetFontObject('GameFontNormalHuge')
		this.nr:SetText(i..'.')
		this.nr:SetPoint('LEFT', 8, 0)
		this.nr:SetTextColor(1, 1, 1)

		this.text = this.f:CreateFontString()
		this.text:SetFontObject('GameFontNormalLarge')
		this.text:SetText('Def')
		this.text:SetPoint('LEFT', 32, 0)
		--this.text:SetTextColor(1, 1, 0)
		this.text:SetJustifyH('LEFT')
		this.text:Hide()

		this.xbutton = CreateFrame('BUTTON', nil, this.f, 'GameMenuButtonTemplate')
		this.xbutton:SetPoint('RIGHT', 0, 0)
		this.xbutton:SetText('X')
		this.xbutton:SetWidth(28)
		this.xbutton:SetScript('OnClick', function() removePriorityRule(i)  end)
		this.xbutton:Hide()
	end

	GMC.abutton = CreateFrame('BUTTON', nil, GMC.pmf, 'GameMenuButtonTemplate')
	GMC.abutton:SetText(L['Add priority rule'])
	GMC.abutton:SetWidth(128)
	GMC.abutton:Hide()
	GMC.abutton:SetScript('OnClick', function()
		wipe(prioMenu)
		tinsert(prioMenu,{text = L["Select an item to add as priority."], isTitle = true, isNotRadio=true,disabled=true, notCheckable=true,notClickable=true})
		for k,v in pairs(prioTitles) do
			tinsert(prioMenu,{text = v, func = addPriorityRule, notCheckable=true, isNotRadio=true, arg1 = k , disabled=inTable(GMC.settings.itemPrio,k)})
		end
		EasyMenu(prioMenu, GMC.pmf, "cursor", 0 , 0, "MENU")
		end
	)
	prioRefresh()
	return GMC.pf
end
function addon:GMCBuildMissionList()
		-- Mission list on follower panels
--		local ml=CreateFrame("Frame",nil,GMC)
--		addBackdrop(ml)
--		ml:Show()
--		ml.Missions={}
--		ml.Parties={}
--		GMC.ml=ml
--		local fs=ml:CreateFontString(nil, "BACKGROUND", "GameFontNormalHugeBlack")
--		fs:SetPoint("TOPLEFT",0,-5)
--		fs:SetPoint("TOPRIGHT",0,-5)
--		fs:SetText(READY)
--		fs:SetTextColor(C.Green())
--		fs:SetHeight(30)
--		fs:SetJustifyV("CENTER")
--		fs:Show()
--		GMC.progressText=fs
--		GMC.ml.Header=fs
--		return GMC.ml
	local ml={widget=AceGUI:Create("GMCLayer"),Parties={}}
	ml.widget:SetTitle(READY)
	ml.widget:SetTitleColor(C.Green())
	ml.widget:SetTitleHeight(40)
	ml.widget:SetParent(GMC)
	ml.widget:Show()
	GMC.ml=ml
	return ml.widget

end
