#!/bin/bash

# ==================================================
# KISMET WARDRIVING STARTER - ROBUST EDITION
# Raspberry Pi 3B+ / 64-bit / RTL8812AU + VK162
# ==================================================

GPS_DEV="/dev/ttyACM1"
GPS_SOCKET="/var/run/gpsd.sock"

LOG_TAG="[KISMET-UP]"

echo "======================================"
echo "$LOG_TAG STARTING SYSTEM"
echo "======================================"

# ==================================================
# DETECT WIFI INTERFACE AUTOMATICALLY
# ==================================================

IFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)

if [ -z "$IFACE" ]; then
    echo "$LOG_TAG ERROR: No WiFi interface found"
    exit 1
fi

echo "$LOG_TAG WiFi interface: $IFACE"

# ==================================================
# 1. MONITOR MODE
# ==================================================

echo "$LOG_TAG [1/3] Setting monitor mode..."

sudo systemctl stop wpa_supplicant 2>/dev/null
sudo killall wpa_supplicant 2>/dev/null

# desbloquear RF KILL
sudo rfkill unblock all
sleep 2

sudo ip link set $IFACE down || exit 1
sudo iw dev $IFACE set type monitor || exit 1
sudo ip link set $IFACE up || exit 1

MODE=$(iw dev $IFACE info | grep type | awk '{print $2}')

if [ "$MODE" != "monitor" ]; then
    echo "$LOG_TAG ERROR: monitor mode failed"
    exit 1
fi

echo "$LOG_TAG monitor mode OK"

# ==================================================
# 2. GPS START
# ==================================================

echo "$LOG_TAG [2/3] Starting GPS..."

sudo systemctl stop gpsd.socket 2>/dev/null
sudo systemctl stop gpsd 2>/dev/null
sudo killall gpsd 2>/dev/null

sudo rm -f $GPS_SOCKET

if [ ! -e "$GPS_DEV" ]; then
    echo "$LOG_TAG ERROR: GPS device not found ($GPS_DEV)"
    exit 1
fi

sudo gpsd -n $GPS_DEV -F $GPS_SOCKET
sleep 2

if ! nc -z localhost 2947; then
    echo "$LOG_TAG ERROR: gpsd not responding"
    exit 1
fi

echo "$LOG_TAG gpsd OK"

# GPS FIX CHECK
GPS_OK=0

for i in {1..10}; do
    if gpspipe -w -n 3 2>/dev/null | grep -q "lat"; then
        GPS_OK=1
        break
    fi
    echo "$LOG_TAG waiting GPS fix... ($i/10)"
    sleep 2
done

if [ $GPS_OK -eq 1 ]; then
    echo "$LOG_TAG GPS FIX ACQUIRED"
else
    echo "$LOG_TAG WARNING: no GPS fix yet"
fi

# ==================================================
# 3. START KISMET
# ==================================================

IP_ADDR=$(hostname -I | awk '{print $1}')

echo "$LOG_TAG [3/3] Launching Kismet..."

echo "--------------------------------------"
echo "Web UI:"
echo "http://$IP_ADDR:2501"
echo "--------------------------------------"

sleep 2

exec sudo kismet
