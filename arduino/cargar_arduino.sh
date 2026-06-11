#!/bin/bash

# ==========================================
# CONFIGURACION
# ==========================================

ARDUINO_DIR="$HOME/arduino"
FQBN="arduino:avr:uno"

clear

echo ""
echo "======================================"
echo " CARGADOR DE PROYECTOS ARDUINO"
echo "======================================"
echo ""

# ==========================================
# DETECTAR ARDUINO
# ==========================================

PUERTO=$(arduino-cli board list | awk '/ttyACM|ttyUSB/ {print $1; exit}')

if [ -z "$PUERTO" ]; then
    echo "[ERROR] No se detectó ningún Arduino."
    echo ""
    exit 1
fi

echo "Puerto detectado:"
echo "  $PUERTO"
echo ""

# ==========================================
# BUSCAR PROYECTOS
# ==========================================

PROYECTOS=()

for dir in "$ARDUINO_DIR"/*/; do
    [ -d "$dir" ] || continue

    nombre=$(basename "$dir")

    if [ -f "$dir/${nombre}.ino" ]; then
        PROYECTOS+=("$nombre")
    fi
done

if [ ${#PROYECTOS[@]} -eq 0 ]; then
    echo "[ERROR] No se encontraron proyectos."
    echo ""
    exit 1
fi

echo "======================================"
echo " PROYECTOS DISPONIBLES"
echo "======================================"
echo ""

for i in "${!PROYECTOS[@]}"; do
    printf "%2d) %s\n" "$((i+1))" "${PROYECTOS[$i]}"
done

echo ""
read -p "Seleccione proyecto: " OPCION

if ! [[ "$OPCION" =~ ^[0-9]+$ ]]; then
    echo ""
    echo "[ERROR] Opción inválida."
    exit 1
fi

INDICE=$((OPCION-1))

if [ "$INDICE" -lt 0 ] || [ "$INDICE" -ge "${#PROYECTOS[@]}" ]; then
    echo ""
    echo "[ERROR] Opción fuera de rango."
    exit 1
fi

PROYECTO="${PROYECTOS[$INDICE]}"
PROYECTO_DIR="$ARDUINO_DIR/$PROYECTO"
INO_FILE="$PROYECTO_DIR/$PROYECTO.ino"

echo ""
echo "======================================"
echo " PROYECTO SELECCIONADO"
echo "======================================"
echo ""
echo "$PROYECTO"
echo ""
echo "$INO_FILE"
echo ""

# ==========================================
# COMPILAR
# ==========================================

echo "======================================"
echo " COMPILANDO"
echo "======================================"
echo ""

arduino-cli compile \
    --fqbn "$FQBN" \
    "$PROYECTO_DIR"

if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Falló la compilación."
    exit 1
fi

echo ""
echo "[OK] Compilación correcta."
echo ""

# ==========================================
# SUBIR
# ==========================================

echo "======================================"
echo " SUBIENDO AL ARDUINO"
echo "======================================"
echo ""

arduino-cli upload \
    -p "$PUERTO" \
    --fqbn "$FQBN" \
    "$PROYECTO_DIR"

if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Falló la subida."
    exit 1
fi

echo ""
echo "======================================"
echo " SUBIDA COMPLETADA"
echo "======================================"
echo ""
echo "Proyecto : $PROYECTO"
echo "Puerto   : $PUERTO"
echo ""
