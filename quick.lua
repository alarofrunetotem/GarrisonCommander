local me, ns = ...
ns.Configure()
local addon=addon --#addon
local _G=_G
local GMF=GMF
local GSF=GSF
local qm=addon:NewSubModule("Quick") --#qm
local missionDone
local shipyardDone
local NavalDomination={
	Alliance=39068,
	Horde=39246
}
local questid=NavalDomination[UnitFactionGroup("player")]
function qm:OnInitialized()
	ns.step="none"
end
local watchdog=0
local function HasShipTable()
	return ns.quests[39068] or ns.quests[39246] -- Naval Domination
end
function addon:missionDone()
	missionDone=true
end
function addon:shipyardDone()
	shipyardDone=true
end
function addon:LogoutTimer(dialog,elapsed)
	if dialog.which ~="LIBINIT_POPUP" then return end
	local text = _G[dialog:GetName().."Text"];
	local timeleft = ceil(dialog.timeleft);
	local which=dialog.which	
	if ( timeleft < 60 ) then
		text:SetFormattedText(StaticPopupDialogs[which].text, timeleft, SECONDS);
	else
		text:SetFormattedText(StaticPopupDialogs[which].text, ceil(timeleft / 60), MINUTES);
	end	
end
function addon:LogoutPopup(timeout)
	local popup=addon:Popup(CAMP_TIMER,timeout or 10,
		function(dialog,data,data2)
			addon:Unhook(dialog,"OnUpdate")
			Logout()
		end,
		function(dialog,data,timeout)
			addon:Unhook(dialog,"OnUpdate")
			if timeout=="timeout" then Logout() end
			missionDone=false
			shipyardDone=false
			StaticPopup_Hide("LIBINIT_POPUP")
		end
	)
	self:SecureHookScript(popup, "OnUpdate", "LogoutTimer")
end
function qm:RunQuick()
	local completeButton=GMF:IsVisible() and GarrisonCommanderQuickMissionComplete or GCQuickShipMissionCompletionButton
	local main=GMF:IsVisible() and GMF or GSF
	if not ns.quick then 
		HideUIPanel(main)
		if not G.HasShipyard() then
			shipyardDone=true
		end
		if missionDone and shipyardDone then
			addon:LogoutPopup(10)
		end
		return 
	end
	while not qm.Mission do
		if completeButton:IsVisible() then
			completeButton:Click()
			return -- Waits to be rescheeduled by mission completion
		end
		if not main.MissionControlTab:IsVisible() then
			main.tabMC:Click()
			break
		end
		if (main.MissionControlTab.runButton:IsEnabled()) then
			main.MissionControlTab.runButton:Click()
		end
		break -- Never loop or we get stuck
	end
	watchdog=watchdog+1
	if watchdog > 10 then
		ns.quick=false
	end
	if ns.quick then
		return addon.ScheduleTimer(qm,"RunQuick",1)
	end

end
function addon:RunQuick(force)
	local main=GMF:IsVisible() and GMF or GSF
	if main.tabMC:GetChecked() then
		self:OpenMissionControlTab()
		self:ScheduleTimer("RunQuick",0.2)
		return
	end
	if not IsShiftKeyDown()  and not force then
		self:Popup(L["Are you sure to start Garrison Commander Auto Pilot?\n(Keep shift pressed while clicking to avoid this question)"],10,
			function()
				StaticPopup_Hide("LIBINIT_POPUP")
				return addon:RunQuick(true)
			end,
			function()
				StaticPopup_Hide("LIBINIT_POPUP")
			end)
	else
		ns.quick=true
		qm.watchdog=0
		return addon.ScheduleTimer(qm,"RunQuick",0.2)
	end
end