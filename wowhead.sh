#!/bin/bash
cd $(dirname $0)
echo -e "local me,ns = ...\n" >wowhead.lua
date +"ns.wowhead_update=%s" >>wowhead.lua
../wowhelpers/GCAllRewards.php >>wowhead.lua
../wowhelpers/GCSalvage.php >>wowhead.lua