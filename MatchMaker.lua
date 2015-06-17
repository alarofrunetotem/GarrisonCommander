local me,ns=...
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
local loadstring=loadstring
local assert=assert
local rawset=rawset
local strsplit=strsplit
local epicMountTrait=221
local extraTrainingTrait=80 --all followers +35
local fastLearnerTrait=29 -- only this follower +50
local hearthStoneProTrait=236 -- all followers +36
local scavengerTrait=79 -- More resources
local GARRISON_CURRENCY=GARRISON_CURRENCY
local GARRISON_SHIP_OIL_CURRENCY=GARRISON_SHIP_OIL_CURRENCY
--@debug@
if LibDebug then LibDebug() end
--@end-debug@
--[===[@non-debug@
setfenv(1,setmetatable({print=function(...) print("x",...) end},{__index=_G}))
--@end-non-debug@]===]
local dbg
local function formatScore(c,r,x,t,maxres,cap)
	if (not maxres) then cap=100 end
	return format("%03d %03d %03d %03d %01d",min(c,cap),r,c,x,t),c
end
function addon:MissionScore(mission,voidcap)
	if ns.toc >=60200 then return self:xMissionScore(mission) end
	if not mission then
		return formatScore(0,1,0,0,false,0)
	end
	local totalTimeString, totalTimeSeconds, isMissionTimeImproved, successChance, partyBuffs, isEnvMechanicCountered, xpBonus, materialMultiplier,goldMultiplier = G.GetPartyMissionInfo(mission.missionID)
	local r=mission.class=="gold" and goldMultiplier or materialMultiplier
	local t=isMissionTimeImproved and 1 or 0
	local x=mission.xp and xpBonus/mission.xp*100 or 0
	return formatScore(successChance,r,x,t,mission.maxable and self:GetBoolean("MAXRES"),self:GetNumber("MAXRESCHANCHE"))
end
function addon:xMissionScore(mission)
	if (mission) then
		local totalTimeString, totalTimeSeconds, isMissionTimeImproved, successChance, partyBuffs, isEnvMechanicCountered, xpBonus, materialMultiplier,goldMultiplier = G.GetPartyMissionInfo(mission.missionID)
		local x=mission.xp and xpBonus/mission.xp*100 or 0
		local r=0
		if type(materialMultiplier)=='table' then
			for _,v in pairs(mission.rewards) do
				if v.currencyID then
					if v.currencyID==0 then
						r=r+goldMultiplier
					else
						r=r+(materialMultiplier[v.currencyID] or 0)
					end
				end
			end
		end
		local t=isMissionTimeImproved and 1 or 0
		return formatScore(successChance,r,x,t,mission.maxable and self:GetBoolean("MAXRES"),self:GetNUmber("MAXRESCHANCE"))
	else
		return formatScore(0,1,0,0,false,0)
	end
end


function addon:FollowerScore(mission,followerID)
	local score,chance=self:MissionScore(mission)
	return format("%s %04d",score,followerID and math.min(1000-self:GetFollowerData(followerID,'rank',90),999)),chance
end
local filters={skipMaxed=false,skipBusy=false}
function filters.nop(followerID)
	return true
end
function filters.maxed(followerID,missionID)
	return filters.skipMaxed and addon:GetFollowerData(followerID,'maxed') or false
end
function filters.busy(followerID,missionID)
	return not addon:IsFollowerAvailableForMission(followerID,filters.skipBusy)
end
function filters.ignored(followerID,missionID)
	return addon:IsIgnored(followerID,missionID)
end
function filters.generic(followerID,missionID)
	return filters.busy(followerID,missionID) or filters.ignored(followerID,missionID)
end
function filters.xp(followerID,missionID)
	return filters.maxed(followerID,missionID) or filters.generic(followerID,missionID)
end
--alias
--filters.resources=filters.generic
--filters.oil=filters.generic
--filters.gold=filters.generic
--filters.equip=filters.generic
--filters.followerEquip=filters.generic
--filters.epic=filters.generic
local nop={addRow=function() end}
local scroller=nop
local function CreateFilter(missionClass)
	local code = [[
	local filters,print,pairs = ...
	local function filterdata(followers,missionID)
		for followerID,_ in pairs(followers) do
			if TEST then
				print("Removing",C_Garrison.GetFollowerName(followerID),"due to TEST", TEST)
				followers[followerID] = nil
			else
				print("Keeping",C_Garrison.GetFollowerName(followerID),"due to TEST", TEST)
			end
		end
	end
	return filterdata
	]]
	code = code:gsub("TEST", " filters." ..missionClass .."(followerID,missionID)")
	print("Compiling ",missionClass,"filterOut")
	return assert(loadstring(code, "filterOut for " .. missionClass))(filters,print,pairs)
end

local filterTypes = setmetatable({}, {__index=function(self, missionClass)
	local filterOut = CreateFilter(missionClass)
	rawset(self, missionClass, CreateFilter(missionClass))
	return filterOut
end})
local function AddMoreFollowers(self,mission,scores,justdo)
	local missionID=mission.missionID
	local filterOut=filters[mission.class] or filters.generic
	local missionScore=self:MissionScore(mission)

	for p=1,P:FreeSlots() do
		if dbg then
			scroller:AddRow("--------------------- Slot " .. P:CurrentSlot() .. " ------------------")
		end
		local candidate=nil
		local candidateScore=missionScore
		for i=1,#scores do
			local score,followerID,chance=strsplit('@',scores[i])
			if (not filterOut(followerID,missionID) and not P:IsIn(followerID)) then
				P:AddFollower(followerID)
				local newScore=self:MissionScore(mission)
				if dbg then
					local c1,c2="green","red"
					if newScore > candidateScore or justdo then
						c1="red"
						c2="green"
					end
					scroller:AddRow(addon:GetFollowerData(followerID,'fullname') .." changes score from " .. C(candidateScore,c1).." to "..C(newScore,c2))
				end
				if (newScore > candidateScore or justdo) then
					candidate=followerID
					candidateScore=newScore
				end
				P:RemoveFollower(followerID)
			end
		end
		if candidate then
			local slot=P:CurrentSlot()
			if P:AddFollower(candidate) and dbg then
				scroller:addRow(C("Slot " .. slot..":","Green").. " " .. addon:GetFollowerData(candidate,'fullname'))
			end
			candidate=nil
		end
	end
end
local function MatchMaker(self,missionID,party,includeBusy,onlyBest)
	local mission=self:GetMissionData(missionID)
	local class=self:GetMissionData(missionID,'class')
	print(C(format("MATCHMAKER %s (%d) class: %s",mission.name,missionID,class),'Orange'),includeBusy and "Busy" or "Ready")
	local filterOut=filters[class] or filters.generic
	filters.skipMaxed=self:GetBoolean("IGP")
	if (includeBusy==nil) then
		filters.skipBusy=self:GetBoolean("IGM")
	else
		filters.skipBusy=not includeBusy
	end
	local scores=new()
	local fillers=new()
	P:Open(missionID,mission.numFollowers)
	--[[
	local buffed=G.GetBuffedFollowersForMission(missionID)
	local traits=G.GetFollowersTraitsForMission(missionID)
	local buffeds=0
	local mechanics=G.GetMissionUncounteredMechanics(missionID)
	--G.GetFollowerBiasForMission(missionID,followerID)
	for followerID,_ in pairs(buffed) do
		P:AddFollower(followerID)
		-- dirty trick to avoid issue with integer overflow
		local followerScore=self:FollowerScore(mission,followerID)
		tinsert(scores,format("%s1|%s",self:FollowerScore(mission,followerID),followerID))
		P:RemoveFollower(followerID)
		buffeds=buffeds+1
	end
	--]]
	local minchance=floor(self:GetNumber('MAXRESCHANCE')/mission.numFollowers)-mission.numFollowers*mission.numFollowers
	for _,followerID in self:GetFollowerIterator() do

		if P:AddFollower(followerID) then
			local score,chance=self:FollowerScore(mission,followerID)
			if (score~=self:FollowerScore(nil,followerID) and chance >minchance) then
				tinsert(scores,format("%s@%s",score,followerID))
			else
				tinsert(fillers,format("%s@%s",score,followerID))
			end
			P:RemoveFollower(followerID)
		end
		--end
	end
	if dbg then
		scroller=self:GetScroller("Score for " .. mission.name .. " Class " .. mission.class)
	end
	if #scores > 0 then
		local firstmember
		table.sort(scores)
		if (dbg) then
			scroller:addRow("Cap Res Cha Xp T Vra Ran")
			for i=1,#scores do
				local score,followerID=strsplit('@',scores[i])
				local t=score .. " " .. addon:GetFollowerData(followerID,'fullname') .. " " .. tostring(G.GetFollowerStatus(followerID))
				scroller:addRow(t)
			end
		else
			scroller=nop
		end
		for i=#scores,1,-1 do
			local score,followerID=strsplit('@',scores[i])
			if not firstmember and not filterOut(followerID,missionID) then
				firstmember=followerID
				break
			end
		end
		if firstmember then
			if P:AddFollower(firstmember) and dbg then
				scroller:AddRow(C("Slot 1:","Green").. " " .. addon:GetFollowerData(firstmember,'fullname'))
			end
			if mission.numFollowers > 1 then
				AddMoreFollowers(self,mission,scores)
			end
		end
	end
	if P:FreeSlots() > 0 then
		if not onlyBest then
			filters.skipMaxed=false
			print("           AddMore 1 with skipmaxed false",filters.skipMaxed)
			AddMoreFollowers(self,mission,scores)
		end
	end
	if P:FreeSlots() > 0 then
		filters.skipMaxed=false
		print("           AddMore 1 with just do true")
		AddMoreFollowers(self,mission,scores,true)
	end
	if P:FreeSlots() > 0 then
		filters.skipMaxed=false
		print("           AddMore 1 with just do true")
		AddMoreFollowers(self,mission,fillers,true)
	end
	if dbg then
		P:Dump()
		scroller:AddRow("Final score: " .. self:MissionScore(mission))
	end
	print("Final score",self:MissionScore(mission))
	if not party.class then
		party.class=class
		party.itemLevel=mission.itemLevel
		party.followerUpgrade=mission.followerUpgrade
		party.xpBonus=mission.xpBonus
		party.gold=mission.gold
		party.resources=mission.resources
	end
	P:StoreFollowers(party.members)
	P:Close(party)
	--del(buffed)
end
function addon:MCMatchMaker(missionID,party,skipEpic)
	MatchMaker(self,missionID,party,false)
	if (skipEpic) then
		if (self:GetMissionData(missionID,'class')=='xp') then
			for i=1,#party.members do
				if not self:GetFollowerData(party.members[i],'maxed') then
					return
				end
			end
			party.full=false
			wipe(party.members)
		end
	end
end
function addon:MatchMaker(missionID,party,includeBusy)
	if (not party) then party=self:GetParty(missionID) end
	MatchMaker(self,missionID,party,includeBusy)
end
function addon:TestMission(missionID,includeBusy)
	dbg=true
	local party=new()
	party.members=new()
	self:MatchMaker(missionID,party,includeBusy)
--@debug@
	DevTools_Dump(party)
--@end-debug@
	del(party.members)
	del(party)
	scroller=nop
	dbg=false
end
function addon:MatchDebug(d)
	dbg=d
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
Dump: value=C_Garrison.GetFollowersTraitsForMission(109)
{
	["0x00000000001BE95D"]={
		[1]={
			traitID=236,
			icon="Interface\\ICONS\\Item_Hearthstone_Card.blp"
		},
		[2]={
			traitID=76,
			icon="Interface\\ICONS\\Spell_Holy_WordFortitude.blp"
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