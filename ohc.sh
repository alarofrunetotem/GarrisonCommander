#!/bin/bash
cd $(dirname $0) or exit
release=2366679
rm -rf OrderHallCommander
rm -f download
echo Processing release $release
wget https://wow.curseforge.com/projects/orderhallcommander/files/$release/download 
unzip download
rm -f download

