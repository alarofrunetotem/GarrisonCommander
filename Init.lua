local me, ns = ...
local _G=_G
local pp=print
local setmetatable=setmetatable
local next=next
local pairs=pairs
local wipe=wipe
local GetChatFrame=GetChatFrame
local format=format
local GetTime=GetTime
local strjoin=strjoin
local tostringall=tostringall
--@debug@
LoadAddOn("Blizzard_DebugTools")
--@end-debug@
ns.addon=LibStub("LibInit"):NewAddon(me,'AceHook-3.0','AceTimer-3.0','AceEvent-3.0','AceBucket-3.0')
local chatframe=ns.addon:GetChatFrame("aDebug")
local function pd(...)
	--if (chatframe) then chatframe:AddMessage(format("GC:%6.3f %s",GetTime(),strjoin(' ',tostringall(...)))) end
	pp(format("|cff808080GC:%6.3f|r %s",GetTime(),strjoin(' ',tostringall(...))))
end
local addon=ns.addon --#addon
ns.toc=select(4,GetBuildInfo())
ns.AceGUI=LibStub("AceGUI-3.0")
ns.D=LibStub("LibDeformat-3.0")
ns.C=ns.addon:GetColorTable()
ns.L=ns.addon:GetLocale()
ns.print=ns.addon:Wrap("Print")
ns.dprint=ns.print
ns.trace=ns.addon:Wrap("Trace")
ns.xprint=function() end
ns.xdump=function() end
ns.xtrace=function() end
--@debug@
--ns.xprint=function(...) pd("|cffff9900DBG|r",...) end
--ns.xdump=function(d,t) pp("|cffff9900DMP|r",t) DevTools_Dump(d) end
--ns.xtrace=ns.trace
--@end-debug@
do
	--@debug@
	local newcount, delcount,createdcount,cached = 0,0,0
	--@end-debug@
	local pool = setmetatable({},{__mode="k"})
	function ns.new()
	--@debug@
		newcount = newcount + 1
	--@end-debug@
		local t = next(pool)
		if t then
			pool[t] = nil
			return t
		else
	--@debug@
			createdcount = createdcount + 1
	--@end-debug@
			return {}
		end
	end
	function ns.copy(t)
		local c = ns.new()
		for k, v in pairs(t) do
			c[k] = v
		end
		return c
	end
	function ns.del(t)
	--@debug@
		delcount = delcount + 1
	--@end-debug@
		wipe(t)
		pool[t] = true
	end
	--@debug@
	function cached()
		local n = 0
		for k in pairs(pool) do
			n = n + 1
		end
		return n
	end
	function ns.addon:CacheStats()
		ns.print("Created:",createdcount)
		ns.print("Aquired:",newcount)
		ns.print("Released:",delcount)
		ns.print("Cached:",cached())
	end
	--@end-debug@
end

local stacklevel=0
local frames
function addon:holdEvents()
	if stacklevel==0 then
		frames={GetFramesRegisteredForEvent('GARRISON_FOLLOWER_LIST_UPDATE')}
		for i=1,#frames do
			frames[i]:UnregisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
		end
	end
	stacklevel=stacklevel+1
end
function addon:releaseEvents()
	stacklevel=stacklevel-1
	assert(stacklevel>=0)
	if (stacklevel==0) then
		for i=1,#frames do
			frames[i]:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
		end
		frames=nil
	end
end
local holdEvents,releaseEvents=addon.holdEvents,addon.releaseEvents
ns.OnLeave=function() GameTooltip:Hide() end

-------------------- to be estracted to CountersCache
--
--local G=C_Garrison
--ns.Abilities=setmetatable({},{
--	__index=function(t,k) rawset(t,k,G.GetFollowerAbilityName(k)) return rawget(t,k) end
--})
--
--

--[===[@non-debug@
if true then return end
--@end-non-debug@]===]
--@do-not-package@
local me, ns = ...
local addon=ns.addon --#addon
local L=ns.L
local D=ns.D
local C=ns.C
local AceGUI=ns.AceGUI
local _G=_G
local pp=print
_G.GAC=addon

--- Enable a trace for every function call. It's a VERY heavy debug
--
if ns.HD then
local memorysinks={}
local callstack={}
local lib=LibStub("LibInit")
for k,v in pairs(addon) do
	if (type(v))=="function" and not lib[k] then
		local wrapped
		do
			local original=addon[k]
			wrapped=function(...)
				pp(k)
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
				if (memafter-membefore > 20) then
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
end
function addon:GetScroller(title,type,h,w)
	h=h or 800
	w=w or 400
	type=type or "Frame"
	local scrollerWindow=AceGUI:Create("Frame")
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
	scroll.AddRow=function (self,...) return addon:AddRow(self,...) end
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
function addon:cutePrint(scroll,level,k,v)
	if (type(level)=="table") then
		for k,v in pairs(level) do
			self:cutePrint(scroll,"",k,v)
		end
		return
	end
	if (type(v)=="table") then
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
	self:cutePrint(scroll,cache.missions[missionID])
end
function addon:DumpMissions()
	local scroll=self:GetScroller("MissionCache")
	for id,data in pairs(cache.missions) do
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
	local scroll=self:GetScroller(title)
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
	local t=new()
	for i,v in pairs(dbcache.seen) do
		tinsert(t,format("%80s %s %d",self:GetMissionData(i,'name'),date("%d/%m/%y %H:%M:%S",v),ns.wowhead[i]))
	end
	local scroll=self:GetScroller("Expire db")
	self:cutePrint(scroll,t)
	del(t)
end
_G.GCF=GCF
_G.MW=173
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
