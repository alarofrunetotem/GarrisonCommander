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
local masterplan
local followers={}
local dirty={}
local successes={}
local requested={}
local missionSlots={}
local availableFollowers=0 -- Total numner of non in mission followers
local GMF
local GMFFollowers
local GMFMissions
local GMFTab1
local GMFTab2
local GMFTab3
local GMFMissionsTab1
local GMFMissionsTab2
local GMFMissionsTab3
local GMFMissionsListScrollFrame
local GMFMissionsListScrollFrameScrollChild
local GMFFollowerPage
local GMFMissionPage
local GMFList
local G
local GARRISON_FOLLOWER_WORKING=GARRISON_FOLLOWER_WORKING -- "Working
local GARRISON_FOLLOWER_ON_MISSION=GARRISON_FOLLOWER_ON_MISSION -- "On Mission"
local GARRISON_FOLLOWER_INACTIVE=GARRISON_FOLLOWER_INACTIVE --"Inactive"
local GARRISON_FOLLOWER_EXHAUSTED=GARRISON_FOLLOWER_EXHAUSTED -- "Recovering (1 Day)"
local GARRISON_BUILDING_SELECT_FOLLOWER_TITLE=GARRISON_BUILDING_SELECT_FOLLOWER_TITLE -- "Select a Follower";
local GARRISON_BUILDING_SELECT_FOLLOWER_TOOLTIP=GARRISON_BUILDING_SELECT_FOLLOWER_TOOLTIP -- "Click here to assign a Follower";
local GARRISON_FOLLOWER_CAN_COUNTER=GARRISON_FOLLOWER_CAN_COUNTER -- "This follower can counter:"
local GARRISON_MISSION_SUCCESS=GARRISON_MISSION_SUCCESS -- "Success"
local GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS=GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS -- "%d Follower mission";
local UNKNOWN_CHANCE=GARRISON_MISSION_PERCENT_CHANCE:gsub('%%d%%%%',UNKNOWN)
local GARRISON_MISSION_PERCENT_CHANCE=GARRISON_MISSION_PERCENT_CHANCE .. " (Estimated)"
local BUTTON_INFO=GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS.. " " .. GARRISON_MISSION_PERCENT_CHANCE
local GARRISON_FOLLOWERS=GARRISON_FOLLOWERS -- "Followers"
local GARRISON_PARTY_NOT_FULL_TOOLTIP=GARRISON_PARTY_NOT_FULL_TOOLTIP -- "You do not have enough followers on this mission."
local AVAILABLE=AVAILABLE -- "Available"
local PARTY=PARTY -- "Party"
local ENVIRONMENT_SUBHEADER=ENVIRONMENT_SUBHEADER -- "Environment"
local SPELL_TARGET_TYPE4_DESC=capitalize(SPELL_TARGET_TYPE4_DESC) -- party member
local SPELL_TARGET_TYPE1_DESC=capitalize(SPELL_TARGET_TYPE1_DESC) -- any
local ANYONE='('..SPELL_TARGET_TYPE1_DESC..')'
local IGNORE_UNAIVALABLE_FOLLOWERS=IGNORE.. ' ' .. UNAVAILABLE .. ' ' .. GARRISON_FOLLOWERS
local IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL=IGNORE.. ' ' .. GARRISON_FOLLOWER_INACTIVE .. ',' .. GARRISON_FOLLOWER_ON_MISSION ..',' .. GARRISON_FOLLOWER_WORKING.. ','.. GARRISON_FOLLOWER_EXHAUSTED .. ' ' .. GARRISON_FOLLOWERS
IGNORE_UNAIVALABLE_FOLLOWERS=capitalize(IGNORE_UNAIVALABLE_FOLLOWERS)
IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL=capitalize(IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL)
local GameTooltip=GameTooltip
local GetItemQualityColor=GetItemQualityColor
local timers={}
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
function addon:GetDifficultyColor(perc)
	local difficulty='trivial'
	if(perc >90) then
		difficulty='standard'
	elseif (perc >74) then
		difficulty='difficult'
	elseif(perc>49) then
		difficulty='verydifficult'
	elseif(perc >20) then
		difficulty='impossible'
	end
	return QuestDifficultyColors[difficulty]
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


function addon:MatchMaker(missionID)
	local mission=self:GetMissionData(missionID)
	-- mission
	-- 	.description
	--	.cost
	--	.duration
	--	.duratonSeconds
	--	.level
	--	.type
	--	.locPrefix
	--	.rewards= {
	--		[rewardid]={
	--			itemId
	--			quantity
	--		}
	--	}
	--	.numRewards
	--	.numFollowers
	--	.state
	--	.iLevel
	--	.name
	--	.followers {} (empty for available
	--	.location
	--	.isRare
	--	.typeAtlas
	--	.missionID
	if (not mission) then return end
	print(C(mission.name,'Yellow'))
	local slots=missionSlots[missionID]
	if (not slots) then
		slots={counters={}}
		local enemies=select(8,G.GetMissionInfo(missionID))
		for i=1,#enemies do
			print(C(enemies[i].name,'Red'))
			local mechanics=enemies[i].mechanics
			for _,mechanic in pairs(mechanics) do
				slots[mechanic.name]= (slots[mechanic] or 0) +1
			end
		end
		slots[TYPE]=1
	end
	--slots[n]={
	--	portraitFileDataID
	--	displayID
	--	name
	--	mechanics={
	--		[abilityID]={
	--			description
	--			name
	--			icon
	--		}
	--	}
	print(mission.name)
	if (slots.counters[1]) then
		DevTools_Dump(slots)
		return
	end
	print("Threats")
	for x,y in pairs(slots) do
		print("Slot",x,y)
	end
	print("Abilities")
	for id,d in pairs(G.GetBuffedFollowersForMission(missionID)) do
		local level=self:GetFollowerData(id,'level')
		local bias= G.GetFollowerBiasForMission(missionID,id);
		local name=self:GetFollowerData(id,'name')
		local iLevel=self:GetFollowerData(id,'iLevel')
		local quality=self:GetFollowerData(id,'quality')
		print(C(name,'azure'),level,bias)
		for i,l in pairs(d) do
			-- i is meaningful
			-- l.counterIcon
			-- l.name
			-- l.counterName
			-- l.icon
			-- l.description
			print("Counters",l.name)
			tinsert(slots.counters,{name=l.name,icon=l.icon,follower=id,bias=bias,rank=level<100 and level or iLevel,quality=quality})
		end
	end
	print("Env")
	for id,d in pairs(G.GetFollowersTraitsForMission(missionID)) do
		local level=self:GetFollowerData(id,'level')
		local bias= G.GetFollowerBiasForMission(missionID,id);
		local name=self:GetFollowerData(id,'name')
		print(C(name,'azure'),level,bias)
		for i,l in pairs(d) do
			--l.traitID
			--l.icon
			if (l.traitID ~= 236) then
				tinsert(slots.counters,{name=TYPE,icon=l.icon,level=level,follower=id})
			end
		end
	end
	table.sort(slots,cmp)
	missionSlots[missionID]=slots

end
function addon:PrefillMissionPage(missionPage)
	if (not IsControlKeyDown()) then return end
	local missionInfo = missionPage.missionInfo;
	if ( not missionPage.missionInfo or not missionPage:IsVisible() ) then
		return;
	end
	local ID=missionInfo.missionID
	local slot=missionSlots[ID]
	if (slot) then
		local menaces=copy(slot)
		DevTools_Dump(slot.counters)
		for i=1,#slot.counters do
			local f=slot.counters[i]
			print("Considering ",self:GetFollowerData(f.follower,'name'),"for",f.name)
			if (menaces[f.name] and menaces[f.name]) then
				print("IS",f.name)
				if (self:GetFollowerStatus(f.follower)==AVAILABLE) then
					--GarrisonMissionPage_AddFollower(f.follower)
					print("Just addedd ",self:GetFollowerData(f.follower,'name'),"for",f.name)
				end
			end
		end
	end
end
function addon:TooltipAdder(missionID,skipTT)
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
		GarrisonFollowerList_UpdateFollowers(GarrisonMissionFrame.FollowerList)
	end
end
function addon:CacheFollowers()
	followers=G.GetFollowers()
end
function addon:GetRunningMissionData()
	local list=GarrisonMissionFrame.MissionTab.MissionList
	G.GetInProgressMissions(list.inProgressMissions);
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

function addon:ApplyMOVEPANEL(value)
	if (not GMF) then return end
	if (value) then
		GMF:SetMovable(true)
		GMF:RegisterForDrag("LeftButton")
		GMF:SetScript("OnDragStart",function(frame) frame:StartMoving() end)
		GMF:SetScript("OnDragStop",function(frame) frame:StopMovingOrSizing() end)
	else
		GMF:SetScript("OnDragStart",nil)
		GMF:SetScript("OnDragStop",nil)
		GMF:ClearAllPoints()
		GMF:SetPoint("CENTER",UIParent)
		GMF:SetMovable(false)
	end
end

function addon:OnInitialized()
--@debug@
	LoadAddOn("Blizzard_DebugTools")
--@end-debug@
	self.OptionsTable.args.on=nil
	self.OptionsTable.args.off=nil
	self.OptionsTable.args.standby=nil
	self:RegisterEvent("ADDON_LOADED")
	self:AddToggle("MOVEPANEL",true,L["Makes Garrison Mission Panel Movable"]).width="full"
	self:AddToggle("IGM",false,IGNORE_UNAIVALABLE_FOLLOWERS,IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL).width="full"
	self:loadHelp()
	self.DbDefaults.global["*"]={}
	self.db:RegisterDefaults(self.DbDefaults)
	return true
end

function addon:ScriptTrace(hook,frame,...)
--@debug@
	print(C(frame:GetName(),"Azure") .. ": " .. C(hook,"red") .. "(",...)
--@end-debug@
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
		return self:SecureHookScript(frame,hook,function(...) addon:ScriptTrace(hook,...) end)
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
		return self:SecureHookScript(frame,hook,function(...) addon:ScriptTrace(hook,...) end)
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
function addon:CleanUp()
	collectgarbage("collect")
end
function addon:SetUp()
	local start=GetTime()
--@debug@
	print("Addon setup")
--@end-debug@
	self:CacheFollowers()
	local list=GarrisonMissionFrame.MissionTab.MissionList
	G.GetAvailableMissions(list.availableMissions)
	if (#list.availableMissions > 0) then
		for i,mission in pairs(list.availableMissions) do
			self:TooltipAdder(mission.missionID,true)
		end
	end
--@debug@
	print("Done in",format("%.3f",GetTime()-start))
--@end-debug@
	dirty=false
end
function addon:SetDirty(...)
--@debug@
	print("Dirty",...)
--@end-debug@
	dirty=true
end
local followersCache={}
local missionCache={}
function addon:GetFollowerData(key,subkey)
	local k=followersCache[key]
	if (not followers[1]) then
		followers=G.GetFollowers()
	end
	local t=followers
	if (not k) then
		for i=1,#t do
			if (t[i] and (t[i].followerID == key or t[i].name==key)) then
				followersCache[t[i].followerID]=i
				followersCache[t[i].name]=i
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
function addon:GetMissionData(missionID)
	local t=GMF.MissionTab.MissionList.availableMissions
	local k=missionCache[missionID]
	print(k,missionID,tostring(t))
	if (not k or t[k].missionID ~= missionID) then
		k=nil
		for i=1,#t do
			if (t[i].missionID == missionID) then
				missionCache[missionID]=i
				k=i
			end
		end
	end
	if (k) then
		return t[k]
	else
		return nil
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

function addon:Init()
	G=C_Garrison
	GMF=GarrisonMissionFrame
	GMFFollowers=GarrisonMissionFrameFollowers
	GMFMissions=GarrisonMissionFrameMissions
	GMFTab1=GarrisonMissionFrameTab1
	GMFTab2=GarrisonMissionFrameTab2
	if (_G.GarrisonMissionFrameTab3) then GMFTab3=GarrisonMissionFrameTab3 end
	GMFMissionsTab1=GarrisonMissionFrameMissionsTab1
	GMFMissionsTab2=GarrisonMissionFrameMissionsTab2
	if (_G.GarrisonMissionFrameMissionsTab3) then GMFMissionsTab3=GarrisonMissionFrameMissionsTab3 end
	GMFMissionsListScrollFrame=GarrisonMissionFrameMissionsListScrollFrame
	GMFMissionsListScrollFrameScrollChild=GarrisonMissionFrameMissionsListScrollFrameScrollChild
	GMFFollowerPage=GMF.FollowerTab
	GMFMissionPage=GMF.MissionTab.MissionPage
	GMFList=GarrisonMissionFrame.MissionTab.MissionList
	_G.GMFL=GMFList
	if (not G or not GMF or not GMFFollowers or not GMFMissions or not GMFTab1 or not GMFTab2 or not GMFMissionsTab1 or not GMFMissionsTab2) then
		print("Lagging badly, retrying in 2 seconds")
		self:ScheduleTimer("Init",2)
		return
	end
	self:FillFollowersList()
	self:CacheFollowers()
	self:SecureHook("GarrisonMissionButton_AddThreatsToTooltip",function(id) self:TooltipAdder(id) end)
	self:SecureHook("GarrisonMissionButton_SetRewards","AddPerc")
	self:SecureHook("GarrisonMissionPage_UpdateStartButton","PrefillMissionPage")
	--self:SecureHook("GarrisonFollowerList_UpdateFollowers","CacheFollowers")
	local _,_,_,loadable,reason=GetAddOnInfo("MasterPlan")
	if (loadable or reason=="DEMAND_LOADED") then
		masterplan=true
		self:SecureHook("GarrisonMissionList_Update","RestoreTooltip")
	end
	--self:HookScript(GMFMissions,"OnShow","SetUp")
	self:HookScript(GMF,"OnHide","CleanUp")
	self:HookScript(GMF,"OnShow","GrowPanel")
	self:HookScript(GMFTab1,"OnCLick","GrowPanel")
	self:HookScript(GMFTab2,"OnCLick","GrowPanel")
	if (GMFTab3) then self:HookScript(GMFTab3,"OnCLick","GrowPanel") end
	--self:HookScript(GMF.MissionTab.MissionPage.CloseButton,"OnClick","SetUp")
	self:HookScript(GMF.MissionComplete,"OnHide","SetUp")
	--self:HookScript(GMFFollowers,"OnHide","SetUp")
	self:ApplyMOVEPANEL(self:GetBoolean("MOVEPANEL"))
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_LOOT","SetDirty")
	self:RegisterEvent("GARRISON_MISSION_FINISHED","SetDirty")
	self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE","SetDirty")
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE","SetDirty")
	self:RegisterEvent("GARRISON_MISSION_LIST_UPDATE","SetDirty")
	self:RegisterEvent("GARRISON_MISSION_STARTED","SetDirty")
	self:RegisterEvent("GARRISON_FOLLOWER_XP_CHANGED","ClearFollowers")
	self:RegisterEvent("GARRISON_FOLLOWER_ADDED","ClearFollowers")
	self:RegisterEvent("GARRISON_FOLLOWER_REMOVED","ClearFollowers")
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
function addon:UpdateMissionPage(button)
	DevTools_Dump(button.info)
end
function addon:GrowPanel(frame, button)
	local id=frame:GetID()
	print("Called  id=",id,GMF.MissionTab.MissionPage:IsShown(),"Frame:",frame:GetName())
	if (id==1) then
		self:CacheFollowers()
	end
	--GarrisonMissionFrame_SelectTab(id);
	local BIGSIZEW=1400
	local BIGSIZEH=662
	local SIZEW=950
	local SIZEH=662
	print(GMFMissions:IsShown(),GMFMissionPage:IsShown() )
	if (GMFMissions:IsShown() and not GMFMissionPage:IsShown() ) then
		GMF.FollowerList.showUncollected=false
		GMF:SetWidth(BIGSIZEW)
		GMF:SetHeight(BIGSIZEH)
		--GMFMissions:SetWidth(890)
		GMFMissions:ClearAllPoints()
		GMFMissions:SetPoint("TOPLEFT",GMF,25,-43)
		GMFMissions:SetPoint("BOTTOMRIGHT",GMF,-25,20)
		GMFMissionsListScrollFrameScrollChild:ClearAllPoints()
		GMFMissionsListScrollFrameScrollChild:SetPoint("TOPLEFT",GMFMissionsListScrollFrame)
		GMFMissionsListScrollFrameScrollChild:SetPoint("BOTTOMRIGHT",GMFMissionsListScrollFrame)
		for i,F in pairs(GMF.MissionTab.MissionList.listScroll.buttons) do
			print("Version 2")
			local PF=CreateFrame("Frame","GPF"..i,F,"GarrisonCommanderButtonsBackground")
			F:SetWidth(BIGSIZEW-PF:GetWidth()-100)
			PF:SetPoint("TOPLEFT",F,"TOPRIGHT")
			if (not F.Party) then
				F.Party={}
				for i=1,3 do
					local f=CreateFrame("Button",nil,F,"GarrisonMissionPageFollowerTemplate")
					f:SetScale(0.9)
					f:SetFrameStrata("HIGH")
					F.Party[i]=f
					f:ClearAllPoints()
					if (i==1) then
						f:SetPoint("BOTTOMLEFT",PF,"BOTTOMLEFT",20,4)
					else
						f:SetPoint("LEFT",F.Party[i-1],"RIGHT",12,0)
					end
				end
				self:HookScript(F,"OnClick","UpdateMissionPage")
			end
		end
		if (not GMF.Ignore) then
			local b=CreateFrame("CheckButton","GACOptions",GMF,"UICheckButtonTemplate")
			b.text:SetText(L["Only consider available followers"])
			b:SetChecked(self:GetBoolean('IGM'))
			b:SetScript("OnCLick",function(b) self:Apply("IGM",b:GetChecked()) end)
			b:SetPoint("BOTTOMLEFT",SIZEW,1)
			GMF.Ignore=b:GetChecked()
		end
	else
		GMF.FollowerList.showUncollected=true
		GMF:SetWidth(SIZEW)
		GMF:SetHeight(SIZEH)
	end
end
function addon:FillFollowerButton(frame,ID)
	if (not frame) then return end
	if (not ID) then
		frame.PortraitFrame.Empty:Show()
		frame.Name:Hide()
		frame.Class:Hide()
		return
	end
	local info=G.GetFollowerInfo(ID)
	--local info=followers[ID]
	frame.info=info
	frame.Name:Show();
	frame.Name:SetText(info.name);
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
end
function addon:RenderButton(button)
	if (not button or not button.Title) then return end
	button.Title:SetFontObject("QuestFont_Large")
	button.Summary:SetFontObject("GameFontNormal")
	button.Summary:ClearAllPoints()
	button.Summary:SetPoint("BOTTOMLEFT",button.Title,"TOPLEFT",0,5)
	button.Title:SetWidth(200)
	--button.Party[1]:SetPoint("TOPLEFT",button,"TOPRIGHT",10,-15)
	local followerID="0x000000000002F5E1"
	local inprogress=GMF.MissionTab.MissionList.showInProgress
	local missionInfo=button.info
	for i=1,3 do
		local frame=button.Party[i]
		if (i>button.info.numFollowers) then
			frame:Hide()
		else
			if (inprogress) then
				if (missionInfo.followers[i]) then
					self:FillFollowerButton(frame,missionInfo.followers[i])
				else
					self:FillFollowerButton(frame)
				end
			elseif (missionFollower[missionInfo.missionID]) then
				self:FillFollowerButton(frame,missionFollower[missionInfo.missionID][i])
			else
				self:FillFollowerButton(frame)
			end
			frame:Show()
		end
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
				local missionLink = G.GetMissionLink(self.info.missionID);
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
		GarrisonMissionFrame.followerCounters = G.GetBuffedFollowersForMission(self.info.missionID)
		GarrisonMissionFrame.followerTraits = G.GetFollowersTraitsForMission(self.info.missionID);
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
_G.GAC=addon