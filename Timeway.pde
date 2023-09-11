import javax.swing.JOptionPane;
import processing.sound.*;
import java.io.FileWriter;   // Import the FileWriter class
import java.io.IOException;
import java.io.StringWriter;
import java.io.PrintWriter;


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
boolean sketch_showCrashScreen = false;
String sketch_ERR_LOG_PATH;

// TODO: Sorry ill put that in the engine code later.

void settings() {
  try {
    //System.setProperty("jogl.disable.openglcore", "true");
    size(displayWidth, displayHeight, P2D);
    //size(1500, 1000, P2D);
    smooth(1);
    PJOGL.setIcon("data/engine/img/icon.png");
  }
  catch (Exception e) {
    JOptionPane.showMessageDialog(null,"A fatal error has occurred: \n"+e.getMessage()+"\n"+e.getStackTrace(),"Timeway",1);
  }
}

void sketch_openErrorLog(Exception e) {
  
  StringWriter sw = new StringWriter();
  PrintWriter pw = new PrintWriter(sw);
  e.printStackTrace(pw);
  String sStackTrace = sw.toString();
  
  String errMsg = 
  "Sorry! Timeway crashed, an exception occured :(\n"+
  "Please provide Neo_2222 with this error log (only if it doesn't contain any personal information you don't want shared), thanks <3\n"+
  e.getClass().toString()+"\nMessage: \""+
  e.getMessage()+"\"\nStack trace:\n"+
  sStackTrace;
  
  // Write the file
  try {
    FileWriter myWriter = new FileWriter(sketch_ERR_LOG_PATH);
    myWriter.write(errMsg);
    myWriter.close();
  } catch (IOException e2) {}
  
  
  if (Desktop.isDesktopSupported()) {
    // Open desktop app with this snippet of code that I stole.
    try {
      Desktop desktop = Desktop.getDesktop();
      File myFile = new File(sketch_ERR_LOG_PATH);
      desktop.open(myFile);
    } 
    catch (IOException ex) {
    }
  }
}


// This is all the code you need to set up and start running
// the timeway engine.
void setup() {
    surface.setResizable(true);
    surface.setTitle("Timeway");
    background(0);
    
    // Are we running in Processing or as an exported application?
    File f1 = new File(sketchPath()+"/lib");
    File f2 = new File(sketchPath()+"/java");
    sketch_showCrashScreen = true;//f1.exists() && f2.exists();
    println("ShowcrashScreen: ", sketch_showCrashScreen);
    sketch_ERR_LOG_PATH = sketchPath()+"/data/error_log.txt";
    
    timewayEngine = new Engine(this);
}

void draw() {
  if (timewayEngine == null) {
    timewayEngine = new Engine(this);
  }
  else {
      // Show error message on crash
      if (sketch_showCrashScreen) {
        
        try {
          timewayEngine.engine();
        }
        catch (Exception e) {
          // Open a text document containing the error message
          sketch_openErrorLog(e);
          // Then shut it all down.
          exit();
        }
      }
      // Let it gracefully crash
      else timewayEngine.engine();
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
