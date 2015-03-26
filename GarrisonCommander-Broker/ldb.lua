local me, ns = ...
if (not LibStub:GetLibrary("LibDataBroker-1.1",true)) then
	--@debug@
	print("Missing libdatabroker")
	--@end-debug@
	return
end
if (LibDebug) then LibDebug() end
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
--local addon=LibStub("AceAddon-3.0"):NewAddon(me,"AceTimer-3.0","AceEvent-3.0","AceConsole-3.0") --#addon
local addon=LibStub("LibInit"):NewAddon(me,"AceTimer-3.0","AceEvent-3.0","AceConsole-3.0") --#addon
local C=addon:GetColorTable()
local dataobj --#Missions
local farmobj --#Farms
local SecondsToTime=SecondsToTime
local type=type
local strsplit=strsplit
local tonumber=tonumber
local tremove=tremove
local time=time
local tinsert=tinsert
local tContains=tContains
local G=C_Garrison
local format=format
local table=table
local math=math
local GetQuestResetTime=GetQuestResetTime
local CalendarGetDate=CalendarGetDate
local CalendarGetAbsMonth=CalendarGetAbsMonth
local GameTooltip=GameTooltip
local pairs=pairs
local select=select
local READY=READY
local NEXT=NEXT
local NONE=C(NONE,"Red")
local DONE=C(DONE,"Green")
local NEED=C(NEED,"Red")
local dbversion=1

local spellids={
	[158754]='herb',
	[158745]='mine',
	[170599]='mine',
	[170691]='herb',
}
local buildids={
	mine={61,62,63},
	herb={29,136,137}
}
local names={
	mine="Lunar Fall",
	herb="Herb Garden"
}
local today=0
local yesterday=0
local lastreset=0
function addon:ldbCleanup()
	local now=time()
	for i=1,#self.db.realm.missions do
		local s=self.db.realm.missions[i]
		if (type(s)=='string') then
			local t,ID,pc=strsplit('.',s)
			t=tonumber(t) or 0
			if pc==ns.me and t < now then
				tremove(self.db.realm.missions,i)
				i=i-1
			end
		end
	end
end
function addon:ldbUpdate()
	dataobj:Update()
end
function addon:GARRISON_MISSION_STARTED(event,missionID)
	local duration=select(2,G.GetPartyMissionInfo(missionID)) or 0
	local k=format("%015d.%4d.%s",time() + duration,missionID,ns.me)
	tinsert(self.db.realm.missions,k)
	table.sort(self.db.realm.missions)
	self:ldbUpdate()
end
function addon:CheckEvents()
	if (G.IsOnGarrisonMap()) then
		self:RegisterEvent("UNIT_SPELLCAST_START")
		--self:RegisterEvent("ITEM_PUSH")
	else
		self:UnregisterEvent("UNIT_SPELLCAST_START")
		--self:UnregisterEvent("ITEM_PUSH")
	end
end
function addon:ZONE_CHANGED_NEW_AREA()
	self:ScheduleTimer("CheckEvents",1)
	self:ScheduleTimer("DiscoverFarms",1)

end
function addon:UNIT_SPELLCAST_START(event,unit,name,rank,lineID,spellID)
	if (unit=='player') then
		if spellids[spellID] then
			name=names[spellids[spellID]]
			if not self.db.realm.farms[ns.me][name] or  today > self.db.realm.farms[ns.me][name] then
				self:CheckDateReset()
				self.db.realm.farms[ns.me][name]=today
				farmobj:Update()
			end
		end
	end
end
function addon:ITEM_PUSH(event,bag,icon)
--@debug@
	self:print(event,bag,icon)
--@end-debug@
end
function addon:CheckDateReset()
	local reset=GetQuestResetTime()
	local weekday, month, day, year = CalendarGetDate()
--@debug@
	self:Print("Calendar",weekday,month,day,year)
--@end-debug@
	if (day <1 or reset<1) then
		self:ScheduleTimer("CheckDateReset",1)
		return day,reset
	end

	today=year*10000+month*100+day
	if month==1 and day==1 then
		local m, y, numdays, firstday = CalendarGetAbsMonth( 12, year-1 )
		yesterday=y*10000+m*100+numdays
	elseif day==1 then
		local m, y, numdays, firstday = CalendarGetAbsMonth( month-1, year)
		yesterday=y*10000+m*100+numdays
	else
		yesterday=year*10000+month*100+day
	end
	if (reset<3600*3) then
		today=yesterday
	end
	self:ScheduleTimer("CheckDateReset",60)

end
function addon:CountMissing()
	local tot=0
	local missing=0
	for p,j in pairs(self.db.realm.farms) do
		for s,_ in pairs(j) do
			tot=tot+1
			if not j[s] or j[s] < today then missing=missing+1 end
		end
	end
	return missing,tot
end
function addon:DiscoverFarms()
	local shipmentIndex = 1;
	local buildings = G.GetBuildings();
	for i = 1, #buildings do
		local buildingID = buildings[i].buildingID;
		if ( buildingID) then
			local name, texture, shipmentCapacity, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString, itemName, itemIcon, itemQuality, itemID = C_Garrison.GetLandingPageShipmentInfo(buildingID);
			if (tContains(buildids.mine,buildingID)) then
				names.mine=name
				if not self.db.realm.farms[ns.me][name] then
					self.db.realm.farms[ns.me][name]=0
				end
			end
			if (tContains(buildids.herb,buildingID)) then
				names.herb=name
				if not self.db.realm.farms[ns.me][name] then
					self.db.realm.farms[ns.me][name]=0
				end
			end

		end
	end
	farmobj:Update()
end
function addon:SetDbDefaults(default)
	default.realm={
		missions={},
		farms={["*"]={
				["*"]=false
			}},
		dbversion=1
	}
end
function addon:OnInitialized()
	ns.me=GetUnitName("player",false)
	self:RegisterEvent("GARRISON_MISSION_STARTED")
	self:RegisterEvent("GARRISON_MISSION_NPC_OPENED","ldbCleanup")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	if dbversion>self.db.realm.dbversion then
		self.db:ResetDB()
		self.db.realm.dbversion=dbversion
	end
	-- Compatibility with alpha
	if self.db.realm.lastday then
		for k,v in pairs(addon.db.realm.farms) do
			for s,d in pairs(v) do
				v[s]=self.db.realm.lastday
			end
		end
		self.db.realm.lastday=nil
	end

end
function addon:DelayedInit()
	self:CheckDateReset()
	self:ZONE_CHANGED_NEW_AREA()
	self:ScheduleRepeatingTimer("ldbUpdate",2)
	farmobj:Update()
end
function addon:OnEnabled()
	self:ScheduleTimer("DelayedInit",2)
end
dataobj=LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("GC-Missions", {
	type = "data source",
	label = "GC Missions ",
	text=NONE,
	category = "Interface",
	icon = "Interface\\ICONS\\ACHIEVEMENT_GUILDPERK_WORKINGOVERTIME"
})
farmobj=LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("GC-Farms", {
	type = "data source",
	label = "GC Farms ",
	text=L["Harvesting status"],
	category = "Interface",
	icon = "Interface\\Icons\\Trade_Engineering"
})
function farmobj:Update()
	local n,t=addon:CountMissing()
	if (t>0) then
		local c1=C.Green.c
		local c2=C.Green.c
		if n>t/2 then
			c1=C.Red.c
		elseif n>0 then
			c1=C.Orange.c
		end
		farmobj.text=format("%s |cff%s%d|r/|cff%s%d|r",L["Harvest"],c1,t-n,c2,t)
	else
		farmobj.text=NONE
	end
end
function farmobj:OnTooltipShow()
	self:AddDoubleLine(L["Time to next reset"],SecondsToTime(GetQuestResetTime()))
	for k,v in pairs(addon.db.realm.farms) do
		if (k==ns.me) then
			self:AddLine(k,C.Green())
		else
			self:AddLine(k,C.Orange())
		end
		for s,d in pairs(v) do
			self:AddDoubleLine(s,(d and d==today) and DONE or NEED)
		end
	end
	self:AddLine("Manually mark my tasks:",C:Cyan())
	self:AddDoubleLine(KEY_BUTTON1,DONE)
	self:AddDoubleLine(KEY_BUTTON2,NEED)
	self:AddLine(me,C.Silver())
end

function dataobj:OnTooltipShow()
	self:AddLine(L["Mission awaiting"])
	local db=addon.db.realm.missions
	local now=time()
	for i=1,#db do
		if db[i] then
			local t,missionID,pc=strsplit('.',db[i])
			t=tonumber(t) or 0
			local name=G.GetMissionName(missionID)
			if (name) then
				local msg=format("|cff%s%s|r: %s",pc==ns.me and C.Green.c or C.Orange.c,pc,name)
				if t > now then
					self:AddDoubleLine(msg,SecondsToTime(t-now),nil,nil,nil,C.Red())
				else
					self:AddDoubleLine(msg,DONE)
				end
			end
		end
	end

	self:AddLine(me,C.Silver())
end

function dataobj:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	dataobj.OnTooltipShow(GameTooltip)

	GameTooltip:Show()
end

function dataobj:OnLeave()
	GameTooltip:Hide()
end
function farmobj:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	farmobj.OnTooltipShow(GameTooltip)
	GameTooltip:Show()
end
farmobj.OnLeave=dataobj.OnLeave
function farmobj:OnClick(button)
	for k,v in pairs(addon.db.realm.farms) do
		if (k==ns.me) then
			for s,d in pairs(v) do
				v[s]=button=="LeftButton"
			end
		end
	end

end

function dataobj:OnClick(button)
	if (button=="LeftButton") then
		GarrisonLandingPage_Toggle()
	end
end
function dataobj:Update()
	local now=time()
	local completed=0
	local ready=NONE
	local prox=NONE
	for i=1,#addon.db.realm.missions do
		local t,missionID,pc=strsplit('.',addon.db.realm.missions[i])
		t=tonumber(t) or 0
		if t>now then
			local duration=t-now
			local duration=duration < 60 and duration or math.floor(duration/60)*60
			prox=format("|cff20ff20%s|r in %s",pc,SecondsToTime(duration),completed)
			break;
		else
			if ready==NONE then
				ready=format("|cff20ff20%s|r",pc)
			end
		end
		completed=completed+1
	end
	self.text=format("%s: %s (Tot: |cff00ff00%d|r) %s: %s",READY,ready,completed,NEXT,prox)
end

--@debug@
function addon:Dump()
	DevTools_Dump(self.db.realm)
end
_G.GACB=addon
--@end-debug@
