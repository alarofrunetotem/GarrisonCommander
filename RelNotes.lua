local me,ns=...
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local hlp=LibStub("AceAddon-3.0"):GetAddon(me)
function hlp:loadHelp()
self:HF_Title(me,"RELNOTES")
self:HF_Paragraph("Description")
self:HF_Pre([[
= GarrisonCommander helps you when choosing the right follower for the right mission =
== Description ==
GarrisonCommander adds to mission tooltips the following informations:
* makes mission panel movable (position NOT yet saved between sessions)
* base success chance (does NOT account for followers)
* list of follower that have the necessary counters for the mission, with their status (on mission, available etc)
* both traits (orange lines) and abilities(blue lines) are shown
* every follower line has now the icon for countered trait/ability

== Future plans ==
# Showing information in an overlay on mission buttons to have all needed information for all missions at a glance
# Mission assign optimizer: I think I could also propone the best assignment to maximise your chances of success

]])
self:RelNotes(1,0,2,[[
Fixed: Follower info refresh should be now more reliable
Feature: Mission panel is now movable
Feature: Shows also countered traits( i.e. environmente/racial bonuses)
Feature: Shows icon for trait or ability countered. Abilities are blue lines, traits orange lines
]])
self:RelNotes(1,0,0,[[
Initial release
]])
end

