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

guardando los arcfhivos *.kismet en db_sensores/  de manera automatica ordenando la generacion de la base de datos kismet

---



## PARTE 2 — Sistema de Telemetria y Adquisicion de Datos (Arduino + Raspberry Pi)

### Objetivo Tecnico
Implementar un nodo de adquisición determinística de variables físicas del entorno mediante el uso de un microcontrolador dedicado para el muestreo analógico/digital y un sistema embebido Linux operando en modo headless como data-logger pasivo.

---

### Especificaciones de Hardware (Subsistema de Telemetría)

* **Unidad de Adquisición Local:** Arduino UNO (ATmega328P).
* **Placa de Expansión:** Arduino Training Shield V2.
* **Sensores Integrados:**
  * **LM35:** Sensor analógico de temperatura calibrado en grados Celsius (Muestreo vía ADC).
  * **LDR (Fotorresistencia):** Divisor de tensión para la medición cualitativa de la intensidad lumínica ambiental.
  * **DHT11:** Sensor digital para el registro redundante de temperatura y humedad relativa (Protocolo Single-Wire).
  * **Receptor IR (38 kHz):** Sensor de demodulación para la detección de pulsos infrarrojos externos.

---

### Arquitectura de Flujo y Control

La topología del sistema se basa en la separación estricta de tareas bajo la filosofía de diseño IoT industrial:

```text
 [ Sensores Físicos ] 
          │
          ▼  (Lectura Directa ADC / Digital)
 ┌──────────────────────────────────┐
 │           Arduino UNO            │  <- Control estricto de tiempos de muestreo
 └────────────────┬─────────────────┘
                  │
                  ▼  (Transmisión Unidireccional / Frame Serial)
          [ Bus USB-UART ]
                  │
                  ▼  (Escucha Pasiva Asíncrona)
 ┌──────────────────────────────────┐
 │    Script Python (Data Logger)   │  <- Sin peticiones activas (No Polling)
 └────────────────┬─────────────────┘
                  │
                  ▼  (Estructuración e Inserción local en caliente)
 ┌──────────────────────────────────┐
 │      Base de Datos SQLite        │  <- Persistencia organizada en db_sensores/
 └──────────────────────────────────┘
Filosofía de Diseño Embebido
Determinismo en Hardware: El Arduino UNO gestiona la adquisición y temporización analógica de forma aislada. Esto garantiza inmunidad a retardos críticos (jitter) provocados por los cambios de contexto del sistema operativo de la Raspberry Pi.

Escucha Pasiva en software: El script en Python actúa como un logger estrictamente asíncrono. No realiza peticiones (polling) al microcontrolador. Al eliminar el handshake interactivo, el sistema se vuelve resiliente al ruido serial y evita bloqueos de E/S en la consola de la Raspberry Pi.

Protocolo de Comunicacion Serial
La comunicación se realiza por medio del puerto serie embebido (USB-UART) con tramas delimitadas de texto plano, facilitando el procesamiento analítico inmediato:

1. Tramas de Telemetría Regular
Formato estandarizado entre caracteres delimitadores de inicio < y fin > con valores separados por comas:

Plaintext
<ID_DISPOSITIVO,VALOR_LM35,VALOR_LDR,VALOR_DHT11>
Ejemplo real transmitido:

Plaintext
<0,13.20,12.70,14.00>
2. Tramas de Eventos del Sistema
Estructuras dedicadas a indicar cambios en el ciclo de vida del hardware o depuración:

Plaintext
<EVENT,START>
<EVENT,STOP>
Persistencia y Persistencia Temporal (Cronología SQLite)
Sincronización Temporal Crítica
Para evitar la desincronización al realizar el cruce de datos posterior con los logs de radiofrecuencia (WiFi), el script de Python asocia las tramas recibidas con la estampa de tiempo UTC (Coordinated Universal Time / Zulu Time). Si el sistema no dispone de conexión a red, el tiempo se sincroniza directamente desde las sentencias de tiempo atómico provistas por el daemon gpsd del módulo GPS VK-162.

Segmentación de Archivos
Los datos se almacenan en archivos SQLite locales autogenerados con nombres dinámicos basados en la fecha y hora de inicialización del proceso de captura:

Plaintext
db_sensores/
 └── sensores_YYYYMMDD_HHMMSS.db
