#!/bin/bash

SESSION="wardrive"
SCRIPT="$HOME/kismet_prog/kismet_up.sh"

echo "======================================"
echo " KISMET SCREEN LAUNCHER"
echo "======================================"

# Cerrar sesión previa si existe
if screen -list | grep -q "\.${SESSION}[[:space:]]"; then
    echo "[INFO] Cerrando sesión anterior..."

    screen -S "$SESSION" -X quit

    sleep 2
fi

# Crear nueva sesión detached
echo "[INFO] Creando nueva sesión..."

screen -dmS "$SESSION" bash -c "$SCRIPT"

sleep 2

# Verificar
if screen -list | grep -q "\.${SESSION}[[:space:]]"; then

    IP=$(hostname -I | awk '{print $1}')

    echo
    echo "[OK] Kismet iniciado"
    echo
    echo "Screen : $SESSION"
    echo "Web UI : http://$IP:2501"
    echo
    echo "Ver consola:"
    echo "screen -r $SESSION"
    echo

else

    echo "[ERROR] No se pudo iniciar la sesión"
    exit 1

fi

exit 0