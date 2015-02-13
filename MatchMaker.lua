local me,ns=...
local xprint=ns.xprint
local pp=print
local addon=ns.addon --#addon
local C=ns.C
local P=ns.party
local _G=_G
local holdEvents,releaseEvents=addon.holdEvents,addon.releaseEvents
local new, del, copy =ns.new,ns.del,ns.copy
--upvalue
local G=C_Garrison
local GMFRewardSplash=GarrisonMissionFrameMissions.CompleteDialog
local pairs=pairs
local format=format
local tonumber=tonumber
local tinsert=tinsert
local tremove=tremove
local dbg
local epicMountTrait=221
local extraTrainingTrait=80 --all followers +35
local fastLearnerTrait=29 -- only this follower +50
local hearthStoneProTrait=236 -- all followers +36
local scavengerTrait=79 -- More resources
local function best(fid1,fid2,counters,mission)
	if (not fid1) then return fid2 end
	if (not fid2) then return fid1 end
	local f1,f2=counters[fid1],counters[fid2]
	if (dbg) then
		xprint("Current",fid1,n[f1.followerID]," vs Candidate",fid2,n[f2.followerID])
	end
	if (P:IsIn(f1.followerID)) then return fid1 end
	if (f2.bias<0) then return fid1 end
	if (f2.bias>f1.bias) then return fid2 end
	if (f1.bias == f2.bias) then
		if (mission.resources > 0 ) then
			if addon:HasTrait(f1.followerID,scavengerTrait) then
				return fid1
			end
		end
		if (f2.quality < f1.quality or f2.rank < f1.rank) then return fid2 end
	end
	return fid1
end
local function filter()
	if (missionCounters) then
		for i=1,#missionCounters do
			local followerID=missionCounters[i].followerID
			if (not followerID) then
				if (dbg) then xprint("Trying to use [",followerID,"]") end
			else
				if (self:IsIgnored(followerID,missionID)) then
					if (dbg) then xprint("Skipped",n[followerID],"due to ignored" ) end
					P:Ignore(followerID,true)
				elseif not self:IsFollowerAvailableForMission(followerID,skipBusy) then
					if (dbg) then xprint("Skipped",n[followerID],"due to busy" ) end
					P:Ignore(followerID)
				elseif (skipMaxed and mission.xpOnly and self:GetFollowerData(followerID,'maxed')) then
					if (dbg) then print("Skipped",n[followerID],"due to maxed" ) end
					P:Ignore(followerID,true)
				end
			end
		end
	end
end
function addon:MissionScore(mission)
	local totalTimeString, totalTimeSeconds, isMissionTimeImproved, successChance, partyBuffs, isEnvMechanicCountered, xpBonus, materialMultiplier = G.GetPartyMissionInfo(mission.missionID)
	return format("%03d%01d%01d%01d",successChance,isEnvMechanicCountered and 1 or 0,materialMultiplier*mission.resources,#partyBuffs)
end
function addon:FollowerScore(mission)
	local totalTimeString, totalTimeSeconds, isMissionTimeImproved, successChance, partyBuffs, isEnvMechanicCountered, xpBonus, materialMultiplier = G.GetPartyMissionInfo(mission.missionID)
	return format("%03d%01d%02d%01d",successChance,isEnvMechanicCountered and 1 or 0,(mission.resources * (materialMultiplier-1)) , (isMissionTimeImproved and 1 or 0))
end
local filters={}
function filters.Xp(data)
	for k,_ in pairs(data) do
		if (addon:GetFollowerData(k,'maxed')) then
			data[k]=nil
		end
	end
end
function addon:MatchMakerEpic(missionID,mission,party,filter)
	if (GMFRewardSplash:IsShown()) then return end
	if (not mission) then mission=self:GetMissionData(missionID) end
	if (not party) then party=self:GetParty(missionID) end
	local skipBusy=self:GetBoolean("IGM")
	local skipMaxed=self:GetBoolean("IGP")
	local scores=new()
	local traits=new()
	dbg=missionID==(tonumber(_G.MW) or 0)
	if (dbg) then xprint(C("Matchmaking mission","Red"),missionID,mission.name) end
	local buffed=G.GetBuffedFollowersForMission(missionID)
	if (filter) then
		filters[filter](buffed)
	end
	local mechanics=G.GetMissionUncounteredMechanics(missionID)
	P:Open(missionID,mission.numFollowers)
	--G.GetFollowerBiasForMission(missionID,followerID)
	for followerID,_ in pairs(buffed) do
		P:AddFollower(followerID)
		tinsert(scores,format("%s|%s",self:FollowerScore(mission),followerID))
		if (mission.numFollowers>1) then
			for k,d in pairs(G.GetFollowersTraitsForMission(missionID)) do
				if not buffed[k] then
					traits[k]=d
				end
			end
		end
		P:RemoveFollower(followerID)
	end
	if (filter) then
		filters[filter](traits)
	end
	for followerID,_ in pairs(traits) do
		P:AddFollower(followerID)
		tinsert(scores,format("%s|%s",self:FollowerScore(mission),followerID))
		xprint(G.GetFollowerName(followerID),scores[#scores])
		P:RemoveFollower(followerID)
	end
	table.sort(scores)
	for i=#scores,1,-1 do
		local score,followerID=strsplit('|',scores[i])
		xprint(score,G.GetFollowerName(followerID))
	end
	local missionScore=self:MissionScore(mission)
	for p=1,mission.numFollowers do
		xprint("Slot",p)
		local delete=0
		local candidate=nil
		local candidateScore=nil
		for i=#scores,1,-1 do
			local score,followerID=strsplit('|',scores[i])
			P:AddFollower(followerID)
			candidateScore=self:MissionScore(mission)
			xprint(G.GetFollowerName(followerID),candidateScore,"pos",i)
			if (p>1) then
				if (missionScore<candidateScore) then
					missionScore=candidateScore
					candidate=followerID
					delete=i
					xprint("Candidate:",G.GetFollowerName(candidate),candidateScore,"will delete",delete)
				end
				P:RemoveFollower(followerID)
			else
				delete=i
				xprint("Adding first",G.GetFollowerName(followerID),candidateScore,"will delete",delete)
				break
			end
		end
		if (delete>0) then
			xprint("scores contiene",#scores)
			xprint("rimuovo",delete)
			tremove(scores,delete)
			xprint("scores contiene",#scores)
		end
		if candidate then
			P:AddFollower(candidate)
			xprint("Adding",G.GetFollowerName(candidate),candidateScore)
		end
		if P:FreeSlots()==0 then break end
	end
	P:Dump()
	xprint("Final score",self:MissionScore(mission))
	P:StoreFollowers(party.members)
	party.full= P:FreeSlots()==0
	party.perc=P:Close()
end

function addon:MatchMakerOld(missionID,mission,party,fromMissionControl)
	if (GMFRewardSplash:IsShown()) then return end
	if (not mission) then mission=self:GetMissionData(missionID) end
	if (not party) then party=self:GetParty(missionID) end
	local skipBusy=self:GetBoolean("IGM")
	local skipMaxed=self:GetBoolean("IGP")
	dbg=missionID==(tonumber(_G.MW) or 0)
	local slots=mission.slots
	local missionCounters=counters[missionID]
	local ct=counterThreatIndex[missionID]
	P:Open(missionID,mission.numFollowers)
	-- Preloading skipped ones in party table.
	if (dbg) then xprint(C("Matchmaking mission","Red"),missionID,mission.name) end
	if (missionCounters) then
		for i=1,#missionCounters do
			local followerID=missionCounters[i].followerID
			if (not followerID) then
				if (dbg) then xprint("Trying to use [",followerID,"]") end
			else
				if (self:IsIgnored(followerID,missionID)) then
					if (dbg) then xprint("Skipped",n[followerID],"due to ignored" ) end
					P:Ignore(followerID,true)
				elseif not self:IsFollowerAvailableForMission(followerID,skipBusy) then
					if (dbg) then xprint("Skipped",n[followerID],"due to busy" ) end
					P:Ignore(followerID)
				elseif (skipMaxed and mission.xpOnly and self:GetFollowerData(followerID,'maxed')) then
					if (dbg) then print("Skipped",n[followerID],"due to maxed" ) end
					P:Ignore(followerID,true)
				end
			end
		end
		if (type(slots)=='table') then
			for i=1,#slots do
				local threat=cleanicon(slots[i].icon)
				local candidates=ct[threat]
				local choosen
				if (dbg) then xprint("Checking ",threat) end
				for i=1,#candidates do
					local followerID=missionCounters[candidates[i]].followerID
					if P:IsIn(followerID) then
						if dbg then xprint("Countered by",n[followerID],"which is already in party") end
						choosen=nil
						break
					end
					if followerID then
						if(not P:IsIgnored(followerID)) then
							choosen=best(choosen,candidates[i],missionCounters,mission)
							if (dbg) then xprint("Taken",n[missionCounters[choosen].followerID]) end
						else
							if (dbg) then xprint("Party Ignored",n[followerID]) end
						end
					end
				end
				if (choosen) then
					if dbg then xprint("Adding to party",n[missionCounters[choosen].followerID]," still need ",P:FreeSlots()) end
					P:AddFollower(missionCounters[choosen].followerID)
				end
				if (P:FreeSlots()==0) then
					break
				end
			end
		else
			ns.xprint("Mission",missionID,"has no slots????")
		end
		if P:FreeSlots() > 0 then self:AddTraitsToParty(missionID,mission) end
	end
	if P:FreeSlots() > 0 then self:CompleteParty(missionID,mission,skipBusy,skipMaxed) end
	if (not fromMissionControl and not P:IsEmpty()) then
		if P:FreeSlots() > 0 then self:CompleteParty(missionID,mission,skipBusy,false) end
	end
	P:StoreFollowers(party.members)
	party.full= P:FreeSlots()==0
	party.perc=P:Close()
end
function addon:AddTraitsToParty(missionID,mission,skipBusy,skipMaxed)
	local t=counters[missionID]
	if (t) then
		for i=1,#t do
			local follower=t[i]
			if (follower.trait and not P:IsIgnored(follower.followerID) and not P:IsIn(follower.followerID)) then
				if mission.resources > 0 and follower.name==scavengerTrait then
					P:AddFollower(follower.followerID)
				elseif mission.xpOnly  and (follower.name==extraTrainingTrait or follower.name==hearthStoneProTrait) then
					P:AddFollower(follower.followerID)
				elseif mission.durationSeconds > GARRISON_LONG_MISSION_TIME  and follower.name==epicMountTrait then
					P:AddFollower(follower.followerID)
				end
			end
		end
	end
end
function addon:CompleteParty(missionID,mission,skipBusy,skipMaxed)
	local perc=select(4,G.GetPartyMissionInfo(missionID)) -- If percentage is already 100, I'll try and add the most useless character
	local candidateMissions=10000
	local candidateRank=10000
	local candidateQuality=9999
	if (dbg) then
		print("Attemptin to fill party, so far perc is ",perc, "and party is")
		P:Dump()
	end
	for x=1,P:FreeSlots() do
		local candidate
		local candidatePerc=perc
		if (dbg) then print("            Perc to beat",perc, "Going for spot ",P:FreeSlots()) end
		local totFollowers=#followersCache
		for i=1,totFollowers do
			local data=followersCache[i]
			local followerID=data.followerID
			if (dbg) then print("evaluating",data.fullname) end
			repeat
				if P:IsIgnored(followerID) then
					if (dbg) then print("Skipped due to party ignored") end
					break
				end
				if P:IsIn(followerID) then
					if (dbg) then print("Skipped due to already in party") end
					break
				end
				if self:IsIgnored(followerID,missionID) then
					if (dbg) then print("Skipped due to ignored") end
					break
				end
				if (skipMaxed and data.maxed and mission.xpOnly) then
					if (dbg) then print("Skipped due to maxed",skipMaxed,mission.xpOnly) end
					break
				end
				if (not self:IsFollowerAvailableForMission(followerID,skipBusy)) then
					if (dbg) then print("Skipped due to busy") end
					break
				end
				local rank=data.rank
				local quality=data.quality
				perc=tonumber(perc) or 0
				if ((perc) <100) then
					P:AddFollower(followerID)
					local newperc=select(4,G.GetPartyMissionInfo(missionID))
					newperc=tonumber(newperc) or 0
					candidatePerc=tonumber(candidatePerc) or 0
					P:RemoveFollower(followerID)
					if (newperc > candidatePerc) then
						candidatePerc=newperc
						candidate=followerID
						candidateRank=rank
						candidateQuality=quality
						break -- continue
					end
				else
					-- This candidate is not improving success chance or we are already at 100%, minimize
					if (i < totFollowers  and data.maxed) then
						break  -- Pointless using a maxed follower if we  have more follower to try
					end
					if(rank<candidateRank) then
						candidate=followerID
						candidateRank=rank
						candidateQuality=quality
					elseif(rank==candidateRank and quality<candidateQuality) then
						candidate=followerID
						candidateRank=rank
						candidateQuality=quality
					elseif (not candidate) then
						candidate=followerID
						candidateRank=rank
						candidateQuality=quality
					end
				end
			until true -- A poor man continue implementation using break
		end
		if (candidate) then
			if (dbg) then print("Attempting to add to party") end
			P:AddFollower(candidate)
			if (dbg) then
				print("Added member to party")
				P:Dump()
			end
			perc=select(4,G.GetPartyMissionInfo(missionID))
			if (dbg) then print("New perc is",perc) end
		end
	end
end
--@do-not-package@
--[[
Dump value=GetBuffedFollowersForMission(315)
{
	["0x0000000000079D62"]={
		[1]={
			counterIcon="Interface\\ICONS\\Ability_Rogue_FanofKnives.blp",
			name="Minion Swarms",
			counterName="Fan of Knives",
			icon="Interface\\ICONS\\Spell_DeathKnight_ArmyOfTheDead.blp",
			description="An enemy with many allies.  Susceptible to area-of-effect damage."
		}
	},
	["0x000000000002F5E1"]={
		[1]={
			counterIcon="Interface\\ICONS\\Spell_Nature_StrangleVines.blp",
			name="Deadly Minions",
			counterName="Entangling Roots",
			icon="Interface\\ICONS\\Achievement_Boss_TwinOrcBrutes.blp",
			description="An enemy with powerful allies that should be neutralized."
		}
	},
	["0x00000000000CBDF8"]={
		[1]={
			counterIcon="Interface\\ICONS\\ability_deathknight_boneshield.blp",
			name="Massive Strike",
			counterName="Bone Shield",
			icon="Interface\\ICONS\\Ability_Warrior_SavageBlow.blp",
			description="An ability that deals massive damage."
		}
	}
}
Enemies
Dump: value=GAC:GetMissionData(315,"enemies")
{
	[1]={
		portraitFileDataID=1067293,
		displayID=54329,
		name="Imperator Mar'gok",
		mechanics={
			[9]={
				description="An enemy with powerful allies that should be neutralized.",
				name="Deadly Minions",
				icon="Interface\\ICONS\\Achievement_Boss_TwinOrcBrutes.blp"
			},
			[10]={
				description="An enemy that must be dealt with quickly.",
				name="Timed Battle",
				icon="Interface\\ICONS\\SPELL_HOLY_BORROWEDTIME.BLP"
			}
		}
	},
	[2]={
		portraitFileDataID=1067315,
		displayID=54825,
		name="Ko'ragh",
		mechanics={
			[7]={
				description="An enemy with many allies.  Susceptible to area-of-effect damage.",
				name="Minion Swarms",
				icon="Interface\\ICONS\\Spell_DeathKnight_ArmyOfTheDead.blp"
			},
			[4]={
				description="A dangerous harmful effect that should be dispelled.",
				name="Magic Debuff",
				icon="Interface\\ICONS\\Spell_Shadow_ShadowWordPain.blp"
			}
		}
	},
	[3]={
		portraitFileDataID=1067275,
		displayID=53855,
		name="The Butcher",
		mechanics={
			[10]={
				description="An enemy that must be dealt with quickly.",
				name="Timed Battle",
				icon="Interface\\ICONS\\SPELL_HOLY_BORROWEDTIME.BLP"
			},
			[2]={
				description="An ability that deals massive damage.",
				name="Massive Strike",
				icon="Interface\\ICONS\\Ability_Warrior_SavageBlow.blp"
			}
		}
	}
}
Dump: value=C_Garrison.GetMissionUncounteredMechanics(315)
{
	[1]={
		[1]=9,
		[2]=10
	},
	[2]={
		[1]=7,
		[2]=4
	},
	[3]={
		[1]=10,
		[2]=2
	}
}

--]]
--@end-do-not-package@