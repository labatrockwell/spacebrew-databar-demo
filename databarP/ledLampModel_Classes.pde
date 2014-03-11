class LedLamp {
	int leds_per_bar;
	ArrayList <LedBar> bars;
    boolean debug = false;

	LedLamp (int _bars, int _leds_per_bar) {
		if (debug) println("[LedBar:LedBar] creating matrix with: " + _bars + " bars " + _leds_per_bar);
		leds_per_bar = _leds_per_bar;

		bars = new ArrayList <LedBar> ();
		for (int i = 0; i < _bars; i++) {
			this.addBar();
		}
	}

	LedLamp (LedLamp _model) {
		this.clone(_model);
	}

	void clone (LedLamp _model) {
        int _bars = int(_model.getSize().x);
		leds_per_bar = int(_model.getSize().y);

		bars = new ArrayList <LedBar> ();
		for (int i = 0; i < _bars; i++) {
			this.addBar();
		}

		for ( int x = 0; x < int(_model.getSize().x) ; x ++ ) {
			for ( int y = 0; y < int(_model.getSize().y) ; y ++ ) {
				this.setPixelColor(x, y, _model.getPixelColor(x, y));
			}
		}
	}

	void addBar() {
		bars.add(new LedBar(leds_per_bar));

		if (debug) println("[LedLamp:setColor] adding new bar with " + leds_per_bar + " pixels");
	}

	void setPixelColor(int _bar, int _pixel, int r, int g, int b) {
		if (_bar >= bars.size()) return;
		if (_pixel >= bars.get(_bar).getLedCount()) return;
		if (debug) println("[LedLamp:setColor] setting bar: " + _bar + " pixel:" + _pixel + " to color r:" + r + " g:" + g + " b:" + b);
		bars.get(_bar).setColor(_pixel,r,g,b);
	}

	void setPixelColor(int _bar, int _pixel, color _color) {
		if (_bar >= bars.size()) return;
		if (_pixel >= bars.get(_bar).getLedCount()) return;
		if (debug) println("[LedLamp:setColor] setting bar: " + _bar + " pixel:" + _pixel + " to color:" + _color);
		bars.get(_bar).setColor(_pixel,_color);
	}	

	color getPixelColor (int _bar, int _pixel) {
		if (_bar >= bars.size()) return -1;
		if (debug) println("[LedLamp:getColor] getting color for bar: " + _bar + " pixel:" + _pixel);
		return bars.get(_bar).getColor(_pixel);
	}

	color [] getBarColor (int _bar) {
		if (_bar >= bars.size()) return null;
		color colorArray [] = new color [leds_per_bar];
		for ( int i = 0; i < leds_per_bar; i ++ ) {
			colorArray[i] = bars.get(_bar).getColor(i);
		}
		return colorArray;
	}

	PVector getSize() {
		return new PVector(bars.size(), leds_per_bar);
	}
}

class LedBar {
	int led_count;
	ArrayList <Led> leds;

	LedBar (int _led_count) {
		if (debug) println("[LedBar:LedBar] creating bar with:" + _led_count );
		led_count = _led_count;
		leds = new ArrayList <Led> ();

		for (int i = 0; i < led_count; i++) {
			leds.add(new Led());
		}
	}

	void setColor(int _pixel, int r, int g, int b) {
		if ( _pixel >= leds.size() ) return;
		if (debug) println("[LedBar:setColor] setting pixel:" + _pixel + " to color r:" + r + " g:" + g + " b:" + b);
		leds.get(_pixel).setColor(r,g,b);
	}

	void setColor(int _pixel, color _color) {
		if ( _pixel >= leds.size() ) return;
		if (debug) println("[LedBar:setColor] setting pixel:" + _pixel + " to color:" + _color);
		leds.get(_pixel).setColor(_color);
	}


	color getColor(int _pixel) {
		if ( _pixel >= leds.size() ) return -1;
		if (debug) println("[LedBar:getColor] getting color for pixel:" + _pixel);
		return leds.get(_pixel).getColor();
	}

	int getLedCount() {
		return leds.size();
	}
}

class Led {
	color colorLed; 

	Led () {
		colorLed = color(0,0,0);
	}

	Led (color _color) {
		colorLed = _color;
	}

	void setColor (int r, int g, int b) {
		colorLed = color(r,g,b);
	}

	void setColor (color _color) {
		colorLed = _color;
	}

	color getColor() {
		return colorLed;
	}
}
