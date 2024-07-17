import java.io.FileWriter;
import java.io.IOException;
import java.io.StringWriter;
import java.io.PrintWriter;

/**
*********** Timeway ************
* Explore your system files in a
* 3D retro world and create notes
* in a Onenote-like editor.
**/

Engine timewayEngine;
boolean sketch_showCrashScreen = false;
String sketch_ERR_LOG_PATH;

// Set to true if you want to show the error log like in an exported build
// rather than throw the error to processing (can be useful if you need more
// error info)
final boolean sketch_FORCE_CRASH_SCREEN = false;
final boolean sketch_MAXIMISE = false;

void settings() {
  try {
    // TODO... we're disabling graphics acceleration?!
    if (isLinux())
      System.setProperty("jogl.disable.openglcore", "true");
    size(displayWidth, displayHeight, P2D);
    //size(900, 1800, P2D);
    //size(750, 1200, P2D);
    smooth(1);
    
    
    // Ugly, I know. But we're at the lowest level point in the program, so ain't
    // much we can do.
    final String iconLocation = "data/engine/img/icon.png";
    File f = new File(sketchPath()+"/"+iconLocation);
    if (f.exists()) {
      setDesktopIcon(iconLocation);
    }
  }
  catch (Exception e) {
    minimalErrorDialog("A fatal error has occurred: \n"+e.getMessage()+"\n"+e.getStackTrace());
  }
}


void sketch_openErrorLog(String mssg) {
  
  // Write the file
  try {
    FileWriter myWriter = new FileWriter(sketch_ERR_LOG_PATH);
    myWriter.write(mssg);
    myWriter.close();
    println(mssg);
  } catch (IOException e2) {}
  
  openErrorLog();
}

void sketch_openErrorLog(Exception e) {
  StringWriter sw = new StringWriter();
  PrintWriter pw = new PrintWriter(sw);
  e.printStackTrace(pw);
  String sStackTrace = sw.toString();
  
  String errMsg = 
  "Sorry! "+Engine.APP_NAME+" crashed :(\n"+
  "Please provide Teo Taylor with this error log, thanks <3\n\n\n"+
  e.getClass().toString()+"\nMessage: \""+
  e.getMessage()+"\"\nStack trace:\n"+
  sStackTrace;
  
  sketch_openErrorLog(errMsg);
}


// This is all the code you need to set up and start running
// the timeway engine.
void setup() {
    hint(DISABLE_OPENGL_ERRORS);
    background(0);
    
    if (isAndroid()) {
      //orientation(LANDSCAPE);    
    }
    
    // Are we running in Processing or as an exported application?
    File f1 = new File(sketchPath()+"/lib");
    sketch_showCrashScreen = f1.exists();
    println("ShowcrashScreen: ", sketch_showCrashScreen);
    sketch_ERR_LOG_PATH = sketchPath()+"/data/error_log.txt";
    timewayEngine = new Engine(this);
    requestAndroidPermissions();
}

void draw() {
  if (timewayEngine == null) {
    timewayEngine = new Engine(this);
  }
  else {
      // Show error message on crash
      if (sketch_showCrashScreen || sketch_FORCE_CRASH_SCREEN) {
        
        try {
          // Run Timeway.
          timewayEngine.engine();
        }
        catch (java.lang.OutOfMemoryError outofmem) {
          sketch_openErrorLog(Engine.APP_NAME+" has run out of memory.");
          exit();
        }
        catch (Exception e) {
          // Open a text document containing the error message
          sketch_openErrorLog(e);
          // Then shut it all down.
          exit();
        }
      }
      
      // Run Timeway.
      else timewayEngine.engine();
  }
}


void keyPressed() {
  if (timewayEngine != null && timewayEngine.input != null) {
    timewayEngine.input.keyboardAction(key, keyCode);
    timewayEngine.input.lastKeyPressed     = key;
    timewayEngine.input.lastKeycodePressed = keyCode;

    // Begin the timer. This will automatically increment once it's != 0.
    timewayEngine.input.keyHoldCounter = 1;
  }
}


void keyReleased() {
    // Stop the hold timer. This will no longer increment.
  if (timewayEngine != null && timewayEngine.input != null) {
    timewayEngine.input.keyHoldCounter = 0;
    timewayEngine.input.releaseKeyboardAction(key, keyCode);
  }
  
}

void mouseWheel(MouseEvent event) {
  if (timewayEngine != null && timewayEngine.input != null) timewayEngine.input.rawScroll = event.getCount();
  //println(event.scrollAmount());
  //TODO: ifShiftDown is horizontal scrolling!
  //println(event.isShiftDown());
  //println(timewayEngine.rawScroll);
}

void outputFileSelected(File selection) {
  if (timewayEngine != null) {
    timewayEngine.file.outputFileSelected(selection);
  }
}

void mouseClicked() {
  if (timewayEngine != null && timewayEngine.input != null) timewayEngine.input.clickEventAction();
}
