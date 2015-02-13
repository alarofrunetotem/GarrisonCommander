local me, ns = ...
local addon=ns.addon --#addon
local L=ns.L
local D=ns.D
local C=ns.C
local AceGUI=ns.AceGUI
local _G=_G
local new, del, copy =ns.new,ns.del,ns.copy
local GMF=GarrisonMissionFrame
local GMFMissions=GarrisonMissionFrameMissions
local G=C_Garrison
ns.missionautocompleting=false

do
	local missions={}
	local states={}
	local currentMission
	local scroller
	local report
	local timer
	local function startTimer(delay)
		delay=delay or 0.2
		addon:ScheduleTimer("MissionAutoComplete",delay,"LOOP")
	end
	local function stopTimer()
		timer=nil
	end
	function addon:MissionsCleanup()
		stopTimer()
		self:MissionEvents(false)
		GMF.MissionTab.MissionList.CompleteDialog:Hide()
		GMF.MissionComplete:Hide()
		GMF.MissionCompleteBackground:Hide()
		GMF.MissionComplete.currentIndex = nil
		GMF.MissionTab:Show()
		GarrisonMissionList_UpdateMissions()
		-- Re-enable "view" button
		GMFMissions.CompleteDialog.BorderFrame.ViewButton:SetEnabled(true)
		missionautocompleting=nil
		GarrisonMissionFrame_SelectTab(1)
		GarrisonMissionFrame_CheckCompleteMissions()
	end
	function addon:MissionEvents(start)
		self:UnregisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE")
		self:UnregisterEvent("GARRISON_MISSION_BONUS_ROLL_LOOT")
		self:UnregisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE")
		self:UnregisterEvent("GARRISON_FOLLOWER_XP_CHANGED")
		self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
		if start then
			self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_LOOT","MissionAutoComplete")
			self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE","MissionAutoComplete")
			self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE","MissionAutoComplete")
			self:RegisterEvent("GARRISON_FOLLOWER_XP_CHANGED","MissionAutoComplete")
			self:RegisterEvent("GET_ITEM_INFO_RECEIVED","MissionAutoComplete")
		else
			self:SafeRegisterEvent("GARRISON_MISSION_BONUS_ROLL_LOOT")
			self:SafeRegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE")
			self:SafeRegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE")
			self:SafeRegisterEvent("GARRISON_FOLLOWER_XP_CHANGED")
		end
	end
	function addon:MissionComplete(this,button)
		GMFMissions.CompleteDialog.BorderFrame.ViewButton:SetEnabled(false)
		missions=G.GetCompleteMissions()
		--GMFMissions.CompleteDialog.BorderFrame.ViewButton:SetEnabled(false) -- Disabling standard Blizzard Completion
		if (missions and #missions > 0) then
			ns.missionautocompleting=true
			report=self:GenerateMissionCompleteList("Missions' results")
			--report:SetPoint("TOPLEFT",GMFMissions.CompleteDialog.BorderFrame)
			--report:SetPoint("BOTTOMRIGHT",GMFMissions.CompleteDialog.BorderFrame)
			report:SetParent(GMF)
			report:SetPoint("TOP",GMF)
			report:SetPoint("BOTTOM",GMF)
			report:SetWidth(500)
			report:SetCallback("OnClose",function() return addon:MissionsCleanup() end)
			for i=1,#missions do
				missions[i].followerXp={}
				missions[i].items={}
				for k,v in pairs(missions[i].followers) do
					missions[i].followerXp[v]={0,G.GetFollowerXP(v),self:GetFollowerData(v,'level'),self:GetFollowerData(v,'quality')}
				end
			end
			currentMission=tremove(missions)
			self:MissionEvents(true)
			self:MissionAutoComplete("LOOP")
		end
	end
	function addon:MissionAutoComplete(event,ID,arg1,arg2,arg3,arg4)
-- C_Garrison.MarkMissionComplete Mark mission as complete and prepare it for bonus roll, da chiamare solo in caso di successo
-- C_Garrison.MissionBonusRoll
	--@debug@
		print("evt",event,ID,arg1,arg2,agr3)
	--@end-debug@
		if self['Event'..event] then
			self['Event'..event](self,event,ID,arg1,arg2,arg3,arg4)
		end
		if (event =="LOOP" ) then
			ID=currentMission and currentMission.missionID or "none"
			arg1=currentMission and currentMission.state or "none"
		end
		-- GARRISON_FOLLOWER_XP_CHANGED: followerID, xpGained, actualXp, newLevel, quality
		if (event=="GARRISON_FOLLOWER_XP_CHANGED") then
			if (arg1 > 0) then
				--report:AddFollower(ID,arg1,arg2)
				currentMission.followerXp[ID][1]=currentMission.followerXp[ID][1]+arg1
			end
			return
		-- GET_ITEM_INFO_RECEIVED: itemID
		elseif (event=="GET_ITEM_INFO_RECEIVED") then
			currentMission.items[ID]=1
			return
		-- GET_ITEM_INFO_RECEIVED: itemID
		elseif (event=="GARRISON_MISSION_BONUS_ROLL_LOOT") then
			currentMission.items[ID]=1
			return
		-- GARRISON_MISSION_COMPLETE_RESPONSE: missionID, requestCompleted, succeeded
		elseif (event=="GARRISON_MISSION_COMPLETE_RESPONSE") then
			if (not arg1) then
				-- We need to call server again
				currentMission.state=0
			elseif (arg2) then -- success, we need to roll
				currentMission.state=1
			else -- failure, just print results
				currentMission.state=2
				startTimer(0.6)
				return
			end
			startTimer(0.1)
			return
		-- GARRISON_MISSION_BONUS_ROLL_COMPLETE: missionID, requestCompleted; happens after C_Garrison.MissionBonusRoll
		elseif (event=="GARRISON_MISSION_BONUS_ROLL_COMPLETE") then
			if (not arg1) then
				-- We need to call server again
				currentMission.state=1
			else
				currentMission.state=3
				startTimer(0.6)
				return
			end
			startTimer(0.1)
			return
		else
			if (currentMission) then
				local step=currentMission.state or -1
				if (step<1) then
					step=0
					currentMission.state=0
					local _
					_,_,_,currentMission.successChance,_,_,currentMission.xpBonus,currentMission.multiplier=G.GetPartyMissionInfo(currentMission.missionID)
					currentMission.xp=select(2,G.GetMissionInfo(currentMission.missionID))
				end
				if (step==0) then
					G.MarkMissionComplete(currentMission.missionID)
				elseif (step==1) then
					G.MissionBonusRoll(currentMission.missionID)
				elseif (step>=2) then
					self:MissionPrintResults(step==3)
					self:RefreshFollowerStatus()
					currentMission=tremove(missions)
					startTimer()
					return
				end
				currentMission.state=step
			else
				report:AddRow(DONE)
			end
		end
	end
	function addon:MissionPrintResults(success)
		stopTimer()

		if (success) then
			report:AddMissionName(currentMission.name,C(format("Succeeded. (Chance was: %s%%)", currentMission.successChance),"Green"))
			PlaySound("UI_Garrison_Mission_Complete_Mission_Success")
		else
			PlaySound("UI_Garrison_Mission_Complete_Encounter_Fail")
			report:AddMissionName(currentMission.name,C(format("Failed. (Chance was: %s%%", currentMission.successChance),"Red"))
		end
--@debug@
		--report:AddRow(format("Resource multiplier: %d Xp Bonus:%d",currentMission.multiplier,currentMission.xpBonus))
		--report:AddRow(format("ID: %d",currentMission.missionID))
--@end-debug@
		if success then
			for k,v in pairs(currentMission.rewards) do
				v.quantity=v.quantity or 0
				v.multiplier=v.multiplier or 1
--@debug@
--				ns.xprint(format("Reward type: = %s",k))
--				for field,value in pairs(v) do
--					ns.xprint(format("   %s = %s",field,value),C.Silver())
--				end
--@end-debug@
				if v.currencyID then
					if v.currencyID == 0 then
							-- Money reward
							report:AddIconText(v.icon,GetMoneyString(v.quantity))
					elseif v.currencyID == GARRISON_CURRENCY then
							-- Garrison currency reward
							report:AddIconText(v.icon,GetCurrencyLink(v.currencyID),v.quantity * v.multiplier)
					else
							-- Other currency reward
							report:AddIconText(v.icon,GetCurrencyLink(v.currencyID),v.quantity )
					end
				elseif v.itemID then
						-- Item reward
						report:AddItem(v.itemID,1)
						currentMission.items[v.itemID]=nil
				else
						-- Follower XP reward
						--report:AddIconText(v.icon,v.name)
				end
			end
		end
		for k,v in pairs(currentMission.items) do
			report:AddItem(k,v)
		end
		for k,v in pairs(currentMission.followers) do
			report:AddFollower(v,currentMission.followerXp[v])
		end
	end
end
