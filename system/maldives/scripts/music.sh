#!/bin/bash
# Obtener info de música con playerctl
STATUS=$(playerctl status 2>/dev/null)

if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
    TITLE=$(playerctl metadata title 2>/dev/null | head -c 40)
    ARTIST=$(playerctl metadata artist 2>/dev/null | head -c 30)
    echo "${STATUS}|${TITLE}|${ARTIST}"
else
    echo "Stopped||"
fi
