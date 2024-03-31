import javax.swing.JOptionPane;
import processing.sound.*;
import java.io.FileWriter;
import java.io.IOException;
import java.io.StringWriter;
import java.io.PrintWriter;
import com.jogamp.newt.opengl.GLWindow;


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

void settings() {
  try {
    // TODO... we're disabling graphics acceleration?!
    if (platform == LINUX)
      System.setProperty("jogl.disable.openglcore", "true");
    size(displayWidth, displayHeight, P2D);
    //size(750, 1200, P2D);
    smooth(1);
    
    
    // Ugly, I know. But we're at the lowest level point in the program, so ain't
    // much we can do.
    PJOGL.setIcon("data/engine/img/icon.png");
  }
  catch (Exception e) {
    JOptionPane.showMessageDialog(null,"A fatal error has occurred: \n"+e.getMessage()+"\n"+e.getStackTrace(),"Timeway",1);
  }
}

@Override
protected PSurface initSurface() {
    PSurface s = super.initSurface();
    
    // Windows is annoying with maximised screens
    // So let's do this hack to make the screen maximised.
    boolean maximise = true;
    
    if (maximise) {
      if (platform == WINDOWS) {
        try {
          // Set maximised.
          Object o = surface.getNative();
          if (o instanceof GLWindow) {
            GLWindow window = (GLWindow)o;
            window.setMaximized(true, true);
          }
        }
        catch (Exception e) {
          sketch_openErrorLog(
              "Maximise error. This is a bug."
              );
        }
      }
    }
    s.setTitle("Timeway");
    s.setResizable(true);
    return s;
}

void sketch_openErrorLog(String mssg) {
  
  // Write the file
  try {
    FileWriter myWriter = new FileWriter(sketch_ERR_LOG_PATH);
    myWriter.write(mssg);
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

void sketch_openErrorLog(Exception e) {
  StringWriter sw = new StringWriter();
  PrintWriter pw = new PrintWriter(sw);
  e.printStackTrace(pw);
  String sStackTrace = sw.toString();
  
  String errMsg = 
  "Sorry! Timeway crashed :(\n"+
  "Please provide Neo_2222 with this error log, thanks <3\n\n\n"+
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
    
    // Are we running in Processing or as an exported application?
    File f1 = new File(sketchPath()+"/lib");
    sketch_showCrashScreen = f1.exists();
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
      if (sketch_showCrashScreen || sketch_FORCE_CRASH_SCREEN) {
        
        try {
          timewayEngine.engine();
        }
        catch (java.lang.OutOfMemoryError outofmem) {
          sketch_openErrorLog(
          "Sorry! Timeway has run out of memory! D:\n"+
          "Either: \n"+
          "You loaded a massive number of files from a folder\n"+
          "or\n"+
          "The OutOfMemoryError protection system failed. This could be a bug."
          );
          exit();
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
