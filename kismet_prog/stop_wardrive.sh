#!/bin/bash

SESSION="wardrive"

echo "======================================"
echo " KISMET STOPPER"
echo "======================================"

if ! screen -list | grep -q "\.${SESSION}[[:space:]]"; then
    echo "[INFO] No existe la sesión '$SESSION'"
    exit 0
fi

echo "[INFO] Enviando CTRL+C a Kismet..."
screen -S "$SESSION" -X stuff $'\003'

echo "[INFO] Esperando cierre limpio..."
sleep 5

echo "[INFO] Cerrando sesión Screen..."
screen -S "$SESSION" -X stuff "exit\n"

sleep 2

echo
echo "Sesiones activas:"
screen -ls