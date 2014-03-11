/**
 * 
 */
class LedLampViewHandler {

	final int MODELS = 2;
	final int SHARED = 0;
	final int VIEW = 1;

	LedLamp models [] = new LedLamp [MODELS];

	ArrayList <LedLampView>  views;

	boolean sendAll = false;
	boolean sendBar [];
	boolean sendPixels [][];
	int pixelsChanged [];

	LedLampViewHandler (LedLamp _model) {
		this.views = new ArrayList <LedLampView> ();
		this.models[SHARED] = _model;
		this.models[VIEW] = new LedLamp (_model);
		this.sendBar = new boolean[ int(models[SHARED].getSize().x) ];
		this.pixelsChanged = new int[ int(models[SHARED].getSize().x) ];
		this.sendPixels = new boolean[ int(models[SHARED].getSize().x) ] [ int(models[SHARED].getSize().y) ];
	}

	void add (LedLampView _view) {
		this.views.add(_view);
	}

	void show(int _index) {
		if (_index >= this.views.size()) return;
		this.views.get(_index).show();
	}

	void hide(int _index) {
		if (_index >= this.views.size()) return;
		this.views.get(_index).hide();        
	}

	boolean isVisible(int _index) {
		if (_index >= this.views.size()) return false;
		return this.views.get(_index).isVisible();
	}

	void initSendVars () {
		this.sendAll = false;
		for ( int x = 0; x < this.models[SHARED].getSize().x; x++ ) {
			this.sendBar[x] = false;
			this.pixelsChanged[x] = 0;
			for ( int y = 0; y < this.models[SHARED].getSize().y; y++ ) {
				this.sendPixels[x][y] = false;
			}
		}		
	}

	void compareModels () {
		this.initSendVars();

		for ( int x = 0; x < this.models[SHARED].getSize().x; x++ ) {
			for ( int y = 0; y < this.models[SHARED].getSize().y; y++ ) {
				if ( this.models[SHARED].getPixelColor(x, y) != this.models[VIEW].getPixelColor(x, y) ) {
					this.sendPixels[x][y] = true;
					this.pixelsChanged[x] += 1;
					this.models[VIEW].setPixelColor(x, y, this.models[SHARED].getPixelColor(x, y) );
				}
			}
		}

		int barsChanged = 0;
		for ( int x = 0; x < this.models[SHARED].getSize().x; x++ ) {
			if (this.pixelsChanged[x] > 9) {
				barsChanged += 1;
				this.sendBar[x] = true;
			} if (barsChanged > 2) {
				this.sendAll = true;
			}
		}

	}

	void draw() {

		this.compareModels();

		for (int i = 0; i < this.views.size(); i++) {

		    if ( this.views.get( i ) instanceof LedLampPhysicalUpdate ){
		    	LedLampPhysicalUpdate curView = (LedLampPhysicalUpdate) this.views.get( i );
				if (this.sendAll) {
					curView.draw();
					if (debug) println("[draw] draw all");
				}
				else {
					for (int b = 0; b < this.sendBar.length; b++) {
						if (this.sendBar[b]) {
							curView.drawBar(b);
							if (debug) println("[draw] draw bar "+ b);
						} else if (this.pixelsChanged[b] > 0) {
							if (debug) print("[draw] draw pixels ");
							for (int p = 0; p < this.sendPixels[b].length; p++) {
								if (this.sendPixels[b][p]) {
									if (debug) print("" + p + ", ");
									curView.drawPixel(b, p);
								}
							}
							if (debug) println();				
						}
					}
				}
		    }

		    else if ( this.views.get( i ) instanceof LedLampScreenUpdate ){
		    	LedLampScreenUpdate curView = (LedLampScreenUpdate) this.views.get( i );
		    	curView.draw();
		    }
		}
	}
}

class LedLampRenderingView extends LedLampView implements LedLampScreenUpdate {

	LedLampVirtualView dataBar;
	PVector rotation;
	PImage render;
	PVector loc;

	LedLampRenderingView (LedLamp _model, float loc_x, float loc_y, float pix_w, float pix_h, String img) {
		super(_model);
		loc = new PVector(loc_x, loc_y);
		dataBar = new LedLampVirtualView(_model, 763, 357, pix_w, pix_h); 
  		dataBar.rotation(182);
		this.rotation = new PVector (radians(0), radians(0), radians(0));
		println("path to file: "+ img);
	 	this.render = loadImage(img);
	}

	void rotation(float _rotation) {
		this.rotation.z = radians(_rotation % 360f);
	}

	void move(float _x, float _y) {
		this.loc = new PVector(_x, _y);
	}

	void draw() {
		if (!this.visible) return;
		pushMatrix();
		translate(this.loc.x, this.loc.y);
		rotate(this.rotation.z);
		dataBar.draw();
	        image(this.render, 0, 0);
		popMatrix();
	}

}


class LedLampVirtualView extends LedLampView implements LedLampScreenUpdate {
	PVector loc;
	PVector rotation;
	PVector pixelSize;
	PVector size;

	LedLampVirtualView (LedLamp _model, float loc_x, float loc_y, float pix_w, float pix_h) {
		super(_model);
		this.loc = new PVector (loc_x, loc_y);
		this.pixelSize = new PVector (pix_w, pix_h);
		this.rotation = new PVector (radians(0), radians(0), radians(270));
		this.size = new PVector((pix_w * this.model.getSize().x), (pix_h * this.model.getSize().y));
	}

	void rotation(float _rotation) {
		this.rotation.z = radians(_rotation % 360f);
	}

	void move(float _x, float _y) {
		this.loc = new PVector(_x, _y);
	}

	void draw() {
		if (!this.visible) return;

		pushMatrix();
		translate(this.loc.x, this.loc.y);
		rotate(this.rotation.z);
		int _width = int(this.model.getSize().x * this.pixelSize.x - this.pixelSize.x);
		for ( int x = 0; x < this.model.getSize().x; x++ ) {
			for ( int y = 0; y < this.model.getSize().y; y++ ) {
				int loc_x = _width - int(x * this.pixelSize.x);
				int loc_y = int(y * this.pixelSize.y);
				color cur_color = this.model.getPixelColor(x, y);
				fill(cur_color);
				rect(loc_x, loc_y, this.pixelSize.x, this.pixelSize.y);
			}
		}
		popMatrix();
	}
}


/**
 * LedLampPhysicalView The controller for the physical led lamp, which uses data from the LedLamp model
 * 		to keep the LedLamp updated.
 */
class LedLampPhysicalView extends LedLampView implements LedLampPhysicalUpdate {

	LedLampPhysicalView (LedLamp _model) {
		super(_model);
	}

	void draw() {
		if (!this.visible) return;

		this.startAllMsg();
		for (int k=0; k < 3; k++) {
			for (int i = 0; i < PIXELS_PER_BAR; i++) {
				this.setMultPixelColor(k, i, this.model.getPixelColor(k, i));
			}  
		}
		this.endMsg();
		this.showPixels();
	}

	void drawBar(int _bar) {
		if (!this.visible) return;
		if (_bar >= model.getSize().x) return;

	    this.startBarMsg(_bar);
	    for (int i = 0; i < PIXELS_PER_BAR; i++) {
	      this.setMultPixelColor(_bar, i, this.model.getPixelColor(_bar, i));
	    }  
	    this.endMsg();
		this.showPixels();
	}

	void drawPixel(int _bar, int _pixel) {
		if (!this.visible) return;
		if ( (_bar >= model.getSize().x) || (_pixel >= model.getSize().y)) return;

		setSinglePixelColor(_bar, _pixel, this.model.getPixelColor(_bar, _pixel));
		showPixels();
	}

	void showPixels() {
		byte [] msg = {
			byte(140)
		};
		if (debug) print("[showPixels] sending message:" );
		for (int i = 0; i < msg.length; i++) {
			arduino.connection.write(msg[i]);
			if (debug) print(int(msg[i]) + ",");
		}
		if (debug) println();
	}

	void setMultPixelColor(int _bar, int _pixel, color _color) {
		byte [] msg = {
			byte(red(_color)/2),
			byte(green(_color)/2),
			byte(blue(_color)/2)
		};

		if (debug) print("[setMultPixelColor] sending message:" );
		for (int i = 0; i < msg.length; i++) {
			arduino.connection.write(msg[i]);
			if (debug) print(int(msg[i]) + ",");
		}
	}

	void setSinglePixelColor(int _bar, int _pixel, color _color) {
		byte [] msg = {
			byte(128),
			byte(_bar),
			byte(_pixel),
			byte(129),
			byte(red(_color)/2),
			byte(green(_color)/2),
			byte(blue(_color)/2),
			byte(130)
		};

		if (debug) print("[setSinglePixelColor] sending message:" );
		for (int i = 0; i < msg.length; i++) {
			arduino.connection.write(msg[i]);
			if (debug) print(int(msg[i]) + ",");
		}
		if (debug) println();
	}

	void setShowSinglePixelColor(int _bar, int _pixel, color _color) {
		setSinglePixelColor(_bar, _pixel, _color);
		showPixels();
	}

	void startAllMsg() {
		byte msg = byte(132);
		arduino.connection.write(msg);
		if (debug) print("[startAllMsg] sending message: " );
		if (debug) println(int(msg));
	}

	void startBarMsg(int bar) {
		byte [] msg = {
			byte(133),
			byte(bar),
			byte(129)
		};
		if (debug) print("[startBarMsg] sending message:" );
		for (int i = 0; i < msg.length; i++) {
			arduino.connection.write(msg[i]);
			if (debug) print(int(msg[i]) + ",");
		}
		if (debug) println();
	}

	void endMsg() {
		byte msg = byte(130);
		arduino.connection.write(msg);
		if (debug) print("[endMsg] sending message: " );
		if (debug) println(int(msg));
	}

}


////////////////////////////////////////
// CONTROL BASE CLASSES AND INTERFACES 
////////////////////////////////////////

interface LedLampPhysicalUpdate {

	void draw();

	void drawBar(int _bar);

	void drawPixel(int _bar, int _pixel);	
}

interface LedLampScreenUpdate {

	void draw();

	void move(float _x, float _y);

	void rotation(float _rotation);
}

class LedLampView {

	LedLamp model;
	Boolean visible;

	LedLampView (LedLamp _model) {
		this.model = _model;
		this.visible = true;
	}

	void show() { 
		this.visible = true; 
	}

	void hide() { 
		this.visible = false; 
	}

	boolean isVisible() {
		return this.visible;
	}

}
