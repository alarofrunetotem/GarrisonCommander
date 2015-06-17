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
local GMF=GarrisonMissionFrame
local GMFMissions=GarrisonMissionFrameMissions
local G=C_Garrison
local GARRISON_CURRENCY=GARRISON_CURRENCY
local pairs=pairs
local format=format
local strsplit=strsplit
local generated
local module=addon:NewSubClass('ShipYard') --#Module
function module:OnInitialize()
	self:Print("ShipYard Loaded")
end
print("CIAOCIAO")