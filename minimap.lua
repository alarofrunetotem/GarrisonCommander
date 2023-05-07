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
  print(UnitLevel('player'))
  GameTooltip:AddLine(key .. " " .. message)
end
if (me ==  gc and  not IsAddOnLoaded(gb) or
    me ==  gb and  not IsAddOnLoaded(gc)
) then

     ExpansionLandingPageMinimapButton:HookScript("OnEnter",
     function(this)
      local d=this.description
        print("GCB",d)
        print(garrison,orderhall,champion,sanctum)
        if GarrisonLandingPage then
          addTooltip(d,CTRL_KEY_TEXT,garrison)
          addTooltip(d,SHIFT_KEY_TEXT,orderhall)
          addTooltip(d,CTRL_KEY_TEXT .. '-' .. SHIFT_KEY_TEXT,champion)
          if C_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer(LE_EXPANSION_DRAGONFLIGHT) then addTooltip(d,CTRL_KEY_TEXT .. '-' .. ALT_KEY_TEXT,sanctum) end
        end
        GameTooltip:Show()
    end
    )
    ExpansionLandingPageMinimapButton:HookScript("OnClick",
      function (this,button)
        if GarrisonLandingPage then
         local shown=GarrisonLandingPage:IsShown()
         local actual=GarrisonLandingPage.garrTypeID
         local requested=C_Garrison.GetLandingPageGarrisonType()
         local original=requested
         local shift,ctrl,alt=IsShiftKeyDown(),IsControlKeyDown(),IsAltKeyDown()
         print("KEYS",
         shift and "shift" or "",
         ctrl and "ctrl" or "",
         alt and "alt" or ""
         )
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
         end
         if InCombatLockdown() then return end
         print("Check",descriptions[requested],'vs',descriptions[actual])
         if shown and actual ~= requested and requested <= actual then
           print("Show ",descriptions[requested],'vs',descriptions[actual])
            ShowGarrisonLandingPage(requested);
         end
       end
      end
    )
end
