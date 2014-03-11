



/*
CHANGES:
- make so that a new mode loads all pixels whenever it is loaded for the first time.

*/

/*
Message format: "\128 B2 B3 \129 B5 B6 B7 \130". 
  * byte \128 is the message start byte
  * byte B2 identifies the led bar number
  * byte B3 specifies the led number
  * byte \129 separates the id from the RGB data
  * bytes B5 through B7 hold the RGB values (the LED strips support 7-bit values only)
  * byte \130 functions as the end byte. 
 */

import com.rockwellgroup.arduinoconnect.*;
import spacebrew.*;
import processing.serial.*;
import javax.swing.*;
import controlP5.*;

boolean debug = false;

final int BARS = 3;
final int PIXELS_PER_BAR = 32;

String server="127.0.0.1";//"sandbox.spacebrew.cc"; 
String name="LED Bar"; 
String description ="This is an example subscriber client for listening to range values";
Spacebrew spacebrewConnection;

ArduinoConnect arduino;
boolean arduino_ready = false;

LedLamp lampModel;
LedLampVirtualView lampVirtual;
LedLampRenderingView lampVirtualRendering;
LedLampPhysicalView lampPhysical;
LedLampViewHandler lampViewControl;

ColorControl lampColor;
LedLampControlHandler lampModelControl;

String subNames [] = { 
                      "hue",
                      "brightness"
                    };

String subTypes [] = { 
                      "range", 
                      "range"
                    };

ArrayList <Integer> strNames;
ArrayList <Integer> rangeNames;
ArrayList <Integer> boolNames;
String strRegex [] = { "(\\d{1,2}):(\\d{1,4})", "(\\d{1,4}):(\\d{1,4}):(\\d{1,4})" };

void setup() {
  size(150, 500);
  
  int startup_time = millis();

  // SPACEBREW SET-UP
  // Instantiate the Spacebrew connection object
  spacebrewConnection = new Spacebrew( this );

  // instantiate the array lists that will hold the string, range and boolean subcription names
  strNames = new ArrayList <Integer> ();
  rangeNames = new ArrayList <Integer> ();
  boolNames = new ArrayList <Integer> ();

  // loop through the subscription names array and process each item 
  int modeCount = 0;
  for (int i = 0; i < subNames.length; i++) {
      // add the subscription to the spacebrew config
      spacebrewConnection.addSubscribe( subNames[i], subTypes[i] );

      // update the string, range and bool array lists with the appropriate names
      if (subTypes[i].indexOf("string") == 0) strNames.add(i);
      else if (subTypes[i].indexOf("range") == 0) rangeNames.add(i);
      else if (subTypes[i].indexOf("boolean") == 0) boolNames.add(i);
  }

  // connect to spacebrew
  spacebrewConnection.connect(server, name, description );
  
  // MODEL, VIEW and CONTROL SET-UP
  // instantiate the shared data model object
  lampModel = new LedLamp (BARS, PIXELS_PER_BAR);

  // instantiate the view objects and the view handler object
  lampVirtual = new LedLampVirtualView (lampModel, 120, 470, 30, 14);
  lampVirtualRendering = new LedLampRenderingView (lampModel, 20, 20, 8, 8, dataPath("data_bar_rendering.png"));
  lampPhysical = new LedLampPhysicalView (lampModel);
  lampViewControl = new LedLampViewHandler (lampModel);

  // instantiate the control objects and the control handler object
  lampColor = new ColorControl (lampModel);
  lampModelControl = new LedLampControlHandler (lampModel);

  // add the screen views to the view handler (the arduino/physical view is linked when the arduino connects)
  lampVirtual.rotation(180);
  lampModelControl.add(lampColor);

  lampViewControl.add(lampVirtual);
//  lampViewControl.add(lampVirtualRendering);
  
  // ARDUINO SET-UP
  // get list of arduinos connected to this computer
  ArduinoConnect.printArduinoSerialNumber();

  // connect to specific arduino running in the check-in station box
  arduino = new ArduinoConnect(this, true);
  arduino.connect("7413234343035171A281", 57600, char(130));

  while(millis() - startup_time < 6000) {}

  lampModelControl.update(0, 0);
  lampModelControl.update(2, 1023);

  frameRate(60);
}

void draw() {
  noStroke();
  if (lampModelControl.update()) {
    background(200,200,200);
    lampViewControl.draw();
  }
}


void onBooleanMessage( String name, boolean value ){
  println("[onBooleanMessage] got boolean message " + name + " : " + value);  
  lampModelControl.onBooleanMessage(name,value);
}

void onRangeMessage( String name, int value ){
  println("[onRangeMessage] got range message " + name + " : " + value);  
  lampModelControl.onRangeMessage(name,value);
}

void onStringMessage( String name, String value ){
  println("[onStringMessage] got string message " + name + " : " + value);  
  lampModelControl.onStringMessage(name,value);
}

void serialEvent(Serial p) {
  if (debug) println("[serialEvent] message received ");
  while (p.available() > 0) {
    int newByte = p.read();
    if (debug) print(newByte + ",");
    if (newByte == int(131)) {
      arduino_ready = true;
      lampViewControl.add(lampPhysical);
      if (debug) println("\narduino_ready");
    }
  }
  if (debug) println();
}

void keyPressed() {
  switch (key){
    case 'd': 
      debug = !debug;
      if (arduino_ready) arduino.connection.write(byte(250));
      if (debug) println("[keyPressed] debug ON");
      println("[keyPressed] debug OFF");
      break;
//    case 'c':
//      println("[keyPressed] change data bar mode");
//      lampModelControl.changeMode();
//      break;
    case 's':
      if (lampViewControl.isVisible(1)) lampViewControl.hide(1);
      else lampViewControl.show(1);
      break;
  }

//  if (int(key) >= int('0') && int(key) <= int('9') ) {
//    int curControl = int(key) - int('0');
//    lampModelControl.changeMode(curControl);
//    println("Control: change to " + curControl);    
//  }
}

void mousePressed() {
}
