#!/bin/bash
# Detectar batería
BATTERY=$(acpi -b 2>/dev/null | head -1)

if [ -z "$BATTERY" ]; then
    echo "AC|100|⚡"
    exit 0
fi

PERCENT=$(echo $BATTERY | grep -oP '\d+(?=%)')
STATUS=$(echo $BATTERY | grep -oP '(Charging|Discharging|Full)')

# Elegir icono según porcentaje
if [ "$STATUS" = "Charging" ]; then
    ICON="🔌"
elif [ $PERCENT -gt 80 ]; then
    ICON="🔋"
elif [ $PERCENT -gt 50 ]; then
    ICON="🔋"
elif [ $PERCENT -gt 20 ]; then
    ICON="🪫"
else
    ICON="🪫"
fi

echo "${STATUS}|${PERCENT}|${ICON}"
