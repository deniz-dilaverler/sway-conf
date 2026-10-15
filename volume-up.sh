#!/bin/sh

volume=$(pactl get-sink-volume @DEFAULT_SINK@ |
    awk -F/ 'NR == 1 { gsub(/[^0-9]/, "", $2); print $2; exit }')

if [ -n "$volume" ] && [ "$volume" -lt 100 ]; then
    target=$((volume + 5))
    [ "$target" -gt 100 ] && target=100
    pactl set-sink-volume @DEFAULT_SINK@ "$target%"
fi
