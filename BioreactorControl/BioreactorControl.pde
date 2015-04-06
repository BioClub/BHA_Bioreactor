/*
Bioreactor Control

We have build the bioreactor as an extensible device. 
Additional devices can be chained by serial connections.

*/
import g4p_controls.*;
import processing.serial.*;


Serial port;      // The serial port, null if no port
float updateSpeed = 2000; // 1000 ms

boolean ledState=true;
PFont defaultFont;
PFont titleFont;

String buffer;
float measuredTemperature;


class Pump {
  float position, speed, maximum;
  int index;
  GCustomSlider slider;
  GLabel label;
  
  Pump(int index) {
    maximum = 100;
    this.index = index;
   
  }
};

ArrayList<Pump> pumps=new ArrayList<Pump>();

void addPump()
{
  int idx = pumps.size();
  GCustomSlider sdr;
    
  sdr = new GCustomSlider(this, 60, 80 + 60 * idx, 260, 50, "blue18px");
  // show          opaque  ticks value limits
  sdr.setShowDecor(false, true, true, true);
  // there are 3 types
  // GCustomSlider.DECIMAL  e.g.  0.002
  // GCustomSlider.EXPONENT e.g.  2E-3
  // GCustomSlider.INTEGER
  sdr.setNumberFormat(G4P.DECIMAL, 3);
  sdr.setLimits(0.5f, 0f, 1.0f);
  
  Pump p = new Pump(idx);
  p.slider = sdr;

  p.label = new GLabel(this, 10, 80 + idx * 60, 60, 20);
  p.label.setText("Pump " + idx);
  p.label.setLocalColorScheme(GCScheme.GREEN_SCHEME);

  pumps.add(p);
}

void setup() {
  size(800, 400);
  
  // create a font with the third font available to the system:
  defaultFont = createFont("Arial", 14);
  titleFont = createFont("Arial", 20);
  textFont(defaultFont);

  // List all the available serial ports:
  printArray(Serial.list());

  String[] ports = Serial.list();
  if (ports.length > 0) {
    String portName = Serial.list()[0];
    port = new Serial(this, portName, 57600);
  } else {
    port=null;
    
    // make some fake pumps
    addPump();
    addPump();
    
  }
  
  ledState=true;
}




void draw() {
  int time = millis();

  background(255);
  
  textFont(titleFont);
  fill(0, 255, 0);
  text("BioHackAcademy Bioreactor Control", 10, 20);
  textFont(defaultFont);
  fill(0);
  
  for (int i=0;i<pumps.size();i++) {
  }
}

void serialEvent(Serial port) {
  while (port.available () >0) {
    char c = port.readChar();
    if (c == '\n' && buffer.length() > 0) {
      
      
      
      buffer="";
    } else {
      buffer+=c;
    }
  }
}

void keyPressed() {
  if (key >= 'A' && key <= 'Z')
    key += 'a'-'A'; // make lowercase

  if (key == 'e') {
    
  }
}


void handleSliderEvents(GSlider slider, GEvent event) {
  println("integer value:" + slider.getValueI() + " float value:" + slider.getValueF());
}

