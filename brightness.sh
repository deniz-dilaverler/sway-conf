#!/bin/sh

output=$(swaymsg -t get_outputs -r 2>/dev/null |
    jq -r '.[] | select(.focused) | .name' |
    head -n 1)

case "$output" in
    HDMI-A-1) display=1 ;;
    DP-3) display=2 ;;
    *) exit 0 ;;
esac

case "$1" in
    up)
        exec ddcutil --display "$display" setvcp 10 + 5
        ;;
    down)
        exec ddcutil --display "$display" setvcp 10 - 5
        ;;
    status)
        values=$(ddcutil --display "$display" getvcp 10 2>/dev/null |
            sed -n 's/.*current value = *\([0-9][0-9]*\), max value = *\([0-9][0-9]*\).*/\1 \2/p')
        set -- $values
        if [ -n "$1" ] && [ -n "$2" ] && [ "$2" -gt 0 ]; then
            awk -v current="$1" -v maximum="$2" 'BEGIN { printf "BRT %d%%", 100 * current / maximum }'
        fi
        ;;
esac
