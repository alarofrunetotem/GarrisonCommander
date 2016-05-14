#!/bin/bash
cd $(dirname $0)
echo -e "local me,ns = ...\n" >wowhead.lua
../wowhelpers/GCAllRewards.php >>wowhead.lua
#../wowhelpers/GCGearTokens.php >>wowhead.lua