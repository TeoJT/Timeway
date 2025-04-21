import java.util.Base64;
import de.humatic.dsj.DSCapture;
import processing.video.Capture;
//import java.awt.image.BufferedImage;
import java.util.concurrent.atomic.AtomicInteger;

class CameraException extends RuntimeException {};

abstract class EditorCapture {
  public int width, height;
  protected TWEngine engine;
  
  public AtomicBoolean ready = new AtomicBoolean(false);
  public AtomicBoolean error = new AtomicBoolean(false);
  public AtomicInteger errorCode = new AtomicInteger(0);
  public int selectedCamera = 0;
  
  public abstract void setup();
  public abstract void turnOffCamera();
  public abstract void switchNextCamera();
  public abstract PImage updateImage();
}

class PCapture extends EditorCapture {
  
  private String[] cameraDevices = null;
  private Capture capture = null;
  private PImage currCapture = null;
  
  public PCapture(TWEngine e) {
    ready.set(false);
    error.set(false);
    engine = e;
    currCapture = engine.display.errorImg;
  }
  
  
  public void setup() {
    ready.set(false);
    error.set(false);
    
    try {
      cameraDevices = Capture.list();
      
      if (cameraDevices.length <= 0) {
          error.set(true);
          errorCode.set(Editor.ERR_NO_CAMERA_DEVICES);
          return;
      }
      
      if (cameraDevices == null) {
        //engine.console.log("Unable to get cameras, but I'll try to start default camera anyway...");
        
        //boolean failed = false;
        //try {
        //  capture = new Capture(engine.app);
          
        //  if (capture == null) {
        //    failed = true;
        //  }
        //}
        //catch (Exception e) {
        //  failed = true;
        //}
        
        //if (failed) {
        //  engine.console.warn("I tried. Unable to start default camera.");
        //  error.set(true);
        //  errorCode.set(Editor.ERR_UNKNOWN);
        //  return;
        //}
        //// At this point it has been successful so spoof
        //// camera device
        //cameraDevices = new String[1];
        //cameraDevices[0] = "Unknown device";
        
        // TODO: at least try the default camera
        error.set(true);
        errorCode.set(Editor.ERR_UNKNOWN);
        return;
      }
    }
    catch (Exception e) {
      error.set(true);
      errorCode.set(Editor.ERR_UNKNOWN);
      return;
    }
    
    selectedCamera = (int)engine.sharedResources.get("lastusedcamera", 0);
    activateCamera();
    
    ready.set(true);
  }
  
  // Activate currently selected camera, switching to next camera if it doesn't work
  private void activateCamera() {
    boolean success = false;
    int originalSelection = selectedCamera;
    
    while (!success) {
      try {
        // Activate the next camera in the list.
        // Some cameras may not work. Skip them if they don't work. If none of them work, throw an error.
        capture = new Capture(engine.app, cameraDevices[selectedCamera]);
        success = true;
      }
      catch (DSJException e) {
        success = false; // Keep trying
        // Increase index by 1, reset to 0 if we're at end of list.
        selectedCamera = ((selectedCamera+1)%(cameraDevices.length));
        
        // If we're back where we started, then there's been a problem :(
        if (originalSelection == selectedCamera) {
          error.set(true);
          errorCode.set(Editor.ERR_FAILED_TO_SWITCH);
          return;
        }
      }
    }
    
    capture.start();
    capture.read();
    
    width = capture.width;
    height = capture.height;
  }
  
  
  public PImage updateImage() {
    if (capture == null) {
      engine.console.bugWarnOnce("No capture available.");
      return engine.display.errorImg;
    }
    if (capture.available()) {
      capture.read();
      currCapture = capture;
    }
    return currCapture;
  }
  
  public void switchNextCamera() {
    // Only run if a camera isn't currently being setup.
    if (ready.compareAndSet(true, false)) {
      if (cameraDevices == null) return;
      if (cameraDevices.length == 0) return;
      
      // Turn off last used camera.
      turnOffCamera();
      
      // Increase index by 1, reset to 0 if we're at end of list.
      selectedCamera = ((selectedCamera+1)%(cameraDevices.length));
      activateCamera();
      
      ready.set(true);
    }
  }
  
  public void turnOffCamera() {
    if (capture != null) capture.stop();
  }
  
  
}

class DCapture extends EditorCapture implements java.beans.PropertyChangeListener {
  private DSCapture capture;
  public final int DEVICE_NONE = -1;
  public final int DEVICE_CAMERA     = 0;
  public final int DEVICE_MICROPHONE = 1;
  
  public ArrayList<DSFilterInfo> cameraDevices;
 
  public DCapture(TWEngine e) {
    ready.set(false);
    error.set(false);
    engine = e;
  }
  
  // Lmao don't care I'm using Java 8 in 2023 dangit
  @SuppressWarnings("deprecation")
  public void setup() {
    ready.set(false);
    error.set(false);
    
    try {
      DSFilterInfo[][] dsi = DSCapture.queryDevices();
      cameraDevices = new ArrayList<DSFilterInfo>();
      
      for (int y = 0; y < dsi.length; y++) {
        for (int x = 0; x < dsi[y].length; x++) {
          println("("+x+", "+y+") "+dsi[y][x].getName(), dsi[y][x].getType());
          if (dsi[y][x].getType() == DEVICE_CAMERA)
            cameraDevices.add(dsi[y][x]);
        }
      }
      
      if (cameraDevices.size() <= 0) {
        error.set(true);
        errorCode.set(Editor.ERR_NO_CAMERA_DEVICES);
        return;
      }
    }
    catch (UnsatisfiedLinkError e) {
        error.set(true);
        errorCode.set(Editor.ERR_UNSUPPORTED_SYSTEM);
        return;
    }
    catch (NoClassDefFoundError e) {
        error.set(true);
        errorCode.set(Editor.ERR_UNSUPPORTED_SYSTEM);
        return;
    }
    catch (Exception e) {
        error.set(true);
        errorCode.set(Editor.ERR_UNKNOWN);
        return;
    }
    
    
    selectedCamera = (int)engine.sharedResources.get("lastusedcamera", 0);
    activateCamera();
    
    ready.set(true);
  }
  
  public void turnOffCamera() {
    if (capture != null) capture.dispose();
  }
  
  // Activate currently selected camera, switching to next camera if it doesn't work
  private void activateCamera() {
    boolean success = false;
    int originalSelection = selectedCamera;
    
    while (!success) {
      try {
        // Activate the next camera in the list.
        // Some cameras may not work. Skip them if they don't work. If none of them work, throw an error.
        capture = new DSCapture(DSFiltergraph.DD7, cameraDevices.get(selectedCamera), false, DSFilterInfo.doNotRender(), this);
        success = true;
      }
      catch (DSJException e) {
        success = false; // Keep trying
        // Increase index by 1, reset to 0 if we're at end of list.
        selectedCamera = ((selectedCamera+1)%(cameraDevices.size()));
        
        // If we're back where we started, then there's been a problem :(
        if (originalSelection == selectedCamera) {
          error.set(true);
          errorCode.set(Editor.ERR_FAILED_TO_SWITCH);
          return;
        }
      }
    }
    
    width =  getDCaptureWidth(capture);
    height = getDCaptureHeight(capture);
  }
  
  public void switchNextCamera() {
    // Only run if a camera isn't currently being setup.
    if (ready.compareAndSet(true, false)) {
      if (cameraDevices == null) return;
      if (cameraDevices.size() == 0) return;
      
      // Turn off last used camera.
      turnOffCamera();
      
      // Increase index by 1, reset to 0 if we're at end of list.
      selectedCamera = ((selectedCamera+1)%(cameraDevices.size()));
      activateCamera();
      
      ready.set(true);
    }
  }
 
  public PImage updateImage() {
    return getDCaptureImage(capture);
  }
 
  public void propertyChange(java.beans.PropertyChangeEvent e) {
    switch (DSJUtils.getEventType(e)) {
    }
  }
}


















public class Editor extends Screen {
    private boolean showGUI = false;
    private float upperbarExpand = 0;
    protected SpriteSystemPlaceholder gui;
    private SpriteSystemPlaceholder placeableSprites;
    protected HashMap<String, Placeable> placeableset;
    private ArrayList<String> imagesInEntry;  // This is so that we can know what to remove when we exit this screen.
    private Placeable editingPlaceable = null;
    private EditorCapture camera;
    private String entryName;
    private String entryPath;
    private String entryDir;
    private color selectedColor = color(255, 255, 255);
    private float selectedFontSize = 20;
    private TextPlaceable entryNameText;
    private boolean cameraMode = false;
    private boolean autoScaleDown = false;
    private boolean changesMade = false;
    private int upperBarDrop = INITIALISE_DROP_ANIMATION;
    private PGraphics canvas;
    private float canvasScale;
    private JSONArray loadedJsonArray;
    protected boolean readOnly = false;
    
    // X goes unused for now but could be useful later.
    private float extentX = 0.;
    private float extentY = 0.;
    private float scrollLimitY = 0.;
    private float prevMouseY = 0.;
    private float scrollVelocity = 0.;
    
    public static final int INITIALISE_DROP_ANIMATION = 0;
    public static final int CAMERA_ON_ANIMATION = 1;
    public static final int CAMERA_OFF_ANIMATION = 2;
    
    final String RENAMEABLE_NAME         = "title";                // The name of the sprite object which is used to rename entries
    final float  EXPAND_HITBOX           = 10;                     // For the (unused) ERS system to slightly increase the erase area to prevent glitches
    final String DEFAULT_FONT            = "Typewriter";           // Default font for entries
    final float  STANDARD_FONT_SIZE      = 64;                     // You get the idea
          float  DEFAULT_FONT_SIZE       = 30;
    final color  DEFAULT_FONT_COLOR      = color(255, 255, 255);
    final float  MIN_FONT_SIZE           = 8.;
    final float  UPPER_BAR_DROP_WEIGHT   = 150;                    
    final int    SCALE_DOWN_SIZE         = 512;
    final float  SCROLL_LIMIT            = 600.;
    
    final color BACKGROUND_COLOR = 0xFF0f0f0e;
    
    // Camera errors
    public final static int ERR_UNKNOWN = 0;
    public final static int ERR_NO_CAMERA_DEVICES = 1;
    public final static int ERR_FAILED_TO_SWITCH = 2;
    public final static int ERR_UNSUPPORTED_SYSTEM = 3;


    

    
    
    private void textOptions() {
      String[] labels = new String[2];
      Runnable[] actions = new Runnable[2];
      
      labels[0] = "Copy";
      actions[0] = new Runnable() {public void run() {
          
          if (editingPlaceable != null) {
            if (editingPlaceable instanceof TextPlaceable) {
              TextPlaceable t = (TextPlaceable)editingPlaceable;
              boolean success = clipboard.copyString(t.text);
              if (success)
                console.log("Copied!");
            }
          }
          
      }};
      
      
      labels[1] = "Delete";
      actions[1] = new Runnable() {public void run() {
          
          if (editingPlaceable != null) {
            placeableset.remove(editingPlaceable.id);
            changesMade = true;
          }
          
      }};
      
      
      
      ui.createOptionsMenu(labels, actions);
    }
    
    
    private void imageOptions() {
      
      String[] labels = new String[3];
      Runnable[] actions = new Runnable[3];
      
      labels[0] = "Copy";
      actions[0] = new Runnable() {public void run() {
          
        console.log("Copying images to clipboard not supported yet, sorry!");
          
      }};
      
      
      labels[1] = "Save";
      actions[1] = new Runnable() {public void run() {
          
        if (editingPlaceable != null && editingPlaceable instanceof ImagePlaceable) {
          ImagePlaceable im = (ImagePlaceable)editingPlaceable;
          file.selectOutput("Save image...", im.getImage());
        }
          
      }};
      
      labels[2] = "Delete";
      actions[2] = new Runnable() {public void run() {
          
        if (editingPlaceable != null) {
          placeableset.remove(editingPlaceable.id);
          changesMade = true;
        }
          
      }};
      
      ui.createOptionsMenu(labels, actions);
    }
    
    
    private void blankOptions() {
      String[] labels = new String[6];
      Runnable[] actions = new Runnable[6];
      
      labels[0] = "New input field";
      actions[0] = new Runnable() {public void run() {
        insertText("Input field", engine.mouseX(), engine.mouseY()-20, TYPE_INPUT_FIELD);
      }};
      
      
      labels[1] = "New boolean field";
      actions[1] = new Runnable() {public void run() {
        insertText("Boolean field", engine.mouseX(), engine.mouseY()-20, TYPE_BOOLEAN_FIELD);
      }};
      
      labels[2] = "New slider field";
      actions[2] = new Runnable() {public void run() {
        insertText("Slider field", engine.mouseX(), engine.mouseY()-20, TYPE_SLIDER_FIELD);
      }};
      
      
      labels[3] = "New int slider field";
      actions[3] = new Runnable() {public void run() {
        insertText("Int slider field", engine.mouseX(), engine.mouseY()-20, TYPE_SLIDERINT_FIELD);
      }};
      
      labels[4] = "New options menu";
      actions[4] = new Runnable() {public void run() {
        insertText("Options menu field", engine.mouseX(), engine.mouseY()-20, TYPE_OPTIONS_FIELD);
      }};
      
      labels[5] = "New button";
      actions[5] = new Runnable() {public void run() {
        insertText("Button", engine.mouseX(), engine.mouseY()-20, TYPE_BUTTON);
      }};
      
      ui.createOptionsMenu(labels, actions);
    }
    
    
    private String generateRandomID() {
      String id = nf(random(0, 99999999), 8, 0);
      while (placeableset.containsKey(id)) {
        id = nf(random(0, 99999999), 8, 0);
      }
      return id;
    }
    
    protected Placeable get(String name) {
      if (!placeableset.containsKey(name)) {
        console.warn("Setting "+name+" not found.");
        return new Placeable("null");
      }
      return placeableset.get(name);
    }


    public class Placeable {
        public SpriteSystemPlaceholder.Sprite sprite;
        public String id;
        public boolean visible = true;

        //public Placeable() {
        //    String name = generateRandomID();
        //    placeableSprites.placeable(name);
        //    sprite = placeableSprites.getSprite(name);
            
        //    if (!placeableset.containsValue(this)) {
        //        placeableset.put(name, this);
        //    }
        //}
        
        public Placeable(String id) {
            this.id = id;
            placeableSprites.placeable(id);
            sprite = placeableSprites.getSprite(id);
            
            if (!placeableset.containsValue(this)) {
                placeableset.put(id, this);
            }
        }
        
        
        protected boolean placeableSelected() {
          if (input.mouseY() < myUpperBarWeight) return false;
          return (sprite.mouseWithinHitbox() && placeableSprites.selectedSprite == sprite && input.primaryDown && !input.mouseMoved);
        }

        protected boolean placeableSelectedSecondary() {
          return (sprite.mouseWithinHitbox() && placeableSprites.selectedSprite == sprite && input.secondaryDown && !input.mouseMoved);
        }
        
        
        @SuppressWarnings("unused")
        public void save(JSONObject json) {
            console.bugWarn("Missing code! Couldn't save unknown placeable: "+this.toString());
        }

        
        // Just a placeholder display for the base class.
        // You shouldn't use super.display() for inherited classes.
        public void display() {
            canvas.fill(255, 0, 0);
            canvas.rect(sprite.xpos, sprite.ypos, sprite.wi, sprite.hi);
        }

        public void update() {
            sprite.offmove(0, input.scrollOffset);
            if (visible) {
              display();
            }
            placeableSprites.placeable(sprite);
        }
    }


    public class TextPlaceable extends Placeable {
        public String text = "Sample text";
        public float fontSize = DEFAULT_FONT_SIZE;
        public PFont fontStyle;
        public color textColor = DEFAULT_FONT_COLOR;
        public float lineSpacing = 8;
        int newlines = 0;

        public TextPlaceable(String name) {
            super(name);
            sprite.allowResizing = false;
            sprite.setImg("nothing");
            fontStyle = display.getFont(DEFAULT_FONT);
            selectedFontSize = this.fontSize;
        }

        protected boolean editing() {
            if (editingPlaceable == this) {
              changesMade = true;
            }
            return editingPlaceable == this;
        }

        protected int countNewlines(String t) {
            int count = 0;
            for (int i = 0; i < t.length(); i++) {
                if (t.charAt(i) == '\n') {
                    count++;
                }
            }
            newlines = count;
            return count;
        }

        public void display() {
            canvas.pushMatrix();
            canvas.scale(canvasScale);
            canvas.fill(textColor);
            canvas.textAlign(LEFT, TOP);
            canvas.textFont(fontStyle, fontSize);
            canvas.textLeading(fontSize+lineSpacing);

            String displayText = "";
            if (editing()) {
                displayText = input.keyboardMessageDisplay();
            }
            else {
                displayText = text;
            }
            canvas.text(displayText, sprite.xpos, sprite.ypos-canvas.textDescent()+EXPAND_HITBOX/2+10);
            canvas.popMatrix();
        }
        
        public void updateDimensions() {
          placeableSprites.hackSpriteDimensions(sprite, int(app.textWidth(text)), int((app.textAscent()+app.textDescent()+lineSpacing)*(countNewlines(text)+1) + EXPAND_HITBOX));
        }
        
        public void save(JSONObject obj) {
          this.sprite.offmove(0,0);
          obj.setString("ID", this.sprite.name);
          obj.setInt("type", TYPE_TEXT);
          obj.setInt("x", int(this.sprite.getX()));
          obj.setInt("y", int(this.sprite.getY()));
          obj.setFloat("size", this.fontSize);
          obj.setString("text", this.text);
          obj.setInt("color", this.textColor);
        }

        public void update() {
          
            //fontSize = (float)sprite.getWidth()/40.;
            app.textFont(fontStyle, fontSize);
            app.textLeading(fontSize+lineSpacing);

            // The famous hitbox hack where we set the hitbox to the text size.
            // For width we simply check the textWidth with the handy function.
            // For text height we account for the ascent/descent thing, expand hitbox to make it slightly larger
            // and times it by the number of newlines.
            
            if (sprite.isSelected()) {
              updateDimensions();
            }
            
            if (editing()) {
                input.addNewlineWhenEnterPressed = true;
                // Oh my god if this bug fix doesn't work I'm gonna lose it
                // DO NOT allow the command prompt to appear by pressing '/' and make the current text we're writing disappear
                // while writing text
                engine.allowShowCommandPrompt = false;
                text = input.keyboardMessage;
            }
            
            if (placeableSelected() || placeableSelectedSecondary()) {
                engine.allowShowCommandPrompt = false;
                editingPlaceable = this;
                input.keyboardMessage = text;
                input.cursorX = input.keyboardMessage.length();
                selectedFontSize = this.fontSize;
            }
                // Mini menu for text
            if (placeableSelectedSecondary()) {
              textOptions();
            }
            super.update();
        }

    }
    

    public class ImagePlaceable extends Placeable {
        // You'd think we'd assign a PImage object to each ImagePlaceable.
        // However, because of the Sprite implementation, that's not how things
        // are done unfortunately.
        // Instead, we must add the image to the engine's image hashmap and then
        // give it a name that the sprite will use to find the correct image.
        // Stupid workaround but it's the least complicated way of doing things lol.
        // We must also remember to remove the image from the engine when we leave
        // this screen otherwise we'll technically create a memory leak.
        public String imageName;

        public ImagePlaceable(String name) {
            super(name);
            sprite.allowResizing = true;
        }
        
        public ImagePlaceable(String id, PImage img) {
            super(id);
            sprite.allowResizing = true;
            
            // Ok yes I see the flaws in this, I'll figure out a more robust system later maybe.
            int uniqueIdentifier = int(random(0, 2147483646));
            String name = "cache-"+str(uniqueIdentifier);
            this.imageName = name;
            
            // I feel so bad using systemImages because it was only ever intended
            // for images loaded by the engine only >.<
            display.systemImages.put(name, img);
            imagesInEntry.add(name);
        }
        
        public void setImage(PImage img, String imgName) {
          this.imageName = imgName;
          display.systemImages.put(imgName, img);
          //app.image(img,0,0);
          imagesInEntry.add(imgName);
        }
        
        public PImage getImage() {
          return display.systemImages.get(this.imageName);
        }
        
        public void display() {
          
        }
        
        
        public void save(JSONObject obj) {
          // First, we need the png image data.
          PImage image = display.systemImages.get(this.sprite.imgName);
          if (image == null) {
            console.bugWarn("Trying to save image placeable, and image doesn't exist in memory?? Possible bug??");
            return;
          }
          
          // No multithreading please!
          // And no shrinking please!
          engine.setCachingShrink(0,0);
          
          
          String cachePath = engine.saveCacheImage(entryPath+"_"+str(numImages++), image);
          
          byte[] cacheBytes = loadBytes(cachePath);
          
          
          // NullPointerException
          String encodedPng = new String(Base64.getEncoder().encode(cacheBytes));
          
          this.sprite.offmove(0,0);
          
          obj.setString("ID", this.sprite.name);
          obj.setInt("type", TYPE_IMAGE);
          obj.setInt("x", int(this.sprite.getX()));
          obj.setInt("y", int(this.sprite.getY()));
          obj.setInt("wi", int(this.sprite.wi));
          obj.setInt("hi", int(this.sprite.hi));
          obj.setString("imgName", this.sprite.imgName);
          obj.setString("png", encodedPng);
          
        }
        
        public void update() {
            sprite.offmove(0, input.scrollOffset);
            if (placeableSelectedSecondary()) {
              editingPlaceable = this;
              imageOptions();
            }
            if (placeableSelected()) {
                editingPlaceable = this;
            }
            
            canvas.pushMatrix();
            canvas.scale(canvasScale);
            placeableSprites.sprite(sprite.getName(), imageName);
            canvas.popMatrix();
        }
    }
    
    public class InputFieldPlaceable extends TextPlaceable {
      
        public InputFieldPlaceable(String name) {
          super(name);
        }
      
        protected final float MIN_FIELD_VISIBLE_SIZE = 150f;
        public String inputText = "";
      
        public void display() {
            canvas.pushMatrix();
            canvas.scale(canvasScale);
            canvas.textAlign(LEFT, TOP);
            canvas.textFont(fontStyle, fontSize);
            canvas.textLeading(fontSize+lineSpacing);

            String displayText = "";
            if (editing()) {
                displayText = input.keyboardMessageDisplay();
            }
            else if (readOnly && modifyingField == this) {
              displayText = text+" "+input.keyboardMessageDisplay();
            }
            else {
                displayText = text+" "+inputText;
            }
            float x = sprite.xpos;
            float y = sprite.ypos-canvas.textDescent()+EXPAND_HITBOX/2+10;
            canvas.stroke(255f);
            canvas.strokeWeight(1f);
            canvas.fill(100, 60);
            canvas.rect(x+canvas.textWidth(text+" ")-10f, y-EXPAND_HITBOX, PApplet.max(canvas.textWidth(inputText)+30f, MIN_FIELD_VISIBLE_SIZE)+EXPAND_HITBOX*2f+10f, sprite.getHeight());
            canvas.fill(textColor);
            canvas.text(displayText, x, y);
            canvas.popMatrix();
        }
        
        public void updateDimensions() {
          float textww = app.textWidth(text+" ");
          float inputfield = app.textWidth(inputText+" ");
          float ww = PApplet.max(textww+inputfield, textww+MIN_FIELD_VISIBLE_SIZE);
          placeableSprites.hackSpriteDimensions(sprite, int(ww), int((app.textAscent()+app.textDescent()+lineSpacing)*(countNewlines(text)+1) + EXPAND_HITBOX));
        }
        
        // Need a custom click method since we can't have selected placeables in read-only mode.
        private boolean myClick() {
          return sprite.mouseWithinHitbox() && input.primaryOnce && !input.mouseMoved;
        }
        
        public void update() {
          super.update();
          
          // Select for text modifying and 
          if (myClick() && readOnly) {
              engine.allowShowCommandPrompt = false;
              modifyingField = this;
              input.keyboardMessage = inputText;
              input.cursorX = input.keyboardMessage.length();
          }
          
          if (modifyingField == this && readOnly) {
            input.addNewlineWhenEnterPressed = false;
            inputText = input.keyboardMessage;
          }
          updateDimensions();
        }
        
        public void save(JSONObject obj) {
          super.save(obj);
          obj.setInt("type", TYPE_INPUT_FIELD);
        }
    }
    
    
    
    public class BooleanFieldPlaceable extends TextPlaceable {
      
        public BooleanFieldPlaceable(String name) {
          super(name);
        }
      
        public boolean state = false;
        public float animationInverted = 0f;
      
        public void display() {
            canvas.pushMatrix();
            canvas.scale(canvasScale);
            canvas.textAlign(LEFT, TOP);
            canvas.textFont(fontStyle, fontSize);
            canvas.textLeading(fontSize+lineSpacing);

            String displayText = "";
            if (editing()) {
                displayText = input.keyboardMessageDisplay();
            }
            else {
                displayText = text;
            }
            float textx = sprite.xpos;
            float texty = sprite.ypos-canvas.textDescent()+EXPAND_HITBOX/2+10;
            float x = textx+canvas.textWidth(text)+20f;
            float y = texty-EXPAND_HITBOX;
            float wi = sprite.getHeight()*1.8f;
            float hi = sprite.getHeight();
            
            if (ui.buttonImg("nothing", x, y, wi, hi)) {
              sound.playSound("select_any");
              // Switch state and init switch animation.
              state = !state;
              animationInverted = 1f;
            }
            
            // Mathy stuff for rendering switch and knob
            final float KNOB_PADDING = 5f;
            final color COLOR_OFF = color(50f, 50f, 50f);
            final color COLOR_ON  = color(100f, 100f, 255f);
            
            float knobwi = hi-KNOB_PADDING*2f;
            float knobx = x+KNOB_PADDING;
            
            float animation = 1f-animationInverted;
            
            if (state == true) {
              knobx += (wi-knobwi-KNOB_PADDING*2f)*animation;
              canvas.fill(app.lerpColor(COLOR_OFF, COLOR_ON, animation));
            }
            else {
              knobx += (wi-knobwi-KNOB_PADDING*2f)*(1f-animation);
              canvas.fill(app.lerpColor(COLOR_ON, COLOR_OFF, animation));
            }
            
            // Draw switch
            canvas.stroke(255f);
            canvas.strokeWeight(2f);
            canvas.rect(x, y, wi, hi);
            
            // Knob
            canvas.noStroke();
            canvas.fill(255f); 
            canvas.rect(knobx, y+KNOB_PADDING, knobwi, knobwi);
            
            // Text
            canvas.fill(textColor);
            canvas.text(displayText, textx, texty);
            canvas.popMatrix();
            
            animationInverted *= PApplet.pow(0.85f, display.getDelta());
            updateDimensions();
        }
        
        //public void updateDimensions() {
        //  float textww = app.textWidth(text+" ");
        //  float inputfield = app.textWidth(inputText+" ");
        //  float ww = PApplet.max(textww+inputfield, textww+MIN_FIELD_VISIBLE_SIZE);
        //  placeableSprites.hackSpriteDimensions(sprite, int(ww), int((app.textAscent()+app.textDescent()+lineSpacing)*(countNewlines(text)+1) + EXPAND_HITBOX));
        //}
        
        //public void update() {
        //  super.update();
          
        //  // Select for text modifying and 
        //  if (myClick() && readOnly) {
        //      engine.allowShowCommandPrompt = false;
        //      modifyingField = this;
        //      input.keyboardMessage = inputText;
        //      input.cursorX = input.keyboardMessage.length();
        //  }
          
        //  if (modifyingField == this && readOnly) {
        //    input.addNewlineWhenEnterPressed = false;
        //    inputText = input.keyboardMessage;
        //  }
        //  updateDimensions();
        //}
        
        public void save(JSONObject obj) {
          super.save(obj);
          obj.setInt("type", TYPE_BOOLEAN_FIELD);
        }
    }
    
    
    private boolean movingSlider = false;
    
    public class SliderFieldPlaceable extends TextPlaceable {
      
        public SliderFieldPlaceable(String name) {
          super(name);
        }
        
        // MUST be called on creation
        public void createSlider(float min, float max, float init) {
          slider = ui.new CustomSlider("", min, max, init);
        }
        
        
        protected TWEngine.UIModule.CustomSlider slider;
        
        public float getVal() {
          if (slider == null) return 0f;
          return slider.valFloat;
        }
        
        public void setVal(float x) {
          if (slider == null) return;
          slider.valFloat = x;
        }
        
      
        public void display() {
            //canvas.pushMatrix();
            //canvas.scale(canvasScale);
            canvas.textAlign(LEFT, TOP);
            canvas.textFont(fontStyle, fontSize);
            canvas.textLeading(fontSize+lineSpacing);

            String displayText = "";
            if (editing()) {
                displayText = input.keyboardMessageDisplay();
            }
            else {
                displayText = text;
            }
            
            float textx = sprite.xpos;
            float texty = sprite.ypos-canvas.textDescent()+EXPAND_HITBOX/2+10;
            
            if (canvas == g) {
              slider.label = displayText;
              slider.wi = 750f;
              slider.display(textx, texty);
            }
            
            if (!movingSlider && slider.inBox() && input.primaryOnce) {
              movingSlider = true;
            }
            
            //canvas.popMatrix();
            updateDimensions();
        }
        
        public void setMinLabel(String label) {
          slider.setWhenMin(label);
        }
        
        public void setMaxLabel(String label) {
          slider.setWhenMax(label);
        }
        
        public void save(JSONObject obj) {
          super.save(obj);
          obj.setFloat("min_value", slider.min);
          obj.setFloat("max_value", slider.max);
          obj.setInt("type", TYPE_SLIDER_FIELD);
        }
    }
    
    public class SliderIntFieldPlaceable extends SliderFieldPlaceable {
      
        public SliderIntFieldPlaceable(String name) {
          super(name);
        }
        
        public int getValInt() {
          if (slider == null) return 0;
          return slider.valInt;
        }
        
        public void setVal(int x) {
          if (slider == null) return;
          slider.valInt = x;
        }
        
        // MUST be called on creation
        public void createSlider(int min, int max, int init) {
          slider = ui.new CustomSliderInt("", min, max, init);
        }
        
        public void save(JSONObject obj) {
          super.save(obj);
          // Should override the float settings from the inherited method.
          obj.setInt("min_value", (int)slider.min);
          obj.setInt("max_value", (int)slider.max);
          obj.setInt("type", TYPE_SLIDERINT_FIELD);
        }
    }
    
    
    public class OptionsFieldPlaceable extends TextPlaceable {
      
        public OptionsFieldPlaceable(String name) {
          super(name);
        }
        
        public String[] options;
        public String selectedOption = "Sample option";
        
        private final float BOX_X_POS  = 400f;
        private final float BOX_X_SIZE = 500f;
        
        public void createOptions(JSONArray array) {
          options = new String[array.size()];
          for (int i = 0; i < array.size(); i++) {
            options[i] = array.getString(i, "---");
          }
        }
        
        public void createOptions(String... array) {
          options = array;
        }
      
        public void display() {
            canvas.pushMatrix();
            canvas.scale(canvasScale);
            canvas.textAlign(LEFT, TOP);
            canvas.textFont(fontStyle, fontSize);
            canvas.textLeading(fontSize+lineSpacing);

            String displayText = "";
            if (editing()) {
                displayText = input.keyboardMessageDisplay();
            }
            else {
                displayText = text;
            }
            float x = sprite.xpos;
            float y = sprite.ypos-canvas.textDescent()+EXPAND_HITBOX/2+10;
            canvas.stroke(255f);
            canvas.strokeWeight(1f);
            canvas.fill(100, 60);
            canvas.rect(x+BOX_X_POS, y-EXPAND_HITBOX, BOX_X_SIZE, sprite.getHeight());
            display.img("down_triangle_64", x+BOX_X_POS+BOX_X_SIZE-69f, y, sprite.getHeight()-20f, sprite.getHeight()-20f);
            
            canvas.fill(textColor);
            // Label text
            canvas.text(displayText, x, y);
            // Selected option text
            canvas.fill(255f);
            canvas.text(selectedOption, x+BOX_X_POS+10f, y);
            canvas.popMatrix();
        }
        
        //public void updateDimensions() {
        //  float textww = app.textWidth(text+" ");
        //  float inputfield = app.textWidth(inputText+" ");
        //  float ww = PApplet.max(textww+inputfield, textww+MIN_FIELD_VISIBLE_SIZE);
        //  placeableSprites.hackSpriteDimensions(sprite, int(ww), int((app.textAscent()+app.textDescent()+lineSpacing)*(countNewlines(text)+1) + EXPAND_HITBOX));
        //}
        
        // Need a custom click method since we can't have selected placeables in read-only mode.
        private boolean myClick() {
          float x = sprite.xpos;
          float y = sprite.ypos-canvas.textDescent()+EXPAND_HITBOX/2+10;
          return ui.buttonImg("nothing", x+BOX_X_POS, y-EXPAND_HITBOX, BOX_X_SIZE, sprite.getHeight()) && input.primaryOnce && !input.mouseMoved;
        }
        
        public void update() {
          super.update();
          
          // Select for text modifying and 
          if (myClick() && readOnly) {
            Runnable[] actions = new Runnable[options.length];
            
            for (int i = 0; i < options.length; i++) {
              final String finalOption = options[i];
              actions[i] = new Runnable() {public void run() {
                  selectedOption = finalOption;
              }};
            }
            
            ui.createOptionsMenu(options, actions);
          }
          
          updateDimensions();
        }
        
        public void save(JSONObject obj) {
          super.save(obj);
          obj.setInt("type", TYPE_OPTIONS_FIELD);
          JSONArray array = new JSONArray();
          
          for (int i = 0; i < options.length; i++) {
            array.setString(i, options[i]);
          }
          obj.setJSONArray("options", array);
        }
    }
    
    
    public class ButtonPlaceable extends TextPlaceable {
      
        public ButtonPlaceable(String name) {
          super(name);
        }
        
        public color rgb = 0xFF614d7d;
        public color rgbHover = 0xFF8d70b5;
        public boolean clicked = false;
      
        public void display() {
            canvas.pushMatrix();
            canvas.scale(canvasScale);
            canvas.textAlign(LEFT, TOP);
            canvas.textFont(fontStyle, fontSize);
            canvas.textLeading(fontSize+lineSpacing);

            String displayText = "";
            if (editing()) {
                displayText = input.keyboardMessageDisplay();
            }
            else {
                displayText = text;
            }
            
            float PADDING = 5f;
            float textx = sprite.xpos;
            float texty = sprite.ypos-canvas.textDescent()+EXPAND_HITBOX/2+10;
            float x = textx-10f-PADDING;
            float y = texty-EXPAND_HITBOX-PADDING;
            float wi = sprite.getWidth()+20f+PADDING*2f;
            float hi = sprite.getHeight()+PADDING*2f;
            
            
            canvas.stroke(255f);
            canvas.strokeWeight(1f);
            if (ui.mouseInArea(x, y, wi, hi)) {
              canvas.fill(rgbHover); 
            }
            else {
              canvas.fill(rgb); 
            }
            
            canvas.rect(x, y, wi, hi);
            clicked = readOnly && ui.buttonImg("nothing", x, y, wi, hi);
            
            // Text
            canvas.fill(textColor);
            canvas.text(displayText, textx, texty);
            canvas.popMatrix();
            
            
            updateDimensions();
        }
        
        public void save(JSONObject obj) {
          super.save(obj);
          obj.setInt("type", TYPE_BUTTON);
          obj.setString("button_color", hex(rgb));
          obj.setString("button_color_hover", hex(rgbHover));
        }
    }
    
    
    
    
    
    //**************************************************************************************
    //**********************************EDITOR SCREEN CODE**********************************
    //**************************************************************************************  
    // Pls don't use this constructor in your code if you are sane.
    public Editor(TWEngine engine, String entryPath, PGraphics c, boolean doMultithreaded) {
        super(engine);
        this.entryPath = entryPath;
        if (c == null) {
          gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/editor/");
          gui.repositionSpritesToScale();
          gui.interactable = false;
          
          // Bug fix: run once so that text element in GUI being at pos 0,0 isn't shown.
          runGUI();
          
          if (isWindows()) {
            camera = new DCapture(engine);
          }
          else if (isAndroid()) {
            camera = new PCapture(engine);
          }
          // In android we use our own camera.
        
        }
        
        if (isAndroid()) {
          DEFAULT_FONT_SIZE = 50;
        }
        
        placeableSprites = new SpriteSystemPlaceholder(engine);
        placeableSprites.allowSelectOffContentPane = false;
        imagesInEntry = new ArrayList<String>();
        placeableset = new HashMap<String, Placeable>();
        
        // Get the path without the file name
        int lindex = entryPath.lastIndexOf('/');
        if (lindex == -1) {
          lindex = entryPath.lastIndexOf('\\');
          if (lindex == -1) console.bugWarn("Could not find entry's dir, possible bug?");
        }
        if (lindex != -1) {
          this.entryDir = entryPath.substring(0, lindex+1);
          this.entryName = entryPath.substring(lindex+1, entryPath.lastIndexOf('.'));
        }

        autoScaleDown = settings.getBoolean("auto_scale_down", false);
        input.scrollOffset = 0.;
        
        if (c != null) {
          canvas = c;
          canvasScale = canvas.width/(WIDTH);
        }
        else {
          canvas = g;
          canvasScale = canvas.width/(WIDTH*display.getScale());
        }

        myLowerBarColor   = 0xFF4c4945;
        myUpperBarColor   = myLowerBarColor;
        myBackgroundColor = BACKGROUND_COLOR;
        //myBackgroundColor = color(255,0,0);
        
        if (doMultithreaded) 
          readEntryJSONInSeperateThread();
        else {
          readEntryJSON();
          loading = false;
        }
    }
    
    public Editor(TWEngine e, String entryPath) {
      this(e, entryPath, null, true);
    }

    //*****************************************************************
    //***********************PLACEABLE TYPES***************************
    //*****************************************************************
    public final int TYPE_UNKNOWN         = 0;
    public final int TYPE_TEXT            = 1;
    public final int TYPE_IMAGE           = 2;
    public final int TYPE_INPUT_FIELD     = 3;
    public final int TYPE_BOOLEAN_FIELD   = 4;
    public final int TYPE_SLIDER_FIELD    = 5;
    public final int TYPE_SLIDERINT_FIELD = 6;
    public final int TYPE_OPTIONS_FIELD   = 7;
    public final int TYPE_BUTTON          = 8;

    //*****************************************************************
    //**************************SAVE PAGE******************************
    //*****************************************************************
    public void saveEntryJSON() {
      // Only save if any changes were made.
      if (changesMade) {
        numImages = 0;
        //JSONObject json = new JSONObject();
        JSONArray array = new JSONArray();
        for (Placeable p : placeableset.values()) {
          // Lil optimisation
            if (p instanceof TextPlaceable) {
              if (((TextPlaceable)p).text.length() == 0) {
                continue;
              }
            }
          
            JSONObject obj = new JSONObject();
            p.save(obj);
            array.append(obj);
        }
        
        
        engine.app.saveJSONArray(array, entryPath);
        
        sound.playSound("chime");
      }
    }
    
    public int numImages = 0;
    
    
    // Util json ancient functions moved from Engine
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
      
      if (result == null) {
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

    //*****************************************************************
    //**************************SAVE PAGE******************************
    //*****************************************************************
    public void readEntryJSON() {
        // check if file exists
        if (!file.exists(entryPath) || file.fileSize(entryPath) <= 2) {
          // If it doesn't exist or is blank, create a new placeable for the name of the entry
            entryNameText = new TextPlaceable(RENAMEABLE_NAME);
            entryNameText.sprite.move(20., UPPER_BAR_DROP_WEIGHT + 80);
            entryNameText.fontSize = 60.;
            entryNameText.textColor = color(255);
            entryNameText.text = entryName;
            entryNameText.updateDimensions();
            
            // Create date
            TextPlaceable date = new TextPlaceable("datetime");
            String d = engine.appendZeros(day(), 2)+"/"+engine.appendZeros(month(), 2)+"/"+year()+"\n"+engine.appendZeros(hour(), 2)+":"+engine.appendZeros(minute(), 2)+":"+engine.appendZeros(second(), 2);
            date.sprite.move(WIDTH-app.textWidth(d)*2., 250);
            date.text = d;
            date.updateDimensions();
            
            // New entry, new default template, ofc we want to save changes!
            changesMade = true;
            
            loading = false;
            return;
        }
        
        // Open json array
        // (This function used to be in the engine code and was ancient)
        try {
          loadedJsonArray = app.loadJSONArray(entryPath);
        }
        catch (RuntimeException e) {
          console.warn("Failed to open JSON file, there was an error: "+e.getMessage());
          return;
        }
        // If the file doesn't exist
        if (loadedJsonArray == null) {
          console.warn("What. The file doesn't exist.");
          return;
        }
        
        for (int i = 0; i < loadedJsonArray.size(); i++) {
            int type = getJSONArrayInt(i, "type", 0);

            switch (type) {
                case TYPE_UNKNOWN:
                    console.warn("Corrupted element, skipping.");
                break;
                case TYPE_TEXT: 
                    TextPlaceable t = readTextPlaceable(i);
                    // Title text element should always be 000
                    if (t.sprite.name.equals(RENAMEABLE_NAME)) entryNameText = t;
                break;
                case TYPE_IMAGE: 
                    readImagePlaceable(i);
                break;
                case TYPE_INPUT_FIELD:
                    readInputFieldPlaceable(i);
                break;
                case TYPE_BOOLEAN_FIELD:
                    readBooleanFieldPlaceable(i);
                break;
                case TYPE_SLIDER_FIELD:
                    readSliderFieldPlaceable(i);
                break;
                case TYPE_SLIDERINT_FIELD:
                    readSliderIntFieldPlaceable(i);
                break;
                case TYPE_OPTIONS_FIELD:
                    readOptionsFieldPlaceable(i);
                break;
                case TYPE_BUTTON:
                    readButtonPlaceable(i);
                break;
                default:
                    console.warn("Corrupted element, skipping.");
                break;
            }
        }
        loading = false;
    }
    
    // Helper function
    private void getTextAttribs(TextPlaceable t, int i) {
        t.sprite.setX((float)getJSONArrayInt(i, "x", (int)WIDTH/2));
        t.sprite.setY((float)getJSONArrayInt(i, "y", (int)HEIGHT/2));
        t.sprite.name = getJSONArrayString(i, "ID", t.id);
        t.text = getJSONArrayString(i, "text", "");
        t.fontSize = getJSONArrayFloat(i, "size", 12.);
        t.textColor = getJSONArrayInt(i, "color", color(255, 255, 255));
        t.updateDimensions();
    }
    private TextPlaceable readTextPlaceable(int i) {
        TextPlaceable t = new TextPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        getTextAttribs(t, i);
        return t;
    }
    private InputFieldPlaceable readInputFieldPlaceable(int i) {
        InputFieldPlaceable t = new InputFieldPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        getTextAttribs(t, i);
        return t;
    }
    private ButtonPlaceable readButtonPlaceable(int i) {
        ButtonPlaceable t = new ButtonPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        t.rgb = unhex(getJSONArrayString(i, "button_color", "FF614d7d"));
        t.rgbHover = unhex(getJSONArrayString(i, "button_color_hover", "FF8d70b5"));
        getTextAttribs(t, i);
        return t;
    }
    private BooleanFieldPlaceable readBooleanFieldPlaceable(int i) {
        BooleanFieldPlaceable t = new BooleanFieldPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        getTextAttribs(t, i);
        return t;
    }
    private SliderFieldPlaceable readSliderFieldPlaceable(int i) {
        SliderFieldPlaceable t = new SliderFieldPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        t.createSlider(getJSONArrayFloat(i, "min_value", 0f), getJSONArrayFloat(i, "max_value", 100f), 50f);
        getTextAttribs(t, i);
        return t;
    }
    private SliderIntFieldPlaceable readSliderIntFieldPlaceable(int i) {
        SliderIntFieldPlaceable t = new SliderIntFieldPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        t.createSlider(getJSONArrayInt(i, "min_value", 0), getJSONArrayInt(i, "max_value", 10), 5);
        getTextAttribs(t, i);
        return t;
    }
    private OptionsFieldPlaceable readOptionsFieldPlaceable(int i) {
        OptionsFieldPlaceable t = new OptionsFieldPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        
        if (!loadedJsonArray.getJSONObject(i).isNull("options")) {
          t.createOptions(loadedJsonArray.getJSONObject(i).getJSONArray("options"));
        }
        else {
          t.createOptions("Item 1", "Item 2", "Item 3");
        }
        
        getTextAttribs(t, i);
        return t;
    }
    private ImagePlaceable readImagePlaceable(final int i) {
        ImagePlaceable im = new ImagePlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        im.sprite.setX((float)getJSONArrayInt(i, "x", (int)WIDTH/2));
        im.sprite.setY((float)getJSONArrayInt(i, "y", (int)HEIGHT/2));
        im.sprite.wi   = getJSONArrayInt(i, "wi", 512);
        im.sprite.hi   = getJSONArrayInt(i, "hi", 512);
        im.sprite.name = im.id;
        String imageName = getJSONArrayString(i, "imgName", "");
        
        // If there's cache, don't bother decoding the base64 string.
        // Otherwise, read the base64 string, generate cache, read from that cache.
        
        Runnable loadFromEntry = new Runnable() {
          public void run() {
            // Decode the string of base64
            String encoded   = getJSONArrayString(i, "png", "");
            
            // Png image data in json is missing
            if (encoded.length() == 0) {
              console.warn("while loading entry: png image data in json is missing.");
            }
            // Everything is found as expected.
            else {
              byte[] decodedBytes = Base64.getDecoder().decode(encoded.getBytes());
              
              PImage img = engine.saveCacheImageBytes(entryPath+"_"+str(i), decodedBytes, "png");
              
              // An error occured, data may have been tampered with/corrupted.
              if (img == null) 
                console.warn("while loading entry: png image data is corrupted or cachepath is invalid.");
              else 
                engine.setOriginalImage(img);
            }
          }
        };
        PImage img = engine.tryLoadImageCache(this.entryPath+"_"+str(i), loadFromEntry);
        
        im.setImage(img, imageName);
        
        return im;
    }
    
    
    public boolean loading = false;
    public void readEntryJSONInSeperateThread() {
      loading = true;
      Thread t = new Thread(new Runnable() {
          public void run() {
              readEntryJSON();
          }
      });
      t.start();
    }
    
    public boolean isLoaded() {
      return !loading;
    }
    
    protected boolean customCommands(String command) {
      if (command.equals("/editgui")) {
        gui.interactable = !gui.interactable;
        if (gui.interactable) console.log("GUI now interactable.");
        else  console.log("GUI is no longer interactable.");
        return true;
      }
      else if (command.equals("/alignbuttons")) {
        console.log("Align buttons to mouse.");
        for (Placeable p : placeableset.values()) {
          if (p instanceof ButtonPlaceable) {
            p.sprite.setX(input.mouseX());
          }
        }
        return true;
      }
      else return false;
    }


    //*****************************************************************
    //*********************GUI BUTTONS AND ACTIONS*********************
    //*****************************************************************

    public void runGUI() {
        ui.useSpriteSystem(gui);
        ui.spriteSystemClickable = !ui.miniMenuShown();

        
        if (!cameraMode) {
  
          // The lines nothin to see here
          gui.guiElement("line_1");
          gui.guiElement("line_2");
          gui.guiElement("line_3");
  
          app.noTint();
          app.textFont(engine.DEFAULT_FONT);
  
          //************BACK BUTTON************
          if (ui.button("back", "back_arrow_128", "Save & back")) {
            try {
               saveEntryJSON();
               if (engine.getPrevScreen() instanceof Explorer) {
                 Explorer prevExplorerScreen = (Explorer)engine.getPrevScreen();
                 prevExplorerScreen.refreshDir();
               }
               
               // Remove all the images from this entry before we head back,
               // we don't wanna cause any memory leaks.
               
               // Update 25/09/23
               // ... where's the code? Hmmmmmmmmmmmm
               // Oh wait it's in the endAnimation function.
               // Bit misleading there, past me.
               
               closeTouchKeyboard();
               previousScreen();
            }
            catch (RuntimeException e) {
              // TODO: dear god we need a proper solution for this!!!!
              console.warn("Failed to save entry :(");
            }
          }
  
          //************FONT COLOUR************
          if (ui.button("font_color", "fonts_128", "Colour")) {
              SpriteSystemPlaceholder.Sprite s = gui.getSprite("font_color");
              
              Runnable r = new Runnable() {
                public void run() {
                  // Set the color of the text placeable
                  if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                      TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                      selectedColor = ui.getPickedColor();
                      editingTextPlaceable.textColor = selectedColor;
                  }
                }
              };
              
              ui.colorPicker(s.xpos, s.ypos+100, r);
          }
  
          //************BIGGER FONT************
          if (ui.button("bigger_font", "bigger_text_128", "Bigger")) {
              power.setAwake();
              if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                  TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                  selectedFontSize = editingTextPlaceable.fontSize + 2;
                  editingTextPlaceable.fontSize = selectedFontSize;
              }
              else {
                  selectedFontSize += 2;
              }
              sound.playSound("select_bigger");
          }
  
          //************SMALLER FONT************
          if (ui.button("smaller_font", "smaller_text_128", "Smaller")) {
              power.setAwake();
              if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                  TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                  selectedFontSize = editingTextPlaceable.fontSize - 2;
                  editingTextPlaceable.fontSize = selectedFontSize;
              }
              else {
                  selectedFontSize -= 2;
              }
  
              // Minimum font size
              if (selectedFontSize < MIN_FONT_SIZE) {
                  selectedFontSize = MIN_FONT_SIZE;
              }
              sound.playSound("select_smaller");
          }
  
          //************FONT SIZE************
          
          // Sprite might not be loaded by the time we want to check for hovering
          // so suppress warnings so we don't get an ugly warning.
          // Nothing bad will happen other than that.
          gui.suppressSpriteWarning = true;
          SpriteSystemPlaceholder.Sprite s = gui.getSprite("font_size");
          // Draw text where the sprite is
          app.textAlign(CENTER, CENTER);
          app.textSize(20);
  
          // Added this line cus other elements caused the text size to gray.
          app.fill(255);
          // Bug fix: don't show the sprite on the first frame of the animation start
          // (showGUI is set later)
          if (showGUI)
            app.text(selectedFontSize, s.xpos+s.wi/2, s.ypos+s.hi/2);
  
          // The button code
          if (ui.button("font_size", "nothing", "Font size")) {
              if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                  TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                  // Doesn't really do anything yet really.
                  editingTextPlaceable.fontSize = selectedFontSize;
              }
          }
  
          // Turn warnings back on.
          gui.suppressSpriteWarning = false;
          
          //************CAMERA************
          if (ui.button("camera", "camera_128", "Take photo")) {
            sound.playSound("select_any");
            this.beginCamera();
          }
          
          
          //************COPY BUTTON************
          if (ui.button("copy", "copy_button_128", "Copy")) {
            sound.playSound("select_any");
            this.copy();
          }
          
          //************PASTE BUTTON************
          if (ui.button("paste", "paste_button_128", "Paste")) {
            sound.playSound("select_any");
            this.paste();
          }
        }
        else {
          
          if (ui.button("camera_back", "back_arrow_128", "")) {
            sound.playSound("select_any");
            this.endCamera();
          }
          
          if (!camera.error.get() && camera.ready.get()) {
            if (ui.button("snap", "snap_button_128", "")) {
              sound.playSound("select_snap");
              stats.increase("photos_taken", 1);
              insertImage(camera.updateImage());
              
              // Rest of the stuff is just for cosmetic effects :sparkle_emoji:
              takePhoto = true;
              cameraFlashEffect = 255.;
            }
            
            // TODO: Add some automatic "position at bottom" function to the messy class.
            gui.getSprite("snap").setY(HEIGHT-myLowerBarWeight+20);
            
            if (ui.button("camera_flip", "flip_camera_128", "Switch camera")) {
              sound.playSound("select_any");
              preparingCameraMessage = "Switching camera...";
              camera.switchNextCamera();
            }
            gui.getSprite("camera_flip").setY(HEIGHT-myLowerBarWeight+10);
          }
          
        }

        // We want to render the gui sprite system above the upper bar
        // so we do it here instead of content()
        gui.updateSpriteSystem();


    }
    
    public void beginCamera() {
      // In android, we don't do anything below us, and just
      // launch the system camera. EZ.
      if (isAndroid()) {
        openAndroidCamera();
        return;
      }
      
      upperBarDrop = CAMERA_ON_ANIMATION;        // Set to 
      upperbarExpand = 1.;
      cameraMode = true;
      myBackgroundColor = color(0);
      
      // Because rendering cameraDisplay takes time on the first run, we should prompt the user
      // that the display is getting set up. I hate this so much.
      app.textFont(engine.DEFAULT_FONT);
      ui.loadingIcon(WIDTH/2, HEIGHT/2);
      fill(255);
      textSize(30);
      textAlign(CENTER, CENTER);
      text("Starting camera display...", WIDTH/2, HEIGHT/2+120);
      
      // Start up the camera.
      Thread t = new Thread(new Runnable() {
          public void run() {
             camera.setup();
          }
      });
      t.start();
      preparingCameraMessage = "Starting camera...";
    }
    
    public void endCamera() {
      upperBarDrop = CAMERA_OFF_ANIMATION;
      upperbarExpand = 1.;
      cameraMode = false;
      camera.turnOffCamera();
      myBackgroundColor = BACKGROUND_COLOR;       // Restore original background color
      engine.sharedResources.set("lastusedcamera", camera.selectedCamera);
    }
    
    public void endCameraAndroid(PImage photo) {
      insertImage(photo);
    }

    // New name without the following path.
    // TODO: safer to move instead of delete
    public void renameEntry(String newName) {
      String newPath = entryDir+newName+"."+engine.ENTRY_EXTENSION;
      boolean success = file.mv(entryPath, newPath);
      
      if (success) {
        entryPath = newPath;
        console.log("Entry renamed to "+newName+"."+engine.ENTRY_EXTENSION);
      }
      else {
        console.warn("Failed to rename file.");
      }
      
      //File f = new File(entryPath);
      //if (f.exists()) {
      //  if (!f.delete()) console.warn("Couldn't rename entry; old file couldn't be deleted.");
      //}
      //entryPath = entryDir+newName+"."+engine.ENTRY_EXTENSION;
      //entryName = newName;
      //try {
      //  saveEntryJSON();
      //}
      //catch (RuntimeException e) {
      //  // TODO: dear god we need a proper solution for this!!!!
      //  console.warn("Failed to save entry :(");
      //}
    }
    
    protected void fabric() {
      display.shader("fabric", 
      "color", 
      red(myUpperBarColor)/255. ,
      green(myUpperBarColor)/255. ,
      blue(myUpperBarColor)/255. ,
      1. , 
      "intensity", 0.1);
    }

    // I don't think you'll really need to modify this code much.
    public void upperBar() {
        // The upper bar expand down animation when the screen loads.
        if (upperbarExpand > 0.001) {
            power.setAwake();
            upperbarExpand *= PApplet.pow(0.8, display.getDelta());
            
            float newBarWeight = UPPER_BAR_DROP_WEIGHT;
            
            if (upperBarDrop == CAMERA_OFF_ANIMATION || upperBarDrop == INITIALISE_DROP_ANIMATION)
              myUpperBarWeight = UPPER_BAR_WEIGHT + newBarWeight - (newBarWeight * upperbarExpand);
            else myUpperBarWeight = UPPER_BAR_WEIGHT + (newBarWeight * upperbarExpand);
            
            
            
            if (upperbarExpand <= 0.001) power.setSleepy();
        }
        
        fabric();
        
        if (!ui.miniMenuShown() && !cameraMode) 
          display.clip(0, 0, WIDTH, myUpperBarWeight);
        super.upperBar();
        display.defaultShader();
        
        if (showGUI)
          runGUI();
        app.noClip();
    }
    
    public void lowerBar() {
      fabric();
      
      float LOWER_BAR_EXPAND = 100.;
      if (upperBarDrop == CAMERA_ON_ANIMATION) myLowerBarWeight = LOWER_BAR_WEIGHT+(LOWER_BAR_EXPAND * (1.-upperbarExpand));
      if (upperBarDrop == CAMERA_OFF_ANIMATION) myLowerBarWeight = LOWER_BAR_WEIGHT+(LOWER_BAR_EXPAND * (upperbarExpand));
      
      super.lowerBar();
      display.defaultShader();
    }
    
    public float insertedXpos = 10;
    public float insertedYpos = this.myUpperBarWeight;
    
    private void insertImage(PImage img) {
      if (readOnly) return;
        
      // Because this could potentially take a while to load and cache into the Processing engine,
      // we should expect framerate drops here.
      engine.power.resetFPSSystem();
      
      // TODO: Check whether we have text or image in the clipboard.
      if (!ui.miniMenuShown()) {
        if (img == null) console.log("Can't paste image from clipboard!");
        else {
          // Resize the image if autoScaleDown is enabled for faster performance.
          if (autoScaleDown) {
            engine.scaleDown(img, SCALE_DOWN_SIZE);
          }
          
          ImagePlaceable imagePlaceable = new ImagePlaceable(generateRandomID(), img);
          if (editingPlaceable != null) {
            // Grab the position of the text that was there previously
            // so we can plonk an image in its place, but only if there was
            // no text to begin with.
            if (editingPlaceable instanceof TextPlaceable) {
              TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
              float x = editingPlaceable.sprite.xpos;
              float y = editingPlaceable.sprite.ypos;
              int hi = editingPlaceable.sprite.hi;
              
              if (editingTextPlaceable.text.length() == 0) {
                  placeableset.remove(editingPlaceable.id);
                  imagePlaceable.sprite.setX(x);
                  imagePlaceable.sprite.setY(y-input.scrollOffset);
              }
              else {
                  imagePlaceable.sprite.setX(x);
                  imagePlaceable.sprite.setY(y+hi);
              }
            }
          }
          else {
            // If no text is being edited then place the image in the default location.
            imagePlaceable.sprite.setX(insertedXpos);
            imagePlaceable.sprite.setY(insertedYpos);
            insertedXpos += 20;
            insertedYpos += 20;
          }
          // Dont want our image stretched
          imagePlaceable.sprite.wi = img.width;
          imagePlaceable.sprite.hi = img.height;
          
          
          float aspect = float(img.height)/float(img.width);
          // If the image is too large, make it smaller quickly
          if (imagePlaceable.sprite.wi > WIDTH*0.5) {
            imagePlaceable.sprite.wi = int((WIDTH*0.5));
            imagePlaceable.sprite.hi = int((WIDTH*0.5)*aspect);
          }
          
          // Select the image we just pasted.
          editingPlaceable = imagePlaceable;
          changesMade = true;
          stats.increase("images_created", 1);
        }
      }
    }
    
    // Just normal text by default.
    private void insertText(String initText, float x, float y) {
      insertText(initText, x, y, TYPE_TEXT);
    }
    
    private void insertText(String initText, float x, float y, int type) {
        // Don't do anything if readonly enabled.
        if (readOnly) return;
        
        TextPlaceable editingTextPlaceable;
        if (type == TYPE_INPUT_FIELD) {
          editingTextPlaceable = new InputFieldPlaceable(generateRandomID());
        }
        else if (type == TYPE_SLIDER_FIELD) {
          SliderFieldPlaceable t = new SliderFieldPlaceable(generateRandomID());
          t.createSlider(0f, 100f, 50f);
          editingTextPlaceable = t;
        }
        else if (type == TYPE_BUTTON) {
          ButtonPlaceable t = new ButtonPlaceable(generateRandomID());
          editingTextPlaceable = t;
        }
        else if (type == TYPE_OPTIONS_FIELD) {
          OptionsFieldPlaceable t = new OptionsFieldPlaceable(generateRandomID());
          t.createOptions("Item 1", "Item 2", "Item 3");
          editingTextPlaceable = t;
        }
        else if (type == TYPE_SLIDERINT_FIELD) {
          SliderIntFieldPlaceable t = new SliderIntFieldPlaceable(generateRandomID());
          t.createSlider(0, 10, 5);
          editingTextPlaceable = t;
        }
        else if (type == TYPE_BOOLEAN_FIELD) {
          editingTextPlaceable = new BooleanFieldPlaceable(generateRandomID());
        }
        else if (type == TYPE_TEXT) {
          editingTextPlaceable = new TextPlaceable(generateRandomID());
        }
        else {
          editingTextPlaceable = new TextPlaceable(generateRandomID());
        }
        
        editingTextPlaceable.textColor = selectedColor;
        placeableSprites.selectedSprite = editingTextPlaceable.sprite;
        editingTextPlaceable.sprite.setX(x);
        editingTextPlaceable.sprite.setY(y-input.scrollOffset);
        editingPlaceable = editingTextPlaceable;
        
        input.keyboardMessage = initText;
        input.cursorX = input.keyboardMessage.length();
        editingTextPlaceable.updateDimensions();
        engine.allowShowCommandPrompt = false;
        stats.increase("text_created", 1);
    }
    
    protected void renderPlaceables() {
        placeableSprites.interactable = !readOnly;
      
        placeableSprites.updateSpriteSystem();
        
        // Because every placeable is placed at a slight offset due to the ribbon bar,
        // readonly doesn't have this bar and hence we should limit scroll at where the
        // ribbon bar normally is.
        if (!readOnly)
          input.processScroll(0., scrollLimitY);
        else 
          input.processScroll(-UPPER_BAR_DROP_WEIGHT, scrollLimitY);
          
        extentX = 0;
        extentY = 0;
        // Run all placeable objects
        for (Placeable p : placeableset.values()) {
          try {
            p.update();
          }
          catch (RuntimeException e) {
            //console.warn("Entry rendering error, continuing.");
          }
            
            // Don't care I can tidy things up later.
            // Update extentX and extentY
            float newx = (p.sprite.defxpos+p.sprite.getWidth());
            if (newx > extentX) extentX = newx;
            float newy = (p.sprite.defypos+p.sprite.getHeight());
            if (newy > extentY) extentY = newy;
        }
        
        // Update max scroll.
        scrollLimitY = max(extentY+SCROLL_LIMIT-HEIGHT+myLowerBarWeight, 0);
    }
    
    private void copy() {
      if (editingPlaceable != null) {
        if (editingPlaceable instanceof TextPlaceable) {
          TextPlaceable t = (TextPlaceable)editingPlaceable;
          boolean success = clipboard.copyString(t.text);
          if (success)
            console.log("Copied!");
        }
        else console.log("Copying of element not supported yet, sorry!");
      }
    }
    
    private void paste() {
      if (clipboard.isImage()) {
        PImage pastedImage = clipboard.getImage();
        if (pastedImage == null) console.log("Can't paste image from clipboard!");
        else {
          insertImage(pastedImage);
          stats.increase("images_pasted", 1);
        }
      }
      else if (clipboard.isString()) {
        String pastedString = clipboard.getText();
        
        if (editingPlaceable != null) {
          // If we're currently editing text, append it
          if (editingPlaceable instanceof TextPlaceable) {
            input.keyboardMessage += pastedString;
          }
          else if (editingPlaceable instanceof ImagePlaceable) {
            // Place it just underneath the image.
            float imx = editingPlaceable.sprite.xpos;
            float imy = editingPlaceable.sprite.ypos;
            int imhi = editingPlaceable.sprite.hi;
            insertText(pastedString, imx, imy+imhi);
          }
        }
        // No text or image being edited, just plonk it whereever.
        else {
          insertedXpos += 20;
          insertedYpos += 20;
          insertText(pastedString, insertedXpos, insertedYpos);
        }
        stats.increase("strings_pasted", 1);
      }
      else console.log("Can't paste item from clipboard!");
    }
    
    
    boolean scrolling = false;
    boolean prevReset = false;
    
    // Only used in readonly mode
    private InputFieldPlaceable modifyingField = null;
    
    private void renderEditor() {
      //yview += engine.scroll;
        // In order to know if we clicked on an object or a blank area,
        // this is what we do:
        // 1 Keep track of a click and do some stuff (like deleting a placeable object)
        // it it's empty
        // 2 Update all objects which will check if any of them have been clicked.
        // 3 If there's been a click from step 1 then check if any object has been clicked.
        boolean clickedThing = false;
        boolean mouseInUpperbar = engine.mouseY() < myUpperBarWeight;
        
        
        if (!input.primaryDown) {
          prevMouseY = input.mouseY();
          prevReset =  true;
        }
      // Reset prevInput for one more frame
        else if (prevReset) {
          prevMouseY = input.mouseY();
          prevReset =  false;
        }
        
        if (input.primaryOnce && !mouseInUpperbar) {
          scrolling = true;
        }
        
        if (input.primaryReleased) {
            if (!input.mouseMoved) {
                clickedThing = true;
            }
            scrolling = false;
        }

        // The part of the code that actually deselects an element when clicking in
        // a blank area.
        // However, we don't want to deselect text in the following:
        // 1. If the minimenu is open
        // 2. GUI element is clicked (we just check the mouse is in the upper bar
        // to check that condition)
        if (input.primaryOnce) {
            if(!ui.miniMenuShown() && !mouseInUpperbar) {

                if (editingPlaceable != null) {
                  if (editingPlaceable instanceof TextPlaceable) {
                    TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                    if (editingTextPlaceable.text.length() == 0) {
                        placeableset.remove(editingPlaceable.id);
                    }
                  }
                  // Rename the entry if we're clicking off the title text.
                  if (editingPlaceable == entryNameText) {
                    if (entryNameText.text.matches("^[a-zA-Z0-9_ ,\\-]+$()") && entryNameText.text.length() > 0) {
                      renameEntry(entryNameText.text);
                    }
                    else {
                      console.log("Invalid characters in entry name!");
                      entryNameText.text = entryName;
                    }
                  }
                  
                  // Otherwise anything else should be deselected automatically.
                  editingPlaceable = null;
                  engine.allowShowCommandPrompt = true;
                  //saveEntryJSON();
                }
                
                // This is ok to place here because fields are selected in renderPlaceables(), and renderPlaceables()
                // is just below this section.
                modifyingField = null;

            }
        }
        
        // Right click menu in a blank space.
        else if (input.secondaryOnce) {
            if(!ui.miniMenuShown() && !mouseInUpperbar && !readOnly) {
                // To ensure we're clicking in a blank space, make sure we're either:
                // A. have an object selected but not right-clicking on it
                // B. don't have an object selected and right-clicking a blank area.
                boolean rightClickMenu = false;
                if (editingPlaceable != null) {
                  rightClickMenu = !editingPlaceable.placeableSelectedSecondary();
                }
                else {
                  rightClickMenu = true;
                }
                
                if (rightClickMenu) {
                  blankOptions();
                }
            }
        }
        
        if (movingSlider && !input.primaryDown) {
          movingSlider = false;
        }
        
        
        // TODO: CTRL+C CTRL+V in Processing is broken.
        if (input.ctrlDown && input.keyDownOnce('c')) { // Ctrl+c
          this.copy();
        }
        
        if (input.ctrlDown && input.keyDownOnce('v')) // Ctrl+v
        {
          this.paste();
        }
        
        
        if (input.keyDownOnce(char(127))) {
          if (editingPlaceable != null) {
            placeableset.remove(editingPlaceable.id);
            changesMade = true;
          }
        }
        
        renderPlaceables();

        
        // Create new text if a blank area has been clicked.
        // Clicking in a blank area will create new text
        // however, there's some exceptions to that rule
        // and the following conditions need to be met:
        // 1. There's no minimenu open
        // 2. There's no gui element being interacted with
        // Oh also scroll if we're dragging instead.
        if (editingPlaceable == null && !ui.miniMenuShown()) {
          // Check back to see if something's been clicked.
          if (clickedThing) {
            if (!readOnly) {
              insertText("", engine.mouseX(), engine.mouseY()-20);
              // And in android
              openTouchKeyboard();
            }
          }
          else {
            closeTouchKeyboard();
          }
          
          if (scrolling && !movingSlider) {
            power.setAwake();
            scrollVelocity = (input.mouseY()-prevMouseY);
          }
          else {
            scrollVelocity *= PApplet.pow(0.92, display.getDelta());
          }
        }
        prevMouseY = input.mouseY();
        input.scrollOffset += scrollVelocity;
        

        
        // Power stuff
        // If we're dragging a sprite, we want framerates to be smooth, so temporarily
        // set framerates higher while we're dragging around.
        if (placeableSprites.selectedSprite != null) {
          if (placeableSprites.selectedSprite.repositionDrag.isDragging() || placeableSprites.selectedSprite.resizeDrag.isDragging()) {
            engine.power.setAwake();
            
            // While we're here, a sprite is being dragged which means changes to the file.
            changesMade = true;
          }
          else {
            engine.power.setSleepy();
          }
          
          // Just check for changes
          // Technically (as of now) just for images (text will never see this code)
          // but can also apply to any new future placeables in the future.
          if (placeableSprites.selectedSprite.resizeDrag.isDragging()) {
            changesMade = true;
          }
        }
    }
    
    public String preparingCameraMessage = "Starting camera...";
    public boolean takePhoto = false;
    public float cameraFlashEffect = 0.;
    public void renderPhotoTaker() {
      app.textFont(engine.DEFAULT_FONT);
      if (!camera.ready.get()) {
        
        textAlign(CENTER, CENTER);
        textSize(30);
        if (camera.error.get() == true) {
          display.imgCentre("error", WIDTH/2, HEIGHT/2);
          String errorMessage = "";
          fill(255, 0, 0);
          switch (camera.errorCode.get()) {
            case ERR_UNKNOWN:
              errorMessage = "An unknown error has occured.";
            break;
            case ERR_NO_CAMERA_DEVICES:
              errorMessage = "No camera devices found.";
            break;
            case ERR_FAILED_TO_SWITCH:
              errorMessage = "A weird error occured with switching cameras.";
            break;
            case ERR_UNSUPPORTED_SYSTEM:
              errorMessage = "Camera is unsupported on your system, sorry :(";
            break;
            default:
              errorMessage = "An unknown error has occured.";
              console.bugWarnOnce("renderPhotoTaker: Unused error code.");
            break;
          }
          text(errorMessage, WIDTH/2, HEIGHT/2+120);
        }
        else {
          ui.loadingIcon(WIDTH/2, HEIGHT/2);
          fill(255);
          text("Starting camera...", WIDTH/2, HEIGHT/2+120);
        }
      }
      else {
        PImage pic = camera.updateImage();
        if (pic != null && pic.width > 0 && pic.height > 0) {
          
          float aspect = float(pic.height)/float(pic.width);
          app.image(pic, 0, 0, WIDTH, WIDTH*aspect);
          if (takePhoto) {
            app.blendMode(ADD);
            app.noStroke();
            app.fill(cameraFlashEffect);
            app.rect(0,0, WIDTH, HEIGHT);
            app.blendMode(NORMAL);
            cameraFlashEffect -= 20.*display.getDelta();
            if (cameraFlashEffect < 10.) {
              takePhoto = false;
              this.endCamera();
            }
          }
        }
        //engine.timestamp("start image");
        //app.beginShape();
        //engine.timestamp("texture");
        //app.texture(pic);
        //engine.timestamp("verticies");
        //app.vertex(x1, y1, 0, 0);           // Bottom left
        //app.vertex(x2,     y1, 1., 0);    // Bottom right
        //app.vertex(x2,     y2, 1., 1.); // Top right
        //app.vertex(x1,       y2, 0, 1.);  // Top left
        //app.endShape();
        //engine.timestamp("end image");
      }
    }
    
    public void display() {
      if (engine.power.getPowerMode() != PowerMode.MINIMAL) {
        app.pushMatrix();
        app.translate(screenx,screeny);
        app.scale(display.getScale());
        this.backg();
        
        this.content();
        this.lowerBar();
        this.upperBar();
        app.popMatrix();
      }
    }
    
    int before = 0;

    public void content() {
      if (loading) {
        ui.loadingIcon(WIDTH/2, HEIGHT/2);
        stats.recordTime("editor_loading_time");
      }
      else {
        if (cameraMode) {
          renderPhotoTaker();
        }
        else {
          // We pretty much just render all of the placeables here.
          renderEditor();
        }
      }
      
      stats.recordTime("time_in_editor");
      stats.increase("total_frames_editor", 1);
    }

    public void startupAnimation() {
        // As soon as the window finishes sliding in, roll down the upper bar.
        // Beautiful animation :twinkle_emoji:
        upperBarDrop = INITIALISE_DROP_ANIMATION;
        upperbarExpand = 1.0;
        showGUI = true;
    }
    
    public void endScreenAnimation() {
      free();
      engine.allowShowCommandPrompt = true;
    }
    
    public void finalize() {
      //free();
    }
    
    public void free() {
       // Clear the images from systemimages to clear up used images.
       for (String s : imagesInEntry) {
         display.systemImages.remove(s);
       }
       imagesInEntry.clear();
    }
}





















public class ReadOnlyEditor extends Editor {
  protected SpriteSystemPlaceholder readonlyEditorUI;
  
  public ReadOnlyEditor(TWEngine engine, String entryPath, PGraphics c, boolean doMultithreaded) {
    super(engine, entryPath, c, doMultithreaded);
    setupp();
  }
  
  public ReadOnlyEditor(TWEngine e, String entryPath) {
    super(e, entryPath);
    setupp();
  }
  
  void setupp()
  {
    readOnly = true;
    input.scrollOffset = -UPPER_BAR_DROP_WEIGHT;
    
    readonlyEditorUI = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/readonlyeditor/");
    readonlyEditorUI.repositionSpritesToScale();
    readonlyEditorUI.interactable = false;
  }
  
  public void upperBar() {
    fabric();
    display.recordRendererTime();
    app.fill(myUpperBarColor);
    app.noStroke();
    app.rect(0, 0, WIDTH, myUpperBarWeight);
    display.recordLogicTime();
    display.defaultShader();
    
    // display our very small ui
    ui.useSpriteSystem(readonlyEditorUI);
    
    if (ui.buttonVary("back-button", "back_arrow_128", "Back")) {
      // This only exists because we can only have one prev screen at a time
      // and I swear to god I hate this and this is gonna get changed sooner or later.
      // In fact I may call this with a TODO.
      // TODO: Please change this. A weak spot that makes the editor class non-modular.
      if (!(engine.getPrevScreen() instanceof PixelRealmWithUI)) {
        sound.stopMusic();
        previousScreen();
        //requestScreen(new Startup(engine));
      }
      else {
        previousScreen();
      }
    }
    
    readonlyEditorUI.updateSpriteSystem();
  }
  
  public void lowerBar() {
    fabric();
    display.recordRendererTime();
    app.fill(myLowerBarColor);
    app.noStroke();
    app.rect(0, HEIGHT-myLowerBarWeight, WIDTH, myLowerBarWeight);
    display.recordLogicTime();
    display.defaultShader();
  }
}



public class CreditsScreen extends ReadOnlyEditor {
  public final static String CREDITS_PATH        = "engine/entryscreens/acknowledgements.timewayentry";
  public final static String CREDITS_PATH_PHONE  = "engine/entryscreens/acknowledgements_phone.timewayentry";
  
  public CreditsScreen(TWEngine engine) {
    // Kinda overcoming an unnecessary java limitation where super must be the first statement,
    // we choose the phone version (for condensed screens) or the normal version.
    super(engine, engine.display.phoneMode ? engine.APPPATH+CREDITS_PATH_PHONE : engine.APPPATH+CREDITS_PATH);
  }
  
  public void content() {
    input.scrollOffset -= display.getDelta()*0.7;
    power.setAwake();
    super.content();
  }
  
  protected boolean customCommands(String command) {
    if (command.equals("/edit") || command.equals("/editcredits")) {
      console.log("Editing acknowledgements.");
      requestScreen(new Editor(engine, display.phoneMode ? engine.APPPATH+CREDITS_PATH_PHONE : engine.APPPATH+CREDITS_PATH));
      return true;
    }
    else return false;
  }
}


// TODO: Add minimized setting.

public class SettingsScreen extends ReadOnlyEditor {
  public final static String SETTINGS_PATH        = "engine/entryscreens/settings.timewayentry";
  public final static String SETTINGS_PATH_PHONE  = "engine/entryscreens/settings_phone.timewayentry";
  
  public SettingsScreen(TWEngine engine) {
    // Kinda overcoming an unnecessary java limitation where super must be the first statement,
    // we choose the phone version (for condensed screens) or the normal version.
    //super(engine, engine.display.phoneMode ? engine.APPPATH+SETTINGS_PATH_PHONE : engine.APPPATH+SETTINGS_PATH, null, false);
    super(engine, engine.APPPATH+SETTINGS_PATH, null, false);
    
    loadSettings();
    get("invalid_path_error").visible = !(file.exists(getInputField("home_directory").inputText) && file.isDirectory(getInputField("home_directory").inputText));
  }
  
  
  
  
    
  protected BooleanFieldPlaceable getBooleanField(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new BooleanFieldPlaceable("null");
    }
    try {
      return (BooleanFieldPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access BooleanFieldPlaceable but is "+get(name).getClass().getSimpleName());
      return new BooleanFieldPlaceable("null");
    }
  }
  
  protected ButtonPlaceable getButton(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new ButtonPlaceable("null");
    }
    try {
      return (ButtonPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access ButtonPlaceable but is "+get(name).getClass().getSimpleName());
      return new ButtonPlaceable("null");
    }
  }
  
  protected InputFieldPlaceable getInputField(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new InputFieldPlaceable("null");
    }
    try {
    return (InputFieldPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access InputFieldPlaceable but is "+get(name).getClass().getSimpleName());
      return new InputFieldPlaceable("null");
    }
  }
  
  protected SliderFieldPlaceable getSliderField(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new SliderFieldPlaceable("null");
    }
    try {
    return (SliderFieldPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access SliderFieldPlaceable but is "+get(name).getClass().getSimpleName());
      return new SliderFieldPlaceable("null");
    }
  }
  
  protected SliderIntFieldPlaceable getSliderIntField(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new SliderIntFieldPlaceable("null");
    }
    try {
      return (SliderIntFieldPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access SliderIntFieldPlaceable but is "+get(name).getClass().getSimpleName());
      return new SliderIntFieldPlaceable("null");
    }
  }

  protected OptionsFieldPlaceable getOptionsField(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new OptionsFieldPlaceable("null");
    }
    try {
    return (OptionsFieldPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access OptionsFieldPlaceable but is "+get(name).getClass().getSimpleName());
      return new OptionsFieldPlaceable("null");
    }
  }
  
  
  private void loadSettings() {
    getBooleanField("dynamic_framerate").state = settings.getBoolean("dynamic_framerate", true);
    getBooleanField("more_ram").state = !settings.getBoolean("low_memory", false);
    getBooleanField("scale_down_images").state = settings.getBoolean("auto_scale_down", false);
    getSliderField("scroll_sensitivity").setVal(settings.getFloat("scroll_sensitivity", 20f));
    
    String newRealmAction = settings.getString("new_realm_action", "prompt");
    if (newRealmAction.equals("prompt")) newRealmAction = "Prompt realm templates";
    if (newRealmAction.equals("default")) newRealmAction = "Create default realm files";
    if (newRealmAction.equals("nothing")) newRealmAction = "Do nothing";
    getOptionsField("new_realm").selectedOption = newRealmAction;
    
    getSliderIntField("pixelation_scale").setVal(settings.getInt("pixelation_scale", 4)-1);
    getBooleanField("enable_caching").state = settings.getBoolean("caching", true);
    
    String powerMode = settings.getString("force_power_mode", "Auto");
    if (powerMode.equals("HIGH")) powerMode = "60 FPS";
    if (powerMode.equals("NORMAL")) powerMode = "30 FPS";
    if (powerMode.equals("SLEEPY")) powerMode = "10 FPS";
    if (powerMode.equals("AUTO")) powerMode = "Auto";
    getOptionsField("target_framerate").selectedOption = powerMode;
    getBooleanField("sleep_when_inactive").state = settings.getBoolean("sleep_when_inactive", true);
    
    
    getInputField("home_directory").inputText = settings.getString("home_directory", System.getProperty("user.home").replace('\\', '/'));
    getBooleanField("music_caching").state = settings.getBoolean("music_caching", true);
    getBooleanField("backup_realm_files").state = settings.getBoolean("backup_realm_files", true);
    getSliderField("field_of_view").setVal(settings.getFloat("fov", 60f));
    getSliderField("volume").setVal(settings.getFloat("volume_normal", 1f));
    getSliderField("minimized_volume").setVal(settings.getFloat("volume_quiet", 0.25f));
    getBooleanField("show_fps").state = settings.getBoolean("show_fps", false);
    getBooleanField("enable_plugins").state = settings.getBoolean("enable_plugins", false);
  }
  
  public void endScreenAnimation() {
    super.endScreenAnimation();
    power.setDynamicFramerate(settings.setBoolean("dynamic_framerate", getBooleanField("dynamic_framerate").state));
    engine.setLowMemory(!getBooleanField("more_ram").state);
    settings.setBoolean("auto_scale_down", getBooleanField("scale_down_images").state);
    input.scrollSensitivity = settings.setFloat("scroll_sensitivity", getSliderField("scroll_sensitivity").getVal());
    
    String selected = getOptionsField("new_realm").selectedOption;
    if (selected.equals("Prompt realm templates")) {
      settings.setString("new_realm_action", "prompt");
    }
    else if (selected.equals("Create default realm files")) {
      settings.setString("new_realm_action", "default");
    }
    else if (selected.equals("Do nothing")) {
      settings.setString("new_realm_action", "nothing");
    }
    
    settings.setInt("pixelation_scale", getSliderIntField("pixelation_scale").getValInt());
    settings.setBoolean("caching", getBooleanField("enable_caching").state);
    power.allowMinimizedMode = settings.setBoolean("sleep_when_inactive", getBooleanField("sleep_when_inactive").state);
    
    selected = getOptionsField("target_framerate").selectedOption;
    if (selected.equals("60 FPS")) selected = settings.setString("force_power_mode", "HIGH");
    else if (selected.equals("30 FPS")) selected = settings.setString("force_power_mode", "NORMAL");
    else if (selected.equals("10 FPS")) selected = settings.setString("force_power_mode", "SLEEPY");
    else if (selected.equals("Auto")) selected = settings.setString("force_power_mode", "AUTO");
    power.setForcedPowerMode(selected);
    
    
    engine.DEFAULT_DIR = settings.setString("home_directory", file.directorify(getInputField("home_directory").inputText));
    engine.CACHE_MUSIC = settings.setBoolean("music_caching", getBooleanField("music_caching").state); 
    settings.setBoolean("backup_realm_files", getBooleanField("backup_realm_files").state); 
    settings.setFloat("fov", getSliderField("field_of_view").getVal());
    sound.VOLUME_NORMAL = settings.setFloat("volume_normal", getSliderField("volume").getVal());
    sound.VOLUME_QUIET = settings.setFloat("volume_quiet", getSliderField("minimized_volume").getVal());
    display.showFPS = settings.setBoolean("show_fps", getBooleanField("show_fps").state);
    settings.setBoolean("enable_plugins", getBooleanField("enable_plugins").state);
    
    System.gc();
  }
  
  public void content() {
    //power.setAwake();
    super.content();
    
    input.scrollSensitivity = getSliderField("scroll_sensitivity").getVal();
    
    display.showFPS = getBooleanField("show_fps").state;
    
    // Update volume (once every 10 frames cus I'm scared of changing it every frame).
    if (app.frameCount % 10 == 0) {
      sound.setMasterVolume(getSliderField("volume").getVal());
    }
    power.allowMinimizedMode = getBooleanField("sleep_when_inactive").state;
    
    // Show "not recommended" warning when target framerate is set to SLEEPY.
    get("target_framerate_warning").visible = getOptionsField("target_framerate").selectedOption.equals("10 FPS");
    
    // Show "not found" error if home dir path is not valid.
    if (input.keyOnce) {
      if (file.exists(getInputField("home_directory").inputText) && file.isDirectory(getInputField("home_directory").inputText)) {
        get("invalid_path_error").visible = false;
      }
      else {
        get("invalid_path_error").visible = true;
      }
    }
    
    
    if (getButton("keybind_settings").clicked) {
      sound.playSound("select_any");
      requestScreen(new KeybindSettingsScreen(engine));
    }
  }
  
  protected boolean customCommands(String command) {
    if (command.equals("/edit")) {
      console.log("Editing settings.");
      requestScreen(new Editor(engine, display.phoneMode ? engine.APPPATH+SETTINGS_PATH_PHONE : engine.APPPATH+SETTINGS_PATH));
      return true;
    }
    else return false;
  }
}




public class KeybindSettingsScreen extends ReadOnlyEditor {
  public final static String KEYBIND_SETTING_PATH        = "engine/entryscreens/keybindSettings.timewayentry";
  public final static String KEYBIND_SETTING_PATH_PHONE  = "engine/entryscreens/keybindSettings_phone.timewayentry";
  
  // When set to true, a prompt asking the user to enter a key or click will appear,
  // which appears when changing a keybinding.
  private boolean enterInputPrompt = false;
  private boolean resetPrompt = false;
  private String settingKey = "";
  
  // Technically, the settings and this code is so bad because it's redundant and doing things like changing
  // the default controls means you need to change all instances of the controls used, PLUS you need to change
  // the code here. 
  // Bad coding practice, but I can't really see a way around it with the current system, and quite frankly, it
  // isn't my top priority to keep this part of the code redundant-proof.
  // It is, somehow, my priority to type long comments like this tho.
  private String[] keybindings = {
      "move_forward",
      "move_backward",
      "move_right",
      "move_left",
      "turn_right",
      "turn_left",
      "dash",
      "search",
      "jump",
      "primary_action",
      "secondary_action",
      "menu",
      "inventory_select_right",
      "inventory_select_left",
      "next_subtool",
      "prev_subtool",
      "scale_up",
      "scale_down",
      "prev_directory",
      "move_slow"
  };
  
  private char[] defaultBindings = {
      'w',
      's',
      'd',
      'a',
      'e',
      'q',
      TWEngine.InputModule.SHIFT_KEY,
      '\n',
      ' ',
      'o',
      'p',
      '\t',
      '.',
      ',',
      ']',
      '[',
      '=',
      '-',
      '\b',
      TWEngine.InputModule.ALT_KEY
  };
  
  // Duplicate code but whatever.
  protected ButtonPlaceable getButton(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new ButtonPlaceable("null");
    }
    try {
      return (ButtonPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access ButtonPlaceable but is "+get(name).getClass().getSimpleName());
      return new ButtonPlaceable("null");
    }
  }
  
  public KeybindSettingsScreen(TWEngine engine) {
    //super(engine, engine.display.phoneMode ? engine.APPPATH+CREDITS_PATH_PHONE : engine.APPPATH+CREDITS_PATH);
    super(engine, engine.APPPATH+KEYBIND_SETTING_PATH, null, false);
    loadSettings();
  }
  
  private void loadSettings() {
    for (int i = 0; i < keybindings.length; i++) {
      getButton(keybindings[i]).text = input.keyTextForm(settings.getKeybinding(keybindings[i], defaultBindings[i]));
    }
  }
  
  public void content() {
    power.setAwake();
    super.content();

    app.fill(255);
    app.textFont(engine.DEFAULT_FONT, 24);
    app.textAlign(CENTER, CENTER);
    if (enterInputPrompt) {
      ui.useSpriteSystem(readonlyEditorUI);
      //readonlyEditorUI.interactable = true;
      readonlyEditorUI.sprite("keybinding_prompt_back", "black");
      float x = readonlyEditorUI.getSprite("keybinding_prompt_back").getX();
      float y = readonlyEditorUI.getSprite("keybinding_prompt_back").getY();
      app.text("Enter key or mouse input...", x+300f, y+80f);
      
      if (display.getTimeSeconds() % 1f < 0.5f) {
        display.imgCentre("keybinding_1_128", x+300f, y+130f);
      }
      else {
        display.imgCentre("keybinding_2_128", x+300f, y+130f);
      }
      
      if (input.keyOnce || input.shiftOnce || input.ctrlOnce || input.altOnce) {
        enterInputPrompt = false;
        settings.setKeybinding(settingKey, input.getLastKeyPressed());
        getButton(settingKey).text = input.keyTextForm(input.getLastKeyPressed());
      }
      else if (input.primaryOnce) {
        enterInputPrompt = false;
        settings.setKeybinding(settingKey, TWEngine.InputModule.LEFT_CLICK);
        getButton(settingKey).text = "Left click";
      }
      else if (input.secondaryOnce) {
        enterInputPrompt = false;
        settings.setKeybinding(settingKey, TWEngine.InputModule.RIGHT_CLICK);
        getButton(settingKey).text = "Right click";
      }
    }
    else if (resetPrompt) {
      ui.useSpriteSystem(readonlyEditorUI);
      //readonlyEditorUI.interactable = true;
      readonlyEditorUI.sprite("keybinding_reset_back", "black");
      float x = readonlyEditorUI.getSprite("keybinding_reset_back").getX();
      float y = readonlyEditorUI.getSprite("keybinding_reset_back").getY();
      app.text("Are you sure you want to reset to defaults?\nThis cannot be undone.", x+315f, y+50f);
      
      if (ui.buttonVary("keybindings_reset_yes", "tick_128", "Yes")) {
        sound.playSound("select_any");
        resetPrompt = false;
        for (int i = 0; i < keybindings.length; i++) {
          settings.setKeybinding(keybindings[i], defaultBindings[i]);
          getButton(keybindings[i]).text = input.keyTextForm(defaultBindings[i]);
        }
        console.log("Reset keybindings.");
      }
      if (ui.buttonVary("keybindings_reset_no", "cross_128", "No")) {
        sound.playSound("select_any");
        resetPrompt = false;
      }
    }
    else {
      for (int i = 0; i < keybindings.length; i++) {
        if (getButton(keybindings[i]).clicked) {
          sound.playSound("select_any");
          settingKey = keybindings[i];
          enterInputPrompt = true;
        }
      }
      
      if (getButton("reset_button").clicked) {
        sound.playSound("select_any");
        resetPrompt = true;
      }
    }
  }
  
  public void endScreenAnimation() {
    
  }
  
  protected boolean customCommands(String command) {
    if (command.equals("/edit")) {
      console.log("Editing settings.");
      requestScreen(new Editor(engine, display.phoneMode ? engine.APPPATH+KEYBIND_SETTING_PATH_PHONE : engine.APPPATH+KEYBIND_SETTING_PATH));
      return true;
    }
    else return false;
  }
}
