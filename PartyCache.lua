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
	__index=function(t,k)  rawset(t,k,{members={},perc=0,full=false}) return t[k] end
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
local ID,maxFollowers,members,ignored=0,1,{},{}
function party:Open(missionID,followers)
	maxFollowers=followers
	ID=missionID
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
function party:FreeSlots()
	return maxFollowers-#members
end
function party:IsEmpty()
	return maxFollowers>0 and #members==0
end

function party:Dump()
	for i=1,3 do
		if (members[i]) then
			ns.xprint(i,addon:GetFollowerData(members[i],'fullname'))
		end
	end
	ns.xprint(G.GetPartyMissionInfo(ID))
end

function party:AddFollower(followerID)
	if (followerID:sub(1,2) ~= '0x') then ns.xtrace(followerID .. "is not an id") end
	if (self:FreeSlots()>0) then
		local rc,code=pcall (G.AddFollowerToMission,ID,followerID)
		if (rc and code) then
			tinsert(members,followerID)
			return true
--@debug@
		else
			ns.xprint("Unable to add", G.GetFollowerName(followerID),"to",ID,code)
--@end-debug@
		end
	end
end
function party:RemoveFollower(followerID)
	for i=1,maxFollowers do
		if (followerID==members[i]) then
			tremove(members,i)
			local rc,code=pcall(G.RemoveFollowerFromMission,ID,followerID)
--@debug@
			if (not rc) then trace("Unable to remove", G.GetFollowerName(members[i]),"from",ID,code) end
--@end-debug@
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
function party:Close()
	local perc=select(4,G.GetPartyMissionInfo(ID))
	for i=1,3 do
		if (members[i]) then
			local rc,code=pcall(G.RemoveFollowerFromMission,ID,members[i])
--@debug@
			if (not rc) then ns.xtrace("Unable to pop", G.GetFollowerName(members[i])," from ",ID,code) end
--@end-debug@

		else
			break
		end
	end
	releaseEvents()
	wipe(members)
	wipe(ignored)
	return perc or 0
end
function addon:GetParty(missionID)
	if (missionID) then
		return parties[missionID]
	else
		return parties
	end
end