#!/bin/bash

WARDRIVE_SESSION="wardrive"
SENSORES_SESSION="sensores"

echo "======================================"
echo " DETENIENDO SERVICIOS"
echo "======================================"

# ==================================================
# DETENER KISMET
# ==================================================

if screen -list | grep -q "\.${WARDRIVE_SESSION}[[:space:]]"; then

    echo
    echo "[INFO] Deteniendo Kismet..."

    screen -S "$WARDRIVE_SESSION" -X stuff $'\003'

    sleep 5

    screen -S "$WARDRIVE_SESSION" -X quit

    echo "[OK] Sesión wardrive cerrada"

else

    echo
    echo "[INFO] No existe sesión wardrive"

fi

# ==================================================
# DETENER CAPTURA DE SENSORES
# ==================================================

if screen -list | grep -q "\.${SENSORES_SESSION}[[:space:]]"; then

    echo
    echo "[INFO] Deteniendo captura de sensores..."

    screen -S "$SENSORES_SESSION" -X stuff $'\003'

    sleep 5

    screen -S "$SENSORES_SESSION" -X quit

    echo "[OK] Sesión sensores cerrada"

else

    echo
    echo "[INFO] No existe sesión sensores"

fi

# ==================================================
# VERIFICACIÓN FINAL
# ==================================================

echo
echo "======================================"
echo " SESIONES SCREEN ACTIVAS"
echo "======================================"

screen -ls

echo
echo "[OK] Proceso finalizado"