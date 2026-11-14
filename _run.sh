#!/bin/sh
# usage: _run.sh <level> "<waypoints>" [verbose] [every-n-frames]
LEVEL=$1 WAY="$2" V=$3 N=${4:-20} godot --headless --path . res://_bot.tscn 2>&1 | grep -E "leg|OK|FAIL|END"
