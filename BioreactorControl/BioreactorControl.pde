/*
Bioreactor Control
  
 This code is using the G4P user interface library to handle things like sliders. 
 Go to Sketch/Import library to download it and see http://www.lagers.org.uk/g4p/ref/ for documentation
 
 */
import g4p_controls.*;
import processing.serial.*;
import java.util.*;

float updateSpeed = 2000; // 1000 ms

boolean ledState=true;
PFont defaultFont;
PFont titleFont;

String buffer;
float measuredTemperature;
GButton btnUpdateDeviceList;
GCustomSlider tempSlider;

class SerialPortBuffer {
  String buffer;
  Serial port;
}
HashMap<String, SerialPortBuffer> serialPorts=new HashMap<String, SerialPortBuffer>();
Serial bioreactorSerial;
float[] tempGraphData = new float[1000];

void addTemp(float val)
{
  for (int i=0; i<tempGraphData.length-1; i++)
    tempGraphData[i]=tempGraphData[i+1];
  tempGraphData[tempGraphData.length-1]=val;
}

void drawTempGraph()
{
  stroke(0);
  float xstart = width*0.2f;
  float xstep = width*0.6f/tempGraphData.length;
  float ystep = 2.0f;
  float h = height-60;

  for (int i=0; i<tempGraphData.length-1; i++) {
    line(xstart+xstep*i, h-tempGraphData[i]*ystep, xstart+xstep*(i+1), h-tempGraphData[i+1]*ystep);
  }
}

void delay(int delay)
{
  int time = millis();
  while (millis () - time <= delay);
}

class Pump {
  float position, speed, maximum;
  Serial port;
  String buffer;

  GCustomSlider slider;
  GLabel label;

  String deviceType;

  Pump(GCustomSlider sl, Serial serialPort) {
    maximum = 100;
    slider = sl;
    port = serialPort;
  }

  void remove() {
    label.dispose();
    slider.dispose();
  }

  void processSerialLine(String line)
  {
  }

  void update()
  {
  }

  void continuousRotation(float rpm) {
    port.write("move" + (int)rpm + "\n");
  }
};

HashMap<Serial, Pump> pumps=new HashMap<Serial, Pump>();

void addPump(String pumpType, Serial serialPort)
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

  Pump p = new Pump(sdr, serialPort);

  p.label = new GLabel(this, 10, 65 + pumpIdx * 60, 180, 20);
  p.label.setText("Pump " + pumpIdx + " (" + pumpType+  ")");
  p.label.setLocalColorScheme(GCScheme.GREEN_SCHEME);

  pumps.put(serialPort, p);
}


void updateDeviceList() {

  // List all the available serial ports:
  printArray(Serial.list());

  // go through all serial ports

  String[] portNames=Serial.list();

  for (int i=0; i<portNames.length; i++) {
    if (!serialPorts.containsKey(portNames[i])) {
      Serial port=new Serial(this, portNames[i], 9600);

      SerialPortBuffer spb = new SerialPortBuffer();
      spb.port=port;
      serialPorts.put(portNames[i], spb);
      port.write("\nid\n");
    }
  }
}


void setup() {
  size(800, 400);

  // create a font with the third font available to the system:
  defaultFont = createFont("Arial", 14);
  titleFont = createFont("Arial", 20);
  textFont(defaultFont);

  ledState=true;  
  btnUpdateDeviceList = new GButton(this, width - 150, 40, 130, 30, "Update device list");
  updateDeviceList();
  
  tempSlider = new GCustomSlider(this, 200, height - 50, 260, 50, "blue18px");
  tempSlider.setShowDecor(false, true, true, true);
  tempSlider.setNumberFormat(G4P.INTEGER, 0);
  tempSlider.setLimits(10, 80);
}


void handleSliderEvents(GValueControl slider, GEvent event) {
  //println("integer value:" + slider.getValueI() + " float value:" + slider.getValueF());

  for (Pump p : pumps.values ()) {
    if (p.slider == slider) {
      p.continuousRotation(slider.getValueF());
      //      println("Pump " + p.deviceIndex + "   value" + slider.getValueF());
    }
  }
  
  if(slider == tempSlider) {
    float wantedTemperature = slider.getValueF();
    if(bioreactorSerial != null) {
      bioreactorSerial.write("temp " + (int)wantedTemperature);
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

  if (bioreactorSerial!=null) {
  }

  drawTempGraph();
  text("Measured Temperature: " + measuredTemperature, 10, height-30);

  for (Pump p : pumps.values ()) {
    p.update();
  }

  textFont(titleFont);
  fill(0, 255, 0);
  text("BioHackAcademy Bioreactor Control", 10, 20);
  textFont(defaultFont);
  fill(0);
}

void initDevice(String deviceID, Serial serial)
{
  println("id: "+ deviceID);
  if (deviceID.equals("bioreactor")) {
    bioreactorSerial = serial;
    println("bioreactor connected.");
  } 

  if (deviceID.equals("peristaltic-pump")) {
    addPump(deviceID, serial);
    println("peristaltic pump connected.");
  } 

  if (deviceID.equals("syringe-pump")) {
    addPump(deviceID, serial);
    println("syringe pump connected.");
  }
}

void serialEvent(Serial serial) {

  SerialPortBuffer spb = null;
  for (SerialPortBuffer s : serialPorts.values ())
    if (s.port == serial) { 
      spb=s; 
      break;
    }

  if (spb != null) {    
    while (serial.available () >0) {
      char c = serial.readChar();
      if (c == '\n' && spb.buffer.length() > 0) {

        if (serial == bioreactorSerial) {
          println("bioreactor: " + spb.buffer);
          
          if (spb.buffer.startsWith("temp")) {
            measuredTemperature = Float.parseFloat(spb.buffer.substring(5));
            addTemp( measuredTemperature );
          }
        } else if (pumps.containsKey(serial)) {
          pumps.get(serial).processSerialLine(spb.buffer);
        } else {
          //          port.write("id\n");
          if (spb.buffer.startsWith("id:")) {
            initDevice(spb.buffer.substring(3).trim(), serial);
          } else
            serial.write("\nid\n");
        }
        spb.buffer="";
      } else {
        spb.buffer+=c;
      }
    }
  }
}

void keyPressed() {
  if (key >= 'A' && key <= 'Z')
    key += 'a'-'A'; // make lowercase

  if (key == 'e') {
  }
}

