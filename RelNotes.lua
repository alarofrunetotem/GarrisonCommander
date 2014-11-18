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
* base success chance
* list of follower that have the necessary counters for the mission, with their status (on mission, available etc)

== Future plans ==
# Showing information in an overlay on mission buttons to have all needed information for all missions at a glance
# Mission assign optimizer: I think I could also propone the best assignment to maximise your chances of success

]])
self:RelNotes(1,0,0,[[
Initial release
]])
end

