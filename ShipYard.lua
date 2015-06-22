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
	self:SafeHookScript(GSF,"OnShow","Setup",true)
end
function module:Setup(this,...)
	print("Doing one time initialization for",this:GetName(),...)
	self:SafeHookScript(GSF,"OnShow","OnShow",true)
end
function module:OnShow()
	print("Doing all time initialization")
end
