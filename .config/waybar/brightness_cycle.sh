#!/bin/bash
BRIGHT_STATE="/tmp/lg_brightness"
LABEL_FILE="/tmp/lg_brightness_label"

# Читаем текущее состояние, по дефолту 50
CURRENT=$(cat $BRIGHT_STATE 2>/dev/null || echo "50")

if [ "$CURRENT" == "50" ]; then
    NEXT=80
    LABEL="   80%"
elif [ "$CURRENT" == "80" ]; then
    NEXT=100
    LABEL="   100%"
elif [ "$CURRENT" == "100" ]; then
    NEXT=30
    LABEL="   30%"
else
    NEXT=50
    LABEL="   50%"
fi

# Применяем яркость к LG на шину 13
ddcutil --bus 13 setvcp 10 $NEXT --sleep-multiplier .1 > /dev/null &

# Сохраняем состояние
echo $NEXT > $BRIGHT_STATE
echo "$LABEL" > $LABEL_FILE

