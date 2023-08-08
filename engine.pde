import java.util.HashSet;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.io.FileOutputStream;
import java.awt.event.MouseWheelEvent;
import java.awt.event.MouseWheelListener;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.Transferable;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.awt.Toolkit;
import processing.video.Movie;
import org.freedesktop.gstreamer.*;
import java.util.TreeSet;

import java.util.ArrayList;
import java.util.List;

import com.sun.jna.Native;
import com.sun.jna.Structure;

// TODO: figure out a solution for multiplatform battery tracking.
// import com.sun.jna.win32.StdCallLibrary;

// Timeway's engine code.
// TODO: add documentation lmao.

class Engine {
    //*****************CONSTANTS SETTINGS**************************
    // Info and versioning
    public static final String NAME        = "Timeway";
    public static final String AUTHOR      = "Teo Taylor";
    public static final String VERSION     = "0.0.3";
    public static final String VERSION_DESCRIPTION = 
    "- Added world customisation \n"+
    "- Made sky move \n"+
    "- Added sounds \n"+
    "- Added music \n"+
    "- Added repositioning items in Pixel Realm \n"+
    "- Improved everything \n"+
    "- Added caching \n"+
    "- Added nice texturing to editor \n"+
    "- Fixed loads of bugs ";
    // ***************************
    // How versioning works:
    // a.b.c
    // a is just gonna stay 0 most of the time unless something significant happens
    // b is a super major release where the system has a complete overhaul.
    // c is pretty much every release whether that's bug fixes or other things.
    // a, b, and c can go well over 10, 100, it can be any positive integer.
    
    // Paths
    public final String ENTRIES_PATH        = "data/legacyentry/";
    public final String ENTRY_DEFAULT_NAME  = "entry";
    public final String CONSOLE_FONT        = "data/engine/font/SourceCodePro-Regular.ttf";
    public final String SND_NOPE            = "data/engine/sound/nope.wav";
    public final String IMG_PATH            = "data/engine/img/";
    public final String FONT_PATH           = "data/engine/font/";
    public final String SHADER_PATH         = "data/engine/shaders/";
    public final String CONFIG_PATH         = "data/config.json";
    public final String KEYBIND_PATH        = "data/keybindings.json";
    public final String PATH_SPRITES_ATTRIB = "data/engine/spritedata/";
    public final String DAILY_ENTRY         = "data/daily_entry.timewayentry";
    public final String GLITCHED_REALM      = "data/engine/default/glitched_realm/";
    public final String CACHE_INFO          = "data/cache/cache_info.json";
    public final String CACHE_PATH          = "data/cache/";
    
    // Static constants
    public static final int    KEY_HOLD_TIME       = 30; // 30 frames
    public static final int    POWER_CHECK_INTERVAL = 5000;  // Currently unused  TODO: remember to change this comment
    public static final int    PRESSED_KEY_ARRAY_LENGTH = 10;
    public static final String CACHE_COMPATIBILITY_VERSION = "0.1";
    public static final int    CACHE_SCALE_DOWN = 128;
    
    // Dynamic constants (changes based on things like e.g. configuration file)
    public       int    POWER_HIGH_BATTERY_THRESHOLD = 50;
    public       PFont  DEFAULT_FONT;
    public       String DEFAULT_DIR;
    public       String DEFAULT_FONT_NAME = "Typewriter";
    
    
    public final String ENTRY_EXTENSION = "timewayentry";
    

    //*************************************************************
    //**************ENGINE SETUP CODE AND VARIABLES****************
    // Core stuff
    public PApplet app;
    public String APPPATH;
    public String OSName;
    public int usingOS;
    public Console console;
    
    // Power modes
    public PowerMode powerMode = PowerMode.HIGH;
    public boolean noBattery = false;
    public boolean doNotExceed = false;
    public boolean sleepyMode = false;
    public boolean dynamicFramerate = true;
    public boolean powerSaver = false;
    public int lastPowerCheck = 0;
    //public Kernel32.SYSTEM_POWER_STATUS powerStatus;
    
    // Display system
    public float displayScale = 2.0;
    PImage errorImg;
    public HashMap<String, PImage> systemImages;
    public HashSet<String> loadedContent;
    public HashMap<String, PFont> fonts;
    public HashMap<String, PShader> shaders;
    public HashMap<String, SoundFile> sounds;
    public float WIDTH = 0, HEIGHT = 0;
    public int loadingFramesLength = 0;
    public int pastedImageCount = 0;
    public int lastFrameMillis = 0;
    public int thisFrameMillis = 0;
    
    // Screens
    public Screen currScreen;
    public Screen prevScreen;
    public boolean transitionScreens = false;
    public float transition = 0;
    public int transitionDirection = RIGHT;
    public boolean initialScreen = true;
    
    // Mouse & keyboard
    public boolean click = false;
    public boolean leftClick = false;
    public boolean rightClick = false;
    public boolean pressDown  = false;
    public boolean mouseDown = false;
    public boolean mouseEventClick = true;
    public float   rawScroll = 0;
    public float   scroll = 0;
    public float   scrollSensitivity = 30.0;             //TODO: scroll sensitivity from the config file.
    public boolean addNewlineWhenEnterPressed = true;
    public boolean noMove = false;
    public String keyboardMessage = "";
    public boolean controlKeyPressed = false;
    public boolean keyPressed = false;
    public boolean enterPressed = false;
    public char lastKeyPressed = 0;
    public int lastKeycodePressed = 0;
    public int keyHoldCounter = 0;
    public float clickStartX = 0;
    public float clickStartY = 0;
    public boolean pressedArray[] = new boolean[PRESSED_KEY_ARRAY_LENGTH];
    public char currentKeyArray[] = new char[PRESSED_KEY_ARRAY_LENGTH];
    public boolean shiftKeyPressed = false;
    
    // Settings & config
    public JSONObject settings;
    public JSONObject keybindings;
    public HashMap <String, Object> defaultSettings;
    public HashMap <String, Character> defaultKeybindings;
    public boolean devMode = false;
    
    // Save & load
    public SaveEntryProperties save;
    public PlaceholderReadEntryProperties read;
    public JSONArray loadedJsonArray;
    
    // Other / doesn't fit into any categories.
    public boolean wireframe;
    public SpriteSystemPlaceholder spriteSystemPlaceholder;
    public long lastTimestamp;
    public String lastTimestampName = null;
    public int timestampCount = 0;
    
    // *************************************************************
    // *********************Begin engine code***********************
    // *************************************************************
    public Engine(PApplet p) {
        // PApplet & engine init stuff
        app = p;
        app.background(0);
        APPPATH = app.sketchPath().replace('\\', '/')+"/";
        
        // Set the display scale; since I've been programming this with my Surface Book 2 at high density resolution,
        // the original display area is 1500x1000, so we simply divide this device's display resolution by 1500 to
        // get the scale.
        displayScale = app.width/1500.;
        WIDTH = app.width/displayScale;
        HEIGHT = app.height/displayScale;
        
        
        generateErrorImg();
        
        loadedContent = new HashSet<String>();
        systemImages = new HashMap<String, PImage>();
        fonts = new HashMap<String, PFont>();
        shaders = new HashMap<String, PShader>();
        sounds = new HashMap<String, SoundFile>();
        
        // First, load the logo and loading symbol.
        loadAsset(APPPATH+IMG_PATH+"logo.png");
        loadAllAssets(APPPATH+IMG_PATH+"loadingmorph/");
        
        
        // Console stuff
        console = new Console();
        console.info("Hello console");
        console.info("init: width/height set to "+str(WIDTH)+", "+str(HEIGHT));
        
        
        // Run the setup method in a seperate thread
        //Thread t = new Thread(new Runnable() {
        //    public void run() {
        //        setup();
        //    }
        //});
        //t.start();
        
        clearKeyBuffer();
        
        
        console.info("init: Running setup in main thread");
        setup();


        // Init loading screen.
        currScreen = new Startup(this);
    }
    
    public JSONObject loadConfig(String configPath, HashMap defaultConfig) {
        File f = new File(configPath);
        JSONObject returnSettings = null;
        boolean newConfig = false;
        if (!f.exists()) {
            newConfig = true;
        }
        else {
          try {
            returnSettings = loadJSONObject(configPath);
          }
          catch (RuntimeException e) {
            console.warn("There's an error in the config file. Loading default settings.");
            newConfig = true;
          }
        }
        
        // New config
        if (newConfig) {
            console.log("Config file not found, creating one.");
            returnSettings = new JSONObject();
            
            // Alphabetically sort the settings so that the config is a lil easier to configure.
            TreeSet<String> sortedSet = new TreeSet<String>(defaultConfig.keySet());
            
            for (String k : sortedSet) {
                if (defaultConfig.get(k) instanceof Boolean)
                  returnSettings.setBoolean(k, (boolean)defaultConfig.get(k));
                else if (defaultConfig.get(k) instanceof String)
                  returnSettings.setString(k, (String)defaultConfig.get(k));
                else if (defaultConfig.get(k) instanceof Float)
                  returnSettings.setFloat(k, (float)defaultConfig.get(k));
                else if (defaultConfig.get(k) instanceof Character) {
                  String s = "";
                  s += defaultConfig.get(k);
                  returnSettings.setString(k, s);
                }
            }
            
            try {
              saveJSONObject(returnSettings, configPath);
            }
            catch (RuntimeException e) {
              console.warn("Failed to save config.");
            }
        }
        return returnSettings;
    }

    public void setup() {
      
        loadEverything();
        
        //println("Running in seperate thread.");
        // Config file
        loadDefaultSettings();
        settings = loadConfig(APPPATH+CONFIG_PATH, defaultSettings);
        keybindings = loadConfig(APPPATH+KEYBIND_PATH, defaultKeybindings);
        
        
        scrollSensitivity = getSettingFloat("scrollSensitivity");
        dynamicFramerate = getSettingBoolean("dynamicFramerate");
        DEFAULT_FONT_NAME = getSettingString("defaultSystemFont");
        DEFAULT_DIR  = getSettingString("homeDirectory");
        currentDir  = DEFAULT_DIR;
        POWER_HIGH_BATTERY_THRESHOLD = int(getSettingFloat("lowBatteryPercent"));
        DEFAULT_FONT = getFont(DEFAULT_FONT_NAME);
        checkDevMode();
        
        String forcePowerMode = getSettingString("forcePowerMode");
        forcePowerModeEnabled = true;   // Temp set to true, if not enabled, it will reset to false.
        if (forcePowerMode.equals("HIGH"))
          forcedPowerMode = PowerMode.HIGH;
        else if (forcePowerMode.equals("NORMAL"))
          forcedPowerMode = PowerMode.NORMAL;
        else if (forcePowerMode.equals("SLEEPY"))
          forcedPowerMode = PowerMode.SLEEPY;
        else if (forcePowerMode.equals("MINIMAL")) {
          console.log("forcePowerMode set to MINIMAL, I wouldn't do that if I were you!");
          forcedPowerMode = PowerMode.MINIMAL;
        }
        // Anything else (e.g. "NONE")
        else {
          forcePowerModeEnabled = false;
        }
        
        
        // TODO: remove
        updateBatteryStatus();


        //spriteSystemPlaceholder = new SpriteSystemPlaceholder(this, APPPATH+PATH_SPRITES_ATTRIB+"gui/");

        // PlaceholderReadEntryProperties p = new PlaceholderReadEntryProperties(APPPATH+"data/entry/exampleentry");
    }
    
    public void clearKeyBuffer() {
      //Clear the key buffer, ready for us to press some nice keys.
      for (int i = 0; i < PRESSED_KEY_ARRAY_LENGTH; i++) {
        currentKeyArray[i] = 0;
        pressedArray[i] = false;
      }
    }
    
    public Runnable doWhenPromptSubmitted = null;
    public String promptText;
    public boolean inputPromptShown = false;
    
    public void beginInputPrompt(String prompt, Runnable doWhenSubmitted) {
      keyboardMessage = "";
      inputPromptShown = true;
      promptText = prompt;
      doWhenPromptSubmitted = doWhenSubmitted;
    }
    
    // TODO: obviously improve...
    public void displayInputPrompt() {
      if (inputPromptShown) {
        // this is such a placeholder lol
        app.noStroke();
        
        app.fill(255);
        app.textAlign(CENTER, CENTER);
        app.textSize(60);
        app.text(promptText, WIDTH/2, HEIGHT/2-100);
        app.textSize(30);
        app.text(keyboardMessage, WIDTH/2, HEIGHT/2);
        
        if (enterPressed) {
          // Remove enter character at end
          keyboardMessage = keyboardMessage.substring(0, keyboardMessage.length()-1);
          doWhenPromptSubmitted.run();
          enterPressed = false;
          inputPromptShown = false;
        }
      }
    }
    
    public boolean commandPromptShown = false;
    public void showCommandPrompt() {
      commandPromptShown = true;
      
      // Execute our command when the command is submitted.
      Runnable r = new Runnable() {
        public void run() {
          commandPromptShown = false;
          runCommand(keyboardMessage);
        }
      };
      
      beginInputPrompt("Enter command", r);
      keyboardMessage = "/";
    }
    
    private boolean commandEquals(String input, String expected) {
      int ind = input.indexOf(' ');
      if (ind <= -1) {
        ind = input.length();
      }
      else {
        if (ind >= input.length())  return false;
      }
      return (input.substring(0, ind).equals(expected));
    }
    
    
    public void runCommand(String command) {
      // TODO: have a better system for commands.
      if (command.equals("/powersaver")) {
        powerSaver = !powerSaver;
        forcePowerModeEnabled = false;
        if (powerSaver) console.log("Power saver enabled.");
        else {
          setPowerMode(PowerMode.NORMAL);
          forceFPSRecoveryMode();
          console.log("Power saver disabled.");
        }
      }
      else if (commandEquals(command, "/forcepowermode")) {
        // Count the number of characters, add one.
        // That's how you deal with substirng.
        String arg = "";
        if (command.length() > 16)
          arg = command.substring(16);
        
        forcePowerModeEnabled = true;   // Temp set to true, if not enabled, it will reset to false.
        if (arg.equals("HIGH")) {
          forcedPowerMode = PowerMode.HIGH;
          console.log("powermode forced to HIGH.");
        }
        else if (arg.equals("NORMAL")){
          forcedPowerMode = PowerMode.NORMAL;
          console.log("powermode forced to NORMAL.");
        }
        else if (arg.equals("SLEEPY")) {
          forcedPowerMode = PowerMode.SLEEPY;
          console.log("powermode forced to SLEEPY.");
        }
        else if (arg.equals("MINIMAL")) {
          console.log("forcePowerMode set to MINIMAL, I wouldn't do that if I were you!");
          forcedPowerMode = PowerMode.MINIMAL;
        }
        else {
          console.log("Invalid argument, options are: HIGH (60fps), NORMAL (30fps), SLEEPY (15fps).");
        }
      }
      else if (commandEquals(command, "/disableforcepowermode")) {
        console.log("Disabled forced powermode.");
        forcePowerModeEnabled = false;
      }
      else if (commandEquals(command, "/benchmark")) {
        int runFor = 180;
        String arg = "";
        if (command.length() > 11) {
          arg = command.substring(11);
          console.log(arg);
          runFor = int(arg);
        }
        
        beginBenchmark(runFor);
      }
      else if (commandEquals(command, "/debuginfo")) {
        // Toggle debug info
        console.debugInfo = !console.debugInfo;
        if (console.debugInfo) console.log("Debug info enabled.");
        else console.log("Debug info disabled.");
      }
      else if (command.length() <= 1) {
        // If empty, do nothing and close the prompt.
      }
      else if (currScreen.customCommands(command)) {
        // Do nothing, we just don't want it to return "unknown command" for a custom command.
      }
      else {
        console.log("Unknown command.");
      }
    }
    
    // TODO: Allow all os system fonts
    // PFont.list()
    public PFont getFont(String name) {
      PFont f = this.fonts.get(name);
      if (f == null) {
        console.warnOnce("Couldn't find font "+name+"!");
        // Idk just use this font as a placeholder instead.
        return createFont("Monospace", 128);
      }
      else return f;
    }
    
    
    public final int MAX_TIMESTAMPS = 1024;
    public boolean benchmark = false;
    public int timestampIndex = 0;
    public boolean finalBenchmarkFrame = false;
    public long[] benchmarkArray = new long[MAX_TIMESTAMPS];
    public long benchmarkFrames = 0;
    public ArrayList<String> benchmarkResults = new ArrayList<String>();
    public long benchmarkRunFor;
    
    public void beginBenchmark(int runFor) {
      benchmarkResults = new ArrayList<String>();
      benchmarkFrames = 0;
      benchmarkArray = new long[MAX_TIMESTAMPS];
      finalBenchmarkFrame = false;
      benchmark = true;
      this.benchmarkRunFor = (long)runFor;
      console.log("Benchmark started");
    }
    
    public void runBenchmark() {
      if (benchmark) {
        timestampIndex = 0;
        benchmarkFrames++;
        if (benchmarkFrames >= benchmarkRunFor) {
          if (!finalBenchmarkFrame) finalBenchmarkFrame = true;  // Order the timestamps to finalise the results
          else {
            console.log("Benchmark ended");
            benchmark = false;
            currScreen.requestScreen(new Benchmark(this));
          }
        }
      }
    }
    
    // Debugging function
    public void timestamp() {
      timestamp("t"+str(timestampCount++));
    }
    
    // custom fps function that gets the fps depending on the
    // time between the last frame and the current frame.
    public float getLiveFPS() {
      float fps = 60;
      switch (powerMode) {
          case HIGH:
          fps = 60.;
          break;
          case NORMAL:
          fps = 30.;
          break;
          case SLEEPY:
          fps = 15.;
          break;
          case MINIMAL:
          fps = 1.;
          break;
      }
      float timeframe = 1000/fps;
      
      return (timeframe/float(thisFrameMillis-lastFrameMillis))*fps;
    }
    
    
    // This is a debug function used for measuring performance at certain points.
    public void timestamp(String name) {
      if (!benchmark) {
        long nanoCapture = System.nanoTime();
        if (lastTimestampName == null) {
          String out = name+" timestamp captured.";
          if (console != null) console.info(out);
          else println(out);
        }
        else {
          String out = lastTimestampName+" - "+name+": "+str((nanoCapture-lastTimestamp)/1000)+"microseconds";
          if (console != null) console.info(out);
          else println(out);
        }
        lastTimestampName = name;
        lastTimestamp = nanoCapture;
      }
      else {
        long nanoCapture = System.nanoTime();
        benchmarkArray[timestampIndex++] += (nanoCapture-lastTimestamp)/1000;
        lastTimestamp = nanoCapture;
        
        if (finalBenchmarkFrame) {
          // Calculate the average for that timestamp.
          long results = benchmarkArray[timestampIndex-1] /= benchmarkFrames;
          String mssg = lastTimestampName+" - "+name+": "+str(results)+"microseconds";
          benchmarkResults.add(mssg);
          lastTimestampName = name;
        }
      }
    }
    
    public class NoBattery extends RuntimeException {
      public NoBattery(String message) {
        super(message);
      }
    }
    
    public void updateBatteryStatus() {
      //powerStatus = new Kernel32.SYSTEM_POWER_STATUS();
      //Kernel32.INSTANCE.GetSystemPowerStatus(powerStatus);
    }
    
    public int batteryPercentage() throws NoBattery {
      //String str = powerStatus.getBatteryLifePercent();
      String str = "100";
      str = str.substring(0, str.length()-1);
      try{
            int percent = Integer.parseInt(str);
            return percent;
      }
      catch (NumberFormatException ex){
          throw new NoBattery("Battery not found..? ("+str+")");
      }
    }
    
    public boolean isCharging() {
      //return (powerStatus.getACLineStatusString().equals("Online"));
      return false;
    }
    
    private void updatePowerModeNow() {
      lastPowerCheck = millis();
    }
    
    public void setSleepy() {
      if (dynamicFramerate) {
        if (!isCharging() && !noBattery && !sleepyMode) {
          sleepyMode = true;
          lastPowerCheck = millis()+POWER_CHECK_INTERVAL;
        }
      }
      else {
        sleepyMode = false;
      }
    }
    
    // You shouldn't call this every frame
    public void setAwake() {
      sleepyMode = false;
      if (fpsTrackingMode == SLEEPY) {
        putFPSSystemIntoGraceMode();
        updatePowerModeNow();
      }
    }
    
    private int powerModeSetTimeout = 0;
    public void setPowerMode(PowerMode m) {
      // Really just a debugging message to keep you using it appropriately.
      //if (powerModeSetTimeout == 1)
      //  console.warnOnce("You shouldn't call setPowerMode on every frame, otherwise Timeway will seriously stutter.");
      //powerModeSetTimeout = 2;
      // Only update if it's not already set to prevent a whole load of bugs
      if (powerMode != m) {
        powerMode = m;
        switch (m) {
          case HIGH:
          frameRate(60);
          //console.log("Power mode HIGH");
          break;
          case NORMAL:
          frameRate(30);
          //console.log("Power mode NORMAL");
          break;
          case SLEEPY:
          frameRate(15);
          //console.log("Power mode SLEEPY");
          break;
          case MINIMAL:
          frameRate(1); //idk for now
          //console.log("Power mode MINIMAL");
          break;
        }
        redraw();
      }
    }
    
    final int MONITOR = 1;
    final int RECOVERY = 2;
    final int SLEEPY = 3;
    final int GRACE  = 4;
    int fpsTrackingMode = MONITOR;
    float fpsScore = 0.;
    float scoreDrain = 1.;
    float recoveryScore = 1.;
    
    // The score that seperates the stable fps from the unstable fps.
    // If you've got half a brain, it would make the most sense to keep it at 0.
    final float FPS_SCORE_MIDDLE = 0.;
    
    // If the framerate is unstable, we "accelerate" draining of the score using this value.
    // Think of it as acceleration rather than speed.
    final float UNSTABLE_CONSTANT = 2.5;
    
    // Once we reach this score, we drop down to the previous frame.
    final float FPS_SCORE_DROP = -3000;
    
    // If we gradually manage to make it to that score, we can go into RECOVERY mode to test what the framerate's like
    // up a level.
    final float FPS_SCORE_RECOVERY = 200.;
    
    // We want to recover to a higher framerate only if we're able to achieve a pretty good framerate.
    // The higher you make RECOVERY_NEGLIGENCE, the more it will neglect the possibility of recovery.
    // For example, trying to achieve 60fps but actual is 40fps, the system will likely recover faster if
    // RECOVERY_NEGLIGENCE is set to 1 but very unlikely if it's set to something higher like 5.
    final float RECOVERY_NEGLIGENCE = 5;    
    
    PowerMode prevPowerMode = PowerMode.HIGH;
    int recoveryFrameCount = 0;
    int graceTimer = 0;
    int recoveryPhase = 1;
    float framerateBuffer[];
    public boolean forcePowerModeEnabled = false;
    public PowerMode forcedPowerMode = PowerMode.HIGH;
    
    // basically use when you expect a significant difference in fps from that point forward.
    public void forceFPSRecoveryMode() {
      fpsScore = FPS_SCORE_MIDDLE;
      fpsTrackingMode = RECOVERY;
      recoveryFrameCount = 0;
      // Record the next 5 frames.
      framerateBuffer = new float[5];
      recoveryPhase = 1;
    }
    
    // use before you expect a sudden delay, e.g. loading something during runtime or switching screens.
    // We basically are telling the fps system to pause its score tracking as the average framerate drops.
    public void putFPSSystemIntoGraceMode() {
      fpsTrackingMode = GRACE;
      graceTimer = 0;
    }
    
    // Similar to putFPSSystemIntoGraceMode() but reset the score.
    // Use when you expect a different average fps, e.g. switching screens.
    // We are telling the fps system to pause so the average framerate can fill up,
    // and then reset the score so it can fairly decide what fps the new scene/screen/whatever
    // should run in.
    public void resetFPSSystem() {
      putFPSSystemIntoGraceMode();
      fpsScore = FPS_SCORE_MIDDLE;
      scoreDrain = 1.;
      recoveryScore = 1.;
    }
    
    public void updatePowerMode() {
      // Just so we can provide a warning lol
      powerModeSetTimeout = max(0, powerModeSetTimeout-1);
      
      // Rules:
      // If plugged in or no battery, have it running at POWER_MODE_HIGH by default.
      // If on battery, the rules are as follows:
      // - POWER_MODE_HIGH    60fps
      // - POWER_MODE_NORMAL  30fps
      // - POWER_MODE_SLEEPY  15 fps
      // - POWER_MODE_MINIMAL loop is turned off
      
      // - POWER_MODE_HIGH if power is above 30% and average fps over 2 seconds is over 58
      // - POWER_MODE_NORMAL stays in 
      // - POWER_MODE_SLEEPY if 30% or below and window isn't focussed
      // - POWER_MODE_MINIMAL if minimised
      // 
      // Go into 1fps mode
      
      // If the window is not focussed, don't even bother doing anything lol.
      
      if (focused) {
        if (!focusedMode) {
          setPowerMode(prevPowerMode);
          focusedMode = true;
          putFPSSystemIntoGraceMode();
        }
      }
      else {
        if (focusedMode) {
          prevPowerMode = powerMode;
          setPowerMode(PowerMode.MINIMAL);
          focusedMode = false;
        }
        return;
      }
      
      if (millis() > lastPowerCheck) {
          lastPowerCheck = millis()+POWER_CHECK_INTERVAL;
        
        // If we specifically requested slow, then go right ahead.
        if (powerSaver || sleepyMode) {
          prevPowerMode = powerMode;
          fpsTrackingMode = SLEEPY;
          setPowerMode(PowerMode.SLEEPY);
        }
        //if (!isCharging() && !noBattery && sleepyMode) {
        //  prevPowerMode = powerMode;
        //  fpsTrackingMode = SLEEPY;
        //  setPowerMode(PowerMode.SLEEPY);
        //  return;
        //}
        
        // TODO: run in seperate thread to prevent stutters. For the time being I'm only gonna
        // run it once.
        updateBatteryStatus();
      }  
    
    // If forced power mode is enabled, don't bother with the powermode selection algorithm below.
    if (forcePowerModeEnabled) {
      if (powerMode != forcedPowerMode) setPowerMode(forcedPowerMode);
      return;
    }
    
    if (powerSaver || sleepyMode) return;
      
    // How the fps algorithm works:
    /*
    There are 4 modes:
    MONITOR:
    - Use average framerate to determine framepoints.
    - If the framerate is below the minimum required framerate, exponentially drain the score
      until the framerate is stable or the drop zone has been reached.
    - If in the unstable zone, linearly recover the score.
    - If in the stable zone, increase the score by the recovery likelyhood (((30-framepoints)/30)**2) 
      but only if we're lower than HIGH power mode. Otherwise max out at the stable threshold.
    - If we reach the drop threshold, drop the power mode down a level and take note of the recovery likelyhood (((30-framepoints)/30)**2)
      and reset the score to the stable threshold.
    - If we reach the recovery threshold, enter fps recovery mode and go up a power level.
    RECOVERY:
    - Don't keep track of score.
    - Use the real-time fps to take a small average of the current frame.
    - Once the average buffer is filled, use the average fps to determine whether we stay in this power mode or drop back.
      - Framerate at least 58, 28 etc, stay in this mode and go back into monitor mode, and reset the score to the stable threshold.
      - Otherwise, update recovery likelyhood and drop back.
    SLEEPY:
    - If sleepy mode is enabled, the score is paused and we don't do any operations;
      Wait until sleepy mode is disabled.
    GRACE:
    - A grace period where the score is not changed for a certain amount of time to allow the average framerate to fill up.
    - Once the grace period ends, return to MONITOR mode.
    */
    
    float stableFPS = 30.;
    int n = 1;
    switch (powerMode) {
      case HIGH:
      stableFPS = 57.;
      n = 1;
      break;
      case NORMAL:
      stableFPS = 27;
      n = 2;
      break;
      case SLEEPY:
      stableFPS = 13.;
      n = 4;
      break;
      // We shouldn't need to come to this but hey, this is a 
      // switch statement.
      case MINIMAL:
      stableFPS = 1.;
      break;
    }
    
        if (fpsTrackingMode == MONITOR) {
    // Everything in monitor will take twice or 4 times long if the framerate is lower.
          for (int i = 0; i < n; i++) {
            if (frameRate < stableFPS) {
                //console.log("Drain");
                scoreDrain += (stableFPS-frameRate)/stableFPS;
                fpsScore -= scoreDrain*scoreDrain;
                //console.log(str(scoreDrain*scoreDrain));
                //console.log(str(fpsScore));
            }
            else {
              scoreDrain = 0.;
              // If in stable zone...
              if (fpsScore > FPS_SCORE_MIDDLE) {
                //console.log("stable zone");
                
                if (powerMode != PowerMode.HIGH)
                  fpsScore += recoveryScore;
                
                //console.log(str(recoveryScore));
              }
              // If in unstable zone...
              else {
                fpsScore += UNSTABLE_CONSTANT;
              }
            }
            
            if (fpsScore < FPS_SCORE_DROP) {
              //console.log("DROP");
              // The lower our framerate, the less likely (or rather longer it takes) to get back to it.
              recoveryScore = pow((frameRate/stableFPS), RECOVERY_NEGLIGENCE);
              // Reset the score.
              fpsScore = FPS_SCORE_MIDDLE;
              scoreDrain = 0.;
              
              // Set the power mode down a level.
              switch (powerMode) {
                case HIGH:
                setPowerMode(PowerMode.NORMAL);
                break;
                case NORMAL:
                setPowerMode(PowerMode.SLEEPY);
                // Because sleepy is a pretty low framerate, chances are we just hit a slow
                // spot and will speed up soon. Let's give ourselves a bit more recoveryScore
                // so that we're not stuck slow forever.
                //recoveryScore += 1;
                break;
                case SLEEPY:
                break;
                case MINIMAL:
                // This is not a power level we downgrade to.
                // We shouldn't downgrade here, but if for whatever reason we're glitched out
                // and stuck in this mode, get ourselves out of it.
                setPowerMode(PowerMode.SLEEPY);
                fpsScore = FPS_SCORE_MIDDLE;
                break;
              }
            }
            
            if (fpsScore > FPS_SCORE_RECOVERY) {
              //console.log("RECOVERY");
              switch (powerMode) {
                case HIGH:
                // We shouldn't reach this here, but if we do, cap the
                // score.
                fpsScore = FPS_SCORE_RECOVERY;
                break;
                case NORMAL:
                setPowerMode(PowerMode.HIGH);
                break;
                case SLEEPY:
                setPowerMode(PowerMode.NORMAL);
                break;
                case MINIMAL:
                // This is not a power level we upgrade to.
                // We shouldn't downgrade here, but if for whatever reason we're glitched out
                // and stuck in this mode, get ourselves out of it.
                setPowerMode(PowerMode.SLEEPY);
                break;
              }
              fpsScore = FPS_SCORE_MIDDLE;
              fpsTrackingMode = RECOVERY;
              recoveryFrameCount = 0;
              // Record the next 5 frames.
              framerateBuffer = new float[5];
              recoveryPhase = 1;
            }
          }
        }
        else if (fpsTrackingMode == RECOVERY) {
          // Record the fps, as long as we're not waiting to go back into MONITOR mode.
          if (recoveryPhase != 3)
            framerateBuffer[recoveryFrameCount++] = getLiveFPS();
            
          // Once we're done recording...
          int l = framerateBuffer.length;
          if (recoveryFrameCount >= l) {
            
            // Calculate the average framerate.
            float total = 0.;
            for (int j = 0; j < l; j++) {
              total += framerateBuffer[j];
            }
            float avg = total/float(l);
            //console.log("Recovery average: "+str(avg));
            
            // If the framerate is at least 90%..
            if (recoveryPhase == 1 && avg/stableFPS >= 0.9) {
              //console.log("Recovery phase 1");
              // Move on to phase 2 and get a little more data.
              recoveryPhase = 2;
              recoveryFrameCount = 0;
              framerateBuffer = new float[30];
            }
            
            // If the framerate is at least the minimum stable fps.
            else if (recoveryPhase == 2 && avg >= stableFPS) {
              //console.log("Recovery phase 2");
              // Now wait a bit before going back to monitor.
              graceTimer = 0;
              recoveryFrameCount = 0;
              fpsTrackingMode = GRACE;
            }
            // Otherwise drop back to the previous power mode.
            else {
              //console.log("Drop back");
              switch (powerMode) {
                  case HIGH:
                  setPowerMode(PowerMode.NORMAL);
                  break;
                  case NORMAL:
                  setPowerMode(PowerMode.SLEEPY);
                  break;
                  case SLEEPY:
                  // Minimum power level, do nothing here.
                  // Hopefully framerates don't get that low.
                  break;
                  case MINIMAL:
                  // This is not a power level we downgrade to.
                  // We shouldn't downgrade here, but if for whatever reason we're glitched out
                  // and stuck in this mode, get ourselves out of it.
                  setPowerMode(PowerMode.SLEEPY);
                  fpsScore = FPS_SCORE_MIDDLE;
                  break;
              }
              recoveryScore = pow((avg/stableFPS), RECOVERY_NEGLIGENCE);
              fpsTrackingMode = MONITOR;
            }
          }
        }
        else if (fpsTrackingMode == SLEEPY) {
          
        }
        else if (fpsTrackingMode == GRACE) {
          graceTimer++;
          if (graceTimer > (240/n))
            fpsTrackingMode = MONITOR;
        }
        //console.log(str(fpsScore));
    }

    public void checkDevMode() {
        if (getSettingBoolean("forceDevMode")) {
            if (getSettingBoolean("repressDevMode")) {
                console.warn("Wut. Dev mode is both forced and repressed. Enabling by default.");
            }
            devMode = true;
            console.log("Dev mode enabled by config.");
            return;
        }

        String path = "just a sample string so the length isn't zero lol amongus.";
        try {
            path = (new File(Engine.class.getProtectionDomain().getCodeSource().getLocation().toURI()).getPath());
        }
        catch (Exception e) {
            devMode = false;
            console.warn("Couldn't check dev mode, disabling by default.");
        }

        // Check if the last characters of path is "/timeway/out"
        if (path.substring(path.length()-12).equals("/timeway/out")) {

            if (getSettingBoolean("repressDevMode")) {
                devMode = false;
                console.log("Dev mode disabled by config.");
                return;
            }
            else {
                console.log("Dev mode enabled.");
                devMode = true;
            }
            
        }
        else {
            devMode = false;
        }

    }

    public void loadEverything() {


        // load everything else.
        loadAllAssets(APPPATH+IMG_PATH);
        loadAllAssets(APPPATH+FONT_PATH);
        loadAllAssets(APPPATH+SHADER_PATH);

        // Find out how many images there are in loadingmorph
        File f = new File(APPPATH+IMG_PATH+"loadingmorph/");
        loadingFramesLength = f.listFiles().length;

    }

    public void generateErrorImg() {
        errorImg = app.createImage(32, 32, RGB);
        errorImg.loadPixels();
        for (int i = 0; i < errorImg.pixels.length; i++) {
            errorImg.pixels[i] = color(255, 0, 0);
        }
        errorImg.updatePixels();
    }

    public boolean getSettingBoolean(String setting) {
        boolean b = false;
        try {
            b = settings.getBoolean(setting);
        }
        catch (NullPointerException e) {
            if (defaultSettings.containsKey(setting)) {
                b = (boolean)defaultSettings.get(setting);
            }
            else {
                console.warnOnce("Setting "+setting+" does not exist.");
                return false;
            }
        }
        return b;
    }
    
    public float getSettingFloat(String setting) {
        float f = 0.0;
        try {
          f = settings.getFloat(setting);
        }
        catch (RuntimeException e) {
            if (defaultSettings.containsKey(setting)) {
                f = (float)defaultSettings.get(setting);
            }
            else {
                console.warnOnce("Setting "+setting+" does not exist.");
                return 0.;
            }
        }
        return f;
    }
    
    public String getSettingString(String setting) {
        String s = "";
        s = settings.getString(setting);
        if (s == null) {
            if (defaultSettings.containsKey(setting)) {
                s = (String)defaultSettings.get(setting);
            }
            else {
                console.warnOnce("Setting "+setting+" does not exist.");
                return "";
            }
        }
        return s;
    }

    public final int LEFT_CLICK = 1;
    public final int RIGHT_CLICK = 2;
    public void loadDefaultSettings() {
        defaultSettings = new HashMap<String, Object>();
        defaultSettings.putIfAbsent("forceDevMode", false);
        defaultSettings.putIfAbsent("repressDevMode", false);
        defaultSettings.putIfAbsent("fullscreen", false);
        defaultSettings.putIfAbsent("scrollSensitivity", 20.0);
        defaultSettings.putIfAbsent("dynamicFramerate", true);
        defaultSettings.putIfAbsent("lowBatteryPercent", 50.0);
        defaultSettings.putIfAbsent("autoScaleDown", true);
        defaultSettings.putIfAbsent("defaultSystemFont", "Typewriter");
        defaultSettings.putIfAbsent("homeDirectory", System.getProperty("user.home").replace('\\', '/'));
        defaultSettings.putIfAbsent("forcePowerMode", "NONE");
        
        defaultKeybindings = new HashMap<String, Character>();
        defaultKeybindings.putIfAbsent("CONFIG_VERSION", char(1));
        defaultKeybindings.putIfAbsent("moveForewards", 'w');
        defaultKeybindings.putIfAbsent("moveBackwards", 's');
        defaultKeybindings.putIfAbsent("moveLeft", 'a');
        defaultKeybindings.putIfAbsent("moveRight", 'd');
        defaultKeybindings.putIfAbsent("lookLeft", 'q');
        defaultKeybindings.putIfAbsent("lookRight", 'e');
        defaultKeybindings.putIfAbsent("menu", '\n');
        defaultKeybindings.putIfAbsent("menuSelect", '\t');
        defaultKeybindings.putIfAbsent("jump", ' ');
        defaultKeybindings.putIfAbsent("sneak", char(0x0F));
        defaultKeybindings.putIfAbsent("dash", 'r');
        defaultKeybindings.putIfAbsent("scaleUp", '=');
        defaultKeybindings.putIfAbsent("scaleDown", '-');
        defaultKeybindings.putIfAbsent("scaleUpSlow", '+');
        defaultKeybindings.putIfAbsent("scaleDownSlow", '_');
        defaultKeybindings.putIfAbsent("primaryAction", char(LEFT_CLICK));
        defaultKeybindings.putIfAbsent("secondaryAction", char(RIGHT_CLICK));
        defaultKeybindings.putIfAbsent("inventorySelectLeft", ',');
        defaultKeybindings.putIfAbsent("inventorySelectRight", '.');
        defaultKeybindings.putIfAbsent("scaleDownSlow", '_');
        defaultKeybindings.putIfAbsent("showCommandPrompt", '/');
    }
    //*************************************************************
    //*************************************************************
    //*******************LITERALLY EVERY CLASS*********************
    //*********************Console class***************************
    // Literally copied right from sketchiepad.
    // Probably gonna be hella messy code.
    // But oh well.
    class Console {
  
        private ConsoleLine[] consoleLine;
        int timeout = 0;
        final static int messageDelay = 60;
        final static int totalLines = 60;
        final static int displayLines = 20;
        private int initialPos = 0;
        private boolean force = false;
        public boolean debugInfo = false;
        PFont consoleFont;
        public BasicUI basicui;
        private boolean enableBasicUI = false;
        
        private class ConsoleLine {
            private int interval = 0;
            private int pos = 0;
            private String message;
            private color messageColor;
            
            public ConsoleLine() {
            messageColor = color(255,255);
            interval = 0;
            this.message = "";
            this.pos = initialPos;
            basicui = new BasicUI();
            }

            public void enableUI() {
            enableBasicUI = true;
            }

            public void disableUI() {
            enableBasicUI = false;
            }
            
            public void move() {
            this.pos++;
            }
            
            public int getPos() {
            return this.pos;
            }
            
            public boolean isBusy() {
            return (interval > 0);
            }
            
            public void kill() {
            interval = 0;
            }
            
            public void message(String message, color messageColor) {
            this.pos = 0;
            this.interval = 200;
            this.message = message;
            this.messageColor = messageColor;
            }
            
            public void display() {
            app.textFont(consoleFont);
            if (force) {
                if (interval > 0) {
                interval--;
                }
                
                int ypos = pos*32;
                noStroke();
                fill(0);
                int recWidth = int(WIDTH/2.);
                if (recWidth < textWidth(this.message)) {
                recWidth = (int)textWidth(this.message)+10;
                }
                app.rect(0, ypos, recWidth, 32);
                app.textSize(24);
                app.textAlign(LEFT);
                app.fill(this.messageColor);
                app.text(message, 5, ypos+20);
            }
            else {
                if (interval > 0 && pos < displayLines) {
                interval--;
                int ypos = pos*32;
                app.noStroke();
                if (interval < 60) {
                    fill(0, 4.25*float(interval));
                }
                else {
                    fill(0);
                }
                int recWidth = int(WIDTH/2.);
                if (recWidth < app.textWidth(this.message)) {
                    recWidth = (int)app.textWidth(this.message)+10;
                }
                app.rect(0, ypos, recWidth, 32);
                app.textSize(24);
                app.textAlign(LEFT);
                if (interval < 60) {
                    app.fill(this.messageColor, 4.25*float(interval));
                }
                else {
                    app.fill(this.messageColor);
                }
                app.text(message, 5, ypos+20);
                }
            }
            }
        }
        
        public Console() {
            this.consoleLine = new ConsoleLine[totalLines];
            this.generateConsole();
            
            consoleFont = createFont(APPPATH+CONSOLE_FONT, 24);
            if (consoleFont == null) {
                consoleFont = createFont("Monospace", 24);
            }
            if (consoleFont == null) {
                consoleFont = createFont("Courier", 24);
            }
            if (consoleFont == null) {
                consoleFont = createFont("Ariel", 24);
            }
        }
        
        private void generateConsole() {
            for (int i = 0; i < consoleLine.length; i++) {
            consoleLine[i] = new ConsoleLine();
            this.initialPos++;
            }
        }
        
        public void enableDebugInfo() {
            this.debugInfo = true;
            this.info("Extra debug info enabled.");
        }
        public void disableDebugInfo() {
            this.debugInfo = false;
        }
        
        private void killLines() {
            for (int i = 0; i < totalLines; i++) {
                this.consoleLine[i].kill();
            }
        }
        
        public void display(boolean doDisplay) {
            if (doDisplay) {
              //pushMatrix();
              //scale
              //popMatrix();
              for (int i = 0; i < totalLines; i++) {
                  this.consoleLine[i].display();
              }
              }
              if (this.timeout > 0) {
              this.timeout--;
            }
            force = false;
        }
        
        public void force() {
            this.force = true;
        }
        
        public void consolePrint(Object message, color c) {
            int l = totalLines;
            int i = 0;
            int last = 0;
            
            String m = "";
            if (message instanceof String) {
            m = (String)message;
            }
            else if (message instanceof Integer) {
            m = str((Integer)message);
            }
            else if (message instanceof Float) {
            m = str((Float)message);
            }
            else if (message instanceof Boolean) {
            m = str((Boolean)message);
            }
            else {
            m = message.toString();
            }
            
            while (i < l) {
            if (consoleLine[i].getPos() == (l - 1)) {
                last = i;
            }
            consoleLine[i].move();
            i++;
            }
            consoleLine[last].message(m, c);
            println(message);
        }
        
        
        public void log(Object message) {
            this.consolePrint(message, color(255));
        }
        public void warn(String message) {
            this.consolePrint("WARNING "+message, color(255, 200, 30));
            if (enableBasicUI) {
              this.basicui.showWarningWindow(message);
            }
        }
        public void bugWarn(String message) {
            this.consolePrint("BUG WARNING "+message, color(255, 102, 102));
        }
        public void error(String message) {
            this.consolePrint("ERROR "+message, color(255, 30, 30));
        }
        public void info(Object message) {
            if (this.debugInfo)
              this.consolePrint(message, color(127));
        }
        public void logOnce(Object message) {
            if (this.timeout == 0)
              this.consolePrint(message, color(255));
            this.timeout = messageDelay;
        }
        public void warnOnce(String message) {
            if (this.timeout == 0)
              this.warn(message);
            this.timeout = messageDelay;
        }
        public void bugWarnOnce(String message) {
            if (this.timeout == 0)
              this.bugWarn(message);
            this.timeout = messageDelay;
            
        }
        public void errorOnce(String message) {
            if (this.timeout == 0)
              this.error(message);
            this.timeout = messageDelay;
        }
        public void infoOnce(Object message) {
            if (this.timeout == 0)
              this.info(message);
            this.timeout = messageDelay;
        }
        
        }



        // BasicUI class part of the console class.
        // Might go unused. It was part of the sketchypad
        // project in order to provide warnings to dumb people.
        class BasicUI {
        
        
        public BasicUI() {
            
        }
        
        private boolean displayingWindow = false;
        private float offsetX = 0, offsetY = 0;
        private float radius = 30;
        private String message = "hdasklfhwea ewajgf awfkgwe fehwafg eawhjfgew ajfghewafg jehwafgghaf hewafgaehjfgewa fg aefhjgew fgewafg egaf ghewaf egwfg ewgfewa fhgewf e wgfgew afgew fg egafwe fg egwhahjfgsd asdnfv eahfhedhajf gweahj fweghf";
        
        private void warningWindow() {
            offsetX = sin(frameCount)*radius;
            offsetY = cos(frameCount)*radius;
            
            radius *= 0.90;
            
            stroke(0);
            strokeWeight(4);
            fill(200);
            rect(200+offsetX, 300+offsetY, WIDTH-400, HEIGHT-500);
            fill(color(255, 127, 0));
            rect(200+offsetX, 200+offsetY, WIDTH-400, 100);
            
            noStroke();
            
            textAlign(CENTER, CENTER);
            textSize(62);
            fill(255);
            text("WARNING!!", WIDTH/2+offsetX, 240+offsetY);
            
            textAlign(LEFT, LEFT);
            
            textSize(24);
            fill(0);
            text(message+"\n\n[press x to dismiss]", 220+offsetX, 320+offsetY, width-440, height-500);
        }
        
        public void showWarningWindow(String m) {
            //sndNope.play();
            message = m;
            radius = 50;
            displayingWindow = true;
        }
        
        public boolean displayingWindow() {
            return displayingWindow;
        }
        
        public void stopDisplayingWindow() {
            displayingWindow = false;
        }  
        
        public void display() {
            if (displayingWindow) {
            warningWindow();
            }
        }
    }

    public class ReadEntryFailureException extends Exception {
        public ReadEntryFailureException(String message) {
            super(message);
            console.error(message);
        }
    }

    // public char PROPERTY_SEPERATOR_CHAR = 253;
    // public char ELEMENT_END_CHAR = 254;
    // public char DATA_HEAP_SEPERATOR_CHAR = 255;
    public final char PROPERTY_SEPERATOR_CHAR = '_';
    public final char ELEMENT_END_CHAR = '\n';
    public final char DATA_HEAP_SEPERATOR_CHAR = '~';

    public final int  POINTER_LENGTH = 4;
    public final int  SIZE_LENGTH    = 4;

    public final byte DATATYPE_INT         = 0;
    public final byte DATATYPE_FLOAT       = 1;
    public final byte DATATYPE_STRING      = 2;
    public final byte DATATYPE_INT_ARRAY   = 3;
    public final byte DATATYPE_BYTE_ARRAY  = 4;
    public final byte DATATYPE_FLOAT_ARRAY = 5;

    public void beginSaveEntry(String path) {
        save = new SaveEntryProperties(path);
    }

    public void beginReadEntry(String path) {
        read = new PlaceholderReadEntryProperties(path);
    }

    public class SaveEntryProperties {
        
        String path = "";
        ByteString properties;
        ByteString heap;

        // String array that can store 8 bit characters.

        class ByteString
        {
            byte[] array;
            int index = 0;
            int length = 0;
            public ByteString() {
                // Inital size of 10KB bytes.
                array = new byte[1024*10];
                length = array.length;
            }

            public void append(byte b) {
                array[index++] = b;

                // Double the array size if the array is full.
                if (index >= length) {
                    byte[] newArray = new byte[length*2];
                    for (int i = 0; i < length; i++) {
                        newArray[i] = array[i];
                    }
                    array = newArray;
                    length = newArray.length;
                }
            }

            public void appendString(String s) {
                for (int i = 0; i < s.length(); i++) {
                    append((byte) s.charAt(i));
                }
            }

            public void appendInt(int i) {
                append((byte) i);
                append((byte) (i >> 8));
                append((byte) (i >> 16));
                append((byte) (i >> 24));
            }
        }

        public SaveEntryProperties(String path) {
            this.path = path;
            // initialise properties to hold 8-bit characters

            properties = new ByteString();
            heap = new ByteString();
        }

        public void createStringProperty(String name, String value) {
            int len = value.length();
            int pointer = heap.index;

            // Write data to properties.
            properties.appendString(name);
            properties.append((byte)PROPERTY_SEPERATOR_CHAR);
            properties.append((byte)DATATYPE_STRING);
            properties.appendInt(pointer);
            properties.appendInt(len);

            // Write the string value to the heap
            heap.appendString(value);
        }

        public void createIntProperty(String name, int value) {
            int pointer = heap.index;

            // Write data to properties.
            properties.appendString(name);
            properties.append((byte)PROPERTY_SEPERATOR_CHAR);
            properties.append((byte)DATATYPE_INT);
            properties.appendInt(pointer);
            properties.appendInt(0);

            // Write the int value to the heap
            heap.appendInt(value);
        }

        public void nextElement() {
            properties.append((byte)ELEMENT_END_CHAR);
        }

        public void endProperties() {
            properties.append((byte)DATA_HEAP_SEPERATOR_CHAR);
        }

        public void closeAndSave() {
            // Combine the properties and heap into one byte array.
            byte[] combined = new byte[properties.index + heap.index];
            for (int i = 0; i < properties.index; i++) {
                combined[i] = properties.array[i];
            }
            for (int i = 0; i < heap.index; i++) {
                combined[i+properties.index] = heap.array[i];
            }

            // Write the combined byte array to the file.
            try {
                FileOutputStream fos = new FileOutputStream(new File(path));
                fos.write(combined);
                fos.close();
            } catch (IOException e) {
                console.error("Failed to save file: " + path);
            }
        }
    }


    // The save file system handler class for loading entries.
    // This does not include sections, shall work on that later.
    // For now, foreign characters shouldn't be used in the save file,
    // only characters from 0-127 are supported.
    // Any bytes outside of that range are used as seperators and control
    // characters.
    // Note: right now I'm using ints so the maximum file size this thing can
    // access is prolly 4GB. Remind be to fix this later.
    public class PlaceholderReadEntryProperties {



        FileInputStream fis;
        ElementProperties currElement = null;
        Integer heapPosition = null;    // Integer object because I want it to throw a null
                                        // pointer exception if it's not set.
        ArrayList<ElementProperties> elements = new ArrayList<ElementProperties>();
        ElementProperties selectedElement = null;


        public class ElementProperties {

            class PnL {
                public int pointer;
                public int len;
                public byte type;
                public PnL(int p, int l, byte t) {
                    this.pointer = p;
                    this.len = l;
                    this.type = t;
                }
            }

            // Properties that can hold a string, int, float or other data type.
            public HashMap<String, PnL> properties;
            FileInputStream dataReader;
            FileInputStream f;
            public boolean moreToRead = true;

            public ElementProperties(FileInputStream f) throws ReadEntryFailureException {
                this.f = f;

                try {
                    dataReader = new FileInputStream(f.getFD());
                }
                catch (IOException e) {
                    throw new ReadEntryFailureException("File system error "+e.getMessage());
                }

                // get the position of f
                try {
                    int pos = (int)f.getChannel().position();
                    if (pos == 0) {
                        int b = f.read();

                        // If we ever come to this point then what are we even
                        // doing with our lives.
                        if (b == -1) {
                            throw new ReadEntryFailureException("What?! This entry file is just empty...");
                        }
                        position(f, 0);
                    }
                }
                catch (IOException e) {
                    throw new ReadEntryFailureException("File system error "+e.getMessage());
                }

                getProperties(0);
            }

            private void position(int pos) {
                try {
                    f.getChannel().position(pos);
                }
                catch (IOException e) {
                    console.error("Oof.");
                }
            }

            private void position(FileInputStream ff, int pos) {
                try {
                    ff.getChannel().position(pos);
                }
                catch (IOException e) {
                    console.error("Oof.");
                }
            }


            // The objective of the following code below is to simply read the bytes
            // and put it into a buffer, until we reach readProperty() we don't do 
            // any actual decoding. The reason it seems so complex is because we need
            // to read until a marker byte, but raw bytes might unintentionally be the marker
            // so we need to read the marker in the right place.
            // We need to start at a newline character.
            // Returns null if there are no lines.
            public byte[] readFileElement() throws ReadEntryFailureException {
                // Start with an initial byte buffer of size 10KB
                byte[] elementBuffer = new byte[1024*10];

                int b = 0;
                int i = 0;
                try {
                    // Read bytes until we hit ELEMENT_END_CHAR
                    // Weird ass bug prevention thing but heck i cant think straight lol
                    if (b == ELEMENT_END_CHAR || b == PROPERTY_SEPERATOR_CHAR || b == DATA_HEAP_SEPERATOR_CHAR) {
                        console.error("Woah there. You've got a bug in your file read code.");
                        return null;
                    }

                    while ((char) b != ELEMENT_END_CHAR 
                        && (char) b != DATA_HEAP_SEPERATOR_CHAR 
                        && b != -1) {
                            
                        // Read property name
                        while ((char) b != PROPERTY_SEPERATOR_CHAR && b != -1 && b != DATA_HEAP_SEPERATOR_CHAR) {
                            b = f.read();
                            elementBuffer[i++] = (byte) b;
                            // println("Property name: " + (char) b);
                        }

                        // botch'd
                        if (b == DATA_HEAP_SEPERATOR_CHAR) {
                            // No more element properties to read.
                            moreToRead = false;
                            heapPosition = (int) f.getChannel().position();
                        }

                        // Read the data type.
                        b = f.read();
                        elementBuffer[i++] = (byte) b;
                        // println("Data type: " + (int) b);

                        // Read pointer and length bytes
                        for (int j = 0; j < POINTER_LENGTH+SIZE_LENGTH; j++) {
                            b = f.read();
                            elementBuffer[i++] = (byte) b;
                            // println("Pointer and length: " + (int) b);
                        }

                        // At the end of the property, read the byte to go to the next
                        // one.
                        b = f.read();
                        elementBuffer[i++] = (byte) b;
                        // println("Next: " + (char) b);
                        
                        // Continue the while loop.
                        
                    }

                    if (b == DATA_HEAP_SEPERATOR_CHAR)  {
                        // No more element properties to read.
                        moreToRead = false;
                        heapPosition = (int) f.getChannel().position();
                    }

                    // Reduce the buffer array according to i and return the reduced the array
                    

                } catch (IOException e) {
                    throw new ReadEntryFailureException("File read error: " + e.getMessage());
                }

                byte[] reducedBuffer = new byte[i];
                for (int j = 0; j < i; j++) {
                    reducedBuffer[j] = elementBuffer[j];
                }
                return reducedBuffer;


                // if (b == DATA_HEAP_SEPERATOR_CHAR || b == -1) {
                //     // No more element properties to read.
                //     return false;
                // }

            }

            // Returns true if we successfully got propeties.
            // Returns false if we reached the end of the elements list..
            public void getProperties(int i) throws ReadEntryFailureException {
                properties = new HashMap<String, PnL>();

                byte[] elementBuffer = readFileElement();
                if (elementBuffer == null) {
                    return;
                }

                //idk the code is messy at this point here is a solution.
                if (elementBuffer.length == 0) {
                    moreToRead = false;
                    return;
                }

                // Read each property, adding it to the hashmap
                readProperty(i, elementBuffer);
            }

            // Returns true if the byte represents a type that exists.
            // False if not.
            private boolean checkDataType(byte b) {
                switch (b) {
                case DATATYPE_INT:
                case DATATYPE_FLOAT:
                case DATATYPE_STRING:
                case DATATYPE_INT_ARRAY:
                case DATATYPE_BYTE_ARRAY:
                case DATATYPE_FLOAT_ARRAY:
                    return true;
                default:
                    return false;
                }
            }

            public String getStringProperty(String name) {
                PnL p = properties.get(name);

                // Warn if the property type is not a string.
                if (p == null) {
                    console.bugWarn("Property " + name + " does not exist.");
                    return null;
                }
                if (p.type != DATATYPE_STRING) {
                    console.bugWarn("Property " + name + " is not a string.");
                }

                byte[] buffer = new byte[p.len];
                position(dataReader, p.pointer+heapPosition);
                try {
                    dataReader.read(buffer);
                    // for (int i = 0; i < buffer.length; i++) {
                    //     buffer[i] = (byte) dataReader.read();
                    // }
                }
                catch (IOException e) {
                    console.error("File read error: " + e.getMessage());
                }

                // Convert byte buffer to string
                String out = new String(buffer);
                
                return out;
            }

            public int getIntProperty(String name) {
                PnL p = properties.get(name);
                if (p == null) {
                    console.warn("Property " + name + " does not exist.");
                    return 0;
                }
                if (p.type != DATATYPE_INT) {
                    console.warn("Property " + name + " is not an int.");
                }

                // We only need 4 bytes for an int.
                byte[] buffer = new byte[4];
                position(dataReader, p.pointer+heapPosition);
                try {
                    dataReader.read(buffer);
                }
                catch (IOException e) {
                    console.warn("File read error: " + e.getMessage());
                }

                // print out the bytes

                // Convert byte buffer to int
                int out = 0;
                for (int i = 0; i < 4; i++) {
                    out = out | (buffer[i] << (i*8));
                }
                return out;
            }

            // public float getFloatProperty(String name) {
            //     return (float) properties.get(name);
            // }

            // public int[] getIntArrayProperty(String name) {
            //     return (int[]) properties.get(name);
            // }
            
            // This function is recursive.
            private void readProperty(int i, byte[] buffer) throws ReadEntryFailureException {
                // Read the property name
                String propertyName = "";
                char b = (char) buffer[i++];

                if (b == ELEMENT_END_CHAR || b == DATA_HEAP_SEPERATOR_CHAR) {
                    // We've reached the end of the properties of this element.
                    return;
                }

                // Error detection code.
                // Property name immediately ends, meaning there is no property name.
                if (b == PROPERTY_SEPERATOR_CHAR) {
                    console.warn("Loading entry error, no property name. I'll try to keep going...");

                    // Attempt to recover by skipping the pointer bytes.
                    i += POINTER_LENGTH+SIZE_LENGTH;
                    i++;
                    readProperty(i, buffer);
                    return;
                    // We don't continue the rest of this function after this point.
                }

                // Read the property name
                try {
                    while (b != PROPERTY_SEPERATOR_CHAR) {
                        propertyName += b;
                        b = (char) buffer[i++];
                    }
                }
                catch (ArrayIndexOutOfBoundsException e) {
                    // If we end up there then hoooooo something has seriously gone wrong.
                    throw new ReadEntryFailureException("Corrupted properties, cannot load entry :(");
                }

                // We should have the property name at that point.

                // Read the data type.
                byte dataType = buffer[i++];
                // An unknown data type is an indication that the save function forgot
                // to add the data type byte.
                if (!checkDataType(dataType)) {
                    console.warn("Loading entry error, invalid or no type byte. I'll try to keep going...");
                    // Go back one byte and assume the data type is a string.
                    i--;
                    dataType = DATATYPE_STRING;
                }

                // Read the pointer and size bytes
                int pointer = 0;
                int size = 0;
                for (int j = 0; j < POINTER_LENGTH; j++) {
                    // println(int(buffer[i++]));
                    pointer = pointer | (buffer[i++] << (8*j));
                }
                for (int j = 0; j < SIZE_LENGTH; j++) {
                    // println(int(buffer[i++]));
                    size = size | (buffer[i++] << (8*j));
                }

                // At this point we should be at the next property.

                println("========================================");
                println("Property name: " + propertyName);
                println("Data type: " + dataType);
                println("Pointer: " + pointer);
                println("Size: " + size);

                properties.put(propertyName, new PnL(pointer, size, dataType));



                if (buffer[i] == ELEMENT_END_CHAR) {
                    // We've reached the end of the properties of this element.
                    return;
                }
                
                // Otherwise we keep going and read the next property.
                readProperty(i, buffer);


            }
        }

        

        public PlaceholderReadEntryProperties(String path) {

            // Create the FileInputStream
            try {
                File file = new File(path);
                if (!file.exists()) {
                    console.error("Save file does not exist!");
                    return;
                }
                fis = new FileInputStream(file);
            }
            catch (FileNotFoundException e) {
                e.printStackTrace();
            }
            
            // Get all the properties of the entry.
            try {
                // Fis's state gets updated whenever we create a new object
                elements = new ArrayList<ElementProperties>();

                ElementProperties e = new ElementProperties(fis);
                elements.add(e);
                while (e.moreToRead) {
                    e = new ElementProperties(fis);
                    elements.add(e);
                }
            }
            catch (ReadEntryFailureException e) {
                console.error("What.");
            }
        }

        public int getElementCount() {
            return elements.size();
        }

        public void selectElement(int index) {
            selectedElement = elements.get(index);
        }

        public String getStringProperty(String name) {
            return selectedElement.getStringProperty(name);
        }

        public int getIntProperty(String name) {
            return selectedElement.getIntProperty(name);
        }



        public void nextElementProperties() {
            try {
                currElement = new ElementProperties(fis);
            }
            catch (ReadEntryFailureException e) {
                console.error("What.");
            }
        }

        public void getStringProperty() {
            currElement.getStringProperty("name");
        }
    }

    // Return true if successfully opened
    // false if failed
    public boolean openJSONArray(String path) {
        try {
            loadedJsonArray = app.loadJSONArray(path);
        }
        catch (RuntimeException e) {
            console.warn("Failed to open JSON file, there was an error: "+e.getMessage());
            return false;
        }

        // If the file doesn't exist
        if (loadedJsonArray == null) {
            console.warn("What. The file doesn't exist.");
            return false;
        }

        return true;
    }
    
    JSONObject loadedJsonObject = null;
    
    // Return true if successfully opened
    // false if failed
    public boolean openJSONObject(String path) {
        try {
            loadedJsonObject = app.loadJSONObject(path);
        }
        catch (RuntimeException e) {
            console.warn("Failed to open JSON file, there was an error: "+e.getMessage());
            return false;
        }

        // If the file doesn't exist
        if (loadedJsonObject == null) {
            console.warn("What. The file doesn't exist.");
            return false;
        }

        return true;
    }
    
    
    public int getJSONInt(String property, int defaultValue) {
      if (loadedJsonObject == null) {
            console.bugWarn("Cannot get property, entry not opened.");
            return defaultValue;
      }
      if (loadedJsonObject.isNull(property))
        return defaultValue;
      else
        return loadedJsonObject.getInt(property);
    }
    
    public String getJSONString(String property, String defaultValue) {
      if (loadedJsonObject == null) {
            console.bugWarn("Cannot get property, entry not opened.");
            return defaultValue;
      }
      if (loadedJsonObject.isNull(property))
        return defaultValue;
      else
        return loadedJsonObject.getString(property);
    }
    
    public float getJSONFloat(String property, float defaultValue) {
      if (loadedJsonObject == null) {
            console.bugWarn("Cannot get property, entry not opened.");
            return defaultValue;
      }
      if (loadedJsonObject.isNull(property))
        return defaultValue;
      else
        return loadedJsonObject.getFloat(property);
    }
    
    public boolean getJSONBoolean(String property, boolean defaultValue) {
      if (loadedJsonObject == null) {
            console.bugWarn("Cannot get property, entry not opened.");
            return defaultValue;
      }
      if (loadedJsonObject.isNull(property))
        return defaultValue;
      else
        return loadedJsonObject.getBoolean(property);
    }

    public int getJSONArrayInt(int index, String property, int defaultValue) {
        if (loadedJsonArray == null) {
            console.bugWarn("Cannot get property, entry not opened.");
            return defaultValue;
        }
        if (index > loadedJsonArray.size()) {
            console.bugWarn("No more elements.");
            return defaultValue;
        }
        
        int result = 0;
        try {
            result = loadedJsonArray.getJSONObject(index).getInt(property);
        }
        catch (Exception e) {
            return defaultValue;
        }

        return result;
    }

    public String getJSONArrayString(int index, String property, String defaultValue) {
        if (loadedJsonArray == null) {
            console.bugWarn("Cannot get property, entry not opened.");
            return defaultValue;
        }
        if (index > loadedJsonArray.size()) {
            console.bugWarn("No more elements.");
            return defaultValue;
        }
        
        String result = "";
        try {
            result = loadedJsonArray.getJSONObject(index).getString(property);
        }
        catch (Exception e) {
            return defaultValue;
        }

        return result;
    }

    public float getJSONArrayFloat(int index, String property, float defaultValue) {
        if (loadedJsonArray == null) {
            console.warn("Cannot get property, entry not opened.");
            return defaultValue;
        }
        if (index > loadedJsonArray.size()) {
            console.warn("No more elements.");
            return defaultValue;
        }
        
        float result = 0;
        try {
            result = loadedJsonArray.getJSONObject(index).getFloat(property);
        }
        catch (Exception e) {
            return defaultValue;
        }

        return result;
    }


    //*******************************************
    //****************ENGINE CODE****************
    //*******************************************
    public void loadAsset(String path) {
        // Make it windows compatible by converting all backslashes to
        // a normal slash.
        path = path.replace('\\', '/');
        
        // get extension
        String ext = path.substring(path.lastIndexOf(".")+1);

        // Get file name without the extension
        String name = path.substring(path.lastIndexOf("/")+1, path.lastIndexOf("."));
        
        //println(name);

        // We don't need to bother with content that's already been loaded.
        if (loadedContent.contains(name)) {
            return;
        }
        // if extension is image
        if (ext.equals("png") || ext.equals("jpg") || ext.equals("gif") || ext.equals("bmp")) {
            // load image and add it to the systemImages hashmap.
            if (systemImages.get(name) == null) {
                systemImages.put(name, app.requestImage(path));
                loadedContent.add(name);
            }
            else {
                console.warn("Image "+name+" already exists, skipping.");
            }
        }
        else if (ext.equals("otf") || ext.equals("ttf")) {       // Load font.
            fonts.put(name, app.createFont(path, 32));
        }
        else if (ext.equals("vlw")) {
            fonts.put(name, app.loadFont(path));
        }
        else if (ext.equals("glsl")) {
            shaders.put(name, app.loadShader(path));
        }
        else if (ext.equals("wav") || ext.equals("ogg") || ext.equals("mp3")) {
            sounds.put(name, new SoundFile(app, path));
        }
        else {
            console.warn("Unknown file type "+ext+" for file "+name+", skipping.");
        }
            
    }

    public void loadAllAssets(String path) {
        // Get list of all assets in current dir
        File f = new File(path);
        File[] assets = f.listFiles();
        // Loop through all assets
        for (int i = 0; i < assets.length; i++) {
            // If asset is a directory
            if (assets[i].isFile()) {
                // Load asset
                loadAsset(assets[i].getAbsolutePath());
            }
            // If asset is a file
            else if (assets[i].isDirectory()) {
                // Load all assets in that directory
                loadAllAssets(assets[i].getAbsolutePath());
            }
        }
    }

    // Since loading essential content only really takes place at the beginning,
    // we can free some memory by clearing the temp info in loadedcontent.
    // Just make sure not to load all content again!
    public void clearLoadingVars() {
        loadedContent.clear();
        systemImages.clear();
    }

    public PImage getImg(String name) {
        if (systemImages.get(name) != null) {
            return systemImages.get(name);
        }
        else {
            console.warnOnce("Image "+name+" doesn't exist.");
            return errorImg;
        }
    }
    
    public void defaultShader() {
      app.resetShader();
    }
    
    public void useShader(String shaderName, Object... uniforms) {
      PShader sh = shaders.get(shaderName);
      if (sh == null) {
        console.warnOnce("Shader "+shaderName+" not found!");
        app.resetShader();
        return;
      }
      int l = uniforms.length;
      app.shader(sh);
      for (int i = 0; i < l; i++) {
        Object o = uniforms[i];
        if (o instanceof String) {
          if (i+1 < l) {
            if (!(uniforms[i+1] instanceof Float)) {
              console.warnOnce("Invalid arguments ("+shaderName+"), uniform name needs to be followed by value.1");
              println((uniforms[i+1]));
              return;
            }
          }
          else {
            console.warnOnce("Invalid arguments ("+shaderName+"), uniform name needs to be followed by value.2");
            return;
          }
          
          int numArgs = 0;
          float args[] = new float[4];   // There can only ever be at most 4 args.
          for (int j = i+1; j < l; j++) {
            if (uniforms[j] instanceof Float) args[numArgs++] = (float)uniforms[j];
            else if (uniforms[j] instanceof String) break;
            else {
              console.warnOnce("Invalid uniform argument for shader "+shaderName+".");
              return;
            }
            if (numArgs > 4) {
              console.warnOnce("There can only be at most 4 uniform args ("+shaderName+").");
              return;
            }
          }
          
          String uniformName = (String)uniforms[i];
          switch (numArgs) {
            case 1:
            sh.set(uniformName, args[0]);
            break;
            case 2:
            sh.set(uniformName, args[0], args[1]);
            break;
            case 3:
            sh.set(uniformName, args[0], args[1], args[2]);
            break;
            case 4:
            sh.set(uniformName, args[0], args[1], args[2], args[3]);
            break;
            default:
            console.warnOnce("Uh oh, that might be a bug (useShader).");
            return;
          }
          i += numArgs;
        }
        else {
          console.warnOnce("Invalid uniform argument for shader "+shaderName+".");
        }
      }
    }

    public void img(PImage image, float x, float y, float w, float h) {
        if (wireframe) {
            app.stroke(sin(app.frameCount*0.1)*127+127, 100);
            app.strokeWeight(3);
            app.noFill();
            app.rect(x, y, w, h);
            app.noStroke();
        }
        else {
            app.noStroke();
        }
        if (image == null) {
            app.image(errorImg, x, y, w, h);
            console.warnOnce("Image listed as 'loaded' but image doesn't seem to exist.");
            return;
        }
        if (image.width == -1 || image.height == -1) {
            app.image(errorImg, x, y, w, h);
            console.warnOnce("Corrupted image.");
            return;
        }
        // If image is loaded render.
        if (image.width > 0 && image.height > 0) {
            app.image(image, x, y, w, h);
            return;
        }
        else {
            app.noStroke();
            return;
        }
        
    }

    public void img(String name, float x, float y, float w, float h) {
        if (systemImages.get(name) != null) {
            img(systemImages.get(name), x, y, w, h);
        }
        else {
            app.image(errorImg, x, y, w, h);
            console.warnOnce("Image "+name+" does not exist");
        }
    }

    public void img(String name, float x, float y) {
        PImage image = systemImages.get(name);
        if (image != null) {
            img(systemImages.get(name), x, y, image.width, image.height);
        }
        else {
            app.image(errorImg, x, y, errorImg.width, errorImg.height);
            console.warnOnce("Image "+name+" does not exist");
        }
    }


    public void imgCentre(String name, float x, float y, float w, float h) {
        PImage image = systemImages.get(name);
        if (image == null) {
            img(errorImg, x-errorImg.width/2, y-errorImg.height/2, w, h);
        }
        else {
            img(image, x-image.width/2, y-image.height/2, w, h);
        }
        
    }

    public void imgCentre(String name, float x, float y) {
        PImage image = systemImages.get(name);
        if (image == null) {
            img(errorImg, x-errorImg.width/2, y-errorImg.height/2, errorImg.width, errorImg.height);
        }
        else {
            img(image, x-image.width/2, y-image.height/2, image.width, image.height);
        }
    }

    

    public int counter(int max, int interval) {
        return (int)(app.frameCount/interval) % (max);
    }

    public String appendZeros(int num, int length) {
        String str = str(num);
        while (str.length() < length) {
            str = "0"+str;
        }
        return str;
    }

    public boolean isLoading() {
        for (PImage p : systemImages.values()) {
            if (p.width == 0 || p.height == 0) {
                return true;
            }
        }
        if (!musicReady.get()) return true;
        return false;
    }
    
    
    public float guiFade = 0;
    public SpriteSystemPlaceholder currentSpritePlaceholderSystem;
    public boolean spriteSystemClickable = false;
    
    public void useSpriteSystem(SpriteSystemPlaceholder system) {
      this.currentSpritePlaceholderSystem = system;
      this.spriteSystemClickable = true;
      this.guiFade = 255.;
    }
    
    public boolean button(String name, String texture, String displayText) {
      
        if (this.currentSpritePlaceholderSystem == null) {
          console.bugWarn("You forgot to call useSpriteSystem()!");
          return false;
        }

        // This doesn't change at all.
        // I just wanna keep it in case it comes in useful later on.
        boolean guiClickable = true;

        // Don't want our messy code to spam the console lol.
        currentSpritePlaceholderSystem.suppressSpriteWarning = true;

        boolean hover = false;

        // Full brightness when not hovering
        app.tint(255, guiFade);
        app.fill(255, guiFade);

        // To click:
        // - Must not be in a minimenu
        // - Must not be in gui move sprite / edit mode.
        // - also the guiClickable thing.
        if (currentSpritePlaceholderSystem.buttonHover(name) && guiClickable && !currentSpritePlaceholderSystem.interactable && spriteSystemClickable) {
            // Slight gray to indicate hover
            app.tint(230, guiFade);
            app.fill(230, guiFade);
            hover = true;
        }

        // Display the button, will be affected by the hover color.
        currentSpritePlaceholderSystem.button(name, texture, displayText);
        app.noTint();

        // Don't have "the boy who called wolf", situation, turn back on warnings
        // for genuine troubleshooting.
        currentSpritePlaceholderSystem.suppressSpriteWarning = false;

        // Only when the button is actually clicked.
        return hover && mouseEventClick;
    }

    public void loadingIcon(float x, float y) {
      int interval = 3;
      switch (powerMode) {
          case HIGH:
          interval = 4;
          break;
          case NORMAL:
          interval = 2;
          break;
          case SLEEPY:
          interval = 1;
          break;
          case MINIMAL:
          interval = 4;
          break;
        }
        imgCentre("load-"+appendZeros(counter(loadingFramesLength, interval), 4), x ,y);
    }

    public float smoothLikeButter(float i) {
        
        switch (powerMode) {
          case HIGH:
          i *= 0.9;
          break;
          case NORMAL:
          i *= 0.9*0.9;
          break;
          case SLEEPY:
          i *= 0.9*0.9*0.9*0.9;
          break;
          case MINIMAL:
          i *= 0.9;
          break;
        }
        
        if (i < 0.05) {
            return i-0.001;
        }
        return i;
    }
    
    public String getLastModified(String path) {
        Path file = Paths.get(path);
        
        if (!file.toFile().exists()) {
          return null;
        }
        
        BasicFileAttributes attr;
        try {
          attr = Files.readAttributes(file, BasicFileAttributes.class);
        }
        catch (IOException e) {
          console.warn("Couldn't get date modified time: "+e.getMessage());
          return null;
        }
      
        return attr.lastModifiedTime().toString();
    }
    
    public int calculateChecksum(PImage image) {
      // To prevent a really bad bug from happening, only actually calculate the checksum if the image is bigger than say,
      // 64 pixels lol.
      if (image.width > 64 || image.height > 64) {
        int checksum = 0;
        int w = image.width;
        int h = image.height;
        
        int gapx = int(image.width*0.099);
        int gapy = int(image.height*0.099);

        for (int y = 0; y < h; y+=gapy) {
            for (int x = 0; x < w; x+=gapx) {
                int pixel = image.get(x, y);
                int red = (pixel >> 16) & 0xFF; // Extract red component
                int green = (pixel >> 8) & 0xFF; // Extract green component
                int blue = pixel & 0xFF; // Extract blue component

                // Add the pixel values to the checksum
                checksum += red + green + blue;
            }
        }

        return checksum;
      }
      else return 0;
    }
    
    public JSONObject cacheInfoJSON = null;
    
    // Whenever cache is written, it would be inefficient to open and close the file each time. So, have a timeout
    // timer which when it expires, the file is written and saved and closed.
    public int cacheInfoTimeout = 0;
    
    public void openCacheInfo() {
      boolean createNewInfoFile = false;
      
      File cacheFolder = new File(APPPATH+CACHE_PATH);
      if ((cacheFolder.exists() && cacheFolder.isDirectory()) == false) {
        console.info("openCacheInfo: cache folder gone, regenerating folder.");
        if (!cacheFolder.mkdir()) {
          console.warn("Couldn't remake the cache directory for whatever reason...");
          return;
        }
      }
      
      // First, open the cache file if it's not been opened already.
      if (cacheInfoTimeout == 0) {
        // Should be true if the info file doesn't exist.
        console.info("openCacheInfo: "+APPPATH+CACHE_INFO);
        File f = new File(APPPATH+CACHE_INFO);
        if (!f.exists()) {
          createNewInfoFile = true;
        }
        else {
          cacheInfoJSON = loadJSONObject(APPPATH+CACHE_INFO);
          // Make sure this cached file is compatible.
          // We add a question mark in the name so that a file can't possibly be named the same in the json file
          String comp_ver = cacheInfoJSON.getString("?cache_compatibility_version", "");
          if (!comp_ver.equals(CACHE_COMPATIBILITY_VERSION)) createNewInfoFile = true;
        }
      }
      
      // TODO: we could probably make this value lower?
      cacheInfoTimeout = 10;  // Reset the timer.
      
      if (createNewInfoFile) {
        console.info("new cache file being created.");
        // Since all currently cached images are now considered useless without the info file, delete all cached images,
        // Folders will be recreated as necessary.
        // TODO: idk ill implement file deleting later, it's not necessary rn.
        
        // Create the new json file.
        cacheInfoJSON = new JSONObject();
        cacheInfoJSON.setString("?cache_compatibility_version", CACHE_COMPATIBILITY_VERSION);
        saveJSONObject(cacheInfoJSON, APPPATH+CACHE_INFO);
        
        cacheInfoTimeout = 0;
      }
    }
    
    private int cacheShrinkX = 0;
    private int cacheShrinkY = 0;
    public void setCachingShrink(int x, int y) {
      cacheShrinkX = x;
      cacheShrinkY = y;
    }
    
    // Returns image if an image is found, returns null if cache for that image doesn't exist.
    public PImage tryLoadImageCache(String originalPath, Runnable readOriginalOperation) {
      console.info("tryLoadImageCache: "+originalPath);
      openCacheInfo();
      
      JSONObject cachedItem = cacheInfoJSON.getJSONObject(originalPath);
      
      // If the object is null here, then there's no info therefore we cannot
      // perform the checksum, so continue to load original instead.
      if (cachedItem != null) {
        console.info("tryLoadImageCache: Found cached entry from info file");
        // First, load the actual image using the actual file path (the one above is a lie lol)
        String actualPath = cachedItem.getString("actual", "");
        
        
        // TODO: shouldn't take long loading a small image, but maybe we should probably use requestImage()
        if (actualPath.length() > 0) {
          console.info("tryLoadImageCache: loading cached image");
          PImage loadedImage = loadImage(actualPath);
          if (loadedImage != null) {
            console.info("tryLoadImageCache: Found cached image");
            
            File f = new File(originalPath);
            String lastModified = "";
            if (f.exists()) lastModified = getLastModified(originalPath);
            
            if (cachedItem.getString("lastModified", "").equals(lastModified)) {
              console.info("tryLoadImageCache: No modifications");
              
              // Perform a checksum which determines if the image can properly be loaded.
              int checksum = calculateChecksum(loadedImage);
              // Return -1 by default if for some reason the checksum is abscent because checksums shouldn't be negative
              if (checksum == cachedItem.getInt("checksum", -1)) {
                console.info("tryLoadImageCache: checksums match");
                return loadedImage;
              }
              else console.info("tryLoadImageCache: Checksums don't match "+str(checksum)+" "+str(cachedItem.getInt("checksum", -1)));
              
              // After this point something happened to the original image (or cache in unusual circumstances)
              // and must not be used.
              // We continue to load original and recreate the cache.
            }
          }
        }
      }
      
      // We should only reach this point if no cache exists or is corrupted
      console.info("tryLoadImageCache: loading original instead");
      readOriginalOperation.run();
      console.info("tryLoadImageCache: done loading");
      
      // At this point we *should* have an image in cachedImage
      if (originalImage == null) {
        console.bugWarn("tryLoadImageCache: Your runnable must store your loaded image using setOriginalImage(PImage image)");
        return null;
      }
      
      // Once we read the original image, we now need to cache the file.
      // Only save to cache if we didn't use requestImage();
      // TODO: remove...?
      //if (originalImage.width != 0 && originalImage.height != 0)
        //saveCacheImage(originalPath, originalImage, true);
      
      PImage returnImage = originalImage;
      // Set it to null to catch programming errors next time.
      originalImage = null;
      return returnImage;
    }
    
    public void moveCache(String oldPath, String newPath) {
      openCacheInfo();
      // If cache of that file exists...
      if (!cacheInfoJSON.isNull(oldPath)) {
        console.info("moveCache: Moved image cache "+newPath);
        JSONObject properties = cacheInfoJSON.getJSONObject(oldPath);
        
        // Tbh we don't care about deleting the original entry
        // Just create a new entry in the new location.
        
        cacheInfoJSON.setJSONObject(newPath, properties);
      }
      
      // Should close automatically by the cache manager so no need to save or anything.
    }
    
    public void scaleDown(PImage image, int scale) {
      console.info("scaleDown: "+str(image.width)+","+str(image.height)+",scale"+str(scale));
      if ((image.width > scale || image.height > scale)) {
        // If the image is vertical, resize to 0x512
        if (image.height > image.width) image.resize(0, scale);
        // If the image is horizontal, resize to 512x0
        else if (image.width > image.height) image.resize(scale, 0);
        // Eh just scale it horizontally by default.
        else image.resize(scale, 0);
      }
    }
    
    
    public String saveCacheImage(String originalPath, final PImage image) {
      console.info("saveCacheImage: "+originalPath);
      openCacheInfo();
      
      JSONObject properties = new JSONObject();
      
      String cachePath = getCachePath();
      
      final String savePath = cachePath;
      final int resizeByX = cacheShrinkX;
      final int resizeByY = cacheShrinkY;
      console.info("saveCacheImage: generating cache in main thread");
      
      // Scale down the cached image so that we have sweet performance and minimal ram usage next time we load up this
      // world. Check if it's actually big enough to be scaled down and scale down by whether it's taller or wider.
      
      // TODO: cacheShrinkX and cacheShrinkY are not actually needed, we just need a true/false boolean.
      if (resizeByX != 0 || resizeByY != 0) 
        scaleDown(image, CACHE_SCALE_DOWN);
      
      console.info("saveCacheImage: saving...");
      image.save(savePath);
      console.info("saveCacheImage: saved");
      
      properties.setString("actual", cachePath);
      properties.setInt("checksum", calculateChecksum(image));
      File f = new File(originalPath);
      if (f.exists()) properties.setString("lastModified", getLastModified(originalPath));
      else properties.setString("lastModified", "");
      
      cacheInfoJSON.setJSONObject(originalPath, properties);
      console.info("saveCacheImage: Done creating cache");
      
      return cachePath;
    }
    
    
    public PImage saveCacheImageBytes(String originalPath, byte[] bytes) {
      openCacheInfo();
      
      JSONObject properties = new JSONObject();
      
      String cachePath = getCachePath();
      
      // Save it as a png.
      saveBytes(cachePath, bytes);
      // Load the png.
      PImage img = loadImage(cachePath);
      
      properties.setString("actual", cachePath);
      properties.setInt("checksum", calculateChecksum(img));
      properties.setString("lastModified", "");
      cacheInfoJSON.setJSONObject(originalPath, properties);
      
      
      return img;
    }
    
    public String getCachePath() {
      // Get a unique idenfifier for the file
      String cachePath = CACHE_PATH+"cache-"+str(int(random(0, 2147483646)))+".png";
      File f = new File(cachePath);
      while (f.exists()) {
        cachePath = CACHE_PATH+"cache-"+str(int(random(0, 2147483646)))+".png";
        f = new File(cachePath);
      }
      
      return cachePath;
    }
    
    public void mv(String oldPlace, String newPlace) {
      try {
        File of = new File(oldPlace);
        File nf = new File(newPlace);
        if (of.exists()) {
          of.renameTo(nf);
          // If the file is cached, move the cached file too to avoid stalling and creating duplicate cache
          moveCache(oldPlace, newPlace);
        }
        else if (!of.exists()) console.warn(oldPlace+" doesn't exist");
      }
      catch (RuntimeException e) {
        console.warn("couldn't move file");
      }
    }
    
    public void backupMove(String path) {
      mv(path, APPPATH+CACHE_PATH+"_"+getLastModified(path).replaceAll(":", "-"));
    }
    
    public void backupAndSaveJSON(JSONObject json, String path) {
      File f = new File(path);
      try {
        if (f.exists())
          backupMove(path);
        }
      catch (NullPointerException e) {
        
      }
      
      saveJSONObject(json, path);
    }
    
    
    
    private PImage originalImage = null;
    public void setOriginalImage(PImage image) {
      if (image == null) console.bugWarn("setOriginalImage: the image you provided is null! Is your runnable load code working??");
      originalImage = image;
    }
    
    
    
    
    public void inputManagement() {

        //*************MOUSE*************
        leftClick  = false;   // True one frame after left  mouse is pressed and then released
        rightClick = false;   // True one frame after right mouse is pressed and then released
        pressDown  = false;   // True for one frame instantly when mouse is pressed.
                
        if (app.mousePressed && !click) {
            click = true;
            pressDown = true;
            noMove = true;
            clickStartX = mouseX();
            clickStartY = mouseY();
        }
        if (!app.mousePressed && click) {
            click = false;
            if (clickStartX != mouseX() || clickStartY != mouseY()) {
                noMove = false;
            }
            if (app.mouseButton == LEFT) {
                leftClick = true;
            }
            else if (app.mouseButton == RIGHT) {
                rightClick = true;
            }
        }


        //*************KEYBOARD*************
        if (keyActionPressed && !keyAction(keyActionPressedName))
          keyActionPressed = false;
        
        if (keyHoldCounter >= 1) {
            switch (powerMode) {
              case HIGH:
              keyHoldCounter++;
              break;
              case NORMAL:
              keyHoldCounter += 2;
              break;
              case SLEEPY:
              keyHoldCounter += 4;
              break;
              case MINIMAL:
              keyHoldCounter++;
              break;
            }
        }

        if (keyHoldCounter > KEY_HOLD_TIME) {
            
            switch (powerMode) {
              case HIGH:
              // Reduce speed of repeated key presses when holding key.
              if (app.frameCount % 2 == 0) {
                keyboardAction(lastKeyPressed, lastKeycodePressed);
              }
              break;
              case NORMAL:
              keyboardAction(lastKeyPressed, lastKeycodePressed);
              break;
              case SLEEPY:
              // Ohgod
              keyboardAction(lastKeyPressed, lastKeycodePressed);
              keyboardAction(lastKeyPressed, lastKeycodePressed);
              break;
              case MINIMAL:
              keyboardAction(lastKeyPressed, lastKeycodePressed);
              break;
            }
        }

        //*************MOUSE WHEEL*************
        if (rawScroll != 0) {
            scroll = rawScroll*-scrollSensitivity;
        }
        else {
            scroll *= 0.5;
        }
        rawScroll = 0.;
    }
    
    // yeah this doesn't work
    // Truth be told I should set up a multiple keys system but I'll do that later if I need it.
    // So right now only one a-z 0-9 key can be pressed at a time and only one code key can be pressed.
    public boolean keys(char... keys) {
      boolean pressed = true;
      if (!this.keyPressed) return false;
      for (char k : keys) {
        if (int(k) == CONTROL) {
          pressed &= controlKeyPressed;
        }
        else { pressed &= (this.lastKeyPressed == k); }
       
      }
      
      return pressed;
    }

    public void keyboardAction(char kkey, int kkeyCode) {
            this.keyPressed = true;
            if (kkey == CODED) {
                //console.log(str(int(kkey)));
                switch (kkeyCode) {
                    case BACKSPACE:
                    if (this.keyboardMessage.length() > 0) {
                        this.keyboardMessage = this.keyboardMessage.substring(0, this.keyboardMessage.length()-1);
                    }
                    break;
                    case ENTER:
                        this.enterPressed = true;
                    break;
                    case CONTROL:
                        this.controlKeyPressed = true;
                    break;
                    case SHIFT:
                        this.shiftKeyPressed = true;
                    break;
                    default:
                    println("Key code: "+kkeyCode);
                    break;
                }
            }
            else if (kkey == '\n') {
                if (this.addNewlineWhenEnterPressed) {
                    this.keyboardMessage += "\n";
                }
                this.enterPressed = true;
            }
            else if (kkey == CONTROL) {
              controlKeyPressed = true;
            }
            else if (kkey == 8) {    //Backspace
                this.backspace();
            }
            else {
                this.keyboardMessage += kkey;
                //this.lastKeyPressed = kkey;
            }
            
            // The key hold part (yay).
            int i = -1;
            boolean loop = true;
            
            //Look through the key pressed array...
            //We're trying to find a blank spot, if the key isn't already being pressed...
            while (loop) {
              i++;
              
              //make sure the key isn't already being pressed...
              if ((i >= PRESSED_KEY_ARRAY_LENGTH)) loop = false;
              else if (Character.toLowerCase(currentKeyArray[i]) == Character.toLowerCase(key)) loop = false;
              else {
                //Once we find a spot write the key here.
                if (currentKeyArray[i] == 0) {
                  loop = false;
                  currentKeyArray[i] = key;
                }
              }
              
            }
    }
    
    public void releaseKeyboardAction() {
      int i = -1;
      boolean loop = true;
      
      if (key == CODED) {
          switch (keyCode) {
              case BACKSPACE:
              break;
              case ENTER:
                  this.enterPressed = false;
              break;
              case CONTROL:
                  this.controlKeyPressed = false;
              break;
              case SHIFT:
                  this.shiftKeyPressed = false;
              break;
          }
      }
      
      //Look through the key pressed array...
      //We're trying to find a blank spot, if the key isn't already being pressed...
      while (loop) {
        i++;
        
        //Check to make sure we're not going beyond the length of the array...
        if (i >= PRESSED_KEY_ARRAY_LENGTH) {
          loop = false;
        }
        else {
          //If we found that key, erase it from the array.
          if (Character.toLowerCase(currentKeyArray[i]) == Character.toLowerCase(key)) {
            loop = false;
            currentKeyArray[i] = 0;
          }
        }
        
      }
    }
    
    public boolean keyDown(char k) {
      if (!inputPromptShown) {
        // TODO: use a hashmap instead of an array.
        for (int i = 0; i < PRESSED_KEY_ARRAY_LENGTH; i++) {
          if (currentKeyArray[i] == k) {
            return true;
          }
        }
      }
      return false;
    }
    
    public boolean keyAction(String keybindName) {
      char k = keybindings.getString(keybindName).charAt(0);
      // Special keys/buttons
      switch (int(k)) {
        case LEFT_CLICK:
        return this.leftClick;
        case RIGHT_CLICK:
        return this.rightClick;
        
        // Otherwise just tell us if the key is down or not
        default:
          return anyKeyDown(k);
      }
    }
    
    private boolean keyActionPressed = false;
    private String keyActionPressedName = "";
    
    public boolean keyActionOnce(String keybindName) {
      if (!keyActionPressed) {
        if (keyAction(keybindName)) {
          keyActionPressedName = keybindName;
          keyActionPressed = true;
          return true;
        }
      }
        
      return false;
    }
    
    public boolean keybindPressed(String keybindName) {
      return (this.keyPressed && int(key) == keybindings.getString(keybindName).charAt(0));
    }
    
    public boolean anyKeyDown(char k) {
      if (!inputPromptShown) {
        k = Character.toLowerCase(k);
        // TODO: use a hashmap instead of an array.
        for (int i = 0; i < PRESSED_KEY_ARRAY_LENGTH; i++) {
          if (Character.toLowerCase(currentKeyArray[i]) == k) {
            return true;
          }
        }
      }
      return false;
    }

    public void displayScreens() {
        if (transitionScreens) {
            setAwake();
            transition = smoothLikeButter(transition);
            
            // Sorry for the code duplication!
            switch (transitionDirection) {
              case RIGHT:
                app.pushMatrix();
                app.translate(((WIDTH*transition)-WIDTH)*displayScale,0);
                prevScreen.display();
                app.popMatrix();
    
    
                app.pushMatrix();
                app.translate((WIDTH*transition)*displayScale,0);
                currScreen.display();
                app.popMatrix();
              break;
              case LEFT:
                app.pushMatrix();
                app.translate((WIDTH-(WIDTH*transition))*displayScale,0);
                prevScreen.display();
                app.popMatrix();
    
    
                app.pushMatrix();
                app.translate((-WIDTH*transition)*displayScale,0);
                currScreen.display();
                app.popMatrix();
              break;
            }

            if (transition < 0.001) {
                transitionScreens = false;
                currScreen.startupAnimation();
                
                // If we're just getting started, we need to get a feel for the framerate since we don't want to start
                // slow and choppy. Once we're done transitioning to the first (well, after the startup) screen, go into
                // FPS recovery mode.
                if (initialScreen) {
                  initialScreen = false;
                  setPowerMode(PowerMode.NORMAL);
                  forceFPSRecoveryMode();
                }
                //prevScreen = null;
            }
        }
        else {
            currScreen.display();
        }
        timestamp("end display");
    }

    



    public void devInfo() {
        if (devMode) {
                    app.noStroke();
                    app.fill(0, 0, 0, 127);
                    app.rect(0, 0, 150, 150);
                    app.fill(255);
                    app.textSize(16);
                    app.textAlign(LEFT);
                    app.text("Dev"+
                             "\nFPS: "+int(app.frameRate)+
                             "\nX: "+mouseX()+
                             "\nY: "+mouseY()+
                             "\nSleepy:  "+sleepyMode
                             , 10, 20);
        }

        if (app.keyPressed && app.keyCode == ALT) {
            devMode = false;
        }
    }

    public void backspace() {
        if (this.keyboardMessage.length() > 0) {
            this.keyboardMessage = this.keyboardMessage.substring(0, this.keyboardMessage.length()-1);
        }
    }
    
    public float mouseX() {
      return mouseX/displayScale;
    }
    
    public float mouseY() {
      return mouseY/displayScale;
    }
    
    private void displayOSError() {
      background(0);
      app.fill(color(255,127,127));
      app.textSize(50);
      app.textAlign(LEFT, TOP);
      app.text(OSName+" is not supported on Timeway, sorry :(\n"+
      "Press any button to exit"
      , 10, 10);
      
      if (keyPressed) {
        exit();
      }
    }
    
    public SoundFile getSound(String name) {
      SoundFile sound = sounds.get(name);
      if (sounds == null) {
        console.bugWarn("playSound: Sound "+name+" doesn't exist!");
        return null;
      }
      else return sound;
    
    }
    
    public void playSound(String name) {
      getSound(name).play();
    }
    
    public void loopSound(String name) {
      getSound(name).loop();
    }
    
    public void setSoundVolume(String name, float vol) {
      getSound(name).amp(vol);
    }
    
    
    public Movie streamMusic;
    public Movie streamMusicFadeTo;
    public float musicFadeOut = 1.;
    public final float MUSIC_FADE_SPEED = 0.95;
    public String musicFadeToPath = "";
    public final float PLAY_DELAY = 0.3;
    public AtomicBoolean musicReady = new AtomicBoolean(true);
    public boolean reloadMusic = false;
    public String reloadMusicPath = "";
    
    // Plays background music directly from the hard drive without loading it into memory, and
    // loops the music when the end of the audio has been reached.
    // This is useful for playing background music, but shouldn't be used for sound effects
    // or randomly accessed sounds.
    // This technically uses an unintended quirk of the Movie library, as passing an audio file
    // instead of a video file still plays the file streamed from the disk.
    public void streamMusic(String path) {
      streamMusic(path, true);
    }
    
    public void streamMusic(final String path, boolean loop) {
      if (musicReady.get() == false) {
        reloadMusic = true;
        reloadMusicPath = path;
        return;
      }
      
      musicReady.set(false);
      Thread t1 = new Thread(new Runnable() {
          public void run() {
            streamMusic = loadNewMusic(path);
            if (streamMusic != null) streamMusic.play();
            musicReady.set(true);
          }
      });
      t1.start();
    }
    
    private Movie loadNewMusic(String path) {
      // Doesn't seem to throw an exception or report an error is the file isn't
      // found so let's do it ourselves.
      File f = new File(path);
      if (!f.exists()) {
        console.bugWarn("loadNewMusic: "+path+" doesn't exist!");
        return null;
      }
      
      Movie newMusic = null;
      
      console.info("loadNewMusic: Starting "+path);
      try {
        newMusic = new Movie(app, path);
      }
      catch (Exception e) {
        console.warn("Error while reading music: "+e.getClass().toString()+", "+e.getMessage());
      }
      
      if (newMusic == null) console.bugWarn("Couldn't read music; null returned");
      
      //  We're creating a new sound streamer, not a movie lmao.
      return newMusic;
    }
    
    public void stopMusic() {
      if (streamMusic != null)
        streamMusic.stop();
      
    }
    
    public void streamMusicWithFade(String path) {
      if (musicReady.get() == false) {
        reloadMusic = true;
        reloadMusicPath = path;
        return;
      }
      
      // Temporary fix
      if (musicFadeOut < 1.) {
        if (streamMusicFadeTo != null) {
          streamMusicFadeTo.stop();
        }
      }
      
      // If no music is currently playing, don't bother fading out the music, just
      // start the music as normal.
      if (streamMusic == null) {
        streamMusic(path);
        return;
      }
      streamMusicFadeTo = loadNewMusic(path);
      streamMusicFadeTo.volume(0.);
      streamMusicFadeTo.playbin.setState(org.freedesktop.gstreamer.State.READY); 
      musicFadeOut = 0.99;
    }
    
    public void fadeAndStopMusic() {
      if (musicFadeOut < 1.) {
        if (streamMusicFadeTo != null) {
          streamMusicFadeTo.stop();
          streamMusicFadeTo = null;
        }
        return;
      }
      musicFadeOut = 0.99;
    }
    
    
    public void processSound() {
      float n = 1.;
      switch (powerMode) {
        case HIGH:
        n = 1.;
        break;
        case NORMAL:
        n = 2.;
        break;
        case SLEEPY:
        n = 4.;
        break;
        case MINIMAL:
        n = 60.;
        break;
      }
      
      if (musicReady.get() == true) {
          if (reloadMusic) {
            stopMusic();
            streamMusic(reloadMusicPath);
            reloadMusic = false;
          }
          
        
          // Fade the music.
          if (musicFadeOut < 1.) {
            if (musicFadeOut > 0.005) {
              // Fade the old music out
              float vol = musicFadeOut *= pow(MUSIC_FADE_SPEED,n);
              streamMusic.playbin.setVolume(vol);
              streamMusic.playbin.getState();   
              
              
              // Fade the new music in.
              if (streamMusicFadeTo != null) {
                streamMusicFadeTo.play();
                streamMusicFadeTo.volume(1.-vol);
              }
              else 
                console.bugWarnOnce("streamMusicFadeTo shouldn't be null here.");
            }
            else {
              stopMusic();
              if (streamMusicFadeTo != null) streamMusic = streamMusicFadeTo;
              musicFadeOut = 1.;
            }
          }
          
        
          
          if (streamMusic != null) {
            if (streamMusic.available() == true) {
              streamMusic.read(); 
            }
            float error = 0.1;
            
            // PERFORMANCE ISSUE: streamMusic.time()
            if (streamMusic.time() >= streamMusic.duration()-error) {
              streamMusic.jump(0.);
            }
          }
      }
    }

//void keyPressed()
//{
//  //if (key == 0x16) // Ctrl+v
//  //{
//    pastedMessage = GetTextFromClipboard();
//    pastedImage = GetImageFromClipboard();
//}
    
    
    // **********************************File stuff for explorers*************************************
    public boolean loading = false;
    public int MAX_DISPLAY_FILES = 2048; 
    public int numTimewayEntries = 0;
    public DisplayableFile[] currentFiles;
    
  // TODO: change this so that you can modify the default dir.
  // TODO: Make it follow the UNIX file system with compatibility with windows.
    public String currentDir;
    public class DisplayableFile {
      public File file;
      public String filename;
      public String fileext;
      public String icon = null;
      // TODO: add other properties.
    }
    
    // Returns the extention WITHOUT the "." dot
    public String getExt(String fileName) {
      int dotIndex = fileName.lastIndexOf(".");
      // If it's a dir, return a dot "."
      if (dotIndex == -1) {
        // Return a dot to resemble that this is a directory.
        // We choose a dot because no extention can possibly be a ".".
        return ".";
      }
      return fileName.substring(dotIndex+1, fileName.length());
    }
    
    public String getDir(String path) {
      String str = path.substring(0, path.lastIndexOf('/', path.length()-2));
      console.log(str);
      return str;
    }
    
    public String getFilename(String path) {
      int index = path.lastIndexOf('/', path.length()-2);
      if (index != -1) {
        if (path.charAt(path.length()-1) == '/') {
          path = path.substring(0, path.length()-1);
        }
        return path.substring(index+1);
      }
      else
        return path;
    }
    
    public boolean atRootDir(String dirName) {
      // This will heavily depend on what os we're on.
      if (platform == WINDOWS) {
        
        // for windows, let's do a dirty way of checking for 3 characters
        // such as C:/
        return (dirName.length() == 3);
      }
      
      // Shouldn't be reached
      return false;
    }
    
    
    
    public String typeToIco(FileType type) {
      switch (type) {
        case FILE_TYPE_UNKNOWN:
          return "unknown_128";
        case FILE_TYPE_IMAGE:
          return "image_128";
        case FILE_TYPE_VIDEO:
          return "media_128";
        case FILE_TYPE_MUSIC:
          return "media_128";
        case FILE_TYPE_MODEL:
          return "unknown_128";
        case FILE_TYPE_DOC:
          return "doc_128";
        default:
          return "unknown_128";
      }
    }
    
    public String extIcon(String ext) {
      return typeToIco(extToType(ext));
    }
    
    public FileType extToType(String ext) {
      if (ext.equals("png")
       || ext.equals("jpg")
       || ext.equals("jpeg")
       || ext.equals("bmp")
       || ext.equals("gif")
       || ext.equals("ico")
       || ext.equals("webm")
       || ext.equals("tiff")
       || ext.equals("tif")) return FileType.FILE_TYPE_IMAGE;
       
      if (ext.equals("doc")
       || ext.equals("docx")
       || ext.equals("txt")
       || ext.equals(ENTRY_EXTENSION)
       || ext.equals("pdf")) return FileType.FILE_TYPE_DOC;
       
      if (ext.equals("mp3")
       || ext.equals("wav")
       || ext.equals("flac")
       || ext.equals("ogg"))  return FileType.FILE_TYPE_MUSIC;
       
      if (ext.equals("mp4")
       || ext.equals("m4v")
       || ext.equals("mov")) return FileType.FILE_TYPE_VIDEO;
       
       return FileType.FILE_TYPE_UNKNOWN;
    }
    
    // A function of conditions for a file to be hidden,
    // for now files are only hidden if they have '.' at the front.
    private boolean fileHidden(String filename) {
      if (filename.length() > 0) {
        if      (filename.charAt(0) == '.') return true;
        else if (filename.equals("desktop.ini")) return true;
      }
      return false;
    }
    
    // Opens the dir and populates the currentFiles list.
    public void openDir(String dirName) {
      loading = true;
      dirName = dirName.replace('\\', '/');
      numTimewayEntries = 0;
      File dir = new File(dirName);
      if (!dir.isDirectory()) {
        console.warn(dirName+" is not a directory!");
        return;
      }
      
      // Start at one because the first element is the back element
      int index = 1;
      
      // Make the dir have one extra slot for back.2
      // TODO: add runtime loading of files and remove the MAX_DISPLAY_FILES limit.
      try {
        int l = dir.listFiles().length + 1;
        if (l > MAX_DISPLAY_FILES) l = MAX_DISPLAY_FILES+1;
        if (atRootDir(dirName)) {
          // if we're at the root dir, then nevermind about that one extra slot;
          // there's no need to go back when we're already at the root dir.
          l = dir.listFiles().length;
          if (l > MAX_DISPLAY_FILES) l = MAX_DISPLAY_FILES;
          index = 0;
        }
        
        currentFiles = new DisplayableFile[l];
        
        // Add the back option to the list
        if (!atRootDir(dirName)) {
          // Assuming we're not at the root dir (therefore possible to go back),
          // add the back option to our dir
          currentFiles[0] = new DisplayableFile();
          currentFiles[0].file = new File(new File(dirName).getParent());
          currentFiles[0].filename = "[Prev dir]";
          currentFiles[0].fileext = "..";            // It should be impossible for any files to have this file extention.
        }
        
        final int MAX_NAME_SIZE = 40;
        
        for (File f : dir.listFiles()) {
          if (index < l) {
            // Cheap fix, sorryyyyyy
            try {
              if (!fileHidden(f.getName())) {
                currentFiles[index] = new DisplayableFile();
                currentFiles[index].file = f;
                currentFiles[index].filename = f.getName();
                if (currentFiles[index].filename.length() > MAX_NAME_SIZE) currentFiles[index].filename = currentFiles[index].filename.substring(0, MAX_NAME_SIZE)+"...";
                currentFiles[index].fileext = getExt(f.getName());
                
                // Get icon
                if (f.isDirectory()) currentFiles[index].icon = "folder_128";
                else currentFiles[index].icon = extIcon(currentFiles[index].fileext);
                
                // Just a piece of code plonked in for the entries part
                if (currentFiles[index].fileext.equals(ENTRY_EXTENSION)) numTimewayEntries++;
                index++;
              }
            }
            catch (NullPointerException e1) {
              
            }
            catch (ArrayIndexOutOfBoundsException e2) {
              
            }
          }
        }
        currentDir = dirName;
        if (currentDir.charAt(currentDir.length()-1) != '/')  currentDir += "/";
        loading = false;
      }
      catch (NullPointerException e) {
        console.warn("Null dir, perhaps refused permissions?");
      }
    }
    
    //public boolean isLoading() {
    //  return loading;
    //}
  
    public void openDirInNewThread(final String dirName) {
      loading = true;
      Thread t = new Thread(new Runnable() {
          public void run() {
              openDir(dirName);
          }
      });
      t.start();
    }
    
    // NOTE: Only opens files, NOT directories (yet).
    public void open(String filePath) {
      String ext = getExt(filePath);
        // Stuff to open with our own app (timeway)
        if (ext.equals(ENTRY_EXTENSION)) {
          currScreen.requestScreen(new Editor(this, filePath));
        }
        
        // Anything else which is opened by a windows app or something.
        // TODO: use xdg-open in linux.
        // TODO: figure out how to open apps with MacOS.
        else {
          if (Desktop.isDesktopSupported()) {
           // Open desktop app with this snippet of code that I stole.
           try {
               Desktop desktop = Desktop.getDesktop();
               File myFile = new File(filePath);
               try {
                 desktop.open(myFile);
               }
               catch (IllegalArgumentException fileNotFound) {
                 console.log("This file or dir no longer exists!");
                 refreshDir();
               }
            } catch (IOException ex) {}
          }
          else {
            console.warn("Couldn't open file, isDesktopSupported=false.");
          }
        }
    }
  
    public void open(DisplayableFile file) {
      String path = file.file.getAbsolutePath();
      if (file.file.isDirectory()) {
        openDirInNewThread(path);
      }
      else {
        // Stuff to open with our own app (timeway)
        if (file.fileext.equals(ENTRY_EXTENSION)) {
          currScreen.requestScreen(new Editor(this, path));
        }
        
        // Anything else which is opened by a windows app or something.
        // TODO: use xdg-open in linux.
        // TODO: figure out how to open apps with MacOS.
        else {
          if (Desktop.isDesktopSupported()) {
           // Open desktop app with this snippet of code that I stole.
           try {
               Desktop desktop = Desktop.getDesktop();
               File myFile = new File(path);
               try {
                 desktop.open(myFile);
               }
               catch (IllegalArgumentException fileNotFound) {
                 console.log("This file or dir no longer exists!");
                 refreshDir();
               }
            } catch (IOException ex) {}
          }
          else {
            console.warn("Couldn't open file, isDesktopSupported=false.");
          }
        }
      }
    }
    
    public void refreshDir() {
      openDirInNewThread(currentDir);
    }

    public String getTextFromClipboard()
    {
      String text = (String) getFromClipboard(DataFlavor.stringFlavor);
      return text;
    }

    public PImage getImageFromClipboard()
    {
      PImage img = null;
      java.awt.Image image = (java.awt.Image) getFromClipboard(DataFlavor.imageFlavor);
      if (image != null)
      {
        img = new PImage(image);
      }
      return img;
    }

    private Object getFromClipboard(DataFlavor flavor)
    {
      Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
      Transferable contents;
      try {
        contents = clipboard.getContents(null);
      }
      catch (IllegalStateException e) {
        contents = null;
      }
      
      Object obj = null;
      if (contents != null && contents.isDataFlavorSupported(flavor))
      {
        try
        {
           obj = contents.getTransferData(flavor);
        }
        catch (UnsupportedFlavorException exu) // Unlikely but we must catch it
        {
          console.warn("(Copy/paste) Unsupported flavor");
    //~  exu.printStackTrace();
        }
        catch (java.io.IOException exi)
        {
          println("Unavailable data: " + exi);
        //~  exi.printStackTrace();
        }
      }
      return obj;
    } 
    
    public void processCaching() {
      if (cacheInfoTimeout > 0) {
        cacheInfoTimeout--;
        if (cacheInfoTimeout == 0) {
          if (cacheInfoJSON != null) {
            console.info("processCaching: saving cache info.");
            saveJSONObject(cacheInfoJSON, APPPATH+CACHE_INFO);
          }
        }
      }
    }
    
    // Woops I should place this at the start.
    boolean focusedMode = true;
    
    // The core engine function which essentially runs EVERYTHING in Timeway.
    // All the screens, all the input management, and everything else.
    public void engine() {
      
        // Run benchmark if it's active.
        runBenchmark();
      
        updatePowerMode();
        
        processSound();
        processCaching();
        
        int n = 1;
        switch (powerMode) {
          case HIGH:
          n = 1;
          break;
          case NORMAL:
          n = 2;
          break;
          case SLEEPY:
          n = 4;
          break;
          case MINIMAL:
          n = 1;
          break;
        }
        
        // This should be run at all times because apparently (for some stupid reason)
        // it uses way more performance NOT to call background();
        app.background(0);

        inputManagement();

        // Show the current GUI.
        displayScreens();
        
        
        // Allow command prompt to be shown.
        if (keyActionOnce("showCommandPrompt"))
          showCommandPrompt();
          
        
        // Display the command prompt if shown.
        app.pushMatrix();
        app.scale(displayScale);
        if (commandPromptShown)
          displayInputPrompt();
        app.popMatrix();
        
        // Update times so we can calculate live fps.
        lastFrameMillis = thisFrameMillis;
        thisFrameMillis = app.millis();

        devInfo();

        // Display console
        // TODO: this renders the console 4 times which is BAD.
        // We need to make the animation execute 4 times, not the drawing routines.
        for (int i = 0; i < n; i++) {
          console.display(true);
        }

        mouseEventClick = false;
        this.keyPressed = false;
    }
}

// Unused because only supported on Windows.
//public interface Kernel32 extends StdCallLibrary {

//    public Kernel32 INSTANCE = Native.load("Kernel32", Kernel32.class);

//    /**
//     * @see https://learn.microsoft.com/en-us/windows/win32/api/winbase/ns-winbase-system_power_status
//     */
//    public class SYSTEM_POWER_STATUS extends Structure {
//        public byte ACLineStatus;
//        public byte BatteryFlag;
//        public byte BatteryLifePercent;
//        public byte Reserved1;
//        public int BatteryLifeTime;
//        public int BatteryFullLifeTime;

//        @Override
//        protected List<String> getFieldOrder() {
//            ArrayList<String> fields = new ArrayList<String>();
//            fields.add("ACLineStatus");
//            fields.add("BatteryFlag");
//            fields.add("BatteryLifePercent");
//            fields.add("Reserved1");
//            fields.add("BatteryLifeTime");
//            fields.add("BatteryFullLifeTime");
//            return fields;
//        }

//        /**
//         * The AC power status
//         */
//        public String getACLineStatusString() {
//            switch (ACLineStatus) {
//                case (0): return "Offline";
//                case (1): return "Online";
//                default: return "Unknown";
//            }
//        }

//        /**
//         * The battery charge status
//         */
//        public String getBatteryFlagString() {
//            switch (BatteryFlag) {
//                case (1): return "High, more than 66 percent";
//                case (2): return "Low, less than 33 percent";
//                case (4): return "Critical, less than five percent";
//                case (8): return "Charging";
//                case ((byte) 128): return "No system battery";
//                default: return "Unknown";
//            }
//        }

//        /**
//         * The percentage of full battery charge remaining
//         */
//        public String getBatteryLifePercent() {
//            return (BatteryLifePercent == (byte) 255) ? "Unknown" : BatteryLifePercent + "%";
//        }

//        /**
//         * The number of seconds of battery life remaining
//         */
//        public String getBatteryLifeTime() {
//            return (BatteryLifeTime == -1) ? "Unknown" : BatteryLifeTime + " seconds";
//        }

//        /**
//         * The number of seconds of battery life when at full charge
//         */
//        public String getBatteryFullLifeTime() {
//            return (BatteryFullLifeTime == -1) ? "Unknown" : BatteryFullLifeTime + " seconds";
//        }

//        @Override
//        public String toString() {
//            StringBuilder sb = new StringBuilder();
//            sb.append("ACLineStatus: " + getACLineStatusString() + "\n");
//            sb.append("Battery Flag: " + getBatteryFlagString() + "\n");
//            sb.append("Battery Life: " + getBatteryLifePercent() + "\n");
//            sb.append("Battery Left: " + getBatteryLifeTime() + "\n");
//            sb.append("Battery Full: " + getBatteryFullLifeTime() + "\n");
//            return sb.toString();
//        }
//    }

//    /**
//     * Fill the structure.
//     */
//    public int GetSystemPowerStatus(SYSTEM_POWER_STATUS result);
//}

interface RedrawElement {
  public float getX();
  public float getY();
  public int getWidth();
  public int getHeight();
  public boolean redraw();
  public void setRedraw(boolean b);
}

//*******************************************
//****************SCREEN CODE****************
//*******************************************
// The basis for everything you see in timeway.
// An abstract class so it merely defines the
// default style of timeway.
public abstract class Screen {
    protected final float UPPER_BAR_WEIGHT = 50;
    protected final float LOWER_BAR_WEIGHT = 50;
    protected final color UPPER_BAR_DEFAULT_COLOR = color(200);
    protected final color LOWER_BAR_DEFAULT_COLOR = color(200);
    protected final color DEFAULT_BACKGROUND_COLOR = color(50);
    protected final float DEFAULT_ANIMATION_SPEED = 0.1;

    protected final int NONE = 0;
    protected final int START = 1;
    protected final int END = 2;


    protected Engine engine;
    protected Engine.Console console;
    protected PApplet app;
    protected float screenx = 0;
    protected float screeny = 0;
    protected color myUpperBarColor = UPPER_BAR_DEFAULT_COLOR;
    protected color myLowerBarColor = LOWER_BAR_DEFAULT_COLOR;
    protected color myBackgroundColor = DEFAULT_BACKGROUND_COLOR;
    protected float myUpperBarWeight = UPPER_BAR_WEIGHT;
    protected float myLowerBarWeight = LOWER_BAR_WEIGHT;
    protected float myAnimationSpeed = DEFAULT_ANIMATION_SPEED;
    protected int transitionState = NONE;
    protected float transitionTick = 0;
    
    // ERS
    protected HashSet<RedrawElement> redrawElements = null;   // Only needed when the screen uses the efficient redraw system (ERS).
    protected boolean ERSenabled = false;
    protected boolean tempERS = false;

    public Screen(Engine engine) {
        this.engine = engine;
        this.console = engine.console;
        this.app = engine.app;
    }
    
    // ERS
    // Optional, enable the efficient redraw system (ERS) so that
    // the background is redrawn in sprites only.
    public void initERS() {
      redrawElements = new HashSet<RedrawElement>();
      ERSenabled = true;
    }
    
    // ERS
    public void addToERS(ArrayList<SpriteSystemPlaceholder.Sprite> existingList) {
      if (ERSenabled) {
        for (SpriteSystemPlaceholder.Sprite s : existingList) {
          if (!redrawElements.contains(s)) redrawElements.add(s);
        }
      }
    }
    
    public void addToERS(HashSet<SpriteSystemPlaceholder.Sprite> existingList) {
      if (ERSenabled) {
        for (SpriteSystemPlaceholder.Sprite s : existingList) {
          if (!redrawElements.contains(s)) redrawElements.add(s);
        }
      }
    }
    
    // ERS
    public void addToERS(SpriteSystemPlaceholder existingSpriteSystemList) {
      if (ERSenabled) {
        for (SpriteSystemPlaceholder.Sprite s : existingSpriteSystemList.sprites) {
          if (!redrawElements.contains(s)) redrawElements.add(s);
        }
      }
    }
    
    // ERS
    public void addToERS(SpriteSystemPlaceholder.Sprite s) {
      if (ERSenabled)
        if (!redrawElements.contains(s)) redrawElements.add(s);
    }
    
    // ERS
    // While in screen transitions, we need to redraw the whole screen.
    private boolean ERSenabled() { return !engine.transitionScreens && ERSenabled; }
    
    // ERS
    public void redraw() {
      // Temporarily disable ERS, call display, and then enable it again. If it's
      // even enabled in the first place.
      boolean temp = ERSenabled;
      ERSenabled = false;
      display();
      ERSenabled = temp;
    }
    
    // ERS
    public void tempDisableERS() {
      tempERS = ERSenabled;
      ERSenabled = false;
    }
    
    // Kinda ERS
    protected void redrawInArea(float x, float y, float wi, float hi, color c) {
      // Stroke lines can increase actual rendered area, so we need to account for that.
      float EXTRA_PADDING = 2.;
      float EXTRA_LEFT = 10.;// Because blinking cursor
      app.noStroke();
      // In ERS mode
      if (ERSenabled()) {
        // Only clear what's necessary.
        for (RedrawElement s : redrawElements) {
          //println(s.redraw()); 
          if (s.redraw()) {
            // Get positions
            float sx = s.getX()-EXTRA_PADDING;
            float sy = s.getY()-EXTRA_PADDING;
            float swi  = float(s.getWidth())+EXTRA_PADDING*2+EXTRA_LEFT;
            float shi  = float(s.getHeight())+EXTRA_PADDING*2;
            
            // Only bother drawing any rectangles if within the render zone.
            //println((sx+swi > x && sx < x+wi && sy+shi > y && sy < y+hi));
            //println((sx+swi));
            //println((sx < x+wi));
            //println((sy+shi > y));
            //println((sy < y+hi));
            if (sx+swi > x && sx < x+wi && sy+shi > y && sy < y+hi) {
              // If the right edge of the element exceeds the rectangle
              // Limit the sprite's render width
              if (sx+swi > x+wi) swi = (x+wi)-sx;
              
              // If the bottom of the element exceeds the bottom of the rectangle
              // Limit the sprite's render height
              if (sy+shi > y+hi) shi = (y+hi)-sy;
              
              // Finally, fill clear the area.
              app.fill(c);
              app.rect(sx, sy, swi, shi);
            }
          }
        }
      }
      
      // Otherwise, just draw the whole thing. 
      // This is the standard non-ERS action!
      else {
        app.fill(c);
        app.rect(x, y, wi, hi);
      }
    }
    
    // Definitely ERS
    private void calculateCollisionRedraw() {
      // First, let's create a new hashmap of all our elements
      ArrayList<RedrawElement> elements = new ArrayList<RedrawElement>(redrawElements);
      
      // The optimisations:
      // 1. Once a collision check is performed, there's no need to do the inverse check
      // (a checks collision with b and c, a collision check b -> a, c -> a would be redundant)
      // 2. Because we're only ever checking if an object needs to be redrawn, there's no
      // need to continue checking the rest of the elements if a collision has been detected;
      // it only takes 1 collision for both objects to be marked as "redraw required"
      
      // SOLUTION TO PROBLEM:
      // Use recursive checks.
      
      while (elements.size() > 0) {
        // "pop" the element
        RedrawElement ea = elements.get(0);
        elements.remove(0);
          // Once we're done checking, we do not want this element in the list anymore.
          
        for (RedrawElement eb : elements) {
          // If both aren't marked for redrawing
          if (ea.redraw() || ea.redraw()) {
            // If a collision has been detected (I'm sorry for this clusterf**k)
            if (ea.getX()+ea.getWidth() > eb.getX() && eb.getX()+eb.getWidth() < ea.getX()
            && ea.getY()+ea.getHeight() > eb.getY() && eb.getY()+eb.getHeight() < ea.getY()) {
              // Collision, both elements should be redrawn.
              
            }
          }
        }
        
      }
    }

    protected void upperBar() {
        redrawInArea(0, 0, engine.WIDTH, myUpperBarWeight, myUpperBarColor);
    }

    protected void lowerBar() {
        redrawInArea(0, engine.HEIGHT-myLowerBarWeight, engine.WIDTH, myLowerBarWeight, myLowerBarColor);
    }

    protected void backg() {
        redrawInArea(0, myUpperBarWeight, engine.WIDTH, engine.HEIGHT-myUpperBarWeight-myLowerBarWeight, myBackgroundColor);
    }

    public void startupAnimation() {
        
    }

    protected void startScreenTransition() {
        engine.transitionScreens = true;
        engine.transition = 1.0;
        engine.transitionDirection = RIGHT;   // Right by default, you can change it to left or anything else
                                              // right after calling startScreenTransition().
    }

    protected void endScreenTransition() {
      
    }


    protected void requestScreen(Screen screen) {
        if (engine.currScreen == this && engine.transitionScreens == false) {
            this.endScreenTransition();
            engine.prevScreen = this;
            engine.currScreen = screen;
            screen.startScreenTransition();
            engine.clearKeyBuffer();
            engine.resetFPSSystem();
            //engine.setAwake();
        }
    }
    
    protected void previousScreen() {
      if (this.engine.prevScreen == null) engine.console.bugWarn("No previous screen to go back to!");
      else {
        requestScreen(this.engine.prevScreen);
        engine.transitionDirection = LEFT;
        engine.setAwake();
        engine.clearKeyBuffer();
      }
    }
    
    
    // A method where you can add your own custom commands.
    // Must return true if a command is found and false if a command
    // is not found.
    protected boolean customCommands(String command) {
      return false;
    }
    



    // The actual stuff you want to display does NOT go into the 
    // display method but rather the content method. Upper and lower
    // bars overlap the content displayed.
    protected void content() {

    }

    // The magic display method that takes all the components
    // of the screen and mashes it all into one complete screen,
    // ready for the engine to display. Simple as.
    public void display() {
      if (engine.powerMode != PowerMode.MINIMAL) {
        app.pushMatrix();
        app.translate(screenx,screeny);
        app.scale(engine.displayScale);
        this.backg();
        
        // Reset the redraw property on sprites if ERS
        if (ERSenabled) {
          for (RedrawElement s : redrawElements) {
            s.setRedraw(false);
          }
        }
        
        this.content();
        this.upperBar();
        this.lowerBar();
        app.popMatrix();
        
        if (tempERS && !ERSenabled) ERSenabled = true;
      }
    }
}

public enum PowerMode {
    HIGH,
    NORMAL,
    SLEEPY,
    MINIMAL
}

public enum FileType {
    FILE_TYPE_UNKNOWN,
    FILE_TYPE_IMAGE,
    FILE_TYPE_VIDEO,
    FILE_TYPE_MUSIC,
    FILE_TYPE_MODEL,
    FILE_TYPE_DOC
}
