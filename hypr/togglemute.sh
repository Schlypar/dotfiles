#!/bin/bash

# Toggle microphone mute using default source
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Optional: Show notification
if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q "MUTED"; then
    notify-send "Microphone Muted" -i audio-microphone-muted-symbolic
else
    notify-send "Microphone Unmuted" -i audio-microphone-sensitivity-high-symbolic
fi
