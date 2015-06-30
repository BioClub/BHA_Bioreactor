// Include libraries
#include <SoftwareSerial.h>
#include <OneWire.h>

// Declare variables
#define LED_PIN 13
#define TEMP_SENSOR_PIN 10

uint32_t lastTick = 0; 
String buffer;
uint32_t lastUpdate=0;

// Initiate temperature sensor
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
    
    Serial.print("temp "); Serial.println(analogRead(0)/10); // just simple test for now
  }
       
  while (Serial.available()>0) {
    char c = (char)Serial.read();
    if (c == '\n') {
      if (buffer.startsWith("id")) {
        Serial.println("id:bioreactor");
      }
      else if(buffer.startsWith("temp")) {
        int temp = buffer.substring(4).toInt();
        
        // TODO: change mosfet duty here
      }
      else {
        Serial.println("Unknown cmd.");
      }
      buffer="";
    } else buffer+=c;
  }  
  
  
}
