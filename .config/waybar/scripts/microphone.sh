#!/bin/bash
if ! command -v pamixer &> /dev/null; then
    echo '{"text": "󰍭", "class": "error", "tooltip": "pamixer not found"}'
    exit 1
fi

get_mic_status() {
    local retries=3
    local delay=0.1
    
    for ((i=1; i<=retries; i++)); do
        if IS_MUTED=$(pamixer --default-source --get-mute 2>/dev/null); then
            VOLUME=$(pamixer --default-source --get-volume 2>/dev/null || echo "0")
            
            if [ "$IS_MUTED" = "true" ]; then
                echo '{"text": "󰍭", "class": "muted", "tooltip": "Microphone: Muted"}'
            else
                echo '{"text": "󰍬", "class": "active", "tooltip": "Microphone: '"$VOLUME"'%"}'
            fi
            return 0
        fi
        sleep $delay
    done
    
    echo '{"text": "󰍭", "class": "error", "tooltip": "Microphone: Error"}'
    return 1
}

get_mic_status
