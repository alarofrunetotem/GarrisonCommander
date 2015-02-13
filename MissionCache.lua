local me,ns=...
local addon=ns.addon --#addon
local holdEvents,releaseEvents=addon.holdEvents,addon.releaseEvents
local xprint=ns.xprint
local xdump=ns.xdump
--upvalue
local G=C_Garrison
local GMF=GarrisonMissionFrame
local GMFMissions=GarrisonMissionFrameMissions
local type=type
local select=select
local pairs=pairs
local tonumber=tonumber
local tinser=tinsert
local GARRISON_CURRENCY=GARRISON_CURRENCY
local Mbase = GMF.MissionTab.MissionList
-- self=Mbase
--	C_Garrison.GetInProgressMissions(self.inProgressMissions);
--	C_Garrison.GetAvailableMissions(self.availableMissions);
local missionIndex={}
local AddExtraData
local function keyToIndex(key)
	local idx=missionIndex[key]
	if (idx and idx <= #Mbase.availableMissions) then
		if Mbase.availableMissions[idx].missionID==key then
			return idx
		else
			idx=nil
		end
	end
	wipe(missionIndex)
	for i=1,#Mbase.availableMissions do
		missionIndex[Mbase.availableMissions[i].missionID]=i
		if Mbase.availableMissions[i].missionID==key then
			return i
		end
	end
end
function addon:GetMissionData(missionID,key)
	local idx=keyToIndex(missionID)
	xprint("Mission",missionID," is ",idx,"of",#Mbase.availableMissions)
	local mission=Mbase.availableMissions[idx]
	if (key==nil) then
		return mission
	end
	if (type(mission[key])~='nil') then
		return mission[key]
	end
	if (key=='rank') then
		mission.rank=mission.level < 100 and mission.level or mission.iLevel
		return mission.rank
	elseif(key=='basePerc') then
		mission.basePerc=select(4,G.GetPartyMissionInfo(missionID))
		return mission.basePerc
	else
		AddExtraData(mission)
		return mission[key]
	end
end
function AddExtraData(mission)
	local _
	_,mission.xp,mission.type,mission.typeDesc,mission.typeIcon,mission.locPrefix,_,mission.enemies=G.GetMissionInfo(mission.missionID)
	mission.rank=mission.level < 100 and mission.level or mission.iLevel
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
						mission.followerUpgrade=itemRarity
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
	mission.slots={}
	local slots=mission.slots

	for i=1,#mission.enemies do
		local mechanics=mission.enemies[i].mechanics
		for i,mechanic in pairs(mechanics) do
			tinsert(slots,mechanic)
		end
	end
	if (type) then
		tinsert(slots,{name=TYPE,key=mission.type,icon=mission.typeIcon})
	end
end
