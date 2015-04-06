/*

Device chaining:
Devices can be chained by connecting another device to software serial pins (rx=8 and tx=9)
Connect the RX pin (8) to the TX pin of the next device, and the TX pin (9) to the RX of the next device (Typically pin 0/1).
Commands to the next device can be send by prefixing a line with a $ character. 
Data coming from the chained device is also prefixed and sent into the serial port.
*/
#include <SoftwareSerial.h>
#include <OneWire.h>

#define LED_PIN 13
#define TEMP_SENSOR_PIN 10


#define CHAIN_SERIAL_RX_PIN 8
#define CHAIN_SERIAL_TX_PIN 9
SoftwareSerial chainedDeviceSerial(CHAIN_SERIAL_RX_PIN, CHAIN_SERIAL_TX_PIN);
String chainedDeviceBuffer;

uint32_t lastTick = 0; 
String buffer;
uint32_t lastUpdate=0;

OneWire tempSensor(TEMP_SENSOR_PIN);

float getTemp(){
 //returns the temperature from one DS18S20 in DEG Celsius

 byte data[12];
 byte addr[8];

 if ( !tempSensor.search(addr)) {
   //no more sensors on chain, reset search
   tempSensor.reset_search();
   return -1000;
 }

 if ( OneWire::crc8( addr, 7) != addr[7]) {
   Serial.println("CRC is not valid!");
   return -1000;
 }

 if ( addr[0] != 0x10 && addr[0] != 0x28) {
   Serial.print("Device is not recognized");
   return -1000;
 }

 tempSensor.reset();
 tempSensor.select(addr);
 tempSensor.write(0x44,1); // start conversion, with parasite power on at the end

 byte present = tempSensor.reset();
 tempSensor.select(addr);  
 tempSensor.write(0xBE); // Read Scratchpad

 
 for (int i = 0; i < 9; i++) { // we need 9 bytes
  data[i] = tempSensor.read();
 }
 
 tempSensor.reset_search();
 
 byte MSB = data[1];
 byte LSB = data[0];

 float tempRead = ((MSB << 8) | LSB); //using two's compliment
 float temperatureSum = tempRead / 16;
 
 return temperatureSum;
 
}

// the setup function runs once when you press reset or power the board
void setup() {
  // Open serial connection and print a message
  Serial.begin(9600);
  Serial.println(F("bioreactor"));

  lastTick = millis();

  // initialize the LED pin as an output:
  pinMode(LED_PIN, OUTPUT);

  chainedDeviceSerial.begin(9600);
}


// the loop function runs over and over again forever
void loop() {
  
  // Update clock
  uint32_t time = millis(); // current time since start of sketch
  uint16_t dt = time-lastTick; // difference between current and previous time
  lastTick = time;
  
  digitalWrite(LED_PIN, !digitalRead(LED_PIN)); // alternate between 0 and 1   
  
  if (time > lastUpdate + 100) {
    lastUpdate=time;
  }
   
  while (chainedDeviceSerial.available()>0) {
    char c = (char)chainedDeviceSerial.read();
    if (c == '\n') {
      Serial.print("$"); Serial.println(chainedDeviceBuffer);
      chainedDeviceBuffer = "";
    } else {
      if (chainedDeviceBuffer.length()<100)
        chainedDeviceBuffer += c;
    }
  }
   
    
  while (Serial.available()>0) {
    char c = (char)Serial.read();
    if (c == '\n') {
      if (buffer.startsWith("$")) {
        chainedDeviceSerial.println(buffer.substring(1));
      }
      else {
        Serial.println("Unknown cmd.");
      }
      buffer="";
    } else buffer+=c;
  }  
  
  
}
