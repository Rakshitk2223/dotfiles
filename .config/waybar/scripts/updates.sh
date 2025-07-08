#!/bin/bash

# Check for Arch package updates
arch_updates=$(checkupdates 2>/dev/null | wc -l)

# Check for AUR package updates (using yay)
aur_updates=$(yay -Qua 2>/dev/null | wc -l)

# Total updates
total_updates=$((arch_updates + aur_updates))

# Create tooltip text
if [ $total_updates -eq 0 ]; then
    tooltip="System is up to date"
    text="0"
else
    tooltip="Arch: $arch_updates updates\nAUR: $aur_updates updates\nTotal: $total_updates updates"
    text="$total_updates"
fi

# Output JSON for Waybar
echo "{\"text\":\"$text\",\"tooltip\":\"$tooltip\",\"class\":\"updates\"}"