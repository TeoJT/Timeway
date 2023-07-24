import javax.swing.JOptionPane;
import processing.sound.*;
/**
*********** Timeway ************
* Explore your system files in a
* 3D retro world and create notes
* in a Onenote-like editor.
**/


/*************************************************************************************
  IMPORTANT THING TO DO WHEN EXPORTING!!!
  
  - Export the application.
  - Go into the lib folder
  - Create a new folder called "windows64"
  - Move all .dll files and the "gstreamer1.0" folder into that new folder but NOT
    the .jar files
  - Hey presto it works!
*************************************************************************************/

Engine timewayEngine;

// TODO: Sorry ill put that in the engine code later.
SoundFile tempCoinSound;
SoundFile temp1upSound;
SoundFile tempPortalSound;
SoundFile tempMenuAppear;
SoundFile tempMenuSelect;
SoundFile tempShiftSound;
SoundFile tempIntroSound;
SoundFile tempJumpSound;
SoundFile tempPickupSound;

void settings() {
  try {
    //System.setProperty("jogl.disable.openglcore", "true");
    size(displayWidth, displayHeight, P2D);
    //size(1500, 1000, P2D);
    smooth(1);
    PJOGL.setIcon("data/engine/img/icon.png");
  }
  catch (Exception e) {
    JOptionPane.showMessageDialog(null,"A fatal error has occured: \n"+e.getMessage()+"\n"+e.getStackTrace(),"Timeway",1);
  }
}


// This is all the code you need to set up and start running
// the timeway engine.
void setup() {
    surface.setResizable(true);
    surface.setTitle("Timeway");
    
    
    background(0);
    textSize(32);
    textAlign(LEFT, TOP);
    text("Setting up", 10, 10);
    
    
    tempCoinSound = new SoundFile(this, "data/engine/sound/coin.wav");
    temp1upSound  = new SoundFile(this, "data/engine/sound/oneup.wav");
    tempPortalSound = new SoundFile(this, "data/engine/sound/portal.wav");
    tempMenuAppear = new SoundFile(this, "data/engine/sound/menu_appear.wav");
    tempMenuSelect = new SoundFile(this, "data/engine/sound/menu_select.wav");
    tempShiftSound = new SoundFile(this, "data/engine/sound/shift.wav");
    tempIntroSound = new SoundFile(this, "data/engine/sound/intro.wav");
    tempPickupSound = new SoundFile(this, "data/engine/sound/pickup.wav");
    tempJumpSound = new SoundFile(this, "data/engine/sound/jump.wav");
    
    timewayEngine = new Engine(this);
    tempPortalSound.amp(0.);
    tempPortalSound.loop();
        
}

void draw() {
  if (timewayEngine == null) {
    timewayEngine = new Engine(this);
  }
  else {
    timewayEngine.engine();
  }
    //saveFrame("saveframe/####.tiff");
}


// ... apart from this. This is just keyboard stuff because I'm still using
// processing in 2022 when I've learned way more stuff and know that processing
// prolly isn't the best system to use but heck it.
void keyPressed() {
  if (timewayEngine != null) {
    timewayEngine.keyboardAction(key, keyCode);
    timewayEngine.lastKeyPressed     = key;
    timewayEngine.lastKeycodePressed = keyCode;

    // Begin the timer. This will automatically increment once it's != 0.
    timewayEngine.keyHoldCounter = 1;
  }
  //println(int(key));
}


void keyReleased() {
    // Stop the hold timer. This will no longer increment.
  if (timewayEngine != null) {
    timewayEngine.keyHoldCounter = 0;
    timewayEngine.controlKeyPressed = false;
    //timewayEngine.lastKeyPressed = 0;
    timewayEngine.releaseKeyboardAction();
  }
}

void mouseWheel(MouseEvent event) {
  if (timewayEngine != null) timewayEngine.rawScroll = event.getCount();
  //println(event.scrollAmount());
  //TODO: ifShiftDown is horizontal scrolling!
  //println(event.isShiftDown());
  //println(timewayEngine.rawScroll);
}

void mouseClicked() {
  if (timewayEngine != null) timewayEngine.mouseEventClick = true;
}
