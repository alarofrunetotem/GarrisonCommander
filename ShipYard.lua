local me, ns = ...
local addon=ns.addon --#addon
local L=ns.L
local D=ns.D
local C=ns.C
local AceGUI=ns.AceGUI
local _G=_G
--@debug@
--if LibDebug() then LibDebug() end
--@end-debug@
local new, del, copy =ns.new,ns.del,ns.copy
local GSF=GarrisonShipyardFrame
local G=C_Garrison
local pairs=pairs
local format=format
local strsplit=strsplit
local generated
local module=addon:NewSubClass('ShipYard') --#Module
function module:OnInitialize()
	self:Print("ShipYard Loaded")
end
function module:Setup()
	print("Doing one time initialization")
	self:SafeHookScript(GSF,"OnShow","GSF_OnShow",true)
end
function module:GSF_OnShow()
	print("Doing all time initialization")
end
