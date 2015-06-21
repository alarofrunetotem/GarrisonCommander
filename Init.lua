local me, ns = ...
local _G=_G
local setmetatable=setmetatable
local next=next
local pairs=pairs
local wipe=wipe
local GetChatFrame=GetChatFrame
local format=format
local GetTime=GetTime
local strjoin=strjoin
local strspilit=strsplit
local tostringall=tostringall
local tostring=tostring
local tonumber=tonumber
--@debug@
LoadAddOn("Blizzard_DebugTools")
if LibDebug then LibDebug() ns.print=print else ns.print=function() end end
--@end-debug@
--[===[@non-debug@
ns.print=function() end
--@end-non.debug@]===]
ns.addon=LibStub("LibInit"):NewAddon(me,'AceHook-3.0','AceTimer-3.0','AceEvent-3.0','AceBucket-3.0')
local addon=ns.addon --#addon
ns.toc=select(4,GetBuildInfo())
ns.AceGUI=LibStub("AceGUI-3.0")
ns.D=LibStub("LibDeformat-3.0")
ns.C=ns.addon:GetColorTable()
ns.L=ns.addon:GetLocale()
ns.G=C_Garrison
ns.GMF=_G.GarrisonMissionFrame
ns.GMFMissions=_G.GarrisonMissionFrameMissions
ns.GSF=_G.GarrisonShipFrame
_G.GARRISON_FOLLOWER_MAX_ITEM_LEVEL = _G.GARRISON_FOLLOWER_MAX_ITEM_LEVEL or 675
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
		print("Created:",createdcount)
		print("Aquired:",newcount)
		print("Released:",delcount)
		print("Cached:",cached())
	end
	--@end-debug@
end

local stacklevel=0
local frames
function ns.holdEvents()
	if stacklevel==0 then
		frames={GetFramesRegisteredForEvent('GARRISON_FOLLOWER_LIST_UPDATE')}
		for i=1,#frames do
			frames[i]:UnregisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
		end
	end
	stacklevel=stacklevel+1
end
function ns.releaseEvents()
	stacklevel=stacklevel-1
	assert(stacklevel>=0)
	if (stacklevel==0) then
		for i=1,#frames do
			frames[i]:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
		end
		frames=nil
	end
end
ns.OnLeave=function() GameTooltip:Hide() end
local upgrades={
	"wt:120302:1",
	"we:114128:3",
	"we:114129:6",
	"we:114131:9",
	"wf:114616:615",
	"wf:114081:630",
	"wf:114622:645",
	"at:120301:1",
	"ae:114745:3",
	"ae:114808:6",
	"ae:114822:9",
	"af:114807:615",
	"af:114806:630",
	"af:114746:645",
}
local followerItems={}
local items={
[114053]={icon='inv_glove_plate_dungeonplate_c_06',quality=2},
[114052]={icon='inv_jewelry_ring_146',quality=3},
[114109]={icon='inv_sword_46',quality=3},
[114068]={icon='inv_misc_pvp_trinket',quality=3},
[114058]={icon='inv_chest_cloth_reputation_c_01',quality=3},
[114063]={icon='inv_shoulder_cloth_reputation_c_01',quality=3},
[114059]={icon='inv_boots_cloth_reputation_c_01',quality=3},
[114066]={icon='inv_jewelry_necklace_70',quality=3},
[114057]={icon='inv_bracer_cloth_reputation_c_01',quality=3},
[114101]={icon='inv_belt_cloth_reputation_c_01',quality=3},
[114098]={icon='inv_helmet_cloth_reputation_c_01',quality=3},
[114096]={icon='inv_boots_cloth_reputation_c_01',quality=3},
[114108]={icon='inv_sword_46',quality=3},
[114094]={icon='inv_bracer_cloth_reputation_c_01',quality=3},
[114099]={icon='inv_pants_cloth_reputation_c_01',quality=3},
[114097]={icon='inv_gauntlets_cloth_reputation_c_01',quality=3},
[114105]={icon='inv_misc_pvp_trinket',quality=3},
[114100]={icon='inv_shoulder_cloth_reputation_c_01',quality=3},
[114110]={icon='inv_sword_46',quality=3},
[114080]={icon='inv_misc_pvp_trinket',quality=3},
[114070]={icon='inv_chest_cloth_reputation_c_01',quality=3},
[114075]={icon='inv_shoulder_cloth_reputation_c_01',quality=3},
[114071]={icon='inv_boots_cloth_reputation_c_01',quality=3},
[114078]={icon='inv_jewelry_necklace_70',quality=3},
[114069]={icon='inv_bracer_cloth_reputation_c_01',quality=3},
[114112]={icon='inv_sword_46',quality=4},
[114087]={icon='inv_misc_pvp_trinket',quality=4},
[114083]={icon='inv_chest_cloth_reputation_c_01',quality=4},
[114085]={icon='inv_shoulder_cloth_reputation_c_01',quality=4},
[114084]={icon='inv_boots_cloth_reputation_c_01',quality=4},
[114086]={icon='inv_jewelry_necklace_70',quality=4},
[114082]={icon='inv_bracer_cloth_reputation_c_01',quality=4},
}
for i=1,#upgrades do
	local _,id,level=strsplit(':',upgrades[i])
	followerItems[id]=level
end
function addon:GetUpgrades()
	return upgrades
end
function addon:GetItems()
	return items
end
-- to be moved in LibInit
--[[
function addon:coroutineExecute(interval,func)
	local co=coroutine.wrap(func)
	local interval=interval
	local repeater
	repeater=function()
		if (co()) then
			C_Timer.After(interval,repeater)
		else
			repeater=nil
		end
	end
	return repeater()
end
--]]
addon:coroutineExecute(0.1,
	function ()
		for itemID,_ in pairs(followerItems) do
			GetItemInfo(itemID)
			coroutine.yield(true)
		end
		for i,v in pairs(items) do
			GetItemInfo(i)
			coroutine.yield(true)
		end
	end
)
function addon:GetType(itemID)
	if (items[itemID]) then return "equip" end
	if (followerItems[itemID]) then return "followerEquip" end
	return "generic"
end
--Data
if ns.toc < 60200 then
ns.traitTable= {
		{
			[9] = "Wastelander",
		[7] = "Mountaineer",
		[45] = "Cave Dweller",
		[46] = "Guerilla Fighter",
		[44] = "Naturalist",
		[48] = "Marshwalker",
		[49] = "Plainsrunner",
		[8] = "Cold-Blooded",
	}, -- [1]
	{
		[79] = "Scavenger",
		[80] = "Extra Training",
		[29] = "Fast Learner",
		[256] = "Treasure Hunter",
	}, -- [2]
	{
		[76] = "High Stamina",
		[221] = "Epic Mount",
		[77] = "Burst of Power",
	}, -- [3]
	[5] = {
		[61] = "Tailoring",
		[52] = "Mining",
		[54] = "Alchemy",
		[56] = "Enchanting",
		[58] = "Inscription",
		[60] = "Leatherworking",
		[62] = "Skinning",
		[53] = "Herbalism",
		[55] = "Blacksmithing",
		[57] = "Engineering",
		[59] = "Jewelcrafting",
	},
	[6] = {
		[73] = "Voodoo Zealot",
		[63] = "Gnome-Lover",
		[66] = "Child of the Moon",
		[70] = "Child of Draenor",
		[74] = "Elvenkind",
		[67] = "Ally of Argus",
		[71] = "Death Fascination",
		[75] = "Economist",
		[64] = "Humanist",
		[68] = "Canine Companion",
		[72] = "Totemist",
		[65] = "Dwarvenborn",
		[69] = "Brew Aficionado",
	},
	[7] = {
		[37] = "Beastslayer",
		[39] = "Primalslayer",
		[4] = "Orcslayer",
		[43] = "Talonslayer",
		[36] = "Demonslayer",
		[38] = "Ogreslayer",
		[40] = "Gronnslayer",
		[42] = "Voidslayer",
		[41] = "Furyslayer",
	},
}
else
ns.traitTable={
[1]={  [9]="Wastelander",  [7]="Mountaineer",  [45]="Cave Dweller",  [46]="Guerilla Fighter",  [44]="Naturalist",  [48]="Marshwalker",  [49]="Plainsrunner",  [8]="Cold-Blooded"},[2]={  [80]="Extra Training",  [314]="Greasemonkey",  [79]="Scavenger",  [256]="Treasure Hunter",  [29]="Fast Learner"},[3]={  [76]="High Stamina",  [221]="Epic Mount",  [77]="Burst of Power"},[6]={  [61]="Tailoring",  [52]="Mining",  [54]="Alchemy",  [56]="Enchanting",  [58]="Inscription",  [60]="Leatherworking",  [62]="Skinning",  [53]="Herbalism",  [55]="Blacksmithing",  [57]="Engineering",  [59]="Jewelcrafting"},[7]={  [64]="Humanist",  [66]="Child of the Moon",  [68]="Canine Companion",  [65]="Dwarvenborn",  [67]="Ally of Argus",  [69]="Brew Aficionado",  [63]="Gnome-Lover"},[8]={  [37]="Beastslayer",  [39]="Primalslayer",  [4]="Orcslayer",  [43]="Talonslayer",  [36]="Demonslayer",  [38]="Ogreslayer",  [40]="Gronnslayer",  [42]="Voidslayer",  [41]="Furyslayer"}
}
end
-- Pseudo Global Support.
-- Calling ns.Configure() will give to the calling function a preloaded env

local ENV={}

for k,v in pairs(ns) do
	ENV[k]=v
end
setmetatable(ENV,
{__index=_G,
__newindex=function(t,k,v)
	assert(type(_G[k]) == 'nil',"Attempting to override global " ..k)
	return rawset(t,k,v)
end
}
)

---@function [parent=#ns] Configure
function ns.Configure()
		local old_env = getfenv(2)
		if old_env ~= _G and old_env ~= ENV then
			error("The calling function has a modified environment, I won't replace it.", 2)
		end
		setfenv(2, ENV)
end
-------------------- to be estracted to CountersCache
--
--local G=C_Garrison
--ns.Abilities=setmetatable({},{
--	__index=function(t,k) rawset(t,k,G.GetFollowerAbilityName(k)) return rawget(t,k) end
--})
--
--
--

--[[ TtraitTable generator
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
ATEINFO['abilities']=map
--]]
