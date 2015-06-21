local me, ns = ...
ns.Configure()
local addon=addon --#addon
local _G=_G
local GSF=GarrisonShipyardFrame
local G=C_Garrison
local pairs=pairs
local format=format
local strsplit=strsplit
local generated
local module=addon:NewSubClass('ShipYard') --#Module
function module:OnInitialize()
	print("ShipYard Loaded")
end
function module:Setup()
	print("Doing one time initialization")
	self:SafeHookScript(GSF,"OnShow","GSF_OnShow",true)
end
function module:GSF_OnShow()
	print("Doing all time initialization")
end
