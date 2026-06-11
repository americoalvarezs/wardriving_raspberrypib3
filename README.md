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

# PARTE 2: Captura de sensores "Arduino" + "Arduino Training Shield V2" + "Raspberry pi b3+" 

Implementación de una plataforma portátil que realiza la captura de varios sensore(presentes en el arduino train shield v2) utilizando **Arduino Uno** como concentrador de datos y al cual estan conectados los sensores y luego este arduino, envia los datos al raspberry pi quien conectra todos los datos recibidos en una sola base de datos sqlite.

---

# Arquitectura del sistema de recoleccion de datos de sensores

```text
Raspberry Pi 3 B+
      │
      ├── Arduino uno conectado con el Arduino Training Shield V2
      │          │
      │          └── Sensor de temperatura LM35, Sensor de luz / LDR A1, Sensor digital de humedad y temperatura DHT11 D4, Sensor IR de 38 kHz D6
      │

```

---

# Material Utilizado

| Componente   | Modelo                            |
| ------------ | --------------------------------- |
| Raspberry Pi | Raspberry Pi 3 B+                 |
| Arduino uno  | Arduino uno |
| sensores varios | Arduino Training Shield V2                        |
| Comunicacion    | seria rs232                         |

<p align="center">
<img src="imagenes/arduino_uno.PNG" width="600"><br>
<img src="imagenes/training_shield1.PNG" width="600"><br>
<img src="imagenes/training_shield2.PNG" width="600"><br>
</p>

---

# Software Utilizado

* Raspberry Pi OS Lite (64 bits)
* Debian Trixie
* sqlite
* python
---


# preparacion de SO - instalando arduino

Actualizar el sistema
sudo apt update
sudo apt full-upgrade -y
2. Instalar dependencias
sudo apt install -y curl git unzip
3. Instalar Arduino CLI

Descarga e instala la versión oficial:

curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

Mover el ejecutable:

sudo mv bin/arduino-cli /usr/local/bin/

Verificar:

arduino-cli version

arduino-cli config init

Deberías obtener algo similar a:

Config file written to: /home/americo/.arduino15/arduino-cli.yaml

Luego verifica:

ls -l ~/.arduino15/

cat ~/.arduino15/arduino-cli.yaml

Después actualiza el índice de placas:

arduino-cli core update-index

instalar placas de arduino

arduino-cli core install arduino:avr

Ver qué placas tienes instaladas

arduino-cli core list

Conectar Arduino y verificar puerto:

arduino-cli board list

sudo apt update
sudo apt install python3-pip -y
pip3 --version

sudo apt update
sudo apt install python3-serial -y

VERIFICAR
python3 -c "import serial; print(serial.__version__)"

Verificar que Arduino aparece

Ejecuta:

ls /dev/tty*

---

# Programar arduino desde el raspberry

estructura de archivos
/home/americo/arduino/
├── sensores/
│   └── sensores.ino
│
└── cargar_arduino.sh

cuando se ejecute el script cargar arduino.sh de manera automatica verificara las carpetas que estan dentro de /home/americo/arduino/  y cada una de estas carpetas tendra dentro el archivo ino que es llamado igual que la carpeta esto para tener unca correcta carga de archivos. de manera automatica el script compila y carga al arduino un scketch INO.

Programa Arduino

Necesitarás la librería:

DHT sensor library

para la lectura del sensor dht11 



---

# comunicacion de arduino con raspberry y programas en raspberry pi

El arduino realizara la lectura de todos los sensores y los concentrara en una sola cadena de comunicacion que se enviara por cable serial al raspberry pi.

Conexiones arduino
LDR
 ├─ VCC → 5V
 ├─ GND → Resistencia 10kΩ → GND
 └─ Punto medio → A1

LM35
 ├─ Vs   → 5V
 ├─ Vout → A2
 └─ GND  → GND

DHT11
 ├─ VCC  → 5V
 ├─ DATA → D4
 └─ GND  → GND


el sistema obedece la siguiente secuencia: Arduino UNO
    ↓
USB Serial
    ↓
Python
    ↓
SQLite






solo arduino nomas que yo tenga el control para enviar datos. no utilizar events start o algo asi en python, esto no es necesario . 

Con este enfoque:

Arduino manda datos solo cuando tú lo decides con botones
Python solo escucha y registra
No dependes de parsing de eventos
El sistema queda más “hardware-driven” (más robusto en campo)

Arduino = fuente de control
Python  = logger pasivo

Arduino controla adquisición y flujo
Botones físicos manejan el estado ON/OFF
LED confirma estado del sistema
Python solo consume y almacena (sin lógica crítica)
Comunicación serial estable a 1 Hz
Sin saturación ni bursts

Esto ya no es un “sketch con sensores”, sino un sistema de adquisición básico:

Sensado → Control de estado → Serial → Logger → Base de datos

Y lo más importante:

✔ Determinístico (no depende de Python para decidir cuándo medir)
✔ Resistente a desconexiones de software
✔ Fácil de depurar (LED + botones)
✔ Escalable a más sensores
basado en frames <...>
Frames seguros
<0,13.20,12.70,14.00>

eventos:

<EVENT,START>
<EVENT,STOP>

stream auto-sincronizado
Python nunca pierde estructura
tolerancia a ruido serial
compatible con sistemas 24/7







programa Python


/home/americo/
│
├── 1_capturar_sensores.sh
└── db_sensores/
    ├── sensores_20260609_120000.db
    ├── sensores_20260609_121500.db
    └── ...

el programa de python capturar_sensores.py ubicado en /home/americo/python/ realiza lo siguiente: 
 
crea la base SQLite si no existe,
recibe datos del Arduino,
agrega timestamp local,
almacena registros.
versión completa, estable y coherente con todo lo que definiste:
✔ sin reconexiones por parsing
✔ sin readline() (evita desincronización)
✔ basado en frames <...>
Ignora automáticamente:
líneas cortadas
ruido serial
datos incompletos
desalineación
✔ buffer continuo
✔ tolera ruido serial
✔ guarda TODO (aunque venga sucio)
✔ pensado para correr en screen sensores 24/7
Cero desincronización real

Porque NO usa readline()
Stream continuo real

Usa buffer tipo:

buffer += chunk

Frames seguros

Solo procesa:

<0,13.20,12.70,14.00>



IDEA CLAVE FINAL
stream + buffer + extracción por delimitadores

el programa 1_capturar_sensores.sh  de manera automatica abre sesion screen llamada sensores y dentro de esa sesion ejecuta el programa /home/americo/python/capturar_sensores.py programa que lee los datos seriales enviador por el arduino que empieza a enviar cuando se presiona el boton ON, y los datos los coloca luego en sqllite3 dentro de la carpeta db_sensores/ archivos llamados 

correr screen sensores
correr wardrive en paralelo
dejarlo 24/7 sin intervención
y nunca perder sincronía del stream

El GPS VK162: Los satélites GPS no saben qué hora es en Bolivia; ellos transmiten la hora en formato UTC.

Kismet: Guarda todo internamente en su base de datos SQLite usando el formato Unix Timestamp (segundos transcurridos desde 1970) referidos a UTC.

tu script de Python para que guarde los datos de tus sensores en hora local de Bolivia mientras el GPS y Kismet guardan en UTC, al momento de querer unir los datos mediante el tiempo (saber qué red WiFi y qué coordenada GPS correspondían a un sensor), tus datos van a estar desfasados por 4 horas y el análisis fallará.

Tu flujo de trabajo ideal debe ser así:
Captura: Tu script de Python, Kismet y el GPS guardan todo en UTC.

Base de datos: Todo se almacena y se procesa en UTC.




¿Qué ha mejorado con este cambio?
Mismo Idioma Temporal: Si ejecutas este script a las 21:30 en tu reloj de Bolivia, el archivo de la base de datos se creará con la estampa 01:30 en el nombre de archivo y en los registros internos. Cuadrara perfectamente al segundo con el .kismet que se esté ejecutando en paralelo.

Nomenclatura Estándar (Z): Le añadí una Z al final del formato de texto (ej. 2026-06-11 01:21:54.123Z). En las bases de datos, esa "Z" (de Zulu Time) le dice a cualquier otro programa o software de visualización posterior que esa hora es UTC y no local. Esto te ahorrará dolores de cabeza en el futuro.


al 11 de junio de 2026 a las 02:30 (en horario UTC), a pesar de que en tu reloj de pared en Bolivia aún sean las 22:30 del 10 de junio.

A partir de este punto, cualquier análisis que hagas para cruzar información será sumamente sencillo:

Sincronización perfecta: Si un sensor detectó un pico extraño a las 02:30:15Z, podrás abrir la base de datos de Kismet, buscar qué redes o paquetes se capturaron exactamente a las 02:30:15 UTC y sabrás con total certeza qué estaba ocurriendo a tu alrededor en ese instante.

Geolocalización precisa: Cuando integres el GPS VK162, las coordenadas se emparejarán directamente con este mismo tiempo sin necesidad de hacer conversiones intermedias ni cálculos matemáticos en tu cabeza.

script para leer base de datos de sensores:

/home/americo/python

Aquí tienes un script en Python diseñado específicamente para eso. Lo he programado para que sea interactivo, limpio y fácil de leer en la terminal.

el código buscará automáticamente todos los archivos .db que encuentre en  /home/americo/db_sensores y te dejará elegir cuál quieres leer mediante un menú numérico. Así no tendrás que escribir nombres largos a mano.

Script de Lectura (leer_sensores.py)
Crea un archivo nuevo al lado de tus bases de datos, por ejemplo con nano leer_sensores.py, pega este código y guárdalo:

---

---

# Notas Finales

Los siguientes archivos deben estar dentro de:

```text
kismet_prog/
```

```text
kismet_up.sh
kismet_down.sh
```

Estructura recomendada:

```text
Proyecto/
│
├── kismet_prog/
│   ├── kismet_up.sh
│   └── kismet_down.sh
│
├── 1_capturar_sensores.sh
├── 2_start_wardrive.sh
├── 3_detener_todo.sh
│
└── capturas/
```

Salida de bases Kismet:

```text
/home/americo/kismet_prog/
```

Esto permite mantener una estructura organizada para posteriores análisis.
