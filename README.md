# PARTE 1: Wardriving con "Raspberry Pi 3 B+" + "Kismet" + "GPS VK-162"

Implementación de una plataforma portátil de **Wardriving** utilizando **Raspberry Pi 3 B+**, una antena **Wi-Fi en modo monitor** y un receptor **GPS USB VK-162**, con captura automática mediante **Kismet**.

---

# Arquitectura del Proyecto

```text
Raspberry Pi 3 B+
      │
      ├── USB WiFi RTL8812AU (Monitor)
      │          │
      │          └── Captura → Kismet
      │
      └── USB GPS VK-162
                 │
                 └── GPS → gpsd → Kismet
```

---

# Material Utilizado

| Componente   | Modelo                            |
| ------------ | --------------------------------- |
| Raspberry Pi | Raspberry Pi 3 B+                 |
| Antena WiFi  | TP-Link Archer T4UHP (US) Ver 1.0 |
| Chipset WiFi | RTL8812AU                         |
| GPS          | VK-162                            |
| Chip GPS     | u-blox 7                          |
| Protocolo    | NMEA 0183                         |

<p align="center">
<img src="imagenes/raspberry pi b3.PNG" width="600"><br>
<img src="imagenes/raspberry pi b3 up.PNG" width="600"><br>
<img src="imagenes/tp link antena v1.PNG" width="600"><br>
<img src="imagenes/Archer_T4UHP.jpg" width="600">
<img src="imagenes/vk162_usb_gps_1.jpg" width="600">
<img src="imagenes/vk162_usb_gps_2.jpg" width="600">
</p>

---

# Software Utilizado

* Raspberry Pi OS Lite (64 bits)
* Debian Trixie
* Kismet
* gpsd
* aircrack-ng

---

# Preparación del Sistema Operativo

Instalar Raspberry Pi OS Lite para optimizar memoria.

<p align="center">
<img src="imagenes/01 instalar_raspbian.gif" width="700">
</p>

Ingresar por SSH (recomendado mediante Ethernet).

<p align="center">
<img src="imagenes/02 Coneccion por ssh a raspberry.PNG" width="700">
</p>

Verificar arquitectura:

```bash
uname -m
uname -r
```

Salida esperada:

```text
aarch64
6.12.75+rpt-rpi-v8
```

---

# Instalación del Driver RTL8812AU

Instalar dependencias:

```bash
sudo apt update

sudo apt install -y \
build-essential \
dkms \
git \
libelf-dev \
bc \
aircrack-ng

sudo apt install -y linux-headers-rpi-v8
```

Clonar e instalar:

```bash
cd /usr/src

sudo git clone -b v5.6.4.2 \
https://github.com/aircrack-ng/rtl8812au.git

cd rtl8812au

sudo make
sudo make install

sudo depmod -a

sudo reboot
```

---

# Configuración del Modo Monitor

Detectar interfaz:

```bash
sudo airmon-ng
```

<p align="center">
<img src="imagenes/03 interfaz modo monitor.PNG" width="700">
</p>

Ejemplo: `wlan1`

Activar modo monitor:

```bash
sudo systemctl stop wpa_supplicant 2>/dev/null
sudo killall wpa_supplicant 2>/dev/null

sudo rfkill unblock all

sudo ip link set wlan1 down
sudo iw dev wlan1 set type monitor
sudo ip link set wlan1 up

iw dev
```

Validar captura:

```bash
sudo airodump-ng wlan1
```

> CTRL + C para detener.

Volver a modo normal:

```bash
sudo ip link set wlan1 down
sudo iw dev wlan1 set type managed
sudo ip link set wlan1 up

sudo systemctl start wpa_supplicant
```

---

# Configuración del GPS VK-162

Detectar dispositivo:

```bash
for dev in /dev/ttyACM*; do
echo "===== $dev ====="
udevadm info -q property -n $dev \
| grep -E "ID_VENDOR=|ID_MODEL="
done
```

Ejemplo:

```text
/dev/ttyACM0 → Arduino
/dev/ttyACM1 → VK-162
```

Instalar GPSD:

```bash
sudo apt update

sudo apt install -y gpsd gpsd-clients
```

Probar:

```bash
sudo systemctl stop gpsd.socket

sudo gpsd /dev/ttyACM1 \
-F /var/run/gpsd.sock

cgps -s
```

Editar:

```bash
sudo nano /etc/default/gpsd
```

```ini
START_DAEMON="true"
DEVICES="/dev/ttyACM1"
GPSD_OPTIONS="-n"
USBAUTO="false"
```

Levantar GPS:

```bash
sudo killall gpsd 2>/dev/null

sudo systemctl stop gpsd
sudo systemctl stop gpsd.socket

sudo rm -f /var/run/gpsd.sock

sudo gpsd \
/dev/ttyACM1 \
-F /var/run/gpsd.sock

sleep 2

cgps -s
```

---

# Instalación de Kismet

```bash
sudo mkdir -p /etc/apt/keyrings

wget -O /tmp/kismet.key \
https://www.kismetwireless.net/repos/kismet-release.gpg.key

sudo gpg --dearmor \
-o /etc/apt/keyrings/kismet.gpg \
/tmp/kismet.key

echo \
"deb [signed-by=/etc/apt/keyrings/kismet.gpg] https://www.kismetwireless.net/repos/apt/release/trixie trixie main" \
| sudo tee \
/etc/apt/sources.list.d/kismet.list

sudo apt update

sudo apt install -y kismet
```

Verificar:

```bash
kismet -v
```

Editar:

```bash
sudo nano /etc/kismet/kismet.conf
```

Modificar:

```ini
source=wlan1:type=linuxwifi
gps=gpsd:host=localhost,port=2947
```

Editar:

```bash
sudo nano /etc/kismet/kismet_logging.conf
```

Modificar:

```ini
log_prefix=/home/americo/db_sensores/
```

Esto define dónde se almacenarán los archivos `.kismet`.

---

# 🤖 Scripts Automatizados

## Opción 1 — Primer Plano

Ejecutar:

```bash
kismet_up.sh
```

Archivo:

```text
kismet_prog/kismet_up.sh
```

---

## Opción 2 — Segundo Plano (Recomendado)

Instalar Screen:

```bash
sudo apt update
sudo apt install -y screen
```

Verificar:

```bash
screen --version
```

Ejecutar:

```bash
./2_start_wardrive.sh
```

Flujo:

```text
screen -S wardrive
↓
ejecuta kismet_up.sh
↓
inicia gpsd
↓
pone wlan1 monitor
↓
inicia Kismet
↓
devuelve SSH
```

guardabndo los arcfhivos *.kismet en db_sensores/  de manera automatica ordenando la generacion de la base de datos kismet

---

# PARTE 2: Sistema de Captura de Sensores  
## Arduino + Training Shield V2 + Raspberry Pi 3 B+

Este subsistema implementa una plataforma portátil de adquisición de datos físicos utilizando:

- Arduino Uno como unidad de adquisición
- Arduino Training Shield V2 como plataforma de sensores
- Raspberry Pi 3 B+ como sistema central de procesamiento y almacenamiento

El sistema permite la captura, transmisión y almacenamiento de datos en una base de datos SQLite de forma continua y automatizada.

---

# Arquitectura del Sistema de Sensores

```text
Sensores (Training Shield V2)
        │
        ├── LM35 (Temperatura analógica)
        ├── LDR (Luminosidad - A1)
        ├── DHT11 (Temperatura/Humedad - D4)
        └── IR 38 kHz (D6)
        │
        ▼
Arduino Uno (Concentrador de datos)
        │ USB Serial
        ▼
Raspberry Pi 3 B+
        │
        ├── capturar_sensores.py (Python)
        ▼
SQLite (db_sensores/)
Material Utilizado
Componente	Modelo
Raspberry Pi	Raspberry Pi 3 B+
Microcontrolador	Arduino Uno
Sensores	Arduino Training Shield V2
Comunicación	USB Serial (RS232)
Software Utilizado
Raspberry Pi OS Lite (64-bit)
Debian Trixie
Python 3
SQLite
Arduino CLI
Preparación del Sistema (Arduino CLI)
Actualización del sistema
sudo apt update
sudo apt full-upgrade -y
Instalación de dependencias
sudo apt install -y curl git unzip
Instalación Arduino CLI
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
sudo mv bin/arduino-cli /usr/local/bin/
Verificación
arduino-cli version
arduino-cli config init
Instalación de placas
arduino-cli core update-index
arduino-cli core install arduino:avr
arduino-cli core list
Conexión de Arduino
arduino-cli board list
ls /dev/tty*
Python y dependencias
sudo apt install -y python3-pip python3-serial
python3 -c "import serial; print(serial.__version__)"
Programación del Arduino desde Raspberry Pi

Estructura del proyecto:

/home/americo/arduino/
│
├── sensores/
│   └── sensores.ino
│
└── cargar_arduino.sh

El script cargar_arduino.sh:

Detecta automáticamente carpetas de proyectos
Compila archivos .ino
Carga el firmware al Arduino UNO
Permite escalabilidad por módulos de sensores
Comunicación Arduino → Raspberry Pi

El Arduino actúa como concentrador de sensores y envía datos por USB Serial.

Conexiones
LDR
VCC → 5V
GND → Resistencia 10kΩ → GND
Señal → A1
LM35
VCC → 5V
Vout → A2
GND → GND
DHT11
VCC → 5V
DATA → D4
GND → GND
Flujo del sistema
Arduino UNO
   ↓
USB Serial
   ↓
Python (Raspberry Pi)
   ↓
SQLite Database
Filosofía del sistema

El sistema sigue un enfoque hardware-driven:

Arduino controla la adquisición de datos
Raspberry Pi actúa como sistema de almacenamiento
Python funciona como logger pasivo

El Arduino envía datos únicamente cuando el usuario lo activa mediante botones físicos.

Protocolo de comunicación (Frames)
Frame de datos
<0,13.20,12.70,14.00>
Eventos
<EVENT,START>
<EVENT,STOP>

Características:

Flujo determinístico
Resistente a ruido serial
Escalable a más sensores
Sin dependencia crítica de Python para el control
Sistema Python de captura

Ubicación:

/home/americo/python/capturar_sensores.py

Funciones:

Crea base de datos SQLite automáticamente
Recibe datos del Arduino por serial
Agrega timestamp a cada registro
Almacena datos en db_sensores/
Diseño del parser

El sistema no utiliza readline().

En su lugar utiliza un buffer continuo:

buffer += chunk

Ventajas:

Evita desincronización
Tolera ruido serial
Maneja datos incompletos
Mantiene flujo continuo de datos
Datos válidos

Solo se procesan frames completos:

<0,13.20,12.70,14.00>
Base de datos SQLite

Ubicación:

db_sensores/

Formato de archivos:

sensores_YYYYMMDD_HHMMSS.db
Ejecución automatizada
Script principal
1_capturar_sensores.sh

Función:

Abre sesión screen llamada sensores
Ejecuta capturar_sensores.py
Mantiene ejecución 24/7
Registra datos automáticamente
Sincronización temporal (CRÍTICO)

Todo el sistema utiliza UTC (Zulu Time).

Razones:

GPS VK-162 usa UTC
Kismet usa UTC
SQLite debe usar UTC
Problema evitado

El uso de hora local genera desincronización de aproximadamente 4 horas en Bolivia, lo que impide la correlación correcta de datos entre sensores, GPS y capturas WiFi.

Formato estándar

Se utiliza formato ISO 8601:

2026-06-11T02:30:15.123Z
Resultado

Permite sincronización exacta entre:

Capturas WiFi (Kismet)
Datos GPS
Sensores Arduino
Flujo final del sistema
Sensores
   ↓
Arduino UNO
   ↓
USB Serial
   ↓
Python Logger
   ↓
SQLite (UTC)
Resumen



