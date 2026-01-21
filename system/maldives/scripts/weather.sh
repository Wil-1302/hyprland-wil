#!/bin/bash
API_KEY="TU_API_KEY_AQUI"
CITY="Lima"
COUNTRY="PE"

DATA=$(curl -s "https://api.openweathermap.org/data/2.5/weather?q=${CITY},${COUNTRY}&appid=${API_KEY}&units=metric&lang=es")

TEMP=$(echo $DATA | jq -r '.main.temp' | cut -d. -f1)
DESC=$(echo $DATA | jq -r '.weather[0].description')
ICON_CODE=$(echo $DATA | jq -r '.weather[0].icon')

# Mapear código de icono a emoji
case ${ICON_CODE:0:2} in
    01) ICON="☀" ;;
    02) ICON="⛅" ;;
    03) ICON="☁" ;;
    04) ICON="☁" ;;
    09) ICON="🌧" ;;
    10) ICON="🌦" ;;
    11) ICON="⛈" ;;
    13) ICON="❄" ;;
    50) ICON="🌫" ;;
    *) ICON="☁" ;;
esac

echo "${TEMP}°C|${DESC}|${ICON}"
