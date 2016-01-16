local me, ns = ...
ns.Configure()
local addon=addon --#addon
local _G=_G
local qm=addon:NewSubModule("Quick") --#qm
function qm:OnInitialized()
	ns.step="none"
end
local watchdog=0
function qm:RunQuick()
	if not ns.quick then return end
--@debug@
	print("qm.RunQuick",watchdog)
--@end-debug@
	while not qm.Mission do
		if GarrisonCommanderQuickMissionComplete:IsVisible() then
			print("Quickcompletion")
			GarrisonCommanderQuickMissionComplete:Click()
			return -- Waits to be rescheeduled by mission completion
		end
		if not GMF.MissionControlTab:IsVisible() then
			print("MissionControl")
			GMF.tabMC:Click()
			break
		end
		if (GMF.MissionControlTab.runButton:IsEnabled()) then
			print("Run Missions")
			GMF.MissionControlTab.runButton:Click()
		end
		break -- Never loop or we get stuck
	end
	watchdog=watchdog+1
	if watchdog > 100 then
		ns.quick=false
	end
	if ns.quick then
		return addon.ScheduleTimer(qm,"RunQuick",1)
	end

end
function addon:RunQuick(force)
--@debug@
print("Runquick called")
--@end-debug@
	if not IsShiftKeyDown()  and not force then
		self:Popup(L["Are you sure to start Garrison Commander Auto Pilot?\n(Keep shift pressed while clicking to avoid this question)"],10,function() return addon:RunQuick(true) end,function() end)
	else
		ns.quick=true
		return qm:RunQuick()
	end
end