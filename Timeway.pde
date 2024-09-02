import java.io.FileWriter;
import java.io.IOException;
import java.io.StringWriter;
import java.io.PrintWriter;

/**
*********************************** Timeway ***********************************
*                      Your computer is your universe.
* 
* Visit https://teojt.github.io/timeway.html for more info on Timeway.
* 
* Here's the basics of Timeway's code:
* Timeway is split into "screens", which you can think of as mini-apps.
* The most significant of them all is the Pixel Realm (where all the 3d file 
* stuff is). There is also the Editor, and other miscellaneous screens in
* otherscreens.pde. 
* 
* Screens have their own states and variables which are cleared when the screen is
* no longer in use. All screens use Timeway's engine, which stores the entire 
* application's state and provides shared functions for all screens to access 
* (e.g. file management, sounds, displaying).
* 
* 
* Here's a quick rundown of what the other .pde files contain:
*
* messy.pde: Contains messy imported code from Sketchiepad that includes the sprite
* system (used for UI and draggable text and images in the editor).
*
* pixelrealm_ui: Simply adds UI functionality to the base PixelRealm class since
* having it all in one class would make it bloated and extremely difficult to 
* maintain.
*
* screen_startup: Screen that shows the Timeway logo and loading screen and does a 
* few startup stuff.
*
* zAndroid and zDesktop: Timeway is designed to work on both Desktop and Android using
* the same codebase. However, there are obviously some big differences between the two,
* and libraries that exist in Android mode simply don't exist for Java (desktop) mode
* and vice verca.
* The solution? Have two scripts for each version.
* When you switch to Android mode, uncomment all the code in zAndroid and comment zDeskstop.
* When you switch to Java mode, uncomment all the code in zDesktop and comment zAndroid.
* Probably the worst system ever, but we like to keep it simple instead of spending ages
* looking for another solution.
*
* Anyways, I have no idea who's reading this or who would delve into the code of Timeway,
* but if you're here reading this, then have fun!
*
*
*
* 
**/














TWEngine timewayEngine;
boolean sketch_showCrashScreen = false;
String sketch_ERR_LOG_PATH;

// Set to true if you want to show the error log like in an exported build
// rather than throw the error to processing (can be useful if you need more
// error info)
final boolean sketch_FORCE_CRASH_SCREEN = false;
final boolean sketch_MAXIMISE = true;

void settings() {
  try {
    // TODO... we're disabling graphics acceleration?!
    //if (isLinux())
    //  System.setProperty("jogl.disable.openglcore", "true");
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
    
    Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
        public void run() {
            shutdown();
        }
    }, "Shutdown-thread"));
    
  }
  catch (Exception e) {
    minimalErrorDialog("A fatal error has occurred: \n"+e.getMessage()+"\n"+e.getStackTrace());
  }
}

void shutdown() {
  timewayEngine.stats.save();
  timewayEngine.stats.set("last_closed", (int)(System.currentTimeMillis() / 1000L));
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
  "Sorry! "+TWEngine.APP_NAME+" crashed :(\n"+
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
    timewayEngine = new TWEngine(this);
    timewayEngine.startScreen(new Startup(timewayEngine));
    requestAndroidPermissions();
}

void draw() {
  if (timewayEngine == null) {
    timewayEngine = new TWEngine(this);
  }
  else {
      // Show error message on crash
      if (sketch_showCrashScreen || sketch_FORCE_CRASH_SCREEN) {
        
        try {
          // Run Timeway.
          timewayEngine.engine();
        }
        catch (java.lang.OutOfMemoryError outofmem) {
          sketch_openErrorLog(TWEngine.APP_NAME+" has run out of memory.");
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










// Because TWEngine is designed to be isolated from the rest of... well, Timeweay,
// there are some things that TWEngine needs to access that are external to the engine,
// and isolating it would mean those external dependancies wouldn't exist.
// These methods handle these external dependencies required by the engine through
// void methods
//@SuppressWarnings("unused")
void twengineRequestEditor(String path) {
  timewayEngine.requestScreen(new Editor(timewayEngine, path));
}

//@SuppressWarnings("unused")
void twengineRequestUpdater(JSONObject json) {
  timewayEngine.requestScreen(new Updater(timewayEngine, json));
}

//@SuppressWarnings("unused")
void twengineRequestBenchmarks() {
  //timewayEngine.requestScreen(new Updater(timewayEngine, json));
  //timewayEngine.requestScreen(new Benchmark(this));
}

@SuppressWarnings("unused")
void twengineRequestSketch(String path) {
  
}

//@SuppressWarnings("unused")
boolean hasPixelrealm() {
  return false;
}


//@SuppressWarnings("unused")
boolean pixelrealmCache() {
  boolean cacheHit = false;
  cacheHit |= timewayEngine.sound.cacheHit(timewayEngine.DEFAULT_DIR+"/"+PixelRealm.REALM_BGM+".wav");
  cacheHit |= timewayEngine.sound.cacheHit(timewayEngine.DEFAULT_DIR+"/"+PixelRealm.REALM_BGM+".ogg");
  cacheHit |= timewayEngine.sound.cacheHit(timewayEngine.DEFAULT_DIR+"/"+PixelRealm.REALM_BGM+".mp3");
  cacheHit |= timewayEngine.sound.cacheHit(timewayEngine.DEFAULT_DIR+"/"+timewayEngine.file.unhide(PixelRealm.REALM_BGM+".wav"));
  cacheHit |= timewayEngine.sound.cacheHit(timewayEngine.DEFAULT_DIR+"/"+timewayEngine.file.unhide(PixelRealm.REALM_BGM+".ogg"));
  cacheHit |= timewayEngine.sound.cacheHit(timewayEngine.DEFAULT_DIR+"/"+timewayEngine.file.unhide(PixelRealm.REALM_BGM+".mp3"));
  cacheHit |= timewayEngine.sound.cacheHit(timewayEngine.APPPATH+PixelRealm.REALM_BGM_DEFAULT);
  cacheHit |= timewayEngine.sound.cacheHit(timewayEngine.APPPATH+PixelRealm.REALM_BGM_DEFAULT_LEGACY);
  return cacheHit;
}
