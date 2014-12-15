local me, ns = ...
local addon=LibStub("LibInit"):NewAddon(me,'AceHook-3.0','AceTimer-3.0','AceEvent-3.0') --#Addon
local C=addon:GetColorTable()
local L=addon:GetLocale()
local print=function(...) addon:Print(...) end
local trace=function(...) addon:_Trace(false,1,...) end
local xprint=function(dbg,...) if (type(dbg)=="boolean") then if dbg then addon:Print('DBG',...) end end end--else addon:Print(dbg,...) end end
--xprint=function() end
local debug=ns.debug or print
local dump=ns.dump or print
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
---TODO:
-- Colorare i seguaci in base ala disponbilita' (verdi disponibili, rossi in altre missioni. Magary gialli se working?)
-- Memorizzare la percentuale di successo delle missioni partire, per visualizzarla nel pannello in progress
-- Rifare il tooltip
-- Decidere come (se) usare lo spazio che rimane a destra delle icone

--@debug@
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
-- Name is here just for doc, I will be using the localized one

local abilities={
	{
		["name"] = "Wild Aggression",
		["icon"] = "Interface\\ICONS\\Spell_Nature_Reincarnation.blp",
	}, -- [1]
	{
		["name"] = "Massive Strike",
		["icon"] = "Interface\\ICONS\\Ability_Warrior_SavageBlow.blp",
	}, -- [2]
	{
		["name"] = "Group Damage",
		["icon"] = "Interface\\ICONS\\Spell_Fire_SelfDestruct.blp",
	}, -- [3]
	{
		["name"] = "Magic Debuff",
		["icon"] = "Interface\\ICONS\\Spell_Shadow_ShadowWordPain.blp",
	}, -- [4]
	nil, -- [5]
	{
		["name"] = "Danger Zones",
		["icon"] = "Interface\\ICONS\\spell_Shaman_Earthquake.blp",
	}, -- [6]
	{
		["name"] = "Minion Swarms",
		["icon"] = "Interface\\ICONS\\Spell_DeathKnight_ArmyOfTheDead.blp",
	}, -- [7]
	{
		["name"] = "Powerful Spell",
		["icon"] = "Interface\\ICONS\\Spell_Shadow_ShadowBolt.blp",
	}, -- [8]
	{
		["name"] = "Deadly Minions",
		["icon"] = "Interface\\ICONS\\Achievement_Boss_TwinOrcBrutes.blp",
	}, -- [9]
	{
		["name"] = "Timed Battle",
		["icon"] = "Interface\\ICONS\\SPELL_HOLY_BORROWEDTIME.BLP",
	}, -- [10]
}

local function getAbilityName(texture)
	for i=1,#abilities do
		if (abilities[i] and abilities[i].icon==texture) then
			return abilities[i].name
		end
	end
	return "unknown"
end
--- upvalues
local AVAILABLE=AVAILABLE -- "Available"
local BUTTON_INFO=GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS.. " " .. GARRISON_MISSION_PERCENT_CHANCE
local ENVIRONMENT_SUBHEADER=ENVIRONMENT_SUBHEADER -- "Environment"
local G=C_Garrison
local GARRISON_BUILDING_SELECT_FOLLOWER_TITLE=GARRISON_BUILDING_SELECT_FOLLOWER_TITLE -- "Select a Follower";
local GARRISON_BUILDING_SELECT_FOLLOWER_TOOLTIP=GARRISON_BUILDING_SELECT_FOLLOWER_TOOLTIP -- "Click here to assign a Follower";
local GARRISON_FOLLOWERS=GARRISON_FOLLOWERS -- "Followers"
local GARRISON_FOLLOWER_CAN_COUNTER=GARRISON_FOLLOWER_CAN_COUNTER -- "This follower can counter:"
local GARRISON_FOLLOWER_EXHAUSTED=GARRISON_FOLLOWER_EXHAUSTED -- "Recovering (1 Day)"
local GARRISON_FOLLOWER_INACTIVE=GARRISON_FOLLOWER_INACTIVE --"Inactive"
local GARRISON_FOLLOWER_IN_PARTY=GARRISON_FOLLOWER_IN_PARTY
local GARRISON_FOLLOWER_ON_MISSION=GARRISON_FOLLOWER_ON_MISSION -- "On Mission"
local GARRISON_FOLLOWER_WORKING=GARRISON_FOLLOWER_WORKING -- "Working
local GARRISON_MISSION_PERCENT_CHANCE="%d%%"-- GARRISON_MISSION_PERCENT_CHANCE
local GARRISON_MISSION_SUCCESS=GARRISON_MISSION_SUCCESS -- "Success"
local GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS=GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS -- "%d Follower mission";
local GARRISON_PARTY_NOT_FULL_TOOLTIP=GARRISON_PARTY_NOT_FULL_TOOLTIP -- "You do not have enough followers on this mission."
local NOT_COLLECTED=NOT_COLLECTED -- not collected
local GMF=GarrisonMissionFrame
local GMFFollowerPage=GMF.FollowerTab
local GMFFollowers=GarrisonMissionFrameFollowers
local GMFMissionPage=GMF.MissionTab
local GMFMissionPageFollowers = GMFMissionPage.MissionPage.Followers
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
local GMFTab1=GarrisonMissionFrameTab1
local GMFTab2=GarrisonMissionFrameTab2
local GMFTab3=GarrisonMissionFrameTab3
local GarrisonMissionFrameMissionsListScrollFrame=GarrisonMissionFrameMissionsListScrollFrame
local IGNORE_UNAIVALABLE_FOLLOWERS=IGNORE.. ' ' .. UNAVAILABLE .. ' ' .. GARRISON_FOLLOWERS
local IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL=IGNORE.. ' ' .. GARRISON_FOLLOWER_INACTIVE .. ',' .. GARRISON_FOLLOWER_ON_MISSION ..',' .. GARRISON_FOLLOWER_WORKING.. ','.. GARRISON_FOLLOWER_EXHAUSTED .. ' ' .. GARRISON_FOLLOWERS
local PARTY=PARTY -- "Party"
local SPELL_TARGET_TYPE1_DESC=capitalize(SPELL_TARGET_TYPE1_DESC) -- any
local SPELL_TARGET_TYPE4_DESC=capitalize(SPELL_TARGET_TYPE4_DESC) -- party member
local ANYONE='('..SPELL_TARGET_TYPE1_DESC..')'
local UNKNOWN_CHANCE=GARRISON_MISSION_PERCENT_CHANCE:gsub('%%d%%%%',UNKNOWN)
IGNORE_UNAIVALABLE_FOLLOWERS=capitalize(IGNORE_UNAIVALABLE_FOLLOWERS)
IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL=capitalize(IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL)
local GARRISON_DURATION_HOURS_MINUTES=GARRISON_DURATION_HOURS_MINUTES
local GARRISON_DURATION_DAYS_HOURS=GARRISON_DURATION_DAYS_HOURS
local AGE_HOURS="First seen " .. GARRISON_DURATION_HOURS_MINUTES .. " ago"
local AGE_DAYS="First seen " .. GARRISON_DURATION_DAYS_HOURS .. " ago"
local UNKNOWN=UNKNOWN
local TYPE=TYPE
-- Panel sizes
local BIGSIZEW=1400
local BIGSIZEH=662
local SIZEW=950
local SIZEH=662
local SIZEV
local GCSIZE=800
local BIGBUTTON=BIGSIZEW-GCSIZE
local SMALLBUTTON=BIGSIZEW-GCSIZE
local GCF
local GCFMissions
local GCFBusyStatus
local GameTooltip=GameTooltip
-- Want to know what I call!!
local GarrisonMissionButton_OnEnter=GarrisonMissionButton_OnEnter
local GarrisonFollowerList_UpdateFollowers=GarrisonFollowerList_UpdateFollowers
local GarrisonMissionList_UpdateMissions=GarrisonMissionList_UpdateMissions
local GarrisonMissionPage_ClearFollower=GarrisonMissionPage_ClearFollower
local GarrisonMissionPage_UpdateMissionForParty=GarrisonMissionPage_UpdateMissionForParty
local GarrisonMissionPage_SetFollower=GarrisonMissionPage_SetFollower
local GetItemInfo=GetItemInfo
local type=type
local ITEM_QUALITY_COLORS=ITEM_QUALITY_COLORS
local deadly={r=C.Purple.r,g=C.Purple.g,b=C.Purple.b}
function addon:GetDifficultyColor(perc)
	if(perc >90) then
		return QuestDifficultyColors['standard']
	elseif (perc >74) then
		return QuestDifficultyColors['difficult']
	elseif(perc>49) then
		return QuestDifficultyColors['verydifficult']
	elseif(perc >20) then
		return QuestDifficultyColors['impossible']
	else
		return QuestDifficultyColors['trivial']
	end
end
if (LibDebug) then LibDebug() end
----- Local variables
--
local t0={
	__index=function(t,k) rawset(t,k,{}) return t[k] end
}

local t1={
	__index=function(t,k) rawset(t,k,setmetatable({},t0)) return t[k] end
}
local t2={
	__index=function(t,k) rawset(t,k,setmetatable({},t1)) return t[k] end
}
local masterplan
local availableFollowers=0 -- Total numner of non in mission followers
local followersCache={}
local followersCacheIndex={}
local dirty=false
local cache
local dbcache
local timers={}
local counters=setmetatable({},t0)
local counterThreatIndex=setmetatable({},t2)
local counterFollowerIndex=setmetatable({},t2)
local onMission={}

--- Parties storage
--
--
local parties=setmetatable({},{
	__index=function(t,k) rawset(t,k,{members={},perc=0,full=false}) return t[k] end
})

--- Follower Missions Info
--
local followerMissions=setmetatable({},{
	__index=function(t,k) rawset(t,k,{}) return t[k] end
})
--- Counters Info per mission
--

local counters=setmetatable({},{
	__index=function(t,k) rawset(t,k,{}) return t[k] end
})


-----------------------------------------------------
-- Coroutines data
-------------
local coroutines={
	Timers={
		func=false,
		elapsed=60,
		interval=10,
		paused=false
	},
	Drawer={
		func=false,
		elapsed=0,
		interval=1,
		paused=false
	}
}
--
-- Temporary party management
local openParty,isInParty,pushFollower,removeFollower,closeParty,roomInParty,storeFollowers

do
	local ID,frames,members,maxFollowers=0,{},{},1
	---@function [parent=#local] openParty
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
	---@function [parent=#local] isInParty
	function isInParty(followerID)
		for i=1,maxFollowers do
			if (followerID==members[i]) then return true end
		end
	end
	---@function [parent=#local] roomInParty
	function roomInParty()
		return not members[maxFollowers]
	end
	---@function [parent=#local] pushFollower
	function pushFollower(followerID)
		if (followerID:sub(1,2) ~= '0x') then error(followerID .. "is not an id") end
		if (roomInParty()) then
			local rc,code=pcall (C_Garrison.AddFollowerToMission,ID,followerID)
			if (rc and code) then
				tinsert(members,followerID)
				return true
--@debug@
			else
				print("Error adding ", followerID,"to",ID,code)
--@end-debug@
			end
		end
	end
	---@function [parent=#local] removeFollowers
	function removeFollower(followerID)
		for i=1,maxFollowers do
			if (followerID==members[i]) then
				tremove(members,i)
				local rc,code=pcall(C_Garrison.RemoveFollowerFromMission,ID,followerID)
--@debug@
				if (not rc) then xprint("Error removing", members[i],"from",ID,code) end
--@end-debug@
			return true end
		end
	end

	---@function [parent=#local] storeFollowers
	function storeFollowers(table)
		wipe(table)
		for i=1,#members do
			tinsert(table,members[i])
		end
		return #table
	end

	---@function [parent=#local] closeParty
	function closeParty()
		local perc=select(4,G.GetPartyMissionInfo(ID))
		for i=1,3 do
			if (members[i]) then
				local rc,code=pcall(C_Garrison.RemoveFollowerFromMission,ID,members[i])
--@debug@
				if (not rc) then xprint("Error popping ", members[i]," from ",ID,code) end
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
		return perc
	end
end
-- ProgressBar

function addon:AddLine(icon,name,status,quality,...)
	local r2,g2,b2=C.Red()
	local q=ITEM_QUALITY_COLORS[quality or 1] or {}
	if (status==AVAILABLE) then
		r2,g2,b2=C.Green()
	elseif (status==GARRISON_FOLLOWER_WORKING) then
		r2,g2,b2=C.Orange()
	end
	--GameTooltip:AddDoubleLine(name, status or AVAILABLE,r,g,b,r2,g2,b2)
	--GameTooltip:AddTexture(icon)
	GameTooltip:AddDoubleLine(icon and "|T" .. tostring(icon) .. ":0|t  " .. name or name, status,q.r,q.g,q.b,r2,g2,b2)
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
	for id,d in pairs(G.GetBuffedFollowersForMission(missionID)) do
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
			tinsert(missioncounters,{mechanic=true,name=l.name,followerID=id,bias=bias,rank=rank,quality=quality,icon=l.icon})
			followerMissions[id][missionID]=1+ (tonumber(followerMissions[id][missionID]) or 0)
		end
	end
	for id,d in pairs(G.GetFollowersTraitsForMission(missionID)) do
		local level=self:GetFollowerData(id,'level')
		local bias= G.GetFollowerBiasForMission(missionID,id);
		local rank=self:GetFollowerData(id,'rank')
		local quality=self:GetFollowerData(id,'quality')
		for i,l in pairs(d) do
			--l.traitID
			--l.icon
			followerMissions[id][missionID]=1+ (tonumber(followerMissions[id][missionID]) or 0)
			tinsert(missioncounters,{trait=true,name=l.icon,followerID=id,bias=bias,rank=rank,quality=quality,icon=l.icon})
		end
	end
	table.sort(missioncounters,cmp)
	local cf=counterFollowerIndex[missionID]
	local ct=counterThreatIndex[missionID]
	for i=1,#missioncounters do
		tinsert(cf[missioncounters[i].followerID],i)
		tinsert(ct[missioncounters[i].icon],i)
	end
end
function addon:Check(missionID)

end
function addon:ThreatDisplayer()
	TF="0x00000000000C2C1B"
	if (not AXE) then
		local AXE=CreateFrame("Frame","AXE",UIParent,"GarrisonAbilityLargeCounterTemplate")
		AXI=CreateFrame("Frame","AXI",UIParent,"GarrisonAbilityCounterTemplate")
	end
	if (not BUBU) then
		CreateFrame("CheckButton","BUBU",AXE,"UICheckButtonTemplate")
	end

	BUBU:SetPoint("CENTER")
	BUBU:SetChecked(true)
	BUBU:GetCheckedTexture():SetVertexColor(1,0,0)

	AXE:SetPoint("CENTER",-100.0)
	AXI:SetPoint("CENTER",100,0)
	AXE:Show()
	AXI:Show()
	local id=154
	local env=select(5,C_Garrison.GetMissionInfo(id))
	AXI.Icon:SetTexture(env)
	AXI.Border:SetVertexColor(1,0,0)
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
	if (isInParty(f1.followerID)) then return fid1 end
	if (f2.bias<0) then return fid1 end
	if (f2.bias>f1.bias) then return fid2 end
	if (f1.bias == f2.bias) then
		if (f2.quality < f1.quality or f2.rank < f1.rank) then return fid2 end
	end
	return fid1
end
function addon:MatchMaker(missionID,mission,party,skipbusy)
	if (not mission) then return end
	if (GMFRewardSplash:IsShown()) then return end
	local dbg=missionID==(tonumber(_G.MW) or 0)
	if (not skipbusy) then
		skipbusy=self:GetBoolean("IGM")
	end
	local ignoreMaxed=self:GetBoolean("IGP")
	local slots=mission.slots
	local missionCounters=counters[missionID]
	local ct=counterThreatIndex[missionID]
	local skipbusy=addon:GetBoolean("IGM")
	openParty(missionID,mission.numFollowers)
	for i=1,#slots do
		local threat=slots[i].icon
		local candidates=ct[threat]
		local choosen
		for i=1,#candidates do
			if (addon:GetFollowerStatusForMission(missionCounters[candidates[i]].followerID,skipbusy)) then
				choosen=best(choosen,candidates[i],missionCounters)
			end
		end
		if (choosen) then
			if (type(missionCounters[choosen]) ~="table") then
				error (format("%s %s %d %d",mission.name,threat,missionID,tonumber(choosen) or 0))
			end
			pushFollower(missionCounters[choosen].followerID)
		end
		if (not roomInParty()) then
			break
		end
	end
	storeFollowers(party.members)
	party.full= not roomInParty()
	party.perc=closeParty()
end
function addon:MatchMaker1(missionID,mission,party,skipbusy)
	if (not mission) then return end
	if (GMFRewardSplash:IsShown()) then return end
	local dbg=missionID==(tonumber(_G.MW) or 0)
	if (not skipbusy) then
		skipbusy=self:GetBoolean("IGM")
	end
	local ignoreMaxed=self:GetBoolean("IGP")
	local slots=mission.slots
	if (slots) then
		wipe(mission.countered)
		local countered=mission.countered
		openParty(missionID,mission.numFollowers)
		for i=1,#counters do
			local f=counters[i]
			local menace=f.name
			if (#countered[menace] == 0) then
				if (roomInParty() and self:GetFollowerStatusForMission(f.follower,skipbusy) and pushFollower(f.follower)) then
					tinsert(countered[menace],f.follower)
				end
			end
		end
		local perc=select(4,G.GetPartyMissionInfo(missionID)) -- If percentage is already 100, I'll try and add the most useless character
		local candidateMissions=10000
		local candidateRank=10000
		local candidateQuality=9999
		for x=1,3 do
			if (not roomInParty()) then break end
			local candidate
			local candidatePerc=perc
			for _,data in pairs(followersCache) do
				local followerID=data.followerID
				if (not isInParty(followerID) and self:GetFollowerStatusForMission(followerID,skipbusy)) then
					local missions=#followerMissions[followerID]
					local rank=data.rank
					local quality=data.quality
					xprint(dbg,"Verifying",self:GetFollowerData(followerID,'name'),missions,rank,quality)
					repeat
						if (mission.numFollowers==1 and  mission.xp and quality>4) then break end -- Pointless using a maxed follower for an xp only mission
						if (perc<=100) then
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
						end
					until true -- A poor man continue implementation using break
				end
			end
			if (candidate) then
				pushFollower(candidate)
				perc=select(4,G.GetPartyMissionInfo(missionID))
			end

		end
		storeFollowers(party.members)
		party.full= not roomInParty()
		party.perc=closeParty()
	end
end
function addon:TooltipAdder(missionID)
	local mission=self:GetMissionData(missionID)
	local button=GetMouseFocus()
--@debug@
	GameTooltip:AddLine("ID:" .. tostring(missionID))
	if (not mission) then GameTooltip:AddLine("E dove minchia è finita??") return end
	_G.MISSION=mission
--@end-debug@
	local f=GarrisonMissionListTooltipThreatsFrame
	if (not f.Env) then
		f.Env=CreateFrame("Frame",nil,f,"GarrisonAbilityCounterTemplate")
		f.Env:SetWidth(20)
		f.Env:SetHeight(20)
		f.Env:SetPoint("LEFT",f)
	end
	local t=f.EnvIcon:GetTexture();
	f.EnvIcon:Hide()
	--f.Env.Icon:SetTexture("Interface\\ICONS\\Achievement_ZoneSilverpine_01")
	f.Env.Icon:SetTexture(t)
	f.Env.Icon:SetWidth(20)
	f.Env.Icon:SetHeight(20)
	if (type(mission.counterers[t])=="table") then
		if (#mission.counterers[t]>0) then
			f.Env.Border:SetVertexColor(0,1,0)
		else
			f.Env.Border:SetVertexColor(1,0,0)
		end
		f.Env.Icon:Show()
		f.Env.Border:Show()
		f:Raise()
		f.Env:Show()
	else
		f.Env:Hide()
	end
--[[
		if (not f.EnvIcon.Mark) then
			local ck=CreateFrame("CheckButton",nil,f.EnvIcon,"UICheckButtonTemplate")
			ck:SetPoint("CENTER")
			ck:SetChecked(true)
			ck:GetCheckedTexture():SetVertexColor(0,1,0)
			f.EnvIcon.Marck=ck
			ck:Show()
		end
--]]
	GameTooltip:AddDoubleLine(t,"Environment")
	for i=1,#f.Threats do
		local t=f.Threats[i]
		GameTooltip:AddDoubleLine(t.Icon:GetTexture(),getAbilityName(t.Icon:GetTexture()))
	end
	GameTooltip:AddLine("Countered")
	for k,v in pairs(mission.countered) do
		GameTooltip:AddLine(k,C.Green())
		for kk,vv in pairs(v) do
			GameTooltip:AddDoubleLine(kk,vv)
		end
	end
	if (button.fromFollowerPage) then
		GameTooltip:AddLine(L["Only first 7 missions with over 60% success chance are shown"],C.Orange())
	end
end

function addon:_TooltipAdder(missionID,skipTT)
--@debug@
	if (not skipTT) then GameTooltip:AddLine("ID:" .. tostring(missionID)) end
--@end-debug@
	self:MatchMaker(missionID)
	local perc=select(4,G.GetPartyMissionInfo(missionID))
	self:GetRunningMissionData()
	local q=self:GetDifficultyColor(perc)
	if (not skipTT) then GameTooltip:AddDoubleLine(GARRISON_MISSION_SUCCESS,format(GARRISON_MISSION_PERCENT_CHANCE,perc),nil,nil,nil,q.r,q.g,q.b) end
	local buffed=new()
	local traited=new()
	local buffs=new()
	local traits=new()
	local fellas=new()
	availableFollowers=0
	self:GetRunningMissionData()
	for id,d in pairs(G.GetBuffedFollowersForMission(missionID)) do
		buffed[id]=d
	end
	for id,d in pairs(G.GetFollowersTraitsForMission(missionID)) do
		for x,y in pairs(d) do
--@debug@
			self.db.global.traits[y.traitID]=y.icon
--@end-debug@
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
		follower.rank=follower.level < 100 and follower.level or follower.iLevel
		if (not follower.isCollected) then break end
		if (not follower.status) then
			availableFollowers=availableFollowers+1
		end
		if (follower.status and self:GetBoolean('IGM')) then
		else
			local id=follower.followerID
			local b=buffed[id]
			local t=traited[id]
			local followerBias = G.GetFollowerBiasForMission(missionID,id);
			follower.bias=followerBias
			local formato=C("%3d","White")
			if (followerBias==-1) then
				formato=C("%3d","Red")
			elseif (followerBias < 0) then
				formato=C("%3d","Orange")
			end
			formato=formato.." %s"
--@debug@
			formato=formato .. " 0x+(0*8)  " .. id:sub(11)
--@end-debug@
			if (b) then
				if (not buffs[id]) then
					buffs[id]={rank=follower.rank,simple=follower.name,name=format(formato,follower.rank,follower.name),quality=follower.quality,status=(follower.status or AVAILABLE)}
				end
				for _,ability in pairs(b) do
					buffs[id].name=buffs[id].name .. " |T" .. tostring(ability.icon) .. ":0|t"
					if (not follower.status) then
						local aname=ability.name
						if (not fellas[aname]) then
							fellas[aname]={}
						end
						fellas[aname]={id=follower.followerID,rank=follower.rank,level=follower.level,iLevel=follower.iLevel,name=follower.name}
					end
				end
			end
			if (t) then
				if (not traits[id]) then
					traits[id]={rank=follower.rank,simple=follower.name,name=format(formato,follower.rank,follower.name),quality=follower.quality,status=follower.status or AVAILABLE}
				end
				for _,ability in pairs(t) do
					traits[id].name=traits[id].name .. " |T" .. tostring(ability.icon) .. ":0|t"
				end
			end
		end
	end
	local added=new()
	local maxfollowers=G.GetMissionMaxFollowers(missionID)
	requested[missionID]=maxfollowers
	local partyshown=false
	local perc=0
	if (next(traits) or next(buffs) ) then
		if (not skipTT) then GameTooltip:AddLine(GARRISON_FOLLOWER_CAN_COUNTER) end
		for id,v in pairs(buffs) do
			local status=(v.status == GARRISON_FOLLOWER_ON_MISSION and (timers[id] or GARRISON_FOLLOWER_ON_MISSION)) or v.status
			if (not skipTT) then self:AddLine(nil,v.name,status,v.quality) end
		end
		for id,v in pairs(traits) do
			local status=(v.status == GARRISON_FOLLOWER_ON_MISSION and (timers[id] or GARRISON_FOLLOWER_ON_MISSION)) or v.status
			if (not skipTT) then self:AddLine(nil,v.name,status,v.quality) end
		end
		if (not skipTT) then GameTooltip:AddLine(PARTY,C.White()) end
		partyshown=true
		local enemies = select(8,G.GetMissionInfo(missionID))
		--local missionInfo=G.GetBasicMissionInfo(missionID)
--@debug@
		--DevTools_Dump(fellas)
--@end-debug@
		for _,enemy in pairs(enemies) do
			for i,mechanic in pairs(enemy.mechanics) do
				local menace=mechanic.name
				local res
				if (fellas[menace]) then
					local followerID=fellas[menace].id
					res=fellas[menace].name
					local rc,code=pcall(G.AddFollowerToMission,missionID,followerID)
					if (rc and code) then
						tinsert(added,followerID)
					end
				end
				if (not skipTT) then
					if (res) then
						GameTooltip:AddDoubleLine(menace,res,0,1,0)
					else
						GameTooltip:AddDoubleLine(menace,' ',1,0,0)
					end
				end
			end
		end
		perc=select(4,G.GetPartyMissionInfo(missionID))
		if (perc < 100 and  #added < maxfollowers and next(traits))  then
			for id,v in pairs(traits) do
				local rc,code=pcall(G.AddFollowerToMission,missionID,id)
				if (rc and code) then
					tinsert(added,id)
					if (not skipTT) then GameTooltip:AddDoubleLine(ENVIRONMENT_SUBHEADER,v.simple,v.quality) end
					break
				end
			end
			perc=select(4,G.GetPartyMissionInfo(missionID))
		end
	end
	-- And then fill the roster
	local partysize=#added
	if (partysize < maxfollowers )  then
		for j=1,#followerList do
			local index=followerList[j]
			local follower=followers[index]
			if (not follower.isCollected) then
				break
			end
			if (follower.status and self:GetBoolean('IGM')) then
			else
				local rc,code=pcall(G.AddFollowerToMission,missionID,follower.followerID)
				if (rc and code) then
					if (not partyshown) then
						if (not skipTT) then GameTooltip:AddLine(PARTY,1) end
						partyshown=true
					end
					tinsert(added,follower.followerID)
					if (not skipTT) then
						GameTooltip:AddDoubleLine(SPELL_TARGET_TYPE4_DESC,follower.name,C.Orange.r,C.Orange.g,C.Orange.b)--SPELL_TARGET_TYPE1_DESC)
					end
					if (#added >= maxfollowers) then break end
				else
--@debug@
					xprint("Failed adding",follower.name,follower.followerID,rc,code)
--@end-debug@
				end
			end
		end
		perc=select(4,G.GetPartyMissionInfo(missionID))
	end
	local q=self:GetDifficultyColor(perc)
	if (not partyshown) then
		if (not skipTT) then GameTooltip:AddDoubleLine(PARTY,ANYONE,C.White.r,C.White.g,C.White.b) end
	end
	if (not skipTT) then GameTooltip:AddDoubleLine(GARRISON_MISSION_SUCCESS,format(GARRISON_MISSION_PERCENT_CHANCE,perc),nil,nil,nil,q.r,q.g,q.b) end
	local b=GameTooltip:GetOwner()
	successes[missionID]=perc
	if (availableFollowers < maxfollowers) then
		if (not skipTT) then GameTooltip:AddLine(GARRISON_PARTY_NOT_FULL_TOOLTIP,C:Red()) end
	else
	end
	if (not skipTT) then self:AddPerc(GameTooltip:GetOwner()) end
	for _,id in pairs(added) do
		local rc,code=pcall(G.RemoveFollowerFromMission,missionID,id)
--@debug@
		if (not rc) then xprint("Add",rc,code) end
--@end-debug@
	end
	-- Add a signature
	--local r,g,b=C:Silver()
	--GameTooltip:AddDoubleLine("GarrisonCommander",self.version,r,g,b,r,g,b)
	del(added)
--@debug@
	--DevTools_Dump(fellas)
--@end-debug@
	del(buffed)
	del(traited)
	del(buffs)
	del(traits)
	del(fellas)
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
function addon:ApplyIGM(value)
	if (not GMF) then return end
	switch("IGM")
	dirty=true
	self:RefreshMissions("Checked")
end
function addon:ApplyIGP(value)
	if (not GMF) then return end
	switch("IGP")
	dirty=true
	self:RefreshMissions("Checked")
end
function addon:GMF_OnDragStart(frame)
	if (not self:GetBoolean('MOVEPANEL')) then return end
	frame.IsSizingOrMoving=true
	if (IsShiftKeyDown()) then
		frame.IsSizing=true
		frame:StartSizing("BOTTOMRIGHT")
		frame:SetScript("OnUpdate",function(frame,elapsed)
			if (frame.timepassed and frame.timepassed >1) then
				self:RefreshMissions()
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
function addon:ApplyMOVEPANEL(value)
	if (not GMF) then return end
	switch("MOVEPANEL")
	if (value) then
		xprint("GMF MOVABLE")
		--GMF:SetMovable(true)
		--GMF:SetResizable(true)
		--GMF:RegisterForDrag("LeftButton")
		--self:RawHookScript(GMF,"OnDragStart","GMF_OnDragStart")
		--self:RawHookScript(GMF,"OnDragStop","GMF_OnDragStop")
	else
		xprint("GMF UNMOVABLE")
		GMF:SetScript("OnDragStart",nil)
		GMF:SetScript("OnDragStop",nil)
		GMF:ClearAllPoints()
		GMF:SetPoint("CENTER",UIParent)
		GMF:SetMovable(false)
	end
end

function addon:RefreshMissions(keepdata)
	self:BuildMissionsCache()
	if (self:IsAvailableMissionPage()) then
		if (not keepdata) then
			wipe(counters)
			wipe(parties)
		end
		GarrisonMissionList_UpdateMissions()
	end
end
function addon:GenerateDrawerPeriodic()
	return function(self)
		if (true) then return end
		if (self:IsRewardPage()) then return end
		if (GMF.IsMovingOrSizing) then return end
		if (GMF:GetHeight()<600) then return end
		if (GMF:GetWidth()< BIGSIZEW or GMF:GetHeight() < SIZEV) then
			xprint("Periodic redraw")
			self:GrowPanel(true)
		end
	end
end

function addon:GenerateTimersPeriodic()
	return coroutine.wrap(
		function(self)
			repeat
				local t=new()
				G.GetInProgressMissions(t)
				wipe(timers)
				wipe(onMission)
				for index=1,#t do
					local mission=t[index]
					for i=1,mission.numFollowers do
						timers[mission.followers[i]]=mission.timeLeft
						onMission[mission.followers[i]]=mission.missionID
					end
				end
				coroutine.yield()
			until false
		end
	)
end
function addon:BuildMissionsCache()
--@debug@
	local start=GetTime()
	xprint("Start")
	--for x=1,10 do -- stress test
--@end-debug@
	local t=new()
	G.GetAvailableMissions(t)
	for index=1,#t do
		local missionID=t[index].missionID
		self:BuildMissionCache(missionID,t[index])
		self:MatchMaker(missionID,self:GetMissionData(missionID),parties[missionID],true)
	end
	del(t)
--@debug@
	--end
	xprint("Done in",GetTime()-start)
--@end-debug@
end
function addon:BuildMissionCache(id,data)
	if (not	dbcache.seen[id]) then
		dbcache.seen[id]=time()
	end
	local mission=cache.missions[id]
	if (mission.name=="<newmission>") then

		for k,v in pairs(mission) do
			if (data[k]) then mission[k]=data[k]end
		end
		mission.rank=mission.level < 100 and mission.level or mission.iLevel
		mission.xp=true
		mission.resources=false
		for k,v in pairs(data.rewards) do
			if (not v.followerXP) then mission.xp=false end
			if (v.currencyID and v.currencyID==824) then mission.resource=false end
		end
		local _,xp,type,typeDesc,typeIcon,_,_,enemies=G.GetMissionInfo(id)
		if (not type) then
			xprint(true,"No type",id,data.name)
		else
			self.db.global.types[type]={name=typeDesc,icon=typeIcon}
		end
		wipe(mission.slots)
		local slots=mission.slots

		for i=1,#enemies do
			local mechanics=enemies[i].mechanics
			for i,mechanic in pairs(mechanics) do
				tinsert(slots,{name=mechanic.name,icon=mechanic.icon})
				self.db.global.abilities[mechanic.name]={desc=mechanic.description,icon=mechanic.icon}
			end
		end
		if (type) then
			tinsert(slots,{name=TYPE,icon=typeIcon})
		end
	end
	self:FillCounters(id,mission)
	--self:MatchMaker(id,mission)
	mission.basePerc=select(4,G.GetPartyMissionInfo(id))
end
function addon:SetDbDefaults(default)
	default.global=default.global or {}
	default.global["*"]={
	}
end
function addon:CreatePrivateDb()
	self.privatedb=self:RegisterDatabase(
		GetAddOnMetadata(me,"X-Database")..'perChar',
		{
			profile={
				seen={},
				history={
					['*']={
					}
			}	}
		},
		true)
	self.private=self:RegisterDatabase(
		"GACPrivateVolatile",
		{
			profile={
				missions={
				["*"]={
					missionID=0,
					counters={},
					countered={
						["*"]={}
					},
					counterers={
						["*"]={}
					},
					slots={
						["*"]=0
					},
					numFollowers=0,
					name="<newmission>",
					basePerc=0,
					durationSeconds=0,
					rewards={},
					level=0,
					iLevel=0,
					rank=0,
					locPrefix=false
				}
			}
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
function addon:wipe(i)
	DevTools_Dump(i)
	privatedb:ResetDB()
end
function addon:OnInitialized()
--@debug@
	LoadAddOn("Blizzard_DebugTools")
	self:DebugEvents()
--@end-debug@
	self:CreatePrivateDb()
	if (self.db.char.missionsCache) then
		self.db.char.missionsCache=nil
		for i,v in pairs(self.db.char.seen) do
			dbcache.seen[i]=v
		end
		self.db.char.seen=nil
	end
	self:RegisterEvent("GARRISON_MISSION_NPC_CLOSED",function(...) print(...) GCF:Hide() end)
	self:RegisterEvent("GARRISON_MISSION_NPC_OPENED",print)
	self:RegisterEvent("GARRISON_MISSION_STARTED")
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE")
	self:SafeHookScript("GarrisonMissionFrame","OnShow","SetUp",true)
	self:AddToggle("MOVEPANEL",true,L["Unlock Garrison Panel"])
	self:AddToggle("IGM",true,IGNORE_UNAIVALABLE_FOLLOWERS,IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL)
	self:AddToggle("IGP",true,L["Ignore maxed followers for xp only one follower missions"])
	print("Booting movepanel",self:GetBoolean("MOVEPANEL"))
--@debug@
	--Only Used for development
	self:RegisterEvent("GARRISON_MISSION_LIST_UPDATE",print)
	self:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE",print) --This event is quite useless, fires too often
	self:RegisterEvent("GARRISON_FOLLOWER_XP_CHANGED",print)
	self:RegisterEvent("GARRISON_FOLLOWER_ADDED",print)
	self:RegisterEvent("GARRISON_FOLLOWER_REMOVED",print)
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_LOOT",print)
	self:RegisterEvent("GARRISON_MISSION_FINISHED",print)
	self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE",print)
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE",print)
	self:RegisterEvent("GARRISON_UPDATE",print)
	self:RegisterEvent("GARRISON_USE_PARTY_GARRISON_CHANGED",print)
--@end-debug@
	return true
end
function addon:WipeMission(missionID)
	cache.missions[missionID]=nil
	counters[missionID]=nil
	dbcache.seen[missionID]=nil
	parties[missionID]=nil
	collectgarbage("step")


end
function addon:GARRISON_MISSION_NPC_CLOSED(event,...)
--@debug@
	print(event,...)
--@end-debug@
	GCF:Hide()
end
function addon:GARRISON_MISSION_STARTED(event,missionID)
--@debug@
	print(event,missionID)
--@end-debug@
	for i=1,3 do
		local m=parties[missionID].members[i]
		if (m) then
			onMission[m]=missionID
		end
	end
	dbcache.seen[missionID]=nil
	wipe(counters)
	wipe(parties)
	self:RefreshMissions(false)
end
function addon:GARRISON_MISSION_BONUS_ROLL_COMPLETE(event,missionID,completed,success)
--@debug@
	print(event,missionID)
--@end-debug@
	dbcache.seen[missionID]=nil
	tinsert(dbcache.history[missionID],{completed=time(),result=100,success=success})
	wipe(parties)
	wipe(counters)
end
function addon:GARRISON_MISSION_COMPLETE_RESPONSE(event,missionID,completed,success)
--@debug@
	print(event,missionID)
--@end-debug@
	dbcache.seen[missionID]=nil
	tinsert(dbcache.history[missionID],{completed=time(),result=100,success=success})
	wipe(parties)
	wipe(counters)
end

function addon:OptionOnClick(checkbox)
	self:SetBoolean(checkbox.flag,checkbox:GetChecked())
	self:Trigger(checkbox.flag)
end
function addon:Option(obj,rel,name,text)
	local b=CreateFrame("CheckButton",nil,obj,"UICheckButtonTemplate")
	b.text:SetText(text)
	b.flag=name
	self:HookScript(b,"OnCLick","OptionOnClick")
	obj[name]=b
	b:SetChecked(self:GetBoolean(name))
	switch(name,self:GetBoolean(name))
	b:SetPoint("LEFT",rel,"RIGHT",10,0)
	b:Show()
	return b.text
end
local elapsed=0
local interval=0.05
local lastmin=0
function addon:Clock(frame,ts)
	elapsed=elapsed+ts
	if (elapsed > interval ) then
		for k,d in pairs(coroutines) do
			local  co=coroutines[k]
			if (not co.func) then
				co.func=self["Generate"..k.."Periodic"](self)
				if (type(co.func) ~="function") then
--@debug@
					print("Periodic inesistente",k)
--@end-debug@
					co.func=function() end
				end
			end
			co.elapsed=co.elapsed+elapsed
			if not co.paused and co.elapsed > co.interval then
				co.elapsed=0
				co.paused=co.func(self)
			end
		end
		elapsed=0
	end
	local h,m=GetGameTime()
	if (m~=lastmin) then
		lastmin=m
		UpdateAddOnCPUUsage()
		print("MP",GetAddOnCPUUsage("MasterPlan"))
		print("GC",GetAddOnCPUUsage("GarrisonCommander"))
	end
end
function addon:ActivateButton(button,OnClick,Tooltiptext,persistent)
	print("Activting")
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
	print("Toggling",name)
	if (f:GetHeight() > 200) then
		f.savedHeight=f:GetHeight()
		f:SetHeight(200)
	else
		f:SetHeight(f.savedHeight)
	end
end
local helpwindow -- pseudo static
function addon:ShowHelpWindow(button)
	if (not helpwindow) then
		local AG=LibStub("AceGUI-3.0")
		helpwindow=AG:Create("Window")
		local r=AG:Create("Label")
		r:SetFullHeight(true)
		r:SetFullWidth(true)
		r:SetFontObject(GameFontNormalLarge2)
		r:SetText([[
Garrison Commander enhancec standard Garrison UI by adding a Menu header and  a secondary list of mission button to the right of the standard list.
Secondary button list:
 * Time since the first time we saw this mission in log
 * Success percent with the current followers selection guidelines
 * A "Good" party composition, on each member countered mechanics are shown.
 *** Green border means full counter, Orange border low level counter
Hovering on it shows a tooltip with:
 * Overall mission status
 * All members which can possibly play a role in the mission
Standard button enhancement
 * In rewards, actual quantity is shown (xp, money and resources) ot iLevel (item rewards)
 * Countered status
Menu Header:
 * Quick selection of which follower ignore for match making
 * Quick mission list order selection
----------------------------------------------------------------------------------------------------------
N.B. I dont love to replicate feature already found in other addons, but I was forced to replicate at least
those given by MasterPlan because MasterPlan clashes with GarrisonCommander.

			]])
		helpwindow:AddChild(r)
		helpwindow:SetTitle("Garrison Commander Help")
	end
	if (helpwindow:IsShown()) then
		helpwindow:Hide()
	else
		helpwindow:ClearAllPoints()
		helpwindow:SetPoint("CENTER")
		helpwindow:Show()
	end
end
function addon:Toggle(button)
	local f=button.Toggle
	local name=f:GetName() or "Unnamed"
	print("Toggling",name)
	if (f:IsShown()) then print("Hiding",name) f:Hide() else print("Showing",name) f:Show() end
	if (button.SetChecked) then
		button:SetChecked(f:IsShown())
	end
end
function addon:Options()
	print("Loading options setters")
	local base=CreateFrame("Frame",nil,UIParent,"GarrisonCommanderTitle")
	GCF=base
	GCF:SetWidth(BIGSIZEW)
	GCF:SetPoint("TOP",UIParent,0,-60)
	base:SetHeight(40)
	base:EnableMouse(true)
	self:RawHookScript(base,"OnUpdate","Clock")
	GCF:SetMovable(true)
	GCF:RegisterForDrag("LeftButton")
	GCF:SetScript("OnDragStart",function(frame)frame:StartMoving() end)
	GCF:SetScript("OnDragStop",function(frame) frame:StopMovingOrSizing() end)
	local rel=base.Signature
	rel=self:Option(base,rel,'IGM',L["Ignore busy followers"])
	rel=self:Option(base,rel,'IGP',L["Ignore maxed followers for xp only one follower missions"])
	rel=self:Option(base,rel,'MOVEPANEL',L["Unlock Panel"])
	--HelpButton
	local h=CreateFrame("Button",nil,base,"UIPanelCloseButton")
	h:SetFrameLevel(999)
	h:SetNormalTexture("interface\\buttons\\ui-microbutton-help-up")
	h:SetPushedTexture("interface\\buttons\\ui-microbutton-help-down")
	h:SetHeight(64)
	h:SetWidth(32)
	h:SetPoint("BOTTOMLEFT")
	self:ActivateButton(h,"ShowHelpWindow",L["Click to toggle Help page"])
	GCF.gcHELP=h
	--MinimizeButton
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
	self:Trigger("MOVEPANEL")
	self.Options=function() end
end

function addon:ScriptTrace(hook,frame,...)
--@debug@
	print("Triggered " .. C(hook,"red").." script on",C(frame,"Azure"),...)
--@end-debug@
end
function addon:IsProgressMissionPage()
	return GMF:IsShown() and GarrisonMissionFrameMissionsListScrollFrame:IsShown() and GMFMissions.showInProgress and not GMFFollowers:IsShown() and not GMF.MissionComplete:IsShown()
end
function addon:IsAvailableMissionPage()
	return GMF:IsShown() and GarrisonMissionFrameMissionsListScrollFrame:IsShown() and not GMFMissions.showInProgress  and not GMFFollowers:IsShown() and not GMF.MissionComplete:IsShown()
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
--@debug@
				print("PostHooked",name,hook)
--@end-debug@
			else
				self:HookScript(frame,hook,method)
--@debug@
				print("PreHooked",name,hook)
--@end-debug@
			end
		else
			if (postHook) then
				self:SecureHookScript(frame,hook,function(...) self:ScriptTrace(name,hook,...) end)
				print("DummyPostHooked:",name,hook)
			else
				self:HookScript(frame,hook,function(...) self:ScriptTrace(name,hook,...) end)
				print("DummyPreHooked:",name,hook)
			end
		end
--@debug@
	else
		print(C("Attempted hook for non existent:","red"),name,hook)
--@end-debug@
	end
end
function addon:_AddPerc(b,...)
	if (b and b.info and b.info.missionID and b.info.missionID ) then
		if (GMF.MissionTab.MissionList.showInProgress) then
			self:RenderButton(b)
			if (b.ProgressHidden) then
				return
			else
				b.ProgressHidden=true
				if (b.Success) then
					b.Success:Hide()
				end
				if (b.NotEnough) then
					b.NotEnough:Hide()
				end
				return
			end

		end
		local missionID=b.info.missionID
		local Perc=successes[missionID] or -2
		if (not b.Success) then
			b.Success=b:CreateFontString()
			if (masterplan) then
				b.Success:SetFontObject("GameFontNormal")
			else
				b.Success:SetFontObject("GameFontNormalLarge2")
			end
			b.Success:SetPoint("BOTTOMLEFT",b.Title,"TOPLEFT",0,3)
		end
		if (not b.NotEnough) then
			b.NotEnough=b:CreateFontString()
			if (masterplan) then
				b.NotEnough:SetFontObject("GameFontNormal")
				b.NotEnough:SetPoint("TOPLEFT",b.Title,"BOTTOMLEFT",150,-3)
			else
				b.NotEnough:SetFontObject("GameFontNormalSmall2")
				b.NotEnough:SetPoint("TOPLEFT",b.Title,"BOTTOMLEFT",0,-3)
			end
			b.NotEnough:SetText("(".. GARRISON_PARTY_NOT_FULL_TOOLTIP .. ")")
			b.NotEnough:SetTextColor(C:Red())
		end
		if (Perc <0 and not b:IsMouseOver()) then
			self:TooltipAdder(missionID,true)
			Perc=successes[missionID] or -2
		end
		if (Perc>=0) then
			if (masterplan) then
				b.Success:SetFormattedText(GARRISON_MISSION_PERCENT_CHANCE,successes[missionID])
			else
				b.Success:SetFormattedText(BUTTON_INFO,G.GetMissionMaxFollowers(missionID),successes[missionID])
			end
			local q=self:GetDifficultyColor(successes[missionID])
			b.Success:SetTextColor(q.r,q.g,q.b)
		else
			b.Success:SetText(UNKNOWN_CHANCE)
			b.Success:SetTextColor(1,1,1)
		end
		b.Success:Show()
		if (not requested[missionID]) then
			requested[missionID]=G.GetMissionMaxFollowers(missionID)
		end
		if (requested[missionID]>availableFollowers) then
			b.NotEnough:Show()
		else
			b.NotEnough:Hide()
		end
		b.ProgressHidden=false
	end
end
function addon:GarrisonMissionFrame_HideCompleteMissions()
	self:GrowPanel(true)
	self:RefreshMissions("MissionCompleteClose")
end
function addon:GarrisonFollowerListButton_OnClick(frame,button)
	if (button=="LeftButton" and not GarrisonMissionFrame.FollowerTab.Model:IsShown()) then
		if (frame.info.isCollected) then
			self:GarrisonFollowerPage_ShowFollower(frame.info,id)
		end
	end
end
-- Shamelessly stolen from Blizzard Code
function addon:FillMissionButton(button)
	local mission=button.info
	button.Title:SetWidth(0);
	button.Title:SetText(mission.name);
	button.Level:SetText(mission.level);
	if ( mission.durationSeconds >= GARRISON_LONG_MISSION_TIME ) then
		local duration = format(GARRISON_LONG_MISSION_TIME_FORMAT, mission.duration);
		button.Summary:SetFormattedText(PARENS_TEMPLATE, duration);
	else
		button.Summary:SetFormattedText(PARENS_TEMPLATE, mission.duration);
	end
	if ( button.Title:GetWidth() + button.Summary:GetWidth() + 8 < 275 - mission.numRewards * 65 ) then
		button.Title:SetPoint("LEFT", 165, 0);
		button.Summary:ClearAllPoints();
		button.Summary:SetPoint("BOTTOMLEFT", button.Title, "BOTTOMRIGHT", 8, 0);
	else
		button.Title:SetPoint("LEFT", 165, 10);
		button.Title:SetWidth(275 - mission.numRewards * 65);
		button.Summary:ClearAllPoints();
		button.Summary:SetPoint("TOPLEFT", button.Title, "BOTTOMLEFT", 0, -4);
	end
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
	GarrisonMissionButton_SetRewards(button, mission.rewards, mission.numRewards);
	button:Show();

end
function addon:GarrisonFollowerPage_ShowFollower(frame,followerID)
	local MAXMISSIONS=6
	local MINPERC=60
	local i=0
	-- frame has every info you can need on a follower, but here I dont really need them, maybe just counters
	--DevTools_Dump(table.Counters)
	local followerName=self:GetFollowerData(followerID,'name')
	local dbg=followerName=="Qiana Moonshadow"
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
				local missionID=onMission[followerID]
				list=GMF.MissionTab.MissionList.inProgressMissions
				m1=followerID
				perc=select(4,G.GetPartyMissionInfo(missionID))
				for j=1,#list do
					index[list[j].missionID]=j
				end
				tinsert(partyIndex,-missionID)
				GCFBusyStatus:SetText("")
			else
				GCFBusyStatus:SetText(self:GetFollowerStatus(followerID,false,true)) -- no time, colored
			end
		else
			GCFBusyStatus:SetText("")
			list=GMF.MissionTab.MissionList.availableMissions
			for j=1,#list do
				index[list[j].missionID]=j
			end
			for k,_ in pairs(parties) do
				tinsert(partyIndex,k)
			end
			table.sort(partyIndex,function(a,b) return parties[a].perc > parties[b].perc end)
		end
		for z = 1,#partyIndex do
			local missionID=partyIndex[z]
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
					panel:SetPoint("TOPLEFT",GCFMissions.Missions[i-1],"BOTTOMLEFT")
					panel:SetPoint("TOPRIGHT",GCFMissions.Missions[i-1],"BOTTOMRIGHT")
					tinsert(GCFMissions.Missions,panel)
					--Creo una riga nuova
				end
				panel.info=mission
				panel.id=index[missionID]
				panel.fromFollowerPage=true
				panel.LocBG:SetPoint("LEFT")
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
	i=i+1
	for x=i,#GCFMissions.Missions do GCFMissions.Missions[x]:Hide() end
end
function addon:SetUp(...)
	SIZEV=GMF:GetHeight()
	self:Options()
	self:StartUp()
end
function addon:StartUp(...)
	self:Unhook(GMF,"OnShow")
	self:PermanentEvents()
	GCF:Show()
	GMF:ClearAllPoints()
	GMF:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT")
	GMF:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT")
	GMFRewardSplash:ClearAllPoints()
	GMFRewardSplash:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT")
	GMFRewardSplash:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT")
	GMFRewardPage:ClearAllPoints()
	GMFRewardPage:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT")
	GMFRewardPage:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT")
	if (not GCFMissions) then
	local ml=CreateFrame("Frame","GCFMissions",GMFFollowers,"GarrisonCommanderFollowerMissionList")
		ml:SetPoint("TOPLEFT",GMFFollowers,"TOPRIGHT")
		ml:SetPoint("BOTTOMLEFT",GMFFollowers,"BOTTOMRIGHT")
		ml:SetWidth(450)
		ml:Show()
		GCFMissions=ml
		local fs=GMFFollowers:CreateFontString(nil, "BACKGROUND", "GameFontNormalHugeBlack")
		fs:SetPoint("TOPLEFT",GMFFollowers,"TOPRIGHT")
		fs:SetPoint("BOTTOMLEFT",GMFFollowers,"BOTTOMRIGHT")
		fs:SetText(AVAILABLE)
		fs:SetWidth(450)
		fs:Show()
		GCFBusyStatus=fs
	end
	self:GrowPanel(self:GetBoolean("BIGPANEL"))
	self:SecureHook("GarrisonMissionFrame_CheckCompleteMissions",function(...) print("GarrisonMissionFrame_CheckCompleteMissions",...) end)
	self:SecureHook("GarrisonMissionButton_AddThreatsToTooltip",function(id) self:TooltipAdder(id) end)
	self:SecureHook("GarrisonMissionButton_SetRewards","RenderButton")
	self:SecureHook("GarrisonFollowerListButton_OnClick")--,function(...) print("GarrisonFollowerListButton_OnClick",...) end)
	self:SecureHook("GarrisonFollowerPage_ShowFollower")--,function(...) print("GarrisonFollowerPage_ShowFollower",...) end)
	self:SecureHook("GarrisonMissionButton_OnClick")
	self:HookScript(GCF,"OnHide","CleanUp")
	-- Forcing refresh when needed without possibly disrupting Blizzard Logic
	self:SecureHook("GarrisonMissionFrame_HideCompleteMissions")	-- Mission reward completed
	self:SafeHookScript(GMFMissions,"OnShow",function (f,...) print(f:GetName(),'OnShow') self:GrowPanel(true) end )
	self:SafeHookScript(GMFFollowers,"OnShow",function (f,...) print(f:GetName(),'OnShow') self:GrowPanel(false) end )
	self:SecureHook("GarrisonMissionPage_ShowMission","UpdateMissionPage")
	self:BuildMissionsCache()
	GarrisonMissionList_UpdateMissions();
end
function addon:PermanentEvents()
	self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE")
	self:RegisterEvent("GARRISON_MISSION_STARTED")
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE")
	self:RegisterEvent("GARRISON_MISSION_NPC_CLOSED")
	self:DebugEvents()
end
function addon:DebugEvents()
	self:RegisterEvent("GARRISON_MISSION_LIST_UPDATE",print)
	self:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE",print) --This event is quite useless, fires too often
	self:RegisterEvent("GARRISON_FOLLOWER_XP_CHANGED",print)
	self:RegisterEvent("GARRISON_FOLLOWER_ADDED",print)
	self:RegisterEvent("GARRISON_FOLLOWER_REMOVED",print)
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_LOOT",print)
	self:RegisterEvent("GARRISON_MISSION_FINISHED",print)
	self:RegisterEvent("GARRISON_UPDATE",print)
	self:RegisterEvent("GARRISON_USE_PARTY_GARRISON_CHANGED",print)
	self:RegisterEvent("GARRISON_MISSION_NPC_OPENED",print)
end

function addon:CleanUp()
	self:UnhookAll()
	self:HookScript(GMF,"OnSHow","StartUp",true)
	self:PermanentEvents() -- Reattaching permanent events
	collectgarbage("collect")
	print("Cleaning up")
end
function addon:GetFollowerData(key,subkey)
	local k=followersCacheIndex[key]
	if (not followersCache[1]) then
		followersCache=G.GetFollowers()
		for i,v in pairs(followersCache) do
			if (not v.isCollected) then
				followersCache[i]=nil
			else
				v.rank=v.level==100 and v.iLevel or v.level
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
			if (subkey=='rank') then
				return t[k].level==100 and t[k].iLevel or t[k].level
			else
				return t[k][subkey]
			end
		else
			return t[k]
		end
	else
		return nil
	end
end
function addon:GetMissionData(missionID,subkey)
	local missionCache=cache.missions[missionID]
	if (missionCache.name=="<newmission>") then
		print("Found a new mission",missionID,"Refreshing mission list")
		self:BuildMissionCache(missionID)
	end
	if (subkey) then
		return missionCache[subkey]
	end
	return missionCache
end
function addon:GetFollowerStatusForMission(followerID,skipbusy)
	if (not skipbusy) then
		return true
	else
		return self:GetFollowerStatus(followerID) == AVAILABLE
	end
end
function addon:GetFollowerStatus(followerID,withTime,colored)
	local status=G.GetFollowerStatus(followerID)
	if (status and status== GARRISON_FOLLOWER_ON_MISSION and withTime) then
		status=timers[followerID]
	end
	if (status) then
		return colored and C(status,"Red") or status
	else
		return colored and C(AVAILABLE,"Green") or AVAILABLE
	end
end

function addon:ClearFollowers()
	wipe(followers)
end
local AceGUI=LibStub("AceGUI-3.0")
function addon:GetScroller(title)
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
function addon:cuttyPrint(scroll,level,k,v)
	if (type(level)=="table") then
		for k,v in pairs(level) do
			self:cuttyPrint(scroll,"",k,v)
		end
		return
	end
	if (type(v)=="table") then
		self:AddLabel(scroll,level..C(k,"Azure")..":" ..C("Table","Orange"))
		for kk,vv in pairs(v) do
			self:cuttyPrint(scroll,level .. "  ",kk,vv)
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
	self:cuttyPrint(scroll,followerMissions.missions[missionID])
end
function addon:DumpMission(missionID)
	local scroll=self:GetScroller("MissionCache " .. self:GetMissionData(missionID,'name'))
	self:cuttyPrint(scroll,cache.missions[missionID])
end
function addon:DumpCounters(missionID)
	local scroll=self:GetScroller("Counters " .. self:GetMissionData(missionID,'name'))
	self:cuttyPrint(scroll,counters[missionID])
	self:cuttyPrint(scroll,"Lista per follower","","")
	self:cuttyPrint(scroll,counterFollowerIndex[missionID])
	self:cuttyPrint(scroll,"Lista per threat","","")
	self:cuttyPrint(scroll,counterThreatIndex[missionID])
end
function addon:DumpCounterers(missionID)
	local scroll=self:GetScroller("Counterers " .. self:GetMissionData(missionID,'name'))
	self:cuttyPrint(scroll,cache.missions[missionID].counterers)
end
function addon:DumpParty(missionID)
	local scroll=self:GetScroller("Party " .. self:GetMissionData(missionID,'name'))
	self:cuttyPrint(scroll,parties[missionID])
end
function addon:UpdateMissionPage(missionInfo)
--@debug@
	print("UpdateMissionPage for",missionInfo.missionID)
--@end-debug@
	--DevTools_Dump(missionInfo)
	--self:BuildMissionData(missionInfo.missionID.missionInfo)
	local mission=self:GetMissionData(missionInfo.missionID)
	local t=new()
	t.members=new()
	self:MatchMaker(mission.missionID,mission,t,true)
	local members=t.members
	for i=1,#members do
		GarrisonMissionPage_ClearFollower(GMFMissionPageFollowers[i])
	end
	for i=1,#members do
		local info=self:GetFollowerData(members[i])
		print(members[i],info.name)
		GarrisonMissionPage_SetFollower(GMFMissionPageFollowers[i],info)
	end
	GarrisonMissionPage_UpdateMissionForParty()
	del(t.members)
	del(t)
end
local firstcall=true
function addon:GrowPanel(enlarge)
	if (not GMFRewardSplash:IsShown()) then
		--GMF:SetWidth(BIGSIZEW)
		GMF:SetHeight(BIGSIZEH)
		--GMFMissions:SetWidth(890)
		--GMFMissions:ClearAllPoints()
		--GMFMissions:SetPoint("TOPLEFT",GMF,25,-64)
		GMFMissions:SetPoint("BOTTOMRIGHT",GMF,-25,35)
		GMFFollowers:SetPoint("BOTTOMLEFT",GMF,-35,65)
		--GMFMissionsListScrollFrame:SetWidth(500)
		GMFMissionsListScrollFrameScrollChild:ClearAllPoints()
		GMFMissionsListScrollFrameScrollChild:SetPoint("TOPLEFT",GMFMissionsListScrollFrame)
		GMFMissionsListScrollFrameScrollChild:SetPoint("BOTTOMRIGHT",GMFMissionsListScrollFrame)
		GMFFollowersListScrollFrameScrollChild:SetPoint("BOTTOMLEFT",GMFFollowersListScrollFrame,-35,35)
	end
end
function addon:GetBiasColor(followerID,missionID)
	local rc,followerBias = pcall(G.GetFollowerBiasForMission,missionID,followerID)
	if (not rc) then
		print(followerID,missionID,followerBias)
		return "White"
	end
	if (followerBias==-1) then
		return "Red"
	elseif (followerBias < 0) then
		return "Orange"
	end
	return "White"
end
function addon:FillFollowerButton(frame,followerID,missionID)
	if (not frame) then return end
	local dbg=missionID==(tonumber(_G.MW) or 0)
	for i=1,#frame.Threats do
		frame.Threats[i]:Hide()
	end
	frame.NotFull:Hide()
	if (not followerID) then
		frame.PortraitFrame.Empty:Show()
		frame.Name:Hide()
		frame.Class:Hide()
		frame.Status:Hide()
		frame.PortraitFrame.LevelBorder:SetAtlas("GarrMission_PortraitRing_LevelBorder");
		frame.PortraitFrame.LevelBorder:SetWidth(58);
		frame.PortraitFrame.Level:SetText("")
		frame:SetScript("OnEnter",nil)
		GarrisonFollowerPortrait_Set(frame.PortraitFrame.Portrait)
		return
	end
	local info=G.GetFollowerInfo(followerID)
	--local info=followers[ID]
	frame.info=info
	frame.Name:Show();
	frame.Name:SetText(info.name);
	local color=self:GetBiasColor(followerID,missionID)
	frame.Name:SetTextColor(C[color]())
	xprint(dbg,G.GetFollowerStatus(followerID))
	frame.Status:SetText(self:GetFollowerStatus(followerID,true,true))
	frame.Status:Show()
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
	local tohide=1
	if (not GMF.MissionTab.MissionList.showInProgress) then
		local mission=self:GetMissionData(missionID)
		local c=mission.counterers[followerID]
		for i=1,min(#c, 4) do
			local t=frame.Threats[i]
			local tx=self.db.global.abilities[c[i]]
			if (tx) then
				t.Icon:SetTexture(tx.icon)
			else
				t.Icon:SetTexture(c[i])
			end
			t:Show()
			tohide=i+1
		end
	end
	for i=tohide,4 do frame.Threats[i]:Show() end
	frame:SetScript("OnEnter",GarrisonMissionPageFollowerFrame_OnEnter)
end
function addon:MissionButton_OnClick(frame,button)
	_G.MW=frame:GetParent().info.missionID
	print("Clicked",frame:GetParent():GetName(),button)
	if (button=="LeftButton") then
		self:RenderButton(frame:GetParent(),{},0)
	end
end
-- pseudo static
local scale=0.9
local x1,y1,x2,y2=10,0,12*scale,0
function addon:PrepareExtraButton(bg,limit)
	limit=limit or 3
	for numMembers=1,limit do
		local f=bg.Party[numMembers]
		if (not f) then
			f=CreateFrame("Button",nil,bg,"GarrisonCommanderMissionPageFollowerTemplate")
			f:SetPoint("LEFT",bg.Party[numMembers-1],"RIGHT",x2,y2)
			--f:SetFrameStrata("HIGH")
			tinsert(bg.Party,f)
		end
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
function addon:BuildExtraButton(button)
	local bg=CreateFrame("Button",nil,button,"GarrisonCommanderMissionButton")
	--button.LocBG:ClearAllPoints()
	--button.LocBG:SetPoint("RIGHT",200,0)
	button.Title:ClearAllPoints()
	button.Title:SetPoint("TOPLEFT",165,-5)
	button.Summary:ClearAllPoints()
	button.Summary:SetPoint("BOTTOMLEFT",165,5)
	button.LocBG:SetPoint("LEFT")
	bg:SetPoint("TOPLEFT",button,"TOPRIGHT")
	bg:SetPoint("RIGHT",GarrisonMissionFrameMissionsListScrollFrame,"RIGHT",-25,0)
	bg.button=button
	bg:SetScript("OnEnter",function(this) GarrisonMissionButton_OnEnter(this.button) end)
	bg:SetScript("OnLeave",function() GameTooltip:FadeOut() end)
	bg:RegisterForClicks("AnyUp")
	self:RawHookScript(bg,"OnClick","MissionButton_OnClick")
	button.gcPANEL=bg
	self:PrepareExtraButton(bg)
end
function addon:GarrisonMissionButton_SetRewards(button,rewards,numrewards)
end
function addon:GarrisonMissionButton_OnClick(tab,button)
	print("Interceptd",button,tab.fromFollowerPage)
	if (tab.fromFollowerPage) then
		GarrisonMissionFrame_SelectTab(1)
	end
end
function addon:RenderButton(button,rewards,numRewards)
--@debug@
	if (not button or not button.Title) then
		error(strconcat("Called on I dunno what ",tostring(button)," ", tostring(button:GetName())))
		return
	end
--@end-debug@
	if (self:IsRewardPage()) then return end
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
			elseif (reward.itemID and reward.quantity==1) then
				local _,_,q,i=GetItemInfo(reward.itemID)
				local c=ITEM_QUALITY_COLORS[q]
				if (not c) then c={r=1,g=1,b=1} end
				Reward.Quantity:SetText(i)
				Reward.Quantity:SetTextColor(c.r,c.g,c.b)
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
	local width=GMF.MissionTab.MissionList.showInProgress and BIGBUTTON or SMALLBUTTON
	button:SetWidth(width)
	if (not button.gcPANEL) then
		self:BuildExtraButton(button)
	else
	-- Summary is a bit stubborn, it must be moved every time
		button.Summary:ClearAllPoints()
		button.Summary:SetPoint("BOTTOMLEFT",165,5)
	end
	local panel=button.gcPANEL
	local missionInfo=button.info
	local missionID=missionInfo.missionID
	local dbg=missionID==(tonumber(_G.MW) or 0)
	xprint(dbg,C("Rendering button for mission "..missionID,"Red"))
	if (GMF.MissionTab.MissionList.showInProgress) then
		if (not button.inProgressFresh) then
			local perc=select(4,G.GetPartyMissionInfo(missionID))
			panel.Percent:SetFormattedText(GARRISON_MISSION_PERCENT_CHANCE,perc)
			panel.Age:Hide()
			local q=self:GetDifficultyColor(perc)
			panel.Percent:SetTextColor(q.r,q.g,q.b)
			button.inProgressFresh=true
			for i=1,3 do
				local frame=panel.Party[i]
				if (missionInfo.followers[i]) then
					self:FillFollowerButton(frame,missionInfo.followers[i],missionID)
					frame:Show()
				else
					frame:Hide()
				end
			end
		end
		return
	end
	button.inProgressFresh=false
	local mission=self:GetMissionData(missionID)
	local party=parties[missionID]
	xprint("Rendering mission",button.info.missionID)
	if (#party.members==0) then
		self:MatchMaker(missionID,mission,party)
	else
		xprint("Using old party",#party.members)
	end
	local perc=party.perc
	local notFull=false
	for i=1,3 do
		local frame=button.gcPANEL.Party[i]
		if (i>mission.numFollowers) then
			frame:Hide()
		else
			if (party.members[i]) then
				self:FillFollowerButton(frame,party.members[i],missionID)
				frame.NotFull:Hide()
			else
				self:FillFollowerButton(frame,false)
				frame.NotFull:Show()
			end
			frame:Show()
		end
	end
	if ( mission.locPrefix ) then
		panel.LocBG:Show();
		panel.LocBG:SetAtlas(mission.locPrefix.."-List");
	else
		panel.LocBG:Hide();
	end
	panel.Percent:SetFormattedText(GARRISON_MISSION_PERCENT_CHANCE,perc)
	local q=self:GetDifficultyColor(perc)
	panel.Percent:SetTextColor(q.r,q.g,q.b)
	panel.Percent:SetWidth(80)
	panel.Percent:SetJustifyH("RIGHT")
	local age=tonumber(dbcache.seen[missionID])
	if (age) then
		local day=60*24
		age=floor((time()-age)/60)
		local days=floor(age/day)
		if (days==0) then
			local hours=floor(age/60)
			panel.Age:SetFormattedText(AGE_HOURS,hours, age  -hours*60 )
		else
			panel.Age:SetFormattedText(AGE_DAYS,days,(age-days*day)/60)
		end
	else
		panel.Age:SetText(UNKNOWN)
	end
	panel.Age:Show()
	panel.Percent:Show()
end
_G.GAC=addon
--@do-not-package@
--[[
MasterPlan final button
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
--@end-do-not-package@
