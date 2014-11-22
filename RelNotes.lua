local me,ns=...
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local hlp=LibStub("AceAddon-3.0"):GetAddon(me)
function hlp:loadHelp()
self:HF_Title(me,"RELNOTES")
self:HF_Paragraph("Description")
self:Wiki([[
= GarrisonCommander helps you when choosing the right follower for the right mission =

== Description ==
GarrisonCommander adds to mission tooltips the following informations:
* makes mission panel movable (position NOT yet saved between sessions)
* base success chance (does NOT account for followers)
* list of follower that have the necessary counters for the mission, with their status (on mission, available etc)
* both traits (silver lines) and abilities(blue lines) are shown
* every follower line has now the icon for countered trait/ability
* time left shown for In mission follower
* possible party and success chance with that party

== Future plans ==
# Showing information in an overlay on mission buttons to have all needed information for all missions at a glance
]])
self:RelNotes(1,0,2,[[
Feature: Level added to follower line
Feature: All counterd traits listed on the same line
Feature: For "In mission" follower time letf is shown instead of "In mission"
Feature: Trait related lines are now silver, while abilities related are Blue
Feature: Mission panel can now optionally be relocked
Feature: You can select to ignore "busy" followers
Feature: possible party and success chance with that party
]])
self:RelNotes(1,0,1,[[
Fixed: Follower info refresh should be now more reliable
Feature: Mission panel is now movable
Feature: Shows also countered traits( i.e. environmente/racial bonuses)
Feature: Shows icon for trait or ability countered. Abilities are blue lines, traits orange lines
]])
self:RelNotes(1,0,0,[[
Initial release
]])
end

