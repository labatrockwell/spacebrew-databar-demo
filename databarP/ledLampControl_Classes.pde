
///////////////////////////
// CONTROL CONTROLLER
///////////////////////////

/**
 * LedLampControlHandler This class provides an interface to switch between different modes 
 *   on the data bar lamp prototype. It holds an array of controls objects, some that make
 *   the data bar function like a bar graphs, other that use it to play animations.
 * 
 */
class LedLampControlHandler {

  ArrayList <LedLampControl>  controls;
  LedLamp model;
  int activeControl;
  boolean debug = false;

  LedLampControlHandler (LedLamp _model) {
    this.controls = new ArrayList <LedLampControl> ();
    this.model = _model;
    this.activeControl = 0;
  }

  void add(LedLampControl _control) {
    this.controls.add( _control );
  }

  boolean update() {
    return this.controls.get( this.activeControl ).update();
  }

  void update(int _val) {
   if ( (this.controls.get( this.activeControl ) instanceof ControlUpdate) ){
      ControlUpdate curItem = (ControlUpdate) this.controls.get( this.activeControl );
      curItem.update(_val);
    }
  }

  void update(int _bar, int _val) {
    if ( (this.controls.get( this.activeControl ) instanceof ControlUpdateWithBar) ){
      ControlUpdateWithBar curItem = (ControlUpdateWithBar) this.controls.get( this.activeControl );
      curItem.update(_bar, _val);
    }
    else if ( (this.controls.get( this.activeControl ) instanceof ControlUpdateColor) ){
      ControlUpdateColor curItem = (ControlUpdateColor) this.controls.get( this.activeControl );
      curItem.update(_bar, _val);
    }
  }

  void update(int _hue, int _sat, int _bri) {
   if ( (this.controls.get( this.activeControl ) instanceof ControlUpdateColor) ){
      ControlUpdateColor curItem = (ControlUpdateColor) this.controls.get( this.activeControl );
      curItem.update(_hue, _sat, _bri);
    }
  }

  void changeMode(int _activeControl) {
    if (_activeControl < 0) return;
    this.activeControl = _activeControl % this.controls.size();
  }

  void changeMode() {
    this.activeControl = (this.activeControl + 1) % this.controls.size();
  }

  void onRangeMessage(String name, int value) {
    println("[CONTROL:onRangeMessage] name " + name + " v: " + value);  

    if (name.indexOf("switch_mode") != -1) {
      println("[CONTROL:onRangeMessage] swich_mode ");  
      this.changeMode( (value % this.controls.size()) );
    }

    else if ( (this.controls.get( this.activeControl ) instanceof ControlUpdateColor) ) {
      println("[onRangeMessage] ControlUpdateColor "); 
      if (debug) println("[onRangeMessage] in mode 6 " + value);  
      if (name.indexOf("hue") != -1) {
        if (debug) println("[onRangeMessage] hue " + value);  
        this.update( 0, value );  
      }
      if (name.indexOf("sat") != -1) {
        if (debug) println("[onRangeMessage] sat " + value);  
        this.update( 1, value );  
      }
      if (name.indexOf("bright") != -1) {
        if (debug) println("[onRangeMessage] bright " + value);  
        this.update( 2, value );  
      }
    }

    else if ( (this.controls.get( this.activeControl ) instanceof ControlUpdateWithBar) ){
      println("[onRangeMessage] ControlUpdateWithBar "); 
      if (debug) println("[onRangeMessage] in mode 4 " + value);  
      if (name.indexOf("col_1") != -1) {
        if (debug) println("[onRangeMessage] col_1 " + value);  
        this.update( 0, value );  
      }
      if (name.indexOf("col_2") != -1) {
        if (debug) println("[onRangeMessage] col_2 " + value);  
        this.update( 1, value );  
      }
      if (name.indexOf("col_3") != -1) {
        if (debug) println("[onRangeMessage] col_3 " + value);  
        this.update( 2, value );  
      }
    }
    else if ( (this.controls.get( this.activeControl ) instanceof ControlUpdate) ){
      println("[onRangeMessage] no class " + value);  
      this.update( value );      
    }    
  }

  void onStringMessage(String name, String value) {
    for (int i = 0; i < strNames.size(); i ++) {
      if (name.indexOf(subNames[strNames.get(i)]) == 0) {
        try {

          String[] m = match(value, strRegex[i]);
          if (debug) println("[onStringMessage] applied regex - matches: " + m.length);  

          // handle messages with one element (first element does not count)
          if (m.length == 2) {
            this.update( parseInt(m[1]) );  
          }

          // handle messages with two elements (first element does not count)
          else if (m.length == 3) {
            this.update( parseInt(m[1]), parseInt(m[2]) );  
          }

          // handle messages with three elements (first element does not count)
          else if (m.length == 4) {
            this.update( parseInt(m[1]), parseInt(m[2]), parseInt(m[3]) );  
          }

        } catch( Exception e ){ 
          if (debug) println("[onStringMessage] error with match on " + value);
        }
      }
    }    
  }

  void onBooleanMessage(String name, boolean value) {
    if (name.indexOf("start") != -1) {
      try {
        String[] m = match(name, "(\\d{1,2})_");
        if (debug) println("[onStringMessage] applied regex - matches: " + m.length);  
        if (m.length == 2) {
          int newMode = parseInt(m[1]);
          // if (newMode < modeUI.getItems().size()) modeUI.activate( newMode );  
          this.changeMode( newMode );
          
        }
      } catch( Exception e ){ 
        if (debug) println("[onStringMessage] error with match on " + value);
      }
    }
  }

}


///////////////////////////
// CONTROL CLASSES
///////////////////////////

/**
 * MultSourceCenterGraphControl Class is an alternate version of the MultSourceGraphControl class. It
 *   visualizes data bars using the the center of the display as the origin point.
 * 
 */
class MultSourceCenterGraphControl extends MultSourceGraphControl implements ControlUpdateWithBar {

  /**
   * MultSourceGraphSumControl Constructor that accepts a link to the data model.
   *
   * @param _model Holds a link to the shared data model
   */
  MultSourceCenterGraphControl (LedLamp _model) {
    super(_model, 500);
  }

  /**
   * MultSourceGraphSumControl Constructor that accepts a link to the data model, and an integer with
   *   the refresh interval in millis.
   *
   * @param _model Holds a link to the shared data model
   * @param _interval Interval in millis between each model refresh 
   */
  MultSourceCenterGraphControl(LedLamp _model, int _interval) {
    super(_model, _interval);
  }

  /**
   * MultSourceGraphSumControl Constructor that accepts a link to the data model, an array of color 
   *   with the foreground color for each bar, and a background color.
   *
   * @param _model Holds a link to the shared data model
   * @param _color Array that holds the color for each of the data bars
   * @param _b_color The background color
   */
  MultSourceCenterGraphControl(LedLamp _model, color _color [], color _b_color) {
    super(_model, _color, _b_color);
  }

  /**
   * update Method that is used to update the data model at the specified refresh rate.
   *   It calculates the new data values by averaging all readings received during the
   *   refresh interval.
   */
  boolean update() {
    if (millis() - this.refreshTimeLast > this.refreshTimeInterval) {
      this.refreshTimeLast = millis();      

      // calculate the new value for each bar by averaging all new readings
      for (int i = 0; i < this.newVals.length; i++) {
        if (this.newValCounts[i] == 0) this.vals[i] = 0;
        else this.vals[i] = int(map((this.newVals[i] / this.newValCounts[i]), 0, 1024, 0, int(this.model.getSize().y/2))); 
        this.newVals[i] = 0;         
        this.newValCounts[i] = 0;
        if (debug) println("[MultSourceCenterGraphControl:update] bar " + i + " val " + this.vals[i] );
      }

      // update the data model
      int originUp = 16;
      int originDown = 15;
      for (int b = 0; b < int(this.model.getSize().x); b++) {
        for (int p = 0; p < int(this.model.getSize().y/2); p++) {
          color curColor;
          if (vals[b] >= p) curColor = this.activeColors[b];
          else curColor = this.backgroundColor;
          this.model.setPixelColor(b, (originUp + p), curColor);
          this.model.setPixelColor(b, (originDown - p), curColor);
        }
      }
      return true;
    }
    return false;
  }

  /**
   * update Method that is called to log a new data entry for a specified bar. These data entries are
   *   summed in the newVals array, and a count of the number of new readings is also saved so that 
   *   an average data value can be calculated when the model is refreshed. 
   *
   * @param _bar Holds the bar number whose value is being set
   * @param _val Holds the value to which the bar will be set
   */
  void update(int _bar, int _val) {
    super.update(_bar, _val);
  }
}




/**
 * MultSourceGraphSumControl Class that makes the Data Bar function like a bar graph where each bar 
 *   visualizes data from a separate source. Functions in sum mode, where the height of each bar is 
 *   incremented by one when the update(_column) method is called.
 * 
 */
class MultSourceGraphSumControl extends MultSourceGraphTempControl implements ControlUpdate {

  /**
   * MultSourceGraphSumControl Constructor that accepts a link to the data model.
   *
   * @param _model Holds a link to the shared data model
   */
  MultSourceGraphSumControl (LedLamp _model) {
    super(_model, 500);
  }

  /**
   * MultSourceGraphSumControl Constructor that accepts a link to the data model, and an integer with
   *   the refresh interval in millis.
   *
   * @param _model Holds a link to the shared data model
   * @param _interval Interval in millis between each model refresh 
   */
  MultSourceGraphSumControl(LedLamp _model, int _interval) {
    super(_model, _interval);
  }

  /**
   * MultSourceGraphSumControl Constructor that accepts a link to the data model, an array of color 
   *   with the foreground color for each bar, and a background color.
   *
   * @param _model Holds a link to the shared data model
   * @param _color Array that holds the color for each of the data bars
   * @param _b_color The background color
   */
  MultSourceGraphSumControl(LedLamp _model, color _color [], color _b_color) {
    super(_model, _color, _b_color);
  }

  /**
   * update Method that is used to update the data model at the specified refresh rate. It
   *   It calculates the new data values by averaging all readings received during the
   *   refresh interval.
   */
  boolean update() {
    if (millis() - this.refreshTimeLast > this.refreshTimeInterval) {
      this.refreshTimeLast = millis();      

      // update the data model
      for (int b = 0; b < int(this.model.getSize().x); b++) {
        for (int p = 0; p < int(this.model.getSize().y); p++) {
          if (vals[b] >= p) this.model.setPixelColor(b, p, this.activeColors[b]);
          else this.model.setPixelColor(b, p, this.backgroundColor);
        }
      }
      return true;
    }
    return false;
  }

  /**
   * update Increments the value represented by a bar by 1 unit. 
   *
   * @param _bar Number of the bar whose value will be incremented by 1
   */
  void update(int _bar) {
    if (_bar < this.vals.length) {
      this.vals[_bar] += 1;
      println("[MultSourceGraphSumControl:UPDATE] updated value " + this.vals[_bar]);
    }
  }
}


/**
 * MultSourceGraphControl Class that makes the Data Bar function like a bar graph where each bar 
 *   visualizes data from a separate source. Instances of this class can function in realtime and
 *   sum modes (realtime mode is the default). In sum mode, the height of each bar is incremented by
 *   one when the update(_column) method is called. When not in sum mode, the height of each bar is
 *   calculated based only on the readings received since last model refresh.
 * 
 */
class MultSourceGraphControl extends MultSourceGraphTempControl implements ControlUpdateWithBar {
//  color backgroundColor;  // holds the background color
//  color activeColors [];  // array that holds the color for each bar
//  int vals [];            // array that holds the number of leds that should be turned on on each bar
//  int newVals [];         // holds the total of all new readings received since last refresh
//  int newValCounts [];    // holds the number of readings received since last refresh

  /**
   * MultSourceGraphControl Constructor that accepts a link to the data model.
   *
   * @param _model Holds a link to the shared data model
   */
  MultSourceGraphControl (LedLamp _model) {
    super(_model, 500);
  }

  /**
   * MultSourceGraphControl Constructor that accepts a link to the data model, and an integer with
   *   the refresh interval in millis.
   *
   * @param _model Holds a link to the shared data model
   * @param _interval Interval in millis between each model refresh 
   */
  MultSourceGraphControl(LedLamp _model, int _interval) {
    super(_model, _interval);
  }

  /**
   * MultSourceGraphControl Constructor that accepts a link to the data model, an array of color 
   *   with the foreground color for each bar, and a background color.
   *
   * @param _model Holds a link to the shared data model
   * @param _color Array that holds the color for each of the data bars
   * @param _b_color The background color
   */
  MultSourceGraphControl(LedLamp _model, color _color [], color _b_color) {
    super(_model, _color, _b_color);
  }

  /**
   * update Method that is used to update the data model at the specified refresh rate. It
   *   It calculates the new data values by averaging all readings received during the
   *   refresh interval.
   */
  boolean update() {
    if (millis() - this.refreshTimeLast > this.refreshTimeInterval) {
      this.refreshTimeLast = millis();      

      // if not in sumMode then calculate the new value for each bar by averaging all new readings
      for (int i = 0; i < this.newVals.length; i++) {
        if (this.newValCounts[i] == 0) this.vals[i] = 0;
        else this.vals[i] = int(map((this.newVals[i] / this.newValCounts[i]), 0, 1024, 0, 32)); 
        this.newVals[i] = 0;         
        this.newValCounts[i] = 0;
        if (debug) println("[MultSourceGraphControl:update] bar " + i + " val " + this.vals[i] );
      }

      // update the data model
      for (int b = 0; b < int(this.model.getSize().x); b++) {
        for (int p = 0; p < int(this.model.getSize().y); p++) {
          if (vals[b] >= p) this.model.setPixelColor(b, p, this.activeColors[b]);
          else this.model.setPixelColor(b, p, this.backgroundColor);
        }
      }
      return true;
    }
    return false;
  }

  /**
   * update Method that is called to log a new data entry for a specified bar. These data entries are
   *   summed in the newVals array, and a count of the number of new readings is also saved so that 
   *   an average data value can be calculated when the model is refreshed. 
   *
   * @param _bar Holds the bar number whose value is being set
   * @param _val Holds the value to which the bar will be set
   */
  void update(int _bar, int _val) {
    _bar = _bar % 3;
    this.newVals[_bar] += _val;
    this.newValCounts[_bar] ++;
    if (debug) println("[MultSourceGraphControl:update(bar,val)] bar " + _bar + " newval " + this.newVals[_bar] + " count " + this.newValCounts[_bar]);
  }
}

/**
 * MultSourceGraphControl Class that makes the Data Bar function like a bar graph where each bar 
 *   visualizes data from a separate source. Instances of this class can function in realtime and
 *   sum modes (realtime mode is the default). In sum mode, the height of each bar is incremented by
 *   one when the update(_column) method is called. When not in sum mode, the height of each bar is
 *   calculated based only on the readings received since last model refresh.
 * 
 */
class MultSourceGraphTempControl extends LedLampControl {
  color backgroundColor;  // holds the background color
  color activeColors [];  // array that holds the color for each bar
  int vals [];            // array that holds the number of leds that should be turned on on each bar
  int newVals [];         // holds the total of all new readings received since last refresh
  int newValCounts [];    // holds the number of readings received since last refresh

  /**
   * MultSourceGraphControl Constructor that accepts a link to the data model.
   *
   * @param _model Holds a link to the shared data model
   */
  MultSourceGraphTempControl (LedLamp _model) {
    this(_model, 500);
  }

  /**
   * MultSourceGraphControl Constructor that accepts a link to the data model, and an integer with
   *   the refresh interval in millis.
   *
   * @param _model Holds a link to the shared data model
   * @param _interval Interval in millis between each model refresh 
   */
  MultSourceGraphTempControl(LedLamp _model, int _interval) {
    super(_model, _interval);
    this.vals = new int [int(this.model.getSize().x)];
    this.newVals = new int [int(this.model.getSize().x)];
    this.newValCounts = new int [int(this.model.getSize().x)];
    this.activeColors = new color [int(this.model.getSize().x)];
    this.backgroundColor = color(0,0,0);
    for (int i = 0; i < this.vals.length; i++) {
      this.vals[i] = 0;
      this.newVals[i] = 0;
      this.newValCounts[i] = 0;
      this.activeColors[i] = color(random(0,255),random(0,255),random(0,255));
    }
  }

  /**
   * MultSourceGraphControl Constructor that accepts a link to the data model, an array of color 
   *   with the foreground color for each bar, and a background color.
   *
   * @param _model Holds a link to the shared data model
   * @param _color Array that holds the color for each of the data bars
   * @param _b_color The background color
   */
  MultSourceGraphTempControl(LedLamp _model, color _color [], color _b_color) {
    this(_model);
    for (int i = 0; i < this.activeColors.length; i++) {
      if (i < _color.length) this.activeColors[i] = _color[i];
    }
    this.backgroundColor = _b_color;
  }
}


/**
 * SingleSourceGraphControl Class that turns the Data Bar into a data graphing tool that 
 *   graphs a single source of data over time. Each time the model is refreshed the data
 *   from each bar shifts over to the right by one location, the new data point being added
 *   to the left-most bar.
 * 
 */
class SingleSourceGraphControl extends LedLampControl  implements ControlUpdate {
  color foregroundColor;  // holds the foreground color
  color backgroundColor;  // holds the background color
  int vals [];          // holds the number of pixels that should be lit up on each bar
  int newVal;           // holds the total of all new readings received since last refresh
  int newValCount;      // holds the number of readings received since last refresh
  boolean debug = false;

  /**
   * SingleSourceGraphControl Constructor for the SingleSourceGraphControl class that accepts a link to 
   *   the active data model.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   */
  SingleSourceGraphControl (LedLamp _model) {
    this(_model, 1000);
  }

  /**
   * SingleSourceGraphControl Constructor for the SingleSourceGraphControl class that accepts a link to 
   *   the active data model and refresh time.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   * @param _refresh Time interval in millis between each model refresh
   */
  SingleSourceGraphControl(LedLamp _model, int _interval) {
    super(_model, _interval);
    this.vals = new int [int(this.model.getSize().x)];
    this.backgroundColor = color(0,0,0);
    this.foregroundColor = color(255,0,0);
    this.newVal = 0;
    this.newValCount = 0;
    for (int i = 0; i < this.vals.length; i++) {
      this.vals[i] = 0;
    }
  }

  /**
   * SingleSourceGraphControl Constructor for the SingleSourceGraphControl class that accepts a link to 
   *   the active data model and color values for the foreground and background color.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   * @param _color Color used to set the foreground color of the bar graph
   * @param _b_color Color used to set the background color of the bar graph
   */

  SingleSourceGraphControl(LedLamp _model, color _color, color _b_color) {
    this(_model, 1000);
    this.backgroundColor = _b_color;
    this.foregroundColor = _color;
  }

  /**
   * update Method that is used to update the data model at the specified refresh rate. It
   *   shifts the data in the data array, and adds the newest data value to the start of the 
   *   array. It calculates the new data value by averaging all values received during the
   *   refresh interval.
   */
  boolean update() {
    // check whether it is time to refresh the model
    if (millis() - this.refreshTimeLast > this.refreshTimeInterval) {
      this.refreshTimeLast = millis();      

      if (this.debug) this.update(int(random(0, 1023)));

      // shift the data in the vals array up by one index
      for (int i = (this.vals.length - 1); i > 0; i--) {
        this.vals[i] = this.vals [i-1];
      }

      // averaging newVal readings to update index 0 of vals array
      if (this.newValCount == 0) this.newVal = 0;
      else this.newVal = this.newVal / this.newValCount;
      vals[0] = int( map( this.newVal, 0, 1023, 0, 32) );

      // loop through the pixels and update each one
      for (int b = 0; b < int(this.model.getSize().x); b++) {
        for (int p = 0; p < int(this.model.getSize().y); p++) {
          if (vals[b] >= p) this.model.setPixelColor(b, p, this.foregroundColor);
          else this.model.setPixelColor(b, p, this.backgroundColor);
        }
      }

      // reset the variables used to average readings when necessary
      this.newVal = 0;
      this.newValCount = 0;
      return true;
    }
    return false;
  }

  /**
   * update Method that is used to input a new reading value. The reading values are summed, and a
   *   counter keeps track of the number of readings, so that these values can be averaged when it 
   *   is time to update/refresh the data model.
   */
  void update(int _val) {
    this.newVal += _val;
    this.newValCount ++;
  }
}

/**
 * RainbowFadeControl Class that runs an animation where a new color is loaded on the 
 *   Data Bar continuously. The colors cycle through a color colorWheel.
 */
class RainbowFadeControl extends LedLampControl {
  color foregroundColor;  

  /**
   * RainbowFadeControl Constructor for the RainbowFadeControl class that accepts a link to the active 
   *   data model.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   */
  RainbowFadeControl (LedLamp _model) {
    this(_model, 60);
  }

  /**
   * RainbowFadeControl Constructor for the RainbowFadeControl class that accepts a link to the active 
   *   data model and refresh time.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   * @param _refresh Time interval in millis between each model refresh
   */
  RainbowFadeControl(LedLamp _model, int _interval) {
    super(_model, _interval);
  }

  /**
   * update Method that is used to update the data model at the specified refresh rate.
   */
  boolean update() {
    // check whether it is time to refresh the model
    if (millis() - this.refreshTimeLast > this.refreshTimeInterval) {
      this.refreshTimeLast = millis();

      // update the active color, and then update all pixels with new color
      this.foregroundColor = colorWheel(); 
      for (int b = 0; b < this.model.getSize().x; b++) {
        for (int p = 0; p < this.model.getSize().y; p++) {
          this.model.setPixelColor(b, p, this.foregroundColor);
        }
      }
      return true;
    }
    return false;
  }
}

/**
 * ColorControl Class that turns the Data Bar into a multi-colored light that can be set to 
 *   any color via HSB values. The color that is set remains unchanged until another color
 *   setting is received. 
 */
class ColorControl extends LedLampControl implements ControlUpdateColor {
  color foregroundColor;
  int hsb [] = new int [3]; // holds the hsb values

  /**
   * ColorControl Constructor for the ColorControl class that accepts a link to the active 
   *   data model and refresh time.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   */
  ColorControl (LedLamp _model) {
    this(_model, 60);
  }

  /**
   * ColorControl Constructor for the ColorControl class that accepts a link to the active 
   *   data model and refresh time.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   * @param _refresh Time interval in millis between each model refresh
   */
  ColorControl(LedLamp _model, int _interval) {
    super(_model, _interval);
    for (int i = 0; i < hsb.length; i++) {
      hsb[i] = 1023;
    }
  }

  /**
   * update Method that is used to update the data model at the specified refresh rate.
   *   This is the only update method that updates the data model, all other models just
   *   load the color into a stagging variable.
   */
  boolean update() {
    // check whether it is time to refresh the model
    if (millis() - this.refreshTimeLast > this.refreshTimeInterval) {
      this.refreshTimeLast = millis();

      // set the active color using the hsb array data
      colorMode(HSB, 1024);
      this.foregroundColor = color(hsb[0], hsb[1], hsb[2]); 
      colorMode(RGB, 255);

      // loop through each pixel and set it to the active color
      for (int b = 0; b < int(this.model.getSize().x); b++) {
        for (int p = 0; p < int(this.model.getSize().y); p++) {
          this.model.setPixelColor(b, p, this.foregroundColor);
        }
      }
      return true;
    }    
    return false;
  }

  /**
   * update Method that updates the value of the hue, saturation and brightness of the 
   *   active color
   *
   * @param _hue Holds an integer that is used to set the hue
   * @param _sat Holds an integer that is used to set the saturation
   * @param _bri Holds an integer that is used to set the brightness
   */
  void update(int _hue, int _sat, int _bri) {
    hsb[0] = constrain(_hue, 0, 1024);;
    hsb[1] = constrain(_sat, 0, 1024);;
    hsb[2] = constrain(_bri, 0, 1024);;
    if (debug) println("[ColorControl:update] hue "  + _hue + " sat " + _sat + " bri " + _bri );
  }

  /**
   * update Method that updates the value of the hue, saturation or brightness of the 
   *   active color
   *
   * @param _hsb Holds an integer between 0 and 2 that refers to a HSB attribute - hue, 
   *             saturation or brightness respectively
   * @param _val Holds the value that is used to set the HSB attribute
   */
  void update(int _hsb, int _val) {
    _hsb = _hsb % 3;
    hsb[_hsb] = constrain(_val, 0, 1024);
    if (debug) println("[ColorControl:update] changing "  + _hsb + " to " + _val );
  }
}

/**
 * ColorChaseBarControl Class that runs an animation where a new color is wiped across the 
 *   Data Bar continuously. The colors cycle through a color colorWheel.
 */
class ColorChaseBarControl extends LedLampControl {
  color foregroundColor;
  int pixel;

  /**
   * ColorChaseBarControl Constructor for the ColorChaseBarControl class that accepts a link to the active 
   *   data model.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   */
  ColorChaseBarControl (LedLamp _model) {
    this(_model, 100);
  }

  /**
   * ColorChaseBarControl Constructor for the ColorChaseBarControl class that accepts a link to the active 
   *   data model and refresh time.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   * @param _refresh Time interval in millis between each model refresh
   */
  ColorChaseBarControl(LedLamp _model, int _interval) {
    super(_model, _interval);
    this.pixel = 0;
  }

  /**
   * update Updates the model by moving a color across the data bar, one pixel at a time
   *   at each refresh interval.
   */
  boolean update() {
    // check whether it is time to refresh the model
    if (millis() - this.refreshTimeLast > this.refreshTimeInterval) {
      this.refreshTimeLast = millis();

      // if the color has filled in the entire Data Bar then get a new color
      if (this.pixel == 0) this.foregroundColor = colorWheel(); 
 
      // update the next set of leds
      this.updateAcross(this.foregroundColor, this.pixel);
      this.pixel = (this.pixel + 1) % PIXELS_PER_BAR;  
      return true;
    }
    return false;
  }

  /**
   * updateAcross Method that updates all pixels across on the data bar (x-axis). 
   *
   * @param _color Color that is used to set all pixels across the bar at the specified height
   * @param _height Height where the leds will be set to the specified color 
   */
  void updateAcross(color _color, int _height) {
    for (int b = 0; b < int(model.getSize().x); b++) {
      this.model.setPixelColor(b, _height, _color);
    }
  }
}

/**
 * PixelTakeoverControl Class the runs an animation where a color takes over the display
 *   one pixel at a time. 
 * 
 */
class PixelTakeoverControl extends LedLampControl {

  color foregroundColor;    // holds the color that is taking over
  boolean isPixelSet [][];  // double array that holds the status of each pixel
  int pixelsNotSet;         // counter that holds the number of pixels that have NOT been set

  /**
   * PixelTakeoverControl Constructor that accepts a link to the active data model.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   */
  PixelTakeoverControl(LedLamp _model) {
    this(_model, 100);
  }

  /**
   * PixelTakeoverControl Constructor that accepts a link to the active data model and refresh time.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   * @param _refresh Time interval in millis between each model refresh
   */
  PixelTakeoverControl(LedLamp _model, int _interval) {
    super(_model, _interval);
    isPixelSet = new boolean [int(this.model.getSize().x)] [int(this.model.getSize().y)];
    this.init();
  }

  /**
   * init Method that re-initializes variables preparation to start fading in a new color 
   */
  void init() {
    this.foregroundColor = color(random(0,255),random(0,255),random(0,255));
    for (int b = 0; b < this.isPixelSet.length; b++) {
      for (int p = 0; p < this.isPixelSet[b].length; p++) {
        this.isPixelSet[b][p] = false;
      }        
    }    
    this.pixelsNotSet = int(this.model.getSize().x * this.model.getSize().y);    
  }

  /**
   * update Updates the model by turning one new pixel to the new color.
   */
  boolean update() {
    // check whether it is time to refresh the model
    if (millis() - this.refreshTimeLast > this.refreshTimeInterval) {
      this.refreshTimeLast = millis();

      // randomly select the next pixel to set
      int nextPix = int(random(0, pixelsNotSet));
      int nextCount = 0;

      // println("[PixelTakeoverControl:update] next pix " + nextPix + " count " + pixelsNotSet);

      // loop through all the pixels to find the appropriate one to update
      for (int b = 0; b < int(model.getSize().x); b++) {
        for (int p = 0; p < int(model.getSize().y); p++) {
          if (!isPixelSet[b][p]) {
            // if pixel has not been set then set color, update isPixelSet array and set visible flag to true
            if (nextCount == nextPix) {
              this.model.setPixelColor(b, p, this.foregroundColor);
              isPixelSet[b][p] = true;   
              pixelsNotSet--;
              b = int(model.getSize().x);
              p = int(model.getSize().y);
            }
            nextCount++;
          }
        }
      }

      // if there all pixels have been set then re-init variables and choose a new color
      if (pixelsNotSet <= 0) {
        this.init();
      }
      return true;
    }    

    return false;
  }

}


/**
 * GrowingPixelControl Class the runs an animation where colored "pixels" appear and grow until
 *   they disappear behind other "pixels", which are in the foreground. 
 * 
 */
class GrowingPixelControl extends LedLampControl {

  ArrayList <PVector> growPixLoc;   // holds location of each "growing pixel"
  ArrayList <PVector> growPixSize;  // holds size of each "growing pixel"
  ArrayList <Integer> activeColors;  // holds color of each "growing pixel"
  int active_colors = 4;


  /**
   * GrowingPixelControl Constructor for the GrowingPixelControl class that accepts a link to the active 
   *   data model.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   */
  GrowingPixelControl(LedLamp _model) {
    this(_model, 100);
  }

  /**
   * GrowingPixelControl Constructor for the GrowingPixelControl class that accepts a link to the active 
   *   data model and refresh time.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   * @param _refresh Time interval in millis between each model refresh
   */
  GrowingPixelControl(LedLamp _model, int _interval) {
    super(_model, _interval);
    this.growPixLoc = new ArrayList<PVector>();
    this.growPixSize = new ArrayList<PVector>();
    this.activeColors = new ArrayList<Integer>();
    for (int b = 0; b < this.active_colors; b++) {
      this.addNewPixel();
    }    
  }

  /**
   * update Updates the model with the visible "growing pixels", increases the size of each
   *   visible "growing pixel", and removes "growing pixels" that are no longer visible.
   */
  boolean update() {
    // check whether it is time to refresh the model
    if (millis() - this.refreshTimeLast > this.refreshTimeInterval) {
      this.refreshTimeLast = millis();

      // create array to track which pixels have been set
      boolean isPixelSet [][] = new boolean [BARS][PIXELS_PER_BAR];
      for (int b = 0; b < int(model.getSize().x); b++) {
        for (int p = 0; p < int(model.getSize().y); p++) isPixelSet[b][p] = false;
      }

      int pixelsRemoved = 0;  // holds the number of "growing pixels" that have been removed
                              // because they are no longer visible

      // loop through each "growing pixel" backwards to determine how to update model 
      for (int i = (this.growPixLoc.size()-1); i >= 0; i--) {

        // set the start and end positions of the current "growing pixel"
        int start_x = int(this.growPixLoc.get(i).x - (this.growPixSize.get(i).x / 2));
        int start_y = int(this.growPixLoc.get(i).y - (this.growPixSize.get(i).y / 2));
        int end_x = int(this.growPixLoc.get(i).x + (this.growPixSize.get(i).x / 2));
        int end_y = int(this.growPixLoc.get(i).y + (this.growPixSize.get(i).y / 2));
        if (start_x < 0) start_x = 0;
        if (start_y < 0) start_y = 0;

        // loop through each pixel from current "growing pixel" and process it
        boolean visible = false;
        for (int b = start_x; (b < end_x) && (b < int(model.getSize().x)); b++) {
          for (int p = start_y; (p < end_y) && (p < int(model.getSize().y)); p++) {
            // if pixel has not been set then set color, update isPixelSet array and set visible flag to true
            if (!isPixelSet[b][p]) {
              this.model.setPixelColor(b, p, this.activeColors.get(i));
              isPixelSet[b][p] = true;     
              visible = true;       
            }
          }
        }

        // if "growing pixel" is no longer visible then remove it from all arrays 
        if (!visible) {
          this.growPixLoc.remove(i);
          this.growPixSize.remove(i);
          this.activeColors.remove(i);
          pixelsRemoved ++;  // increment the pixelsRemoved counter
        } 

        // if "growing pixel" is visible then increase its size by 1 pixel in each direction
        else {
          this.growPixSize.get(i).y += 2;
          this.growPixSize.get(i).x += 2;
        }
      }

      // add new "pixels" for each one that is no longer visible
      for (int i = 0; i < pixelsRemoved; i++) {
        this.addNewPixel();
      }
      return true;
    }  
    return false;
  }

  /**
   * addNewPixel Adds a new pixel to the animation. Generates a random color and location, 
   *   and sets the starting size to 1x1 pixels.
   */
  void addNewPixel() {
    this.activeColors.add( color(random(0,255),random(0,255),random(0,255)) );
    this.growPixLoc.add( new PVector (int(random(0,BARS)), int(random(0,PIXELS_PER_BAR))) );
    this.growPixSize.add( new PVector (1 , 1) );      
  }
}



////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////
// CONTROL BASE CLASSES AND INTERFACES 
////////////////////////////////////////

/**
 * ControlUpdateColor Interface that is implemented by all classes that support
 *   updates to color using update methods that accept two and three arguments.
 * 
 */
interface ControlUpdateColor {
  void update(int _hue, int _sat, int _bri);
  void update(int _hsb, int _val);
}

/**
 * ControlUpdateWithBar Interface that is implemented by all classes that support
 *   update methods that accept two integers.
 * 
 */
interface ControlUpdateWithBar {
  void update (int _bar, int _val);
}

/**
 * ControlUpdate Interface that is implemented by all classes that support update
 *   methods that accept a single integer argument.
 * 
 */
interface ControlUpdate {
  void update (int _val);
}

/**
 * LedLampControl Base class for all LedLampControl classes. These classes are responsible for
 *   updating the data model to create animations and data visualizations. This base class
 *   defines the base variables, such as the model object and refresh time-related variables. 
 * 
 */
class LedLampControl {

  // Constants that hold color colorWheel 
  final int COLOR_ELEMENTS = 3;
  final int COLOR_RESOLUTION = 127;
  final int COLOR_WHEEL_SIZE = COLOR_ELEMENTS * COLOR_RESOLUTION;
  final float COLOR_WHEEL_STEP = 1f / float(COLOR_WHEEL_SIZE);
  final int MIN_INTERVAL = 60;  // minimum refresh interval between each refresh, in millis

  LedLamp model;  // holds link to the active data model

  float cycleOffset;

  long refreshTimeLast = millis();  // holds the last time that the model was updated
  int refreshTimeInterval = MIN_INTERVAL;    // holds the interval between each refresh, in millis

  /**
   * LedLampControl Constructor for the LedLampControl class that accepts a link to the active data model.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   * @param _refresh Time interval in millis between each model refresh
   */
  LedLampControl (LedLamp _model) {
    this.model = _model;
    this.cycleOffset = 0f;
  }

  /**
   * LedLampControl Constructor for the LedLampControl class that accepts a link to the active data model 
   *   and refresh time.
   *
   * @param _model Link to the active data model that is shared by the Control and View classes. 
   * @param _refresh Time interval in millis between each model refresh
   */
  LedLampControl (LedLamp _model, int _refresh) {
    this(_model);
    if (_refresh < MIN_INTERVAL) _refresh = MIN_INTERVAL;
    this.refreshTimeInterval = _refresh;
  }

  /**
   * update Prototype that will be defined by classes that inherit from the LedLampControl class.
   *   This method should be used to manage the updates to the model at a refresh rate that can be
   *   supported by the Data Bars (the maximum refresh rate is 16 times a second, every 60 millis).
   */
  boolean update() { return true; }

  /**
   * colorWheel Method that returns a color from the color colorWheel based on float argument that is 
   *   provided, ranging from 0.0 - 1.0. The colorWheel just loops through different hue values,
   *   the saturation, and brightness remains unchanged 100%.
   *
   * @param _hue_shift A value between 0.0 and 1.0 that is used to specify the location on the
   *                   color whose color should be returned. If the value is larger than 1, then 
   *                   the number will be reduced to its decimal point.
   */
  color colorWheel(float _hue_shift) {
    colorMode(HSB, 1.0);
    _hue_shift = _hue_shift - floor(_hue_shift);
    color newColor = color(_hue_shift, 1.0, 1.0);
    colorMode(RGB, 255);
    return newColor;
  }

  /**
   * colorWheel Method that cycles through each color in the color colorWheel. It gets the new color
   *   using the colorWheel method, and then it updates the cycleOffset variable to prepare for the next
   *   method call.
   */
  color colorWheel() {
    color newColor = colorWheel(cycleOffset);
    cycleOffset += COLOR_WHEEL_STEP;
    if (cycleOffset >= 1) cycleOffset -= 1;
    return newColor;
  }

}

