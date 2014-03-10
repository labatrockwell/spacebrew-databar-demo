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

ControlP5 cp5;
RadioButton modeUI;

// String server="ec2-184-72-140-184.compute-1.amazonaws.com"; 
//String server="lab-server.rockwellgroup.com"; 
String server="sandbox.spacebrew.cc"; 
String name="ArduinoLEDBar"; 
String description ="This is an example subscriber client for listening to range values";
Spacebrew spacebrewConnection;

ArduinoConnect arduino;
boolean arduino_ready = false;

LedLamp lampModel;
LedLampVirtualView lampVirtual;
LedLampRenderingView lampVirtualRendering;
LedLampPhysicalView lampPhysical;
LedLampViewHandler lampViewControl;

GrowingPixelControl lampGrowingPixAnim;
ColorChaseBarControl lampJointColorChase;
RainbowFadeControl lampRainbowFade;
SingleSourceGraphControl lampSingleSourceGraph;
MultSourceGraphControl lampMultSourceGraph;
MultSourceGraphSumControl lampMultSourceGraphSum;
MultSourceCenterGraphControl lampMultSourceGraphCenter;
ColorControl lampColor;
PixelTakeoverControl lampPixelTakeoverAnim;
LedLampControlHandler lampModelControl;

String subNames [] = { 
                      "switch_mode val",
                      "0_anim_growing_pixels start", 
                      "1_anim_rainbow_chase start", 
                      "2_anim_rainbow_fade start", 
                      "3_graph_single_src start", 
                      "4_graph_multi_src_sum start", 
                      "5_graph_multi_src_rt start", 
                      "6_graph_center_multi_src_rt start", 
                      "7_solid_color start", 
                      "8_anim_pixel_takeover start",
                      "graph_single_src val", 
                      "graph_multi_src_sum col", 
                      "graph_multi_src_rt col_1", 
                      "graph_multi_src_rt col_2", 
                      "graph_multi_src_rt col_3", 
                      "solid_color hue",
                      "solid_color sat",
                      "solid_color bright",
                      "graph_multi_src_rt column:val", 
                      "solid_color hue:sat:bright"
                    };

String subTypes [] = { 
                      "range", 
                      "boolean", 
                      "boolean", 
                      "boolean", 
                      "boolean", 
                      "boolean", 
                      "boolean", 
                      "boolean", 
                      "boolean", 
                      "boolean", 
                      "range",
                      "range", 
                      "range", 
                      "range", 
                      "range", 
                      "range", 
                      "range", 
                      "range",
                      "string", 
                      "string" 
                    };

ArrayList <Integer> strNames;
ArrayList <Integer> rangeNames;
ArrayList <Integer> boolNames;
String strRegex [] = { "(\\d{1,2}):(\\d{1,4})", "(\\d{1,4}):(\\d{1,4}):(\\d{1,4})" };

String pubNoiseRangeBaseName = "perlin_noise_";
float pubNoiseRangeVal [] = {0.0f, 0.0f, 0.0f}; 
float pubNoiseRangeInc [] = {0.05f, 0.03f, -0.04f}; 
String pubCountName = "sum_test_";
float pubCountLast = millis();
int pubCountInter = int(random(3000,10000));

void setup() {
  size(940, 560);

  // MODE UI SET-UP
  // create the modeUI radio button user interface component using the P5 library
  cp5 = new ControlP5(this);
  modeUI = cp5.addRadioButton("radioButton")
         .setPosition(20,500)
         .setSize(15,15)
         .setColorForeground(color(120))
         .setColorActive(color(255))
         .setColorLabel(color(75))
         .setItemsPerRow(5)
         .setSpacingColumn(150);
   
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

      // regex that matches all mode "start" subscriptions 
      String[] m = match(subNames[i], "\\d{1,2}_(.*) start");
      // if match was successful then create a modeUI element and update the mode counter
      if (m != null) {
        if (m.length == 2) {
          modeUI.addItem(m[1], modeCount);
          modeCount++;
        }
      }
  }

  // register the noise generators, that provide dummy data for the data viz views
  for(int i = 0; i < pubNoiseRangeVal.length; i++) {
    spacebrewConnection.addPublish( (pubNoiseRangeBaseName + i), 0 );
  }
  spacebrewConnection.addPublish( pubCountName, 0 );

  // connect to spacebrew
  spacebrewConnection.connect("ws://"+server+":9000", name, description );
  
  // select mode 0 from the mode UI
  modeUI.activate(0);

  // style all of the modeUI elements
  for(Toggle modeUIele:modeUI.getItems()) {
    modeUIele.captionLabel().setColorBackground(color(255,80,0,0));
    modeUIele.captionLabel().style().moveMargin(-7,0,0,-3);
    modeUIele.captionLabel().style().movePadding(7,0,0,3);
    modeUIele.captionLabel().style().backgroundWidth = 150;
    modeUIele.captionLabel().style().backgroundHeight = 13;
  }

  // MODEL, VIEW and CONTROL SET-UP
  // instantiate the shared data model object
  lampModel = new LedLamp (BARS, PIXELS_PER_BAR);

  // instantiate the view objects and the view handler object
  lampVirtual = new LedLampVirtualView (lampModel, 900, 470, 14, 14);
  lampVirtualRendering = new LedLampRenderingView (lampModel, 20, 20, 8, 8, dataPath("data_bar_rendering.png"));
  lampPhysical = new LedLampPhysicalView (lampModel);
  lampViewControl = new LedLampViewHandler (lampModel);

  // instantiate the control objects and the control handler object
  lampGrowingPixAnim = new GrowingPixelControl (lampModel);
  lampJointColorChase = new ColorChaseBarControl (lampModel, 60);
  lampRainbowFade = new RainbowFadeControl (lampModel, 200);
  lampSingleSourceGraph = new SingleSourceGraphControl (lampModel, 1000);
  lampMultSourceGraph = new MultSourceGraphControl (lampModel, 180);
  lampMultSourceGraphSum = new MultSourceGraphSumControl (lampModel, 120);
  lampMultSourceGraphCenter = new MultSourceCenterGraphControl (lampModel, 180);
  lampColor = new ColorControl (lampModel);
  lampPixelTakeoverAnim = new PixelTakeoverControl (lampModel, 100);
  lampModelControl = new LedLampControlHandler (lampModel);

  // add the screen views to the view handler (the arduino/physical view is linked when the arduino connects)
  lampVirtual.rotation(180);
  lampViewControl.add(lampVirtual);
  lampViewControl.add(lampVirtualRendering);

  // add the controls to the control handler
  lampModelControl.add(lampGrowingPixAnim);
  lampModelControl.add(lampJointColorChase);
  lampModelControl.add(lampRainbowFade);
  lampModelControl.add(lampSingleSourceGraph);
  lampModelControl.add(lampMultSourceGraphSum);
  lampModelControl.add(lampMultSourceGraph);
  lampModelControl.add(lampMultSourceGraphCenter);
  lampModelControl.add(lampColor);
  lampModelControl.add(lampPixelTakeoverAnim);
  
    // ARDUINO SET-UP
  // get list of arduinos connected to this computer
  ArduinoConnect.printArduinoSerialNumber();

  // connect to specific arduino running in the check-in station box
  arduino = new ArduinoConnect(this, true);
  arduino.connect("7413234343035171A281", 57600, char(130));


  frameRate(60);
}

void draw() {
  noStroke();
  if (lampModelControl.update()) {
    background(200,200,200);
    lampViewControl.draw();
  }
  generateRandomValues();
}

void generateRandomValues() {
  if (spacebrewConnection.connected()) {
    for (int i = 0; i < pubNoiseRangeVal.length; i ++) {
      spacebrewConnection.send((pubNoiseRangeBaseName + i), int(noise(pubNoiseRangeVal[i]) * 1024));
      pubNoiseRangeVal[i] += pubNoiseRangeInc[i];
    }
  }
  if ((millis() - pubCountLast) > pubCountInter) {
    pubCountInter = int(random(3000,10000));
    pubCountLast = millis();
    spacebrewConnection.send(pubCountName, (pubCountInter % 3));
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

void controlEvent(ControlEvent theEvent) {
  if(theEvent.isFrom(modeUI)) {
    if (debug) print("[controlEvent] got an event from "+theEvent.getName()+"\t");
//    for(int i=0;i<theEvent.getGroup().getArrayValue().length;i++) {
//      print(int(theEvent.getGroup().getArrayValue()[i]));
//    }
  print("[controlEvent] got an event from "+theEvent.getName()+"\t");
  println("\t "+theEvent.getValue());
    if (debug) println("\t "+theEvent.getValue());
    lampModelControl.changeMode(int(theEvent.getValue()));
  }
}

void keyPressed() {
  switch (key){
    case 'd': 
      debug = !debug;
      if (arduino_ready) arduino.connection.write(byte(250));
      if (debug) println("[keyPressed] debug ON");
      println("[keyPressed] debug OFF");
      break;
    case 'c':
      println("[keyPressed] change data bar mode");
      lampModelControl.changeMode();
      break;
    case 's':
      if (lampViewControl.isVisible(1)) lampViewControl.hide(1);
      else lampViewControl.show(1);
      break;
  }

  if (int(key) >= int('0') && int(key) <= int('9') ) {
    int curControl = int(key) - int('0');
    lampModelControl.changeMode(curControl);
    println("Control: change to " + curControl);    
  }
}

void mousePressed() {
}
