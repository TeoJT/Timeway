import java.util.HashSet;
import java.io.File;
import java.net.MalformedURLException;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.io.FileOutputStream;
import org.freedesktop.gstreamer.*;
import java.io.InputStream;
import java.io.FileOutputStream;
import java.net.URL;
import java.util.zip.*;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.io.ByteArrayInputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.ShortBuffer;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import java.nio.file.Paths;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.nio.file.*;
import java.nio.file.attribute.*;
import java.util.ArrayList;
import java.util.List;
import com.sun.jna.Native;
import com.sun.jna.Structure;
import processing.video.Movie;
import gifAnimation.*;
import java.net.URLClassLoader;
import java.net.URL;
import java.lang.reflect.Method;
import java.lang.reflect.Parameter;
import java.io.OutputStream;
import java.io.InputStreamReader;
import java.util.Iterator;   // Used by the stack class at the bottom
import java.util.Arrays;   // Used by the stack class at the bottom
import java.util.Collections;
import java.lang.reflect.InvocationTargetException;
import java.util.concurrent.TimeUnit;


//Garbage Collection Tuning: While you can't change the heap size dynamically, you can tune garbage collection behavior using JVM options such as:

//-XX:MaxHeapFreeRatio: Controls the maximum percentage of heap that can be free after garbage collection.
//-XX:MinHeapFreeRatio: Controls the minimum percentage of heap that should be free after garbage collection.


// Timeway's engine code.
// TODO: add documentation lmao.
public class TWEngine {
  //*****************CONSTANTS SETTINGS**************************
  // Info and versioning
  private static final String VERSION     = "0.1.7";
  
  public String getAppName() {
    return "Timeway";
  }
  
  public String getVersion() {
    return VERSION;
  }
    
  // ***************************
  // How versioning works:
  // a.b.c
  // a is just gonna stay 0 most of the time unless something significant happens
  // b is a super major release where the system has a complete overhaul.
  // c is pretty much every release whether that's bug fixes or other things.
  // a, b, and c can go well over 10, 100, it can be any positive integer.

  // Paths
  //public final String WINDOWS_CMD         = "engine/shell/mywindowscommand.bat";
  public final String POCKET_PATH         = "pocket/";
  public final String TEMPLATES_PATH      = "engine/realmtemplates/";
  public final String EVERYTHING_TXT_PATH = "engine/everything.txt";
  public final String DEFAULT_MUSIC_PATH  = "engine/music/default.wav";
  public       String DEFAULT_UPDATE_PATH = "";  // Set up by setup()
  public final String BOILERPLATE_PATH    = "engine/other/plugin_boilerplate.java";
  public final String PDFTOPNG_PATH       = "engine/bin/windows/pdftopng.exe";
  public final String LOW_MEM_EXE         = "engine/other/run_low_mem.exe";
  public final String NORMAL_MEM_EXE      = "engine/other/run_normal.exe";
  
  public String CONSOLE_FONT() {return "engine/font/SourceCodePro-Regular.ttf";}
  public String IMG_PATH() {return "engine/img/";}
  public String FONT_PATH() {return "engine/font/";}
  public String DEFAULT_FONT_PATH() {return "engine/font/Typewriter.vlw";}
  public String SHADER_PATH() {return "engine/shaders/";}
  public String SOUND_PATH() { return "engine/sounds/"; }
  public String CONFIG_PATH() { return "config.json"; }
  public String KEYBIND_PATH() { return "keybindings.json"; }
  public String STATS_FILE() { return "stats.json"; }
  public String PATH_SPRITES_ATTRIB() { return "engine/spritedata/"; }
  public String CACHE_INFO() { return "cache_info.json"; }

  // Static constants
  public static final float   KEY_HOLD_TIME       = 30.; // 30 frames
  public static final int     POWER_CHECK_INTERVAL = 5000;
  public static final String  CACHE_COMPATIBILITY_VERSION = "0.3";
  public static final String  CACHE_FILE_TYPE = "png";
  public static final int     MAX_RAM_NORMAL = 1024*1024*1024; // 1GB
  public static final int     MAX_RAM_LIMITED = 1024*1024*200; // 200MB
  
  public boolean CACHE_MUSIC = false;
  

  // Dynamic constants (changes based on things like e.g. configuration file)
  public       PFont  DEFAULT_FONT;
  public       String DEFAULT_DIR;
  public       String DEFAULT_FONT_NAME = "Typewriter";

  
  public final String SKETCHIO_EXTENSION = "sketchio";
  public final String ENTRY_EXTENSION = "timewayentry";
  public final String SHORTCUT_EXTENSION = "timewayshortcut";


  //*************************************************************
  //**************ENGINE SETUP CODE AND VARIABLES****************
  // Core stuff
  public PApplet app;
  public String APPPATH = sketchPath().replace('\\', '/')+"/data/";
  public String CACHE_PATH = "cache/";
  
  // Modules
  public Console console;
  public SharedResourcesModule sharedResources;  // TODO: Unused module, remove shared resources.
  public SettingsModule settings;
  public DisplayModule display;
  public PowerModeModule power;
  public AudioModule sound;
  public FilemanagerModule file;
  public StatsModule stats;
  public ClipboardModule clipboard;
  public UIModule ui;
  public InputModule input;
  public TWEngine.PluginModule plugins;
  public IndexerModule indexer;


  
  
  

  // Screens
  public Screen currScreen;
  public Screen prevScreenTransition;
  public Stack<Screen> screenStack = new Stack(64);
  private DummyScreen dummyScreen;
  public boolean transitionScreens = false;
  public float transition = 0f;
  public int transitionDirection = RIGHT;
  public boolean initialScreen = true;


  // Other / doesn't fit into any categories.
  public long lastTimestamp;
  public String lastTimestampName = null;
  public int timestampCount = 0;
  public boolean allowShowCommandPrompt = true;
  public boolean playWhileUnfocused = true;
  public HashMap<Long, Float> noiseCache = new HashMap<Long, Float>();
  public boolean focusedMode = true;
  public boolean lowMemory = false;
  public boolean enableCaching = true;
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class SharedResourcesModule {
    private HashMap<String, Object> sharedResourcesMap;
    
    public SharedResourcesModule() {
      sharedResourcesMap = new HashMap<String, Object>();
    }
    
    public void set(String resourceName, Object val) {
      sharedResourcesMap.put(resourceName, val);
    }
    
    public Object get(String resourceName) {
      Object o = sharedResourcesMap.get(resourceName);
      if (o == null) console.bugWarn("get: null object. Maybe use set or add a runnable argument to get?");
      return o;
    }
    
    public Object get(String resourceName, Object addIfAbsent) {
      Object o = sharedResourcesMap.get(resourceName);
      if (o == null) this.set(resourceName, addIfAbsent);
      o = sharedResourcesMap.get(resourceName);
      // If it's still null after running, send a warning
      if (o == null) console.bugWarn("get: You just passed a null object...?");
      return o;
    }
    
    public Object get(String resourceName, Runnable runIfAbsent) {
      Object o = sharedResourcesMap.get(resourceName);
      if (o == null) runIfAbsent.run();
      o = sharedResourcesMap.get(resourceName);
      // If it's still null after running, send a warning
      if (o == null) console.bugWarn("get: object still null after running runIfAbsent. Make sure to use set in your runnable!");
      return o;
    }
    
    public void remove(String resourceName) {
      sharedResourcesMap.remove(resourceName);
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class SettingsModule {
      private JSONObject settings;
      private JSONObject keybindings;
      public int saveSettingsTimeout = 0;
      
      public SettingsModule() {
        if (!isAndroid()) {
          // Normal you expect it.
          settings = loadConfig(APPPATH+CONFIG_PATH());
          keybindings = loadConfig(APPPATH+KEYBIND_PATH());
        }
        else {
          // However, in android, we're not allowed to write to the usual place.
          // Android gives you a specific variable dir to write to, so we must use that instead.
          settings = loadConfig(getAndroidWriteableDir()+CONFIG_PATH());
          keybindings = loadConfig(getAndroidWriteableDir()+KEYBIND_PATH());
        }
      }
      
      public void saveSettings() {
        if (saveSettingsTimeout <= 0) {
          saveJSONObject(settings, APPPATH+CONFIG_PATH());
          saveJSONObject(keybindings, APPPATH+KEYBIND_PATH());
          saveSettingsTimeout = 60;
        }
      }
      
      public void update() {
        if (saveSettingsTimeout > 0) {
          saveSettingsTimeout--;
          if (saveSettingsTimeout == 0) {
            saveSettings();
            saveSettingsTimeout = 0;
          }
        }
      }
      
      public void forceSaveSettings() {
        saveJSONObject(settings, APPPATH+CONFIG_PATH());
        saveJSONObject(keybindings, APPPATH+KEYBIND_PATH());
      }
      
      public void setKeybinding(String keybindName, char kkey) {
        keybindings.setString(keybindName, ""+Character.toLowerCase(kkey));
        saveSettings();
      }
      
      public char getKeybinding(String keybindName, char defaultChar) {
        
        if (keybindings.isNull(keybindName)) {
          keybindings.setString(keybindName, ""+defaultChar);
          saveSettings();
          return defaultChar;
        }
        else {
          String s = keybindings.getString(keybindName);
          if (s.length() == 0) {
            keybindings.setString(keybindName, ""+defaultChar);
            return defaultChar;
          }
          return s.charAt(0);
        }
      }
      
      public boolean getBoolean(String setting, boolean defaultSetting) {
        if (settings.isNull(setting)) {
          settings.setBoolean(setting, defaultSetting);
          saveSettings();
          return defaultSetting;
        }
        else {
          return settings.getBoolean(setting);
        }
      }
    
      public float getFloat(String setting, float defaultSetting) {
        if (settings.isNull(setting)) {
          settings.setFloat(setting, defaultSetting);
          saveSettings();
          return defaultSetting;
        }
        else {
          return settings.getFloat(setting);
        }
      }
    
      public String getString(String setting, String defaultSetting) {
        if (settings.isNull(setting)) {
          settings.setString(setting, defaultSetting);
          saveSettings();
          return defaultSetting;
        }
        else {
          return settings.getString(setting);
        }
      }
      
      public int getInt(String setting, int defaultSetting) {
        if (settings.isNull(setting)) {
          settings.setInt(setting, defaultSetting);
          saveSettings();
          return defaultSetting;
        }
        else {
          return settings.getInt(setting);
        }
      }
      
      public boolean setBoolean(String setting, boolean value) {
        settings.setBoolean(setting, value);
        saveSettings();
        return value;
      }
    
      public float setFloat(String setting, float value) {
        settings.setFloat(setting, value);
        saveSettings();
        return value;
      }
    
      public String setString(String setting, String value) {
        settings.setString(setting, value);
        saveSettings();
        return value;
      }
      
      public int setInt(String setting, int value) {
        settings.setInt(setting, value);
        saveSettings();
        return value;
      }
      
      
      public JSONObject loadConfig(String configPath) {
        File f = new File(configPath);
        if (!f.exists()) {
          return new JSONObject();
        } else {
          try {
            return loadJSONObject(configPath);
          }
          catch (RuntimeException e) {
            console.warn("There's an error in the config file. Loading default settings.");
            return new JSONObject();
          }
        }
      }
  }
  
  


  

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class PowerModeModule {
    
  // Power modes
    public PowerMode powerMode = PowerMode.HIGH;
    private boolean noBattery = false;
    private boolean sleepyMode = false;
    private boolean dynamicFramerate = true;
    private boolean powerSaver = false;
    private int lastPowerCheck = 0;
    
    public PowerMode getPowerMode() {
      return powerMode;
    }
    
    
    final int MONITOR = 1;
    final int RECOVERY = 2;
    final int SLEEPY = 3;
    final int GRACE  = 4;
    int fpsTrackingMode = MONITOR;
    float fpsScore = 1000.;
    float scoreDrain = 1.;
    float recoveryScore = 1.;
    
    PowerMode prevPowerMode = PowerMode.HIGH;
    int recoveryFrameCount = 0;
    int graceTimer = 0;
    int recoveryPhase = 1;
    float framerateBuffer[];
    private boolean forcePowerModeEnabled = false;
    private PowerMode forcedPowerMode = PowerMode.HIGH;
    private PowerMode powerModeBefore = PowerMode.NORMAL;
    public boolean allowMinimizedMode = true;
  
    // The score that seperates the stable fps from the unstable fps.
    // If you've got half a brain, it would make the most sense to keep it at 0.
    final float FPS_SCORE_MIDDLE = 0.;
  
    // Increase the score if the framerate is good but we're in the unstable zone.
    private final float UNSTABLE_CONSTANT = 7.;
  
    // Once we reach this score, we drop down to the previous frame.
    private final float FPS_SCORE_DROP = -3000;
  
    // If we gradually manage to make it to that score, we can go into RECOVERY mode to test what the framerate's like
    // up a level.
    private final float FPS_SCORE_RECOVERY = 500.;
  
    // We want to recover to a higher framerate only if we're able to achieve a pretty good framerate.
    // The higher you make RECOVERY_NEGLIGENCE, the more it will neglect the possibility of recovery.
    // For example, trying to achieve 60fps but actual is 40fps, the system will likely recover faster if
    // RECOVERY_NEGLIGENCE is set to 1 but very unlikely if it's set to something higher like 5.
    private final float RECOVERY_NEGLIGENCE = 1;
    
    private final int RECOVERY_PHASE_1_FRAMES = 20;
    private final int RECOVERY_PHASE_2_FRAMES = 120;   // 2 seconds
    
    public PowerModeModule() {
      setForcedPowerMode(settings.getString("force_power_mode", "AUTO"));
      allowMinimizedMode = settings.getBoolean("sleep_when_inactive", true);
    }
    
    public void setDynamicFramerate(boolean b) {
      dynamicFramerate = b;
    }
    
    
    public String getPowerModeString() {
      switch (powerMode) {
        case HIGH:
        return "HIGH";
        case NORMAL:
        return "NORMAL";
        case SLEEPY:
        return "SLEEPY";
        case MINIMAL:
        return "MINIMAL";
        default:
        console.bugWarn("getPowerModeString: Unknown power mode");
        return "";
      }
    }
    
    public void setForcedPowerMode(String p) {
      forcePowerModeEnabled = true;   // Temp set to true, if not enabled, it will reset to false.
      if (p.equals("HIGH"))
        forcedPowerMode = PowerMode.HIGH;
      else if (p.equals("NORMAL"))
        forcedPowerMode = PowerMode.NORMAL;
      else if (p.equals("SLEEPY"))
        forcedPowerMode = PowerMode.SLEEPY;
      else if (p.equals("MINIMAL")) {
        console.log("forcePowerMode set to MINIMAL, I wouldn't do that if I were you!");
        forcedPowerMode = PowerMode.MINIMAL;
      }
      // Anything else (e.g. "NONE")
      else {
        forcePowerModeEnabled = false;
      }
    }
    
    public void setForcedPowerMode(PowerMode p) {
      forcePowerModeEnabled = true;
      forcedPowerMode = p;
      if (p == PowerMode.MINIMAL) {
        console.log("forcePowerMode set to MINIMAL, I wouldn't do that if I were you!");
      }
    }
    
    public void disableForcedPowerMode() {
      forcePowerModeEnabled = false;
    }
    
    public void setPowerSaver(boolean b) {
      power.powerSaver = b;
      
      if (b)
        forcePowerModeEnabled = false;
      else {
        setPowerMode(PowerMode.NORMAL);
        forceFPSRecoveryMode();
      }
    }
    
    public boolean getPowerSaver() { return powerSaver; }
    
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
      try {
        int percent = Integer.parseInt(str);
        return percent;
      }
      catch (NumberFormatException ex) {
        throw new NoBattery("Battery not found..? ("+str+")");
      }
    }
  
    public boolean isCharging() {
      //return (powerStatus.getACLineStatusString().equals("Online"));
      return false;
    }
  
    public void updatePowerModeNow() {
      lastPowerCheck = millis();
    }
  
    public void setSleepy() {
      if (dynamicFramerate) {
        if (!isCharging() && !noBattery && !sleepyMode) {
          sleepyMode = true;
          powerModeBefore = getPowerMode();
          lastPowerCheck = millis()+POWER_CHECK_INTERVAL;
        }
      } else {
        sleepyMode = false;
      }
    }
  
    // You shouldn't call this every frame
    public void setAwake() {
      sleepyMode = false;
      if (getPowerMode() == PowerMode.SLEEPY) {
        putFPSSystemIntoGraceMode();
        setPowerMode(powerModeBefore);
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
          frameRate(10);
          //console.log("Power mode SLEEPY");
          break;
        case MINIMAL:
          frameRate(2); //idk for now
          //console.log("Power mode MINIMAL");
          break;
        }
      }
    }
  
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
      
      if (app.focused) {
        if (!focusedMode) {
          setPowerMode(prevPowerMode);
          focusedMode = true;
          putFPSSystemIntoGraceMode();
          sound.setNormalVolume();
        }
      } else if (allowMinimizedMode) {
        if (focusedMode) {
          prevPowerMode = powerMode;
          setPowerMode(PowerMode.MINIMAL);
          focusedMode = false;
          input.releaseAllInput();
          
          if (playWhileUnfocused)
            sound.setQuietVolume();
          else
            sound.setMasterVolume(0.);  // Mute
        }
        return;
      }
  
      if (millis() > lastPowerCheck) {
        lastPowerCheck = millis()+POWER_CHECK_INTERVAL;
  
        // If we specifically requested slow, then go right ahead.
        if (sleepyMode) {
          prevPowerMode = powerMode;
          fpsTrackingMode = SLEEPY;
          setPowerMode(PowerMode.SLEEPY);
        }
      }
      //if (!isCharging() && !noBattery && sleepyMode) {
      //  prevPowerMode = powerMode;
      //  fpsTrackingMode = SLEEPY;
      //  setPowerMode(PowerMode.SLEEPY);
      //  return;
      //}
      
      if (sleepyMode) return;
        
      // If forced power mode is enabled, don't bother with the powermode selection algorithm below.
      if (forcePowerModeEnabled) {
        if (powerMode != forcedPowerMode) setPowerMode(forcedPowerMode);
        return;
      }

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
              fpsScore -= scoreDrain;
              //console.log(str(scoreDrain*scoreDrain));
              //console.log(str(fpsScore));
            } else {
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
              // The lower our framerate, the less likely (or rather longer it takes) to get back to it.
              recoveryScore = PApplet.pow((frameRate/stableFPS), RECOVERY_NEGLIGENCE);
              // Reset the score.
              fpsScore = FPS_SCORE_MIDDLE;
              scoreDrain = 0.;
    
              // Set the power mode down a level.
              switch (powerMode) {
              case HIGH:
                setPowerMode(PowerMode.NORMAL);
                break;
              case NORMAL:
                //setPowerMode(PowerMode.SLEEPY);
                // Because sleepy is a pretty low framerate, chances are we just hit a slow
                // spot and will speed up soon. Let's give ourselves a bit more recoveryScore
                // so that we're not stuck slow forever.
                //recoveryScore += 1;
                fpsScore = FPS_SCORE_MIDDLE;
                break;
              case SLEEPY:
                // Raise this to true to enable any other bits of the code to perform performance-saving measures.
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
                n = 1;
                break;
              case NORMAL:
                // Cap it out at 30fps when in power saver mode.
                if (getPowerSaver()) {
                  fpsScore = FPS_SCORE_RECOVERY;
                  n = 2;
                }
                else {
                  setPowerMode(PowerMode.HIGH);
                  n = 1;
                }
                break;
              case SLEEPY:
                setPowerMode(PowerMode.NORMAL);
                n = 2;
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
              // Record the next so and so frames.
              framerateBuffer = new float[RECOVERY_PHASE_1_FRAMES/n];
              recoveryPhase = 1;
            }
          }
        } else if (fpsTrackingMode == RECOVERY) {
          // Record the fps, as long as we're not waiting to go back into MONITOR mode.
          if (recoveryPhase != 3)
            framerateBuffer[recoveryFrameCount++] = display.getLiveFPS();
    
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
              framerateBuffer = new float[RECOVERY_PHASE_2_FRAMES/n];
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
              switch (powerMode) {
              case HIGH:
                setPowerMode(PowerMode.NORMAL);
                break;
              case NORMAL:
                // For the sake of this system what with the new delta framerate, we don't go any lower than NORMAL.
                //setPowerMode(PowerMode.SLEEPY);
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
              recoveryScore = PApplet.pow((avg/stableFPS), RECOVERY_NEGLIGENCE);
              fpsTrackingMode = MONITOR;
            }
          }
        } else if (fpsTrackingMode == SLEEPY) {
        } else if (fpsTrackingMode == GRACE) {
          graceTimer++;
          if (graceTimer > (240/n))
            fpsTrackingMode = MONITOR;
        }  
        
        //console.log(fpsScore);
        //console.log(getPowerModeString());
    }
    
    public boolean getSleepyMode() {
      return sleepyMode;
    }
    
    public void setSleepyMode(boolean b) {
      sleepyMode = b;
    }
    
    //public Kernel32.SYSTEM_POWER_STATUS powerStatus;
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  private HashSet<String> loadedContent;
  
  public class DisplayModule {
    // Display system
    private float displayScale = 2.0;
    public PImage errorImg;
    public PShader errShader;
    private HashMap<String, PImage> systemImages = new HashMap<String, PImage>();;
    public HashMap<String, PFont> fonts = new HashMap<String, PFont>();;
    private HashMap<String, PShaderEntry> shaders = new HashMap<String, PShaderEntry>();;
    public  float WIDTH = 0, HEIGHT = 0;
    private int loadingFramesLength = 0;
    private int lastFrameMillis = 0;
    private int thisFrameMillis = 0;
    private int totalTimeMillis = 0;
    private float time = 0.;
    private float selectBorderTime = 0.;
    public boolean showCPUBenchmarks = false;
    public PGraphics currentPG;
    public boolean phoneMode = false;
    
    public final float BASE_FRAMERATE = 60.;
    private float delta = 0.;
    private float forcedDelta = -1f;
    public boolean wireframe;
    
    public boolean showFPS = false;
    
    public long rendererTime = 0;
    public long logicTime  = 0;
    public long idleTime  = 0;
    private long lastTime = 0;
    
    public int RENDER_TIME = 1;
    public int LOGIC_TIME  = 2;
    public int IDLE_TIME   = 3;
    
    public int timeMode = LOGIC_TIME;
    
    class PShaderEntry {
      public PShaderEntry(PShader s, String p) {
        shader = s;
        filepath = p;
      }
      public PShader shader;
      public String filepath = "";
      public boolean compiled = false;
      public boolean success = false;
    }
    
    public void recordRendererTime() {
      long time = System.nanoTime();
      if (timeMode == LOGIC_TIME) {
        logicTime += time-lastTime;
      }
      lastTime = time;
      timeMode = RENDER_TIME;
    }
    
    public PImage getImg(String name) {
      PImage img = systemImages.get(name);
      if (img != null) {
        return img;
      }
      else {
        console.warnOnce("Image "+name+" doesn't exist.");
        return errorImg;
      }
    }
    
    public void recordLogicTime() {
      long time = System.nanoTime();
      if (timeMode == RENDER_TIME) {
        rendererTime += time-lastTime;
      }
      lastTime = time;
      timeMode = LOGIC_TIME;
    }
    
    public int getRendererTime() {
      return (int)rendererTime;
    }
    
    public int getLogicTime() {
      return (int)logicTime;
    }
    
    public void resetTimes() {
      lastTime = System.nanoTime();
      rendererTime = 0;
      logicTime = 0;
    }
    
    
    public void showBenchmarks() {
      app.pushMatrix();
      app.scale(displayScale);
      
      app.noStroke();
      
      int totalTime = (totalTimeMillis*1000000);
      
      float wi = WIDTH*0.8;
      
      try {
        app.fill(127);
        app.rect(WIDTH*0.1, 10, wi, 50);
        
        float logic = wi*(((float)logicTime/(float)totalTime));
        app.fill(color(0,255,0));
        app.rect(WIDTH*0.1, 10, logic, 50);
        app.fill(255);
        app.textAlign(LEFT, CENTER);
        app.text("logic", WIDTH*0.1+10, 30);
        
        float opengl = wi*((float)rendererTime/(float)totalTime);
        app.fill(color(0,0,255));
        app.rect(WIDTH*0.1+logic, 10, opengl, 50);
        app.fill(255);
        app.textAlign(LEFT, CENTER);
        app.text("opengl", WIDTH*0.1+logic+10, 30);
      }
      catch (ArithmeticException e) {}
      app.popMatrix();
    }
    
    
    public DisplayModule() {
        // Set the display scale; since I've been programming this with my Surface Book 2 at high density resolution,
        // the original display area is 1500x1000, so we simply divide this device's display resolution by 1500 to
        // get the scale.
        displayScale = width/1500.;
        WIDTH = width/displayScale;
        HEIGHT = height/displayScale;
        
        if (HEIGHT > WIDTH) {
          displayScale *= 2.;
          phoneMode = true;
        }
        else phoneMode = false;
        
        console.info("init: width/height set to "+str(WIDTH)+", "+str(HEIGHT));
        
        generateErrorImg();
        generateErrorShader();
        currentPG = g;
        
        showFPS = settings.getBoolean("show_fps", false);
        
        resetTimes();
    }
    
    public void setShowFPS(boolean b) {
      showFPS = b;
    }
    
    public boolean showFPS() {
      return showFPS;
    }
    
    private void generateErrorImg() {
      errorImg = createImage(32, 32, RGB);
      errorImg.loadPixels();
      for (int i = 0; i < errorImg.pixels.length; i++) {
        errorImg.pixels[i] = color(255, 0, 255);
      }
      errorImg.updatePixels();
    }
    
    private void generateErrorShader() {
      String[] vertSrc = {
      "uniform mat4 transformMatrix;",
      "attribute vec4 position;",
      "attribute vec4 color;",
      "varying vec4 vertColor;",
      "void main() {",
      "  gl_Position = transformMatrix * position;",
      "  vertColor = color;",
      "}"};
      
      String[] fragSrc = {
      "#ifdef GL_ES",
      "precision mediump float;",
      "#endif",
      "uniform vec4 color;",
      "uniform float intensity;",
      "void main() {",
      "gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);",
      "}"};
      
      errShader = new PShader(app, vertSrc, fragSrc);
    }
    
    public float getScale() {
      return displayScale;
    }
    
    public void clip(float x, float y, float wi, float hi) {
      currentPG.imageMode(CORNER);
      if (currentPG == g) {
        app.clip(x*displayScale, y*displayScale, wi*displayScale, hi*displayScale);
      }
      else {
        currentPG.clip(x, y, wi, hi);
      }
    }
    
    public void noClip() {
      currentPG.noClip();
    }
    
    // Since loading essential content only really takes place at the beginning,
    // we can free some memory by clearing the temp info in loadedcontent.
    // Just make sure not to load all content again!
    public void clearLoadingVars() {
      loadedContent.clear();
      systemImages.clear();
    }
    
    public void loadShader(String path) {
      // Ignore the warning in android cus we can't check if our files exist.
      if (!file.exists(path)) {
        console.bugWarn("loadShader: "+path+" doesn't exist.");
        return;
      }
      String name = file.getIsolatedFilename(path);
      String ext  = file.getExt(path);
      
      
      try {
        // If we're loading a vertex shader, we also have to load the corresponding 
        // fragment shader.
        if (ext.equals("vert")) {
          String fragPath = file.getDirLegacy(path)+"/"+name+".frag";
          // Again can't check if file exists on android, so just trust that it's there.
          if (file.exists(fragPath)) {
            PShader s = app.loadShader(fragPath, path);
            PShaderEntry shaderentry = new PShaderEntry(s, path);
            shaders.put(name, shaderentry);
            return;
          }
          else {
            // File not found, continue to the normal fragment-only code.
            console.warn("loadShader: corresponding "+name+" fragment shader file not found.");
          }
        }
      
        PShader s = app.loadShader(path);
        PShaderEntry shaderentry = new PShaderEntry(s, path);
        shaders.put(name, shaderentry);
      }
      catch (RuntimeException e) {
        console.warn(path+" couldn't be loaded due to runtime exception.");
      }
    }
  
    public void resetShader() {
      app.resetShader();
    }
    
    public void shader(String shaderName, Object... uniforms) {
      initShader(shaderName);
      app.shader(
        getShaderWithParams(shaderName, uniforms)
      );
    }
    
    
    public void reloadShaders() {
      HashMap<String, PShaderEntry> sh = new HashMap<String, PShaderEntry>(shaders);
      
      for (PShaderEntry s : sh.values()) {
        this.loadShader(s.filepath);
      }
    }
    
    public void initShader(String name) {
      PShaderEntry sh = shaders.get(name);
      
      if (sh == null) {
        console.warnOnce("Shader "+name+" not found!");
        return;
      }
      
      // Switch to the shader to force it to compile:
      if (!sh.compiled) {
        try {
          sh.shader.init();
          sh.success = true;
        }
        catch (RuntimeException e) {
          console.warn("Shader "+name+" failed to compile: ");
          String[] err = PApplet.split(e.getMessage(), "\n");
          for (String line : err) {
            console.log(line);
          }
          sh.success = false;
        }
        sh.compiled = true;
      }
      
    }
    
    public void shader(PGraphics framebuffer, String shaderName, Object... uniforms) {
      initShader(shaderName);
      framebuffer.shader(
        getShaderWithParams(shaderName, uniforms)
      );
    }
    
    public void shaderUniformList(PGraphics framebuffer, String shaderName, Object[] uniforms) {
      initShader(shaderName);
      framebuffer.shader(
        getShaderWithParams(shaderName, uniforms)
      );
    }
    
    public PShader getShader(String shaderName) {
      return getShaderWithParams(shaderName, null);
    }
    
    public PShader getShaderWithArgs(String shaderName, Object... uniforms) {
      return getShaderWithParams(shaderName, uniforms);
    }
    
    public PShader getShaderWithParams(String shaderName, Object[] uniforms) {
      PShaderEntry shentry = shaders.get(shaderName);
      if (shentry == null) {
        console.warn("Shader "+shaderName+" not found!");
        return errShader;
      }
      PShader sh = shentry.shader;
      
      if (!shaders.get(shaderName).success) return errShader;
      
      if (uniforms == null) return sh;
      
      int l = uniforms.length;
      
      for (int i = 0; i < l; i++) {
        Object o = uniforms[i];
        if (o instanceof String) {
          if (i+1 < l) {
            if (!(uniforms[i+1] instanceof Float)) {
              console.bugWarn("Invalid arguments ("+shaderName+"), uniform name needs to be followed by value.1");
              //println((uniforms[i+1]));
              return sh;
            }
          } else {
            console.bugWarn("Invalid arguments ("+shaderName+"), uniform name needs to be followed by value.2");
            return sh;
          }
  
          int numArgs = 0;
          float args[] = new float[4];   // There can only ever be at most 4 args.
          for (int j = i+1; j < l; j++) {
            if (uniforms[j] instanceof Float) args[numArgs++] = (float)uniforms[j];
            else if (uniforms[j] instanceof String) break;
            else {
              console.bugWarn("Invalid uniform argument for shader "+shaderName+".");
              return sh;
            }
            if (numArgs > 4) {
              console.bugWarn("There can only be at most 4 uniform args ("+shaderName+").");
              return sh;
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
            console.bugWarn("Uh oh, that might be a bug (useShader).");
            return sh;
          }
          i += numArgs;
        } else {
          console.bugWarn("Invalid uniform argument for shader "+shaderName+".");
        }
      }
      return sh;
    }
    
    public void setPGraphics(PGraphics p) {
      currentPG = p;
    }
    
    public void img(String name, float vx1, float vy1, float vx2, float vy2, float vx3, float vy3, float vx4, float vy4) {
      if (systemImages.get(name) != null) {
        img(systemImages.get(name), vx1, vy1, vx2, vy2, vx3, vy3, vx4, vy4);
      } else {
        console.warnOnce("Image "+name+" does not exist");
      }
    }
    
    
    public void img(PImage image, float vx1, float vy1, float vx2, float vy2, float vx3, float vy3, float vx4, float vy4) {
      
      if (image == null) {
        console.warnOnce("Image listed as 'loaded' but image doesn't seem to exist.");
        return;
      }
      else if (image.width == -1 || image.height == -1) {
        image = errorImg;
        console.warnOnce("Corrupted image.");
      }
      
      
      if (image.width > 0 && image.height > 0) {
        
        
      
        currentPG.noFill();
        currentPG.noStroke();
        currentPG.beginShape(QUADS);
          
          // Annnnd a wireframe
          if (wireframe) {
            currentPG.stroke(sin(selectBorderTime)*127+127, 100);
            selectBorderTime += 0.1*getDelta();
            currentPG.strokeWeight(3);
          } else {
            currentPG.noStroke();
          }
        
          currentPG.texture(image);
          currentPG.vertex(vx1, vy1, 0f, 0f);
          currentPG.vertex(vx2, vy2, image.width, 0f);
          currentPG.vertex(vx3, vy3, image.width, image.height);
          currentPG.vertex(vx4, vy4, 0f, image.height);
        
        currentPG.endShape();
        currentPG.flush();
        
        //if (image.mode == 2) {
        //  currentPG.resetShader();
          
        //  // Annnnd a wireframe
        //  if (wireframe) {
        //    currentPG.stroke(sin(selectBorderTime)*127+127, 100);
        //    selectBorderTime += 0.1*getDelta();
        //    currentPG.noFill();
        //    currentPG.strokeWeight(3);
        //    currentPG.beginShape(QUADS);
        //    currentPG.vertex(vx1, vy1);
        //    currentPG.vertex(vx2, vy2);
        //    currentPG.vertex(vx3, vy3);
        //    currentPG.vertex(vx4, vy4);
        //    currentPG.endShape();
        //  } 
        //  currentPG.noStroke();
          
        //}
        image.pixels = null;
        
        return;
      } else {
        app.noStroke();
        return;
      }
    }
    
    
    
    public void img(PImage image, float x, float y, float w, float h) {
      
      
      if (image == null) {
        currentPG.image(errorImg, x, y, w, h);
        recordLogicTime();
        console.warnOnce("Image listed as 'loaded' but image doesn't seem to exist.");
        return;
      }
      if (image.width == -1 || image.height == -1) {
        currentPG.image(errorImg, x, y, w, h);
        recordLogicTime();
        console.warnOnce("Corrupted image.");
        return;
      }
      
      //console.log(image.width + " " + image.height + " " + image.mode);
      
      // If image is loaded render.
      if (image.width > 0 && image.height > 0) {
        // For some reason an occasional exception occures here
        try {
          currentPG.image(image, x, y, w, h);
        }
        catch (IndexOutOfBoundsException e) {
          // Doesn't matter if we don't render an image for one frame
          // if a serious error occures
          return;
        }
        catch (NullPointerException e2) {
          return;
        }
        
        // Annnnd a wireframe
        if (wireframe) {
          recordRendererTime();
          currentPG.stroke(sin(selectBorderTime)*127+127, 100);
          selectBorderTime += 0.1*getDelta();
          currentPG.strokeWeight(3);
          currentPG.noFill();
          
          currentPG.beginShape(QUADS);
          currentPG.vertex(x, y);
          currentPG.vertex(x+w, y);
          currentPG.vertex(x+w, y+h);
          currentPG.vertex(x, y+h);
          currentPG.endShape();
          
          currentPG.noStroke();
        } else {
          currentPG.noStroke();
        }
        return;
      } else {
        app.noStroke();
        return;
      }
    }
  
    public void img(String name, float x, float y, float w, float h) {
      PImage image = systemImages.get(name);
      if (image != null) {
        img(image, x, y, w, h);
      } else {
        recordRendererTime();
        currentPG.image(errorImg, x, y, w, h);
        recordLogicTime();
        console.warnOnce("Image "+name+" does not exist");
      }
    }
  
    public void img(String name, float x, float y) {
      PImage image = systemImages.get(name);
      if (image != null) {
        img(image, x, y, image.width, image.height);
      } else {
        recordRendererTime();
        currentPG.image(errorImg, x, y, errorImg.width, errorImg.height);
        recordLogicTime();
        console.warnOnce("Image "+name+" does not exist");
      }
    }
  
  
    public void imgCentre(String name, float x, float y, float w, float h) {
      PImage image = systemImages.get(name);
      if (image == null) {
        //img(errorImg, x-errorImg.width/2, y-errorImg.height/2, w, h);
      } else {
        img(image, x-w/2, y-h/2, w, h);
      }
    }
  
    public void imgCentre(String name, float x, float y) {
      PImage image = systemImages.get(name);
      if (image == null) {
        //img(errorImg, x-errorImg.width/2, y-errorImg.height/2, errorImg.width, errorImg.height);
      } else {
        img(image, x-image.width/2, y-image.height/2, image.width, image.height);
      }
    }
    
    // TODO: Allow all os system fonts
    // PFont.list()
    public PFont getFont(String name) {
      PFont f = display.fonts.get(name);
      if (f == null) {
        console.warnOnce("Couldn't find font "+name+"!");
        // Idk just use this font as a placeholder instead.
        return createFont("Monospace", 128);
      } else return f;
    }
    
    public float getLiveFPS() {
      float timeframe = 1000/BASE_FRAMERATE;
      return (timeframe/float(thisFrameMillis-lastFrameMillis))*BASE_FRAMERATE;
    }
    
    
    public void displayScreens() {
      // Set the display scale; since I've been programming this with my Surface Book 2 at high density resolution,
      // the original display area is 1500x1000, so we simply divide this device's display resolution by 1500 to
      // get the scale.
      displayScale = float(app.width)/1500.;
      
      if (HEIGHT > WIDTH) {
        displayScale *= 2.;
        phoneMode = true;
      }
      else phoneMode = false;
      
      WIDTH = float(app.width)/displayScale;
      HEIGHT = float(app.height)/displayScale;
      
      
      if (transitionScreens) {
        power.setAwake();
  
        // Sorry for the code duplication!
        switch (transitionDirection) {
          case RIGHT:
            app.pushMatrix();
            getPrevScreen().screenx = ((WIDTH*transition)-WIDTH)*displayScale;
            getPrevScreen().display();
            app.popMatrix();
    
    
            app.pushMatrix();
            currScreen.screenx = ((WIDTH*transition)*displayScale);
            currScreen.display();
            app.popMatrix();
            break;
          case LEFT:
            app.pushMatrix();
            prevScreenTransition.screenx = ((WIDTH-(WIDTH*transition))*displayScale);
            prevScreenTransition.display();
            app.popMatrix();
    
    
            app.pushMatrix();
            currScreen.screenx = ((-WIDTH*transition)*displayScale);
            currScreen.display();
            app.popMatrix();
            break;
        }
        transition = ui.smoothLikeButter(transition);
            //console.log("currScreen: "+currScreen.getClass().getSimpleName());
            //console.log("prevScreen: "+getPrevScreen().getClass().getSimpleName());
  
        if (transition < 0.001) {
          transitionScreens = false;
          currScreen.startupAnimation();
          if (prevScreenTransition != null) {
            prevScreenTransition.endScreenAnimation();
            prevScreenTransition = null;
          }
          
          //console.log("END");
  
          // If we're just getting started, we need to get a feel for the framerate since we don't want to start
          // slow and choppy. Once we're done transitioning to the first (well, after the startup) screen, go into
          // FPS recovery mode.
          if (initialScreen) {
            initialScreen = false;
            power.setPowerMode(PowerMode.NORMAL);
            power.forceFPSRecoveryMode();
          }
          //prevScreen = null;
        }
      } else {
        currScreen.display();
      }
      display.recordLogicTime();
    }
    
    public void update() {
      totalTimeMillis = thisFrameMillis-lastFrameMillis;
      lastFrameMillis = thisFrameMillis;
      thisFrameMillis = app.millis();
      // Limit delta to 7.5.
      // This means the entire application starts running slow below 8fps
      // lol
      // But sudden lag frames won't be a problem
      delta = min(BASE_FRAMERATE/display.getLiveFPS(), 7.5);
      
      // Also update the time while we're at it.
      time += delta;
    }
    
    public void forceDelta(float forcedDelta) {
      this.forcedDelta = forcedDelta;
    }
    
    public float getDelta() {
      if (forcedDelta > 0f) return forcedDelta;
      return delta;
    }
    
    // Frames since the beginning of the program, accounting for missed frames (always 1 second = 60 frames, even if running at 30fps)
    public float getTime() {
      return time;
    }
    
    public float getTimeSeconds() {
      return time/display.BASE_FRAMERATE;
    }
    
    // Same as getTimeSeconds() but resets after every 1 second.
    public float getTimeSecondsLoop() {
      float t = getTimeSeconds();
      return t-floor(t);
    }
  }
















  public class UIModule {
    
    public float guiFade = 0;
    public SpriteSystemPlaceholder currentSpritePlaceholderSystem;
    public boolean spriteSystemClickable = false;
    public MiniMenu currMinimenu = null;
    public SpriteSystemPlaceholder dummySpriteSystem;
    
    // To be used by API.
    public HashMap<String, SpriteSystemPlaceholder> spriteSystems;
    public boolean usingTWITSpriteSystem = false;
    
    
    
    
    
    
    
    
    public class MiniMenu {
        public SpriteSystemPlaceholder g;
        public float x = 0., y = 0.;
        public float width = 0., height = 0.;
        public float yappear = 1.;
        public boolean disappear = false;

        final public float APPEAR_SPEED = 0.2;
        final public color BACKGROUND_COLOR = color(0, 0, 0, 150);
        
        public MiniMenu() {
            power.setAwake();
            yappear = 1.;
            sound.playSound("fade_in");
        }
        
        public MiniMenu(float x, float y) {
          this();
          this.x = x;
          this.y = y;
        }
        
        public MiniMenu(float x, float y, float w, float h) {
          this(x, y);
          this.width = w;
          this.height = h;
        }

        public void close() {
            // Only bother closing if we're not in any current animation
            if (!disappear && yappear <= 0.01) {
                disappear = true;
                power.setSleepy();
                yappear = 1.;
                sound.playSound("fade_out");
            }
        }

        public void display() {
            app.noTint();
            // Sorry I'm lazy
            
            yappear *= PApplet.pow(1.-APPEAR_SPEED, display.getDelta());
            
            app.noStroke();
            app.fill(BACKGROUND_COLOR);

            // Cool menu appaer animation. Or disappear animation.
            if (!disappear) {
                float h = this.height-(this.height*yappear);
                app.rect(x, y, this.width, h);
                display.clip(x, y, this.width, h);
            }
            else {
                app.rect(x, y, this.width, this.height*yappear);
                display.clip(x, y, this.width, this.height*yappear);
                if (yappear <= 0.01) {
                    power.setSleepy();
                    currMinimenu = null;
                }
            }
            
            

            // If we click away from the minimenu, close the minimenu
            if ((mouseX() > x && mouseX() < x+this.width && mouseY() > y && mouseY() < y+this.height) == false) {

                if (input.primaryOnce) {
                    close();
                }
            }
            //app.noClip();
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    public class OptionsMenu extends MiniMenu {
      private ArrayList<String> options = new ArrayList<String>();
      private ArrayList<Runnable> actions = new ArrayList<Runnable>();
      private String selectedOption = null;
      private static final float SIZE = 30.;
      private static final float SPACING = 10.;
      private static final float OFFSET_SPACING_X = 50.;
      private static final color HOVER_COLOR = 0xFFC200FF;
      
      // Keep track if the menu has been selected, and if it has, set this to
      // false so that our selected action is only performed once (might loop
      // during the closing animation of the MiniMenu)
      private boolean selectable = true;
      
      // Deprecated.
      //public OptionsMenu(String... opts) {
      //  super(mouseX(), mouseY());
        
      //  float maxWidth = 0.;
      //  float hi = 0.;        
      //  app.textFont(DEFAULT_FONT, SIZE);
      //  for (String op : opts) {
      //    options.add(op);
      //    float wi = app.textWidth(op);
      //    if (wi > maxWidth) maxWidth = wi;
      //    hi += SIZE+SPACING;
      //  }
        
      //  this.width = maxWidth+SPACING*2.+OFFSET_SPACING_X;
      //  this.height = hi+SPACING;
      //}
      
      public OptionsMenu(String[] opts, Runnable[] acts) {
        super(mouseX(), mouseY());
        
        float maxWidth = 0.;
        float hi = 0.;        
        app.textFont(DEFAULT_FONT, SIZE);
        
        if (opts.length != acts.length) {
          console.bugWarn("OptionsMenu: options and actions not equal length.");
        }
        else {
          for (int i = 0; i < opts.length; i++) {
            options.add(opts[i]);
            actions.add(acts[i]);
            float wi = app.textWidth(opts[i]);
            if (wi > maxWidth) maxWidth = wi;
            hi += SIZE+SPACING;
          }
        }
        
        
        this.width = maxWidth+SPACING*2.+OFFSET_SPACING_X;
        this.height = hi+SPACING;
        
        // lil fix
        if (this.y+this.height > display.HEIGHT) {
          this.y = mouseY()-this.height;
        }
      }
      
      public OptionsMenu(ArrayList<String> opts, ArrayList<Runnable> acts) {
        super(mouseX(), mouseY());
        
        float maxWidth = 0.;
        float hi = 0.;        
        app.textFont(DEFAULT_FONT, SIZE);
        
        options = opts;
        actions = acts;
        
        for (int i = 0; i < opts.size(); i++) {
          float wi = app.textWidth(opts.get(i));
          if (wi > maxWidth) maxWidth = wi;
          hi += SIZE+SPACING;
        }
        
        this.width = maxWidth+SPACING*2.+OFFSET_SPACING_X;
        this.height = hi+SPACING;
      }
      
      
      public void display() {
        super.display();
        if (selectedOption != null) 
          selectable = false;
        
        app.textFont(DEFAULT_FONT, SIZE);
        app.textAlign(LEFT, TOP);
        
        float yy = this.y+SPACING;
        for (int i = 0; i < options.size(); i++) {
          String op = options.get(i);
          float xx = this.x+OFFSET_SPACING_X+SPACING;
          if (mouseX() > this.x && mouseX() < this.x+this.width && mouseY() > yy && mouseY() < yy+SIZE+SPACING) {
            app.fill(HOVER_COLOR);
            if (input.primaryOnce && selectable) {
              sound.playSound("select_any");
              actions.get(i).run();
              selectedOption = op;
              this.close();
            }
          }
          else app.fill(255);
          app.text(op, xx, yy);
          yy += SIZE+SPACING;
        }
      }
      
      public boolean optionSelected() {
        if (!selectable) return false;
        return (selectedOption != null);
      }
    }
    
    public void createOptionsMenu(String[] opts, Runnable[] acts) {
      currMinimenu = new OptionsMenu(opts, acts);
    }
    
    
    
    
    
    
    
    
    
    
    // BIG TODO: Obviously we want to pimp up this menu and add more colors.
    // This is probably one of the oldest yet most used code in Timeway that hasn't been updated in FOREVER.
    public class ColorPicker extends MiniMenu {
        public boolean selected = false;
        public color selectedColor;
        public Runnable runWhenPicked = null;
      
        public color[] colorArray = {
            //ffffff
            color(255, 255, 255),
            //909090
            color(144, 144, 144),
            //4d4d4d
            color(77, 77, 77),
            //000000
            color(0, 0, 0),
            //ffde96
            color(255, 222, 150),
            //ffc64b
            color(255, 198, 75),
            //ffae00
            color(255, 174, 0),
            //ffb4f6
            color(255, 180, 246),
            //ff89b9
            color(255, 137, 185),
            //ff5d5f
            color(255, 93, 95),
            //cab9ff
            color(202, 185, 255),
            //727aff
            color(114, 122, 255),
            //38a7ff
            color(56, 167, 255),
            
            color(189, 226, 149)
        };

        public int maxCols = 6;


        public ColorPicker(float x, float y, float width, float height, Runnable r) {
            super(x, y, width, height);
            runWhenPicked = r;
        }

        public void display() {
            // Super display to display the background
            super.display();
            //app.tint(255, 255.*yappear);


            // display all the colors in the colorArray, in a grid, with a new row every MAX_COLS

            float spacing = 20;
            float selSize = 5;

            // The width of each color box
            float boxWidth = (this.width/maxCols);
            // The height of each color box
            // The height of the box is the aspect ratio of the minimenu
            float boxHeight = boxWidth*(this.height/this.width);
            // Loop through each colour
            for (int i = 0; i < colorArray.length; i++) {
                // The x position of the color box
                // Give it a bit of space between each box
                float boxX = this.x+(i%maxCols)*boxWidth;
                // The y position of the color box
                float boxY = this.y+(spacing/2)+(i/maxCols)*boxHeight;
                // The color of the color box
                color boxColor = colorArray[i];

                boolean wasHovered = false;
                // If the mouse is hovering over the color box, tint it
                if (mouseX() > boxX-selSize && mouseX() < boxX+boxWidth+selSize && mouseY() > boxY-selSize && mouseY() < boxY+boxHeight+selSize) {
                    boxX -= selSize;
                    boxY -= selSize;
                    boxWidth += selSize*2;
                    boxHeight += selSize*2;
                    wasHovered = true;

                    // If clicked 
                    if (input.primaryOnce && !disappear) {
                        selectedColor = colorArray[i];
                        
                        if (runWhenPicked != null) {
                          sound.playSound("select_color");
                          runWhenPicked.run();
                        }
                        
                        close();
                    }
                }

                // Display the color box
                app.fill(boxColor);
                app.rect((spacing/2)+boxX, boxY, boxWidth-spacing, boxHeight-(spacing/2));

                if (wasHovered) {
                    // Shrink the width n height back to what it was before
                    boxX += selSize;
                    boxY += selSize;
                    boxWidth -= selSize*2;
                    boxHeight -= selSize*2;
                }
            }

            //Remember to call noTint
            app.noTint();
        }
    }
    
    
    public void colorPicker(float x, float y, Runnable runWhenPicked) {
      float wi = 300., hi = 200.;
      if (display.phoneMode) {
        wi = 450.;
        hi = 300.;
      }
      if (x+wi > display.WIDTH) {
        x = display.WIDTH-wi;
      }
      currMinimenu = new ColorPicker(x, y, wi, hi, runWhenPicked);
    }
    
    public color getPickedColor() {
      if (!(currMinimenu instanceof ColorPicker)) {
        console.bugWarn("getPickedColor: currMinimenu is not a ColorPicker!");
        return 0;
      }
      return ((ColorPicker)currMinimenu).selectedColor;
    }
    
    
    public void displayMiniMenu() {
      // Display the minimenu in front of all the buttons.
      if (miniMenuShown()) {
          app.pushMatrix();
          app.scale(display.getScale());
          currMinimenu.display();
          app.noClip();
          app.popMatrix();
      }
    }
    
    public void display() {
      displayMiniMenu();
    }
    
    
    ///////////////////////////////////////////////////////
    // CUSTOM SLIDERS
    
    // When the user is clicking and dragging a node, the occupied node is set here so that it can continue to be scrolled and
    // other scrollNodes don't intervene.
    private CustomNode usingNode = null;
    
    public abstract class CustomNode {
      public String label = "";
      public float x = 0.;
      public float wi = 100.;
      private float y = 0;
      
      public float valFloat = 0.;
      public boolean valBool = false;
      public int valInt = 0;
      
      public static final float CONTROL_X = 300.;
      public CustomNode(String l) {
        label = l;
      }
      
      public float getHeight() {
        return 100.;
      }
      
      public boolean inBox() {
        boolean hovering = (mouseX() > x+CONTROL_X-10 && mouseY() > y && mouseX() < x+wi+10 && mouseY() < y+getHeight());
        return hovering && !miniMenuShown();
      }
      
      public boolean getValBool() {
        return false;
      }
      
      public boolean mouseDown() {
        return usingNode == this;
      }
      
      public void detectUserInput() {
        if (usingNode == null && inBox() && input.primaryOnce) {
          usingNode = this;
        }
        if (usingNode != null && !input.primaryDown) {
          usingNode = null;
        }
      }
      
      public void display(float x, float y) {
        this.x = x;
        this.y = y;
        y += 20;
        
        detectUserInput();
        
        app.fill(255);
        app.textFont(DEFAULT_FONT, 20);
        app.textAlign(LEFT, CENTER);
        
        app.text(label, x, y);
      }
    }
    
    public class CustomSlider extends CustomNode {
      public float min = 0.;
      public float max = 100.;
      protected String maxLabel = null;
      protected String minLabel = null;
      
      
      public CustomSlider(String l, float min, float max, float initVal) {
        super(l);
        this.min = min;
        this.max = max;
        this.valFloat = initVal;
      }
      
      @Override
      public float getHeight() {
        return 40.;
      }
      
      protected void getSliderVal() {
        if (usingNode == this) {
          app.stroke(160);
          valFloat = min+((mouseX()-x-CONTROL_X)/(wi-CONTROL_X))*(max-min);
          valFloat = min(max(valFloat, min), max);
          power.setAwake();
        }
        else if (usingNode == null) {
          if (inBox()) {
            app.stroke(160);
          }
          else {
            app.stroke(127);
          }
        }
        else {
          app.stroke(127);
        }
      }
      
      protected void showVal(float y) {
        app.fill(255);
        app.textFont(DEFAULT_FONT, 26);
        app.textAlign(RIGHT, CENTER);
        
        String disp = nf(valFloat, 0, 2);
        if (valFloat == max && maxLabel != null) disp = maxLabel;
        if (valFloat == min && minLabel != null) disp = minLabel;
        app.text(disp, x+CONTROL_X-12, y);
      }
      
      public void setVal(float val) {
        this.valFloat = val;
      }
      
      protected void renderSlider(float y) {
        app.strokeWeight(5);
        app.line(x+CONTROL_X, y, x+wi, y);
        
        app.noStroke();
        app.fill(255);
        
        float percentage = (valFloat-min)/(max-min);
        
        app.rect(x+CONTROL_X+percentage*(wi-CONTROL_X)-5, y-15, 10, 30);
      }
      
      public void display(float x, float y) {
        super.display(x, y);
        y += 20;
        getSliderVal();
        showVal(y);
        renderSlider(y);
      }
      
      public void setWhenMax(String label) {
        maxLabel = label;
      }
      
      public void setWhenMin(String label) {
        minLabel = label;
      }
    }
    
    
    public class CustomSliderInt extends CustomSlider {
      
      public CustomSliderInt(String l, int min, int max, int initVal) {
        super(l, (float)min, (float)max, (float)initVal);
        setVal(initVal);
      }
      
      public void setVal(int val) {
        this.valFloat = (float)val;
      }
      
      @Override
      protected void showVal(float y) {
        app.fill(255);
        app.textFont(DEFAULT_FONT, 26);
        app.textAlign(RIGHT, CENTER);
        
        String disp = str((int)round(valFloat));
        if (valFloat == max && maxLabel != null) disp = maxLabel;
        if (valFloat == min && minLabel != null) disp = minLabel;
        app.text(disp, x+CONTROL_X-12, y);
      }
      
      @Override
      protected void renderSlider(float y) {
        app.strokeWeight(5);
        app.line(x+CONTROL_X, y, x+wi, y);
        
        app.noStroke();
        app.fill(255);
        
        valInt = round(valFloat);
        float percentage = (round(valFloat)-min)/(max-min);
        app.rect(x+CONTROL_X+percentage*(wi-CONTROL_X)-5, y-15, 10, 30);
      }
    }
    
    
    
    
    
    
    
    
    
    
    
    public UIModule() {
      
    }

  
    public void useSpriteSystem(SpriteSystemPlaceholder system) {
      this.currentSpritePlaceholderSystem = system;
      this.spriteSystemClickable = true;
      this.guiFade = 255.;
      usingTWITSpriteSystem = false;
    }
    
    public boolean buttonImg(String img, float x, float y, float w, float h) {
      display.img(img, x, y, w, h);
      
      if (miniMenuShown()) return false;
      return (mouseInArea(x, y, w, h) && input.primaryOnce);
    }
    
    public boolean mouseInArea(float x, float y, float w, float h) {
      if (miniMenuShown()) return false;
      return (input.mouseX() > x && input.mouseX() < x+w && input.mouseY() > y && input.mouseY() < y+h);
    }
    
    public boolean buttonHoverVary(String name) {
      if (display.phoneMode) {
        name += "-phone";
      }
      return buttonHover(name);
    }
    
    public boolean buttonHover(String name) {
      if (this.currentSpritePlaceholderSystem == null) {
        console.bugWarn("You forgot to call useSpriteSystem()!");
        return false;
      }
      
      return (currentSpritePlaceholderSystem.buttonHover(name) && !currentSpritePlaceholderSystem.interactable && spriteSystemClickable);
    }
    
    // This vary version has multiple types of buttons (normal and phone) for different size configurations.
    public boolean buttonVary(String name, String texture, String displayText) {
      if (display.phoneMode) {
        return button(name+"-phone", texture, displayText);
      }
      else {
        return button(name, texture, displayText);
      }
    }
  
    public boolean button(String name, String texture, String displayText) {
  
      if (this.currentSpritePlaceholderSystem == null) {
        console.bugWarn("You forgot to call useSpriteSystem()!");
        return false;
      }
  
      // This doesn't change at all.
      // I just wanna keep it in case it comes in useful later on.
      //boolean guiClickable = true;
  
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
      if (buttonHover(name)) {
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
      
      if (miniMenuShown()) return false;
  
      // Only when the button is actually clicked.
      return hover && input.primaryOnce;
    }
    
    public boolean basicButton(String display, float x, float y, float wi, float hi) {
      color c = color(200);
      
      boolean hovering = (input.mouseX() > x && input.mouseY() > y && input.mouseX() < x+wi && input.mouseY() < y+hi);
      if (hovering) c = color(255);
      
      noFill();
      stroke(c);
      rect(x+10, y, wi, hi);
      
      textSize(32);
      textAlign(CENTER, CENTER);
      fill(c);
      text(display, x+wi/2, y+hi/2);
      return hovering && input.primaryOnce;
    }
    
    public void loadingIcon(float x, float y, float widthheight) {
      display.imgCentre("load-"+appendZeros(counter(max(display.loadingFramesLength-1, 1), 3), 4), x, y, widthheight, widthheight);
    }
  
    public void loadingIcon(float x, float y) {
      loadingIcon(x, y, 128);
    }
    
  
    public float smoothLikeButter(float i) {
  
      // I wanna emulate some of the cruddy performance from the old fps system
      // so we limit the display delta especially when we get sudden fps dips.
      // Max it at 4 because that was the minimum framerate we could do in SLEEPY mode,
      // 15fps!
      float d = min(display.getDelta(), 4.);
      
      //if (input.shiftDown) {
      //  i *= pow(0.995f, d);
      //}
      //else {
      //  i *= pow(0.9f, d);
      //}
      i *= pow(0.9f, d);
      
      
      // LMAO REALLY FUNNY GLITCH, COMMENT THE LINE ABOVE AND UNCOMMENT THIS ONE BELOW!!
      // Update: the glitch no longer works it just displays a black screen (how sad)
      //i *= 0.9*display.getDelta();
  
      if (i < 0.05) {
        return i-0.001;
      }
      return i;
    }
    
    public boolean miniMenuShown() {
      return (currMinimenu != null);
    }
    
    public void addSpriteSystem(TWEngine engine, String name, String path) {
      if (spriteSystems == null) {
        spriteSystems = new HashMap<String, SpriteSystemPlaceholder>();
      }
      spriteSystems.put(name, new SpriteSystemPlaceholder(engine, path));
    }
    
    public SpriteSystemPlaceholder getSpriteSystem(String name) {
      if (!spriteSystems.containsKey(name)) {
        console.warn("Sprite system "+name+" doesn't exist!");
        
        return dummySpriteSystem;
      }
      else {
        return spriteSystems.get(name);
      }
    }
    
    public SpriteSystemPlaceholder getInUseSpriteSystem() {
      if (currentSpritePlaceholderSystem == null) {
        // TODO: Return a blank spritesystem so that we don't crash.
        console.warn("No sprite system currently in use!");
        return null;
      }
      return currentSpritePlaceholderSystem;
    }
    
    public void updateSpriteSystems() {
      if (spriteSystems == null) return;
      for (SpriteSystemPlaceholder system : spriteSystems.values()) {
        system.updateSpriteSystem();
      }
    }
    
  }



  

















  public class AudioModule {
    private Music streamerMusic;
    private Music streamerMusicFadeTo;
    
    private float musicFadeOut = 1.;
    public final float MUSIC_FADE_SPEED = 0.95;
    public final float PLAY_DELAY = 0.3;
    public HashMap<String, SoundFile> sounds;
    private AtomicBoolean musicReady = new AtomicBoolean(true);
    private boolean startupGStreamer = true;
    private boolean reloadMusic = false;
    private String reloadMusicPath = "";
    public       float  VOLUME_NORMAL = 1.;
    public       float  VOLUME_QUIET = 0.;
    public boolean CACHE_MISS_NO_MUSIC = false;
    public boolean WAIT_FOR_GSTREAMER_START = false;
    
    public final String MUSIC_CACHE_FILE = "music_cache_02.json";
    
    // For when porting to other platforms which don't support gstreamer (*ahem* android *ahem*) 
    public boolean DISABLE_GSTREAMER = false;
    
    
    // So that we can use both SoundFile and Movie types without complicated code
    class Music {
      final int NONE = 0;
      final int CACHED = 1;
      final int STREAM = 2;
      final int ANDROID = 3;
      int mode = 0;
      boolean cacheMiss = false;
      private Movie streamMusic;
      private SoundFile cachedMusic;
      private AndroidMedia androidMusic;
      String originalPath = "";
      float volume = 0.;
      
      // Load cached music
      public Music(String path) {
        originalPath = path;
        // If music is still loading, try and get cached entry
        if (loadingMusic()) {
          //console.log("Cache music mode");
          mode = CACHED;
          
          String cachePath = tryGetMusicCache(path);
          SoundFile m = null;
          if (cachePath.equals(path)) {
            // Cache doesn't exist.
          }
          else {
            m = new SoundFile(app, cachePath);
            // TODO: Load in separate thread.
          }
          
          
          
          if (m != null) {
            cachedMusic = m;
            cachedMusic.amp(1.0);
          }
          // If cache miss, this just means we can't play any music until gstreamer has loaded.
          else {
            // 3 cases here:
            // - Don't play any music while gstreamer is still starting up
            // - Load compressed if gstreamer is starting up (slow, only if file is small enough)
            // - Play loading music if gstreamer is still starting up and file in question is too long.
            {
              // Perform size approximation.
              // FLAC files not in this list due to them not being supported by soundfile
              // therefore loading music will play in place.
              final String ext = file.getExt(path);
              boolean playDefaultLoadingMusic = true;
              
              int COMPRESSED_MAX_SIZE = 1048576*5; // 5mb
              int UNCOMPRESSED_MAX_SIZE = 1048576*50; // 50mb
              
              // We are very careful with our memory.
              if (lowMemory) {
                COMPRESSED_MAX_SIZE = 1048576*1; // 1mb
                UNCOMPRESSED_MAX_SIZE = 1048576*10; // 10mb
              }
              
              // Compressed file formats can take long to decompress,
              // so we'll only allow a minute or two at most.
              if (ext.equals("mp3") || ext.equals("ogg")) {
                File f = new File(path);
                // Fits compressed size
                //console.log("Is compressed file "+f.length());
                playDefaultLoadingMusic = (f.length() > COMPRESSED_MAX_SIZE);
                //if (playDefaultLoadingMusic) console.log("EXCEEDS max file size");
              }
              
              // Uncompressed files are much faster to load.
              // Therefore we can have a much higher threashold for wav files
              else if (ext.equals("wav")) {
                File f = new File(path);
                //console.log("Is uncompressed file "+f.length());
                playDefaultLoadingMusic = (f.length() > UNCOMPRESSED_MAX_SIZE);
                //if (playDefaultLoadingMusic) console.log("EXCEEDS max file size");
              }
              
              // Determinining default music done
              // Load default music if it's available.
              if (playDefaultLoadingMusic) {
                if (sounds.containsKey("loadingmusic") && !CACHE_MISS_NO_MUSIC) {
                  cachedMusic = sounds.get("loadingmusic");
                  mode = CACHED;
                }
                // Otherwise don't play any music.
                else mode = NONE;
              }
              // Load and play the music.
              else {
                //console.log("Cache miss, direct load");
                cachedMusic = new SoundFile(app, path, false);  // Yes, on the main thread.
                mode = CACHED;
              }
            }
            // Later we can use it in the thing etc
          }
        }
        // Otherwise use gstreamer
        else {
          //console.log("Stream music mode");
          
          if (isAndroid()) {
            mode = ANDROID;
            androidMusic = new AndroidMedia(path);
          }
          else {
            mode = STREAM;
            if (!DISABLE_GSTREAMER)
              streamMusic = new Movie(app, path);
          }
        }
      }
      
      public void play() {
        if (mode == CACHED) {
          if (!cachedMusic.isPlaying()) cachedMusic.play(); 
        } 
        else if (mode == STREAM && !DISABLE_GSTREAMER) streamMusic.play();
        else if (mode == ANDROID) androidMusic.loop();     // Here we loop cus this ain't the half-working Movie library, we can freely do that
      }
      
      public void pause() {
        if (mode == CACHED) cachedMusic.pause(); 
        else if (mode == STREAM && !DISABLE_GSTREAMER) streamMusic.pause();
        else if (mode == ANDROID) androidMusic.pause();
      }
      
      public void stop() {
        if (mode == CACHED) cachedMusic.stop(); 
        else if (mode == STREAM && !DISABLE_GSTREAMER) streamMusic.stop();
        else if (mode == ANDROID) androidMusic.stop();
      }
      
      public boolean available() {
        if (mode == STREAM && !DISABLE_GSTREAMER) return streamMusic.available();
        // No need in android
        return true;
      }
      
      public void read() {
        if (mode == STREAM && !DISABLE_GSTREAMER) streamMusic.read();
        // No need in android
      }
      
      public void volume(float vol) {
        volume = vol;
        if (mode == CACHED) cachedMusic.amp(vol);
        else if (mode == STREAM && !DISABLE_GSTREAMER) streamMusic.volume(vol);
        else if (mode == ANDROID) androidMusic.volume(vol);
      }
      
      public float duration() {
        if (mode == CACHED) return cachedMusic.duration(); 
        else if (mode == STREAM && !DISABLE_GSTREAMER) return streamMusic.duration();
        // Since android loops we don't need to worry about this (for now).
        return 0.;
      }
      
      public float time() {
        if (mode == CACHED) return cachedMusic.position(); 
        else if (mode == STREAM && !DISABLE_GSTREAMER) return streamMusic.time();
        // Since android loops we don't need to worry about this (for now).
        return 0.;
      }
      
      public void sync(float expectedTime) {
        float currentTime = this.time();
        float tolerance = 0.05;
        if ((currentTime > expectedTime+tolerance) || (currentTime < expectedTime-tolerance)) {
          
          this.jump(expectedTime);
        }
      }
      
      public void jump(float pos) {
        if (mode == CACHED) cachedMusic.jump(pos); 
        else if (mode == STREAM && !DISABLE_GSTREAMER) streamMusic.jump(pos);
        // Since android loops we don't need to worry about this (for now).
      }
      
      public boolean isPlaying() {
        if (mode == CACHED) return cachedMusic.isPlaying(); 
        else if (mode == STREAM && !DISABLE_GSTREAMER) return streamMusic.isPlaying();
        else if (mode == ANDROID) return androidMusic.isPlaying();
        return true;
      }
      
      public void setReady() {
        //if (mode == STREAM) streamMusic.playbin.setState(org.freedesktop.gstreamer.State.READY); 
      }
      
      public void playbinSetVolume(float vol) {
        volume = vol;
        if (mode == CACHED) {
          cachedMusic.amp(vol);
        }
        else if (mode == STREAM && !DISABLE_GSTREAMER) {
          streamMusic.playbin.setVolume(vol*masterVolume);
          streamMusic.playbin.getState();
        }
        else if (mode == ANDROID) {
          androidMusic.volume(vol);
        }
      }
      
      // When gstreamer finally loads, switches seamlessly to gstreamer version.
      // Note that this should not be called in android mode.
      public void switchMode() {
        if (!loadingMusic() && mode != STREAM) {
          
          if (!DISABLE_GSTREAMER) {
            streamMusic = new Movie(app, originalPath);
          
            // Transfer cachedMusic properties over to streammusic
            if (streamMusic != null) {
              streamMusic.volume(this.volume);
              
              // If cachedmusic exists then cachedmusic.isplaying = streammusic.isplaying
              // Otherwise mode must be NONE so we just kickstart the streamMusic.
              if (cachedMusic != null) {
                if (cachedMusic.isPlaying()) {
                  streamMusic.play();
                  delay(10);
                  streamMusic.jump(cachedMusic.position());
                }
              }
              else streamMusic.play();
              
              if (mode == CACHED) cachedMusic.stop();
            }
          }
          
          mode = STREAM;
        }
      }
    }
    
    public AudioModule() {
      // For now.
      if (isAndroid()) {
        DISABLE_GSTREAMER = true;
      }
      
      sounds = new HashMap<String, SoundFile>();
      CACHE_MUSIC = settings.getBoolean("music_caching", true) && enableCaching;
      VOLUME_NORMAL = settings.getFloat("volume_normal", 1f);
      VOLUME_QUIET = settings.getFloat("volume_quiet", 0.25f);
      CACHE_MISS_NO_MUSIC = settings.getBoolean("cache_miss_no_music", false);
      WAIT_FOR_GSTREAMER_START = settings.getBoolean("gstreamer_startup_wait", false);
      setMasterVolume(VOLUME_NORMAL);
      startupGStreamer = true;
    }
    
    public void setNormalVolume() {
      setMasterVolume(VOLUME_NORMAL);
    }
    
    public void setQuietVolume() {
      setMasterVolume(VOLUME_QUIET);
    }
    
    
    //@SuppressWarnings("unused")
    public void saveAsWav(SoundFile s, int sampleRate, String path) {
      // Android uses a completely different audio system and caching isn't needed 
      // (cus we don't need to wait for gstreamer to start up), so we disable caching
      // music, it's not needed.
      if (!isAndroid()) {
        AudioSample a = (AudioSample)s;
        
        // Only allow a maximum of a minute of audio data to be loaded
        int size = min(a.frames()*a.channels(), 60*a.channels()*sampleRate);
        float[] data = new float[size];
        a.read(data);
        int bitDepth = 16;
        int numChannels = a.channels();
  
        byte[] audioData = floatArrayToByteArray(data, bitDepth);
        
        saveByteArrayAsWAV(audioData, sampleRate, bitDepth, numChannels, path);
        
        updateMusicCache(path);
        
        stats.increase("music_cache_files", 1);
      }
      
      //// TODO: User may close application midway while creating wav which might end up
      //// in Timeway not loading.
    }

    //@SuppressWarnings("unused")
    private byte[] floatArrayToByteArray(float[] floatArray, int bitDepth) {
        ByteBuffer byteBuffer = ByteBuffer.allocate(floatArray.length * (bitDepth / 8));
        ByteOrder order = ByteOrder.LITTLE_ENDIAN;
        
        byteBuffer.order(order);

        if (bitDepth == 16) {
            ShortBuffer shortBuffer = byteBuffer.asShortBuffer();
            short[] shortArray = new short[floatArray.length];
            float MAX = float(Short.MAX_VALUE);
            for (int i = 0; i < floatArray.length; i++) {
                shortArray[i] = (short) (floatArray[i] * MAX);
            }
            shortBuffer.put(shortArray);
        } else if (bitDepth == 32) {
            FloatBuffer floatBuffer = byteBuffer.asFloatBuffer();
            floatBuffer.put(floatArray);
        } else {
            throw new IllegalArgumentException("Unsupported bit depth: " + bitDepth);
        }


        return byteBuffer.array();
    }
    
    
    
    // Basically checks for paths beginning with ?/ which means it's relative path
    // aka append "/path/to/Timeway/data/" at "?/"
    private String fromPossibleRelative(String path) {
      if (path == null) return null;
      
      if (path.length() > 1) {
        if (path.charAt(0) == '?' && path.charAt(1) == '/') {
          // Return relative path of timeway
          // Remember apppath includes /data/
          return APPPATH+path.substring(2);
        }
      }
      return path;
    }
    
    // Converts "C:/path/to/cache/data/" to "?/cache/data/"
    private String toPossibleRelative(String path) {
      
      path = path.replaceAll("\\\\", "/");
      // We want our cached paths to be relative
      if (path.contains(APPPATH)) {
        return "?/"+path.substring(APPPATH.length());
      }
      else {
        // Otherwise return path as is
        return path;
      }
    }
    
    
    // We don't wanna cache music files that are too small cus that will just use up unnecessary cache space.
    // At the same time, we don't wanna go over the max limit otherwise we could end up with a outofmemory exception.
    // Remember,
    // 10MB uncompressed = ~1 minute music
    private final int MIN_CACHE_SIZE = 1024*1024*6;
    private final int MAX_CACHE_SIZE = 1024*1024*60;   // Let's go with 60mb ram usage.
    private final int MAX_CACHE_SIZE_LOW_MEM = 1024*1024*20;
    private AtomicBoolean caching = new AtomicBoolean(false);
    
    // Pass forceScore = -1 to disable force score.
    private void updateMusicCache(final String ppath) {
      if (DISABLE_GSTREAMER) return;
      
      if ((!CACHE_MUSIC || isAndroid())) return;
      
      final String path = ppath.replaceAll("\\\\", "/");
      
      if (path.contains(CACHE_PATH)) return; // We ain't gonna cache cache files wtf.
      
      // Bug fix to avoid outofmemoryexception, find the size now, not later.
      // Because we're still loading up the sound file in the background, best we can do here is
      // make an estimate on how large the file will be.
      // Here's the rules:
      // wav: filesize*2
      // mp3: filesize*10
      // ogg: filesize*10
      // anything else: filesize*2
      int size = 0;
      int filesize = (int)(new File(path)).length();
      if (file.getExt(path).equals("wav")) size = filesize*2;
      else if (file.getExt(path).equals("mp3")) size = filesize*10;
      else if (file.getExt(path).equals("ogg")) size = filesize*10;
      else size = filesize*2;
      
      int maxCacheSize = MAX_CACHE_SIZE;
      if (lowMemory) {
        maxCacheSize = MAX_CACHE_SIZE_LOW_MEM;
      }
      
      // FLAC is not supported by soundfile so don't bother caching that.
      if (file.getExt(path).equals("flac") || size > maxCacheSize) {
        //console.log("flac file or file is way too big.");
        return;
      }
      
      // File too small, not worth caching as this will just waste storage space (it's better just to load it directly).
      if (size < MIN_CACHE_SIZE) {
        //console.log("File too small to be worth caching.");
        return;
      }
      
        boolean cacheLoaded = true;
        String cacheInfoPath = CACHE_PATH+MUSIC_CACHE_FILE;
        JSONObject json = null;
        if (file.exists(cacheInfoPath)) {
          try {
            json = app.loadJSONObject(cacheInfoPath);
            if (json == null) {
              //console.log("updateMusicCache: couldn't load music cache.");
              cacheLoaded = false;
            }
          }
          catch (RuntimeException e) {
            //console.log("updateMusicCache: something's wrong with the music cache json.");
            cacheLoaded = false;
          }
        }
        else cacheLoaded = false;
        
        if (!cacheLoaded || json == null) {
          json = new JSONObject();
        }
        
        
        
        // Save these for later, we'll need the below down there in the code.
        String tempCacheFilePath = null;
        
        boolean createNewEntry = json.isNull(toPossibleRelative(path));
        if (createNewEntry) {
          //console.log("no cache, creating new");
        }
        else {
          tempCacheFilePath = fromPossibleRelative(json.getJSONObject(toPossibleRelative(path)).getString("cache_path"));
          //console.log("existing cache path");
        }
        
        
        // Save the actual wav file as cache
        String cachedPath = "";
        final String ext = file.getExt(path);
        // Sometimes the entry can exist but not the cached file.
        // We can easily just re-create the entry if it's missing.
        
        // If it's a wav, there's no need to do converstions into the cache.
        // Just tell it that the original path is the cached path.
        if (ext.equals("wav")) {
          cachedPath = path;
          //obj.setString("cachePath", cachedFileName.replaceAll("\\\\", "/"));
        }
        // Otherwise, begin to load the compressed file, decompress it, and save as wav in cache folder.
        else {
          // 2 cases here:
          // - We're playing music that has never been cached before
          // - The music has a cache entry but the cache WAV file doesn't exist.
          String temp = "";
          // Entry already exists but wav file doesn't
          if (!createNewEntry) {
            if (tempCacheFilePath != null && tempCacheFilePath.length() > 0) {
              temp = tempCacheFilePath;
              // Only bother creating the new file if it doesn't exist
              if (file.exists(tempCacheFilePath)) return;  // Nothing more to do here.
            }
            else console.bugWarn("updateMusicCache: tempCacheFilePath read a non-existing json string or is null");
          }
          // Entry doesn't exist i.e. no cache whatsoever.
          else {
            temp = generateCachePath("wav");
          }
          
          // From here we go ahead and generate the cache wav file.
          
          final String cachedFilePathFinal = temp;
          cachedPath = cachedFilePathFinal;
          
          if (!DISABLE_GSTREAMER) {
            // Kickstart the thread that will cache the file.
            Thread t1 = new Thread(new Runnable() {
              public void run() {
                // As soon as we're not caching anymore, take the opportunity and set to true.
                // Otherwise, wait wait wait
                while (!caching.compareAndSet(false, true)) {
                  try {
                    Thread.sleep(10);
                  }
                  catch (InterruptedException e) {
                    // we don't care.
                  }
                }
                
                try {
                  PApplet.println("Caching "+path+"...");
                  SoundFile s = new SoundFile(app, path);
                  int samplerate = s.sampleRate();
                  // Bug fix: mp3 sampleRate() doesn't seem to be very accurate
                  // for mp3 files
                  // TODO: Read mp3/ogg header data and determine samplerate there.
                  if (ext.equals("mp3")) {
                    samplerate = 48000;
                  }
                  
                  saveAsWav(s, samplerate, cachedFilePathFinal);
                  s.removeFromCache();
                  System.gc();
                  PApplet.println("DONE SOUND CACHE "+cachedFilePathFinal);
                  
                }
                catch (RuntimeException e) {
                  console.warn("Sound caching error: "+e.getMessage());
                }
                // Release so that another thread can begin its caching process.
                caching.set(false);
              }
            }
            );
            //t1.setDaemon(true);
            t1.start();
          }
        }
        
        // Save to the cache info
        // If we get to this point, entry doesn't exist in the cache file/cache file doesn't exist.
        JSONObject obj = new JSONObject();
        obj.setString("cache_path", toPossibleRelative(cachedPath));
        json.setJSONObject(toPossibleRelative(path), obj);
        try {
          app.saveJSONObject(json, cacheInfoPath);
        }
        catch (RuntimeException e) {
          console.warn(e.getMessage());
          console.warn("Failed to write music cache file:");
        }
    }
    
    
    public String tryGetMusicCache(String originalPath) {
      String cacheFilePath = CACHE_PATH+MUSIC_CACHE_FILE;
      
      // TODO: Loading it each time is very inefficient, we should probably cache the cache.
      File f = new File(cacheFilePath);
      if (f.exists()) {
        JSONObject json;
        try {
          json = app.loadJSONObject(cacheFilePath);
          if (json == null) {
            //console.log("cache miss, info file null");
            return null;
          }
        }
        catch (RuntimeException e) {
          //console.log("cache miss, info file exception");
          return null;
        }
        
        
        // Check cache entry exists
        String originalPathRel = toPossibleRelative(originalPath);
        JSONObject entry = json.getJSONObject(originalPathRel);
        if (entry != null) {
          // Cache hit. Not done yet tho.
          String cachePath = fromPossibleRelative(entry.getString("cache_path"));
          
          
          // Check music file actually exists.
          if (file.exists(cachePath)) {
            //console.log("cache hit");
            return cachePath;
          }
          else {
            //console.log("cache miss, cache file doesnt exist");
            
          }
        }
        else {
          //console.log("cache miss, entry doesnt exist");
        }
      }
      else {
        //console.log("cache miss, info file doenst exist");
      }
      
      return originalPath;
    }
    
    
    // Ugly code but secure
    public boolean loadingMusic() {
      // In android, we use a completely different system that doesn't need loading.
      if (isAndroid()) return false;
      boolean ready = musicReady.get();
      //if (gstreamerLoading && ready) gstreamerLoading = false;
      
      // Not android and gstreamer is disabled.
      if (DISABLE_GSTREAMER) return true;
      
      return !ready;
    }
    
    public SoundFile getSound(String name) {
      SoundFile sound = sounds.get(name);
      if (sound == null) {
        console.bugWarn("getsound: Sound "+name+" doesn't exist!");
        return null;
      } else return sound;
    }
  
    public void playSound(String name) {
      playSound(name, 1.0);
    }
    
    public void playSoundOnce(String name) {
      SoundFile s = getSound(name);
      if (s != null) {
        if (!s.isPlaying()) s.play();
      }
    }
    
    public void pauseSound(String name) {
      SoundFile s = getSound(name);
      if (s != null) {
        if (s.isPlaying()) s.pause();
      }
    }
    
    public void playSound(String name, float pitch) {
      SoundFile s = getSound(name);
      if (s != null) {
        if (s.isPlaying()) s.stop();
        s.play(pitch);
      }
    }
  
    public void loopSound(String name) {
      // Don't want loads of annoying loops
      SoundFile s = getSound(name);
      if (s != null) {
        if (!s.isPlaying())
          s.loop();
      }
    }
    
    public void stopSound(String name) {
      SoundFile s = getSound(name);
      if (s != null) {
          s.stop();
      }
    }
    
  
    public void setSoundVolume(String name, float vol) {
      SoundFile s = getSound(name);
      if (s != null) s.amp(vol);
    }
    
    private float masterVolume = 1.;
    private float musicVolume = 1.;
     
    
    public void setMasterVolume(float vol) {
      masterVolume = vol;
      //Sound.volume(vol);
    }
    
    public void setMusicVolume(float vol) {
      musicVolume = vol;
    }
  
  
    // Plays background music directly from the hard drive without loading it into memory, and
    // loops the music when the end of the audio has been reached.
    // This is useful for playing background music, but shouldn't be used for sound effects
    // or randomly accessed sounds.
    // This technically uses an unintended quirk of the Movie library, as passing an audio file
    // instead of a video file still plays the file streamed from the disk.
  
    public void streamMusic(final String path) {
      // If still loading
      if (loadingMusic()) {
        reloadMusic = true;
        reloadMusicPath = path;
      }
      
      // Crash avoidance
      //if (crashAvoidance)
      
      // We don't need to boot up gstreamer in android cus gstreamer doesn't exist in android.
      if (startupGStreamer && !isAndroid()) {
        //console.log("startup gstreamer");
        // Start music and don't play anything (just want it to get past the inital delay of starting gstreamer.
        musicReady.set(false);
        Thread t1 = new Thread(new Runnable() {
          public void run() {
            if (!DISABLE_GSTREAMER) {
              Movie loadGstreamer = new Movie(app, path);
              loadGstreamer.play();
              loadGstreamer.stop();
            }
    
            musicReady.set(true);
          }
        }
        );
        //t1.setDaemon(true);
        t1.start();
        startupGStreamer = false;
      }
      // Play as normal
      else {
        //console.log("streammusic "+path);
        //if ((loadingMusic() && !CACHE_MUSIC) == false) {
          Thread t1 = new Thread(new Runnable() {
          public void run() {
            streamerMusic = loadNewMusic(path);
    
            if (streamerMusic != null)
              streamerMusic.play();
            }
          }
          );
          //t1.setDaemon(true);
          t1.start();
        //}
      }
    }
  
    private Music loadNewMusic(String path) {
      
      // Doesn't seem to throw an exception or report an error is the file isn't
      // found so let's do it ourselves.
      if (!file.exists(path)) {
        console.bugWarn("loadNewMusic: "+path+" doesn't exist!");
        return null;
      }
      
      Music newMusic = null;
  
      console.info("loadNewMusic: Starting "+path);
      try {
        // Automatically loads cached music if gstreamer has not started yet.
        newMusic = new Music(path);
      }
      catch (Exception e) {
        console.warn("Error while reading music: "+e.getClass().toString()+", "+e.getMessage());
      }
  
      if (newMusic == null) console.bugWarn("Couldn't read music; null returned");
      
      updateMusicCache(path);
  
      //  We're creating a new sound streamer, not a movie lmao.
      return newMusic;
    }
  
    public void stopMusic() {
      if (streamerMusic != null) {
        // We use pause instead of stop because stop can cause crashes
        streamerMusic.pause();
          
        streamerMusic = null;
      }
      if (streamerMusicFadeTo != null) {
        streamerMusicFadeTo.stop();
        streamerMusicFadeTo = null;
      }
    }
    
    public void pauseMusic() {
      if (streamerMusic != null) {
        streamerMusic.pause();
      }
    }
    
    public void continueMusic() {
      if (streamerMusic != null) {
        streamerMusic.play();
      }
    }
  
    public void streamMusicWithFade(String path) {
      if (musicReady.get() == false) {
        reloadMusic = true;
        reloadMusicPath = path;
        //updateMusicCache(path);
      }
  
      // Temporary fix
      if (musicFadeOut < 1.) {
        if (streamerMusicFadeTo != null) {
          streamerMusicFadeTo.stop();
        }
      }
  
      // If no music is currently playing, don't bother fading out the music, just
      // start the music as normal.
      if (streamerMusic == null || isLoading()) {
        streamMusic(path);
        return;
      }
      
      streamerMusicFadeTo = loadNewMusic(path);
      if (streamerMusicFadeTo != null) {
        streamerMusicFadeTo.volume(0.);
        streamerMusicFadeTo.setReady();
      }
      musicFadeOut = 0.99;
    }
    
    public void fadeAndStopMusic() {
      //if (musicFadeOut < 1.) {
      //  if (streamerMusicFadeTo != null) {
      //    streamerMusicFadeTo.stop();
      //    streamerMusicFadeTo = null;
      //  }
      //  return;
      //}
      musicFadeOut = 0.99;
    }
    
    
    public void syncMusic(float expectedTime) {
      if (streamerMusic != null) {
        streamerMusic.sync(expectedTime);
      }
    }
    
    public float getCurrentMusicDuration() {
      if (streamerMusic != null) {
        return streamerMusic.duration();
      }
      return 0.0;
    }
    
    
    public int beat = 0;
    public int step = 0;
    
    private float bpm = 120f;
    private float musicTime = 0f;
    private boolean customTime = false;
    
    public void setCustomMusicTime(float t) {
      customTime = true;
      musicTime = t;
    }
    
    public void setMusicTimeAuto() {
      customTime = true;
    }
    
    public float getTime() {
      if (customTime) {
        return musicTime;
      }
      else {
        if (streamerMusic != null) {
          // TODO: getting time is slow for some reason.
          return streamerMusic.time();
        }
        return 0f;
      }
    }
    
    public void setBPM(float bpm) {
      this.bpm = bpm;
    }
    
    public float beatToTime(int beat) {
      float beatspersecond = 60f/bpm;
      return beatspersecond*((float)beat);
    }
    
    public float beatToTime(int beat, int step) {
      float beatspersecond = 60f/bpm;
      float stepsspersecond = beatspersecond/4f;
      return beatspersecond*((float)beat)+stepsspersecond*((float)step);
    }
    
    @SuppressWarnings("unused")
    public boolean beatBetween(int start, int end) {
      return false;
    }
    
    
    public float beatSaw(int beatoffset, int stepoffset, int everyxbeat) {
      if (everyxbeat == 0) everyxbeat = 1;
      float t = (getTime())+beatToTime(beatoffset, stepoffset);
    
      float beatspersecond = 60f/bpm;
      float beatfloat = (t/beatspersecond);
      int beat = (int)beatfloat;
    
      if (beat % everyxbeat == 0) return 1f-(beatfloat-(float)beat);
      else return 0f;
    }
    
    public float framesPerBeat() {
      float beatspersecond = 60f/bpm;
      float framesPerBeat = (display.BASE_FRAMERATE*beatspersecond);
      return framesPerBeat;
    }
    
    public float framesPerQuarter() {
      return framesPerBeat()/4f;
    }
    
    public float beatSaw(int beatoffset, int everyxbeat) {
      return beatSaw(beatoffset, 0, everyxbeat);
    }
    
    public float beatSaw(int beatoffset) {
      return beatSaw(beatoffset, 0, 1);
    }
    
    public float beatSawOffbeat(int beatoffset, int everyxbeat) {
      return beatSaw(beatoffset, 2, everyxbeat);
    }
    
    public float beatSaw() {
      return beatSaw(0, 0, 1);
    }
    
    public float stepSaw(int offset) {
      float t = (getTime())+beatToTime(0, offset);
    
      float beatspersecond = 60f/bpm;
      float stepfloat = (t/(beatspersecond/4f));
    
      return 1f-(stepfloat-(float)((int)stepfloat));
    }
    
    
    private void processBeat() {
      float t = 0f;
      if (customTime) {
        t = musicTime;
      }
      else {
        if (streamerMusic != null) {
          // TODO: getting time is slow for some reason.
          t = streamerMusic.time();
        }
        musicTime = t;
      }
      if (bpm == 0f) return;
      
      float beatspersecond = 60f/bpm;

      float beatfloat = (t/beatspersecond);
      float stepfloat = (t/(beatspersecond/4f));
    
      beat = (int)beatfloat;
      step = ((int)stepfloat)%4;
      
      if (!customTime) {
        
      }
    }
    
    public boolean musicIsPlaying() {
      if (streamerMusic != null) {
        // TODO: getting time is slow for some reason.
        return streamerMusic.isPlaying();
      }
      return false;
    }
  
    public void processSound() {
      processBeat();
      
      // Once gstreamer has loaded up, begin playing the music we actually want to play.
      if (reloadMusic && !loadingMusic()) {
        if (CACHE_MUSIC && !isAndroid()) {
          if (streamerMusic != null) streamerMusic.switchMode();
          if (streamerMusicFadeTo != null) streamerMusicFadeTo.switchMode();
          
        }
        else {
          stopMusic();
          streamMusic(reloadMusicPath);
        }
        
        reloadMusic = false;
      }
      

      // Fade the music.
      boolean useNewLibraryVersion = false; // javaPlatform >= 17;
      
      if (musicFadeOut < 1.) {
        if (musicFadeOut > 0.005 && !useNewLibraryVersion) {
          // Fade the old music out
          float vol = musicFadeOut *= PApplet.pow(MUSIC_FADE_SPEED, display.getDelta());
          if (streamerMusic != null) {
            streamerMusic.playbinSetVolume(vol);
          }


          // Fade the new music in.
          if (streamerMusicFadeTo != null) {
            streamerMusicFadeTo.play();
            streamerMusicFadeTo.volume((1.-vol)*masterVolume*musicVolume);
          } 
          
          
          //else 
          //  console.bugWarnOnce("streamMusicFadeTo shouldn't be null here.");
        } else {
          if (streamerMusic != null) {
            streamerMusic.stop();
            streamerMusic = null;
          }
          if (streamerMusicFadeTo != null) streamerMusic = streamerMusicFadeTo;
          if (useNewLibraryVersion) streamerMusic.play();
          musicFadeOut = 1.;
        }
      }



      if (streamerMusic != null) {
        // Don't wanna change the volume on cached music
        if (!loadingMusic())
          streamerMusic.volume(masterVolume*musicVolume);
          
        if (streamerMusic.available() == true) {
          streamerMusic.read();
        }
        float error = 0.1;

        // PERFORMANCE ISSUE: streamMusic.time()
        
        // If the music has finished playing, jump to beginning to play again.
        if (isAndroid()) {
          
        }
        else {
          if (streamerMusic.time() >= streamerMusic.duration()-error) {
            streamerMusic.jump(0.);
            if (!streamerMusic.isPlaying()) {
              streamerMusic.play();
            }
          }
        }
      }
    }
    
    // End of the module
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class StatsModule {
    JSONObject json;
    HashMap<String, Float> befores = new HashMap<String, Float>();
    
    public StatsModule() {
      try {
        if (isAndroid()) {
          String path = file.directorify(getAndroidWriteableDir())+STATS_FILE();
          if (file.exists(path))
            json = loadJSONObject(path);
          else json = new JSONObject();
        }
        else {
          String path = APPPATH+STATS_FILE();
          if (file.exists(path))
            json = loadJSONObject(path);
          else json = new JSONObject();
        }
      }
      catch (Exception e) {
        json = new JSONObject();
      }
    }
    
    public void set(String name, int value) {
      json.setInt(name, value);
    }
    
    public void set(String name, float value) {
      json.setFloat(name, value);
    }
    
    public void setIfHigher(String name, int value) {
      if (value > stats.getInt(name)) {
        set(name, value);
      }
    }
    
    public void setIfIHigher(String name, float value) {
      if (value > stats.getFloat(name)) {
        set(name, value);
      }
    }
    
    public int getInt(String name) {
      return json.getInt(name, 0);
    }
    
    public float getFloat(String name) {
      return json.getFloat(name, 0.0);
    }
    
    public void increase(String name, int value) {
      json.setInt(name, json.getInt(name, 0)+value);
    }
    
    public void increase(String name, float value) {
      json.setFloat(name, json.getFloat(name, 0.0)+value);
    }
    
    public void recordTime(String name) {
      float before = 0;
      if (befores.containsKey(name)) {
        before = befores.get(name);
      }
      float timesince = (float(millis())-before)/1000.;
      // To only make the timer run when the method is called.
      if (timesince > 0.5) timesince = 0.;
      
      increase(name, timesince);
      befores.put(name, float(millis()));
    }
    
    public void save(boolean onlyIfExists) {
      String path = "";
      if (isAndroid()) {
        path = file.directorify(getAndroidWriteableDir())+STATS_FILE();
      }
      else {
        path = APPPATH+STATS_FILE();
      }
      if (onlyIfExists && !file.exists(path)) return;
      
      saveJSONObject(json, path);
    }
    
    public void save() {
      save(true);
    }
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class FilemanagerModule {
    public FilemanagerModule() {
      
      DEFAULT_DIR  = settings.getString("home_directory", System.getProperty("user.home").replace('\\', '/'));
      {
        File f = new File(DEFAULT_DIR);
        if (!f.exists()) {
          console.warn("homeDirectory "+DEFAULT_DIR+" doesn't exist! You should check your config file.");
          
          if (isAndroid()) {
            DEFAULT_DIR = "/storage/emulated/0/";
          }
          else {
            DEFAULT_DIR = System.getProperty("user.home").replace('\\', '/');
          }
        }
        currentDir  = DEFAULT_DIR;
      }
      
      if (DEFAULT_DIR.length() > 0)
        if (DEFAULT_DIR.charAt(DEFAULT_DIR.length()-1) == '/')  DEFAULT_DIR = DEFAULT_DIR.substring(0, DEFAULT_DIR.length()-1);
        
      // Cus we can't get any information on anything about our files, we'll need to load a list which contains everything
      // so that exists() works.
      if (isAndroid()) {
        String[] strings = loadStrings(EVERYTHING_TXT_PATH);
        for (String path : strings) {
          everything.add(path.trim());
        }
      }
      
      // Recycle bin
      if (!exists(APPPATH+RECYCLE_BIN_INFO)) {
        recycleJson = new JSONArray();
      }
      else {
        try {
          recycleJson = loadJSONArray(APPPATH+RECYCLE_BIN_INFO);
        }
        catch (RuntimeException e) {
          console.warn("Something went wrong with loading recycling bin info: "+e.getMessage());
          recycleJson = new JSONArray();
        }
      }
    }
    
    public final String RECYCLE_BIN_PATH = "recyclebin/";
    public final String RECYCLE_BIN_INFO = RECYCLE_BIN_PATH+"recycle.json";
    private JSONArray recycleJson = null;
    
    public boolean loading = false;
    public int MAX_DISPLAY_FILES = 2048; 
    public int numTimewayEntries = 0;
    public DisplayableFile[] currentFiles;
    public String fileSelected = null;
    public boolean fileSelectSuccess = false;
    public boolean selectingFile = false;
    public Object objectToSave;
    private HashSet<String> everything = new HashSet<String>();
    
    
    void selectOutput(String promptMessage) {
      if (true) {
        fileSelectSuccess = false;
        selectOutputSketch(promptMessage, "outputFileSelected");
        selectingFile = true;
      }
      // TODO: Pixelrealm file chooser.
    }
    
    void selectOutput(String promptMessage, PImage imageToSave) {
      this.selectOutput(promptMessage);
      objectToSave = imageToSave;
    }
    
    void outputFileSelected(File selection) {
      selectingFile = false;
      if (selection == null) {
        fileSelected = null;
        fileSelectSuccess = false;
      }
      else {
        fileSelected = selection.getAbsolutePath();
        fileSelectSuccess = true;
      }
      
      if (objectToSave != null && fileSelectSuccess) {
        if (objectToSave instanceof PImage) {
          Thread t = new Thread(new Runnable() {
              public void run() {
                  PImage imageToSave = (PImage)objectToSave;
                  imageToSave.save(fileSelected);
                  objectToSave = null;
              }
          });
          t.start();
        }
        else {
          console.bugWarn("outputFileSelected: I don't know how to save "+objectToSave.getClass().toString()+"!");
        }
      }
    }
    
    public boolean mv(String oldPlace, String newPlace) {
      // We know we're merely accessing a fake filesystem now in android.
      if (isAndroid() && (oldPlace.charAt(0) != '/' || newPlace.charAt(0) != '/')) {
        console.bugWarn("You can't move files to/from the assets folder! It's read-only!");
        return false;
      }
      
      try {
        File of = new File(oldPlace);
        File nf = new File(newPlace);
        if (nf.exists()) {
           return false;
        }
        if (of.exists()) {
          of.renameTo(nf);
          // If the file is cached, move the cached file too to avoid stalling and creating duplicate cache
          moveCache(oldPlace, newPlace);
        } else if (!of.exists()) {
          return false;
        }
      }
      catch (SecurityException e) {
        console.warn(e.getMessage());
        return false;
      }
      return true;
    }
    
    
    public void mkdir(String path) {
      File f = new File(path);
      if (!f.exists() || !f.isDirectory()) {
        if (!f.mkdir()) {
          console.warn("Couldn't remake directory "+getFilename(path));
          return;
        }
      }
    }
    
    
    public boolean recycle(String oldLocation) {
      String newName = nf(random(0, 99999999), 8, 0);
      while (exists(APPPATH+RECYCLE_BIN_PATH+newName)) {
        newName = nf(random(0, 99999999), 8, 0);
      }
      
      mkdir(APPPATH+RECYCLE_BIN_PATH);
      
      if (!mv(oldLocation, APPPATH+RECYCLE_BIN_PATH+newName)) {
        console.warn("Could not recycle "+getFilename(oldLocation)+", maybe file permissions denied?");
        return false;
      }
      
      JSONObject entry = new JSONObject();
      entry.setString("name", newName);
      entry.setString("old_location", oldLocation);
      recycleJson.setJSONObject(recycleJson.size(), entry);
      app.saveJSONArray(recycleJson, APPPATH+RECYCLE_BIN_INFO);
      return true;
    }
    
    public boolean copy(String src, String dest) {
      //if (!exists(src)) {
      //  console.bugWarn("copy: "+src+" doesn't exist!");
      //  return false;
      //}
      
      // In android mode, we need to tell when we're copying from the source folder.
      
      if (isAndroid()) {
        // Can't write to assets, dest should never be in assets.
        if (dest.charAt(0) != '/') {
          console.bugWarn("copy: you can't copy to destination! Assets is read-only!");
        }
        
        // Case: copying from assets directory. We use android mode's buildin function to make
        // a inputstreamer.
        InputStream fis = null;
        OutputStream fos = null;
        try {
            if (src.charAt(0) != '/') {
                fis = createInput(src);
                fos = new FileOutputStream(dest);
            }
            else {
                fis = new FileInputStream(src);
                fos = new FileOutputStream(dest);
            }
        

            byte[] buffer = new byte[1024];
            int length;
            while ((length = fis.read(buffer)) > 0) {
                fos.write(buffer, 0, length);
            }
            System.out.println("File copied successfully.");
            
            fis.close();
            fos.close();

        } catch (IOException e) {
            console.warn("Couldn't copy files: "+e.getMessage());
            return false;
        }
        
      }
      else {
        try {
          Path copied = Paths.get(dest);
          Path originalPath = (new File(src)).toPath();
          Files.copy(originalPath, copied, StandardCopyOption.REPLACE_EXISTING);
        }
        catch (IOException e) {
          console.warn(e.getMessage());
          return false;
        }
      }
      return true;
    }
  
    public void backupMove(String path) {
      if (!exists(path)) return;
      String name = getFilename(path);
      String newPath = CACHE_PATH+"_"+name+"_"+getLastModified(path).replaceAll("[\\.:]", "-")+".txt";
      if (!mv(path, newPath)) {
        console.log(newPath);
        // If a file doesn't back up, it's not the end of the world.
        console.warn("Couldn't back up "+path+".");
      }
    }
  
    public void backupAndSaveJSON(JSONObject json, String path) {
      File f = new File(path);
      if (f.exists())
        backupMove(path);
          
      app.saveJSONObject(json, path);
    }
    
    
    public String getLastModified(String path) {
      // For now, nothing we can do
      if (isAndroid()) {
        return "000000";
      }
      
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
        return "";
      }
  
      return attr.lastModifiedTime().toString();
    }
    
    
  
    // TODO: Make it follow the UNIX file system with compatibility with windows.
    public String currentDir;
    public class DisplayableFile {
      public String path;
      public String filename;
      public String fileext;
      public String icon = null;
      // TODO: add other properties.
      
      
      public boolean exists() {
        return (new File(path)).exists();
      }
      
      public boolean isDirectory() {
        if (!exists()) {
          console.bugWarn("isDirectory: "+path+" doesn't exist!");
          return false;
        }
        return (new File(path)).isDirectory();
      }
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
      try {
        String str = path.substring(0, path.lastIndexOf('/', path.length()-2));
        return str;
      }
      catch (StringIndexOutOfBoundsException e) {
        return "";
      }
    }
    
    // Because I can't be bothered to solve bugs.
    // If there's no dir, returns the full path instead of nothing.
    public String getDirLegacy(String path) {
      try {
        String str = path.substring(0, path.lastIndexOf('/', path.length()-2));
        return str;
      }
      catch (StringIndexOutOfBoundsException e) {
        return path;
      }
    }
    
    public boolean isDirectory(String path) {
      return (new File(path)).isDirectory();
    }
    
    // TODO: optimise to be safe and for use with MacOS and Linux.
    public String getPrevDir(String dir) {
      int i = dir.lastIndexOf("/", dir.length()-2);
      if (i == -1) {
        console.bugWarn("getPrevDir: At root dir, make sure to use atRootDir in your code!");
        return dir;
      }
      return dir.substring(0, i);
    }
    
    //C:/mydata/notebook/
    //C:/mydata/notebook/hazy_era/recovery/006
    
    //hazy_era/recovery/006
    
    //C:/mydata/notebook/hazy_era/a/directory/of/thing
    //C:/mydata/notebook/hazy_era/homen/002
    
    //C:/mydata/notebook/hazy_era/a/directory/of/   ../
    //C:/mydata/notebook/hazy_era/a/directory/      ../../
    //C:/mydata/notebook/hazy_era/a/                ../../../
    //C:/mydata/notebook/hazy_era/                  ../../../../
    //C:/mydata/notebook/hazy_era/homen/            ../../../../homen/
    //C:/mydata/notebook/hazy_era/homen/002         ../../../../homen/002/
    public String getRelativeDir(String from, String to) {
      if (from == null || to == null) return "";
      
      try {
        // Paranoid code.
        from = directorify(from.replaceAll("\\\\", "/"));
        to = directorify(to.replaceAll("\\\\", "/"));
        
        // We gonna construct a relative path starting with no string
        String relative = "";
        // Used for second step
        int commonPathLength = 0;
        int count = 0;
        
        // STEP 1: Backtrack paths.
        // Condition to ensure we don't loop forever in case something goes terribly wrong
        while (count < 999) {
          // Before we (possibly) break, set commonPathLength for step 2.
          // Remember we're processing from variable "from"
          commonPathLength = from.length();
          
          // Can't go any further back if at root dir
          if (atRootDir(from)) {
            break;
          }
          // This condition checks for paths in common between from and to.
          // For example, C:/mydata/notebook/hazy_era/homen/006 and C:/mydata/notebook/cool_summer/090623
          // both have C:/mydata/notebook/ in their paths.
          if (from.substring(0, PApplet.min(from.length(), to.length())).equals( to.substring(0, PApplet.min(from.length(), to.length())) )) {
            break;
          }
          
          // If common path not found yet, take a dir away and iterate again.
          from = directorify(getPrevDir(from));
          relative += "../"; // Ofc we're going back one dir
          count++;  // Looplock prevention
        }
        if (count < 999 == false) {
          console.bugWarn("getRelativeDir: Loop lock prevention for "+from+", "+to);
          return "";
        }
        
        // STEP 2: 
        // Slap on the directories leading to "to"
        // Take out the common path in "to" and append to relative.
        relative += to.substring(commonPathLength);
        return relative;
      }
      catch (Exception e) {
        console.bugWarn("getRelativeDir: "+e.getMessage());
        return "";
      }
      
    }
    
    // Converts a path (created from getRelativeDir) back to absolute path given a starting path
    public String relativeToAbsolute(String start, String relative) {
      try {
        String path = start;
        // Turn into list
        String[] elements = relative.split("/");
        for (String s : elements) {
          // Consume elements.
          // .. means go back
          // anything else means append to path.
          //console.log(s);
          if (s.equals("..")) {
            path = directorify(getPrevDir(path));
          }
          else {
            path += s;
            path = directorify(path);
          }
        }
        return path;
      }
      catch (Exception e) {
        console.bugWarn("relativeToAbsolute: "+e.getMessage());
        return DEFAULT_DIR;
      }
    }
    
    public String directorify(String dir) {
      if (dir.charAt(dir.length()-1) != '/')  dir += "/";
      return dir;
    }
    
    public String getMyDir() {
      String dir = getDir(APPPATH);
      return directorify(dir);
    }
    
    public String anyFileWithExt(String pathWithoutExt, String[] exts) {
      for (String ext : exts) {
        // Because we like to keep our code secure, let's do a bit of error checking (what opengl suffers from lol)
        if (ext.charAt(0) != '.') ext = "."+ext;
        
        File f = new File(pathWithoutExt+ext);
        if (f.exists()) {
          return pathWithoutExt+ext;
        }
      }
      return null;
    }
    
    // Yes.
    public boolean exists(String path) {
      if (path == null) return false;
      boolean exists = (new File(path)).exists();
      return isAndroid() ? exists || everything.contains(path) : exists;
    }
    
    // TODO: For now, only ever used in editor, but eventually will need to be changed to work properly in
    // android mode.
    public int fileSize(String path) {
      File f = new File(path);
      return isAndroid() ? 10000 : (int)f.length();
    }
    
    public boolean isImage(String path) {
      String ext = getExt(path);
      if (ext.equals("png")
        || ext.equals("jpg")
        || ext.equals("jpeg")
        || ext.equals("bmp")
        || ext.equals("gif")
        || ext.equals("ico")
        || ext.equals("webm")
        || ext.equals("tiff")
        || ext.equals("tif"))
        return true;
      else
        return false;
    }
    
    public String anyImageFile(String pathWithoutExt) {
      String[] SUPPORTED_IMG_TYPES = { ".png", ".bmp", ".jpg", ".jpeg", ".gif" };
      return anyFileWithExt(pathWithoutExt, SUPPORTED_IMG_TYPES);
    }
    
    public String anyMusicFile(String pathWithoutExt) {
      String[] SUPPORTED_MUSIC_TYPES = { ".wav", ".mp3", ".flac", ".ogg" };
      return anyFileWithExt(pathWithoutExt, SUPPORTED_MUSIC_TYPES);
    }
  
    public String getFilename(String path) {
      int index = path.lastIndexOf('/', path.length()-2);
      if (index != -1) {
        if (path.charAt(path.length()-1) == '/') {
          path = path.substring(0, path.length()-1);
        }
        return path.substring(index+1);
      } else
        return path;
    }
    
    // Returns filename without the extension.
    public String getIsolatedFilename(String path) {
      int index = path.lastIndexOf('/', path.length()-2);
      String filenameWithExt = "";
      if (index != -1) {
        if (path.charAt(path.length()-1) == '/') {
          path = path.substring(0, path.length()-1);
        }
        filenameWithExt = path.substring(index+1);
      } else {
        filenameWithExt = path;
      }
      
      // Now strip off the ext.
      index = filenameWithExt.indexOf('.');
      if (index == -1) {
        return filenameWithExt;
      }
      String result = filenameWithExt.substring(0, index);
      //console.log(result);
      return result;
    }
  
    public boolean atRootDir(String dirName) {
      // This will heavily depend on what os we're on.
      if (isWindows()) {
  
        // for windows, let's do a dirty way of checking for 3 characters
        // such as C:/
        return (dirName.length() <= 3);
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
      case FILE_TYPE_PDF:
        return "doc_128";
      case FILE_TYPE_VIDEO:
        return "media_128";
      case FILE_TYPE_MUSIC:
        return "media_128";
      case FILE_TYPE_MODEL:
        return "unknown_128";
      case FILE_TYPE_DOC:
        return "doc_128";
      case FILE_TYPE_SKETCHIO:
        return "sketchio_128";
      case FILE_TYPE_TIMEWAYENTRY:
        return "timeway_entry_64";
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
        || ext.equals("txt")) return FileType.FILE_TYPE_DOC;
        
        
      if (ext.equals("pdf")) return FileType.FILE_TYPE_PDF;
        
      if (ext.equals(ENTRY_EXTENSION))
        return FileType.FILE_TYPE_TIMEWAYENTRY;
        
      if (ext.equals("sketchio"))
        return FileType.FILE_TYPE_SKETCHIO;
  
      if (ext.equals("mp3")
        || ext.equals("wav")
        || ext.equals("flac")
        || ext.equals("ogg"))  return FileType.FILE_TYPE_MUSIC;
  
      if (ext.equals("mp4")
        || ext.equals("m4v")
        || ext.equals("mov")) return FileType.FILE_TYPE_VIDEO;
        
      if (ext.equals("obj")) return FileType.FILE_TYPE_MODEL;
      
      if (ext.equals(SHORTCUT_EXTENSION)) return FileType.FILE_TYPE_SHORTCUT;
  
      return FileType.FILE_TYPE_UNKNOWN;
    }
  
    // A function of conditions for a file to be hidden,
    // for now files are only hidden if they have '.' at the front.
    public boolean fileHidden(String filename) {
      if (filename.length() > 0) {
        if      (filename.charAt(0) == '.') return true;
        else if (filename.equals("desktop.ini")) return true;
      }
      return false;
    }
    
    public String unhide(String original) {
      String name = getFilename(original);
      String dir  = getDir(original);
      
      if (dir.length() > 1) {
        dir = directorify(dir);
      }
      
      if (name.charAt(0) == '.') name = name.substring(1);
      return dir+name;
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
          currentFiles[0].path = getDir(dirName);
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
                currentFiles[index].path = f.getAbsolutePath();
                currentFiles[index].filename = f.getName();
                if (currentFiles[index].filename.length() > MAX_NAME_SIZE) currentFiles[index].filename = currentFiles[index].filename.substring(0, MAX_NAME_SIZE)+"...";
                currentFiles[index].fileext = getExt(f.getName());
  
                // Get icon
                if (f.isDirectory() && !file.getExt(currentFiles[index].filename).equals("sketchio")) currentFiles[index].icon = "folder_128";
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
      }
      );
      t.start();
    }
    
    public int countFiles(String path) {
        File folder = new File(path);
        if (!folder.exists() || !folder.isDirectory())
            return 1;
            
        int count = 0;
        File[] files = folder.listFiles();
        if (files != null) {
            for (File file : files) {
                if (file.isFile()) {
                    count++;
                } else if (file.isDirectory()) {
                    count += countFiles(file.getAbsolutePath()); // Recursively count files in subfolders
                }
            }
        }
        return count;
    }
  
    // NOTE: Only opens files, NOT directories (yet).
    public void open(String filePath) {
      if (!exists(filePath)) {
        console.warn(filePath+" doesn't exist!");
        return;
      }
      
      String ext = getExt(filePath);
      // Stuff to open with our own app (timeway)
      if (ext.equals(ENTRY_EXTENSION)) {
        twengineRequestEditor(filePath);
      }
      else if (ext.equals(SKETCHIO_EXTENSION)) {
        twengineRequestSketch(filePath);
      }
  
      // Anything else which is opened by a windows app or something.
      // TODO: use xdg-open in linux.
      // TODO: figure out how to open apps with MacOS.
      else {
        desktopOpen(filePath);
      }
    }
  
    public void open(DisplayableFile file) {
      String path = file.path;
      if (getExt(path).equals(SKETCHIO_EXTENSION)) {
        twengineRequestSketch(path);
      }
      else if (file.isDirectory()) {
        openDirInNewThread(path);
      } else {
        desktopOpen(path);
      }
    }
    
    public void openEntryReadonly(String path) {
      if (!exists(path)) {
        console.warn(path+" doesn't exist!");
        return;
      }
      
      String ext = getExt(path);
      // Stuff to open with our own app (timeway)
      if (ext.equals(ENTRY_EXTENSION)) {
        twengineRequestReadonlyEditor(path);
      }
      else {
        console.warn("openEntryReadonly: "+ext+" is not a timewayentry");
      }
    }
  
    public void refreshDir() {
      openDirInNewThread(currentDir);
    }
    
        // NOTE: VERY INACCURATE
    private int countApproxGifFrames(FileInputStream inputStream) throws IOException {
            int count = 0;
    
            // Read GIF header
            byte[] header = new byte[6];
            inputStream.read(header);
            
            int i_1 = 0;
    
            while (true) {
                // Read the block type
                int blockType = inputStream.read();
    
                if (blockType == 0x3B) {
                    // Reached the end of the GIF file
                    break;
                } else if (blockType == 0x21) {
                    // Extension block
                    int extensionType = inputStream.read();
                    if (extensionType == 0xF9) {
                        count++;
                    } else {
                        // Skip other extension blocks
                        while (true) {
                            int blockSize = inputStream.read();
                            if (blockSize == 0) {
                                break; // Block terminator found
                            }
                            inputStream.skip(blockSize); // Skip this block
                        }
                    }
                } else {
                    // Image Data block
                    int i_2 = 0;
                    while (true) {
                        int blockSize = inputStream.read();
                        if (blockSize == 0) {
                            break; // Block terminator found
                        }
                        inputStream.skip(blockSize); // Skip image data sub-blocks
                        
                        i_2++;
                        if (i_2 > 5000) {
                          break;
                        }
                    }
                    //count++;
                }
                
                
                i_1++;
                if (i_1 > 5900) {
                  break;
                }
            }
    
            return count*2;
        }
        
    
    private int[] extractGifDimensions(FileInputStream inputStream) throws IOException {
            int[] dimensions = new int[2];
    
            // Read GIF header and Logical Screen Descriptor
            byte[] headerAndLSD = new byte[13];
            inputStream.read(headerAndLSD);
    
            // Extract width and height from the Logical Screen Descriptor
            dimensions[0] = (headerAndLSD[6] & 0xFF) | ((headerAndLSD[7] & 0xFF) << 8);
            dimensions[1] = (headerAndLSD[8] & 0xFF) | ((headerAndLSD[9] & 0xFF) << 8);
    
            return dimensions;
        }
    
    // WARNING: may provide VERY inaccurate results. This is largely an approximation.
    // It should mainly be used to check if it's possible to fit it in memory, because it will
    // most likely over-estimate.
    // Please note that it may also take a while to get the size depending on the file size.
    // Therefore, you should run this in a seperate thread.
    public int getGifUncompressedSize(String filePath) {
      FileInputStream inputStream;
      try {
          inputStream = new FileInputStream(filePath);
          int numFrames = countApproxGifFrames(inputStream);
          
          inputStream.close();
          inputStream = new FileInputStream(filePath);
          int[] widthheight = extractGifDimensions(inputStream);
          int wi = widthheight[0];
          int hi = widthheight[1];
          return wi*hi*4*numFrames;
      }
      catch (IOException e) {
          return Integer.MAX_VALUE;
      }
      catch (RuntimeException e) {
        return Integer.MAX_VALUE;
      }
    }
    
    public int[] getPNGImageDimensions(String filePath) throws IOException {
        File file = new File(filePath);
        byte[] data = new byte[24]; // PNG header size is 24 bytes
        FileInputStream stream;
        try {
            stream = new FileInputStream(file);
            stream.read(data);
            stream.close();
        }
        catch (IOException e) {
          // idk
          int[] someValue = {0, 0};
          return someValue;
        }

        // Check if the file is a PNG image
        if (isPNG(data)) {
            int width = getIntFromBytes(data, 16);
            int height = getIntFromBytes(data, 20);
            int[] dimensions = { width, height };
            return dimensions;
        } else {
            throw new IOException("Not a valid PNG image");
        }
    }

    private boolean isPNG(byte[] data) {
        // Check PNG signature (first 8 bytes)
        return data.length >= 8 &&
                data[0] == (byte) 0x89 &&
                data[1] == (byte) 0x50 &&
                data[2] == (byte) 0x4E &&
                data[3] == (byte) 0x47 &&
                data[4] == (byte) 0x0D &&
                data[5] == (byte) 0x0A &&
                data[6] == (byte) 0x1A &&
                data[7] == (byte) 0x0A;
    }

    private int getIntFromBytes(byte[] data, int offset) {
        return ((data[offset] & 0xFF) << 24) |
               ((data[offset + 1] & 0xFF) << 16) |
               ((data[offset + 2] & 0xFF) << 8) |
               (data[offset + 3] & 0xFF);
    }

    
    public int getPNGUncompressedSize(String path) {
      try {
        int[] widthheight = getPNGImageDimensions(path);
        int wi = widthheight[0];
        int hi = widthheight[1];
        return wi*hi*4;
      }
      catch (IOException e) {
        return Integer.MAX_VALUE;
      }
    }
    
    private int readUnsignedShort(InputStream inputStream) throws IOException {
        int byte1 = inputStream.read();
        int byte2 = inputStream.read();

        if ((byte1 | byte2) < 0) {
            throw new IOException("End of stream reached");
        }

        return (byte1 << 8) + byte2;
    }



    private int[] getJPEGImageDimensions(String filePath) throws IOException {
        File file = new File(filePath);
        FileInputStream stream;
            stream = new FileInputStream(file);
            byte[] data = new byte[2];
            stream.read(data);
            if (isJPEG(data)) {
                // Skip to the SOF0 marker (0xFFC0)
                while (true) {
                    int marker = readUnsignedShort(stream);
                    int length = readUnsignedShort(stream);
                    if (marker >= 0xFFC0 && marker <= 0xFFCF && marker != 0xFFC4 && marker != 0xFFC8) {
                        // Found SOF marker, read dimensions
                        stream.skip(1); // Skip precision byte
                        int hi = readUnsignedShort(stream);
                        int wi = readUnsignedShort(stream);
                        int[] dimensions = {wi, hi};
                        stream.close();
                        return dimensions;
                    } else {
                        // Skip marker segment
                        stream.skip(length - 2);
                    }
                }
            } else {
              stream.close();
                throw new IOException("Not a valid JPEG image");
            }
    }

    private boolean isJPEG(byte[] data) {
        return data.length >= 2 &&
                data[0] == (byte) 0xFF &&
                data[1] == (byte) 0xD8;
    }

    public int getJPEGUncompressedSize(String path) {
      try {
        int[] widthheight = getJPEGImageDimensions(path);
        int wi = widthheight[0];
        int hi = widthheight[1];
        return wi*hi*4;
      }
      catch (IOException e) {
        return Integer.MAX_VALUE;
      }
    }
    
    private int[] getBmpDimensions(String filePath) throws IOException {
        int[] dimensions = new int[2];
        FileInputStream fileInputStream;
        try {
            fileInputStream = new FileInputStream(filePath);
            // BMP header contains width and height information at specific offsets
            fileInputStream.skip(18); // Skip to width bytes
            dimensions[0] = readLittleEndianInt(fileInputStream); // Read width (little-endian)
            dimensions[1] = readLittleEndianInt(fileInputStream); // Read height (little-endian)
            return dimensions;
        }
        catch (IOException e) {
          // idk
          int[] someValue = {0, 0};
          return someValue;
        }
    }

    private int readLittleEndianInt(FileInputStream inputStream) throws IOException {
        byte[] buffer = new byte[4];
        inputStream.read(buffer);
        // Convert little-endian bytes to an integer
        return (buffer[3] & 0xFF) << 24 | (buffer[2] & 0xFF) << 16 | (buffer[1] & 0xFF) << 8 | (buffer[0] & 0xFF);
    }
    
    public int getBMPUncompressedSize(String path) {
      try {
          int[] dimensions = getBmpDimensions(path);
          int wi = dimensions[0];
          int hi = dimensions[1];
          return wi*hi*4;
      } catch (IOException e) {
          return Integer.MAX_VALUE;
      }
    }
    
    // WARNING: might take time to calculate. You should run this in a seperate thread.
    public int getImageUncompressedSize(String path) {
      String ext = getExt(path);
      if (ext.equals("png")) {
        return getPNGUncompressedSize(path);
      }
      else if (ext.equals(ENTRY_EXTENSION) || ext.equals("pdf")) {
        return 0;
      }
      else if (ext.equals("jpg") || ext.equals("jpeg")) {
        return getJPEGUncompressedSize(path);
      }
      else if (ext.equals("gif")) {
        return getGifUncompressedSize(path);
      }
      else if (ext.equals("bmp")) {
        return getBMPUncompressedSize(path);
      }
      else if (ext.equals("tiff")) {
        // TODO: size estimation for tiff
        return 99999;
      }
      else {
        console.bugWarn("getImageUncompressedSize: file format ("+ext+" is not an image format.");
        return Integer.MAX_VALUE;
      }
    }
  }
  
  AtomicBoolean loadedEverything = new AtomicBoolean(false);
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class IndexerModule {
    public final String INDEXER_PATH = "index.txt";
    
    class Leaf {
      String content = "";
      String name = "";
      String path = "";
      int score = 0;
      
      public Leaf(String name, String path, String content, int score) {
        this.name = name;
        this.path = path;
        this.content = content;
        this.score = score;
      }
    }
    
    private class SlowIndexer {
    
      
      public SlowIndexer() {
        
      }
      
      public HashMap<String, Leaf> entries = new HashMap<String, Leaf>();
      
      public void insertString(String st) {
        insertString(st, st);
      }
      
      public void insertString(String path, String st, int score) {
        String name = file.getFilename(path);
        entries.putIfAbsent(name, new Leaf(name, path, cleanString(st), score));
      }
      
      public void insertString(String path, String st) {
        String name = file.getFilename(path);
        entries.put(name, new Leaf(name, path, cleanString(st), 0));
      }
      
      public void removeString(String name, String st) {
        entries.remove(name);
      }
      
      public void save() {
        try (FileWriter fileWriter = new FileWriter("string_set.txt")) {
            for (Leaf leaf : entries.values()) {
                fileWriter.write(leaf.path+"\n");
                fileWriter.write(leaf.content+"\n");
                fileWriter.write(leaf.score+"\n");
            }
        } catch (IOException e) {
            //System.err.println("Error writing to file: " + e.getMessage());
        }
      }
      
      public void load() {
        
      }
      
      public void increaseScore(String name, int increaseValue) {
        entries.get(name).score += increaseValue;
      }
      
      public ArrayList<Leaf> search(String st, String favouredPath) {
        st = cleanString(st);
        favouredPath = favouredPath.toLowerCase();
        ArrayList<Leaf> results = new ArrayList<Leaf>();
        
        if (st.length() == 0 || st.equals(" ")) {
          return results;
        }
        
        
        String[] keywords = st.split(" ");
        
        for (Leaf leaf : entries.values()) {
          boolean contains = true;
          
          leaf.score = 0;
          
          for (String s : keywords) {
            contains &= (leaf.content.contains(s));
            leaf.score++;
          }
          
          if (contains) {
            // Scoring parameters
            if (cleanString(leaf.name).equals(st)) {
              leaf.score += 20;
              //console.log(leaf.name+" exact match");
            }
            //println((file.directorify(file.getDir(leaf.path))), favouredPath);
            if (leaf.path.toLowerCase().contains(favouredPath)) {
              leaf.score += 3;
              
              if (file.getDir(leaf.path).toLowerCase().equals(favouredPath)) {
                //println(leaf.name+"Super favoured path");
              }
              
              if (file.isDirectory(leaf.path)) {
                leaf.score += 5;
                //println(leaf.name+" directory");
              }
            }
            //println(leaf.path, file.isDirectory(leaf.path));
            
            
            
            // Finally
            results.add(leaf);
          }
          
          //if (i > 2000) {
          //  break;
          //}
        }
        //println(i);
        
        
        Collections.sort(results, (o1, o2) -> o2.score-o1.score);
        
        //println(results.size()+" results");
        //if (results.size() == 0) {
        //  println("0 slow search results for \""+st+"\".");
        //}
        //else {
        //  println("Slow search results for \""+st+"\":");
          
          //int count = 1;
          //for (int j = 0; j < results.size(); j++) {
          //  try {
          //    println(count+". "+results.get(j).name+" [score: "+results.get(j).score+"]");
          //    count++;
          //    if (count > 16) break;
          //  }
          //  catch (IndexOutOfBoundsException e) {
              
          //  }
          //}
        //}
        return results;
      }
    }
    
    private String cleanString(String st) {
      st = st.toLowerCase().replaceAll("[!\"£%\\^&\\*\\(\\)<>?,.\\/#'\\[\\]:;#~@{}\\-=_+\\$\\n]", " ");
      while (st.contains("  ")) {
        st = st.replaceAll("  ", " ");;
      }
      return st;
    }
    
    private SlowIndexer indexer; 
    private AtomicBoolean lock = new AtomicBoolean(false);
    
    public IndexerModule() {
      indexer = new SlowIndexer();
      startIndexingThread(DEFAULT_DIR);
    }
    
    public void insert(String path, String st) {
      indexer.insertString(path, st, 1);
    }
    
    public void insert(String path) {
      indexer.insertString(path, cleanString(file.getFilename(path)), 5);
    }
    
    public void insert(String path, int score) {
      indexer.insertString(path, cleanString(path), score);
    }
    
    public void insert(String path, String st, int score) {
      indexer.insertString(path, st, score);
    }
    
    
    public ArrayList<String> search(String query, String favouredPath) {
      while (!lock.compareAndSet(false, true)) { }
      
      ArrayList<String> filenames = new ArrayList<String>();
      ArrayList<Leaf> results = indexer.search(query, favouredPath);
      for (Leaf leaf : results) {
        filenames.add(leaf.path);
      }
      lock.set(false);
      return filenames;
    }
    
    public void load() {
      // TODO
    }
    
    
    private void traverse(String path, int depth) {
      //if (depth > 15) {
      //  return;
      //}
      
      if (depth > 6) return;
      
      if (file.exists(path) && file.isDirectory(path)) {
        File fff = new File(path);
        File[] files = fff.listFiles();
        try {
          for (File f : files) {
            while (!lock.compareAndSet(false, true)) {
              try {
                Thread.sleep(100);
              }
              catch (InterruptedException e) {
                
              }
            }
            String fpath = f.getAbsolutePath().replaceAll("\\\\", "/");
            
            if (file.isDirectory(fpath)) {
              insert(fpath, file.getFilename(fpath));
              lock.set(false);
              traverse(fpath, depth+1);
            }
            else {
              insert(fpath);
              lock.set(false);
            }
          }
        }
        catch (NullPointerException e) {
          
        }
      }
    }
    
    public void startIndexingThread(final String path) {
      if (lowMemory && indexer.entries.size() > 10000) {
        while (!lock.compareAndSet(false, true)) { }
        //console.log("Indexer cleanout");
        indexer.entries.clear();
        System.gc();
      }
      
      Thread t1 = new Thread(new Runnable() {
        public void run() {
          traverse(path, 0);
        }
      });
      //t1.setDaemon(true);
      t1.start();
    }
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class PluginModule {
    private String exepath;
    private String javapath;
    private int cacheEntry = 0;
    
    public PluginModule() {
      // Load the boilerplate for plugin code.
      if (file.exists(APPPATH+BOILERPLATE_PATH)) {
        
      }
      else {
        console.warn(APPPATH+BOILERPLATE_PATH+" not found! Plugins will not work.");
      }
      
      // Get the location of java that is currently running our beloved timeway (we will need it
      // for compiling classes)
      String pp = (new File(".").getAbsolutePath());
      exepath  = pp.substring(0, pp.length()-2).replaceAll("\\\\", "/");
      javapath = exepath+"/java";
    }

    // Actual plugin object
    public class Plugin {
      // These are needed to load the java code
      private Class pluginClass;
      
      // These are needed for comminication between master and slave
      // (Timeway is master and plugin is slave)
      // (yes, it's kinda an offensive term but this is what it's
      // called in the computing world unfortunately.)
      private Method pluginRunPoint;
      private Method pluginGetOpCode;
      private Method pluginGetArgs;
      private Method pluginSetRet;
      private Object pluginIntance;
      public PGraphics sketchioGraphics;
      
      // DO NOT rely on this to get error message. You should only access this after the run() method returns false.
      public String exceptionMessage = "";
      
      // Need this because the run method needs our plugin object.
      private Plugin thisPlugin;
      
      public boolean compiled = false;
      public String errorOutput = "";
      
      // Famous callAPI method.
      // Remember that whenever our plugin (slave) wants to call an API method from master,
      // using a runnable method is the way for inter-plugin communication.
      private Runnable callAPI = new Runnable() {
            public void run() {
              runAPI(thisPlugin);
            }
      };
      
      public Plugin() {
        this.thisPlugin = this;
      }
      
      // Call this to run a cycle of the plugin.
      // Returns true if it runs without problems.
      // Returns false if there's an uncaught exception.
      public boolean run() {
        if (compiled && pluginRunPoint != null && pluginIntance != null) {
          // TODO: extra protection
          // e.g. saving from infinite loops, block from running until resolved,
          // etc.
          try {
            pluginRunPoint.invoke(pluginIntance);
          }
          catch (InvocationTargetException ite) {
              // This exception wraps the actual exception thrown by the invoked method
              Throwable cause = ite.getCause(); // Get the underlying exception
              console.warnOnce("Run plugin exception: " + ite.getClass().getSimpleName() + 
                                " | Cause: " + (cause != null ? cause.getClass().getSimpleName() + " - " + cause.getMessage() : "No cause"));
              if (cause != null) cause.printStackTrace(); // Print the stack trace of the underlying exception
              
              if (cause != null) {
                exceptionMessage = cause.getClass().getSimpleName() + " - " + cause.getMessage();
              }
              else {
                exceptionMessage = "No exception cause specified - typically caused by a bug in TWEngine's plugin handler.";
              }
              
              return false;
          } catch (IllegalAccessException iae) {
              console.warnOnce("Run plugin exception: " + iae.getClass().getSimpleName() + " - " + iae.getMessage());
              exceptionMessage = iae.getClass().getSimpleName() + " - " + iae.getMessage();
              return false;
          } catch (Exception e) {
              console.warnOnce("Run plugin exception: " + e.getClass().getSimpleName() + " - " + e.getMessage());
              exceptionMessage = e.getClass().getSimpleName() + " - " + e.getMessage();
              return false;
          }
        }
        return true;
      }
      
      // Loads class from file.
      void loadPlugin(String pluginPath) {
        //System.out.println("Loading plugin "+pluginPath);
        
        // Here, we do some wacky java stuff I found online to slap some java code into Timeway
        // during runtime.
        URLClassLoader child = null;
        try {
          child = new URLClassLoader(
                  new URL[] {new File(pluginPath).toURI().toURL()},
                  this.getClass().getClassLoader()
          );
        }
        catch (Exception e) {
          console.warn("URL Exception: "+ e.getClass().getSimpleName());
        }
        
        // Dunno why we set pluginClass to null but imma keep it that
        // way so it doesn't break things.
        pluginClass = null;
        try {
          // TODO: Is having the same class name for each plugin bad? Eh, I guess we'll find out soon enough.
          pluginClass = Class.forName("CustomPlugin", true, child);
          // Get the run() method
          pluginRunPoint = pluginClass.getDeclaredMethod("run");
          // annnnd rest should be self-explainatory
          pluginGetOpCode = pluginClass.getDeclaredMethod("getCallOpCode");
          pluginGetArgs = pluginClass.getDeclaredMethod("getArgs");
          pluginSetRet = pluginClass.getDeclaredMethod("setRet", Object.class);
          pluginIntance = pluginClass.getDeclaredConstructor().newInstance();
        }
        // TODO: extended error-catching.
        catch (Exception e) {
          console.warn("LoadPlugin Exception: "+ e.getClass().getSimpleName());
          e.printStackTrace();
        }
        
        // here we call setup(). Maybe TODO: perhaps we should have an onLoad() then an actual setup()?
        try {
          if (sketchioGraphics != null) {
            Method passAppletMethod = pluginClass.getDeclaredMethod("setup", PApplet.class, Runnable.class, PGraphics.class);
            passAppletMethod.invoke(pluginIntance, app, callAPI, sketchioGraphics);
          }
          else {
            Method passAppletMethod = pluginClass.getDeclaredMethod("setup", PApplet.class, Runnable.class);
            passAppletMethod.invoke(pluginIntance, app, callAPI);
          }
        }
        // TODO: extended error checking
        catch (Exception e) {
          System.err.println("passPApplet Exception: "+ e.getClass().getSimpleName());
          System.err.println(e.getMessage());
        }
      }
      
      
      // Compiles the code into a file, then loads the file.
      // And you read this method right, you just provide the code into
      // this method and boom, it'll compile just like that.
      public boolean compile(String code) {
        
        // You might be thinking it's ineffective to just keep
        // counting up the cacheEntries, but they're held on by
        // java (meaning we can't delete them) until the program
        // closes, at which point cacheEntry will obviously be
        // 0, so it'll just end up overwriting the old dead cached
        // entries.
        cacheEntry++;
        compiled = false;
        
        //console.log("Compiling plugin...");
        
        String pluginBoilerplateCode_1 = "";
        String pluginBoilerplateCode_2 = "";
        
        
        // Moved here instead of setup because we want to be able to modify the boilerplate file too without having to restart
        // the program each time.
        
        console.log(APPPATH+BOILERPLATE_PATH);
        
        console.log(file.exists(APPPATH+BOILERPLATE_PATH));
        
        if (file.exists(APPPATH+BOILERPLATE_PATH)) {
          String[] txts = app.loadStrings(APPPATH+BOILERPLATE_PATH);
          boolean secondPart = false;
          for (String s : txts) {
            if (!secondPart && s.trim().equals("[plugin_code]")) {
              // Don't add [plugin_code] line, initiate the second part.
              secondPart = true;
            }
            else if (!secondPart)
              pluginBoilerplateCode_1 += s+"\n";
            else
              pluginBoilerplateCode_2 += s+"\n";
          }
        }
        else {
          console.warn(APPPATH+BOILERPLATE_PATH+" not found! Plugins will not work.");
        }
        
        
        
        // We don't actually need the cache info, but calling this method will
        // create the cache folder if it doesn't already exist, which is wayyyy
        // less work and coding to do. Plus it'll automatically close after 10
        // frames, you know the routine.
        openCacheInfo();
        
        
        // Now remember, we go
        // raw code -> java file (combined with boilerplate) -> class file -> jar file.
        final String javaFileOut = CACHE_PATH+"CustomPlugin.java";
        final String classFileOut = CACHE_PATH+"compiled/CustomPlugin.class";
        
        file.mkdir(CACHE_PATH+"compiled");
        
        // raw code -> java file
        String fullCode = pluginBoilerplateCode_1+code+pluginBoilerplateCode_2;
        app.saveStrings(javaFileOut, fullCode.split("\n"));
        
        
        
        // Delete all .class files in the cache directory
        //File[] cacheFiles = (new File(CACHE_PATH)).listFiles();
        //for (File f : cacheFiles) {
        //  if (file.getExt(f.getName()).equals("class")) {
        //    f.delete();
        //  }
        //}
        
        
        // java file -> class file
        CmdOutput cmd = toClassFile(javaFileOut);
        compiled = cmd.success;
        
        
        if (!compiled) {
          this.errorOutput = cmd.message;
          if (this.errorOutput.length() == 0) {
            this.errorOutput = "Status code error "+cmd.exitCode;
          }
          return false;
        }
        this.errorOutput = "";
        
        
        // class file -> executable jar
        String executableJarFile = toJarFile(classFileOut);
        
        
        // Finally, load the plugin!
        loadPlugin(executableJarFile);
        
        
        return true;
      }
      
      // Now the following methods are to be used by the runAPI functions.
      // Imagine this: slave sends API function, master gets the opcode,
      // gets the arguments, and then returns the value.
      public void ret(Object val) {
        try {
          pluginSetRet.invoke(pluginIntance, val);
        }
        catch (Exception e) {
          // TODO: extended error checking
          println("Ohno");
        }
      }
      
      // Get the API opcode called from slave
      public int getOpCode() {
        try {
          return (int) pluginGetOpCode.invoke(pluginIntance);
        }
        catch (Exception e) {
          // TODO: extended error checking
          println("Ohno");
          return -1;
        }
      }
      
      // Get the arguments from the API call from slave.
      public Object[] getArgs() {
        try {
          return (Object[]) pluginGetArgs.invoke(pluginIntance);
        }
        catch (Exception e) {
          // TODO: extended error checking
          println("Ohno");
          return null;
        }
      }
      
    }
    // End plugin class.
    
    // Literally no point to this other than so you don't
    // need to type out TWEngine.PluginModule.Plugin each time.
    // Damn I need to sort out Timeway...
    public Plugin createPlugin() {
      return new Plugin();
    }
    
    // Use javac (java compiler) to turn our file into a .class file.
    // I have no idea what a .class file is lol.
    CmdOutput toClassFile(String inputFile) {
      String javacPath;
      
      if (isWindows()) {
        javacPath = javapath+"/bin/javac.exe";
      }
      else {
        javacPath = javapath+"/bin/javac";
      }
      
      // Find the processing core so we can use PApplet in our plugin.
      // For the dev version (processing ide)
      String processingCorePath = "";
      if (file.exists(exepath+"/core/library/core.jar")) {
        processingCorePath = exepath+"/core/library/core.jar";
      }
      // for exported builds
      else if (file.exists(exepath+"/lib/core.jar")) {
        processingCorePath = exepath+"/lib/core.jar";
      }
      // Uhoh
      else {
        console.warn("Could not find Processing core.");
        return new CmdOutput(1, "Could not find Processing core.");
      }
      
      
      // Stored in the cache folder.
      final String pluginPath = CACHE_PATH+"compiled/";
      
      // run as if we've opened up cmd/terminal and are running our command.
      CmdOutput cmd = null;
      if (isWindows()) {
        cmd = runExecutableCommand(javacPath, "-d", pluginPath, "-cp", processingCorePath+";"+pluginPath, inputFile);
        //println(javacPath, "-d", pluginPath, "-cp", processingCorePath+";"+pluginPath, inputFile);
        //cmd = runExecutableCommand(javacPath, "-cp", processingCorePath+";"+pluginPath, inputFile);
      }
      else {
        //cmd = runOSCommand("\""+javacPath+"\" -cp \""+processingCorePath+";"+pluginPath+"\" \""+inputFile+"\"");
        cmd = runExecutableCommand(javacPath, "-cp", processingCorePath, inputFile);
      }
      return cmd;
    }
    
    String toJarFile(String classFile) {
      // Good ol jar thingie.
      String jarExePath;
      
      if (isWindows()) {
        jarExePath = javapath+"/bin/jar.exe";
      }
      else {
        jarExePath = javapath+"/bin/jar";
      }
      
      // In our cachepath.
      final String out = CACHE_PATH+"plugin-"+cacheEntry+".jar";
      
      // We need the class path because the command line argument is weird,
      // (that might be an issue if we have tons of other items in our cache folder but oh well)
      // TODO: Shouldn't we be using our own custom file class here????
      final String classPath = (new File(classFile)).getParent().toString();
      //final String className = (new File(classFile)).getName();
      
      //File[] cacheFiles = (new File(CACHE_PATH)).listFiles();
      //String classfiles = "";
      //for (File f : cacheFiles) {
      //  if (file.getExt(f.getName()).equals("class")) {
      //    classfiles += f.getName()+" ";
      //  }
      //}
      
      // And boom. It is then done.
      //runExecutableCommand(jarExePath, "cvf", out, "-C", classPath, className);
      runExecutableCommand(jarExePath, "cvf", out, "-C", classPath, ".");
      
      return out;
    }
    
    public void runAPI(Plugin p) {
      // The getCallOpCode method takes no arguments and returns an int
      // The getArgs method takes no arguments and returns an Object[]
      // The setRet method takes an Object as argument and returns void
      int opcode = p.getOpCode();
      Object[] args = p.getArgs();
      // Opcode of -1 means there was a class-based error with calling the
      // getOpCode method in slave. Same applies with args being null
      if (opcode == -1 || args == null) {
        // error handling code
        return;
      }
      // Run TimeWay's Interfacing Toolkit
      // We're returning stuff every time, but it should not matter
      // if a method does not expect something to return, because
      // it shouldn't check the returned value.
      p.ret(runTWIT(opcode, args));
    }
  }
  
  
  
  // *************************************************************
  // *********************Begin engine code***********************
  // *************************************************************
  public TWEngine(PApplet p) {
    // PApplet & engine init stuff
    app = p;
    app.background(0);
    loadedContent = new HashSet<String>();
    
    console = new Console();
    console.info("Hello console");
    
    if (isAndroid()) {
      APPPATH = "";
      CACHE_PATH = getAndroidCacheDir();
    }
    else {
      // TODO: This is ugly and unmaintainable.
      CACHE_PATH = APPPATH+"cache/";
    }
    
    settings = new SettingsModule();
    input = new InputModule();
    file = new FilemanagerModule();
    stats = new StatsModule();
    sharedResources = new SharedResourcesModule();
    display = new DisplayModule();
    power = new PowerModeModule();
    ui = new UIModule();
    sound = new AudioModule();
    clipboard = new ClipboardModule();
    plugins = new PluginModule();
    indexer = new IndexerModule();
    
    power.putFPSSystemIntoGraceMode();
    
    // First, load the essential stuff.
    
    //loadAsset(APPPATH+SOUND_PATH()+"intro.wav");
    loadAsset(APPPATH+IMG_PATH()+"logo.png");
    loadAllAssets(APPPATH+IMG_PATH()+"loadingmorph/");
    // We need to load shaders on the main thread.
    loadAllAssets(APPPATH+SHADER_PATH());
    // Find out how many images there are in loadingmorph
    File f = new File(APPPATH+IMG_PATH()+"loadingmorph/");
    
    // Idc
    if (isAndroid()) {
      display.loadingFramesLength = 84;
    }
    else {
      display.loadingFramesLength = f.listFiles().length;
    }
    loadAsset(APPPATH+DEFAULT_FONT_PATH());
    
    stats.increase("started_up", 1);
    
    // Huh, "Timeaway" sounds strangely familiar, huh?
    int lastClosed = stats.getInt("last_closed") > 1000 ? stats.getInt("last_closed") : ((int)(System.currentTimeMillis() / 1000L));
    int timeAway = ((int)(System.currentTimeMillis() / 1000L))-lastClosed;
    stats.setIfHigher("longest_time_away", timeAway);
    
    // Load in seperate thread.
    loadedEverything.set(false);
    Thread t1 = new Thread(new Runnable() {
      public void run() {
          loadEverything();
          loadedEverything.set(true);
          System.gc();
        }
      }
    );
    t1.start();

    //println("Running in seperate thread.");
    // Config file
    getUpdateInfo();
    
    lowMemory = settings.getBoolean("low_memory", false);
    enableCaching = settings.getBoolean("caching", true);

    power.setDynamicFramerate(settings.getBoolean("dynamic_framerate", true));
    DEFAULT_FONT_NAME = settings.getString("default_system_font", "Typewriter");
    
    DEFAULT_FONT = display.getFont(DEFAULT_FONT_NAME);
  }
  
  public void startScreen(Screen screen) {
    // Create dummy screen
    dummyScreen = new DummyScreen(this);
    
    // Init loading screen.
    currScreen = screen;
  }


  public Runnable doWhenPromptSubmitted = null;
  public String promptText;
  public boolean inputPromptShown = false;
  public String lastInput = "";

  public void beginInputPrompt(String prompt, Runnable doWhenSubmitted) {
    input.prepareTyping();
    inputPromptShown = true;
    input.addNewlineWhenEnterPressed = false;
    promptText = prompt;
    doWhenPromptSubmitted = doWhenSubmitted;
    openTouchKeyboard();
  }

  public void displayInputPrompt() {
    if (inputPromptShown) {
      if (input.upOnce) {
        if (lastInput.length() > 0) {
          input.keyboardMessage = lastInput;
          input.cursorX = input.keyboardMessage.length();
        }
      }
      
      if (input.ctrlDown && input.keys[int('v')] == 2) {
        //input.keyboardMessage = input.keyboardMessage.substring(0, input.keyboardMessage.length()-1);
        if (clipboard.isString()) {
          input.keyboardMessage += clipboard.getText();
        }
      }
      
      float buttonwi = 200;
      boolean button = ui.basicButton("Enter", display.WIDTH/2-buttonwi/2, display.HEIGHT/2+50, buttonwi, 50f);

      if (input.enterOnce || button) {
        inputPromptShown = false;
        //if (input.keyboardMessage.length() <= 0) return;
        // Remove enter character at end
        if (input.keyboardMessage.length() > 0) {
          int ll = max(input.keyboardMessage.length()-1, 0);   // Don't allow it to go lower than 0
          if (input.keyboardMessage.charAt(ll) == '\n') input.keyboardMessage = input.keyboardMessage.substring(0, ll);
        }
        doWhenPromptSubmitted.run();
        lastInput = input.keyboardMessage;
        closeTouchKeyboard();
      }
      
      // this is such a placeholder lol
      app.noStroke();

      app.fill(255);
      app.textAlign(CENTER, CENTER);
      app.textFont(DEFAULT_FONT, 60);
      app.text(promptText, display.WIDTH/2, display.HEIGHT/2-100);
      app.textSize(30);
      app.text(input.keyboardMessageDisplay(), display.WIDTH/2, display.HEIGHT/2);
    }
  }


  public AtomicBoolean operationComplete = new AtomicBoolean(false);
  public String updateError = "";
  public AtomicInteger completionPercent = new AtomicInteger(0);

  public void downloadFile(String url, String outputFileName) {
    operationComplete.set(false);
    InputStream in;
    try {
      in = (new URL(url)).openStream();
    }
    catch (MalformedURLException e1) {
      console.warn(e1.getMessage());
      updateError = "URL is malformed, this might be an issue on the server side.";
      operationComplete.set(true);
      return;
    }
    catch (IOException e2) {
      console.log("Use /update to attempt the update again.");
      updateError = "Couldn't open update stream, check your connection.";
      operationComplete.set(true);
      return;
    }
    
    
    ReadableByteChannel rbc = Channels.newChannel(in);
    FileOutputStream fos = null;
    try {
      fos = new FileOutputStream(outputFileName);
    }
    catch (FileNotFoundException e1) {
      console.warn(e1.getMessage());
      console.log("Use /update to attempt the update again.");
      updateError = "An unknown error occured on the client side";
      operationComplete.set(true);
      return;
    }
    try {
      fos.getChannel().transferFrom(rbc, 0, Long.MAX_VALUE);
    }
    catch (IOException e) {
      console.log("Use /update to attempt the update again.");
      console.warn("exception warning:"+e.getMessage());
      updateError = "Something happened while streaming from the server, check your connection.";
      operationComplete.set(true);
    }
    try { fos.close(); }
    catch (IOException e) {
      console.warn(e.getMessage());
      updateError = "Couldn't save the download to disk, maybe permissions denied?";
      operationComplete.set(true);
      return;
    }
    operationComplete.set(true);
  }

  public void unzip(String zipFilePath, String destDirectory) {
    completionPercent.set(0);
    operationComplete.set(false);

    File destDir = new File(destDirectory);
    if (!destDir.exists()) {
      destDir.mkdirs();
    }


    byte[] buffer = new byte[1024];
    int numberFilesExtracted = 0;
    try {
      FileInputStream fis = new FileInputStream(zipFilePath);
      ZipInputStream zipInputStream = new ZipInputStream(fis);

      // Get size of the zip file
      ZipFile zipFile = new ZipFile(zipFilePath);
      int zipSize = zipFile.size();
      zipFile.close();
      
      boolean success = true;
      ZipEntry zipEntry = zipInputStream.getNextEntry();
      while (zipEntry != null) {
        String fileName = zipEntry.getName();
        File newFile = new File(destDirectory + File.separator + fileName);

        // Create all non-existing parent directories for the new file
        new File(newFile.getParent()).mkdirs();

        if (!zipEntry.isDirectory()) {
          try {
            FileOutputStream fos = new FileOutputStream(newFile);
            int length;
            while ((length = zipInputStream.read(buffer)) > 0) {
              fos.write(buffer, 0, length);
            }
            fos.close();
            numberFilesExtracted++;
            completionPercent.set(int((float(numberFilesExtracted)/float(zipSize))*100.));
          }
          catch (Exception e) {
            console.warn("Couldn't uncompress file: "+newFile+", "+e.getMessage());
            success = false;
          }
        }
        zipInputStream.closeEntry();
        zipEntry = zipInputStream.getNextEntry();
      }
      zipInputStream.close();
      if (!success)
        updateError = "Something went wrong with extracting individual files.";
      operationComplete.set(true);
    }
    catch (Exception e) {
      console.warn("An error occured with extracting the files, "+e.getMessage());
      e.printStackTrace();
      updateError = "An error occured with extracting the files...";
      operationComplete.set(true);
    }
  }
  
  
  
  public boolean devMode() {
    return !file.exists(sketchPath()+"/lib");
  }
    
  public int getUsedMemKB() {
    long used = (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory());
    return (int)(used/1024L);
  }
  
  public void setLowMemory(boolean enable) {
    settings.setBoolean("low_memory", enable);
    
    // We don't copy exe's if we're running it in the Processing IDE because there is no exe.
    if (devMode()) return;
    
    boolean success = false;
    if (enable) {
      success = file.copy(APPPATH+LOW_MEM_EXE, sketchPath().replaceAll("/", "\\\\")+"/Timeway.exe");
    }
    else {
      success = file.copy(APPPATH+NORMAL_MEM_EXE, sketchPath().replaceAll("/", "\\\\")+"/Timeway.exe");
    }
    
    if (!success) {
      console.warn("Unable to set low memory (copy error) ");
    }
  }
    
  

    
  // We need this because simply storing the output message in a command line
  // is not sufficient; we need error code, whether it was successful or not etc.
  class CmdOutput {
    public int exitCode = -1;
    public boolean success = false;
    public String message = "";
    
    public CmdOutput(int ec, String mssg) {
      exitCode = ec;
      success =  (exitCode == 0);
      message = mssg;
    }
  }

  //public void runExecutableCommand(String cmd) {
  //  if (isWindows()) {
  //      String[] cmds = new String[1];
  //      cmds[0] = cmd;
  //      app.saveStrings(APPPATH+WINDOWS_CMD, cmds);
  //      delay(100);
  //      file.open(APPPATH+WINDOWS_CMD);
  //  }
  //  else {
  //    console.bugWarn("runOSCommand: support for os not implemented!");
  //  }
  //}


  
  // Now this thing basically just runs a windows command, not too complicated.
  // If I'm lucky enough, I think this thing should work in linux too even though
  // the cmd system is completely different, because we're essentially just calling
  // some java executables.
  public CmdOutput runExecutableCommand(String... cmd) {
    try {
      // Run the OS command
      Process process = Runtime.getRuntime().exec(cmd);
      
      
      // Get the messages from the console (so that we can get stuff like error messages).
      BufferedReader stdInput = new BufferedReader(new InputStreamReader(process.getInputStream()));
      //BufferedReader stdOutput = new BufferedReader(new OutputStream(process.getOutputStream()));
      BufferedReader stdError = new BufferedReader(new InputStreamReader(process.getErrorStream()));
      
      
      // This function should prolly run this in a different thread.
      
      boolean timeout = !process.waitFor(settings.getInt("compilation_timeout_milliseconds", 6000), TimeUnit.MILLISECONDS);
      
      if (timeout) {
        return new CmdOutput(1, "Compilation timeout; this is typically caused by a boilerplate code error.");
      }
      
      int exitCode;
      try {
        exitCode = process.exitValue();
      }
      // Had to timeout or process not yet exited.
      catch (IllegalThreadStateException e) {
        return new CmdOutput(1, "No exit code available; may be caused by runExecutableCommand bug.");
      }
      
      
      // s will be used to read the stdout lines.
      String s = null;
      
      // Where we'll actually store our stdoutput
      String stdoutput = "";
      
      if (exitCode == 1) {
        while ((s = stdInput.readLine()) != null) {
            stdoutput += s+"\n";
        }
        //while ((s = stdOutput.readLine()) != null) {
        //    stdoutput += s+"\n";
        //}
        // Truth be told, i should prolly have seperate stdout and stderr
        // but I don't really mind combining it into one message.
        while ((s = stdError.readLine()) != null) {
            stdoutput += s+"\n";
        }
        
        //System.out.println(stdoutput);
      }
      
      //System.out.println("Exit code: "+exitCode);
      // Done!
      return new CmdOutput(exitCode, stdoutput);
    }
    // No need to do additional error checking here because I highly doubt we will get this kind
    // of error unless we intentionally realllllllly mess up some files here.
    catch (Exception e) {
      console.warn("OS command exception: "+ e.getClass().getSimpleName());
      console.warn(e.getMessage());
      // 666 eeeeeevil number.
      return new CmdOutput(666, e.getClass().getSimpleName());
    }
  }
  
  private PImage pdftopngnocache(String path) {
    if (!file.exists(APPPATH+PDFTOPNG_PATH)) {
      console.warn("pdftopng missing!");
      return display.errorImg;
    }
    
    String cachepath = generateCachePath("");
    CmdOutput cmdout = runExecutableCommand(APPPATH+PDFTOPNG_PATH, "-f", "1", "-l", "1", "-r", "48", path, cachepath);
    if (!cmdout.success) {
      console.warn("pdftopng error: "+cmdout.exitCode+" "+cmdout.message);
    }
    
    // Out command executable includes the ".png" file path name automatically
    return loadImage(cachepath+"-000001.png");
  }
  
  // converts png, stores in cache folder, returns cached entry
  // if already exists, and if not, returns png after caching.
  public PImage pdftopng(String path) {
    PImage img = tryLoadImageCache(path, new Runnable() {
      // Here, we gotta generate cache.
      // Pretty easy in hindsight.
      public void run() {
        PImage im2 = pdftopngnocache(path);
        setOriginalImage(im2);
      }
    });
    return img;
  }
  
  
  

  private int updatePhase = 0;
  // 0 - Not updating at all.
  // 1 - Downloading
  // 2 - Unzipping
  private int checkPercentageInterval = 0;
  private int downloadPercent = 0;
  private String downloadPath;

  private void runUpdate() {

    // Download
    if (updatePhase == 1) {

      // Get the download size so we can show a nice progress bar.
      // The size of the download will of course depend on the type of platform we're on.
      // i.e. windows downloads are a lot larger than macos downloads because we include the whole
      // java 8 package.
      int fileSize = 1;
      String plat = "";
      if (isWindows()) {
        plat = "windows-download-size";
      }
      else if (isLinux()) {
        plat = "linux-download-size";
      }
      else if (isMacOS()) {
        plat = "macos-download-size";
      }

      // Get size
      if (updateInfo != null) fileSize = updateInfo.getInt(plat, 1)*1024;  // Time 1024 because download size is in kilobytes
      else console.bugWarn("runUpdate: why is updateInfo null?!");

      // Every 0.5 secs, update the download percentage
      checkPercentageInterval++;
      if (checkPercentageInterval > (int)(30./display.getDelta())) {
        checkPercentageInterval = 0;

        // Because we can't really check how many bytes we've downloaded without making
        // it suuuuuuper slow, let's just do it using a botch'd approach. Scan the file on
        // the drive that's currently being downloaded.
        File dw = new File(this.downloadPath);
        downloadPercent = int(((float)dw.length()/(float)fileSize)*100.);
      }
      // Render the UI
      pushMatrix();
      scale(display.getScale());
      noStroke();
      color c = color(127);
      float x1 = display.WIDTH/2;
      float y1 = 0;
      float hi = 128;
      float wi = 128*2;
      // TODO have some sort of fabric function instead of this mess.
      display.shader("fabric", "color", float((c>>16)&0xFF)/255., float((c>>8)&0xFF)/255., float((c)&0xFF)/255., 1., "intensity", 0.1);
      rect(x1-wi, y1, wi*2, hi);
      display.resetShader();
      ui.loadingIcon(x1-wi+64, y1+64);

      fill(255);
      textAlign(LEFT, TOP);
      textFont(DEFAULT_FONT, 30);
      text("Downloading...", x1-wi+128, y1+10, wi*2-128, hi);
      textSize(20);
      text("You can continue using "+getAppName()+" while updating.", x1-wi+128, y1+50, wi*2-128, hi);
      // Process bar
      fill(0, 127);
      rect(x1-wi+128+10, y1+hi-15, (float(downloadPercent)/100.)*((wi*2)-128-30), 3);
      textAlign(RIGHT, BOTTOM);
      textSize(18);
      text(str(downloadPercent)+"%", x1+wi-5, y1+hi-5);

      popMatrix();
      // If finished downloading move on to extracting the files.
      if (operationComplete.get() == true) {
        // Check no error has occured...
        if (updateError.length() == 0) {
          updatePhase = 2;
          
          Thread t1 = new Thread(new Runnable() {
            public void run() {
                try {
                  unzip(downloadPath, file.getMyDir());
                }
                catch (Exception e) {
                  console.warn("An error occured while downloading update...");
                }
                
                // Once unzipped we no longer need the zip file
                File f = new File(downloadPath);
                // f exists just for safety...
                if (f.exists()) f.delete();
                else console.bugWarn("runUpdate: why is the download zip missing??");
              }
            }
          );
          updateError = "";
          //t1.setDaemon(true);
          t1.start();
        }
        else {
          updatePhase = 666;
        }
      }
      
    } else if (updatePhase == 2) {
      pushMatrix();
      scale(display.getScale());
      noStroke();
      color c = color(127);
      float x1 = display.WIDTH/2;
      float y1 = 0;
      float hi = 128;
      float wi = 128*2;
      // TODO have some sort of fabric function instead of this mess.
      display.shader("fabric", "color", float((c>>16)&0xFF)/255., float((c>>8)&0xFF)/255., float((c)&0xFF)/255., 1., "intensity", 0.1);
      rect(x1-wi, y1, wi*2, hi);
      display.resetShader();
      ui.loadingIcon(x1-wi+64, y1+64);

      fill(255);
      textAlign(LEFT, TOP);
      textFont(DEFAULT_FONT, 30);
      text("Extracting...", x1-wi+128, y1+10, wi*2-128, hi);
      textSize(20);
      text(getAppName()+" will restart in the new version shortly.", x1-wi+128, y1+50, wi*2-128, hi);
      
      downloadPercent = completionPercent.get();
      // Process bar
      fill(0, 127);
      rect(x1-wi+128+10, y1+hi-15, (float(downloadPercent)/100.)*((wi*2)-128-30), 3);
      textAlign(RIGHT, BOTTOM);
      textSize(18);
      text(str(downloadPercent)+"%", x1+wi-5, y1+hi-5);
      
      popMatrix();
      
      
      if (operationComplete.get()) {
        delay(1000);
        if (updateError.length() == 0) {
          String exeloc = "";
          if (isWindows()) {
              exeloc = updateInfo.getString("windows-executable-location", "");
          }
          else if (isLinux()) {
              exeloc = updateInfo.getString("linux-executable-location", "");
          }
          else if (isMacOS()) {
              exeloc = updateInfo.getString("macos-executable-location", "");
          }
          // TODO: move files from old version
          String newVersion = file.getMyDir()+exeloc;
          File f = new File(newVersion);
          if (f.exists()) {
            updatePhase = 0;
            //Process p = Runtime.getRuntime().exec(newVersion);
            String cmd = "start \""+getAppName()+"\" /d \""+file.getDir(newVersion).replaceAll("/", "\\\\")+"\" \""+file.getFilename(newVersion)+"\"";
            console.log(cmd);
            runExecutableCommand(cmd);
            delay(500);
            exit();
          }
          else {
            console.warn("New version of "+getAppName()+" could not be found, please close "+getAppName()+" and open new version manually.");
            console.log("The new version should be somewhere in "+newVersion);
            updatePhase = 0;
          }
        }
        else {
          updatePhase = 666;
        }
      }
    }
    else if (updatePhase == 666) {
      pushMatrix();
      scale(display.getScale());
      noStroke();
      color c = color(127);
      float x1 = display.WIDTH/2;
      float y1 = 0;
      float hi = 128;
      float wi = 128*2;
      // TODO have some sort of fabric function instead of this mess.
      display.shader("fabric", "color", float((c>>16)&0xFF)/255., float((c>>8)&0xFF)/255., float((c)&0xFF)/255., 1., "intensity", 0.1);
      rect(x1-wi, y1, wi*2, hi);
      display.resetShader();
      
      display.imgCentre("error", x1-wi+64, y1+64);
      
      fill(255);
      textAlign(LEFT, TOP);
      textFont(DEFAULT_FONT, 30);
      text("An error occurred...", x1-wi+128, y1+10, wi*2-128, hi);
      textSize(20);
      text(updateError, x1-wi+128, y1+50, wi*2-128, hi);
      
      popMatrix();
    }
  }
  
  public String getExeFilename() {
    if (isWindows()) {
      // TODO: Smarter finding filename?
      return getAppName()+".exe";
    }
    else if (isLinux()) {
      console.bugWarn("getExeFilename(): Not implemented for Linux");
    }
    else if (isMacOS()) {
      console.bugWarn("getExeFilename(): Not implemented for MacOS");
    }
    return "";
  }
  
  public void restart() {
    String cmd = "";
    
    // TODO: make restart work while in Processing (dev mode)
    if (isWindows()) {
      cmd = "start \""+getAppName()+"\" /d \""+file.getMyDir().replaceAll("/", "\\\\")+"\" \""+getExeFilename()+"\"";
    }
    else if (isLinux()) {
      console.bugWarn("restart(): Not implemented for Linux");
      return;
    }
    else if (isMacOS()) {
      console.bugWarn("restart(): Not implemented for MacOS");
      return;
    }
    runExecutableCommand(cmd);
    delay(500);
    exit();
  }


  void beginUpdate(final String downloadUrl, final String downloadPath) {
    this.downloadPath = downloadPath;

    // Phase 1: download zip file
    updatePhase = 1;

    // Run in a seperate thread obviously
    Thread t1 = new Thread(new Runnable() {
      public void run() {
        // Delete the old file as it may be leftover from an attempted update.
        File old = new File(downloadPath);
        if (old.exists()) old.delete();
        try {
          downloadFile(downloadUrl, downloadPath);
        }
        catch (Exception e) {
          updateError = "An unknown error occured while downloading update...";
          console.warn("An error occured while downloading update...");
        }
      }
    }
    );
    updateError = "";
    
    //t1.setDaemon(true);
    t1.start();
  }

  public boolean commandPromptShown = false;
  public void showCommandPrompt() {
    commandPromptShown = true;

    // Execute our command when the command is submitted.
    Runnable r = new Runnable() {
      public void run() {
        commandPromptShown = false;
        runCommand(input.keyboardMessage);
      }
    };

    beginInputPrompt("Enter command", r);
    input.keyboardMessage = "/";
    input.cursorX = input.keyboardMessage.length();
  }

  private boolean commandEquals(String input, String expected) {
    int ind = input.indexOf(' ');
    if (ind <= -1) {
      ind = input.length();
    } else {
      if (ind >= input.length())  return false;
    }
    return (input.substring(0, ind).equals(expected));
  }
  
  
  public void toggleUnfocusedMusic() {
    playWhileUnfocused = !playWhileUnfocused;
    if (playWhileUnfocused) console.log("Background music (while focused) enabled.");
    else console.log("Background music (while focused) disabled.");
  }


  public void runCommand(String command) throws RuntimeException {
    boolean success = true;
    
    // TODO: have a better system for commands.
    if (command.equals("/powersaver")) {
      if (!power.getPowerSaver()) {
        power.setPowerSaver(true);
        console.log("Power saver enabled.");
      }
      else {
        power.setPowerSaver(false);
        console.log("Power saver disabled.");
      }
    } else if (commandEquals(command, "/forcepowermode")) {
      // Count the number of characters, add one.
      // That's how you deal with substirng.
      String arg = "";
      if (command.length() > 16)
        arg = command.substring(16);

      power.setForcedPowerMode(arg);
      if (arg.equals("HIGH") || arg.equals("NORMAL") || arg.equals("SLEEPY") || arg.equals("MINIMAL")) console.log("Forced power mode set to "+arg);
      else console.log("Unknown power mode "+arg);
    } else if (commandEquals(command, "/disableforcepowermode")) {
      console.log("Disabled forced powermode.");
      power.disableForcedPowerMode();
    } else if (commandEquals(command, "/benchmark")) {
      int runFor = 180;
      String arg = "";
      if (command.length() > 11) {
        arg = command.substring(11);
        console.log(arg);
        runFor = int(arg);
      }

      beginBenchmark(runFor);
    } else if (commandEquals(command, "/debuginfo")) {
      // Toggle debug info
      console.debugInfo = !console.debugInfo;
      if (console.debugInfo) console.log("Debug info enabled.");
      else console.log("Debug info disabled.");
    } else if (commandEquals(command, "/update")) {
      if (isAndroid()) {
        console.log("Can't update within the app, check https://teojt.github.io/timeway for updates!");
      }
      else {
        shownUpdateScreen = false;
        showUpdateScreen = false;
        getUpdateInfo();
        // Force delay
        while (!updateInfoLoaded.get()) { delay(10); }
        processUpdate();
        if (showUpdateScreen) {
          
          console.log("An update is available!");
        }
        else console.log("No updates available.");
      }
    } 
    else if (commandEquals(command, "/throwexception")) {
      console.log("Prepare for a crash!");
      throw new RuntimeException("/throwexception command");
    }
    else if (commandEquals(command, "/restart")) {
      console.log("Restarting "+getAppName()+"...");
      restart();
    }
    else if (commandEquals(command, "/backgroundmusic") || commandEquals(command, "/backmusic")) {
      toggleUnfocusedMusic();
    }
    else if (commandEquals(command, "/enablebackgroundmusic") || commandEquals(command, "/enablebackmusic")) {
      playWhileUnfocused = true;
      console.log("Background music (while focused) disabled.");
    }
    else if (commandEquals(command, "/disablebackgroundMusic") || commandEquals(command, "/disablebackMusic")) {
      playWhileUnfocused = false;
      console.log("Background music (while focused) disabled.");
    }
    else if (commandEquals(command, "/showfps")) {
      if (display.showFPS()) {
        display.setShowFPS(false);
        console.log("FPS hidden.");
      }
      else {
        display.setShowFPS(true);
        console.log("FPS shown.");
      }
    }
    else if (commandEquals(command, "/cpubenchmark")) {
      if (display.showCPUBenchmarks) {
        display.showCPUBenchmarks = false;
        console.log("CPU benchmarks hidden.");
      }
      else {
        display.showCPUBenchmarks = true;
        console.log("CPU benchmarks shown.");
      }
    }
    else if (commandEquals(command, "/stopmusic")) {
      console.log("Music stopped");
      sound.stopMusic();
    }
    else if (commandEquals(command, "/reloadshaders")) {
      display.reloadShaders();
      console.log("Shaders reloaded.");
    }
    else if (commandEquals(command, "/memusage")) {
      showMemUsage = !showMemUsage;
      if (showMemUsage) console.log("Memory usage bar shown.");
      else console.log("Memory usage bar hidden.");
    }
    else if (commandEquals(command, "/sleepmode") || commandEquals(command, "/minimalmode") || commandEquals(command, "/minimizedmode")) {
      power.allowMinimizedMode = !power.allowMinimizedMode;
      console.log("Minimized mode "+(power.allowMinimizedMode ? "enabled" : "disabled"));
    }
    else if (commandEquals(command, "/gc")) {
      console.log("Garbage collector called.");
      System.gc();
    }
    //else if (commandEquals(command, "/testrelative")) {
    //  String fro = "C:/mydata/notebook/hazy_era/homen/006";
    //  String to = "C:/mydata/notebook/hazy_era/homen/007";
    //  String relative = file.getRelativeDir("C:/mydata/notebook/cold_summer/homen/006", to);
      
    //  console.log(fro + ", " + to);
    //  console.log(relative);
    //  console.log(file.relativeToAbsolute(fro, relative));
    //}
    
    // No commands
    else if (command.length() <= 1) {
      // If empty, do nothing and close the prompt.
    } else if (currScreen.customCommands(command)) {
      // Do nothing, we just don't want it to return "unknown command" for a custom command.
    } else {
      console.log("Unknown command.");
      success = false;
    }
    if (success)
      stats.increase("commands_entered", 1);
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
          twengineRequestBenchmarks();
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


  // This is a debug function used for measuring performance at certain points.
  public void timestamp(String name) {
    if (!benchmark) {
      long nanoCapture = System.nanoTime();
      if (lastTimestampName == null) {
        //String out = name+" timestamp captured.";
        //if (console != null) console.info(out);
        //else println(out);
      } else {
        //String out = lastTimestampName+" - "+name+": "+str((nanoCapture-lastTimestamp)/1000)+"microseconds";
        //if (console != null) console.info(out);
        //else println(out);
      }
      lastTimestampName = name;
      lastTimestamp = nanoCapture;
    } else {
      long nanoCapture = System.nanoTime();
      benchmarkArray[timestampIndex++] += (nanoCapture-lastTimestamp)/1000;
      lastTimestamp = nanoCapture;

      if (finalBenchmarkFrame) {
        // Calculate the average for that timestamp.
        long results = benchmarkArray[timestampIndex-1] /= benchmarkFrames;
        String mssg = lastTimestampName+" - "+name+": "+str(results)+" microseconds";
        benchmarkResults.add(mssg);
        lastTimestampName = name;
      }
    }
  }

  public final String UPDATE_INFO_URL = "https://teojt.github.io/updates/timeway_update.json";

  JSONObject updateInfo = null;
  public boolean shownUpdateScreen = false;
  AtomicBoolean updateInfoLoaded = new AtomicBoolean(false);
  public boolean showUpdateScreen = false;
  public void getUpdateInfo() {
    // That's right, the update feature goes completely unused in android.
    if (!isAndroid()) {
      Thread t = new Thread(new Runnable() {
        public void run() {
          try {
            updateInfo = loadJSONObject(UPDATE_INFO_URL);
          }
          catch (Exception e) {
            console.warn("Couldn't get update info");
          }
          updateInfoLoaded.set(true);
        }
      }
      );
      updateInfoLoaded.set(false);
      t.start();
    }
  }



  public void processUpdate() {
    if (!shownUpdateScreen && updateInfoLoaded.get()) {
      shownUpdateScreen = true;
      boolean update = true;
      try {
        update &= updateInfo.getString("type", "").equals("update");
        update &= !updateInfo.getString("version", "").equals(VERSION);
        JSONArray compatibleVersion = updateInfo.getJSONArray("compatible-versions");

        boolean compatible = false;
        for (int i = 0; i < compatibleVersion.size(); i++) {
          compatible |= compatibleVersion.getString(i).equals(VERSION);
        }
        compatible |= updateInfo.getBoolean("update-if-incompatible", false);
        compatible |= updateInfo.getBoolean("update-if-uncompatible", false);    // Oops I made a typo at one point

        update &= compatible;

        // Check if there's a release available for the platform Timeway is running on.
        String downloadURL = "";
        if (isWindows()) {
          downloadURL = updateInfo.getString("windows-download", "[none]");
        }
        else if (isLinux()) {
          downloadURL = updateInfo.getString("linux-download", "[none]");
        }
        else if (isMacOS()) {
          downloadURL = updateInfo.getString("macos-download", "[none]");
        }
        update &= !(downloadURL.equals("[none]") || downloadURL.equals("null"));

        // Priority
        // 0: optional  (no prompt)
        // 1: standard  (prompt)
        // 2: kinda important  (show even if updates repressed)
        // 3: important  (update automatically without permission, even if updates are repressed, DO NOT USE UNLESS EMERGENCY)
        update &= (updateInfo.getInt("priority", 1) > 0);
      }
      catch (Exception e) {
        console.warn("A problem occured with trying to get update info.");
        showUpdateScreen = false;
        return;
      }

      showUpdateScreen = update;
    }
  }
  

  public void loadEverything() {
    // load everything else.
    loadAllAssets(APPPATH+IMG_PATH());
    loadAllAssets(APPPATH+FONT_PATH());
    loadAllAssets(APPPATH+SHADER_PATH());
    loadAllAssets(APPPATH+SOUND_PATH());
  }

  
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
        messageColor = color(255, 255);
        interval = 0;
        this.message = "";
        this.pos = initialPos;
        basicui = new BasicUI();
      }

      //public void enableUI() {
      //  enableBasicUI = true;
      //}

      //public void disableUI() {
      //  enableBasicUI = false;
      //}

      public void move() {
        this.pos++;
      }

      public int getPos() {
        return this.pos;
      }

      //public boolean isBusy() {
      //  return (interval > 0);
      //}

      //public void kill() {
      //  interval = 0;
      //}

      public void message(String message, color messageColor) {
        this.pos = 0;
        this.interval = 200;
        this.message = message;
        this.messageColor = messageColor;
      }

      public void display() {
        if (display != null) display.recordRendererTime();
        
        app.textFont(consoleFont);
        if (force) {
          if (interval > 0) {
            interval--;
          }

          int ypos = pos*32;
          noStroke();
          fill(0);
          int recWidth = int(display.WIDTH/2.);
          if (recWidth < textWidth(this.message)) {
            recWidth = (int)textWidth(this.message)+10;
          }
          app.rect(0, ypos, recWidth, 32);
          app.textSize(24);
          app.textAlign(LEFT);
          app.fill(this.messageColor);
          app.text(message, 5, ypos+20);
        } else {
          if (interval > 0 && pos < displayLines) {
            interval--;
            int ypos = pos*32;
            app.noStroke();
            if (interval < 60) {
              fill(0, 4.25*float(interval));
            } else {
              fill(0);
            }
            int recWidth = int(display.WIDTH/2.);
            if (recWidth < app.textWidth(this.message)) {
              recWidth = (int)app.textWidth(this.message)+10;
            }
            app.rect(0, ypos, recWidth, 32);
            app.textSize(24);
            app.textAlign(LEFT);
            if (interval < 60) {
              app.fill(this.messageColor, 4.25*float(interval));
            } else {
              app.fill(this.messageColor);
            }
            app.text(message, 5, ypos+20);
          }
        }
        if (display != null) display.recordLogicTime();
      }
    }

    public Console() {
      this.consoleLine = new ConsoleLine[totalLines];
      this.generateConsole();
      
      boolean createFontFailed = false;
      try {
        consoleFont = createFont(APPPATH+CONSOLE_FONT(), 24);
      }
      catch (RuntimeException e) {
        createFontFailed = true;
      }
      if (createFontFailed) consoleFont = null;
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

    //private void killLines() {
    //  for (int i = 0; i < totalLines; i++) {
    //    this.consoleLine[i].kill();
    //  }
    //}

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
      } else if (message instanceof Integer) {
        m = str((Integer)message);
      } else if (message instanceof Float) {
        m = str((Float)message);
      } else if (message instanceof Boolean) {
        m = str((Boolean)message);
      } else {
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
      //if (enableBasicUI) {
      //  this.basicui.showWarningWindow(message);
      //}
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
      rect(200+offsetX, 300+offsetY, display.WIDTH-400, display.HEIGHT-500);
      fill(color(255, 127, 0));
      rect(200+offsetX, 200+offsetY, display.WIDTH-400, 100);

      noStroke();

      textAlign(CENTER, CENTER);
      textSize(62);
      fill(255);
      text("WARNING!!", display.WIDTH/2+offsetX, 240+offsetY);

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
    if (loadedContent.contains(name) || name.equals("everything") || name.equals("load_list")) {
      return;
    }
    // if extension is image
    if (ext.equals("png") || ext.equals("jpg") || ext.equals("gif") || ext.equals("bmp")) {
      // load image and add it to the systemImages hashmap.
      if (display.systemImages.get(name) == null) {
        display.systemImages.put(name, app.loadImage(path));
        loadedContent.add(name);
      } else {
        console.warn("Image "+name+" already exists, skipping.");
      }
    } else if (ext.equals("otf") || ext.equals("ttf")) {       // Load font.
      display.fonts.put(name, app.createFont(path, 32));
    } else if (ext.equals("vlw")) {
      display.fonts.put(name, app.loadFont(path));
    } else if (ext.equals("glsl") || ext.equals("vert")) {
      display.loadShader(path);
    } else if (ext.equals("frag")) {
      // Don't load anything since .vert also loads corresponding .frag
    } else if (ext.equals("wav") || ext.equals("ogg") || ext.equals("mp3")) {
      sound.sounds.put(name, new SoundFile(app, path));
    } else if (ext.equals("ini")) {
      // Just ignore these
    } else {
      console.warn("Unknown file type "+ext+" for file "+name+", skipping.");
    }
  }

  public void loadAllAssets(String path) {
    // Get list of all assets in current dir
    
    
    File f = new File(path);
    String[] assets = null;
    
    // Unfortunately in Android, we're not allowed to call listFiles()
    // in our own data directory. Therefore, there is a list of predefined
    // asset locations that tell our system which files to load.
    // It should be in the same directory where we call loadAllAssets()
    
    if (isAndroid()) {
      assets = app.loadStrings(file.directorify(path)+"load_list.txt");
    }
    else {
      File[] files = f.listFiles();
      assets = new String[files.length];
      for (int i = 0; i < files.length; i++) {
        assets[i] = files[i].getAbsolutePath();
      }
    }
    
    if (assets != null) {
      // Loop through all assets
      for (int i = 0; i < assets.length; i++) {
        // If asset is a directory
        String ext = file.getExt(assets[i]);
        if (ext.length() <= 1) {
          // Load all assets in that directory
          loadAllAssets(assets[i]);
          //println(assets[i]+" is dir");
        }
        // If asset is a file
        else {
          // Load asset
          loadAsset(assets[i]);
          //println(assets[i]+" is file");
        }
      }
    }
    else console.warn("Missing assets, was the files tampered with?");
  }

  

  private float counter = 0.;

  public int counter(int max, int interval) {
    return (int)((counter)/interval) % (max);
  }

// TODO: There is literally a function in Processing which does exactly what this function does. Remove it.
  public String appendZeros(int num, int length) {
    String str = str(num);
    while (str.length() < length) {
      str = "0"+str;
    }
    return str;
  }

  public boolean isLoading() {
    // Report loading if standard assets (images etc) are still being loaded
    if (loadedEverything.get() == false) return true;
    
    // If caching's turned off wait for GStreamer.
    if (isAndroid()) {
      // Android doesn't wait for music
      // Anyways do nothing here to stop the other code below running.
    }
    //else if (!CACHE_MUSIC) {
    //  if (sound.loadingMusic()) return true;
    //}
    else {
      // Otherwise, proceed right ahead if-
      // The home dir's .pixelrealm-bgm is cached
      // The default music/legacy default music is being played (these are automatically cached.
      // If we're not using the default music and the home realm with the .pixelrealm file isn't cached,
      // we have no choice but to wait (or start with silence but this isn't desireable so lets just report that its still loading) 
      
      
      //if (sound.loadingMusic() && !pixelrealmCache())
      //  return true;
    }
    
    return false;
  }


  public int calculateChecksum(PImage image) {
    // To prevent a really bad bug from happening, only actually calculate the checksum if the image is bigger than say,
    // 64 pixels lol.
    try {
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
      } else return 0;
    }
    catch (RuntimeException e) {
      return 0;
    }
  }

  public JSONObject cacheInfoJSON = new JSONObject();

  // Whenever cache is written, it would be inefficient to open and close the file each time. So, have a timeout
  // timer which when it expires, the file is written and saved and closed.
  public int cacheInfoTimeout = 0;

  public void openCacheInfo() {
    boolean createNewInfoFile = false;

    File cacheFolder = new File(CACHE_PATH);
    if ((cacheFolder.exists() && cacheFolder.isDirectory()) == false) {
      createNewInfoFile = true;
      console.info("openCacheInfo: cache folder gone, regenerating folder.");
      if (!cacheFolder.mkdir()) {
        console.warn("Couldn't remake the cache directory for whatever reason...");
        return;
      }
    }
    

    // First, open the cache file if it's not been opened already.
    if (cacheInfoTimeout == 0) {
      // Should be true if the info file doesn't exist.
      console.info("openCacheInfo: "+CACHE_PATH+CACHE_INFO());
      if (!file.exists(CACHE_PATH+CACHE_INFO())) {
        createNewInfoFile = true;
      } else {
        try {
          cacheInfoJSON = loadJSONObject(CACHE_PATH+CACHE_INFO());
        }
        catch (RuntimeException e) {
          console.warn("Cache info read failure.");
          //createNewInfoFile = true;
          return;
        }
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
      saveJSONObject(cacheInfoJSON, CACHE_PATH+CACHE_INFO());

      cacheInfoTimeout = 0;
    }
  }

  private int cacheShrinkX = 0;
  private int cacheShrinkY = 0;
  public void setCachingShrink(int x, int y) {
    cacheShrinkX = x;
    cacheShrinkY = y;
  }
  
  // Gets the size of the cache if available, otherwise returns the original size.
  public int getCacheSize(String originalPath) {
    openCacheInfo();
    JSONObject cachedItem = cacheInfoJSON.getJSONObject(originalPath);
    if (cachedItem != null) {
      return cachedItem.getInt("size", 0);
    }
    else {
      String ext = file.getExt(originalPath);
      if (ext.equals("bmp") || ext.equals("png") || ext.equals("jpeg") || ext.equals("jpg") || ext.equals("gif")) {
        return file.getImageUncompressedSize(originalPath);
      }
      else {
        console.bugWarn("getCacheSize: unsupported file format "+ext+", returning file size.");
        return (int)((new File(originalPath)).length());
      }
    }
  }
  
  
  public boolean cacheExists(String originalPath) {
    return !tryGetCachePath(originalPath).equals(originalPath);
  }
  
  
  public String tryGetCachePath(String originalPath) {
    openCacheInfo();

    JSONObject cachedItem = cacheInfoJSON.getJSONObject(originalPath);

    if (cachedItem != null) {
      String actualPath = cachedItem.getString("actual", "");
      

        if (actualPath.length() > 0) {
          String lastModified = "[null]";        // Test below automatically fails if there's no file found.
          if (file.exists(originalPath)) lastModified = file.getLastModified(originalPath);
      
          if (cachedItem.getString("lastModified", "").equals(lastModified) || cachedItem.getString("lastModified", "").equals("")) {
            return actualPath;
          }
        }
    }
    
    return originalPath;
  }
  
  
  // IMPORTANT NOTE: This function does NOT load in a seperate thread, so you should do that yourself
  // when using this!
  public SoundFile tryLoadSoundCache(String originalPath, Runnable readOriginalOperation) {
    openCacheInfo();

    JSONObject cachedItem = cacheInfoJSON.getJSONObject(originalPath);
    
    
    // If the object is null here, then there's no info therefore we cannot
    // perform the checksum, so continue to load original instead.
    if (cachedItem != null) {
      console.info("tryLoadSoundCache: Found cached entry from info file");
      
      
      // First, load the actual sound using the actual file path (the one above is a lie lol)
      String actualPath = cachedItem.getString("actual", "");
      

        if (actualPath.length() > 0) {
          String lastModified = "[null]";        // Test below automatically fails if there's no file found.
          if (file.exists(originalPath)) lastModified = file.getLastModified(originalPath);
      
          // Check if the sound has been modified at all since last time before we load the original.
          if (cachedItem.getString("lastModified", "").equals(lastModified)) {
            console.info("tryLoadSoundCache: No modifications");
            
            // No checksum tests because checksums are kinda useless anyways!
            
            // All checks passed so we can load the cache.
            console.info("tryLoadSoundCache: loading cached sound");
            try {
              // Do NOT let this stay in RAM once we're done with it! (the false argument in this constructor)
              SoundFile loadedSound = new SoundFile(app, actualPath, false);
              return loadedSound;
            }
            catch (RuntimeException e) {
              console.info("tryLoadSoundCache: welp, time to load the original!");
              console.info("tryLoadSoundCache: something went wrong with loading cache (maybe it's corrupted)");
            }
            
            
            // After this point something happened to the original image (or cache in unusual circumstances)
            // and must not be used.
            // We continue to load original and recreate the cache.
          }
      }
      
      
    }
    
    // We should only reach this point if no cache exists or is corrupted
    console.info("tryLoadSoundCache: loading original instead");
    if (readOriginalOperation != null) readOriginalOperation.run();
    console.info("tryLoadSoundCache: done loading");
    

    SoundFile returnSound = originalSound;
    // Set it to null to catch programming errors next time.
    originalSound = null;
    return returnSound;
  }

  // Returns image if an image is found, returns null if cache for that image doesn't exist.
  public PImage tryLoadImageCache(String originalPath, Runnable readOriginalOperation) {
    console.info("tryLoadImageCache: "+originalPath);
    // TODO: Worryingly bad threading issues here.
    openCacheInfo();
    
    try {
      JSONObject cachedItem = cacheInfoJSON.getJSONObject(originalPath);
  
      // If the object is null here, then there's no info therefore we cannot
      // perform the checksum, so continue to load original instead.
      if (cachedItem != null) {
        console.info("tryLoadImageCache: Found cached entry from info file");
        // First, load the actual image using the actual file path (the one above is a lie lol)
        String actualPath = cachedItem.getString("actual", "");
  
        if (actualPath.length() > 0) {
          console.info("tryLoadImageCache: loading cached image");
          PImage loadedImage = loadImage(actualPath);
          if (loadedImage != null) {
            console.info("tryLoadImageCache: Found cached image");
  
            File f = new File(originalPath);
            String lastModified = "[null]";
            if (f.exists()) lastModified = file.getLastModified(originalPath);
  
            if (cachedItem.getString("lastModified", "").equals(lastModified)) {
              console.info("tryLoadImageCache: No modifications");
  
              // Perform a checksum which determines if the image can properly be loaded.
              int checksum = calculateChecksum(loadedImage);
              // Return -1 by default if for some reason the checksum is abscent because checksums shouldn't be negative
              if (checksum == cachedItem.getInt("checksum", -1)) {
                console.info("tryLoadImageCache: checksums match");
                return loadedImage;
              } else console.info("tryLoadImageCache: Checksums don't match "+str(checksum)+" "+str(cachedItem.getInt("checksum", -1)));
  
              // After this point something happened to the original image (or cache in unusual circumstances)
              // and must not be used.
              // We continue to load original and recreate the cache.
            }
          }
          else {
            console.warn("what");
          }
        }
      }
  
      // We should only reach this point if no cache exists or is corrupted
      console.info("tryLoadImageCache: loading original instead");
      readOriginalOperation.run();
      console.info("tryLoadImageCache: done loading");
  
      // At this point we *should* have an image in cachedImage
      if (originalImage == null) {
        //console.bugWarn("tryLoadImageCache: Your runnable must store your loaded image using setOriginalImage(PImage image)");
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
    catch (RuntimeException e) {
      return display.errorImg;
    }
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
    if (image == null) return;
    console.info("scaleDown: "+str(image.width)+","+str(image.height)+",scale"+str(scale));
    if ((image.width > scale || image.height > scale)) {
      // If the image is vertical, resize to 0x512
      if (image.height > image.width) {
        image.resize(0, scale);
      }
      // If the image is horizontal, resize to 512x0
      else if (image.width > image.height) {
        image.resize(scale, 0);
      }
      // Eh just scale it horizontally by default.
      else image.resize(scale, 0);
    }
  }
  
  
  public String saveCacheEntry(String originalPath, int size) {
    
    JSONObject properties = new JSONObject();
    String cachePath = generateCachePath(file.getExt(originalPath));
    
    
    properties.setString("actual", cachePath);
    
    if (file.exists(originalPath)) {
      properties.setString("lastModified", file.getLastModified(originalPath));
      properties.setInt("size", size);
    }
    else {
      properties.setString("lastModified", "");
      properties.setInt("size", size);
    }
    
    cacheInfoJSON.setJSONObject(originalPath, properties);
    stats.increase("cache_files_created", 1);
    
    saveCacheInfoNow();
    
    return cachePath;
  }
  

  // TODO: Put this in a seperate thread, because hoo lordy.
  public String saveCacheImage(String originalPath, PImage image) {
    console.info("saveCacheImage: "+originalPath);
    //if (image instanceof Gif) {
    //  console.warn("Caching gifs not supported yet!");
    //  return originalPath;
    //}
    openCacheInfo();

    JSONObject properties = new JSONObject();

    String cachePath = generateCachePath(CACHE_FILE_TYPE);

    final String savePath = cachePath;
    final int resizeByX = cacheShrinkX;
    final int resizeByY = cacheShrinkY;
    console.info("saveCacheImage: generating cache in main thread");

    // Scale down the cached image so that we have sweet performance and minimal ram usage next time we load up this
    // world. Check if it's actually big enough to be scaled down and scale down by whether it's taller or wider.

    // TODO: cacheShrinkX and cacheShrinkY are not actually needed, we just need a true/false boolean.
    if (resizeByX != 0 || resizeByY != 0) 
      //image = experimentalScaleDown(image);
      scaleDown(image, max(resizeByX, resizeByY));

    console.info("saveCacheImage: saving...");
    try {
      image.save(savePath);
      console.info("saveCacheImage: saved");
    }
    catch (RuntimeException e) {
      console.warn("Image caching failed.");
    }

    properties.setString("actual", cachePath);
    properties.setInt("checksum", calculateChecksum(image));
    
    if (file.exists(originalPath)) {
      properties.setString("lastModified", file.getLastModified(originalPath));
      properties.setInt("size", image.width*image.height*4);
    }
    else {
      properties.setString("lastModified", "");
      
      // TODO: Gif support.
      properties.setInt("size", image.width*image.height*4);
    }

    cacheInfoJSON.setJSONObject(originalPath, properties);
    console.info("saveCacheImage: Done creating cache");
    stats.increase("cache_files_created", 1);

    return cachePath;
  }

  // Don't care
  @SuppressWarnings("unused")
  public PImage saveCacheImageBytes(String originalPath, byte[] bytes, String type) {
    openCacheInfo();


    String cachePath = generateCachePath(type);

    // Save it as a png.
    saveBytes(cachePath, bytes);
    // Load the png.
    PImage img = loadImage(cachePath);
    
    // TODO: I don't like this line of code at all...
    //File f = new File(cachePath);
    //f.delete();
    
    // Also remember to uncomment that.
    // Actually... I think that's what was causing the annoying concurrentException bug...
    // Let's leave that commented...
    //JSONObject properties = new JSONObject();
    //properties.setString("actual", cachePath);
    //properties.setInt("checksum", calculateChecksum(img));
    //properties.setString("lastModified", "");
    //properties.setInt("size", 0);
    //cacheInfoJSON.setJSONObject(originalPath, properties);


    return img;
  }

  public String generateCachePath(String ext) {
    String extt = "";
    if (ext.length() > 0) {
      extt = "."+ext;
    }
    // Get a unique idenfifier for the file
    String cachePath = CACHE_PATH+"cache-"+str(int(random(0, 2147483646)))+extt;
    while (file.exists(cachePath)) {
      cachePath = CACHE_PATH+"cache-"+str(int(random(0, 2147483646)))+extt;
    }
    return cachePath;
  }
  
  private float noise_seed = random(0, 189456790123485.);
  private float noise_octave = 2.;
  private float noise_falloff = 0.5;
  
  public float noise(float x, float y) {
    //4420.0825
    //32760.305
    //519930
    
    if (lowMemory) return app.noise(x, y);
    
    long k = (long)(x*4420.0825) + (long)(y*32760.305)*519930 + (long)noise_octave*1048576 + (long)(noise_falloff*1048576.) + (long)noise_seed;
    Float val = noiseCache.get(k);
    if (val == null) {
      float newval = app.noise(x, y);
      
      if (noiseCache.size() > 50000) {
        // Just to be memory-safe.
        noiseCache.clear();
      }
      
      noiseCache.put(k, newval);
      return newval;
    }
    else {
      return (float)val;
    }
  }
  
  public float noise(float x) {
    return this.noise(x, 0);
  }
  
  public void noiseSeed(int seed) {
    noise_seed = (float)seed;
    app.noiseSeed(seed);
  }

  public void noiseDetail(int octave, float fall) {
    noise_octave = (float)octave;
    noise_falloff = fall;
    app.noiseDetail(octave, fall);
  }



  private PImage originalImage = null;
  private SoundFile originalSound = null;
  public void setOriginalImage(PImage image) {
    if (image == null) console.bugWarn("setOriginalImage: the image you provided is null! Is your runnable load code working??");
    originalImage = image;
  }
  public void setOriginalSound(SoundFile sound) {
    if (sound == null) console.bugWarn("setOriginalSound: the sound you provided is null! Is your runnable load code working??");
    originalSound = sound;
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class InputModule {
    
    // Mouse & keyboard
    public boolean primaryOnce = false;
    public boolean secondaryOnce = false;
    public boolean primaryDown = false;
    public boolean secondaryDown = false;
    public boolean primaryReleased = false;
    public boolean secondaryReleased = false;
    public boolean keyOnce = false;
    public boolean keyDown = false;
    
    public int cursorX = 0;
    public String CURSOR_CHAR = "";
    
    public boolean mouseMoved = false;
    
    public float   rawScroll = 0;
    public float   scroll = 0;
    public float   scrollSensitivity = 30.0;
    
    public String keyboardMessage = "";
    public boolean addNewlineWhenEnterPressed = true;
    
    // used for one-time click
    private boolean click = false;
    private boolean eventClick = false;   // This is used sort of as a backup click as a solution to the problem where the user clicks in quick succession, but there aren't enough frames inbetween.
    private float normalClickTimeout = 0.;
    private float keyHoldCounter = 0;
    private float clickStartX = 0;
    private float clickStartY = 0;
    private char lastKeyPressed = 0;
    private int lastKeycodePressed = 0;
    private float holdKeyFrames = 0.;
    
    private float cache_mouseX = 0.0;
    private float cache_mouseY = 0.0;
    public  float scrollOffset = 0.0;
    private float blinkTime = 0.0;
    
    public int keys[]       = new int[1024];
    private int robotKeys[] = new int[1024];
    
    // Down
    public boolean backspaceDown = false;
    public boolean shiftDown = false;
    public boolean ctrlDown = false;
    public boolean altDown  = false;
    public boolean altgrDown  = false;
    public boolean enterDown = false;
    public boolean leftDown = false;
    public boolean rightDown = false;
    public boolean upDown = false;
    public boolean downDown = false;
    
    // Down counters
    private int backspaceDownCounter = 0;
    private int shiftDownCounter = 0;
    private int ctrlDownCounter = 0;
    private int altDownCounter  = 0;
    private int altgrDownCounter  = 0;
    private int enterDownCounter = 0;
    private int leftDownCounter = 0;
    private int rightDownCounter = 0;
    private int upDownCounter = 0;
    private int downDownCounter = 0;
    
    // Once
    public boolean backspaceOnce = false;
    public boolean shiftOnce = false;
    public boolean ctrlOnce = false;
    public boolean altOnce  = false;
    public boolean altgrOnce  = false;
    public boolean enterOnce = false;
    public boolean leftOnce = false;
    public boolean rightOnce = false;
    public boolean upOnce = false;
    public boolean downOnce = false;
    
    public static final char LEFT_CLICK = 1;
    public static final char RIGHT_CLICK = 2;
    public static final char SHIFT_KEY = 3;
    public static final char CTRL_KEY = 4;
    public static final char ALT_KEY = 5;
    public static final char ALTGR_KEY = 6;
    
    
    public InputModule() {
      scrollSensitivity = settings.getFloat("scroll_sensitivity", 20f);
      CURSOR_CHAR = settings.getString("text_cursor_char", "_");
    }
    
      
    public void runInputManagement() {
      //*************MOUSE MOVEMENT*************
      cache_mouseX = app.mouseX/display.getScale();
      cache_mouseY = app.mouseY/display.getScale();
      
      
      
      //*************MOUSE CLICKING*************
      // "Shouldn't it be (app.mouseButton == LEFT)?"
      // One word. MacOS.
      primaryDown = app.mousePressed && (app.mouseButton != RIGHT);
      secondaryDown = (app.mousePressed &&  (app.mouseButton == RIGHT));
      
      // If the mouse begins click on the frame, this will be later updated to true.
      // Then next frame this will be set to false, and because of the one-click code,
      // this will not be updated at all hence remaining false.
      primaryOnce = false;
      secondaryOnce = false;
      primaryReleased = false;
      secondaryReleased = false;
      keyOnce = false;
      
      normalClickTimeout -= display.getDelta();
  
      // Here, we use either our default click method or we use the "void mouseClicked" method to
      // mitigate the cases where the mouse is clicked rapidly but not released fast enough for the click variable to be set to false.
      // In order to stop double-click bugs (where we click once but it registers twice because of click and eventClick firing on slightly different frames),
      // we need to introduce a small timeout for event clicks which are always a few frames later.
      if ((app.mousePressed && !click) || (eventClick)) {
        click = true;
        
        // While normal click might not be able to register a mouseup for a few frames, rely on the event click
        // in case user rapidly clicks.
        if (!eventClick)
          normalClickTimeout = 15.;
        eventClick = false;
        
        primaryOnce = (app.mouseButton != RIGHT);
        
        secondaryOnce = (app.mouseButton == RIGHT);
        
        mouseMoved = false;
        clickStartX = mouseX();
        clickStartY = mouseY();
      }
      else if (!app.mousePressed && click) {
        click = false;
        primaryReleased = (app.mouseButton != RIGHT);
        secondaryReleased = (app.mouseButton == RIGHT);
        
        if (clickStartX != mouseX() || clickStartY != mouseY()) {
          mouseMoved = true;
        }
      }
  
  
      //*************KEYBOARD*************
      
      // Oneshot key control
      for (int i = 0; i < 1024; i++) {
        if (keys[i] > 0) {
          // If at least one of them is pressed, keyOnce is true
          if (keys[i] == 1) {
            keyOnce = true;
          }
          keys[i]++;
        }
        if (robotKeys[i] > 0) {
          robotKeys[i]++;
          if (robotKeys[i] > 4) {
            keys[i] = 0;
            robotKeys[i] = 0;
          }
        }
      }
      
      // Special keys oneshots
      if (backspaceDown) backspaceDownCounter++; else backspaceDownCounter = 0; 
      if (shiftDown) shiftDownCounter++; else shiftDownCounter = 0;
      if (ctrlDown) ctrlDownCounter++; else ctrlDownCounter = 0;
      if (altDown) altDownCounter++; else altDownCounter = 0;
      if (altgrDown) altgrDownCounter++; else altgrDownCounter = 0;
      if (enterDown) enterDownCounter++; else enterDownCounter = 0;
      if (leftDown) leftDownCounter++; else leftDownCounter = 0;
      if (rightDown) rightDownCounter++; else rightDownCounter = 0;
      if (upDown) upDownCounter++; else upDownCounter = 0;
      if (downDown) downDownCounter++; else downDownCounter = 0;
      
      
      backspaceOnce = (backspaceDownCounter == 1);
      shiftOnce = (shiftDownCounter == 1);
      ctrlOnce = (ctrlDownCounter == 1);
      altOnce = (altDownCounter == 1);
      altgrOnce = (altgrDownCounter == 1);
      enterOnce = (enterDownCounter == 1);
      leftOnce = (leftDownCounter == 1);
      rightOnce = (rightDownCounter == 1);
      upOnce = (upDownCounter == 1);
      downOnce = (downDownCounter == 1);
      
      // Holding counter (for repeating held keys)
      if (keyHoldCounter >= 1.) {
        keyHoldCounter += display.getDelta();
      }
      // The code that actually repeats the held key.
      if (keyHoldCounter > KEY_HOLD_TIME) {
        power.setAwake();
        // good fix for bad framerates.
        // However we want smooth framerates so we set it to awake mode so this
        // code barely matters oop.
        for (int i = int(holdKeyFrames*0.5); i >= 2; i--) {
          keyboardAction(lastKeyPressed, lastKeycodePressed);
          holdKeyFrames -= 2;
        }
        holdKeyFrames += display.getDelta();
      }
      
      
      // ************TYPING*******************
      boolean solidifyBlink = true;
      
      if (leftOnce) { 
        cursorX--;
        if (ctrlDown) {
          boolean traversed = false;
          while (ctrlTraversable()) {
            cursorX--;
            traversed = true;
          }
          if (traversed) cursorX++;
        }
      }
      else if (rightOnce) {
        cursorX++;
        if (ctrlDown) {
          while (ctrlTraversable()) {
            cursorX++;
          }
        }
      }
      else if (upOnce) { 
        // Start of current line
        int startOfCurrLine = keyboardMessage.lastIndexOf('\n', cursorX)+1;
        int dist = cursorX-startOfCurrLine;
        
        // start of prev line
        int startOfPrevLine = keyboardMessage.lastIndexOf('\n', startOfCurrLine-2)+1;
        
        // Let's say for example you move your cursor like this:
        //
        // short
        // A longer mess|ge hello world
        // 
        // short|
        // A longer message hello world
        //
        // As you can see, "short" is not long enough to plonk the cursor into the new position,
        // so it gets put at the start.
        if (startOfCurrLine-startOfPrevLine < dist) {
          cursorX = startOfCurrLine-1;
        }
        else {
          cursorX = startOfPrevLine+dist;
        }
      }
      else if (downOnce) { 
        // Start of current line
        int startOfThisLine = keyboardMessage.lastIndexOf('\n', cursorX-1)+1;
        int startOfNextLine = keyboardMessage.indexOf('\n', cursorX)+1;
        if (startOfNextLine != 0) {
          int dist = cursorX-startOfThisLine;
          cursorX = startOfNextLine+dist;
        }
      }
      else if (keyOnce) {}
      else solidifyBlink = false;
      
      if (solidifyBlink) {
        blinkTime = 0.0;
      }
      cursorX = max(min(cursorX, keyboardMessage.length()), 0);
    
      blinkTime += display.getDelta();
    
      
  
      //*************MOUSE WHEEL*************
      if (rawScroll != 0) {
        scroll = rawScroll*-scrollSensitivity;
      } else {
        scroll *= 0.5;
      }
      rawScroll = 0.;
    }
    
    
    public void prepareTyping() {
      keyboardMessage = "";
      cursorX = 0;
    }
    
    private boolean ctrlTraversable() {
      if (cursorX >= keyboardMessage.length()-1 || cursorX <= 0 ) return false;
      char c = keyboardMessage.charAt(cursorX);
      return c != ' '
          && c != '\n'
          && c != '('
          && c != ')'
          && c != '{'
          && c != '}'
          && c != '['
          && c != ']';
    }
    
    public char getLastKeyPressed() {
      return lastKeyPressed;
    }
  
    // To be called by base sketch code.
    public void releaseKeyboardAction(char kkey, int kkeyCode) {
      // Special keys
      if (kkey == CODED) {
        switch (kkeyCode) {
        case CONTROL:
          ctrlDown = false;
          break;
        case SHIFT:
          shiftDown = false;
          break;
        case ALT:
          altDown = false;
          break;
        case 19:  // ALT GR
          altgrDown = false;
          break;
        case LEFT:
          leftDown = false;
          break;
        case RIGHT:
          rightDown = false;
          break;
        case UP:
          upDown = false;
          break;
        case DOWN:
          downDown = false;
          break;
        // For android
        case 67:
          backspaceDown = false;
          break;
        }
      }
      else if (kkey == BACKSPACE || kkey == RETURN) {
        backspaceDown = false;
      }
      else if (kkey == ENTER || kkey == RETURN || int(kkey) == 10) {
        enterDown = false;
      }
      // Down keys
      char actualKey = kkey;
      if (shiftDown) {
        actualKey = char(kkeyCode);
      }
      int val = int(Character.toLowerCase(actualKey));
      
      if (val >= 1024) return;
      
      keys[val] = 0;
    }
    
    public String keyboardMessageDisplay(String code) {
      if (int(blinkTime) % 60 < 30) {
        // Blinking cursor replaces the current character with █
        // But we do NOT want it to replace \n since this will remove the newline and make
        // the text all wonky.
        // Also ignore all the min(), I don't want to get a StringIndexOutOfBoundsException.
        int l = code.length();
        if (l == 0) return CURSOR_CHAR;
        
        
        if (code.charAt(min(cursorX, l-1)) == '\n') {
          return code.substring(0, min(cursorX, l))+CURSOR_CHAR+code.substring(min(cursorX, l-1));
        }
        else {
          return code.substring(0, min(cursorX, l))+CURSOR_CHAR+code.substring(min(cursorX+1, l));
        }
      }
      return code;
    }
    
    public String keyboardMessageDisplay() {
      return keyboardMessageDisplay(keyboardMessage);
    }
  
    public boolean keyDown(char k) {
      if (inputPromptShown) return false;
      
      int val = int(Character.toLowerCase(k));
      return keys[val] >= 1;
    }
    
    public boolean keyDownOnce(char k) {
      if (inputPromptShown) return false;
      
      int val = int(Character.toLowerCase(k));
      
      //if (keys[val] > 0) {
      //  console.log(val);
      //}
      
      return keys[val] == 2;
    }
    
  
    public boolean keyAction(String keybindName, char defaultKey) {
      char k = settings.getKeybinding(keybindName, defaultKey);
      
      // Special keys/buttons
      if (k == LEFT_CLICK)
        return this.primaryDown;
      else if (k == RIGHT_CLICK)
        return this.secondaryDown;
      else if (k == SHIFT_KEY)
        return this.shiftDown;
      else if (k == CTRL_KEY)
        return this.ctrlDown;
      else if (k == ALT_KEY)
        return this.altDown;
      else if (k == ALTGR_KEY)
        return this.altgrDown;
      else 
        // Otherwise just tell us if the key is down or not
        return keyDown(k);
    }
    
    public void setAction(String keybindName, char defaultKey) {
      char k = settings.getKeybinding(keybindName, defaultKey);
      int val = int(Character.toLowerCase(k));
      keys[val] = 1;
      robotKeys[val] = 1;
    }
  
    public boolean keyActionOnce(String keybindName, char defaultKey) {
      char k = settings.getKeybinding(keybindName, defaultKey);
      
      // Special keys/buttons
      if (k == LEFT_CLICK)
        return this.primaryOnce;
      else if (k == RIGHT_CLICK)
        return this.secondaryOnce;
      else if (k == SHIFT_KEY)
        return this.shiftOnce;
      else if (k == ALTGR_KEY)
        return this.altgrOnce;
      else if (k == ALT_KEY)
        return this.altOnce;
      else if (k == CTRL_KEY)
        return this.ctrlOnce;
      else {
        // Otherwise just tell us if the key is down or not
        return keyDownOnce(k);
      }
    }
  
    public void backspace() {
      if (this.keyboardMessage.length() > 0 && cursorX > 0)  {
        this.keyboardMessage = keyboardMessage.substring(0, cursorX-1)+keyboardMessage.substring(cursorX);
        cursorX--;
      }
    }
    
    public float mouseX() {
      return cache_mouseX;
    }
  
    public float mouseY() {
      return cache_mouseY;
    }
    
    
    public String keyTextForm(char c) {
      String text;
      switch (c) {
        case ' ':
        text = "Space";
        break;
        case '\t':
        text = "Tab";
        break;
        case '\n':
        if (isMacOS()) {
          text = "Return";
        }
        else {
          text = "Enter";
        }
        break;
        case '\b':
        text = "Backspace";
        break;
        case LEFT_CLICK:
        text = "Left click";
        break;
        case RIGHT_CLICK:
        text = "Left click";
        break;
        case SHIFT_KEY:
        text = "Shift";
        break;
        case 127:
        text = "Delete";
        break;
        case ALT_KEY:
        text = "Alt";
        break;
        case ALTGR_KEY:
        text = "Alt Gr";
        break;
        case CTRL_KEY:
        text = "Ctrl";
        break;
        
        // TODO: This assumes user has a QWERTY keyboard.
        case '.':
        text = ">";
        break;
        case ',':
        text = "<";
        break;
        case '\'':
        text = "@";
        break;
        case '=':
        text = "+";
        break;
        default:
        text = ""+Character.toUpperCase(c);
        break;
      }
      
      return text;
    }
  
    
    // TODO: This is old code. Need I say more?
    // It's also broken af.
    public void processScroll(float top, float bottom) {
      final float ELASTIC_MAX = 100.;
      
      if (scroll != 0.0) {
        power.setAwake();
      }
      else {
        power.setSleepy();
      }
      
      int n = 1;
      switch (power.getPowerMode()) {
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
      
      // Sorry not sorry
      for (int i = 0; i < n; i++) {
        if (scrollOffset > top) {
            scrollOffset -= (scrollOffset-top)*0.1;
            if (input.scroll < 0.0) scrollOffset += input.scroll;
            else scrollOffset += input.scroll*(max(0.0, ((ELASTIC_MAX+top)-scrollOffset)/ELASTIC_MAX));
        }
        else if (-scrollOffset > bottom) {
            // TODO: Actually get some pen and paper and make the elastic band edge work.
            // This is just a placeholder so that it's usable.
            scrollOffset = -bottom;
          
            //scrollOffset += (bottom-scrollOffset)*0.1;
            //if (engine.scroll > 0.0) scrollOffset += engine.scroll;
            //else scrollOffset += engine.scroll*(max(0.0, ((-scrollOffset)-(ELASTIC_MAX+bottom))/ELASTIC_MAX));
        }
        else scrollOffset += input.scroll;
      }
    }
      
    
    public void clickEventAction() {
      // We don't want to trigger a click if the normal clicking system receives a click.
      if (normalClickTimeout < 0.) {
        eventClick = true;
      }
    }
    
    public void releaseAllInput() {
      for (int i = 0; i < 1024; i++) {
        keys[i] = 0;
      }
      primaryOnce = false;
      secondaryOnce = false;
      primaryDown = false;
      secondaryDown = false;
      click = false;
      eventClick = false;
      keyHoldCounter = 0.;
    }
    
    public void keyboardAction(char kkey, int kkeyCode) {
      lastKeyPressed     = kkey;
      lastKeycodePressed = kkeyCode;
      
      if (kkey == CODED) {
        switch (kkeyCode) {
          case CONTROL:
            ctrlDown = true;
            lastKeyPressed = CTRL_KEY;
            return;
          case SHIFT:
            shiftDown = true;
            lastKeyPressed = SHIFT_KEY;
            break;
          case ALT:
            altDown = true;
            lastKeyPressed = ALT_KEY;
            return;
          case 19:      // ALT GR  
            altgrDown = true;
            lastKeyPressed = ALTGR_KEY;
            return;
          case LEFT:
            leftDownCounter = 0;
            leftDown = true;
            break;
          case RIGHT:
            rightDownCounter = 0;
            rightDown = true;
            break;
          case UP:
            upDownCounter = 0;
            upDown = true;
            break;
          case DOWN:
            downDownCounter = 0;
            downDown = true;
            break;
          case 67:
            this.backspace();
            backspaceDown = true;
            return;
        }
        // 10 for android
      } else if (kkey == ENTER || kkey == RETURN || int(kkey) == 10) {
        if (this.addNewlineWhenEnterPressed) {
          insert('\n');
        }
        enterDown = true;
        // 65535 67 for android
      } else if (kkey == BACKSPACE) {    // Backspace
        this.backspace();
        backspaceDown = true;
      }
      else {
        insert(kkey);
      }
      
      // And actually set the current pressed key state
      char actualKey = kkey;
      if (shiftDown) {
        actualKey = char(kkeyCode);
      }
      int val = int(Character.toLowerCase(actualKey));
      
      if (val >= 1024) return;
      if (keys[val] > 0) return;
      keys[val] = 1;
      stats.increase("keys_pressed", 1);
    }
  
    public void insert(char c) {
      // Remember, we now have a cursor.
      // If we're typing at the end, simply append char (like normal)
      if (cursorX == keyboardMessage.length()) {
        keyboardMessage += c;
      }
      // Otherwise, add the char in between the text.
      else {
        this.keyboardMessage = keyboardMessage.substring(0, cursorX) + c + keyboardMessage.substring(cursorX);
      }
      cursorX++;
    }
  }
  // Cus why replace 9999999 lines of code when you can write 6 new lines of code that makes sure everything still works.
  public float mouseX() {
    return input.mouseX();
  }
  public float mouseY() {
    return input.mouseY();
  }





  
  
  public class ClipboardModule {
    private Object cachedClipboardObject;
    
    public boolean isImage() {
      if (cachedClipboardObject == null) cachedClipboardObject = getPImageFromClipboard();
      
      // If still false, is nothing so isn't an image.
      if (cachedClipboardObject == null) return false;
      return (cachedClipboardObject instanceof PImage);
    }
  
    public String getText()
    {
      if (cachedClipboardObject == null) cachedClipboardObject = getFromClipboardStringFlavour();
      String text = (String) cachedClipboardObject;
      cachedClipboardObject = null;
      return text;
    }
    
    public boolean isString() {
      if (cachedClipboardObject == null) cachedClipboardObject = getFromClipboardStringFlavour();
      
      // If still false, is nothing so isn't an image.
      if (cachedClipboardObject == null) return false;
      return (cachedClipboardObject instanceof String);
    }
  
    public PImage getImage() {
      if (!isImage()) {
        console.bugWarn("getImage: clipboard doesn't contain an image, make sure to check first with isImage()!");
        return display.getImg("white");
      }
      
      PImage ret = (PImage)cachedClipboardObject;
      cachedClipboardObject = null;
      return ret;
    }
    
    // Returns true if successful, false if not
    public boolean copyString(String str) {
      String myString = str;
      try {
        copyStringToClipboard(myString);
      }
      catch (RuntimeException e) {
        console.warn(e.getMessage());
        console.warn("Couldn't copy text to clipboard: ");
        return false;
      }
      return true;
    }
  
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  private long gcPanicCooldown = 1;
  
  public Screen getPrevScreen() {
    if (screenStack.isEmpty()) {
      //console.bugWarn("No more prev screens.");
      return dummyScreen;
    }
    return screenStack.peek(0);
  }

  public void processCaching() {
    if (cacheInfoTimeout > 0) {
      cacheInfoTimeout--;
      if (cacheInfoTimeout == 0) {
        saveCacheInfoNow();
      }
    }
  }
  
  private long usedMemValues[] = new long[400];;
  private int usedMemValuesIndex = 0;
  private boolean showMemUsage = false;
  private long[] heapFillRateValues = new long[30];
  private long lastUsedMemSize = 0;
  private long heapFillDisplayKB = 0;
  private long minimumMem = 0;
  private long totalToKeepTrackOfMinimumMem = 0;
  
  public void memUsage() {
    long used = (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory());
    long total = Runtime.getRuntime().totalMemory();
    
    
    if (showMemUsage) {
      app.pushMatrix();
      app.scale(display.getScale());
      
      
      app.noStroke();
      
      float y = 20f;
      float hi = 100f;
      float wi = (display.WIDTH-200f);
      
      // Bar
      app.fill(0, 0, 0, 127);
      app.rect(100f, y, wi, hi);
      
      // Line graph
      app.fill(255, 150);
      int l = usedMemValues.length;
      float xpw = wi / (float)l;
      for (int i = 0; i < l-1; i++) {
        float xp1 = 100f + ((float)i / (float)l) * wi;
        float yp2 = min((((float)usedMemValues[(usedMemValuesIndex+i)%l] / (float)total)) * hi, hi);
        rect(xp1, y+hi-yp2, xpw, yp2);
        
        // Lil red indicator bar
        if (i == l-2) {
          rect(xp1+xpw, y+hi-yp2, xpw, yp2);
          fill(255, 0, 0);
          rect(100f+wi-70f, y+hi-yp2-4f, 70f, 4f); 
        }
      }
      
      // Overall memory usage
      app.fill(0);
      app.textFont(DEFAULT_FONT, 30);
      app.textAlign(LEFT, CENTER);
      app.text("Mem: "+(used/1024L)+"KB / "+(total/1024)+"KB ("+(used/1048576L)+"MB / "+(total/1048576L)+"MB)", 106, y+26);
      app.fill(255);
      app.text("Mem: "+(used/1024L)+"KB / "+(total/1024)+"KB ("+(used/1048576L)+"MB / "+(total/1048576L)+"MB)", 104, y+24);
      
      // Heap fill rate
      // Calculate average first
      if (app.frameCount % 7 == 0) {
        long sum = 0;
        for (int i = 0; i < heapFillRateValues.length; i++) {
          sum += heapFillRateValues[i];
        }
        long avg = sum / (long)heapFillRateValues.length;
        
        heapFillDisplayKB = avg;
      }
      
      // Indicator of low lowMemory mode
      if (lowMemory) {
        app.textAlign(RIGHT, CENTER);
        app.textFont(DEFAULT_FONT, 22);
        app.fill(0);
        app.text("Low memory mode enabled", wi, y+26);
        app.fill(255, 100, 100);
        app.text("Low memory mode enabled", wi, y+24);
        app.textAlign(LEFT, CENTER);
      }
      
      // Display heap fill rate
      app.textFont(DEFAULT_FONT, 20);
      app.fill(0);
      app.text("Heap fill rate: "+(heapFillDisplayKB/1024L)+"KB/frame", 106, y+52);
      app.fill(255);
      app.text("Heap fill rate: "+(heapFillDisplayKB/1024L)+"KB/frame", 104, y+50);
      
      // Display minimum memory
      app.fill(0);
      app.text("Min required mem: "+(minimumMem/1048576L)+"MB", 106, y+70);
      app.fill(255);
      app.text("Min required mem: "+(minimumMem/1048576L)+"MB", 104, y+68);
      
      app.textFont(DEFAULT_FONT, 12);
      app.fill(0);
      app.text("Use the /gc command to refresh min required memory.", 106, y+90);
      app.fill(255);
      app.text("Use the /gc command to refresh min required memory.", 104, y+88);
      
      app.popMatrix();
    }
    
    // Used mem array
    usedMemValues[usedMemValuesIndex] = used;
    usedMemValuesIndex++;
    if (usedMemValuesIndex >= usedMemValues.length) usedMemValuesIndex = 0;
    
    // Memory heap fill rate
    heapFillRateValues[app.frameCount % heapFillRateValues.length] = used-lastUsedMemSize < 0 ? 0 : used-lastUsedMemSize;
    lastUsedMemSize = used;
    
    // Minimum memory
    if (totalToKeepTrackOfMinimumMem != total) {
      minimumMem = used;
      totalToKeepTrackOfMinimumMem = total;
    }
  }
  
  public void saveCacheInfoNow() {
    if (cacheInfoJSON != null) {
      console.info("processCaching: saving cache info.");
      saveJSONObject(cacheInfoJSON, CACHE_PATH+CACHE_INFO());
      cacheInfoTimeout = 0;
      stats.increase("total_cache_info_saves", 1);
    }
  }
  
  public void shutdown() {
    stats.save();
    stats.set("last_closed", (int)(System.currentTimeMillis() / 1000L));
    settings.forceSaveSettings();
  }

  
  // TODO: Move requestScreen from Screen class to engine.
  public void requestScreen(Screen screen) {
    if (currScreen != null) {
      currScreen.requestScreen(screen);
    }
  }
  
  public void previousScreen() {
    if (currScreen != null) currScreen.previousScreen();
  }

  // The core engine function which essentially runs EVERYTHING in Timeway.
  // All the screens, all the input management, and everything else.
  public void engine() {
    if (display != null) display.resetTimes();
    if (display != null) display.recordLogicTime();
    // Run benchmark if it's active.
    runBenchmark();
    
    display.WIDTH = width/display.displayScale;
    display.HEIGHT = height/display.displayScale;

    power.updatePowerMode();

    processCaching();
    settings.update();

    // Truly an awful piece of code.
    //if ((int)app.frameCount % 2000 == 0) {
    //  stats.save();
    //}

    app.background(0);

    // Update inputs
    input.runInputManagement();
    
    // Get updates
    //processUpdate();

    // Show the current GUI.
    display.displayScreens();
    
    sound.processSound();
    
    // Dumb code
    if (ui.dummySpriteSystem == null) ui.dummySpriteSystem = new SpriteSystemPlaceholder(this);
    ui.display();
    
    if (showMemUsage) {
      memUsage();
    }
    
    if (lowMemory) {
      // If the memory is past its 512mb limit, call the garbage collector. Get that mem usage down.
      // If there's no effect, slow down the number of times we call gc() so that we don't lag the system to a crawl.
      if (Runtime.getRuntime().totalMemory() > 536870912l) {
        if ((long)app.frameCount % gcPanicCooldown == 0l) {
          System.gc();
          gcPanicCooldown *= 2l;
        }
      }
      else {
        gcPanicCooldown = 1l;
      }
    }
    
    // If Timeway is updating, a little notice and progress
    // bar will appear in front of the screen.
    runUpdate();


    // Allow command prompt to be shown.
    if (input.keyActionOnce("command_prompt", '/') && allowShowCommandPrompt)
      showCommandPrompt();


    if (commandPromptShown) {
      // Display the command prompt if shown.
      app.pushMatrix();
      app.scale(display.getScale());
      noStroke();
      app.fill(0, 127);
      app.noStroke();
      float promptWi = 600;
      float promptHi = 250;
      app.rect(display.WIDTH/2-promptWi/2, display.HEIGHT/2-promptHi/2, promptWi, promptHi);
      displayInputPrompt();
      app.noFill();
      app.popMatrix();
    }

    counter += display.getDelta();
    // Update times so we can calculate live fps.
    display.update();
    if (display.showCPUBenchmarks) display.showBenchmarks();
    
    if (display.showFPS()) {
      pushMatrix();
      app.scale(display.getScale());
      app.textFont(DEFAULT_FONT, 32);
      app.textAlign(LEFT, TOP);
      float y = 5;
      if (currScreen != null) y = currScreen.myUpperBarWeight+5;
      
      String txt = str(round(frameRate))+"\n"+power.getPowerModeString();
      
      app.fill(0);
      app.text(txt, 5, y);
      app.fill(255);
      app.text(txt, 7, y+2);
      app.popMatrix();
    }

    // Display console
    // TODO: this renders the console 4 times which is BAD.
    // We need to make the animation execute 4 times, not the drawing routines.
    console.display(true);
    
    display.resetTimes();
    
    if (display != null) display.timeMode = display.IDLE_TIME;
    
    stats.recordTime("total_time_in_timeway");
    stats.increase("total_frames_timeway", 1);
    
    display.forceDelta(-1f);
  }
  
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

  protected final int NONE = 0;
  protected final int START = 1;
  protected final int END = 2;

  protected PApplet app;
  protected TWEngine engine;
  protected TWEngine.Console console;
  protected TWEngine.SharedResourcesModule sharedResources;
  protected TWEngine.SettingsModule settings;
  protected TWEngine.InputModule input;
  protected TWEngine.DisplayModule display;
  protected TWEngine.PowerModeModule power;
  protected TWEngine.AudioModule sound;
  protected TWEngine.FilemanagerModule file;
  protected TWEngine.StatsModule stats;
  protected TWEngine.ClipboardModule clipboard;
  protected TWEngine.UIModule ui;
  protected TWEngine.PluginModule plugins;
  protected TWEngine.IndexerModule indexer;
  
  protected float screenx = 0;
  protected float screeny = 0;
  protected color myUpperBarColor = UPPER_BAR_DEFAULT_COLOR;
  protected color myLowerBarColor = LOWER_BAR_DEFAULT_COLOR;
  protected color myBackgroundColor = DEFAULT_BACKGROUND_COLOR;
  protected float myUpperBarWeight = UPPER_BAR_WEIGHT;
  protected float myLowerBarWeight = LOWER_BAR_WEIGHT;
  
  protected float WIDTH = 0.;
  protected float HEIGHT = 0.;

  public Screen(TWEngine engine) {
    this.engine = engine;
    this.console = engine.console;
    this.app = engine.app;
    
    this.sharedResources = engine.sharedResources;
    this.settings = engine.settings;
    this.input = engine.input;
    this.display = engine.display;
    this.ui = engine.ui;
    this.power = engine.power;
    this.sound = engine.sound;
    this.file = engine.file;
    this.clipboard = engine.clipboard;
    this.stats = engine.stats;
    this.plugins = engine.plugins;
    this.indexer = engine.indexer;
    
    this.WIDTH = engine.display.WIDTH;
    this.HEIGHT = engine.display.HEIGHT;
  }

  protected void upperBar() {
    display.recordRendererTime();
    app.fill(myUpperBarColor);
    app.noStroke();
    app.rect(0, 0, WIDTH, myUpperBarWeight);
    display.recordLogicTime();
  }

  protected void lowerBar() {
    display.recordRendererTime();
    app.fill(myLowerBarColor);
    app.noStroke();
    app.rect(0, HEIGHT-myLowerBarWeight, WIDTH, myLowerBarWeight);
    display.recordLogicTime();
  }

  protected void backg() {
    display.recordRendererTime();
    app.fill(myBackgroundColor);
    app.noStroke();
    app.rect(0, myUpperBarWeight, WIDTH, HEIGHT-myUpperBarWeight-myLowerBarWeight);
    display.recordLogicTime();
  }
  
  // Run code here you want to run in the background during MINIMAL mode.
  protected void runMinimal() {
    
  }

  public void startupAnimation() {
  }

  protected void startScreenTransition() {
    engine.transitionScreens = true;
    engine.transition = 1.0;
    // right after calling startScreenTransition().
  }
  
  protected boolean focused() {
    return (engine.currScreen == this);
  }

  protected void endScreenAnimation() {
  }

  protected void previousReturnAnimation() {
  }

  private void printStack() {
    for (int i = 0; i < engine.screenStack.size(); i++) {
      console.log(engine.screenStack.peek(i).getClass().getSimpleName());
    }
    console.log("------------------");
  }

  protected void requestScreen(Screen screen) {
    if (engine.currScreen == this && engine.transitionScreens == false) {
      engine.screenStack.push(this);
      engine.currScreen = screen;
      screen.startScreenTransition();
      engine.power.resetFPSSystem();
      engine.allowShowCommandPrompt = true;
      engine.transitionDirection = RIGHT;
      //engine.setAwake();
    }
    //printStack();
  }

  protected void previousScreen() {
    if (this.engine.screenStack.isEmpty()) engine.console.bugWarn("No previous screen to go back to!");
    else {
      engine.getPrevScreen().previousReturnAnimation();
      
      // Request screen but without stack pushing
      Screen prevScreen = this.engine.screenStack.pop();
      if (engine.currScreen == this && engine.transitionScreens == false) {
        engine.prevScreenTransition = engine.currScreen;
        engine.currScreen = prevScreen;
        prevScreen.startScreenTransition();
        engine.power.resetFPSSystem();
        engine.allowShowCommandPrompt = true;
        //engine.setAwake();
      }
      
      engine.transitionDirection = LEFT;
      engine.power.setAwake();
    }
    //printStack();
  }


  // A method where you can add your own custom commands.
  // Must return true if a command is found and false if a command
  // is not found.
  @SuppressWarnings("unused")
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
    this.WIDTH = engine.display.WIDTH;
    this.HEIGHT = engine.display.HEIGHT;
    if (power.powerMode != PowerMode.MINIMAL) {
      app.pushMatrix();
      //float scl = display.getScale();
      app.translate(screenx, screeny);
      app.scale(display.getScale());
      this.backg();
      this.content();
      this.upperBar();
      this.lowerBar();
      
      // Show the minimenu if any.
      
      app.popMatrix();
    }
    else {
      this.runMinimal();
    }
  }
}


// Sometimes, problems can occure.
// Better to have something than let the application completely crash.
// So we use this dummy screen when we try to access a screen that does not exist.
// This screen literally does nothing.
public class DummyScreen extends Screen {
  public DummyScreen(TWEngine engine) {
    super(engine);
  }
}






















//*********************Sprite Class****************************
// Now yes, I am aware that the code is a mess and there are many
// features inside of this class that go unused. This was ripped
// straight from SketchiePad. This is mainly placeholder code as
// to be able to have click+draggable objects.
// Its functionalities:
// 1. Create sprites simply by calling the sprite() method
// 2. Click and drag objects
// 3. Resize objects
// 4. Save the position of objects between closing and starting again
// 5. Move objects with code, but still allow the position to be updated when clicked+dragged.
public final class SpriteSystemPlaceholder {
        public HashMap<String, Integer> spriteNames;
        public ArrayList<Sprite> sprites;
        public Sprite selectedSprite;
        public Stack<Sprite> spritesStack;
        private int newSpriteX = 0, newSpriteY = 0, newSpriteZ = 0;
        public Sprite unusedSprite;
        public TWEngine engine;
        public PApplet app;
        public TWEngine.Console console;
        public boolean keyPressAllowed = true;
        public Click generalClick;
        public Stack<Sprite> selectedSprites;
        public String myPath;
        public boolean interactable = true;
        public boolean saveSpriteData = true;
        public boolean showAllWireframes = false;
        public boolean suppressSpriteWarning = false;
        public boolean repositionSpritesToScale = true;
        public boolean allowSelectOffContentPane = true;
        public float mouseScaleX = 1.0;
        public float mouseScaleY = 1.0;
        public float mouseOffsetX = 0.0;
        public float mouseOffsetY = 0.0;
        public float myDelta = 0.; 
        private boolean customDelta = false;
        private boolean mouseInputEnabled = true;

        public String PATH_SPRITES_ATTRIB;
        public String APPPATH; 

        public final int SINGLE = 1;
        public final int DOUBLE = 2;
        public final int VERTEX = 3;
        public final int ROTATE = 4;   
        
        public float selectBorderTime = 0.;
        
        private float mouseX() {
          return ((engine.mouseX()-mouseOffsetX)/mouseScaleX);
        }
        private float mouseY() {
          return ((engine.mouseY()-mouseOffsetY)/mouseScaleY);
        }
        
        private boolean mouseDown() {
          return engine.input.primaryDown && !engine.ui.miniMenuShown() && mouseInputEnabled;
        }
        
        public void setDelta(float del) {
          customDelta = true;
          myDelta = del;
        }

        // Use this constructor for no saving sprite data.
        public SpriteSystemPlaceholder(TWEngine engine) {
            this(engine, "");
            saveSpriteData = false;
        } 

        // Default constructor.
        public SpriteSystemPlaceholder(TWEngine engine, String path) {
            this.engine = engine;
            spriteNames = new HashMap<String, Integer>();
            selectedSprites = new Stack<Sprite>(256);
            sprites = new ArrayList<Sprite>();
            spritesStack = new Stack<Sprite>(32768);
            unusedSprite = new Sprite("UNUSED");
            generalClick = new Click();
            selectedSprite = null;
            app = engine.app;
            console = engine.console;
            PATH_SPRITES_ATTRIB = engine.PATH_SPRITES_ATTRIB();
            APPPATH = engine.APPPATH;
            this.myPath = path;
        }

        
        class Click {
            private boolean dragging = false;
            private int clickDelay = 0;
            private boolean click = false;
            private boolean draggingEnd = false;
            
            public boolean isDragging() {
                return dragging;
            }
            
            public void update() {
                draggingEnd = false;
                if (!mouseDown() && dragging) {
                dragging = false;
                draggingEnd = true;
                }
                if (clickDelay > 0) {
                clickDelay--;
                }
                if (!click && mouseDown()) {
                click = true;
                clickDelay = 1;
                }
                if (click && !mouseDown()) {
                click = false;
                }
            }
            
            public boolean draggingEnded() {
                return draggingEnd;
            }
            
            public void beginDrag() {
                if (mouseDown() && clickDelay > 0) {
                dragging = true;
                }
            }
            
            public boolean clicked() {
                return (clickDelay > 0);
            }
            
            
        }
        class QuadVertices {
            public PVector v[] = new PVector[4];
            
            {
            v[0] = new PVector(0,0);
            v[1] = new PVector(0,0);
            v[2] = new PVector(0,0);
            v[3] = new PVector(0,0);
            }
            
            public QuadVertices() {
            
            }
            public QuadVertices(float xStart1,float yStart1,float xStart2,float yStart2,float xEnd1,float yEnd1,float xEnd2,float yEnd2) {
            v[0].set(xStart1, yStart1);
            v[1].set(xStart2, yStart2);
            v[2].set(xEnd1,   yEnd1);
            v[3].set(xEnd2,   yEnd2);
            }
        }
        
        // Added implements RedrawElement so that we can use sprite with ERS
        class Sprite {

            public String imgName = "";
            public String name;
            
            public float xpos, ypos, zpos;
            public int wi = 0, hi = 0;
            
            public QuadVertices vertex;
 
            
            public float defxpos, defypos, defzpos;
            public int defwi = 0, defhi = 0;
            public QuadVertices defvertex;
            public float defrot = HALF_PI;
            public float defradius = 100.; //radiusY = 50.;
            
            public float offxpos, offypos;
            public int offwi = 0, offhi = 0;
            public QuadVertices offvertex;
            public float offrot = HALF_PI;
            public float offradius = 100.; //radiusY = 50.;
            
            public int spriteOrder;
            public boolean allowResizing = true;
            
            public float repositionDragStartX;
            public float repositionDragStartY;
            public QuadVertices repositionV;
            public float aspect;
            public Click resizeDrag;
            public Click repositionDrag;
            public Click select;
            public int currentVertex = 0;
            public boolean hoveringOverResizeSquare = false;
            public boolean lock = false;
            public int lastFrameShown = 0;
            public float bop = 0.0;
            public int mode = SINGLE;
            public float rot = HALF_PI;
            public float radius = 100.; //radiusY = 50.;
            
            public float BOX_SIZE = 50;
            
            
            
            //Scale modes:
            //1 - pixel width height (int)
            //2 - scale multiplier (float)

            public Sprite(String name) {
                xpos = 0;
                ypos = 0;
                this.name = name;
                vertex = new QuadVertices();
                offvertex = new QuadVertices();
                defvertex = new QuadVertices();
                repositionV = new QuadVertices();
                resizeDrag     = new Click();
                repositionDrag = new Click();
                select         = new Click();
            }
            
            public void setOrder(int order) {
                this.spriteOrder = order;
            }
            
            public int getOrder() {
                return spriteOrder;
            }

            public float getBop() {
                return bop;
            }

            public void bop() {
                bop = 0.2;
            }

            public void bop(float b) {
                bop = b;
            }

            public void resetBop() {
                bop = 0.0;
            }
            
            public String getModeString() {
                switch (mode) {
                case SINGLE: //SINGLE
                return "SINGLE";
                case DOUBLE: //DOUBLE
                return "DOUBLE";
                case VERTEX: //VERTEX
                return "VERTEX";
                case ROTATE: //ROTATE
                return "ROTATE";
                default:
                return "SINGLE";
                }
            }
            
            public void setMode(int m) {
                this.mode = m;
            }
            
            public void setModeString(String m) {
                if (m.equals("SINGLE")) {
                mode = SINGLE;
                }
                else if (m.equals("DOUBLE")) {
                mode = DOUBLE;
                }
                else if (m.equals("VERTEX")) {
                mode = VERTEX;
                }
                else if (m.equals("ROTATE")) {
                mode = ROTATE;
                }
                else {
                mode = SINGLE;
                }
            }

            public String getName() {
                return this.name;
            }

            public void lock() {
                lock = true;
            }
            public void unlock() {
                lock = false;
            }
            public void poke(int f) {
                //rot += 0.05;
                bop *= PApplet.pow(0.85, myDelta);
                lastFrameShown = f;
            }
            public boolean beingUsed(int f) {
                return (f == lastFrameShown-1 || f == lastFrameShown || f == lastFrameShown+1);
            }
            public boolean isLocked() {
                return lock;
            }
            public void setImg(String name) {
                PImage im = engine.display.getImg(name);
                if (im == null) {
                  engine.console.warn("sprite setImg(): "+name+" doesn't exist");
                  imgName = "white";
                  return;
                }
                imgName = name;
                if (wi == 0) { 
                wi = (int)im.width;
                defwi = wi;
                }
                if (hi == 0) {
                hi = (int)im.height;
                defhi = hi;
                }
                aspect = float(im.height)/float(im.width);
            }

            public void move(float x, float y) {
                float oldX = xpos;
                float oldY = ypos;
                xpos = x;
                ypos = y;
                defxpos = x;
                defypos = y;
                
                //Vertex position
                for (int i = 0; i < 4; i++) {
                  vertex.v[i].add(xpos-oldX, ypos-oldY);
                  defvertex.v[i].add(xpos-oldX, ypos-oldY);
                }
            }
            
            public void offmove(float x, float y) {
                //float oldX = xpos;
                //float oldY = ypos;
                offxpos = x;
                offypos = y;
                xpos = defxpos+x;
                ypos = defypos+y;
                
                for (int i = 0; i < 4; i++) {
                  //vertex.v[i].add(xpos-oldX, ypos-oldY);
                  offvertex(i, x, y);
                }
            }
            
            public void vertex(int v, float x, float y) {
                vertex.v[v].set(x, y);
                defvertex.v[v].set(x, y);
            }
            
            public void offvertex(int v, float x, float y) {
                offvertex.v[v].set(x, y);
                vertex.v[v].set(defvertex.v[v].x+x, defvertex.v[v].y+y);
            }

            public void setX(float x) {
                xpos = x;
                defxpos = x;
            }

            public void setY(float y) {
                ypos = y;
                defypos = y;
            }
            
            public void offsetX(float x) {
                offxpos = x;
                xpos = defxpos+x;
            }

            public void offsetY(float y) {
                offypos = y;
                ypos = defxpos+y;
            }

            public void setZ(float z) {
                zpos = z;
                defzpos = z;
            }

            public void setWidth(int w) {
                this.wi = w;
                defwi =   w;
            }

            public void setHeight(int h) {
                this.hi = h;
                defhi =   h;
            }
            
            public void offsetWidth(int w) {
                this.offwi = w;
                this.wi = defwi+w;
            }

            public void offsetHeight(int h) {
                this.offhi = h;
                this.hi = defhi+h;
            }

            public float getX() {
                return this.xpos;
            }

            public float getY() {
                return this.ypos;
            }

            public float getZ() {
                return this.zpos;
            }

            public int getWidth() {
                return this.wi;
            }

            public int getHeight() {
                return this.hi;
            }
            
            
            private boolean polyPoint(PVector[] vertices, float px, float py) {
                boolean collision = false;
            
                // go through each of the vertices, plus
                // the next vertex in the list
                int next = 0;
                for (int current=0; current<vertices.length; current++) {
            
                // get next vertex in list
                // if we've hit the end, wrap around to 0
                next = current+1;
                if (next == vertices.length) next = 0;
            
                // get the PVectors at our current position
                // this makes our if statement a little cleaner
                PVector vc = vertices[current];    // c for "current"
                PVector vn = vertices[next];       // n for "next"
            
                // compare position, flip 'collision' variable
                // back and forth
                if (((vc.y >= py && vn.y < py) || (vc.y < py && vn.y >= py)) &&
                    (px < (vn.x-vc.x)*(py-vc.y) / (vn.y-vc.y)+vc.x)) {
                        collision = !collision;
                }
                }
                return collision;
            }



            public boolean mouseWithinSquare() {
                switch (mode) {
                case SINGLE: {
                    float d = BOX_SIZE, x = (float)wi-d+xpos, y = (float)hi-d+ypos;
                    if (mouseX() > x && mouseY() > y && mouseX() < x+d && mouseY() < y+d) {
                      return true;
                    }
                }
                break;
                case DOUBLE: {
                  // width square
                    float d = BOX_SIZE, x1 = (float)wi-(d/2)+xpos, y1 = (float)(hi/2)-(d/2)+ypos;
                  // height square
                    float               x2 = (float)(wi/2)-(d/2)+xpos, y2 = (float)(hi)-(d/2)+ypos;
                    if ((mouseX() > x1 && mouseY() > y1 && mouseX() < x1+d && mouseY() < y1+d)
                    || (mouseX() > x2 && mouseY() > y2 && mouseX() < x2+d && mouseY() < y2+d)) {
                      return true;
                    }
                }
                break;
                case VERTEX: {
                    for (int i = 0; i < 4; i++) {
                    float d = BOX_SIZE;
                    float x = vertex.v[i].x;
                    float y = vertex.v[i].y;
                    if (mouseX() > x-d/2 && mouseY() > y-d/2 && mouseX() < x+d/2 && mouseY() < y+d/2) {
                        return true;
                    }
                    }
                }
                break;
                case ROTATE:
                //float decx = float(mouseX)-cx;
                //float decy = cy-float(mouseY);
                //if (decy < 0) {
                //  rot = atan(-decx/decy);
                //}
                //else {
                //  rot = atan(-decx/decy)+PI;
                //}
                float cx = xpos+wi/2, cy = ypos+hi/2;
                float d = BOX_SIZE;
                float x = cx+sin(rot)*radius,  y = cy+cos(rot)*radius;
                
                if (mouseX() > x-d/2 && mouseY() > y-d/2 && mouseX() < x+d/2 && mouseY() < y+d/2) {
                    return true;
                }
                break;
                default: {
                    d = BOX_SIZE;
                    x = (float)wi-d+xpos;
                    y = (float)hi-d+ypos;
                    if (mouseX() > x && mouseY() > y && mouseX() < x+d && mouseY() < y+d) {
                    return true;
                    }
                }
                break;
                }
                return false;
            }
            
            public float getRot() {
                return this.rot;
            }
            
            public void setRot(float r) {
                this.rot = r;
            }
            
            // hooo now that is some very incomplete code.
            // Don't use it, it doesn't work.
            public boolean rotateCollision() {
                float r = HALF_PI/2 + rot;
                float xr = radius;
                float yr = radius;
                float xd = xpos+float(wi)/2;
                float yd = ypos+float(hi)/2;
                float f = 0;
                if (wi > hi) {
                f = 1-(float(hi)/float(wi));
                }
                else if (hi > wi) {
                f = 1-(float(wi)/float(hi));
                }
                else {
                f = 0;
                }
                
                float x = sin(r+f)*xr + xd;
                float y = cos(r+f)*yr + yd;
                vertex.v[0].x = x;
                vertex.v[0].y = y;
                x = sin(r-f+HALF_PI)*xr + xd;
                y = cos(r-f+HALF_PI)*yr + yd;
                vertex.v[1].x = x;
                vertex.v[1].y = y;
                x = sin(r+f+PI)*xr + xd;
                y = cos(r+f+PI)*yr + yd;
                vertex.v[2].x = x;
                vertex.v[2].y = y;
                x = sin(r-f+HALF_PI+PI)*xr + xd;
                y = cos(r-f+HALF_PI+PI)*yr + yd;
                vertex.v[3].x = x;
                vertex.v[3].y = y;
                x = sin(r+f)*xr + xd;
                y = cos(r+f)*yr + yd;
                vertex.v[0].x = x;
                vertex.v[0].y = y;
                
                return polyPoint(vertex.v, mouseX(), mouseY());
            }
            
            
            public boolean mouseWithinSprite() {
                // Bug fix thing to not allow clickable area to go outside canvas bounds.
                // it's for umm *ahem* sketchiepad.
                float canvwi = engine.display.currentPG.width;
                float canvhi = engine.display.currentPG.height;
                float x   = max(min(xpos, canvwi), 0);
                float y   = max(min(ypos, canvhi), 0);
                float xwi = max(min(xpos+wi, canvwi), 0);
                float yhi = max(min(ypos+hi, canvhi), 0);
                switch (mode) {
                  case SINGLE: {
                      return (mouseX() > x && mouseY() > y && mouseX() < xwi && mouseY() < yhi);
                      //return (mouseX > x && mouseY > y && mouseX < x+wi && mouseY < y+hi && !repositionDrag.isDragging());
                  }
                  case DOUBLE: {
                      return (mouseX() > x && mouseY() > y && mouseX() < xwi && mouseY() < yhi);
                  }
                  case VERTEX:
                      return polyPoint(vertex.v, mouseX(), mouseY());
                  case ROTATE: {
                      return rotateCollision();
                }
                    
                }
                return false;
            }
            
            public boolean mouseWithinHitbox() {
              return mouseWithinSprite() || mouseWithinSquare();
            }

            public boolean clickedOn() {
                return (mouseWithinHitbox() && repositionDrag.clicked());
            }
            
            public boolean isSelected() {
              return this.equals(selectedSprite);
            }
            
            // The sprite class ripped from Sketchiepad likes to sh*t out
            // json files whenever it's moved or anything. We don't want any
            // text placeable elements to do that. If a path wasn't provided
            // in the constructor we do NOT update the sprite data.
            public void updateJSON() {
                if (saveSpriteData) {
                    JSONObject attributes = new JSONObject();
                    
                    attributes.setString("name", name);
                    attributes.setString("mode", getModeString());
                    attributes.setBoolean("locked", this.isLocked());
                    attributes.setInt("x", (int)this.defxpos);
                    attributes.setInt("y", (int)this.defypos);
                    attributes.setInt("w", (int)this.defwi);
                    attributes.setInt("h", (int)this.defhi);
                    
                    for (int i = 0; i < 4; i++) {
                        attributes.setInt("vx"+str(i), (int)defvertex.v[i].x);
                        attributes.setInt("vy"+str(i), (int)defvertex.v[i].y);
                    }
                    
                    //resetDefaults();
                    
                    app.saveJSONObject(attributes, myPath+name+".json");
                }
                engine.stats.increase("sprites_moved", 1);
            }
            
            public boolean isDragging() {
                return resizeDrag.isDragging() || repositionDrag.isDragging();
            }

            public void dragReposition() {
                boolean dragging = mouseWithinHitbox();
                
                if (mode == VERTEX) {
                  dragging = mouseWithinSprite();
                }
                
                // Bug fix where small area is non-selectable.
                if (allowResizing) {
                  dragging &= !mouseWithinSquare();
                }
                
                if (dragging && !repositionDrag.isDragging()) {
                repositionDrag.beginDrag();
                
                //X and Y position
                repositionDragStartX = this.xpos-mouseX();
                repositionDragStartY = this.ypos-mouseY();
                
                //Vertex position
                for (int i = 0; i < 4; i++) {
                    repositionV.v[i].set(vertex.v[i].x-mouseX(), vertex.v[i].y-mouseY());
                }
                }
                if (repositionDrag.isDragging()) {
                //X and y position
                this.xpos = repositionDragStartX+mouseX();
                this.ypos = repositionDragStartY+mouseY();
                
                defxpos = xpos-offxpos;
                defypos = ypos-offypos;
                
                //Vertex position
                for (int i = 0; i < 4; i++) {
                    vertex.v[i].set(repositionV.v[i].x+mouseX(), repositionV.v[i].y+mouseY());
                    defvertex.v[i].set(vertex.v[i].x-offvertex.v[i].x, vertex.v[i].y-offvertex.v[i].y);
                }
                }
                if (repositionDrag.draggingEnded()) {
                    updateJSON();
                }

                repositionDrag.update();
            }

            public boolean hoveringOverResizeSquare() {
                return this.hoveringOverResizeSquare;
            }

            public boolean hoveringVertex(float px, float py) {
                boolean collision = false;
                int next = 0;
                for (int current=0; current<vertex.v.length; current++) {

                // get next vertex in list
                // if we've hit the end, wrap around to 0
                next = current+1;
                if (next == vertex.v.length) next = 0;

                PVector vc = vertex.v[current];    // c for "current"
                PVector vn = vertex.v[next];       // n for "next"

                if ( ((vc.y > py) != (vn.y > py)) && (px < (vn.x-vc.x) * (py-vc.y) / (vn.y-vc.y) + vc.x) ) {
                    collision = !collision;
                }
                }

                return false;
            }

            public void resizeSquare() {
                switch (mode) {
                case SINGLE: {
                    float d = BOX_SIZE, x = (float)wi-d+xpos, y = (float)hi-d+ypos;
                    resizeDrag.update();
                    this.square(x,y, d);
                    if (mouseX() > x && mouseY() > y && mouseX() < x+d && mouseY() < y+d) {
                    resizeDrag.beginDrag();
                    this.hoveringOverResizeSquare = true;
                    } else {
                    this.hoveringOverResizeSquare = false;
                    }
                    if (resizeDrag.isDragging()) {
                    wi = int((mouseX()+d/2-xpos));
                    hi = int((mouseX()+d/2-xpos)*aspect);
                    
                    defwi = wi-offwi;
                    defhi = hi-offhi;
                    }
                    if (resizeDrag.draggingEnded()) {
                    updateJSON();
                    }
                }
                break;
                    
                    
                case DOUBLE: {
                  // width square
                    float d = BOX_SIZE, x1 = (float)wi-(d/2)+xpos, y1 = (float)(hi/2)-(d/2)+ypos;
                  // height square
                    float               x2 = (float)(wi/2)-(d/2)+xpos, y2 = (float)(hi)-(d/2)+ypos;
                    resizeDrag.update();
                    this.square(x1, y1, d);
                    this.square(x2, y2, d);
                    if (mouseX() > x1 && mouseY() > y1 && mouseX() < x1+d && mouseY() < y1+d) {
                      resizeDrag.beginDrag();
                      // whatever we're using currentVertex
                      currentVertex = 1;
                      this.hoveringOverResizeSquare = true;
                    } else if (mouseX() > x2 && mouseY() > y2 && mouseX() < x2+d && mouseY() < y2+d) {
                      resizeDrag.beginDrag();
                      // whatever we're using currentVertex
                      currentVertex = 2;
                      this.hoveringOverResizeSquare = true;
                    }
                    else {
                      this.hoveringOverResizeSquare = false;
                    }
                    
                    
                    if (resizeDrag.isDragging()) {
                      if (currentVertex == 1) {
                        wi = int((mouseX()+d/2-xpos));
                      }
                      else if (currentVertex == 2) {
                        hi = int((mouseY()+d/2-ypos));
                      }
                      
                      defwi = wi-offwi;
                      defhi = hi-offhi;
                    }
                    
                    if (resizeDrag.draggingEnded()) {
                      updateJSON();
                    }
                }
                break;
                
                case VERTEX: {
                    resizeDrag.update();
                    for (int i = 0; i < 4; i++) {
                      float d = BOX_SIZE;
                      float x = vertex.v[i].x;
                      float y = vertex.v[i].y;
                      this.square(x-d/2, y-d/2, d);
                      
                      if (mouseX() > x-d/2 && mouseY() > y-d/2 && mouseX() < x+d/2 && mouseY() < y+d/2) {
                          resizeDrag.beginDrag();
                          currentVertex = i;
                          this.hoveringOverResizeSquare = true;
                      } else {
                          this.hoveringOverResizeSquare = false;
                      }
                      if (resizeDrag.isDragging() && currentVertex == i) {
                          vertex.v[i].x = mouseX();
                          vertex.v[i].y = mouseY();
                          defvertex.v[i].set(vertex.v[i].x-offvertex.v[i].x, vertex.v[i].y-offvertex.v[i].y);
                      }
                    }
                    if (resizeDrag.draggingEnded()) {
                    updateJSON();
                    }
                }
                break;
                
                
                case ROTATE: {
                    resizeDrag.update();
                    float cx = xpos+wi/2, cy = ypos+hi/2;
                    float d = BOX_SIZE;
                    float x = cx+sin(rot)*radius,  y = cy+cos(rot)*radius;
                    
                    this.square(x-d/2, y-d/2, d);
                    
                    if (mouseX() > x-d/2 && mouseY() > y-d/2 && mouseX() < x+d/2 && mouseY() < y+d/2) {
                    resizeDrag.beginDrag();
                    this.hoveringOverResizeSquare = true;
                    } else {
                    this.hoveringOverResizeSquare = false;
                    }
                    
                    if (resizeDrag.isDragging()) {
                    float decx = (mouseX())-cx;
                    float decy = cy-(mouseY());
                    if (decy < 0) {
                        rot = atan(-decx/decy);
                    }
                    else {
                        rot = atan(-decx/decy)+PI;
                    }
                    
                    //float a = float(wi)/float(hi);
                    float s = sin(rot);//, c = a*-cos(rot);
                    if (s != 0.0) {
                        radius = decx/s;
                    }
                    
                    
                    }
                }
                break;
                    
                }
            }
            
            public void setRadius(float x) {
                radius = x;
            }
            
            public float getRadius() {
                return radius;
            }
            
            public void createVertices() {
                vertex.v[0].set(xpos, ypos);
                vertex.v[1].set(xpos+wi, ypos);
                vertex.v[2].set(xpos+wi, ypos+hi);
                vertex.v[3].set(xpos, ypos+hi);
                
                defvertex.v[0].set(xpos, ypos);
                defvertex.v[1].set(xpos+wi, ypos);
                defvertex.v[2].set(xpos+wi, ypos+hi);
                defvertex.v[3].set(xpos, ypos+hi);
            }

            private void square(float x, float y, float d) {
                noStroke();
                engine.display.currentPG.fill(sin(selectBorderTime += 0.1*engine.display.getDelta())*50+200, 100);
                engine.display.currentPG.rect(x, y, d, d);
            }
        }
        
        // New method added.
        // This is called at the start of screens so that things like GUI's can
        // be repositioned if there's different scaling.
        // Only does it on the x axis for now.
        public void repositionSpritesToScale() {
          repositionSpritesToScale = true;
        }

        private int totalSprites = 0;
        
        public Sprite getSprite(String name) {
            try {
            return sprites.get(spriteNames.get(name));
            }
            catch (NullPointerException e) {
                //if (!suppressSpriteWarning)
                //    console.bugWarn("Sprite "+name+" does not exist.");
                return unusedSprite;
            }
        }
        
        public Sprite getSpriteVary(String name) {
          try {
            if (engine.display.phoneMode) {
              return sprites.get(spriteNames.get(name+"-phone"));
            }
            else {
              return sprites.get(spriteNames.get(name));
            }
          }
          catch (NullPointerException e) {
              //if (!suppressSpriteWarning)
              //    console.bugWarn("Sprite "+name+" does not exist.");
              return unusedSprite;
          }
        }
  
        // What a confusing method name lol
        // We don't want to load or save from json for sprites like
        // placeables.
        public void updateSpriteFromJSON(Sprite s) throws NullPointerException {
            if (saveSpriteData) {
                JSONObject att = loadJSONObject(myPath+s.getName()+".json");
                s.move(att.getInt("x"), att.getInt("y"));
                s.setWidth(att.getInt("w"));
                s.setHeight(att.getInt("h"));
                
                s.setModeString(att.getString("mode"));
                if (att.getBoolean("locked")) {
                    s.lock();
                }
                
                for (int i = 0; i < 4; i++) {
                    //s.vertex.v[i].set(att.getInt("vx"+str(i)), att.getInt("vy"+str(i)));
                    //s.defvertex.v[i].set(att.getInt("vx"+str(i)), att.getInt("vy"+str(i)));
                    s.vertex(i, att.getInt("vx"+str(i)), att.getInt("vy"+str(i)));
                }
            }
        }
        public void addSprite(String identifier, String img) {
            Sprite newSprite = new Sprite(identifier);
            newSprite.setImg(img);
            newSprite.setOrder(++totalSprites);
            addSprite(identifier, newSprite);
            try {
            updateSpriteFromJSON(newSprite);
            }
            catch (NullPointerException e) {
            newSprite.move(newSpriteX, newSpriteY);
            newSprite.setZ(newSpriteZ);
            newSpriteX += 20;
            newSpriteY += 20;
            newSpriteZ += 20;
            newSprite.createVertices();
            }
            
            // Added part: automatically offset if we need to reposition by scale.
            // TODO: This code has been disabled because it is buggy. It needs to be fixed.
            //if (repositionSpritesToScale) {
            //  if (engine.displayScale*0.5 >= 1.) newSprite.offsetX((newSprite.getX()/(engine.displayScale*0.5))-newSprite.getX());
            //  else newSprite.offsetX(newSprite.getX()-(newSprite.getX()/sqrt(engine.displayScale*2)));
            //}
        }
        private void addSprite(String name, Sprite sprite) {
            sprites.add(sprite);
            spriteNames.put(name, sprites.size()-1);
        }
        
        public Sprite spriteWithName(String name) {
            return sprites.get(spriteNames.get(name));
        }
        public void newSprite(String name) {
            Sprite sprite = new Sprite(name);
            this.addSprite(name, sprite);
        }
        public void newSprite(String name, String img) {
            Sprite sprite = new Sprite(name);
            sprite.setImg(img);
            this.addSprite(name, sprite);
        }
        public void newSprite(String name, String img, float x, float y) {
            Sprite sprite = new Sprite(name);
            sprite.setImg(img);
            sprite.move(x,y);
            this.addSprite(name, sprite);
        }
        public void newSprite(String name, String img, float x, float y, int w, int h) {
            Sprite sprite = new Sprite(name);
            sprite.setImg(img);
            sprite.move(x,y);
            sprite.setWidth(w);
            sprite.setHeight(h);
            this.addSprite(name, sprite);
        }

        public boolean spriteExists(String identifier) {
            return (spriteNames.get(identifier) != null);
        }

        public void emptySpriteStack() {
            spritesStack.empty();
        }

        private void renderSprite(Sprite s) {
            if (s.isSelected() || (showAllWireframes && keyPressAllowed)) {
                engine.display.wireframe = true;
                if (engine.input.ctrlDown && engine.input.altDown && engine.input.shiftDown) {
                  if (engine.input.keyDownOnce('d')) {
                    s.mode = DOUBLE;
                    engine.console.log("Sprite mode set to DOUBLE");
                  }
                  else if (engine.input.keyDownOnce('s')) {
                    s.mode = SINGLE;
                    engine.console.log("Sprite mode set to SINGLE");
                  }
                }
            }
            //draw.autoImg(s.getImg(), s.getX(), s.getY()+s.getHeight()*s.getBop(), s.getWidth(), s.getHeight()-int((float)s.getHeight()*s.getBop()));
            
            // Bug fix (hopefully)
            fill(255);
            switch (s.mode) {
              case SINGLE:
              engine.display.img(s.imgName, s.getX(), s.getY()+s.getHeight()*s.getBop(), s.getWidth(), s.getHeight()-int((float)s.getHeight()*s.getBop()));
              break;
              case DOUBLE:
              engine.display.img(s.imgName, s.getX(), s.getY()+s.getHeight()*s.getBop(), s.getWidth(), s.getHeight()-int((float)s.getHeight()*s.getBop()));
              break;
              case VERTEX:
              //engine.console.log(
              //s.vertex.v[0].x+","+ s.vertex.v[0].y+","+ 
              //s.vertex.v[1].x+","+ s.vertex.v[1].y+","+
              //s.vertex.v[2].x+","+ s.vertex.v[2].y+","+ 
              //s.vertex.v[3].x+","+ s.vertex.v[3].y);
              
              engine.display.img(s.imgName, 
              s.vertex.v[0].x, s.vertex.v[0].y, 
              s.vertex.v[1].x, s.vertex.v[1].y, 
              s.vertex.v[2].x, s.vertex.v[2].y, 
              s.vertex.v[3].x, s.vertex.v[3].y);
              
              break;
              case ROTATE:
              //draw.autoImgRotate(s);
              break;
            }
            
            if (s.isSelected()) {
              if (!s.isLocked()) {
                  if (s.allowResizing) {
                      s.resizeSquare();
                      // Bug fix: reset fill
                      engine.display.currentPG.fill(255, 255);
                  }
                  s.dragReposition();
              }
            }
            
            engine.display.wireframe = false;
            s.poke(app.frameCount);
        }

        public void renderSprites() {
            for (Sprite s : sprites) {
                renderSprite(s);
            }
        }
        
        public void renderSprite(String name, String img) {
            Sprite s = getSprite(name);
            s.setImg(img);
            renderSprite(s);
        }
        
        public void renderSprite(String name) {
            Sprite s = sprites.get(spriteNames.get(name));
            renderSprite(s);
        }

        public void guiElement(String identifier, String image) {
            //float ratioX = app.width/float(app.displayWidth);
            //println("ratioX: " + ratioX);
            //getSprite(identifier).offmove((float(app.displayWidth)*ratioX), 0.);
            this.sprite(identifier, image);
        }

        public void guiElement(String nameAndID) {
            this.guiElement(nameAndID, nameAndID);
        }

        public void button(String identifier, String image, String text) {
            this.guiElement(identifier, image);
            if (text.length() > 0) {
                app.textFont(engine.DEFAULT_FONT, 18);
                // app.fill(255);
                app.textAlign(CENTER, TOP);
                float x = getSprite(identifier).getX() + getSprite(identifier).getWidth()/2;
                float y = getSprite(identifier).getY() + getSprite(identifier).getHeight() + 5;
                engine.display.recordRendererTime();
                app.text(text, x, y);
                engine.display.recordLogicTime();
            }
        }

        public void button(String nameAndID, String text) {
            this.button(nameAndID, nameAndID, text);
        }

        public void button(String nameAndID) {
            this.button(nameAndID, nameAndID);
        }


        // TODO: move the button code to the engine later.
        // Anything that needs to be consistant between screens
        // should be in the engine class anyways.
        public boolean buttonClicked(String identifier) {
            Sprite s = getSprite(identifier);
            return (s.mouseWithinHitbox() && engine.input.primaryOnce);
        }

        public boolean buttonHover(String identifier) {
            Sprite s = getSprite(identifier);
            return s.mouseWithinHitbox();
        }
        
        public void spriteVary(String nameAndID) {
          if (engine.display.phoneMode) {
            this.sprite(nameAndID+"-phone", nameAndID);
          }
          else {
            this.sprite(nameAndID, nameAndID);
          }
        }

        public void spriteVary(String identifier, String image) {
          if (engine.display.phoneMode) {
            this.sprite(identifier+"-phone", image);
          }
          else {
            this.sprite(identifier, image);
          }
        }

        public void sprite(String nameAndID) {
            this.sprite(nameAndID, nameAndID);
        }

        public void sprite(String identifier, String image) {
            if (!spriteExists(identifier)) {
                addSprite(identifier, image);
            }
            Sprite s = getSprite(identifier);
            s.setImg(image);
            try { spritesStack.push(s); }
            catch (StackException e) { 
              this.engine.console.bugWarnOnce("Sprite stack is full, did you forget to call updateSpriteSystem()?"); 
            }
            renderSprite(s);
        }

        // Same as sprite, except since the code is so botched,
        // here's some more botch'd code with hackDimensions
        // where we DON'T render the sprite.
        public void placeable(String identifier) {
            if (!spriteExists(identifier)) addSprite(identifier, "nothing");
            Sprite s = getSprite(identifier);
            placeable(s);
        }

        public void placeable(Sprite s) {
            s.imgName = "nothing";
            spritesStack.push(s);
            renderSprite(s);
        }

        public void hackSpriteDimensions(Sprite s, int w, int h) {
            s.wi = w;
            s.hi = h;
            s.aspect = float(h)/float(w);
        }

        public void hackSpriteDimensions(String identifier, int w, int h) {
            Sprite s = getSprite(identifier);
            hackSpriteDimensions(s, w, h);
        }
        
        private void runSpriteInteraction() {
            
            // Replace true with false to disable sprite interaction.
          
            if (!interactable) return;
              
            if (selectedSprite != null) {
                if (!selectedSprite.beingUsed(app.frameCount)) {
                selectedSprite = null;
                }
            }
            
            boolean hoveringOverAtLeast1Sprite = false;
            boolean clickedSprite = false;
            
            
            for (int i = 0; i < spritesStack.size(); i++) {
                Sprite s = spritesStack.peek(i);
                if (s.isSelected()) {
                  if (s.mouseWithinHitbox()) {
                      hoveringOverAtLeast1Sprite = true;
                  }
                }
                else if (s.mouseWithinHitbox()) {
                hoveringOverAtLeast1Sprite = true;
                if (generalClick.clicked()) {
                    selectedSprites.push(s);
                    clickedSprite = true;
                }
                }
            }
            
            
            // Don't bother with selecting logic if it's outside of the clicking content zone.
            if (!allowSelectOffContentPane) {
              float mousey = engine.input.mouseY();
              float upper = engine.currScreen.myUpperBarWeight;
              float lower = engine.display.HEIGHT-engine.currScreen.myLowerBarWeight;
              // If mouse is within upperbar or lowerbar zone, don't bother
              // checking for selecting sprites.
              if (mousey < upper || mousey > lower) return;
            }
            
            
            //Sort through the sprites and select the front-most sprite (sprite with the biggest zpos)
            if (clickedSprite && selectedSprites.size() > 0) {
                boolean performSearch = true;
                if (selectedSprite != null) {
                  if (selectedSprite.mouseWithinHitbox()) {
                      performSearch = false;
                  }
                  
                  if (selectedSprite.isDragging()) {
                      performSearch = false;
                  }
                }
                
                if (performSearch) {
                  int highest = selectedSprites.top().getOrder();
                  Sprite highestSelected = selectedSprites.top();
                  for (int i = 0; i < selectedSprites.size(); i++) {
                      Sprite s = selectedSprites.peek(i);
                      if (s.getOrder() > highest) {
                          highest = s.getOrder();
                          highestSelected = s;
                      }
                  }
                  selectedSprite = highestSelected;
                  selectedSprites.empty();
                }
            }
            
            if (!hoveringOverAtLeast1Sprite && generalClick.clicked()) {
                selectedSprite = null;
            }
        }
        
        //idk man. I'm not in the mood to name things today lol.
        public void keyboardInteractionEnabler() {
          if (engine.input.ctrlDown && engine.input.altDown && engine.input.shiftDown) {
            if (engine.input.secondaryOnce) {
              if (!this.interactable) {
                this.interactable = true;
                engine.console.log("Sprite system interactability enabled.");
              }
              else {
                this.interactable = false;
                engine.console.log("Sprite system interactability disabled.");
              }
            }
          }
        }

        public void updateSpriteSystem() {
            // By default, delta is engine's delta
            if (!customDelta) {
              customDelta = false;
            }
            else myDelta = engine.display.getDelta();
            
            this.keyboardInteractionEnabler();
            this.generalClick.update();
            this.runSpriteInteraction();
            this.emptySpriteStack();
        }
        
        public void setMouseScale(float x, float y) {
          mouseScaleX = x;
          mouseScaleY = y;
        }
        
        public void setMouseOffset(float x, float y) {
          mouseOffsetX = x;
          mouseOffsetY = y;
        }

    }
    


    

    //*******************************************
    //****************Stack class****************
    class StackException extends RuntimeException{    
        public StackException(String err) {
            super(err);
        }
    }

    public class Stack<T> implements Iterable<T> {
      private Object[] S;
      private int top;
      private int capacity;
      
      public Stack(int size){
          capacity = size;
          S = new Object[size];
          top = -1;
      }
  
      public Stack(){
          this(100);
      }
      
      public T peek() {
          if(isEmpty())
          throw new StackException("stack is empty");
          return (T)S[top];
      }
      
      public T peek(int indexFromTop) {
          //Accessing negative indexes should be impossible.
          if(top-indexFromTop < 0)
          throw new StackException("stack is empty");
          return (T)S[top-indexFromTop];
      }
      
      public boolean isEmpty(){
          return top < 0;
      }
      
      public int size(){
          return top+1; 
      }
      
      public void empty() {
          top = -1;
      }
  
      public void push(T e){
          if(size() == capacity) {
            throw new StackException("stack is full");
          }
          S[++top] = e;
      }
      
      public T pop() throws StackException{
          if(isEmpty())
          throw new StackException("stack is empty");
          // this type cast is safe because we type checked the push method
          return (T) S[top--];
      }
      
      public T top() throws StackException{
          if(isEmpty())
          throw new StackException("stack is empty");
          // this type cast is safe because we type checked the push method
          return (T) S[top];
      }
      
      public Iterator<T> iterator() {
        return (Iterator<T>)Arrays.asList(S).iterator();
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
    FILE_TYPE_PDF,
    FILE_TYPE_VIDEO, 
    FILE_TYPE_MUSIC, 
    FILE_TYPE_MODEL, 
    FILE_TYPE_DOC,
    FILE_TYPE_TIMEWAYENTRY,
    FILE_TYPE_SHORTCUT,
    FILE_TYPE_SKETCHIO
}
