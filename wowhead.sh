#!/bin/bash
cd $(dirname $0)
echo -e "local me,ns = ...\n" >wowhead.lua
../Helpers/GCAllRewards.php >>wowhead.lua
../Helpers/GCGearTokens.php >>wowhead.lua