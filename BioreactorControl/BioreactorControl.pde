/*
Bioreactor Control

We have build the bioreactor as an extensible device. 
Additional devices can be chained by serial connections.

*/
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
  boolean overLeft, overRight;
  
  Pump(int index) {
    maximum = 100;
    this.index = index;
  }
  
  void drawLeftTriangle(int x, int y, int w, int h)
  {
    fill(128);
    stroke(0);
    triangle(x, y + h, x + w, y, x + w, y + h*2);
    fill(255);
  }
  
  void drawRightTriangle(int x,int y,int w,int h)
  {
    fill(128);
    stroke(0);
    triangle(x + w*2, y + h, x + w, y, x + w, y + h*2);
    fill(255);
  }
 
  
  void drawAndUpdate () {
    int startX=10;
    int startY=40*index+150;
    int W=20,H=15;
    int nx=startX + 80;

    fill(0);
    text("Pump " + index + ":", startX, startY+H);

    overLeft = mouseX > nx && mouseX < nx + W && mouseY >= startY && mouseY < startY + H;
  
    if (overLeft)
      drawLeftTriangle(nx-2, startY-2, W+4,H+4);
    else 
      drawLeftTriangle(nx, startY, W,H);
    nx += 30;

    overRight = mouseX > nx && mouseX < nx + W && mouseY >= startY && mouseY < startY + H;
    drawRightTriangle(nx, startY, W, H);

  }
};

ArrayList<Pump> pumps=new ArrayList<Pump>();


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
    pumps.add(new Pump(0));
    pumps.add(new Pump(1));
    pumps.add(new Pump(2));
  }
  
  ledState=true;
}




void draw() {
  int time = millis();

  background(255);
  
  textFont(titleFont);
  fill(0, 255, 0);
  text("BioHackAcademy Spectrophotometer", 10, 20);
  textFont(defaultFont);
  fill(0);
  
  for (int i=0;i<pumps.size();i++) {
    pumps.get(i).drawAndUpdate();
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



void polygon(float x, float y, float radius, int npoints) {
  float angle = TWO_PI / npoints;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius;
    float sy = y + sin(a) * radius;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}



