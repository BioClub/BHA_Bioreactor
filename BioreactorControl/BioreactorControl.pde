/*
Bioreactor Control

We have build the bioreactor as an extensible device. 
Additional devices can be chained by serial connections.

This code is using the G4P user interface library to handle things like sliders. 
Go to Sketch/Import library to download it and see http://www.lagers.org.uk/g4p/ref/ for documentation

*/
import g4p_controls.*;
import processing.serial.*;


Serial serial;      // The serial port, null if no port
float updateSpeed = 2000; // 1000 ms

boolean ledState=true;
PFont defaultFont;
PFont titleFont;

String buffer;
float measuredTemperature;

GButton btnUpdateDeviceList;

String indexToPrefix(int index) {
  String prefix="";
  for (int i=0;i<index;i++)
    prefix += "$";
  return prefix;
}

class Pump {
  float position, speed, maximum;
  int deviceIndex;
  GCustomSlider slider;
  GLabel label;
  
  String deviceType;
  
  Pump(int deviceIndex, GCustomSlider sl) {
    maximum = 100;
    this.deviceIndex = deviceIndex;
    slider = sl;
  }
  
  
  void remove() {
    label.dispose();
    slider.dispose();
  }
  
  String prefix() { return indexToPrefix(deviceIndex); }
  
  void continuousRotation(float rpm) {
    serial.write(prefix() + "ct" + (int)rpm + "\n");
  }
  
  void rotate(float rpm, float numRevs) {
    serial.write(prefix() + "speed " + (int)rpm);
    serial.write(prefix() + "rotate " + (int) (numRevs * 10));
  }
};

ArrayList<Pump> pumps=new ArrayList<Pump>();

void addPump(int deviceIndex, String pumpType)
{
  int pumpIdx = pumps.size();
  GCustomSlider sdr;
    
  sdr = new GCustomSlider(this, 60, 80 + 60 * pumpIdx, 260, 50, "blue18px");
  // show          opaque  ticks value limits
  sdr.setShowDecor(false, true, true, true);
  // there are 3 types
  // GCustomSlider.DECIMAL  e.g.  0.002
  // GCustomSlider.EXPONENT e.g.  2E-3
  // GCustomSlider.INTEGER
  sdr.setNumberFormat(G4P.INTEGER, 0);
  sdr.setLimits(0.5f, 0f, 1.0f);
  
  if (pumpType.equals("peristaltic-pump")) {
    sdr.setLimits(-250, 250);
  }
  
  Pump p = new Pump(deviceIndex, sdr);

  p.label = new GLabel(this, 10, 65 + pumpIdx * 60, 180, 20);
  p.label.setText("Pump " + pumpIdx + " (" + pumpType+  ")");
  p.label.setLocalColorScheme(GCScheme.GREEN_SCHEME);

  pumps.add(p);
}

void handleCommand(int deviceIndex, String text)
{
  println("device: " +deviceIndex + " sent text:" + text);
  
  if (text.startsWith("id:")) {
    String id = text.substring(3);
    if (id == "peristaltic-pump")
      addPump(deviceIndex, id);
    if (id == "syringe-pump")
      addPump(deviceIndex, id);
  }
}

void updateDeviceList() {
  for (int i=0;i<10;i++) {
    serial.write(indexToPrefix(i) + "id" +"\n" ); // this will trigger all devices to send back "id:something"
  }
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
    serial = new Serial(this, portName, 57600);

    updateDeviceList();
  } else {
    serial=null;
    
    // make some fake pumps
    addPump(1, "peristaltic-pump");
//    addPump();
  }
    addPump(1, "peristaltic-pump");
  
  ledState=true;
  
  btnUpdateDeviceList = new GButton(this, width - 150, 40, 130, 30, "Update device list");
}


void handleSliderEvents(GValueControl slider, GEvent event) {
//println("integer value:" + slider.getValueI() + " float value:" + slider.getValueF());

  for (Pump p : pumps) {
    if (p.slider == slider) {
      println("Pump " + p.deviceIndex + "   value" + slider.getValueF());
    }
  }
}

void handleButtonEvents(GButton button, GEvent event) {
  if (button == btnUpdateDeviceList) {
    updateDeviceList();
  }
}



void draw() {
  int time = millis();

  background(255);
  
  textFont(titleFont);
  fill(0, 255, 0);
  text("BioHackAcademy Bioreactor Control", 10, 20);
  textFont(defaultFont);
  fill(0);
}

void serialEvent(Serial serial) {
  while (serial.available () >0) {
    char c = serial.readChar();
    if (c == '\n' && buffer.length() > 0) {
      
      int deviceIndex = 0;

      // the number of $ prefixes indicates which device the current text is coming from. Every device in the chain adds one $      
      while (buffer.charAt(0) == '$') {
        buffer = buffer.substring(1);
        deviceIndex ++;
      }
      
      handleCommand (deviceIndex,buffer);
      
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

