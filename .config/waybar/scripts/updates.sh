#!/bin/bash
# Check for updates - outputs icon only if updates available, otherwise empty

# Check for Arch package updates
arch_updates=$(checkupdates 2>/dev/null | wc -l)

# Check for AUR package updates (using yay)
aur_updates=$(yay -Qua 2>/dev/null | wc -l)

# Total updates
total_updates=$((arch_updates + aur_updates))

# Only output if there are updates (empty output hides the module)
if [ $total_updates -gt 0 ]; then
	echo ""
fi
