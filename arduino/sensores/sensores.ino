#include <DHT.h>

// ======================================
// PINES
// ======================================

#define PIN_LDR    A1
#define PIN_LM35   A2
#define PIN_DHT    4

#define BOTON_ON   2
#define BOTON_OFF  3

#define LED_ESTADO 13

#define DHTTYPE DHT11

DHT dht(PIN_DHT, DHTTYPE);

// ======================================
// CONFIG
// ======================================

const unsigned long PERIODO_MS = 1000;

// ======================================
// ESTADO DEL SISTEMA
// ======================================

bool transmisionActiva = false;
unsigned long ultimoEnvio = 0;

// ======================================
// BOTONES (estado anterior)
// ======================================

int estadoAnteriorON = HIGH;
int estadoAnteriorOFF = HIGH;

// ======================================
// LECTURA ADC PROMEDIO
// ======================================

int leerPromedioADC(byte pin, byte muestras)
{
    long suma = 0;

    for (byte i = 0; i < muestras; i++)
    {
        suma += analogRead(pin);
    }

    return suma / muestras;
}

// ======================================
// SETUP
// ======================================

void setup()
{
    pinMode(BOTON_ON, INPUT);
    pinMode(BOTON_OFF, INPUT);

    pinMode(LED_ESTADO, OUTPUT);
    digitalWrite(LED_ESTADO, LOW);

    Serial.begin(9600);
    dht.begin();

    delay(1000);
}

// ======================================
// LOOP
// ======================================

void loop()
{
    manejarBotones();

    if (!transmisionActiva)
        return;

    if (millis() - ultimoEnvio < PERIODO_MS)
        return;

    ultimoEnvio += PERIODO_MS;

    enviarSensores();
}

// ======================================
// BOTONES (lógica simple robusta)
// ======================================

void manejarBotones()
{
    int lecturaON = digitalRead(BOTON_ON);

    if (estadoAnteriorON == HIGH && lecturaON == LOW)
    {
        if (!transmisionActiva)
        {
            transmisionActiva = true;

            digitalWrite(LED_ESTADO, HIGH);

            Serial.println("<EVENT,START>");

            ultimoEnvio = millis();
        }
    }

    estadoAnteriorON = lecturaON;

    // ----------------------------

    int lecturaOFF = digitalRead(BOTON_OFF);

    if (estadoAnteriorOFF == HIGH && lecturaOFF == LOW)
    {
        if (transmisionActiva)
        {
            transmisionActiva = false;

            digitalWrite(LED_ESTADO, LOW);

            Serial.println("<EVENT,STOP>");
        }
    }

    estadoAnteriorOFF = lecturaOFF;
}

// ======================================
// ENVIO DE SENSORES
// ======================================

void enviarSensores()
{
    int ldr = leerPromedioADC(PIN_LDR, 8);

    int adcLM35 = leerPromedioADC(PIN_LM35, 8);

    float voltaje = adcLM35 * (5.0 / 1023.0);
    float temperaturaLM35 = voltaje * 100.0;

    float humedad = dht.readHumidity();
    float temperaturaDHT = dht.readTemperature();

    if (isnan(humedad)) humedad = -1.0;
    if (isnan(temperaturaDHT)) temperaturaDHT = -1.0;

    SSerial.print("<");
	Serial.print(ldr);
	Serial.print(",");
	Serial.print(temperaturaLM35, 2);
	Serial.print(",");
	Serial.print(temperaturaDHT, 2);
	Serial.print(",");
	Serial.print(humedad, 2);
	Serial.println(">");
}
