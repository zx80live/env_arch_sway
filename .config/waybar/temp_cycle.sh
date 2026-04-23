#!/bin/bash

STATE_FILE="/tmp/wlsunset_state"
LABEL_FILE="/tmp/wlsunset_label"

# Читаем текущее состояние
CURRENT=$(cat $STATE_FILE 2>/dev/null || echo "5000")

if [ "$CURRENT" == "5000" ]; then
    NEXT_TEMP=4500
    LABEL="🌙 4500K"
elif [ "$CURRENT" == "4500" ]; then
    NEXT_TEMP=6500
    LABEL="☀️ 6500K"
else
    NEXT_TEMP=5000
    LABEL="🖥️ 5000K"
fi

# Применяем
pkill wlsunset
if [ "$NEXT_TEMP" != "6500" ]; then
    wlsunset -t $NEXT_TEMP -T $((NEXT_TEMP+1)) &
fi

# Сохраняем для Waybar
echo $NEXT_TEMP > $STATE_FILE
echo "$LABEL" > $LABEL_FILE

