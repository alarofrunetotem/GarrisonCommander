local me, ns = ...
local addon=ns.addon --#addon
local L=ns.L
local D=ns.D
local C=ns.C
local AceGUI=ns.AceGUI
local _G=_G
local new, del, copy =ns.new,ns.del,ns.copy
-- Courtesy of Motig
-- Concept and interface reused with permission
-- Mission building rewritten from scratch
--local GMC_G = {}
local factory=addon:GetFactory()
--GMC_G.frame = CreateFrame('FRAME')
local aMissions={}
local dbcache
local cache
local db
local GMC
local GMF=GarrisonMissionFrame
local G=C_Garrison
local GMCUsedFollowers={}
local wipe=wipe
local pairs=pairs
local tinsert=tinsert
--@debug@
_G.GAC=addon
if LibDebug then LibDebug() end
--@end-debug@
local dbg
local tItems = {
	{t = 'Enable/Disable money rewards.', i = 'Interface\\Icons\\inv_misc_coin_01', key = 'gold'},
	{t = 'Enable/Disable resource awards. (Resources/Seals)', i= 'Interface\\Icons\\inv_garrison_resource', key = 'resources'},
	{t = 'Enable/Disable rush scroll.', i= 'Interface\\ICONS\\INV_Scroll_12', key = 'rush'},
	{t = 'Enable/Disable Follower XP Bonus rewards.', i = 'Interface\\Icons\\XPBonus_Icon', key = 'xp'},
	{t = 'Enable/Disable follower equip enhancement.', i = 'Interface\\ICONS\\Garrison_ArmorUpgrade', key = 'followerUpgrade'},
	{t = 'Enable/Disable item tokens.', i = "Interface\\ICONS\\INV_Bracer_Cloth_Reputation_C_01", key = 'itemLevel'},
	{t = 'Enable/Disable apexis.', i = "Interface\\Icons\\inv_apexis_draenor", key = 'apexis'},
	{t = 'Enable/Disable other rewards.', i = "Interface\\ICONS\\INV_Box_02", key = 'other'}
}
local tOrder
local settings
if (ns.toc >=60200) then
	tinsert(tItems,3,{t = 'Enable/Disable oil awards.', i= 'Interface\\Icons\\garrison_oil', key = 'oil'})
end
local module=addon:NewSubClass("MissionControl") --#module
function module:GMCBusy(followerID)
	return GMCUsedFollowers[followerID]
end
addon.GMCBusy=module.GMCBusy
function module:GMCCreateMissionList(workList)
	--First get rid of unwanted rewards and missions that are too long
	local settings=self.privatedb.profile.missionControl
	local ar=settings.allowedRewards
	wipe(workList)
	for _,missionID in self:GetMissionIterator() do
		local discarded=false
		local class=self:GetMissionData(missionID,"class")
		repeat
			print("|cffff0000",'Examing',missionID,self:GetMissionData(missionID,"name"),class,"|r")
			local durationSeconds=self:GetMissionData(missionID,'durationSeconds')
			if (durationSeconds > settings.maxDuration * 3600 or durationSeconds <  settings.minDuration * 3600) then
				print(missionID,"discarded due to len",durationSeconds /3600)
				break
			end -- Mission too long, out of here
			if (self:GetMissionData(missionID,'isRare') and settings.skipRare) then
				print(missionID,"discarded due to rarity")
				break
			end
			if (not ar[class]) then
				print(missionID,"discarded due to class == ", class)
				discarded=true
				break
			end
			if (not discarded) then
				tinsert(workList,missionID)
			end
		until true
	end
	local parties=self:GetParty()
	local function msort(i1,i2)
		local c1=addon:GetMissionData(i1,'class','other')
		local c2=addon:GetMissionData(i2,'class','other')
		if (c1==c2) then
			return addon:GetMissionData(i1,c1,0) > addon:GetMissionData(i2,c2,0)
		else
			return tOrder[c1]<tOrder[c2]
		end
	end
	table.sort(workList,msort)
end
--- This routine can be called both as coroutin and as a standard one
-- In standard version, delay between group building and submitting is done via a self schedule
--@param #integer missionID Optional, to run a single mission
--@param #bool start Optional, tells that follower already are on mission and that we need just to start it
function module:GMCRunMission(missionID,start)
	print("Asked to start mission",missionID)
	if (start) then
		G.StartMission(missionID)
		PlaySound("UI_Garrison_CommandTable_MissionStart")
		return
	end
	for i=1,#GMC.ml.Parties do
		local party=GMC.ml.Parties[i]
		print("Checking",party.missionID)
		if (missionID and party.missionID==missionID or not missionID) then
			GMC.ml.widget:RemoveChild(party.missionID)
			GMC.ml.widget:DoLayout()
			if (party.full) then
				for j=1,#party.members do
					G.AddFollowerToMission(party.missionID, party.members[j])
				end
				if (not missionID) then
					coroutine.yield(true)
					G.StartMission(party.missionID)
					PlaySound("UI_Garrison_CommandTable_MissionStart")
					coroutine.yield(true)
				else
					self:ScheduleTimer("GMCRunMission",0.25,party.missionID,true)
				end
			end
		end
	end
end
do
	local timeElapsed=0
	local currentMission=0
	local x=0
	function module:GMCCalculateMissions(this,elapsed)
		db.news.MissionControl=true
		timeElapsed = timeElapsed + elapsed
		if (#aMissions == 0 ) then
			if timeElapsed >= 1 then
				currentMission=0
				x=0
				self:Unhook(this,"OnUpdate")
				GMC.ml.widget:SetTitle(READY)
				GMC.ml.widget:SetTitleColor(C.Green())
				wipe(GMCUsedFollowers)
				this:Enable()
				GMC.runButton:Enable()
				if (#GMC.ml.Parties>0) then
					GMC.runButton:Enable()
				end
			end
			return
		end
		if (timeElapsed >=0.05) then
			currentMission=currentMission+1
			if (currentMission > #aMissions) then
				wipe(aMissions)
				currentMission=0
				x=0
				timeElapsed=0.5
			else
				local missionID=aMissions[currentMission]
				GMC.ml.widget:SetFormattedTitle("Processing mission %d of %d (%s)",currentMission,#aMissions,G.GetMissionName(missionID))
				local class=self:GetMissionData(missionID,"class")
				local checkprio=class
				if checkprio=="itemLevel" then class="equip" end
				if checkprio=="followerUpgrade" then class= "followerEquip" end
				print(C("Processing ","Red"),missionID,addon:GetMissionData(missionID,"name"))
				local minimumChance=0
				if (GMC.settings.useOneChance) then
					minimumChance=tonumber(GMC.settings.minimumChance) or 100
				else
					minimumChance=tonumber(GMC.settings.rewardChance[checkprio]) or 100
				end
				local party={members={},perc=0}
				self:MCMatchMaker(missionID,party,GMC.settings.skipEpic)
				print ("                           Requested",class,";",minimumChance,"Mission",party.perc,party.full)
				if ( party.full and party.perc >= minimumChance) then
					print("                           Mission accepted")
					local mb=AceGUI:Create("GMCMissionButton")
					for i=1,#party.members do
						GMCUsedFollowers[party.members[i]]=true
					end
					party.missionID=missionID
					tinsert(GMC.ml.Parties,party)
					GMC.ml.widget:PushChild(mb,missionID)
					mb:SetFullWidth(true)
					mb:SetMission(self:GetMissionData(missionID),party)
					mb:SetCallback("OnClick",function(...)
						module:GMCRunMission(missionID)
						GMC.ml.widget:RemoveChild(missionID)
					end
					)
				end
				timeElapsed=0
			end
		end
	end
end

function module:GMC_OnClick_Run(this,button)
	this:Disable()
	GMC.logoutButton:Disable()
	do
	local elapsed=0
	local co=coroutine.wrap(self.GMCRunMission)
	self:RawHookScript(GMC.runButton,'OnUpdate',function(this,ts)
		elapsed=elapsed+ts
		if (elapsed>0.25) then
			elapsed=0
			local rc=co(self)
			if (not rc) then
				self:Unhook(GMC.runButton,'OnUpdate')
				GMC.logoutButton:Enable()
			end
		end
	end
	)
	end
end
function module:GMC_OnClick_Start(this,button)
	print(C("-------------------------------------------------","Yellow"))
	GMC.ml.widget:ClearChildren()
	if (self:GetTotFollowers(AVAILABLE) == 0) then
		GMC.ml.widget:SetTitle("All followers are busy")
		GMC.ml.widget:SetTitleColor(C.Orange())
		return
	end
	if ( G.IsAboveFollowerSoftCap(1) ) then
		GMC.ml.widget:SetTitle(GARRISON_MAX_FOLLOWERS_MISSION_TOOLTIP)
		GMC.ml.widget:SetTitleColor(C.Red())
		return
	end
	this:Disable()
	GMC.ml.widget:SetTitleColor(C.Green())
	module:GMCCreateMissionList(aMissions)
	wipe(GMCUsedFollowers)
	wipe(GMC.ml.Parties)
	self:RefreshFollowerStatus()
	if (#aMissions>0) then
		GMC.ml.widget:SetFormattedTitle(L["Processing mission %d of %d"],1,#aMissions)
	else
		GMC.ml.widget:SetTitle("No mission matches your criteria")
		GMC.ml.widget:SetTitleColor(C.Red())
	end
	self:RawHookScript(GMC.startButton,'OnUpdate',"GMCCalculateMissions")

end
local chestTexture
local function drawItemButtons()
	local scale=1.1
	local h=37 -- itemButtonTemplate standard size
	local gap=5
	local single=GMC.settings.useOneChance
	--for j = 1, #tItems do
		--local i=tOrder[j]
	for j,i in ipairs(tOrder) do
		local frame = GMC.ignoreFrames[j] or CreateFrame('BUTTON', "Priority" .. j, GMC.aif, 'ItemButtonTemplate')
		GMC.ignoreFrames[j] = frame
		frame:SetID(i)
		frame:ClearAllPoints()
		frame:SetScale(scale)
		frame:SetPoint('TOPLEFT', 0,(j) * (-h -gap) * scale)
		frame.icon:SetTexture(tItems[i].i)
		frame.key=tItems[i].key
		tOrder[frame.key]=j
		frame.tooltip=tItems[i].t
		frame.allowed=GMC.settings.allowedRewards[frame.key]
		frame.chance=GMC.settings.rewardChance[frame.key]
		frame.icon:SetDesaturated(not frame.allowed)
		-- Need to resave them asap in order to populate the array for future scans
		GMC.settings.allowedRewards[frame.key]=frame.allowed
		GMC.settings.rewardChance[frame.key]=frame.chance
		frame.slider=frame.slider or factory:Slider(frame,0,100,frame.chance or 100,frame.chance or 100)
		frame.slider:SetWidth(128)
		frame.slider:SetPoint('BOTTOMLEFT',60,0)
		frame.slider.Text:SetFontObject('NumberFont_Outline_Med')
		if (single) then
			frame.slider.Text:SetTextColor(C.Silver())
		else
			frame.slider.Text:SetTextColor(C.Green())
		end
		frame.slider.isPercent=true
		frame.slider:SetScript("OnValueChanged",function(this,value)
			GMC.settings.rewardChance[this:GetParent().key]=this:OnValueChanged(value)
			end
		)
		frame.slider:OnValueChanged(GMC.settings.rewardChance[frame.key] or 100)
		--frame.slider:SetText(GMC.settings.rewardChance[frame.key])
		frame.chest = frame.chest or frame:CreateTexture(nil, 'BACKGROUND')
		frame.chest:SetTexture('Interface\\Garrison\\GarrisonMissionUI2.blp')
		frame.chest:SetAtlas(chestTexture)
		frame.chest:SetSize((209-(209*0.25))*0.30, (155-(155*0.25)) * 0.30)
		frame.chest:SetPoint('CENTER',frame.slider, 0, 25)
		if (single) then
			frame.chest:SetDesaturated(true)
		else
			frame.chest:SetDesaturated(false)
		end
		frame.chest:Show()
		frame:SetScript('OnClick', function(this)
			GMC.settings.allowedRewards[this.key] = not GMC.settings.allowedRewards[this.key]
			drawItemButtons()
			GMC.startButton:Click()
		end)
		frame:SetScript('OnEnter', function(this)
			GameTooltip:SetOwner(this, 'ANCHOR_BOTTOMRIGHT')
			GameTooltip:AddLine(this.tooltip);
			GameTooltip:Show()
		end)
		frame:RegisterForDrag("LeftButton")
		frame:SetMovable(true)
		frame:SetScript("OnDragStart",function(this,button)
			print("Start",this:GetID())
			this:StartMoving()
			this.oldframestrata=this:GetFrameStrata()
			this:SetFrameStrata("FULLSCREEN_DIALOG")
		end)
		frame:SetScript("OnDragStop",function(this,button)
			this:StopMovingOrSizing()
			print("Stopped",this:GetID())
			this:SetFrameStrata(this.oldframestrata)

		end)
		frame:SetScript("OnReceiveDrag",function(this)
				local x,y=this:GetCenter()
				local id=this:GetID()
				for i=1,#tItems do
					local f=GMC.ignoreFrames[i]
					if f:GetID() ~= id then
						print(y,f:GetBottom(),f:GetTop())
						if y>=f:GetBottom() and y<=f:GetTop() then
							this:SetID(f:GetID())
							f:SetID(id)
							for j=1,#tItems do
								tOrder[j]=GMC.ignoreFrames[j]:GetID()
								tOrder[GMC.ignoreFrames[j].key]=j
							end
							break
						end
					end
				end
				drawItemButtons()
				GMC.startButton:Click()
		end)
		frame:SetScript('OnLeave', function() GameTooltip:Hide() end)
		frame:Show()
		frame.top=frame:GetTop()
		frame.bottom=frame:GetBottom()
	end
	if not GMC.rewardinfo then
		GMC.rewardinfo = GMC.aif:CreateFontString()
		local info=GMC.rewardinfo
		info:SetFontObject('GameFontHighlight')
		info:SetText("Click to enable/disable a reward.\nDrag to reorder")
		info:SetTextColor(1, 1, 1)
		info:SetPoint("TOP",GMC.ignoreFrames[#tItems],"BOTTOM",256/2,-15)
	end
	GMC.aif:SetSize(256, (scale*h+gap) * #tItems)
	return GMC.ignoreFrames[#tItems]

end

function module:OnInitialized()
	local bigscreen=ns.bigscreen
	db=addon.db.global
	dbcache=addon.privatedb.profile
	cache=addon.private.profile
	chestTexture='GarrMission-'..UnitFactionGroup('player').. 'Chest'
	GMC = CreateFrame('FRAME', 'GMCOptions', GMF)
	ns.GMC=GMC
	GMC.settings=dbcache.missionControl
	settings=dbcache.missionControl
	if type(settings.allowedRewards['equip'])~='nil' then
		settings.allowedRewards['itemLevel']=settings.allowedRewards['equip']
		settings.allowedRewards['equip']=nil
	end
	if type(settings.allowedRewards['followerEquip'])~='nil' then
		settings.allowedRewards['followerUpgrade']=settings.allowedRewards['followerUpgrade']
		settings.allowedRewards['followerEquip']=nil
	end
	tOrder=GMC.settings.rewardOrder
	if GMC.settings.itemPrio then
		GMC.settings.itemPrio=nil
	end
	GMC:SetAllPoints()
	--GMC:SetPoint('LEFT')
	--GMC:SetSize(GMF:GetWidth(), GMF:GetHeight())
	GMC:Hide()
	local chance=self:GMCBuildChance()
	local duration=self:GMCBuildDuration()
	local rewards=self:GMCBuildRewards()
	local list=self:GMCBuildMissionList()
	duration:SetPoint("TOPLEFT",0,-50)
	chance:SetPoint("TOPLEFT",duration,"BOTTOMLEFT",0,-80)
	rewards:SetPoint("TOPLEFT",duration,"TOPRIGHT",bigscreen and 50 or 10,0)
	list:SetPoint("TOPLEFT",rewards,"TOPRIGHT",10,-30)
	list:SetPoint("BOTTOMRIGHT",GMF,"BOTTOMRIGHT",-25,25)
	GMC.startButton = CreateFrame('BUTTON',nil,  list.frame, 'GameMenuButtonTemplate')
	GMC.startButton:SetText('Calculate')
	GMC.startButton:SetWidth(148)
	GMC.startButton:SetPoint('TOPLEFT',10,25)
	GMC.startButton:SetScript('OnClick', function(this,button) self:GMC_OnClick_Start(this,button) end)
	GMC.startButton:SetScript('OnEnter', function() GameTooltip:SetOwner(GMC.startButton, 'ANCHOR_TOPRIGHT') GameTooltip:AddLine('Assign your followers to missions.') GameTooltip:Show() end)
	GMC.startButton:SetScript('OnLeave', function() GameTooltip:Hide() end)
	GMC.runButton = CreateFrame('BUTTON', nil,list.frame, 'GameMenuButtonTemplate')
	GMC.runButton:SetText('Send all mission at once')
	GMC.runButton:SetScript('OnEnter', function()
		GameTooltip:SetOwner(GMC.runButton, 'ANCHOR_TOPRIGHT')
		GameTooltip:AddLine(L["Submit all your mission at once. No question asked."])
		GameTooltip:AddLine(L["You can also send mission one by one clicking on each button."])
		GameTooltip:Show()
	end)
	GMC.runButton:SetScript('OnLeave', function() GameTooltip:Hide() end)
	GMC.runButton:SetWidth(148)
	GMC.runButton:SetScript('OnClick',function(this,button) self:GMC_OnClick_Run(this,button) end)
	GMC.runButton:Disable()
	GMC.runButton:SetPoint('TOPRIGHT',-10,25)
	GMC.logoutButton=CreateFrame('BUTTON', nil,list.frame, 'GameMenuButtonTemplate')
	GMC.logoutButton:SetText(LOGOUT)
	GMC.logoutButton:SetWidth(ns.bigscreen and 148 or 90)
	GMC.logoutButton:SetScript("OnClick",function() GMF:Hide() Logout() end )
	GMC.logoutButton:SetPoint('TOP',0,25)
	GMC.skipRare=factory:Checkbox(GMC,GMC.settings.skipRare,L["Ignore rare missions"])
	GMC.skipRare:SetPoint("TOPLEFT",chance,"BOTTOMLEFT",40,-50)
	GMC.skipRare:SetScript("OnClick",function(this)
		GMC.settings.skipRare=this:GetChecked()
		module:GMC_OnClick_Start(GMC.startButton,"LeftUp")
	end)
	local warning=GMC:CreateFontString(nil,"ARTWORK","CombatTextFont")
	warning:SetText(L["Epic followers are NOT sent alone on xp only missions"])
	warning:SetPoint("TOPLEFT",GMC,"TOPLEFT",0,-25)
	warning:SetPoint("TOPRIGHT",GMC,"TOPRIGHT",0,-25)
	warning:SetJustifyH("CENTER")
	warning:SetTextColor(C.Orange())
	if (GMC.settings.skipEpic) then warning:Show() else warning:Hide() end
	GMC.skipEpic=factory:Checkbox(GMC,GMC.settings.skipEpic,L["Ignore epic followers for xp only missions"])
	GMC.skipEpic:SetPoint("TOPLEFT",GMC.skipRare,"BOTTOMLEFT",0,-10)
	GMC.skipEpic:SetScript("OnClick",function(this)
		GMC.settings.skipEpic=this:GetChecked()
		if (GMC.settings.skipEpic) then warning:Show() else warning:Hide() end
		module:GMC_OnClick_Start(GMC.startButton,"LeftUp")
	end)
	GMC.Credits=GMC:CreateFontString(nil,"ARTWORK","QuestFont_Shadow_Small")
	GMC.Credits:SetWidth(0)
	GMC.Credits:SetFormattedText(C(L["Original concept and interface by %s"],'Yellow'),C("Motig","Red") )
	GMC.Credits:SetJustifyH("LEFT")
	GMC.Credits:SetPoint("BOTTOMLEFT",25,25)
	return GMC
end
function module:GMCBuildChance()
	_G['GMC']=GMC
	--Chance
	GMC.cf = CreateFrame('FRAME', nil, GMC)
	GMC.cf:SetSize(256, 150)

	GMC.cp = GMC.cf:CreateTexture(nil, 'BACKGROUND')
	GMC.cp:SetTexture('Interface\\Garrison\\GarrisonMissionUI2.blp')
	GMC.cp:SetAtlas(chestTexture)
	GMC.cp:SetSize((209-(209*0.25))*0.60, (155-(155*0.25))*0.60)
	GMC.cp:SetPoint('CENTER', 0, 20)

	GMC.cc = GMC.cf:CreateFontString()
	GMC.cc:SetFontObject('GameFontNormalHuge')
	GMC.cc:SetText('Success Chance')
	GMC.cc:SetPoint('TOP', 0, 0)
	GMC.cc:SetTextColor(1, 1, 1)

	GMC.ct = GMC.cf:CreateFontString()
	GMC.ct:SetFontObject('ZoneTextFont')
	GMC.ct:SetFormattedText('%d%%',GMC.settings.minimumChance)
	GMC.ct:SetPoint('TOP', 0, -40)
	GMC.ct:SetTextColor(0, 1, 0)

	GMC.cs = factory:Slider(GMC.cf,0,100,GMC.settings.minimumChance,'Minumum chance to start a mission')
	GMC.cs:SetPoint('BOTTOM', 10, 0)
	GMC.cs:SetScript('OnValueChanged', function(self, value)
			local value = math.floor(value)
			GMC.ct:SetText(value..'%')
			GMC.settings.minimumChance = value
	end)
	GMC.cs:SetValue(GMC.settings.minimumChance)
	GMC.ck=factory:Checkbox(GMC.cs,GMC.settings.useOneChance,"Use this percentage for all missions")
	GMC.ck.tooltip="Unchecking this will allow you to set specific success chance for each reward type"
	GMC.ck:SetPoint("TOPLEFT",GMC.cs,"BOTTOMLEFT",-25,-10)
	GMC.ck:SetScript("OnClick",function(this)
		GMC.settings.useOneChance=this:GetChecked()
		if (GMC.settings.useOneChance) then
			GMC.cp:SetDesaturated(false)
			GMC.ct:SetTextColor(C.Green())
		else
			GMC.cp:SetDesaturated(true)
			GMC.ct:SetTextColor(C.Silver())
		end
		drawItemButtons()
	end)
	return GMC.cf
end
local function timeslidechange(this,value)
	local value = math.floor(value)
	if (this.max) then
		GMC.settings.maxDuration = max(value,GMC.settings.minDuration)
		if (value~=GMC.settings.maxDuration) then this:SetValue(GMC.settings.maxDuration) end
	else
		GMC.settings.minDuration = min(value,GMC.settings.maxDuration)
		if (value~=GMC.settings.minDuration) then this:SetValue(GMC.settings.minDuration) end
	end
	local c = 1-(value*(1/24))
	if c < 0.3 then c = 0.3 end
	GMC.mt:SetTextColor(1, c, c)
	GMC.mt:SetFormattedText("%d-%dh",GMC.settings.minDuration,GMC.settings.maxDuration)
end
function module:GMCBuildDuration()
	-- Duration
	GMC.tf = CreateFrame('FRAME', nil, GMC)
	GMC.tf:SetSize(256, 180)
	GMC.tf:SetPoint('LEFT', 80, 120)

	GMC.bg = GMC.tf:CreateTexture(nil, 'BACKGROUND')
	GMC.bg:SetTexture('Interface\\Timer\\Challenges-Logo.blp')
	GMC.bg:SetSize(100, 100)
	GMC.bg:SetPoint('CENTER', 0, 0)
	GMC.bg:SetBlendMode('ADD')

	GMC.tcf = GMC.tf:CreateTexture(nil, 'BACKGROUND')
	--bb:SetTexture('Interface\\Timer\\Challenges-Logo.blp')
	--bb:SetTexture('dungeons\\textures\\devices\\mm_clockface_01.blp')
	GMC.tcf:SetTexture('World\\Dungeon\\Challenge\\clockRunes.blp')
	GMC.tcf:SetSize(110, 110)
	GMC.tcf:SetPoint('CENTER', 0, 0)
	GMC.tcf:SetBlendMode('ADD')

	GMC.mdt = GMC.tf:CreateFontString()
	GMC.mdt:SetFontObject('GameFontNormalHuge')
	GMC.mdt:SetText('Mission Duration')
	GMC.mdt:SetPoint('TOP', 0, 0)
	GMC.mdt:SetTextColor(1, 1, 1)

	GMC.mt = GMC.tf:CreateFontString()
	GMC.mt:SetFontObject('ZoneTextFont')
	GMC.mt:SetFormattedText('%d-%dh',GMC.settings.minDuration,GMC.settings.maxDuration)
	GMC.mt:SetPoint('CENTER', 0, 0)
	GMC.mt:SetTextColor(1, 1, 1)

	GMC.ms1 = factory:Slider(GMC.tf,0,24,GMC.settings.minDuration,'Minimum mission duration.')
	GMC.ms2 = factory:Slider(GMC.tf,0,24,GMC.settings.maxDuration,'Maximum mission duration.')
	GMC.ms1:SetPoint('BOTTOM', 0, 0)
	GMC.ms2:SetPoint('TOP', GMC.ms1,"BOTTOM",0, -25)
	GMC.ms2.max=true
	GMC.ms1:SetScript('OnValueChanged', timeslidechange)
	GMC.ms2:SetScript('OnValueChanged', timeslidechange)
	timeslidechange(GMC.ms1,GMC.settings.minDuration)
	timeslidechange(GMC.ms2,GMC.settings.maxDuration)
	return GMC.tf
end
function module:GMCBuildRewards()
	--Allowed rewards
	GMC.aif = CreateFrame('FRAME', nil, GMC)
	GMC.itf = GMC.aif:CreateFontString()
	GMC.itf:SetFontObject('GameFontNormalHuge')
	GMC.itf:SetText('Allowed Rewards')
	GMC.itf:SetPoint('TOP', 0, -10)
	GMC.itf:SetTextColor(1, 1, 1)
	GMC.ignoreFrames = {}
	-- converting from old data
	local ar=GMC.settings.allowedRewards
	local rc=GMC.settings.rewardChance
	if ar.xpBonus then ar.xp=true end
	ar.xpBonus=nil
	if ar.followerUpgrade then ar.followerEquip=true end
	ar.followerUpgrade=nil
	if ar.itemLevel then ar.equip=true end
	ar.itemLevel=nil
	if rc.xpBonus then rc.xp=rc.xpbonus or 100 end
	rc.xpBonus=nil
	if rc.followerUpgrade then rc.followerEquip=rc.followerUpgrade or 100 end
	rc.followerUpgrade=nil
	if rc.itemLevel then rc.equip=rc.itemLevel or 100 end
	rc.itemLevel=nil
	local ref=drawItemButtons()
	return GMC.aif
end

function module:GMCBuildMissionList()
		-- Mission list on follower panels
--		local ml=CreateFrame("Frame",nil,GMC)
--		addBackdrop(ml)
--		ml:Show()
--		ml.Missions={}
--		ml.Parties={}
--		GMC.ml=ml
--		local fs=ml:CreateFontString(nil, "BACKGROUND", "GameFontNormalHugeBlack")
--		fs:SetPoint("TOPLEFT",0,-5)
--		fs:SetPoint("TOPRIGHT",0,-5)
--		fs:SetText(READY)
--		fs:SetTextColor(C.Green())
--		fs:SetHeight(30)
--		fs:SetJustifyV("CENTER")
--		fs:Show()
--		GMC.progressText=fs
--		GMC.ml.Header=fs
--		return GMC.ml
	local ml={widget=AceGUI:Create("GMCLayer"),Parties={}}
	ml.widget:SetTitle(READY)
	ml.widget:SetTitleColor(C.Green())
	ml.widget:SetTitleHeight(40)
	ml.widget:SetParent(GMC)
	ml.widget:Show()
	GMC.ml=ml
	return ml.widget

end
