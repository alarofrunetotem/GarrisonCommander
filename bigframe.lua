local me, ns = ...
local addon=LibStub("LibInit"):NewAddon(me,'AceHook-3.0','AceTimer-3.0','AceEvent-3.0') --#Addon
local C=addon:GetColorTable()
local L=addon:GetLocale()
local print=ns.print or print
local debug=ns.debug or print
local dump=ns.dump or print
local pairs=pairs
print("Loaded bigframe")
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
local GARRISON_MISSION_PERCENT_CHANCE=GARRISON_MISSION_PERCENT_CHANCE
local GARRISON_MISSION_SUCCESS=GARRISON_MISSION_SUCCESS -- "Success"
local GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS=GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS -- "%d Follower mission";
local GARRISON_PARTY_NOT_FULL_TOOLTIP=GARRISON_PARTY_NOT_FULL_TOOLTIP -- "You do not have enough followers on this mission."
local GMF=GarrisonMissionFrame
local GMFFollowerPage=GMF.FollowerTab
local GMFFollowers=GarrisonMissionFrameFollowers
local GMFMissionPage=GMF.MissionTab
local GMFMissionPageFollowers = GMFMissionPage.MissionPage.Followers
local GMFMissions=GarrisonMissionFrameMissions
local GMFMissionsTab1=GarrisonMissionFrameMissionsTab1
local GMFMissionsTab2=GarrisonMissionFrameMissionsTab2
local GMFMissionsTab3=GarrisonMissionFrameMissionsTab2
local GMFRewardPage=GMFMissions.MissionComplete
local GMFRewardSplash=GMFMissions.CompleteDialog
local GMFMissionsListScrollFrameScrollChild=GarrisonMissionFrameMissionsListScrollFrameScrollChild
local GMFMissionsListScrollFrame=GarrisonMissionFrameMissionsListScrollFrame
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
-- Panel sizes
local BIGSIZEW=1500
local BIGSIZEH=662
local SIZEW=950
local SIZEH=662
local BIGBUTTON=BIGSIZEW-700
local SMALLBUTTON=BIGSIZEW-900
local GameTooltip=GameTooltip
-- Want to know what I call!!
local GarrisonMissionButton_OnEnter=GarrisonMissionButton_OnEnter
local GarrisonFollowerList_UpdateFollowers=GarrisonFollowerList_UpdateFollowers
local GarrisonMissionList_UpdateMissions=GarrisonMissionList_UpdateMissions
local GarrisonMissionPage_ClearFollower=GarrisonMissionPage_ClearFollower
local GarrisonMissionPage_UpdateMissionForParty=GarrisonMissionPage_UpdateMissionForParty
local GarrisonMissionPage_SetFollower=GarrisonMissionPage_SetFollower

local ITEM_QUALITY_COLORS=ITEM_QUALITY_COLORS
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
		return ITEM_QUALITY_COLORS[4]
	end
end
if (LibDebug) then LibDebug() end
----- Local variables
local masterplan
local availableFollowers=0 -- Total numner of non in mission followers
local followersCache={}
local followersCacheIndex={}
local dirty=false
--- Parties storage
--
local parties=setmetatable({},{
	__index=function(t,k) rawset(t,k,{members={},perc=0,full=false}) return t[k] end
})

--- Follower Missions Info
--
local followerMissions=setmetatable({},{
	__index=function(t,k) rawset(t,k,{}) return t[k] end
})

-----------------------------------------------------
-- Temporary party management
local openParty,isInParty,pushFollower,removeFollower,closeParty,roomInParty,storeFollowers

do
	local ID,frames,members,maxFollowers=0,{},{},1
	---@function [parent=#local] openParty
	function openParty(missionID,followers)
		if (#frames > 0 or #members > 0) then
			error("Unbalanced openParty/closeParty")
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
				if (not rc) then print("Error removing", members[i],"from",ID,code) end
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
				if (not rc) then print("Error popping ", members[i]," from ",ID,code) end
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
-- This is a ugly hack while I rewrite this code for 2.0

local function cmp(a,b)
	if (a.name==TYPE and b.name~=TYPE) then return false end
	if (b.name==TYPE and a.name~=TYPE) then return true end
	if (a.name~=b.name) then return a.name < b.name end
	if (a.bias==-1) then return false end
	if (b.bias==-1) then return true end
	if (a.bias~=b.bias) then return (a.bias>b.bias) end
	if (a.rank ~= b.rank) then return (a.rank > b.rank) end
	return a.quality > b.quality
end


function addon:FillCounters(missionID,mission)
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
	if (not mission) then return end
	local slots=mission.slots
	wipe(mission.counters)
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
			tinsert(mission.counters,{name=l.name,follower=id,bias=bias,rank=rank,quality=quality})
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
			if (l.traitID ~= 236) then
				followerMissions[id][missionID]=1+ (tonumber(followerMissions[id][missionID]) or 0)
				tinsert(mission.counters,{name=TYPE,follower=id,bias=bias,rank=rank,quality=quality})
			end
		end
	end
	table.sort(mission.counters,cmp)
end
function addon:Check(missionID)

end
function addon:MatchMaker(missionID,mission,party,skipbusy)
	if (not mission) then return end
	if (GMFRewardSplash:IsShown()) then return end

	local dbg=missionID==(tonumber(_G.MW) or 0)
	if dbg then print(C("Matchmaker debug for " .. mission.name,"Yellow")) end
	if (not skipbusy) then
		skipbusy=self:GetBoolean("IGM")
	end
	local slots=mission.slots
	if (slots) then
		local countered=new()
		local counters=mission.counters
		if (dbg) then print("Preparying party") end
		openParty(missionID,mission.numFollowers)
		for i=1,#counters do
			local f=counters[i]
			local menace=f.name
			countered[menace]=countered[menace] or slots[menace] or 0
			if (countered[menace] > 0) then
				if (dbg) then print("Considering ",self:GetFollowerData(f.follower,'name'),"for",menace) end
				if (roomInParty() and self:GetFollowerStatusForMission(f.follower,skipbusy) and pushFollower(f.follower)) then
					if (dbg) then print("Taken ",self:GetFollowerData(f.follower,'name'),"for",menace) end
					countered[menace]=countered[menace]-1
				end
			end
		end
		del(countered)
		local perc=select(4,G.GetPartyMissionInfo(missionID)) -- If percentage is already 100, I'll try and add the most useless character
		local candidateMissions=10000
		local candidateRank=10000
		local candidateQuality=9999
		for x=1,3 do
			if dbg then print("Party filling") end
			if (not roomInParty()) then break end
			if dbg then print("Party is not full") end
			local candidate
			local candidatePerc=perc
			for _,data in pairs(followersCache) do
				local followerID=data.followerID
				if (not isInParty(followerID) and self:GetFollowerStatusForMission(followerID,skipbusy)) then
					local missions=#followerMissions[followerID]
					local rank=data.rank
					local quality=data.quality
					if (dbg) then print("Verifying",self:GetFollowerData(followerID,'name'),missions,rank,quality) end
					local skipMinimize
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
							skipMinimize=true -- Improvement, go with him
						elseif (newperc < candidatePerc) then
							skipMinimize=true -- Deprovement, go away
						end
					end
					if (not skipMinimize) then
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
					end
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
		if (dbg) then print(C("Matchmaker end","silver")) end
	end
end
function addon:TooltipAdder(missionID)
	local mission=self:GetMissionData(missionID)
--@debug@
	GameTooltip:AddLine("ID:" .. tostring(missionID))
	if (not mission) then GameTooltip:AddLine("E dove minchia è finita??") return end
--@end-debug@
	local party=parties[missionID]
	GameTooltip:AddDoubleLine("Base",mission.basePerc)
	GameTooltip:AddDoubleLine("Free",party.perc)
	for i=1,mission.numFollowers do
		local fid=party.members[i]
		if (fid) then
			GameTooltip:AddLine(self:GetFollowerData(fid,'name'))
		end
	end
	if (IsAltKeyDown()) then
		print("Alt down")
		_G.MW=missionID
		wipe(parties[missionID])
		self:RenderButton(GetMouseFocus(),true)
		_G.MW=nil
	end

end

function addon:TooltipAdderx(missionID,skipTT)
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
--@debug@
				self.db.global.abilities[i]={name=mechanic.name,icon=mechanic.icon}
--@end-debug@
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
					print("Failed adding",follower.name,follower.followerID,rc,code)
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
		if (not rc) then print("Add",rc,code) end
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
local function switch(obj,value)
	if (not obj) then return end
	if (value) then
		obj.text:SetTextColor(C:Green())
	else
		obj.text:SetTextColor(C:Silver())
	end
	obj:SetChecked(value)
end
function addon:ApplyIGM(value)
	if (not GMF) then return end
	print("ApplyIGM")
	dirty=true
	switch(GMF.gcIGM,value)
	self:RefreshMissions("Checked")
end
function addon:ApplyMOVEPANEL(value)
	if (not GMF) then return end
	print("ApplyMOVEPANEL",GMF.gcMOVEPANEL,value)
	switch(GMF.gcMOVEPANEL,value)
	if (value) then
		GMF:SetMovable(true)
		GMF:SetResizable(true)
		GMF:RegisterForDrag("LeftButton")
		GMF:SetScript("OnDragStart",function(frame) if (IsShiftKeyDown()) then frame:StartSizing("BOTTOMRIGHT") else frame:StartMoving() end end)
		GMF:SetScript("OnDragStop",function(frame) frame:StopMovingOrSizing() end)
	else
		GMF:SetScript("OnDragStart",nil)
		GMF:SetScript("OnDragStop",nil)
		GMF:ClearAllPoints()
		GMF:SetPoint("CENTER",UIParent)
		GMF:SetMovable(false)
	end
end

function addon:RefreshMissions(event)
--@debug@
	print("Refreshing due to",event)
--@end-debug@
	if (self:IsAvailableMissionPage()) then
		availableFollowers=0
		self:PrefillMissionList()
		wipe(parties)
		--@debug@
			print("Refresh missions called")
		--@end-debug@
		GarrisonMissionList_UpdateMissions()
	end
end
function addon:FixButtons()
	local self = GMF.MissionTab.MissionList
	local scrollFrame = self.listScroll
	local buttons = scrollFrame.buttons
	if (masterplan) then
		for i =1,#buttons do
			local b=buttons[i]
			b.Success:ClearAllPoints()
			if (b.Expire) then
				b.Success:SetPoint("TOPLEFT",b.Expire,"TOPRIGHT",5,0)
			else
				b.Success:SetPoint("TOPLEFT",b.Title,"BOTTOMLEFT",200,-3)
			end
			b.NotEnough:SetFontObject("GameFontNormalSmall2")
			b.NotEnough:ClearAllPoints()
			b.NotEnough:SetPoint("BOTTOMLEFT",b.Title,"TOPLEFT",0,3)
		end
	else
		for i =1,#buttons do
			local b=buttons[i]
			b.Success:ClearAllPoints()
			b.Success:SetPoint("BOTTOMLEFT",b.Title,"TOPLEFT",0,3)
			b.NotEnough:SetFontObject("GameFontNormalSmall")
			b.NotEnough:SetPoint("TOPLEFT",b.Title,"BOTTOMLEFT",0,-3)
		end
	end
end
function addon:FixForSure()
	local rc=pcall(self.FixButtons,self)
	if (not rc) then
		self:ScheduleTimer("FixForSure",1)
	end
end
function addon:MasterPlanDetection(novar,...)
	local _,_,_,loadable,reason=GetAddOnInfo("MasterPlan")
	masterplan=false
	if (loadable or reason=="DEMAND_LOADED") then
		masterplan=true
		print("Rehooking tooltip")
		self:SecureHook("GarrisonMissionList_UpdateMissions","RestoreTooltip")
		self:FixForSure()
	end
end
function addon:PrefillMissionList()
--@debug@
	local start=GetTime()
	print("Start")
	--for x=1,10 do -- stress test
--@end-debug@
	local t=new()
	G.GetAvailableMissions(t)
	for index=1,#t do
		local id=t[index].missionID
		self:BuildMissionCache(id,t[index])
	end
	del(t)
--@debug@
	--end
	print("Done in",GetTime()-start)
--@end-debug@
end
function addon:BuildMissionCache(id,data)
	if (not	self.db.char.seen[id]) then
		self.db.char.seen[id]=time()
	end
	local missionCache=self.db.char.missionsCache[id]
	if (missionCache.name=="<newmission>") then
		for k,v in pairs(missionCache) do
			if (data[k]) then missionCache[k]=data[k]end
		end
		missionCache.rank=missionCache.level < 100 and missionCache.level or missionCache.iLevel
		missionCache.seen=time()
	end
	missionCache.xp=true
	missionCache.resources=false
	for k,v in pairs(data.rewards) do
		if (not v.followerXP) then missionCache.xp=false end
		if (v.currencyID and v.currencyID==824) then missionCache.resource=false end
	end
	local slots=missionCache.slots
	local enemies=select(8,G.GetMissionInfo(id))
	for i=1,#enemies do
		local mechanics=enemies[i].mechanics
		for _,mechanic in pairs(mechanics) do
			slots[mechanic.name]= (slots[mechanic] or 0) +1
		end
	end
	slots[TYPE]=1
	self:FillCounters(id,missionCache)
	--self:MatchMaker(id,missionCache)
	missionCache.basePerc=select(4,G.GetPartyMissionInfo(id))
end
function addon:SetDbDefaults(default)

	default.global=default.global or {}
	default.global["*"]={}
	default.char=default.char or {}
	default.char.seen={}
	default.char.missionsCache={
		["*"]={
			missionID=0,
			counters={},
			slots={},
			numFollowers=0,
			name="<newmission>",
			basePerc=0,
			durationSeconds=0,
			rewards={},
			level=0,
			iLevel=0
		}
	}
	default.char.lastnumericversion=0
end
function addon:SetClean()
	dirty=false
end
function addon:UseCommonProfile()
	return true
end
function addon:OnInitializedx()
	self:RegisterEvent("GARRISON_MISSION_LIST_UPDATE",print)
	self:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE",print) --This event is quite useless, fires too often
	self:RegisterEvent("GARRISON_FOLLOWER_XP_CHANGED",print)
	self:RegisterEvent("GARRISON_FOLLOWER_ADDED",print)
	self:RegisterEvent("GARRISON_FOLLOWER_REMOVED",print)
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_LOOT",print)
	self:RegisterEvent("GARRISON_MISSION_FINISHED",print)
	self:RegisterEvent("GARRISON_MISSION_STARTED",print)
	self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE",print)
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE",print)
	self:RegisterEvent("GARRISON_UPDATE",print)
	self:RegisterEvent("GARRISON_USE_PARTY_GARRISON_CHANGED",print)
	self:RegisterEvent("GARRISON_MISSION_NPC_OPENED",print)
	self:RegisterEvent("GARRISON_MISSION_NPC_CLOSED",print)
	for i=1,20 do
		self:SafeHookScript("GarrisonMissionFrameFollowersListScrollFrameButton"..i,"OnClick",print)
	end
	print("Ho registrato in allegria")
end
function addon:OnInitialized()
--@debug@
	LoadAddOn("Blizzard_DebugTools")
--@end-debug@
	self:RegisterEvent("GARRISON_MISSION_NPC_OPENED",print)
	self:RegisterEvent("GARRISON_MISSION_NPC_CLOSED",print)
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
	self:RegisterEvent("GARRISON_MISSION_STARTED")
	self:SafeHookScript("GarrisonMissionFrameTab1","OnCLick")
	self:SafeHookScript("GarrisonMissionFrameTab2","OnCLick")
	self:SafeHookScript("GarrisonMissionFrameTab3","OnCLick")
	self:SafeHookScript(GMFMissions,"OnHide")
	self:SafeHookScript(GMFFollowers,"OnHide")
	self:SafeHookScript(GMF.MissionTab.MissionPage.CloseButton,"OnClick")
--@end-debug@
	self:SafeHookScript("GarrisonMissionFrame","OnShow","SetUp",true)
	self:AddToggle("MOVEPANEL",true,L["Makes Garrison Mission Panel Movable"]).width="full"
	self:AddToggle("IGM",true,IGNORE_UNAIVALABLE_FOLLOWERS,IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL).width="full"
	self:AddToggle("BIGPANEL",true,L["Uses a bigger mission panel"],L["Show a party preview"]).width="full"
	return true
end
function addon:GARRISON_MISSION_STARTED(event,missionid)
--@debug@
	print(event,missionid)
--@end-debug@
	wipe(self.db.char.missionsCache[missionid])
	self.db.char.seen[missionid]=nil
	dirty=true
	self:RefreshMissions(event)
end
function addon:Options()
	local f=GMF:CreateFontString()
	f:SetFontObject(GameFontNormalSmall)
	--f:SetHeight(32)
	f:SetText(me .. L[" Options:"])
	--f:SetTextColor(C:Azure())
	f:Show()
	GMF.GCLabel=f
	local b=CreateFrame("CheckButton","gcIGM",GMF,"UICheckButtonTemplate")
	b.text:SetText(L["Ignore busy followers"])
	b:SetScript("OnCLick",function(b) self:Trigger('IGM',b:GetChecked()) end)
	b:Show()
	GMF.gcIGM=b
	local l=CreateFrame("CheckButton","gcMOVEPANEL",GMF,"UICheckButtonTemplate")
	l.text:SetText(L["Unlock Panel"])
	l:SetScript("OnCLick",function(b) self:Trigger('MOVEPANEL',b:GetChecked()) end)
	l:Show()
	GMF.gcMOVEPANEL=l
	self:ApplyIGM(self:GetBoolean('IGM'))
	self:ApplyMOVEPANEL(self:GetBoolean('MOVEPANEL'))
--@debug@
	local s=CreateFrame("Frame","GACStatus",GMF)
	s:SetHeight(32)
	local st=s:CreateFontString()
	s.text=st
	st:SetFontObject(GameFontNormalSmall)
	st:Show()
	st:SetAllPoints()
	f:SetPoint("BOTTOMLEFT",GMF,"TOPLEFT",10,15)
	b:SetPoint("TOPLEFT",f,"TOPRIGHT",10,10)
	l:SetPoint("TOPLEFT",b,"TOPRIGHT",10+b.text:GetWidth(),0)
	s:SetPoint("TOPLEFT",l,"TOPRIGHT",10+l.text:GetWidth(),0)
	self:HookScript(s,"OnUpdate","Status")
--@end-debug@
end

function addon:ScriptTrace(hook,frame,...)
--@debug@
	print("Triggered " .. C(hook,"red").." script on",C(frame,"Azure"),...)
--@end-debug@
end

function addon:Status(frame)
	frame.text:SetText(format("PM:%s AM:%s FL:%s RP:%s MP:%s Av Fol: %d",
		self:IsProgressMissionPage() and 'Yes' or 'Not',
		self:IsAvailableMissionPage() and 'Yes' or 'Not',
		self:IsFollowerList() and 'Yes' or 'Not',
		self:IsRewardPage() and 'Yes' or 'Not',
		self:IsMissionPage() and 'Yes' or 'Not'),
		availableFollowers
	)
	frame:SetWidth(frame.text:GetWidth())
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
function addon:AddPerc(b,...)
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
function addon:SetUp(...)
	self:Options()
	self:MasterPlanDetection()
	self:StartUp()
end
function addon:StartUp(...)
	self:Unhook(GMF,"OnShow")
	self:GrowPanel(self:GetBoolean("BIGPANEL"))
	self:SecureHook("GarrisonMissionFrame_CheckCompleteMissions",function(...) print("GarrisonMissionFrame_CheckCompleteMissions",...) end)
	self:SecureHook("GarrisonMissionButton_AddThreatsToTooltip",function(id) self:TooltipAdder(id) end)
	self:SecureHook("GarrisonMissionButton_SetRewards","RenderButton")
	self:HookScript(GMF,"OnHide","CleanUp")
	-- Forcing refresh when needed without possibly disrupting Blizzard Logic
	self:SecureHook("GarrisonMissionFrame_HideCompleteMissions",function() addon:RefreshMissions("MissionCompleteClose") end)	-- Mission reward completed
	self:SafeHookScript(GMFMissions,"OnShow",function (f,...) print(f:GetName(),'OnShow') self:GrowPanel(true) end )
	self:SafeHookScript(GMFFollowers,"OnShow",function (f,...) print(f:GetName(),'OnShow') self:GrowPanel(false) end )
	self:SecureHook("GarrisonMissionPage_ShowMission","UpdateMissionPage")
	self:RefreshMissions()
end
function addon:CleanUp()
	self:UnhookAll()
	self:SafeHookScript("GarrisonMissionFrame","OnSHow","StartUp",true)
	collectgarbage("collect")
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
function addon:GetMissionData(missionID)
	local missionCache=self.db.char.missionsCache[missionID]
	if (missionCache.name=="<newmission>") then
		print("Found a new mission",missionID,"Refreshing mission list")
		self:PrefillMissionList()
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
function addon:GetFollowerStatus(followerID,withTime)
	local status=G.GetFollowerStatus(followerID)
	if (status and status== GARRISON_FOLLOWER_ON_MISSION and withTime) then
		local t=GMF.MissionTab.MissionList.inProgressMissions
		for i=1,#t do
			for k=1,#t.followers do
				if (t.followers[k]==followerID) then
					return t.timeLeft
				end
			end
		end
	end
	return status or AVAILABLE
end

function addon:ClearFollowers()
	wipe(followers)
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
function addon:DumpFollowerMissions()
	for k,v in pairs(followerMissions) do
		print(self:GetFollowerData(k,'name'))
		for kk,vv in pairs(v) do
			print(kk,vv)
		end
	end
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
	if (enlarge and not GMFRewardSplash:IsShown()) then
		print("GrowPanel","big")
		GMF:SetWidth(BIGSIZEW)
		GMF:SetHeight(BIGSIZEH)
		--GMFMissions:SetWidth(890)
		GMFMissions:ClearAllPoints()
		GMFMissions:SetPoint("TOPLEFT",GMF,25,-43)
		GMFMissions:SetPoint("BOTTOMRIGHT",GMF,-25,20)
		--GMFMissionsListScrollFrame:SetWidth(500)
		GMFMissionsListScrollFrameScrollChild:ClearAllPoints()
		GMFMissionsListScrollFrameScrollChild:SetPoint("TOPLEFT",GMFMissionsListScrollFrame)
		GMFMissionsListScrollFrameScrollChild:SetPoint("BOTTOMRIGHT",GMFMissionsListScrollFrame)
		if (firstcall) then
			local h=CreateFrame("Frame",nil,GMF,"UIPanelDialogTemplate")
			h:SetFrameLevel(999)
			h:SetWidth(400)
			h:SetHeight(600)
			h:SetFrameStrata("DIALOG")
			h:SetFrameLevel(999)
			h.title:SetText("Garrison Commander Help")
			h:Show()
			GMF.gcHELPDIALOG=h
			local f=CreateFrame("Frame",nil,GMF)
			local s=f:CreateFontString("GarrisonCommanderTitle","OVERLAY")
			f:SetFrameStrata("HIGH")
			f:SetFrameLevel(999)
			s:SetFontObject("QuestTitleFontBlackShadow")
			s:SetPoint("TOPLEFT")
			s:SetPoint("BOTTOMRIGHT",-40,0)
			f:SetHeight(50)
			f:SetWidth(400)
			s:SetText("Garrison Commander")
			f.text=s
			f:SetPoint("TOP",GMF,"TOP",0,-15)
			GMF.gcTITLE=f
			local h=CreateFrame("Button",nil,f,"UIPanelCloseButton")
			h:SetFrameLevel(999)
			h:SetNormalTexture("interface\\buttons\\ui-microbutton-help-up")
			h:SetPushedTexture("interface\\buttons\\ui-microbutton-help-down")
			h:SetHighlightTexture("interface\\buttons\\ui-microbutton-hilight")
			h:SetHeight(48)
			h:SetWidth(32)
			h:SetScript("OnClick",function() GMF.gcHELPDIALOG:SetPoint("TOP") GMF.gcHELPDIALOG:Show() end)
			h:SetPoint("TOPRIGHT")
			h:SetScript("OnEnter",function(this)
				GameTooltip:SetOwner(this, "ANCHOR_CURSOR_RIGHT")
				GameTooltip:SetText(L["Click to show help page"])
				GameTooltip:Show()
			end
			)
			h:SetScript("OnLeave",function() GameTooltip:FadeOut() end)
			h.tooltip="tooltip"
			h.toolTip="toolTip"
			h.ToolTip="ToolTip"
			h.Tooltip="Tooltip"
			GMF.gcHELP=h
			firstcall=nil
		end
		GMF.gcTITLE:Show()
	else
		print("GrowPanel","small")
		GMF:SetWidth(SIZEW)
		GMF:SetHeight(SIZEH)
		if (GMF.gcTITLE) then GMF.gcTITLE:Hide() end
	end
end
function addon:FillFollowerButton(frame,ID,useful)
	if (not frame) then return end
	if (not ID) then
		frame.PortraitFrame.Empty:Show()
		print("Requested",ID,type(ID))
		if (type(ID)=="boolean") then
			frame.Name:SetText(GARRISON_PARTY_NOT_FULL_TOOLTIP)
			frame.Name:SetTextColor(C.Red())
			frame.Name:Show()
			frame.Name:SetWidth(200)
		else
			frame.Name:Hide()
		end
		frame.Class:Hide()
		frame.PortraitFrame.LevelBorder:SetAtlas("GarrMission_PortraitRing_LevelBorder");
		frame.PortraitFrame.LevelBorder:SetWidth(58);
		frame:SetScript("OnEnter",nil)
		return
	end
	local info=G.GetFollowerInfo(ID)
	--local info=followers[ID]
	frame.info=info
	frame.Name:Show();
	frame.Name:SetText(info.name);
	if (useful) then
		frame.Name:SetTextColor(C.Green())
	else
		frame.Name:SetTextColor(C.Yellow())
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
	frame:SetScript("OnEnter",GarrisonMissionPageFollowerFrame_OnEnter)
end
function addon:BuildExtraButton(button)
	local bg=CreateFrame("Button",nil,button,"GarrisonCommanderButtonsBackground")
	bg:SetPoint("TOPLEFT",button,"TOPRIGHT")
	bg:SetPoint("RIGHT",GarrisonMissionFrameMissionsListScrollFrame,"RIGHT",-25,0)
	bg.button=button
	bg:SetScript("OnEnter",function(this) GarrisonMissionButton_OnEnter(this.button) end)
	bg:SetScript("OnLeave",function() GameTooltip:FadeOut() end)
	bg:SetScript("OnClick",function() bg.button:Click() end)
	button.gcPANEL=bg
	button.Party={}
	for i=1,3 do
		local f=CreateFrame("Button",nil,button,"GarrisonCommanderMissionPageFollowerTemplate")
		f:RegisterForClicks()
		f:SetScript("OnDragStart",nil)
		f:SetScript("OnDragStop",nil)
		f:SetScript("OnReceiveDrag",nil)
		f:SetScript("OnClick",nil)
		f:SetScale(0.8)
		f:SetFrameStrata("HIGH")
		button.Party[i]=f
		f:ClearAllPoints()
		if (i==1) then
			f:SetPoint("BOTTOMLEFT",bg.Percent,"BOTTOMRIGHT",10,10)
		else
			f:SetPoint("LEFT",button.Party[i-1],"RIGHT",12,0)
		end
	end
end
function addon:RenderButton(button,dbg)
	if (not button or not button.Title) then print("Called on I dunno what",button,button:GetName()) return end
	if (self:IsRewardPage()) then return end
	local width=GMF.MissionTab.MissionList.showInProgress and BIGBUTTON or SMALLBUTTON
	button:SetWidth(width)
	if (not button.gcPANEL) then
		self:BuildExtraButton(button)
	end
	local panel=button.gcPANEL
	local missionInfo=button.info
	if (GMF.MissionTab.MissionList.showInProgress) then
		if (not button.inProgressFresh) then
			panel.Percent:SetText(UNKNOWN_CHANCE)
			button.inProgressFresh=true
			for i=1,3 do
				local frame=button.Party[i]
				if (missionInfo.followers[i]) then
					self:FillFollowerButton(frame,missionInfo.followers[i])
					frame:Show()
				else
					frame:Hide()
				end
			end
		end
		return
	end
	button.inProgressFresh=false
	local missionID=missionInfo.missionID
	if (dbg) then print("RenderButton",missionID) end
	local mission=self:GetMissionData(missionID)
	local party=parties[missionID]
	if (#party.members==0) then
		self:MatchMaker(missionID,mission,party)
	end
	local perc=party.perc
	for i=1,3 do
		local frame=button.Party[i]
		if (i>mission.numFollowers) then
			frame:Hide()
		else
			if (party.members[i]) then
				self:FillFollowerButton(frame,party.members[i])
			else
				self:FillFollowerButton(frame,false)
			end
			frame:Show()
		end
	end
	if (perc>=0) then
		panel.Percent:SetFormattedText(GARRISON_MISSION_PERCENT_CHANCE,perc)
		local q=self:GetDifficultyColor(perc)
		panel.Percent:SetTextColor(q.r,q.g,q.b)
	else
		panel.Percent:SetText(UNKNOWN_CHANCE)
		panel.Percent:SetTextColor(C.Silver())
	end
	panel.Percent:Show()
end
_G.GAC=addon
--@do-not-package@
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
