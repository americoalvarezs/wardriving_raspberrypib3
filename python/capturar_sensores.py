import os
import sqlite3
import serial
import time
import subprocess
from datetime import datetime, timezone

# ==========================================
# CONFIGURACION
# ==========================================

BAUDIOS = 9600
CARPETA_DB = "/home/americo/db_sensores"
COMMIT_CADA = 60
REINTENTO_CONEXION = 3

os.makedirs(CARPETA_DB, exist_ok=True)

# ==========================================
# DETECCION PUERTO
# ==========================================

def detectar_puerto():
    try:
        resultado = subprocess.run(
            ["arduino-cli", "board", "list"],
            capture_output=True,
            text=True
        )

        for linea in resultado.stdout.splitlines():
            if "ttyACM" in linea or "ttyUSB" in linea:
                return linea.split()[0]

    except:
        pass

    return None

# ==========================================
# CONEXION SERIAL (SOLO HARDWARE REAL)
# ==========================================

def conectar_serial():
    for _ in range(REINTENTO_CONEXION):

        puerto = detectar_puerto()

        if puerto:
            try:
                ser = serial.Serial(
                    puerto,
                    BAUDIOS,
                    timeout=1,
                    write_timeout=1
                )

                time.sleep(2)
                ser.reset_input_buffer()

                print(f"[OK] Conectado a {puerto}")
                return ser, puerto

            except Exception as e:
                print("[WARN] Error conexión:", repr(e))

        print("Reintentando USB...")
        time.sleep(2)

    return None, None

# ==========================================
# DB
# ==========================================

def crear_db():
    fecha = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

    db_path = os.path.join(
        CARPETA_DB,
        f"sensores_{fecha}_UTC.db"
    )

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS mediciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        ldr TEXT,
        lm35 TEXT,
        dht_temp TEXT,
        dht_hum TEXT
    )
    """)

    conn.commit()

    return conn, cursor, db_path

# ==========================================
# PARSER DE FRAMES <...>
# ==========================================

def extraer_frames(buffer):
    frames = []

    while "<" in buffer and ">" in buffer:

        start = buffer.find("<")
        end = buffer.find(">")

        if start == -1 or end == -1:
            break

        if end < start:
            buffer = buffer[end+1:]
            continue

        frame = buffer[start+1:end]
        buffer = buffer[end+1:]

        frames.append((frame, buffer))

    return frames, buffer

# ==========================================
# MAIN
# ==========================================

ser, puerto = conectar_serial()

if not ser:
    print("ERROR: no se detecta Arduino")
    exit(1)

conn, cursor, db_path = crear_db()

print("\n=== LOGGER SERIAL ROBUSTO ===")
print("Puerto:", puerto)
print("DB:", db_path)
print("=============================\n")

buffer = ""
contador = 0
commit_counter = 0

# ==========================================
# LOOP PRINCIPAL
# ==========================================

try:
    while True:

        try:
            chunk = ser.read(ser.in_waiting or 1).decode("utf-8", errors="ignore")
            buffer += chunk

        except Exception as e:
            print("[WARN] read error:", repr(e))
            continue

        frames, buffer = extraer_frames(buffer)

        for frame, buffer in frames:

            campos = frame.split(",")

            if len(campos) != 4:
                continue

            ldr = campos[0]
            lm35 = campos[1]
            dht_temp = campos[2]
            dht_hum = campos[3]

            timestamp = datetime.now(timezone.utc).strftime(
                "%Y-%m-%d %H:%M:%S.%f"
            )[:-3] + "Z"

            cursor.execute("""
                INSERT INTO mediciones (
                    timestamp, ldr, lm35, dht_temp, dht_hum
                )
                VALUES (?, ?, ?, ?, ?)
            """, (timestamp, ldr, lm35, dht_temp, dht_hum))

            contador += 1
            commit_counter += 1

            if commit_counter >= COMMIT_CADA:
                conn.commit()
                commit_counter = 0

            print(f"[{contador}] {timestamp} | {frame}")

except KeyboardInterrupt:
    print("\nDeteniendo...")

finally:
    conn.commit()
    conn.close()
    ser.close()

    print("\nMuestras guardadas:", contador)
    print("Base cerrada")
    print("Puerto cerrado")