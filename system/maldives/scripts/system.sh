#!/bin/bash
# CPU usage
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d. -f1)

# RAM usage
RAM=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')

# Uptime
UPTIME=$(uptime -p | sed 's/up //')

echo "${CPU}|${RAM}|${UPTIME}"
