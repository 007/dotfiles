#!/bin/sh

EXTERNAL_MONITOR=$(xrandr | grep -Eo '^.{3,5} connected ' | cut -d\  -f1 | grep -v '^eDP1$' | head -1)
BEST_RESOLUTION=$(xrandr | grep -A4 "^${EXTERNAL_MONITOR} " | grep -v connected | awk '{print $1}' | grep -E '(2560x1440|1920x1080)' | head -1)

/usr/bin/xrandr --output eDP1 --auto --output ${EXTERNAL_MONITOR} --primary --mode ${BEST_RESOLUTION} --above eDP1
