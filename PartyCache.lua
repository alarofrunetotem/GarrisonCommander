local me,ns=...
local addon=ns.addon --#addon
local holdEvents,releaseEvents=addon.holdEvents,addon.releaseEvents
--upvalue
local G=C_Garrison
local setmetatable=setmetatable
local rawset=rawset
local tContains=tContains
local wipe=wipe
local tremove=tremove
local tinsert=tinsert
local pcall=pcall

--
-- Temporary party management
local parties=setmetatable({},{
	__index=function(t,k)  rawset(t,k,
		{
			members={},
			threats={},
			perc=0,
			itemLevel=0,
			followerUpgrade=0,
			xpBonus=0,
			gold=0,
			resources=0,
		}) return t[k] end
})
function ns.inParty(missionID,followerID)
	return tContains(ns.parties[missionID].members,followerID)
end
--- Follower Missions Info
--
local followerMissions=setmetatable({},{
	__index=function(t,k)  rawset(t,k,{}) return t[k] end
})
ns.party={}
local party=ns.party --#party
local ID,maxFollowers,members,ignored,threats=0,1,{},{},{}
function party:Open(missionID,followers)
	maxFollowers=followers
	ID=missionID
	for enemy,menaces in pairs(G.GetMissionUncounteredMechanics(ID)) do
		for i=1,#menaces do
			tinsert(threats,format("%d:%d",enemy,menaces[i]))
		end
	end
	holdEvents()
end
function party:Ignore(followerID)
	ignored[followerID]=true
end
function party:IsIgnored(followerID)
	return ignored[followerID]
end

function party:IsIn(followerID)
	return tContains(members,followerID)
end
function party:MaxSlots()
	return maxFollowers
end
function party:FreeSlots()
	return maxFollowers-#members
end
function party:IsEmpty()
	return maxFollowers>0 and #members==0
end

function party:Dump()
	ns.xprint("Dumping party for mission",ID)
	for i=1,#members do
		ns.xprint(addon:GetFollowerData(members[i],'fullname'),G.GetFollowerStatus(members[i] or 1))
	end
	ns.xprint(G.GetPartyMissionInfo(ID))
end

function party:AddFollower(followerID)
	if (followerID:sub(1,2) ~= '0x') then ns.xtrace(followerID .. "is not an id") end
	if (self:FreeSlots()>0) then
		local rc,code=pcall (G.AddFollowerToMission,ID,followerID)
		if (not rc and code==false) then
			pcall(G.RemoveFollowerFromMission,ID,followerID)
			rc,code=pcall (G.AddFollowerToMission,ID,followerID)
		end
		if (rc and code) then
			tinsert(members,followerID)
			return true
--[===[@debug@
		else
			ns.xprint("Unable to add",followerID, G.GetFollowerName(followerID),"to",ID,code,self:IsIn(followerID),G.GetFollowerStatus(followerID))
			ns.xprint(members[1],members[2],members[3])
			ns.xprint(debugstack(1,6,0))
--@end-debug@]===]
		end
	end
end
function party:RemoveFollower(followerID)
	for i=1,maxFollowers do
		if (followerID==members[i]) then
			tremove(members,i)
			local rc,code=pcall(G.RemoveFollowerFromMission,ID,followerID)
--[===[@debug@
			if (not rc) then trace("Unable to remove", G.GetFollowerName(members[i]),"from",ID,code) end
--@end-debug@]===]
		return true end
	end
end

function party:StoreFollowers(table)
	wipe(table)
	for i=1,#members do
		tinsert(table,members[i])
	end
	return #table
end
local function fsort(a,b)
	return addon:GetFollowerData(a,"rank")>addon:GetFollowerData(b,"rank")
end
function party:Close(desttable)
	local perc
	table.sort(members,fsort)
	for i=1,#members do
		local bias=G.GetFollowerBiasForMission(ID,members[i])
		for _id,ability in pairs(G.GetFollowerAbilities(members[i])) do
			if not ability.isTrait then
				for counter,data in pairs(ability.counters) do
					for j=1,#threats do
						local enemy,threat,oldbias,follower,name=strsplit(":",threats[j])
						oldbias=tonumber(oldbias) or -2
						if bias >oldbias and tonumber(threat)==tonumber(counter) then
							threats[j]=format("%d:%d:%f:%s:%s",enemy,threat,bias or -2,members[i],G.GetFollowerName(members[i]))
						end
					end
				end
			end
		end
	end
	if (desttable) then
		desttable.totalTimeString,
		desttable.totalTimeSeconds,
		desttable.isMissionTimeImproved,
		desttable.perc,
		desttable.partyBuffs,
		desttable.isEnvMechanicCountered,
		desttable.xpBonus,
		desttable.materialMultiplier,
		desttable.goldMultiplier = G.GetPartyMissionInfo(ID)
		if (ns.toc < 60100) then
			desttable.goldMultiplier = 1
		end
		desttable.full=self:FreeSlots()==0
		desttable.threats=desttable.threats or {}
		wipe(desttable.threats)
		for i=1,#threats do
			tinsert(desttable.threats,threats[i])
		end
		perc=desttable.perc
	else
		perc=select(4,G.GetPartyMissionInfo(ID))
	end
	for i=1,3 do
		if (members[i]) then
			local rc,code=pcall(G.RemoveFollowerFromMission,ID,members[i])
--[===[@debug@
			if (not rc) then ns.xtrace("Unable to pop", G.GetFollowerName(members[i])," from ",ID,code) end
--@end-debug@]===]

		else
			break
		end
	end
	releaseEvents()
	wipe(members)
	wipe(ignored)
	wipe(threats)
	return perc or 0
end
function party:CalculateThreats(followers,missionID)
	local threats = {};
	threats.full = {};
	threats.partial = {};
	threats.away = {};
	threats.worker = {};
	missionID=missionID or ID
	local followerList=followers or members
	for i = 1, #followerList do
		local followerID = followerList[i];
		local status=G.GetFollowerStatus(followerID)
		local bias = G.GetFollowerBiasForMission(missionID, followerID);
		if ( bias > -1.0 ) then
			local abilities = G.GetFollowerAbilities(followerID);
			for j = 1, #abilities do
				for counterMechanicID in pairs(abilities[j].counters) do
					if ( status ) then
						if ( status == GARRISON_FOLLOWER_ON_MISSION ) then
							local time = G.GetFollowerMissionTimeLeftSeconds(followerID);
							if ( not threats.away[counterMechanicID] ) then
								threats.away[counterMechanicID] = {};
							end
							table.insert(threats.away[counterMechanicID], time);
						elseif ( status == GARRISON_FOLLOWER_WORKING ) then
							threats.worker[counterMechanicID] = (threats.worker[counterMechanicID] or 0) + 1;
						end
					else
						local isFullCounter = G.IsMechanicFullyCountered(missionID, followerID, counterMechanicID, abilities[j].id);
						if ( isFullCounter ) then
							threats.full[counterMechanicID] = (threats.full[counterMechanicID] or 0) + 1;
						else
							threats.partial[counterMechanicID] = (threats.partial[counterMechanicID] or 0) + 1;
						end
					end
				end
			end
		end
	end

	for counter, times in pairs(threats.away) do
		table.sort(times);
	end
	return threats;
end
function addon:GetBusyParty(missionID)
	return self:GetParty(missionID).busy
end
function addon:GetReadyParty(missionID,key)
	return self:GetParty(missionID)
end
function addon:GetParties()
	return self:GetParty()
end
function addon:GetParty(missionID,key)
	if not missionID then return parties end
	local party=parties[missionID]
	if #party.members==0 and G.GetNumFollowersOnMission(missionID)>0 then
		local followers=self:GetMissionData(missionID,'followers')
		party.perc=select(4,G.GetPartyMissionInfo(missionID))
		for i=1,#followers do
			party.members[i]=followers[i]
		end
		--Running Mission, taking followers from mission data
	end
	if key then
		return party[key]
	else
		return party
	end

end