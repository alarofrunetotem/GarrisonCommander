local me, ns = ...
local print,hooksecurefunc,IsAddOnLoaded=print,hooksecurefunc,IsAddOnLoaded
local gc,gb="GarrisonCommander","GarrisonCommander-Broker"
local garrison,orderhall,champion,sanctum=
MINIMAP_GARRISON_LANDING_PAGE_TOOLTIP,
MINIMAP_ORDER_HALL_LANDING_PAGE_TOOLTIP,
GARRISON_TYPE_8_0_LANDING_PAGE_TOOLTIP,
GARRISON_TYPE_9_0_LANDING_PAGE_TOOLTIP
local LE_GARRISON_TYPE_6_0=Enum.GarrisonType.Type_6_0_Garrison
local LE_GARRISON_TYPE_7_0=Enum.GarrisonType.Type_7_0_Garrison
local LE_GARRISON_TYPE_8_0=Enum.GarrisonType.Type_8_0_Garrison
local LE_GARRISON_TYPE_9_0=Enum.GarrisonType.Type_9_0_Garrison
local descriptions={
[LE_GARRISON_TYPE_6_0] = "Garrison",
[LE_GARRISON_TYPE_7_0]= "Order Hall",
[LE_GARRISON_TYPE_8_0] = "CHampion Missions",
[LE_GARRISON_TYPE_9_0] = "Covenant"
}
local function addTooltip(d,key,message)
  if (d==message) then return end
  GameTooltip:AddLine(key .. " " .. message)
end
print("GCB",me,gc,IsAddOnLoaded(gc),gb,IsAddOnLoaded(gb))
if (me ==  gc and  not IsAddOnLoaded(gb) or
    me ==  gb and  not IsAddOnLoaded(gc)
) then
    print("Hooking tooltip")
     ExpansionLandingPageMinimapButton:HookScript("OnEnter",
     function(this)
      local d=this.description
        addTooltip(d,CTRL_KEY_TEXT,garrison)
        addTooltip(d,SHIFT_KEY_TEXT,orderhall)
        addTooltip(d,CTRL_KEY_TEXT .. '-' .. SHIFT_KEY_TEXT,champion)
        if C_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer(LE_EXPANSION_DRAGONFLIGHT) then addTooltip(d,CTRL_KEY_TEXT .. '-' .. ALT_KEY_TEXT,sanctum) end
        GameTooltip:Show()
    end
    )
    ExpansionLandingPageMinimapButton:HookScript("OnClick",
      function (this,button)
        local shift,ctrl,alt=IsShiftKeyDown(),IsControlKeyDown(),IsAltKeyDown()
        local requested=0
        print (shift,ctrl,alt)
        if ctrl then
          if alt then
            requested=LE_GARRISON_TYPE_9_0
          elseif shift then
            requested=LE_GARRISON_TYPE_8_0
          else
            requested=LE_GARRISON_TYPE_6_0
          end
        elseif shift then
          requested=LE_GARRISON_TYPE_7_0
        else
          return
        end
        if not GarrisonLandingPage then
          Garrison_LoadUI()
        end
          if InCombatLockdown() then return end
        local actual=GarrisonLandingPage.garrTypeID
        local original=requested
        if ExpansionLandingPage and ExpansionLandingPage:IsShown() then
           ExpansionLandingPage:Hide()
        end
        if actual ~= requested then
          ShowGarrisonLandingPage(requested);
          
       end
     end
    )
end
