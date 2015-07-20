--@do-not-package@
local _G=_G
LoadAddOn("Blizzard_DebugTools")
local me, ns = ...
if (me=="doc") then
	local mt={
		keys=setmetatable({},{__index=function(t,k) rawset(t,k,{}) return t[k] end }),
		__metatable=true

	}
	function mt:__index(k)

		if k=="n" then
			return #mt.keys[self]
		end
		return rawget(self,k)
	end
	function mt:__len()
		return #mt.keys[self]
	end
	function mt:__newindex(k,v)
		local keys=mt.keys[self]
		local pos=#keys+1
		print("Inserting",k)
		for i,x in ipairs(keys) do
			if x>k then
				pos=i
				break;
			end
		end
		table.insert(keys,pos,k)
		print("Inserted",k,"at",pos)
		rawset(self,k,v)
	end
	function a()
				return function(unsorted,i)
				i=i+1
				local k=mt.keys[unsorted][i]
				if k then return i,k end
			end,self,0
	end
	function mt:__call()
		do
			local current=0
			return function(unsorted,i)
				current=current+1
				local k=mt.keys[unsorted][current]
				if k then return k,self[k] end
			end,self,0
		end
	end
	local my=setmetatable({},mt)
	my.pippo=3
	my.pluto=4
	my.andrea=2
	my.zanzi=1
	print("Sorted")
	for k,v in my() do print(k,v) end
	print("Unsorted")
	for k,v in pairs(my) do print(k,v) end
	return
end
local pp=print
if ns.Configure then ns.Configure() end
local addon=ns.addon --#addon
local L=ns.L
local D=ns.D
local C=ns.C
local AceGUI=ns.AceGUI
local _G=_G
_G.GAC=addon


local m={}
function m:AddRow(text,...)
	local l=AceGUI:Create("Label")
	l:SetText(text)
	l:SetColor(...)
	l:SetFullWidth(true)
	self:AddChild(l)
	return l
end
--[[
function m:AddIconText(icon,text,qt)
	local l=AceGUI:Create("InteractiveLabel")
	l:SetFontObject(GameFontNormalSmall)
	if (qt) then
		l:SetText(format("%s x %s",text,qt))
	else
		l:SetText(text)
	end
	l:SetImage(icon)
	l:SetImageSize(24,24)
	l:SetFullWidth(true)
	l.frame:EnableMouse(true)
	l.frame:SetFrameLevel(999)
	self:AddChild(l)
	return l
end
function m:AddItem(itemID,qt)
	local _,itemlink,itemquality,_,_,_,_,_,_,itemtexture=GetItemInfo(itemID)
	if not itemlink then
		return self:AddIconText(itemtexture,itemID)
	else
		return self:AddIconText(itemtexture,itemlink)
	end
end
--]]
function addon:GetScroller(title,type,h,w)
	h=h or 800
	w=w or 400
	type=type or "Frame"
	local scrollerWindow=AceGUI:Create("Frame")
	--scrollerWindow.frame:SetAlpha(1)
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
	scrollerWindow:SetHeight(h)
	scrollerWindow:SetWidth(w)
	scrollerWindow:SetPoint("CENTER")
	scrollerWindow:Show()
	for k,v in pairs(m) do scroll[k]=v end
	scroll.addRow=scroll.AddRow
	return scroll
end
function addon:AddRow(obj,text,...)
--@debug@
	assert(obj)
--@end-debug@
	if (obj) then
		local l=AceGUI:Create("Label")
		l:SetText(text)
		l:SetColor(...)
		l:SetFullWidth(true)
		obj:AddChild(l)
	end
end
local function safesort(a,b)
	if (tonumber(a) and tonumber(b)) then
		return a < b
	else
		return tostring(a) < tostring(b)
	end
end
function addon:cutePrint(scroll,level,k,v)
	if (type(level)=="table") then
		for k,v in kpairs(level,safesort) do
			self:cutePrint(scroll,"",k,v)
		end
		return
	end
	if (type(v)=="table") then
		if (level:len()>6) then return end
		self:AddRow(scroll,level..C(k,"Azure")..":" ..C("Table","Orange"))
		for kk,vv in pairs(v) do
			self:cutePrint(scroll,level .. "  ",kk,vv)
		end
	else
		if (type(v)=="string" and v:sub(1,2)=='0x') then
			v=v.. " " ..tostring(self:GetFollowerData(v,'name'))
		end
		self:AddRow(scroll,level..C(k,"White")..":" ..C(v,"Yellow"))
	end
end
function addon:DumpFollower(name)
	local follower=self:GetFollowerData(name)
	if (follower) then
		local scroll=self:GetScroller(follower.name)
		self:cutePrint(scroll,follower)
	end

end
function addon:DumpStatus(title)
	local scroll=self:GetScroller(title)
	for i=1,#followersCache do
		local followerID=followersCache[i].followerID
		scroll:AddRow(format("%s (%s): %d",self:GetFollowerData(followerID,'fullname'),self:GetFollowerData(followerID,'followerID'),G.GetFollowerXP(followerID)))
	end
	scroll:AddRow("Garrison resources: " .. select(2,GetCurrencyInfo(GARRISON_CURRENCY)))
	scroll:AddRow("Money: " .. GetMoneyString(GetMoney()))
end
function addon:DumpFollowers()
	local scroll=self:GetScroller("Followers Cache (" .. #followersCache ..")"  )
	self:cutePrint(scroll,followersCache)
end
function addon:DumpFollowerMissions(missionID)
	local scroll=self:GetScroller("FollowerMissions " .. self:GetMissionData(missionID,'name'))
	self:cutePrint(scroll,followerMissions.missions[missionID])
end
function addon:DumpIgnored()
	local scroll=self:GetScroller("Ignored")
	self:cutePrint(scroll,self.privatedb.profile.ignored)
end
function addon:DumpMission(missionID)
	local scroll=self:GetScroller("MissionCache " .. self:GetMissionData(missionID,'name'))
	self:cutePrint(scroll,self:GetMissionData(missionID))
end
function addon:DumpMissions()
	local scroll=self:GetScroller("MissionCache")
	for id,data in pairs(self:GetMissionData(missionID)) do
		self:cutePrint(scroll,id .. '.'..data.name)
	end
end
---
-- Debug function
--@param missionID Identificativo missione
function addon:DumpCounters(missionID)
	local scroll=self:GetScroller("Counters " .. self:GetMissionData(missionID,'name'))
	self:cutePrint(scroll,counters[missionID])
	self:cutePrint(scroll,"Lista per follower","","")
	self:cutePrint(scroll,counterFollowerIndex[missionID])
	self:cutePrint(scroll,"Lista per threat","","")
	self:cutePrint(scroll,counterThreatIndex[missionID])
end
function addon:Dump(title,data)
	if type(data)=="string" then
		data=_G[data]
	end
	if type(data) ~= "table" then
		print(data,"is not a table")
		return
	end
	local scroll=self:GetScroller(title)
	print("Dumping",title)
	self:cutePrint(scroll,data)
	return scroll
end
function addon:DumpCounterers(missionID)
	local scroll=self:GetScroller("Counterers " .. self:GetMissionData(missionID,'name'))
	self:cutePrint(scroll,cache.missions[missionID].counterers)
end
function addon:DumpParty(missionID)
	local scroll=self:GetScroller("Party " .. self:GetMissionData(missionID,'name'))
	self:cutePrint(scroll,parties[missionID])
end
function addon:DumpAgeDb()
	local t=ns.new()
	for i,v in pairs(dbcache.seen) do
		tinsert(t,format("%80s %s %d",self:GetMissionData(i,'name'),date("%d/%m/%y %H:%M:%S",v),ns.wowhead[i]))
	end
	local scroll=self:GetScroller("Expire db")
	self:cutePrint(scroll,t)
	ns.del(t)
end
do
local appo
appo=addon.OnInitialized
function addon:OnInitialized()
	appo(self)
	self:AddLabel("Developers options")
	self:AddToggle("DBG",false, "Enable Debug")
	self:AddToggle("TRC",false, "Enable Trace")
	self:AddOpenCmd("show","showdata","Prints a mission score")
end
end
local function traitGen()
	local TT=C_Garrison.GetRecruiterAbilityList(true)
	local map={}
	local  keys={}
	for i,v in pairs(C_Garrison.GetRecruiterAbilityCategories()) do
		keys[v]=i
	end
	for  _,trait in  pairs(TT) do
		local key=keys[trait.category]
		if type(map[key])~="table"  then
				map[key]={}
		end
		map[key][trait.id]=trait.name
	end
	DevTools_Dump(map)
	do
		local f=ns.AceGUI:Create("Frame")
		local editbox=ns.AceGUI:Create("EditBox")
		f:AddChild(editbox)
		editbox:SetFullHeight(true)
		f:SetLayout("Fill")
		f:DoLayout()
		local accumulator=""
		local context = {
				depth = 0,
				key = nil,
		};
		context.GetTableName = function() return nil end
		context.GetFunctionName = context.GetTableName
		context.GetUserdataName = context.GetTableName
		context.Write=function(this,msg) accumulator=accumulator..msg end
		DevTools_RunDump(map,context)
		editbox:SetText(accumulator)
	end
end
local trackedEvents={}
local function eventTrace ( self, event, ... )
	if (event=="VARIABLES_LOADED") then
		trackedEvents=ATEINFO.trackedEvents or {}
	elseif (event:find("GARRISON",1,true)) then
		local signature="("..event
		for i=1,select('#',...) do
			signature=','..signature.." ".. tostring(select(i,...))
		end
		signature=signature..")"
		trackedEvents[event]=signature
	end
end
function addon:showdata(fullargs,action,missionid,chance)
	self:Print(fullargs,",",missionid,chance)
	missionid=tonumber(missionid)
	if missionid then
		if action=="score" then
			self:Print(self:GetMissionData(missionid,'name'),self:MissionScore(self:GetMissionData(missionid)))
		elseif action=="mission" then
			self:DumpMission(missionid)
		elseif action=="match" then
			self:TestMission(missionid)
		elseif action=="mcmatch" then
			self:GCTestMission(missionid,false,tonumber(chance) or 50)
		end
	else
		if action=="traits" then
			traitGen()
		elseif action=="events" then
			self:Dump("EventList",trackedEvents)
		end
	end
end

local f=CreateFrame("Frame")
f:SetScript("OnEvent",eventTrace)
f:RegisterAllEvents()

--]]
--- Enable a trace for every function call. It's a VERY heavy debug
--
ns.HD=false
if not ns.HD then return end
print("DISABLEEEEEEEE")
local memorysinks={}
local callstack={}
local lib=LibStub("LibInit")
for k,v in pairs(addon) do
	if (type(v))=="function" and not lib[k] then
		local wrapped
		do
			local original=addon[k]
			wrapped=function(...)
				tinsert(callstack,k)
				local membefore=GetAddOnMemoryUsage("GarrisonCommander")
				local a1,a2,a3,a4,a5,a6,a7,a8,a9=original(...)
				local memafter=GetAddOnMemoryUsage("GarrisonCommander")
				tremove(callstack)
				memorysinks[k].mem=memorysinks[k].mem+memafter-membefore
				memorysinks[k].calls=memorysinks[k].calls+1
				if (#callstack) then
					memorysinks[k].callers=strjoin("->",unpack(callstack))
				else
					memorysinks[k].callers="main"
				end
				if (memafter-membefore > 5) then
					pp(C(k,'Red'),'used ',memafter-membefore)
				end
				return a1,a2,a3,a4,a5,a6,a7,a8,a9
			end
		end
		addon[k]=wrapped
		memorysinks[k]={mem=0,calls=0,callers=""}
	end
end
function addon:ResetSinks()
	for k,v in pairs(memorysinks) do
		memorysinks[k].mem=0
		memorysinks[k].calls=0
	end
end
local sorted={}
function addon:DumpSinks()
	local scroll=self:GetScroller("Sinks",nil,400,1000)
	wipe(sorted)
	for k,v in pairs(memorysinks) do
		if v.mem then
			tinsert(sorted,format("Mem %06d (calls: %03d) Mem per call:%03.2f  Callstack:%s(%s)",v.mem,v.calls,v.mem/v.calls,C(k,"Orange"),v.callers))
		end
	end
	table.sort(sorted,function(a,b) return a>b end)
	self:cutePrint(scroll,sorted)
end
_G.GAC=addon
--[[
PlaySound("UI_Garrison_CommandTable_Open");
	PlaySound("UI_Garrison_CommandTable_Close");
	PlaySound("UI_Garrison_Nav_Tabs");
	PlaySound("UI_Garrison_Nav_Tabs");
	PlaySound("UI_Garrison_CommandTable_SelectMission");
			PlaySound("UI_Garrison_CommandTable_IncreaseSuccess");
			PlaySound("UI_Garrison_CommandTable_100Success");
			PlaySound("UI_Garrison_CommandTable_ReducedSuccessChance");
				PlaySound("UI_Garrison_Mission_Threat_Countered");
			PlaySoundKitID(43507);	-- 100% chance reached
	PlaySound("UI_Garrison_CommandTable_AssignFollower");
			PlaySound("UI_Garrison_CommandTable_UnassignFollower");
		PlaySound("UI_Garrison_Mission_Threat_Countered");
	PlaySound("UI_Garrison_CommandTable_MissionStart");
	PlaySound("UI_Garrison_CommandTable_ViewMissionReport");
		PlaySound("UI_Garrison_Mission_Complete_Encounter_Chance");
	PlaySound("UI_Garrison_CommandTable_Nav_Next");
		PlaySound("UI_Garrison_CommandTable_ChestUnlock_Gold_Success");
		PlaySound("UI_Garrison_Mission_Threat_Countered");
		PlaySound("UI_Garrison_MissionEncounter_Animation_Generic");
			PlaySoundKitID(currentAnim.castSoundID);
		PlaySoundKitID(currentAnim.impactSoundID);
			PlaySound("UI_Garrison_Mission_Complete_Encounter_Fail");
			PlaySound("UI_Garrison_Mission_Complete_Mission_Success");
		PlaySound("UI_Garrison_CommandTable_MissionSuccess_Stinger");
		PlaySound("UI_Garrison_Mission_Complete_MissionFail_Stinger");
		PlaySound("UI_Garrison_CommandTable_ChestUnlock");
				PlaySound("UI_Garrison_CommandTable_Follower_LevelUp");

--]]
--@end-do-not-package@