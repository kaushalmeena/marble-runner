#!/bin/sh
# usage: _shot.sh <scene> <level> <wait> <out.png>   (GALLERY=1 for the gimmick gallery)
SCENE=$1 LEVEL=$2 WAIT=$3 OUT=$4 godot --path . --resolution 1152x648 res://_shot.tscn >/dev/null 2>&1 &
pid=$!
( sleep 25; kill $pid 2>/dev/null ) &
wait $pid 2>/dev/null
