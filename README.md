# wardriving implementacion con raspberry pi b3

## Material utilizado
- raspberry pi 3 b+
- USB - WIFI con modo monitor (TP-Link Archer T4UHP(US) VER:1.0. con chipset RTL8812AU)
- USB - GPS VK-162 (Chip GPS u-blox 7 con salida de datos protocolo NMEA 0183)
## Software
- Sistema Operativo Raspberry Pi OS Lite (32bits) a port of Debian Trixie with no desktop environment.
- Kismet 
### Preparar S.O. e instalar herramientas
**Instalar Raspbian CLI** para optimizar el consumo de memoria.</br>
<img src="imagenes/instalar_raspbian.gif" alt="Texto alternativo" width="500"></br>
Ingresamos por ssh a la consola del raspberry (recomendacion conectar con cable ethernet)</br>
<img src="imagenes/02 Coneccion por ssh a raspberry.PNG" alt="Texto alternativo" width="500"></br>
Se verifica arquitectura y kernel 
`uname -m
armv7l
`uname -r
6.12.75+rpt-rpi-v7

**instalar dependencias y headers para el kernel especifico de la raspberry pi b3**
sudo apt update
sudo apt install -y build-essential dkms git libelf-dev bc aircrack-ng
