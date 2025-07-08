#!/bin/bash
# Microphone toggle script with notifications
# Toggles the default source microphone and shows notification

pamixer --default-source -t

if pamixer --get-mute --default-source | grep -q true; then
    dunstify -a "Microphone" -h string:x-dunst-stack-tag:mic "🎙️ Muted" -t 2000
else
    VOLUME=$(pamixer --default-source --get-volume)
    dunstify -a "Microphone" -h string:x-dunst-stack-tag:mic "🎙️ Unmuted ($VOLUME%)" -t 2000
fi

pkill -RTMIN+8 waybar 2>/dev/null || true