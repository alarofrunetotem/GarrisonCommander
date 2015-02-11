local me, ns = ...
if (LibDebug) then LibDebug() end
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local addon=LibStub("AceAddon-3.0"):GetAddon(me)
--[[ -----------------------------------------
LibDataBroker Stuff
--]]
local appo={}
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
if (not LibStub:GetLibrary("LibDataBroker-1.1",true)) then
	--@debug@
	print("Missing libdatabroker")
	--@end-debug@
	return
end
local dataobj=LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(me, {
	type = "data source",
	label = "GarrisonCommander",
	text=NONE,
	icon = "Interface\\ICONS\\ACHIEVEMENT_GUILDPERK_WORKINGOVERTIME"
})
function addon:ldbUpdate()
	local now=time()
	local old=time()-3600
	for i=1,#self.db.realm.missions do
		local t,missionID,pc=strsplit('.',self.db.realm.missions[i])
		t=tonumber(t) or 0
		if t>now then
			dataobj.text=format("Next mission on |cff20ff20%s|r in %s",pc,SecondsToTime(t-now))
			return
		end
	end
	dataobj.text=NONE
end
function dataobj:OnTooltipShow()
	self:AddLine("Mission awaiting")
	local db=addon.db.realm.missions
	local now=time()
	for i=1,#db do
		if db[i] then
			local t,missionID,pc=strsplit('.',db[i])
			t=tonumber(t) or 0
			local name=C_Garrison.GetMissionName(missionID)
			if (name) then
				if t > now then
					self:AddDoubleLine(format("|cffff9900%s|r: %s",pc,name),SecondsToTime(t-now),nil,nil,nil,0,1,0)
				else
					self:AddDoubleLine(format("|cffff9900%s|r: %s",pc,name),DONE,nil,nil,nil,1,0,0)
				end
			end
		end
	end
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
--function dataobj:OnClick(button)
--end
