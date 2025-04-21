import processing.core.*;
import processing.data.*;
import processing.event.*;
import processing.opengl.*;
// import java.lang.Math;
import java.io.*;
import java.lang.reflect.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.text.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.regex.*;
import java.util.zip.*;
import java.lang.Runnable;


public class CustomPlugin {

  public PApplet app;
  public PGraphics g;
  
  // PConstants
  public final int X = 0;
  public final int Y = 1;
  public final int Z = 2;
  public final String JAVA2D = "processing.awt.PGraphicsJava2D";
  public final String P2D = "processing.opengl.PGraphics2D";
  public final String P3D = "processing.opengl.PGraphics3D";
  public final String FX2D = "processing.javafx.PGraphicsFX2D";
  public final String PDF = "processing.pdf.PGraphicsPDF";
  public final String SVG = "processing.svg.PGraphicsSVG";
  public final String DXF = "processing.dxf.RawDXF";
  public final int OTHER   = 0;
  public final int WINDOWS = 1;
  public final int MACOS   = 2;
  public final int LINUX   = 3;
  public final String[] platformNames = {
    "other", "windows", "macos", "linux"
  };
  public final float EPSILON = 0.0001f;
  public final float MAX_FLOAT = Float.MAX_VALUE;
  public final float MIN_FLOAT = -Float.MAX_VALUE;
  public final int MAX_INT = Integer.MAX_VALUE;
  public final int MIN_INT = Integer.MIN_VALUE;
  public final int VERTEX = 0;
  public final int BEZIER_VERTEX = 1;
  public final int QUADRATIC_VERTEX = 2;
  public final int CURVE_VERTEX = 3;
  public final int BREAK = 4;
  public final int QUAD_BEZIER_VERTEX = 2;
  public final float PI = (float) Math.PI;
  public final float HALF_PI = (float) (Math.PI / 2.0);
  public final float THIRD_PI = (float) (Math.PI / 3.0);
  public final float QUARTER_PI = (float) (Math.PI / 4.0);
  public final float TWO_PI = (float) (2.0 * Math.PI);
  public final float TAU = (float) (2.0 * Math.PI);
  public final float DEG_TO_RAD = PI/180.0f;
  public final float RAD_TO_DEG = 180.0f/PI;
  public final String WHITESPACE = " \t\n\r\f\u00A0";
  public final int RGB   = 1;  // image & color
  public final int ARGB  = 2;  // image
  public final int HSB   = 3;  // color
  public final int ALPHA = 4;  // image
  public final int TIFF  = 0;
  public final int TARGA = 1;
  public final int JPEG  = 2;
  public final int GIF   = 3;
  public final int BLUR      = 11;
  public final int GRAY      = 12;
  public final int INVERT    = 13;
  public final int OPAQUE    = 14;
  public final int POSTERIZE = 15;
  public final int THRESHOLD = 16;
  public final int ERODE     = 17;
  public final int DILATE    = 18;
  public final int REPLACE    = 0;
  public final int BLEND      = 1 << 0;
  public final int ADD        = 1 << 1;
  public final int SUBTRACT   = 1 << 2;
  public final int LIGHTEST   = 1 << 3;
  public final int DARKEST    = 1 << 4;
  public final int DIFFERENCE = 1 << 5;
  public final int EXCLUSION  = 1 << 6;
  public final int MULTIPLY   = 1 << 7;
  public final int SCREEN     = 1 << 8;
  public final int OVERLAY    = 1 << 9;
  public final int HARD_LIGHT = 1 << 10;
  public final int SOFT_LIGHT = 1 << 11;
  public final int DODGE      = 1 << 12;
  public final int BURN       = 1 << 13;
  public final int CHATTER   = 0;
  public final int COMPLAINT = 1;
  public final int PROBLEM   = 2;
  public final int PROJECTION = 0;
  public final int MODELVIEW  = 1;
  public final int CUSTOM       = 0; // user-specified fanciness
  public final int ORTHOGRAPHIC = 2; // 2D isometric projection
  public final int PERSPECTIVE  = 3; // perspective matrix
  public final int GROUP           = 0;   // createShape()
  public final int POINT           = 2;   // primitive
  public final int POINTS          = 3;   // vertices
  public final int LINE            = 4;   // primitive
  public final int LINES           = 5;   // beginShape(), createShape()
  public final int LINE_STRIP      = 50;  // beginShape()
  public final int LINE_LOOP       = 51;
  public final int TRIANGLE        = 8;   // primitive
  public final int TRIANGLES       = 9;   // vertices
  public final int TRIANGLE_STRIP  = 10;  // vertices
  public final int TRIANGLE_FAN    = 11;  // vertices
  public final int QUAD            = 16;  // primitive
  public final int QUADS           = 17;  // vertices
  public final int QUAD_STRIP      = 18;  // vertices
  public final int POLYGON         = 20;  // in the end, probably cannot
  public final int PATH            = 21;  // separate these two
  public final int RECT            = 30;  // primitive
  public final int ELLIPSE         = 31;  // primitive
  public final int ARC             = 32;  // primitive
  public final int SPHERE          = 40;  // primitive
  public final int BOX             = 41;  // primitive
  public final int OPEN = 1;
  public final int CLOSE = 2;
  public final int CORNER   = 0;
  public final int CORNERS  = 1;
  public final int RADIUS   = 2;
  public final int CENTER   = 3;
  public final int DIAMETER = 3;
  public final int CHORD  = 2;
  public final int PIE    = 3;
  public final int BASELINE = 0;
  public final int TOP = 101;
  public final int BOTTOM = 102;
  public final int NORMAL     = 1;
  public final int IMAGE      = 2;
  public final int CLAMP = 0;
  public final int REPEAT = 1;
  public final int MODEL = 4;
  public final int SHAPE = 5;
  public final int SQUARE   = 1 << 0;  // called 'butt' in the svg spec
  public final int ROUND    = 1 << 1;
  public final int PROJECT  = 1 << 2;  // called 'square' in the svg spec
  public final int MITER    = 1 << 3;
  public final int BEVEL    = 1 << 5;
  public final int AMBIENT = 0;
  public final int DIRECTIONAL  = 1;
  public final int SPOT = 3;
  public final char BACKSPACE = 8;
  public final char TAB       = 9;
  public final char ENTER     = 10;
  public final char RETURN    = 13;
  public final char ESC       = 27;
  public final char DELETE    = 127;
  public final int CODED     = 0xffff;
  public final int PORTRAIT = 1;
  public final int LANDSCAPE = 2;
  public final int SPAN = 0;
  public final int DISABLE_DEPTH_TEST         =  2;
  public final int ENABLE_DEPTH_TEST          = -2;
  public final int ENABLE_DEPTH_SORT          =  3;
  public final int DISABLE_DEPTH_SORT         = -3;
  public final int DISABLE_OPENGL_ERRORS      =  4;
  public final int ENABLE_OPENGL_ERRORS       = -4;
  public final int DISABLE_DEPTH_MASK         =  5;
  public final int ENABLE_DEPTH_MASK          = -5;
  public final int DISABLE_OPTIMIZED_STROKE   =  6;
  public final int ENABLE_OPTIMIZED_STROKE    = -6;
  public final int ENABLE_STROKE_PERSPECTIVE  =  7;
  public final int DISABLE_STROKE_PERSPECTIVE = -7;
  public final int DISABLE_TEXTURE_MIPMAPS    =  8;
  public final int ENABLE_TEXTURE_MIPMAPS     = -8;
  public final int ENABLE_STROKE_PURE         =  9;
  public final int DISABLE_STROKE_PURE        = -9;
  public final int ENABLE_BUFFER_READING      =  10;
  public final int DISABLE_BUFFER_READING     = -10;
  public final int DISABLE_KEY_REPEAT         =  11;
  public final int ENABLE_KEY_REPEAT          = -11;
  public final int DISABLE_ASYNC_SAVEFRAME    =  12;
  public final int ENABLE_ASYNC_SAVEFRAME     = -12;
  public final int HINT_COUNT                 =  13;

  public final int MODE_PRESCENE = 1;
  public final int MODE_SCENE = 2;
  public final int MODE_POSTSCENE = 13;
  public final int MODE_UI = 4;


  ///////////////////////////////////////////
  // API

  private String getString(int op, Object... argss) {
    apiOpCode = op;
    for (int i = 0; i < argss.length; i++) {
      args[i] = argss[i];
    }
    apiCall.run();
    return (String)ret;
  }

  private float getFloat(int op, Object... argss) {
    apiOpCode = op;
    for (int i = 0; i < argss.length; i++) {
      args[i] = argss[i];
    }
    apiCall.run();
    return (float)ret;
  }
  
  private int getInt(int op, Object... argss) {
    apiOpCode = op;
    for (int i = 0; i < argss.length; i++) {
      args[i] = argss[i];
    }
    apiCall.run();
    return (int)ret;
  }
  
  
  private boolean getBool(int op, Object... argss) {
    apiOpCode = op;
    for (int i = 0; i < argss.length; i++) {
      args[i] = argss[i];
    }
    apiCall.run();
    return (boolean)ret;
  }

  private void call(int op, Object... argss) {
    apiOpCode = op;
    for (int i = 0; i < argss.length; i++) {
      args[i] = argss[i];
    }
    apiCall.run();
  }

  // API calls.

  public String test(int number) {
    return getString(1, number);
  }

  public void print(Object... stufftoprint) {
    apiOpCode = 2;
    if (stufftoprint.length >= 127) {
      warn("You've put too many args in print()!");
      return;
    }
    // First arg used for length of list
    args[0] = stufftoprint.length+1;
    // Continue here.
    for (int i = 1; i < stufftoprint.length+1; i++) {
      args[i] = stufftoprint[i-1];
    }
    apiCall.run();
  }

  public void warn(String message) {
    call(3, message);
  }

  
  // File API functions
  public void fileMkdir(String path) {
    call(1000, path);
  }

  public boolean fileCopy(String src, String dest) {
    return getBool(1001, src, dest);
  }

  public String fileGetLastModified(String path) {
    return getString(1002, path);
  }

  public String fileGetExt(String path) {
    return getString(1003, path);
  }

  public String fileGetDir(String path) {
    return getString(1004, path);
  }

  public boolean fileIsDirectory(String path) {
    return getBool(1005, path);
  }

  public String fileGetPrevDir(String path) {
    return getString(1006, path);
  }

  public String fileGetRelativeDir(String from, String to) {
    return getString(1007, from, to);
  }

  public String fileRelativeToAbsolute(String start, String relative) {
    return getString(1008, start, relative);
  }

  public String fileDirectorify(String dir) {
    return getString(1010, dir);
  }

  public String fileGetMyDir() {
    return getString(1011);
  }

  public boolean fileExists(String path) {
    return getBool(1012, path);
  }

  public int fileGetSize(String path) {
    return getInt(1013, path);
  }

  public boolean fileIsImage(String path) {
      return getBool(1014, path);
  }

  public String fileGetFilename(String path) {
      return getString(1015, path);
  }

  public String fileGetIsolatedFilename(String path) {
      return getString(1016, path);
  }
  
  public boolean fileAtRootDir(String dirName) {      
      return getBool(1017, dirName);
  }
  
  public String fileExtToIco(String ext) {
      return getString(1009, ext);
  }

  public boolean fileHidden(String filename) {
      return getBool(1018, filename);
  }

  public String fileUnhide(String original) {
      return getString(1019, original);
  }
  
  public int fileCountFiles(String path) {
      return getInt(1020, path);
  }

  public void fileOpen(String path) {
      call(1021, path);
  }

  public void fileOpenEntryReadonly(String path) {
      call(1022, path);
  }
  
  

  // UI functions
  public void uiAddSpriteSystem(String name, String path, boolean interactable) {
    call(2000, name, path, interactable);
  }

  public void uiAddSpriteSystem(String name, String path) {
      call(2000, name, path, false);
  }
  
  public void uiUseSpriteSystem(String name) {
      call(2001, name);
  }
  
  public void uiSetSpriteSystemInteractable(String name, boolean interactable) {
      call(2002, name, interactable);
  }

  public void uiSprite(String name) {
      call(2003, name, name);
  }
  
  public void uiSprite(String name, String img) {
      call(2003, name, img);
  }
  
  public boolean uiButton(String name, String texture, String displayText) {
      return getBool(2004, name, texture, displayText);
  }
  
  public boolean uiButtonHover(String name) {
      return getBool(2005, name);
  }

  public boolean uiBasicButton(String display, float x, float y, float wi, float hi) {
      return getBool(2006, display, x, y, wi, hi);
  }

  public void uiLoadingIcon(float x, float y, float widthheight) {
      call(2007, x, y, widthheight);
  }

  public void uiUpdateSpriteSystems() {
      call(2008);
  }


  // Pixelrealm functions
  // First two are technically PR-related,
  // but since they're important they don't start with "PR"
  public String getPluginPath() {
      return getString(3000);
  }
  
  public String getPluginDir() {
      return fileDirectorify(fileGetDir(getPluginPath()));
  }
  
  public int getRunPoint() {
      return getInt(3001);
  }

  
  public void prPauseRefresher() {
      call(3002);
  }

  public void prResumeRefresher() {
      call(3003);
  }
  
  public void prPrompt(String title, String text, int appearDelay) {
      call(3004, title, text, appearDelay);
  }
  
  public void prPrompt(String title, String text) {
      call(3004, title, text, 0);
  }
  
  public void prPrompt(String text) {
      call(3004, "", text, 0);
  }
  
  public boolean prMenuShown() {
      return getBool(3005);
  }
  
  public void prCreateCustomMenu(String title, String backname, Runnable displayRunnable) {
      call(3006, title, backname, displayRunnable);
  }

  public void prCloseMenu() {
      call(3007);
  }

  public void soundPlay(String name, float vol) {
      call(4000, name, vol);
  }
  
  public void soundPlay(String name) {
      call(4000, name, 1f);
  }

  public void soundPlayOnce(String name) {
      call(4001, name);
  }

  public void soundPause(String name) {
      call(4002, name);
  }

  public void soundStop(String name) {
      call(4003, name);
  }

  public void soundLoop(String name) {
      call(4004, name);
  }

  public void soundSetVolume(String name, float vol) {
      call(4005, name, vol);
  }

  public void soundSetMasterVolume(float vol) {
      call(4006, vol);
  }

  public void soundSetMusicVolume(float vol) {
      call(4007, vol);
  }

  public void soundStreamMusic(String path) {
      call(4008, path);
  }

  public void soundStreamMusicWithFade(String path) {
      call(4009, path);
  }

  public void soundStopMusic() {
      call(4010);
  }

  public void soundPauseMusic() {
      call(4011);
  }

  public void soundContinueMusic() {
      call(4012);
  }

  public void soundFadeAndStopMusic() {
      call(4013);
  }

  public void soundSyncMusic(float pos) {
      call(4014, pos);
  }

  public float soundGetMusicDuration() {
      return getFloat(4015);
  }

  // Display functions
  public float displayWidth() {
      return getFloat(5000);
  }
  
  public float displayHeight() {
      return getFloat(5001);
  }
  
  public float displayDelta() {
      return getFloat(5002);
  }
  
  public float displayTime() {
      return getFloat(5003);
  }
  
  public float displayTimeSeconds() {
      return getFloat(5004);
  }
  
  public float displayGetUpperBarY() {
      return getFloat(5005);
  }

  public float displayGetLowerBarY() {
      return getFloat(5006);
  }
  
  public float displayLiveFPS() {
      return getFloat(5007);
  }
  
  public float displayImg(String name, float x, float y, float wi, float hi) {
      return getFloat(5008, name, x, y, wi, hi);
  }
  
  public float displayWidth(String name, float x, float y) {
      return getFloat(5009, name, x, y);
  }
  
  public float imgCentre(String name, float x, float y, float wi, float hi) {
      return getFloat(5010);
  }
  
  public float imgCentre(String name, float x, float y) {
      return getFloat(5011, name, x, y);
  }
  
  

  



// We need a start() and run() method here which is
// automatically inserted by the generator.

// when parsing this line is automatically replaced
// by plugin code.
[plugin_code]





  // Plugin-host communication methods
  private Runnable apiCall;
  private int apiOpCode = 0;
  private Object[] args = new Object[128];
  private Object ret;

  public int getCallOpCode() {
    return apiOpCode;
  }

  public Object[] getArgs() {
    return args;
  }

  public void setRet(Object ret) {
    this.ret = ret;
  }
  

  public void setup(PApplet p, Runnable api, PGraphics g) {
    this.app = p;
    this.apiCall = api;
    this.g = g;

    // Start doesn't exist in this file alone,
    // but should be there after generator processes
    // plugin.
    start();
  }

  public void run() {
      switch (getRunPoint()) {
            case MODE_PRESCENE:
                  runPrescene();
            break;
            case MODE_SCENE:
                  runScene();
            break;
            case MODE_POSTSCENE:
                  runPostscene();
            break;
            case MODE_UI:
                  runUI();
                  uiUpdateSpriteSystems();
            break;
      }
  }

  // Currently unused for now.
  public void runPostscene() {

  }
















  // Processing function abstraction
  
  public PGraphics createGraphics(int w, int h) {
        return app.createGraphics(w, h);
  }
  public PGraphics createGraphics(int w, int h, String renderer) {
        return app.createGraphics(w, h, renderer);
  }
  public PImage createImage(int w, int h, int format) {
        return app.createImage(w, h, format);
  }
  public void delay(int napTime) {
        app.delay(napTime);
  }
  public void link(String url) {
        app.link(url);
  }
  public void thread(String name) {
        app.thread(name);
  }
  public void save(String filename) {
        g.save(filename);
  }
  public void saveFrame() {
        app.saveFrame();
  }
  public void saveFrame(String filename) {
        app.saveFrame(filename);
  }
  public float random(float high) {
        return app.random(high);
  }
  public float randomGaussian() {
        return app.randomGaussian();
  }
  public float random(float low, float high) {
        return app.random(low, high);
  }
  public void randomSeed(long seed) {
        app.randomSeed(seed);
  }
  public int choice(int high) {
        return app.choice(high);
  }
  public int choice(int low, int high) {
        return app.choice(low, high);
  }
  
  // TODO: Replace with engine.noise() for improved efficiency
  public float noise(float x) {
        return app.noise(x);
  }
  public float noise(float x, float y) {
        return app.noise(x, y);
  }
  public float noise(float x, float y, float z) {
        return app.noise(x, y, z);
  }
  public void noiseDetail(int lod) {
        app.noiseDetail(lod);
  }
  public void noiseDetail(int lod, float falloff) {
        app.noiseDetail(lod, falloff);
  }
  public void noiseSeed(long seed) {
        app.noiseSeed(seed);
  }
  public PImage loadImage(String filename) {
        return app.loadImage(filename);
  }
  public PImage loadImage(String filename, String extension) {
        return app.loadImage(filename, extension);
  }
  public PImage requestImage(String filename) {
        return app.requestImage(filename);
  }
  public PImage requestImage(String filename, String extension) {
        return app.requestImage(filename, extension);
  }
  public XML loadXML(String filename) {
        return app.loadXML(filename);
  }
  public XML loadXML(String filename, String options) {
        return app.loadXML(filename, options);
  }
  public XML parseXML(String xmlString) {
        return app.parseXML(xmlString);
  }
  public XML parseXML(String xmlString, String options) {
        return app.parseXML(xmlString, options);
  }
  public boolean saveXML(XML xml, String filename) {
        return app.saveXML(xml, filename);
  }
  public boolean saveXML(XML xml, String filename, String options) {
        return app.saveXML(xml, filename, options);
  }
  public JSONObject parseJSONObject(String input) {
        return app.parseJSONObject(input);
  }
  public JSONObject loadJSONObject(String filename) {
        return app.loadJSONObject(filename);
  }
  public boolean saveJSONObject(JSONObject json, String filename) {
        return app.saveJSONObject(json, filename);
  }
  public boolean saveJSONObject(JSONObject json, String filename, String options) {
        return app.saveJSONObject(json, filename, options);
  }
  public JSONArray parseJSONArray(String input) {
        return app.parseJSONArray(input);
  }
  public JSONArray loadJSONArray(String filename) {
        return app.loadJSONArray(filename);
  }
  public boolean saveJSONArray(JSONArray json, String filename) {
        return app.saveJSONArray(json, filename);
  }
  public boolean saveJSONArray(JSONArray json, String filename, String options) {
        return app.saveJSONArray(json, filename, options);
  }
  public Table loadTable(String filename) {
        return app.loadTable(filename);
  }
  public Table loadTable(String filename, String options) {
        return app.loadTable(filename, options);
  }
  public boolean saveTable(Table table, String filename) {
        return app.saveTable(table, filename);
  }
  public boolean saveTable(Table table, String filename, String options) {
        return app.saveTable(table, filename, options);
  }
  public PFont loadFont(String filename) {
        return app.loadFont(filename);
  }
  public PFont createFont(String name, float size) {
        return app.createFont(name, size);
  }
  public PFont createFont(String name, float size, boolean smooth) {
        return app.createFont(name, size, smooth);
  }
  public void selectInput(String prompt, String callback) {
        app.selectInput(prompt, callback);
  }
  public void selectInput(String prompt, String callback, File file) {
        app.selectInput(prompt, callback, file);
  }
  public void selectOutput(String prompt, String callback) {
        app.selectOutput(prompt, callback);
  }
  public void selectOutput(String prompt, String callback, File file) {
        app.selectOutput(prompt, callback, file);
  }
  public void selectFolder(String prompt, String callback) {
        app.selectFolder(prompt, callback);
  }
  public void selectFolder(String prompt, String callback, File file) {
        app.selectFolder(prompt, callback, file);
  }
  public String[] listPaths(String path, String... options) {
        return app.listPaths(path, options);
  }
  public File[] listFiles(String path, String... options) {
        return app.listFiles(path, options);
  }
  public BufferedReader createReader(String filename) {
        return app.createReader(filename);
  }
  public PrintWriter createWriter(String filename) {
        return app.createWriter(filename);
  }
  public InputStream createInput(String filename) {
        return app.createInput(filename);
  }
  public InputStream createInputRaw(String filename) {
        return app.createInputRaw(filename);
  }
  public byte[] loadBytes(String filename) {
        return app.loadBytes(filename);
  }
  public String[] loadStrings(String filename) {
        return app.loadStrings(filename);
  }
  public OutputStream createOutput(String filename) {
        return app.createOutput(filename);
  }
  public boolean saveStream(String target, String source) {
        return app.saveStream(target, source);
  }
  public boolean saveStream(File target, String source) {
        return app.saveStream(target, source);
  }
  public boolean saveStream(String target, InputStream source) {
        return app.saveStream(target, source);
  }
  public void saveBytes(String filename, byte[] data) {
        app.saveBytes(filename, data);
  }
  public void saveStrings(String filename, String[] data) {
        app.saveStrings(filename, data);
  }
  public String sketchPath() {
        return app.sketchPath();
  }
  public String sketchPath(String where) {
        return app.sketchPath(where);
  }
  public File sketchFile(String where) {
        return app.sketchFile(where);
  }
  public String savePath(String where) {
        return app.savePath(where);
  }
  public File saveFile(String where) {
        return app.saveFile(where);
  }
  public String dataPath(String where) {
        return app.dataPath(where);
  }
  public File dataFile(String where) {
        return app.dataFile(where);
  }
  public int color(int gray) {
       return app.color(gray);
  }
  public int color(float fgray) {
       return app.color(fgray);
  }
  public int color(int gray, int alpha) {
       return app.color(gray, alpha);
  }
  public int color(float fgray, float falpha) {
       return app.color(fgray, falpha);
  }
  public int color(int v1, int v2, int v3) {
       return app.color(v1, v2, v3);
  }
  public int color(int v1, int v2, int v3, int alpha) {
       return app.color(v1, v2, v3, alpha);
  }
  public int color(float v1, float v2, float v3) {
       return app.color(v1, v2, v3);
  }
  public int color(float v1, float v2, float v3, float alpha) {
       return app.color(v1, v2, v3, alpha);
  }
  public int lerpColor(int c1, int c2, float amt) {
        return app.lerpColor(c1, c2, amt);
  }
  public PGraphics beginRaw(String renderer, String filename) {
        return app.beginRaw(renderer, filename);
  }
  public void beginRaw(PGraphics rawGraphics) {
        app.beginRaw(rawGraphics);
  }
  public void endRaw() {
        app.endRaw();
  }
  public void loadPixels() {
        g.loadPixels();
  }
  public void updatePixels() {
        g.updatePixels();
  }
  public void updatePixels(int x1, int y1, int x2, int y2) {
        g.updatePixels(x1, y1, x2, y2);
  }
  public PGL beginPGL() {
        return g.beginPGL();
  }
  public void endPGL() {
        g.endPGL();
  }
  public void flush() {
        g.flush();
  }
  public void hint(int which) {
        g.hint(which);
  }
  public void beginShape() {
        g.beginShape();
  }
  public void beginShape(int kind) {
        g.beginShape(kind);
  }
  public void edge(boolean edge) {
        g.edge(edge);
  }
  public void normal(float nx, float ny, float nz) {
        g.normal(nx, ny, nz);
  }
  public void attribPosition(String name, float x, float y, float z) {
        g.attribPosition(name, x, y, z);
  }
  public void attribNormal(String name, float nx, float ny, float nz) {
        g.attribNormal(name, nx, ny, nz);
  }
  public void attribColor(String name, int c) {
        g.attribColor(name, c);
  }
  public void attrib(String name, float... values) {
        g.attrib(name, values);
  }
  public void attrib(String name, int... values) {
        g.attrib(name, values);
  }
  public void attrib(String name, boolean... values) {
        g.attrib(name, values);
  }
  public void textureMode(int mode) {
        g.textureMode(mode);
  }
  public void textureWrap(int wrap) {
        g.textureWrap(wrap);
  }
  public void texture(PImage image) {
        g.texture(image);
  }
  public void noTexture() {
        g.noTexture();
  }
  public void vertex(float x, float y) {
        g.vertex(x, y);
  }
  public void vertex(float x, float y, float z) {
        g.vertex(x, y, z);
  }
  public void vertex(float[] v) {
        g.vertex(v);
  }
  public void vertex(float x, float y, float u, float v) {
        g.vertex(x, y, u, v);
  }
  public void vertex(float x, float y, float z, float u, float v) {
        g.vertex(x, y, z, u, v);
  }
  public void beginContour() {
        g.beginContour();
  }
  public void endContour() {
        g.endContour();
  }
  public void endShape() {
        g.endShape();
  }
  public void endShape(int mode) {
        g.endShape(mode);
  }
  public PShape loadShape(String filename) {
        return g.loadShape(filename);
  }
  public PShape loadShape(String filename, String options) {
        return g.loadShape(filename, options);
  }
  public PShape createShape() {
        return g.createShape();
  }
  public PShape createShape(int type) {
        return g.createShape(type);
  }
  public PShape createShape(int kind, float... p) {
        return g.createShape(kind, p);
  }
  public PShader loadShader(String fragFilename) {
        return g.loadShader(fragFilename);
  }
  public PShader loadShader(String fragFilename, String vertFilename) {
        return g.loadShader(fragFilename, vertFilename);
  }
  public void shader(PShader shader) {
        g.shader(shader);
  }
  public void shader(PShader shader, int kind) {
        g.shader(shader, kind);
  }
  public void resetShader() {
        g.resetShader();
  }
  public void resetShader(int kind) {
        g.resetShader(kind);
  }
  public void filter(PShader shader) {
        g.filter(shader);
  }
  public void clip(float a, float b, float c, float d) {
        g.clip(a, b, c, d);
  }
  public void noClip() {
        g.noClip();
  }
  public void blendMode(int mode) {
        g.blendMode(mode);
  }
  public void curveVertex(float x, float y) {
        g.curveVertex(x, y);
  }
  public void curveVertex(float x, float y, float z) {
        g.curveVertex(x, y, z);
  }
  public void point(float x, float y) {
        g.point(x, y);
  }
  public void point(float x, float y, float z) {
        g.point(x, y, z);
  }
  public void line(float x1, float y1, float x2, float y2) {
        g.line(x1, y1, x2, y2);
  }
  public void rectMode(int mode) {
        g.rectMode(mode);
  }
  public void rect(float a, float b, float c, float d) {
        g.rect(a, b, c, d);
  }
  public void rect(float a, float b, float c, float d, float r) {
        g.rect(a, b, c, d, r);
  }
  public void square(float x, float y, float extent) {
        g.square(x, y, extent);
  }
  public void ellipseMode(int mode) {
        g.ellipseMode(mode);
  }
  public void ellipse(float a, float b, float c, float d) {
        g.ellipse(a, b, c, d);
  }
  public void circle(float x, float y, float extent) {
        g.circle(x, y, extent);
  }
  public void box(float size) {
        g.box(size);
  }
  public void box(float w, float h, float d) {
        g.box(w, h, d);
  }
  public void sphereDetail(int res) {
        g.sphereDetail(res);
  }
  public void sphereDetail(int ures, int vres) {
        g.sphereDetail(ures, vres);
  }
  public void sphere(float r) {
        g.sphere(r);
  }
  public float bezierPoint(float a, float b, float c, float d, float t) {
        return g.bezierPoint(a, b, c, d, t);
  }
  public float bezierTangent(float a, float b, float c, float d, float t) {
        return g.bezierTangent(a, b, c, d, t);
  }
  public void bezierDetail(int detail) {
        g.bezierDetail(detail);
  }
  public float curvePoint(float a, float b, float c, float d, float t) {
        return g.curvePoint(a, b, c, d, t);
  }
  public float curveTangent(float a, float b, float c, float d, float t) {
        return g.curveTangent(a, b, c, d, t);
  }
  public void curveDetail(int detail) {
        g.curveDetail(detail);
  }
  public void curveTightness(float tightness) {
        g.curveTightness(tightness);
  }
  public void imageMode(int mode) {
        g.imageMode(mode);
  }
  public void image(PImage img, float a, float b) {
        g.image(img, a, b);
  }
  public void image(PImage img, float a, float b, float c, float d) {
        g.image(img, a, b, c, d);
  }
  public void shapeMode(int mode) {
        g.shapeMode(mode);
  }
  public void shape(PShape shape) {
        g.shape(shape);
  }
  public void shape(PShape shape, float x, float y) {
        g.shape(shape, x, y);
  }
  public void shape(PShape shape, float a, float b, float c, float d) {
        g.shape(shape, a, b, c, d);
  }
  public void textAlign(int alignX) {
        g.textAlign(alignX);
  }
  public void textAlign(int alignX, int alignY) {
        g.textAlign(alignX, alignY);
  }
  public float textAscent() {
        return g.textAscent();
  }
  public float textDescent() {
        return g.textDescent();
  }
  public void textFont(PFont which) {
        g.textFont(which);
  }
  public void textFont(PFont which, float size) {
        g.textFont(which, size);
  }
  public void textLeading(float leading) {
        g.textLeading(leading);
  }
  public void textMode(int mode) {
        g.textMode(mode);
  }
  public void textSize(float size) {
        g.textSize(size);
  }
  public float textWidth(char c) {
        return g.textWidth(c);
  }
  public float textWidth(String str) {
        return g.textWidth(str);
  }
  public float textWidth(char[] chars, int start, int length) {
        return g.textWidth(chars, start, length);
  }
  public void text(char c, float x, float y) {
        g.text(c, x, y);
  }
  public void text(char c, float x, float y, float z) {
        g.text(c, x, y, z);
  }
  public void text(String str, float x, float y) {
        g.text(str, x, y);
  }
  public void text(char[] chars, int start, int stop, float x, float y) {
        g.text(chars, start, stop, x, y);
  }
  public void text(String str, float x, float y, float z) {
        g.text(str, x, y, z);
  }
  public void text(String str, float x1, float y1, float x2, float y2) {
        g.text(str, x1, y1, x2, y2);
  }
  public void text(int num, float x, float y) {
        g.text(num, x, y);
  }
  public void text(int num, float x, float y, float z) {
        g.text(num, x, y, z);
  }
  public void text(float num, float x, float y) {
        g.text(num, x, y);
  }
  public void text(float num, float x, float y, float z) {
        g.text(num, x, y, z);
  }
  public void push() {
        g.push();
  }
  public void pop() {
        g.pop();
  }
  public void pushMatrix() {
        g.pushMatrix();
  }
  public void popMatrix() {
        g.popMatrix();
  }
  public void translate(float x, float y) {
        g.translate(x, y);
  }
  public void translate(float x, float y, float z) {
        g.translate(x, y, z);
  }
  public void rotate(float angle) {
        g.rotate(angle);
  }
  public void rotateX(float angle) {
        g.rotateX(angle);
  }
  public void rotateY(float angle) {
        g.rotateY(angle);
  }
  public void rotateZ(float angle) {
        g.rotateZ(angle);
  }
  public void rotate(float angle, float x, float y, float z) {
        g.rotate(angle, x, y, z);
  }
  public void scale(float s) {
        g.scale(s);
  }
  public void scale(float x, float y) {
        g.scale(x, y);
  }
  public void scale(float x, float y, float z) {
        g.scale(x, y, z);
  }
  public void shearX(float angle) {
        g.shearX(angle);
  }
  public void shearY(float angle) {
        g.shearY(angle);
  }
  public void resetMatrix() {
        g.resetMatrix();
  }
  public void applyMatrix(PMatrix source) {
        g.applyMatrix(source);
  }
  public void applyMatrix(PMatrix2D source) {
        g.applyMatrix(source);
  }
  public void applyMatrix(PMatrix3D source) {
        g.applyMatrix(source);
  }
  public PMatrix getMatrix() {
        return g.getMatrix();
  }
  public PMatrix2D getMatrix(PMatrix2D target) {
        return g.getMatrix(target);
  }
  public PMatrix3D getMatrix(PMatrix3D target) {
        return g.getMatrix( target);
  }
  public void setMatrix(PMatrix source) {
        g.setMatrix(source);
  }
  public void setMatrix(PMatrix2D source) {
        g.setMatrix(source);
  }
  public void setMatrix(PMatrix3D source) {
        g.setMatrix(source);
  }
  public void printMatrix() {
        g.printMatrix();
  }
  public void beginCamera() {
        g.beginCamera();
  }
  public void endCamera() {
        g.endCamera();
  }
  public void camera() {
        g.camera();
  }
  public void printCamera() {
        g.printCamera();
  }
  public void ortho() {
        g.ortho();
  }
  public void perspective() {
        g.perspective();
  }
  public void perspective(float fovy, float aspect, float zNear, float zFar) {
        g.perspective(fovy, aspect, zNear, zFar);
  }
  public void printProjection() {
        g.printProjection();
  }
  public float screenX(float x, float y) {
        return g.screenX(x, y);
  }
  public float screenY(float x, float y) {
        return g.screenY(x, y);
  }
  public float screenX(float x, float y, float z) {
        return g.screenX(x, y, z);
  }
  public float screenY(float x, float y, float z) {
        return g.screenY(x, y, z);
  }
  public float screenZ(float x, float y, float z) {
        return g.screenZ(x, y, z);
  }
  public float modelX(float x, float y, float z) {
        return g.modelX(x, y, z);
  }
  public float modelY(float x, float y, float z) {
        return g.modelY(x, y, z);
  }
  public float modelZ(float x, float y, float z) {
        return g.modelZ(x, y, z);
  }
  public void pushStyle() {
        g.pushStyle();
  }
  public void popStyle() {
        g.popStyle();
  }
  public void style(PStyle s) {
        g.style(s);
  }
  public void strokeWeight(float weight) {
        g.strokeWeight(weight);
  }
  public void strokeJoin(int join) {
        g.strokeJoin(join);
  }
  public void strokeCap(int cap) {
        g.strokeCap(cap);
  }
  public void noStroke() {
        g.noStroke();
  }
  public void stroke(int rgb) {
        g.stroke(rgb);
  }
  public void stroke(int rgb, float alpha) {
        g.stroke(rgb, alpha);
  }
  public void stroke(float gray) {
        g.stroke(gray);
  }
  public void stroke(float gray, float alpha) {
        g.stroke(gray, alpha);
  }
  public void stroke(float v1, float v2, float v3) {
        g.stroke(v1, v2, v3);
  }
  public void stroke(float v1, float v2, float v3, float alpha) {
        g.stroke(v1, v2, v3, alpha);
  }
  public void noTint() {
        g.noTint();
  }
  public void tint(int rgb) {
        g.tint(rgb);
  }
  public void tint(int rgb, float alpha) {
        g.tint(rgb, alpha);
  }
  public void tint(float gray) {
        g.tint(gray);
  }
  public void tint(float gray, float alpha) {
        g.tint(gray, alpha);
  }
  public void tint(float v1, float v2, float v3) {
        g.tint(v1, v2, v3);
  }
  public void tint(float v1, float v2, float v3, float alpha) {
        g.tint(v1, v2, v3, alpha);
  }
  public void noFill() {
        g.noFill();
  }
  public void fill(int rgb) {
        g.fill(rgb);
  }
  public void fill(int rgb, float alpha) {
        g.fill(rgb, alpha);
  }
  public void fill(float gray) {
        g.fill(gray);
  }
  public void fill(float gray, float alpha) {
        g.fill(gray, alpha);
  }
  public void fill(float v1, float v2, float v3) {
        g.fill(v1, v2, v3);
  }
  public void fill(float v1, float v2, float v3, float alpha) {
        g.fill(v1, v2, v3, alpha);
  }
  public void ambient(int rgb) {
        g.ambient(rgb);
  }
  public void ambient(float gray) {
        g.ambient(gray);
  }
  public void ambient(float v1, float v2, float v3) {
        g.ambient(v1, v2, v3);
  }
  public void specular(int rgb) {
        g.specular(rgb);
  }
  public void specular(float gray) {
        g.specular(gray);
  }
  public void specular(float v1, float v2, float v3) {
        g.specular(v1, v2, v3);
  }
  public void shininess(float shine) {
        g.shininess(shine);
  }
  public void emissive(int rgb) {
        g.emissive(rgb);
  }
  public void emissive(float gray) {
        g.emissive(gray);
  }
  public void emissive(float v1, float v2, float v3) {
        g.emissive(v1, v2, v3);
  }
  public void lights() {
        g.lights();
  }
  public void noLights() {
        g.noLights();
  }
  public void ambientLight(float v1, float v2, float v3) {
        g.ambientLight(v1, v2, v3);
  }
  public void lightFalloff(float constant, float linear, float quadratic) {
        g.lightFalloff(constant, linear, quadratic);
  }
  public void lightSpecular(float v1, float v2, float v3) {
        g.lightSpecular(v1, v2, v3);
  }
  public void background(int rgb) {
        g.background(rgb);
  }
  public void background(int rgb, float alpha) {
        g.background(rgb, alpha);
  }
  public void background(float gray) {
        g.background(gray);
  }
  public void background(float gray, float alpha) {
        g.background(gray, alpha);
  }
  public void background(float v1, float v2, float v3) {
        g.background(v1, v2, v3);
  }
  public void background(float v1, float v2, float v3, float alpha) {
        g.background(v1, v2, v3, alpha);
  }
  public void clear() {
        g.clear();
  }
  public void background(PImage image) {
        g.background(image);
  }
  public void colorMode(int mode) {
        g.colorMode(mode);
  }
  public void colorMode(int mode, float max) {
        g.colorMode(mode, max);
  }
  public void colorMode(int mode, float max1, float max2, float max3) {
        g.colorMode(mode, max1, max2, max3);
  }
  public float alpha(int rgb) {
        return g.alpha(rgb);
  }
  public float red(int rgb) {
        return g.red(rgb);
  }
  public float green(int rgb) {
        return g.green(rgb);
  }
  public float blue(int rgb) {
        return g.blue(rgb);
  }
  public float hue(int rgb) {
        return g.hue(rgb);
  }
  public float saturation(int rgb) {
        return g.saturation(rgb);
  }
  public float brightness(int rgb) {
        return g.brightness(rgb);
  }
  public void checkAlpha() {
        g.checkAlpha();
  }
  public int get(int x, int y) {
        return g.get(x, y);
  }
  public PImage get(int x, int y, int w, int h) {
        return g.get(x, y, w, h);
  }
  public PImage get() {
        return g.get();
  }
  public PImage copy() {
        return g.copy();
  }
  public void set(int x, int y, int c) {
        g.set(x, y, c);
  }
  public void set(int x, int y, PImage img) {
        g.set(x, y, img);
  }
  public void mask(PImage img) {
        g.mask(img);
  }
  public void filter(int kind) {
        g.filter(kind);
  }
  public void filter(int kind, float param) {
        g.filter(kind, param);
  }

  public float sin(float d) {
      return app.sin(d);
  }
  public float cos(float d) {
      return app.cos(d);
  }
  public float tan(float d) {
      return app.tan(d);
  }

  public int hour() {
      return PApplet.hour();
  }
  public int minute() {
      return PApplet.minute();
  }
  public int second() {
      return PApplet.second();
  }
  public int day() {
      return PApplet.day();
  }
  public int month() {
      return PApplet.month();
  }
  public int year() {
      return PApplet.year();
  }
}