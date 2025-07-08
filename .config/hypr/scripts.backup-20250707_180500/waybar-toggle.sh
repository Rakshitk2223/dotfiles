#!/usr/bin/env sh

# Check if a Waybar process is running
if pgrep -x waybar >/dev/null; then
	# If it is, kill it
	pkill -x waybar
else
	# If it's not, start a new instance of Waybar
	# This will automatically use the latest config
	waybar &
fi
