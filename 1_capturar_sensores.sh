#!/bin/bash

SESSION="sensores"
PYTHON_SCRIPT="/home/americo/python/capturar_sensores.py"

echo "======================================"
echo " SENSOR SCREEN LAUNCHER"
echo "======================================"

# Cerrar sesión anterior si existe
if screen -list | grep -q "\.${SESSION}[[:space:]]"; then
    echo "[INFO] Cerrando sesión anterior..."
    screen -S "$SESSION" -X quit
    sleep 2
fi

# Verificar que exista el script
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "[ERROR] No existe:"
    echo "        $PYTHON_SCRIPT"
    exit 1
fi

echo "[INFO] Creando nueva sesión..."

# Crear nueva sesión screen
screen -dmS "$SESSION"

# Ejecutar programa Python dentro de screen
screen -S "$SESSION" -X stuff "python3 $PYTHON_SCRIPT$(printf '\r')"

# Esperar unos segundos para verificar que arrancó
sleep 3

echo
echo "[OK] Captura de sensores iniciada"
echo
echo "Screen : $SESSION"
echo "Script : $PYTHON_SCRIPT"
echo
echo "Ver consola:"
echo "screen -r $SESSION"
echo