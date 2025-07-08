#!/bin/bash

# Screenshot script for Hyprland
# Usage: screenshot.sh [area|fullscreen|monitor] [annotate]

# Create screenshots directory if it doesn't exist
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Generate timestamp for filename
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Check if annotation is requested
ANNOTATE="$2"

case "$1" in
"area")
	# Partial screenshot - select area once, copy to clipboard and save
	TEMP_FILE=$(mktemp --suffix=.png)
	grim -g "$(slurp)" "$TEMP_FILE"
	if [ $? -eq 0 ]; then
		# Copy to clipboard
		wl-copy <"$TEMP_FILE"

		if [ "$ANNOTATE" = "annotate" ]; then
			# Open in swappy for annotation
			swappy -f "$TEMP_FILE" -o "$SCREENSHOT_DIR/screenshot_area_$TIMESTAMP.png"
			notify-send "Screenshot" "Annotated screenshot saved to ~/Pictures/Screenshots/"
		else
			# Save to screenshots folder
			cp "$TEMP_FILE" "$SCREENSHOT_DIR/screenshot_area_$TIMESTAMP.png"
			notify-send "Screenshot" "Area screenshot saved to ~/Pictures/Screenshots/"
		fi

		# Clean up temp file
		rm "$TEMP_FILE"
	fi
	;;
"fullscreen")
	# First monitor screenshot - copy to clipboard and save
	MONITOR_NAME=$(hyprctl monitors -j | jq -r ".[0].name")
	TEMP_FILE=$(mktemp --suffix=.png)
	grim -o "$MONITOR_NAME" "$TEMP_FILE"
	if [ $? -eq 0 ]; then
		# Copy to clipboard
		wl-copy <"$TEMP_FILE"

		if [ "$ANNOTATE" = "annotate" ]; then
			# Open in swappy for annotation
			swappy -f "$TEMP_FILE" -o "$SCREENSHOT_DIR/screenshot_fullscreen_$TIMESTAMP.png"
			notify-send "Screenshot" "Annotated screenshot saved to ~/Pictures/Screenshots/"
		else
			# Save to screenshots folder
			cp "$TEMP_FILE" "$SCREENSHOT_DIR/screenshot_fullscreen_$TIMESTAMP.png"
			notify-send "Screenshot" "Fullscreen screenshot saved to ~/Pictures/Screenshots/"
		fi

		# Clean up temp file
		rm "$TEMP_FILE"
	fi
	;;
"monitor")
	# Active monitor screenshot - copy to clipboard and save
	ACTIVE_MONITOR=$(hyprctl activeworkspace -j | jq -r ".monitor")
	TEMP_FILE=$(mktemp --suffix=.png)
	grim -o "$ACTIVE_MONITOR" "$TEMP_FILE"
	if [ $? -eq 0 ]; then
		# Copy to clipboard
		wl-copy <"$TEMP_FILE"

		if [ "$ANNOTATE" = "annotate" ]; then
			# Open in swappy for annotation
			swappy -f "$TEMP_FILE" -o "$SCREENSHOT_DIR/screenshot_monitor_$TIMESTAMP.png"
			notify-send "Screenshot" "Annotated screenshot saved to ~/Pictures/Screenshots/"
		else
			# Save to screenshots folder
			cp "$TEMP_FILE" "$SCREENSHOT_DIR/screenshot_monitor_$TIMESTAMP.png"
			notify-send "Screenshot" "Monitor screenshot saved to ~/Pictures/Screenshots/"
		fi

		# Clean up temp file
		rm "$TEMP_FILE"
	fi
	;;
*)
	echo "Usage: $0 [area|fullscreen|monitor] [annotate]"
	exit 1
	;;
esac