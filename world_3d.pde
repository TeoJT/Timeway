import java.util.concurrent.atomic.AtomicBoolean;
import javax.sound.midi.*;
import java.io.BufferedInputStream;
import processing.sound.*;
import java.nio.file.attribute.*;
import java.nio.file.*;

// Optimisations to be made:
// - Rather than update the image on every single coin sprite, change the image the coin sprites use.
// - Object3d value is technically calculated twice, once for rendering (for dist) and other for sorting (calculateVal)
// - Hovering and rendering flat 3d objects done twice; have temporary values that are calculated ONCE in the object3D
//   class rather than re-calculating everything for each Object3D.
// - Use shaders for the portal code rather than the gross old code from yestercentury when I didn't know how to code gud.
// - Only process and sort objects that are in view instead of every single one.

public class PixelRealm extends Screen {
    final String COMPATIBILITY_VERSION = "1.0";
  
    public float moveStarX = 0.;
    public float height = 0.;
    
    final int scale = 4;
    
    public PImage img_glow;
    public PImage img_grass;
    public PImage img_neonTest;
    public PImage img_coin[] = new PImage[6];
    public PImage img_tree;
    public PImage img_nightskyStars[] = new PImage[4];
    public SoundFile snd_bgm;
    
    // Reallllly sorry.
    public PGraphics background;
    public PImage img_sky_1;
    
    public boolean lights = false;
    public boolean finderEnabled = false;
    
    public final static String REALM_GRASS = ".pixelrealm-grass.png";
    public final static String REALM_MUSIC = ".pixelrealm-music.wav";
    public final static String REALM_SKY   = ".pixelrealm-sky.png";
    public final static String REALM_TREE  = ".pixelrealm-terrain_object-1.png";
    public final static String REALM_BGM   = ".pixelrealm-bgm.wav";
    public final static String REALM_SEQ   = ".pixelrealm-bgm.mid";
    public final static String REALM_TURF  = ".pixelrealm-turf.json";
    
    public PImage REALM_GRASS_DEFAULT;
    public PImage REALM_MUSIC_DEFAULT;
    public PImage REALM_SKY_DEFAULT;
    public PImage REALM_TREE_DEFAULT;
    public static final String REALM_BGM_DEFAULT = "data/engine/sound/birds.wav";
    public Sequencer REALM_SEQ_DEFAULT = null;
    
    PGraphics scene, portal;
    SpriteSystemPlaceholder guiMainToolbar;
    
    public float xpos = 1000.0, ypos = 0., zpos = 1000.0;
    public float yvel = 0.;
    public float direction = PI;
    public float bob = 0.0;
    public float onQuadY = 0.;
    public int jumpTimeout = 0;
    
    public Stack<FileObject> inventory;
    public HashSet<FileObject> inventoryContents;
    
    private float flatSinDirection;
    private float flatCosDirection;
    
    // For use with the sky, we need to declair it as a global variable since we
    // want to update it AFTER direction has been updated.

    // All of this is stupid
    public boolean isWalking = false;
    public boolean nearObject = false;
    public boolean repositionMode = false;
    public boolean menuShown = false;
    
    int coinSpinAnimation = 0;
    
    
    final float bob_Speed = 0.4;
    final float WALK_SPEED = 7.0;
    final float RUN_SPEED = 15.0;
    final float SNEAK_SPEED = 1.5;
    final float TURN_SPEED = 0.05;
    final float SLOW_TURN_SPEED = 0.01;
    final float TERMINAL_VEL = 1000.;
    final float GRAVITY = 0.2;
    final float JUMP_STRENGTH = 5.;
    final float PLAYER_HEIGHT = 80;
    final float PLAYER_WIDTH  = 20;
    
    
    Object3D coins[];
    FileObject[] files;
    public DirectoryPortal prevPortal;
    private int collectedCoins = 0;
    
    private AtomicBoolean refreshRealm = new AtomicBoolean(false);
    
    
    final int RENDER_DISTANCE = 6;
    final int GROUND_REPEAT = 2;
    final int GROUND_SIZE = 400;
    final float FADE_DIST_OBJECTS = pow((RENDER_DISTANCE-4)*GROUND_SIZE,2);
    final float FADE_DIST_GROUND = pow(GROUND_SIZE*max(RENDER_DISTANCE-3, 0),2);
    
    public float portalLight = 255.;
    public final float MIN_PORTAL_LIGHT_THRESHOLD = pow(140.,2);
    public int portalCoolDown = 45;
    
    final boolean BIG_HITBOX = true;
    final boolean SMALL_HITBOX = false;
    
    private boolean obstructionFront = false;
    
    HashSet<String> autogenStuff;
    
    // Our custom stack class that allows for emptying the stack in a single step.
    Stack<Object3D> terrainObjects;
    
    public int worldThemeSky = 0;
    
    private Object3D tailNode = null;
    private Object3D headNode = null;
    private int numObjects = 0;

    class NightSkyStar {
        boolean active;
        float x;
        float y;
        int image;
        int config;
    }
    NightSkyStar[] nightskyStars;
    final int MAX_NIGHT_SKY_STARS = 100;
    
    class TerrainObject3D extends Object3D {
      public TerrainObject3D(float x, float y, float z, float size, String id) {
        super(x,y,z);
        this.img = img_tree;
        this.setSize(size);
        this.hitboxSize = SMALL_HITBOX;
        autogenStuff.add(id);
      }
    }
    
    class FileObject extends Object3D {
      public String dir;
      public String filename;
      public FileObject(float x, float y, float z, String dir) {
        super(x,y,z);
        setFileNameAndIcon(dir);
      }
      
      public FileObject(String dir) {
        super();
        setFileNameAndIcon(dir);
      }
      
      public void setFileNameAndIcon(String dir) {
        dir = dir.replace('\\', '/');
        this.dir = dir;
        this.filename = engine.getFilename(dir);
        engine.systemImages.get(engine.extIcon(this.filename));
      }
      
      public void display() {
        super.display(true);
      }
      
      public void load() {
        // We expect the engine to have already loaded a JSON object.
        // Every 3d object has x y z position.
        this.x = engine.getJSONFloat("x", random(-4000, 4000));
        this.y = engine.getJSONFloat("y", 0.);
        this.z = engine.getJSONFloat("z", random(-4000, 4000));
      }
      
      public JSONObject save() {
          JSONObject object3d = new JSONObject();
          object3d.setString("filename", this.filename);
          object3d.setFloat("x", this.x);
          object3d.setFloat("y", this.y);
          object3d.setFloat("z", this.z);
          return object3d;
      }
      
    }
    
    class ImageFileObject extends FileObject {
      public float rot = 0.;
      
      
      public boolean loadFlag = false;
      public boolean cacheFlag = false;
      
      public ImageFileObject(float x, float y, float z, String dir) {
        super(x,y,z,dir);
      }
      
      public ImageFileObject(String dir) {
        super(dir);
      }
      
      public void display() {
        if (visible) {
          if (this.img != null) {
            if (!loadFlag) {
              if (img.width > 0 && img.height > 0) {
                
                // If the image HASN'T been cached (same as using a boolean called cachedFlag)
                // the image hasn't been cached, so let's create some to reduce load times
                // and ram usage in the future.
                if (cacheFlag) {
                  engine.setCachingShrink(128, 0);
                  engine.saveCacheImage(this.dir, img);
                  cacheFlag = true;
                }
                
                // Set load flag to true
                loadFlag = true;
              }
            }
            if (img.width > 0 && img.height > 0 && loadFlag) {
              setSize(1.);
              float y1 = y-hi;
              // There's no y2 huehue.
              
              // Half width
              float hwi = wi/2;
              float sin_d = sin(rot)*(hwi);
              float cos_d = cos(rot)*(hwi);
              float x1 = x + sin_d;
              float z1 = z + cos_d;
              float x2 = x - sin_d;
              float z2 = z - cos_d;
              
              displayQuad(x1,y1,z1,x2,y1+hi,z2,true);
            }
          }
        }
      }
      
      public void load() {
        super.load();
        
        
        
        this.img = engine.tryLoadImageCache(this.dir, new Runnable() {
          public void run() {
            cacheFlag = true;
            engine.setOriginalImage(requestImage(dir));
          }
        });
      console.info("loaded");
        
        
        this.rot = engine.getJSONFloat("rot", random(-PI, PI));
      }
      
      public JSONObject save() {
        JSONObject object3d = super.save();
        object3d.setFloat("rot", this.rot);
        return object3d;
      }
      
      
    }
    
    class DirectoryPortal extends FileObject {
      
      public DirectoryPortal(float x, float y, float z, String dir) {
        super(x,y,z,dir);
        this.img = portal;
      }
      
      public DirectoryPortal(String dir) {
        super(dir);
      }
      
      {
        this.hitboxSize = SMALL_HITBOX;
        this.img = portal;
        setSize(1.);
      }
      
      
      public void display() {
        if (visible) {
          // Tint it based on its dir colour.
          // TODO: Eventually the world theming system will be different, remember to replace.
          //scene.colorMode(HSB, 255);
          //scene.tint(myTheme,127,255);
          //scene.colorMode(RGB, 255);
          
          // Display like normal like before
          super.display();
          
          scene.noTint();
          
          // Display text over the portal showing the directory.
          float d = direction-PI;
          //float w = img.width*size;
          float h = img.height*size;
          if (lights) scene.noLights();
          scene.pushMatrix();
          scene.translate(x, y-h+40, z);
          scene.rotateY(d);
          scene.textSize(24);
          scene.textFont(engine.DEFAULT_FONT);
          scene.textAlign(CENTER, CENTER);
          scene.fill(255);
          scene.text(filename, 0, 0, 0);
          scene.popMatrix();
          if (lights) scene.lights();
          
          // Screen glow effect.
          // Calculate distance to portal
          float dist = pow(x-xpos,2)+pow(z-zpos,2);
          if (dist < MIN_PORTAL_LIGHT_THRESHOLD) {
            // If close to the portal, set the portal light to create a portal enter/transistion effect.
            portalLight = max(portalLight, (1.-(dist/MIN_PORTAL_LIGHT_THRESHOLD))*255.);
          }
        }
      }
    }
    
    public Object3D closestObject = null;
    public float closestVal = 0.;
    
    class Object3D {
      public int id;
      public float x;
      public float y;
      public float z;
      public PImage img = null;;
      protected float size = 1.;
      protected float wi = 0.;
      protected float hi = 0.;
      public boolean hitboxSize = BIG_HITBOX;
      public float val;
      public Object3D next = null;
      public Object3D prev = null;
      public boolean visible = true;
      
      public Object3D() {
        addToList(this);
      }
      
      public Object3D(float x, float y, float z) {
        this.x = x;
        this.y = y;
        this.z = z;
        addToList(this);
      }
      
      public void calculateVal() {
        float x = xpos-this.x;
        float y = ypos-this.y;
        float z = zpos-this.z;
        this.val = x*x + y*y + z*z;
      }
      
      public boolean touchingPlayer() {
        float sw = wi/2;
        float spw = PLAYER_WIDTH/2;  
        if (hitboxSize == SMALL_HITBOX) {
          sw = wi/4;
          spw = 0;
        }
        return (xpos-spw < (x+sw)
        && (xpos+spw > (x-sw)) 
        && ((zpos-spw) < (z+sw)) 
        && ((zpos+spw) > (z-sw)) 
        && (ypos-PLAYER_HEIGHT < (y)) 
        && (ypos > (y-hi)));
      }
      
      public void checkHovering() {
        float d_sin = flatSinDirection*(wi/2);
        float d_cos = flatCosDirection*(wi/2);
        float x1 = x + d_sin;
        float z1 = z + d_cos;
        float x2 = x - d_sin;
        float z2 = z - d_cos;
        
        final float SELECT_FAR = 500.;
        
        float beamX1 = xpos;
        float beamZ1 = zpos;
        
        float beamX2 = xpos+sin(direction)*SELECT_FAR;
        float beamZ2 = zpos+cos(direction)*SELECT_FAR;
        
        if (lineLine(x1,z1,x2,z2,beamX1,beamZ1,beamX2,beamZ2)) {
          if (this.val < closestVal) {
            closestVal = this.val;
            closestObject = this;
          }
        }
      }
      
      // Note: you need to run checkHovering for all hoverable 3d objects first.
      public boolean hovering() {
        return (closestObject == this);
      }
      
      public boolean selectedLeft() {
        return hovering() && engine.leftClick;
      }
      
      public boolean selectedRight() {
        return hovering() && engine.rightClick;
      }
      
      public void destroy() {
        removeFromList(this);
      }
      
      public void setSize(float size) {
        this.size = size;
        if (img == null) {
          console.bugWarn("You shouldn't be setting the size if you don't have an image!");
          return;
        }
        this.wi = float(img.width)*size;
        this.hi = float(img.height)*size;
      }
      
      public void display() {
        this.display(false);
      }
      
      public void display(boolean useFinder) {
        if (visible) {
          if (img == null)
            return;
          
          float y1 = y-hi;
          // There's no y2 huehue.
          
          // Half width
          float hwi = wi/2;
          float sin_d = flatSinDirection*(hwi);
          float cos_d = flatCosDirection*(hwi);
          float x1 = x + sin_d;
          float z1 = z + cos_d;
          float x2 = x - sin_d;
          float z2 = z - cos_d;
          
          displayQuad(x1,y1,z1,x2,y1+hi,z2,useFinder);
        }
      }
      
      protected void displayQuad(float x1, float y1, float z1, float x2, float y2, float z2, boolean useFinder) {
        //boolean selected = lineLine(x1,z1,x2,z2,beamX1,beamZ1,beamX2,beamZ2);
        //color selectedColor = color(255);
        //if (hovering()) {
        //  selectedColor = color(255, 127, 127);
        //}
        
        useFinder &= finderEnabled;
        
        //Now render the image in 3D!!!
        
        //Add some fog for objects as they get further away.
        //Note that if the transparacy is 100%, the object will not be rendered at all.
        float dist = pow((xpos-x), 2)+pow((zpos-z), 2);
        
        boolean dontRender = false;
        if (dist > FADE_DIST_OBJECTS) {
          float fade = calculateFade(dist, FADE_DIST_OBJECTS);
          if (fade > 1) {
            scene.tint(255, fade);
          }
          else {
            dontRender = true;
          }
        }
        else scene.tint(255, 255);
        
        
        if (useFinder) {
          scene.stroke(255, 127, 127);
          scene.strokeWeight(2.);
          scene.noFill();
        }
        else {
          scene.noStroke();
        }
        
        if (!dontRender || useFinder) {
          scene.pushMatrix();
          
          
          scene.beginShape();
          if (!dontRender) {
            scene.textureMode(NORMAL);
            scene.textureWrap(REPEAT);
            scene.texture(img);
          }
          scene.vertex(x1, y1, z1, 0, 0);           // Bottom left
          scene.vertex(x2,     y1, z2, 0.995, 0);    // Bottom right
          scene.vertex(x2,     y2, z2, 0.995, 0.995); // Top right
          scene.vertex(x1,       y2, z1, 0, 0.995);  // Top left
          if (useFinder) scene.vertex(x1, y1, z1, 0, 0);  // Extra vertex to render a complete square if finder is enabled.
                                                              // Not necessary if just rendering the quad without the line.
          scene.noTint();
          scene.endShape();
          
          scene.popMatrix();
        }
      }
    }
    
    
    public void addToList(Object3D o) {
       if(headNode == null) {  
            headNode = tailNode = o;
            headNode.prev = null;
            tailNode.next = null;  
        }  
        else {  
            //add newNode to the end of list. tail->next set to newNode  
            tailNode.next = o;  
            //newNode->previous set to tail  
            o.prev = tailNode;  
            //newNode becomes new tail  
            tailNode = o;  
            //tail's next point to null  
            tailNode.next = null;  
        }  
        numObjects++;
    }
    
    public void removeFromList(Object3D o) {
      if (o == headNode)
        headNode = o.next;
      
      if (o == tailNode)
        tailNode = o.prev;
      
      if (o.prev != null)
        o.prev.next = o.next;
        
      if (o.next != null)
        o.next.prev = o.prev;
       
      // Object should be dereferenced now.
    }
    
    
    public int operationCount = 0;
    
    // I totally didn't ask chatgpt for a merge sort algorithm shuttap.
    private Object3D mergeSort(Object3D head) {
        operationCount++;
        if (head == null || head.next == null) {
            return head; // Base case: list is empty or has only one element
        }

        // Split the list into two halves
        Object3D middle = getMiddle(head);
        Object3D nextOfMiddle = middle.next;
        middle.next = null;
        nextOfMiddle.prev = null;

        // Recursively sort the two halves
        Object3D left = mergeSort(head);
        Object3D right = mergeSort(nextOfMiddle);

        // Merge the sorted halves
        return merge(left, right);
    }

    private Object3D merge(Object3D left, Object3D right) {
        operationCount++;
        if (left == null) {
            return right; // Base case: left half is empty
        }
        if (right == null) {
            return left; // Base case: right half is empty
        }

        Object3D result;
        if (left.val >= right.val) {
            result = left;
            result.next = merge(left.next, right);
        } else {
            result = right;
            result.next = merge(left, right.next);
        }
        result.next.prev = result;
        result.prev = null;

        return result;
    }

    private Object3D getMiddle(Object3D head) {
        if (head == null) {
            return head;
        }

        Object3D slow = head;
        Object3D fast = head.next;

        while (fast != null && fast.next != null) {
            operationCount++;
            slow = slow.next;
            fast = fast.next.next;
        }

        return slow;
    }
    
    public Sequencer sequencer;
    
    private Sequencer loadMidiFile(String midiFile) {
      try {
        Sequencer s = MidiSystem.getSequencer();
 
        // Opens the device, indicating that it should now acquire any
        // system resources it requires and become operational.
        s.open();
 
        // create a stream from a file
        InputStream is = new BufferedInputStream(new FileInputStream(new File(midiFile)));
 
        // Sets the current sequence on which the sequencer operates.
        // The stream must point to MIDI file data.
        s.setSequence(is);
        
        return s;
      }
      catch (MidiUnavailableException e) {
        console.bugWarn("Couldn't play midi; MidiUnavailableException");
      }
      catch (IOException e) {
        console.bugWarn("Couldn't play midi; IOException");
      }
      catch (InvalidMidiDataException e) {
        console.bugWarn("Couldn't play midi; InvalidMidiDataException");
      }
      return null;
  }

    public PixelRealm(Engine engine, String dir, String emergeFrom) {
        super(engine);
        this.setup(dir, emergeFrom);
    }
    
    public PixelRealm(Engine engine, String dir) {
        super(engine);
        this.setup(dir, dir.substring(0, dir.lastIndexOf("/", dir.length()-2)));
    }
    
    public void setup(String dir, String emergeFrom) {
      
        img_glow  = engine.systemImages.get("glow");
        img_grass = engine.systemImages.get("grass");
        img_neonTest = engine.systemImages.get("neonTest");
        img_coin[0]  = engine.systemImages.get("coin_0");
        img_coin[1]  = engine.systemImages.get("coin_1");
        img_coin[2]  = engine.systemImages.get("coin_2");
        img_coin[3]  = engine.systemImages.get("coin_3");
        img_coin[4]  = engine.systemImages.get("coin_4");
        img_coin[5]  = engine.systemImages.get("coin_5");
        img_tree     = engine.systemImages.get("tree");
        img_sky_1    = engine.systemImages.get("sky_1");
        REALM_GRASS_DEFAULT = img_grass;
        REALM_MUSIC_DEFAULT = null;
        REALM_SKY_DEFAULT = img_sky_1;
        REALM_TREE_DEFAULT = img_tree;
        
        guiMainToolbar = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"gui/pixelrealm/");
        
        noiseSeed(getHash(dir));
        
        worldThemeSky = 0;
        
        this.height = engine.HEIGHT-myLowerBarWeight-myUpperBarWeight;
        
        //Now craete those offscreen graphics so we can use them for all eternity!!!!
        scene = createGraphics((int(engine.WIDTH)/scale), int(this.height)/scale, P3D);
        ((PGraphicsOpenGL)scene).textureSampling(2);                  //This strange code here just turns off smooth rendering because for some reason noSmooth() doesn't work.
        portal = createGraphics(128, 128+96, P2D);
        
        
        //img_sky_1.resize(scene.width, scene.height);
        
        //Set the position of the coins.
        coins = new Object3D[100];
        float prevX = 0.;
        float prevZ = 0.;
        for (int i = 0; i < 100; i++) {
          float x = prevX+random(0, 90);
          float z = prevZ+random(-500, 500);
          prevX = x;
          prevZ = z;
          Object3D coin = new Object3D(x, onSurface(x,z), z);
          coin.img = img_coin[0];
          coin.setSize(0.25);
          coin.hitboxSize = BIG_HITBOX;
          coins[i] = coin;
          
        }
        
        //Reset the particles in the portal(s).
        for (int i = 0; i < portPartNum; i++) {
          portPartX[i] = -999;
        }
        
        String prevDir = dir.substring(0, dir.lastIndexOf('/', dir.length()-2)+1);
        //prevPortal = new DirectoryPortal(xpos-200, 0, zpos, 1., SMALL_HITBOX, prevDir, "[prev]");
        
        // Because our stack holds the generated terrain objects which is generated by the floor tiles,
        // this means that there could theoretically be at most renderDistance in the x axis times
        // renderDistance in the z axis. Hope that makes sense.
        inventory = new Stack<FileObject>(128);
        terrainObjects = new Stack<Object3D>((RENDER_DISTANCE*2)*(RENDER_DISTANCE*2));
        autogenStuff = new HashSet<String>();
        init3DObjects();
        
        loadTurfJson(dir, emergeFrom);
        
        // TODO: make the thread only load when there are changes to the files
        // and run the refreshRealm() in the main thread.
        refreshRealmInSeperateThread();
        
        refreshRealm();
        //scatterNightskyStars();
        
    }
    
    final int portPartNum = 90;
    float portPartX[] = new float[portPartNum];
    float portPartY[] = new float[portPartNum];
    float portPartVX[] = new float[portPartNum];
    float portPartVY[] = new float[portPartNum];
    float portPartTick[] = new float[portPartNum];
    
    
    public void loadTurfJson(String dir, String emergeFrom) {
        openDir(dir);
        if (dir.charAt(dir.length()-1) != '/')  dir += "/";
        if (emergeFrom.length() > 0)
          if (emergeFrom.charAt(emergeFrom.length()-1) == '/')  emergeFrom = emergeFrom.substring(0, emergeFrom.length()-1);;
        // Really really stupid bug fix.
        if (emergeFrom.equals("C:")) emergeFrom = "C:/";
        emergeFrom     = engine.getFilename(emergeFrom);
        
        // Find out if the directory has a turf file.
        File f = new File(dir+REALM_TURF);
        boolean newTurf = false;
        DirectoryPortal fromPortal = null;
        if (f.exists()) {
          if (!engine.openJSONObject(dir+REALM_TURF)) {
            console.warn("There's an error in the folder's turf file. Will now act as if the turf is new.");
            newTurf = true;
          }
          
          // Check to see if the version we're reading is compatible.
          if (!engine.getJSONString("compatibility_version", "").equals(COMPATIBILITY_VERSION)) {
            newTurf = true;
            console.log("Incompatible turf file, creating new turf.");
            engine.backupMove(dir+REALM_TURF);
          }
        }
        else newTurf = true;
        
        // Randomise the object's locations and save the turf.
        if (newTurf) {
          for (FileObject o : files) {
            engine.loadedJsonObject = new JSONObject();
            if (o != null) {
              o.load();

              // While we're at it, find the prev dir portal.
              if (o instanceof DirectoryPortal) {
                DirectoryPortal p = (DirectoryPortal)o;
                if (emergeFrom.equals(p.filename)) {
                  fromPortal = p;
                }
              }
            }
            
          }
          saveTurfJson();
        }
        else {
          JSONArray objects3d = engine.loadedJsonObject.getJSONArray("objects3d");
          if (objects3d == null) {
            console.warn("Couldn't read turf file, objects3d array is missing/misnamed.");
            return;
          }
          HashMap<String, FileObject> namesToObjects = new HashMap<String, FileObject>();
          for (FileObject o : files) {
            if (o != null) {
              namesToObjects.put(o.filename, o);
            }
          }
          
          // This is where we actually load our json.
          int l = objects3d.size();
          // Loop thru each file object in the array. Remember each object is uniquely identified by its filename.
          for (int i = 0; i < l; i++) {
            try {
              engine.loadedJsonObject = objects3d.getJSONObject(i);
              
              // Each object is uniquely identified by its filename/folder name.
              String name = engine.getJSONString("filename", engine.APPPATH+engine.GLITCHED_REALM);
              // Due to the filename used to be called "dir", check for legacy names.
              
              // Get the object by name so we can do a lil bit of things to it.
              FileObject o = namesToObjects.remove(name);
              if (o == null) {
                // This may happen if a folder/file has been renamed/deleted. Just move
                // on to the next item.
                continue;
              }
              
              // From here, the way the object is loaded is depending on its type.
              o.load();
              
              // While we're at it we can figure out which portal we're emerging from.
              if (emergeFrom.equals(o.filename)) {
                fromPortal = (DirectoryPortal)o;
              }
            }
            // For some reason we can get unexplained nullpointerexceptions.
            // Just a lazy way to overcome it, literally doesn't affect anything.
            // Totally. Totally doesn't affect anything.
            catch (RuntimeException e) {
              
            }
          }
          
          // Give any unassigned objects (e.g. new folders/portals) random positions.
          for (FileObject p : namesToObjects.values()) {
              engine.loadedJsonObject = new JSONObject();
              p.load();
          }
        }
        
        // Figure out the starting position, we want to choose a position that is clear of other portals.
        final float FROM_DIST = 150.;
        final float AREA_LENGTH = 1500.;
        final float AREA_OFFSET = 100.;
        final float AREA_WIDTH  = 100.;
        int[] portalCount = new int[4];
        // 0   +x
        // 1   +z
        // 2   -x
        // 3   -z
        if (fromPortal != null) {
          for (Object3D o : files) {
            if (o != null) {
              if (o instanceof DirectoryPortal) {
                
                // This is +z and -z
                if (o.x > fromPortal.x-AREA_WIDTH && o.x < fromPortal.x+AREA_WIDTH) {
                  // +z
                  if (o.z > fromPortal.z+AREA_OFFSET && o.z < fromPortal.z+AREA_LENGTH)
                    portalCount[1] += 1;
                  // -z
                  if (o.z < fromPortal.z-AREA_OFFSET && o.z > fromPortal.z-AREA_LENGTH)
                    portalCount[3] += 1;
                }
                if (o.z > fromPortal.z-AREA_WIDTH && o.z < fromPortal.z+AREA_WIDTH) {
                  // +x
                  if (o.x > fromPortal.x+AREA_OFFSET && o.x < fromPortal.x+AREA_LENGTH)
                    portalCount[0] += 1;
                  // -x
                  if (o.x < fromPortal.x-AREA_OFFSET && o.x > fromPortal.x-AREA_LENGTH)
                    portalCount[2] += 1;
                }
              }
            }
          }
          
          // Now we've exit the loop.
          // Check which exit has the least portals and choose that one to position the player.
          int lowest = Integer.MAX_VALUE;
          int chosenDir = 0;
          for (int i = 0; i < portalCount.length; i++) {
            if (portalCount[i] < lowest) {
              chosenDir = i;
              lowest = portalCount[i];
            }
          }
          
          // I think I'm overdoing it now lol
          // If we're going backwards, we might as well position ourselves in the opposite direction
          // This is just a really hack'd up script.
          float additionalDir = 0;
          if (engine.keyAction("moveBackwards")) {
            additionalDir = PI;
            if (chosenDir >= 2)
              chosenDir -= 2;
            else
              chosenDir += 2;
          }
          
          // Remember:
          // 0   +x
          // 1   +z
          // 2   -x
          // 3   -z
          
          // PI        -z
          // HALF_PI   +x
          // 0         +z
          // -HALF_PI  -x
          switch (chosenDir) {
            // +x
            case 0:
            xpos = fromPortal.x+FROM_DIST;
            zpos = fromPortal.z;
            direction = HALF_PI + additionalDir;
            break;
            // +z
            case 1:
            xpos = fromPortal.x;
            zpos = fromPortal.z+FROM_DIST;
            direction = 0. + additionalDir;
            break;
            // -x
            case 2:
            xpos = fromPortal.x-FROM_DIST;
            zpos = fromPortal.z;
            direction = -HALF_PI + additionalDir;
            break;
            // -z
            case 3:
            xpos = fromPortal.x;
            zpos = fromPortal.z-FROM_DIST;
            direction = PI + additionalDir;
            break;
          }
        }
    }
    
    
    public void findStartingPos(String dirName, String emergeFrom, DirectoryPortal p) {
      final float FROM_DIST = 50.;
      if (emergeFrom.equals(dirName)) {
        xpos = p.x;
        zpos = p.z-50.;
      }
    }
    
    public void saveTurfJson() {
      JSONArray objects3d = new JSONArray();
      int l = files.length;
      for (int i = 0; i < l; i++) {
        FileObject o = files[i];
        if (o != null) {
          objects3d.setJSONObject(i, o.save());
        }
      }
      
      JSONObject turfJson = new JSONObject();
      turfJson.setJSONArray("objects3d", objects3d);
      turfJson.setString("compatibility_version", COMPATIBILITY_VERSION);
      
      try {
        engine.backupAndSaveJSON(turfJson, engine.currentDir+REALM_TURF);
      }
      catch (RuntimeException e) {
        console.log("Maybe permissions are denied for this folder?");
        console.warn("Couldn't save turf json: "+e.getMessage());
      }
    }
    
    public void insertionSort() {
        if (headNode == null || headNode.next == null) {
            return; // List is empty or has only one element, so it is already sorted
        }

        Object3D current = headNode.next; // Node to be inserted into the sorted portion
        
        while (current != null) {
            Object3D nextNode = current.next; // Store the next node before modifying current.next

            boolean run = true;
            while (current.prev != null && run) {
              operationCount++;
              if (current.prev.val < current.val) {
                  // Swap them.
                  Object3D previous = current.prev;
                  Object3D next = current.next;
                  
                  previous.next = next;
                  current.prev = previous.prev;
                  current.next = previous;
                  
                  if (previous.prev != null) {
                      previous.prev.next = current;
                  }
                  previous.prev = current;
                  if (next != null) {
                      next.prev = previous;
                  }
                  
                  if (headNode == previous) {
                      headNode = current;
                  }
                  if (tailNode == current) {
                      tailNode = previous;
                  }
              }
              else run = false;
            }

            current = nextNode; // Move to the next node
        }
        
        if (tailNode == null) console.bugWarn("Null tailnode!");
    }
    
    // This took bloody ages to figure out so it better work 100% of the timeee
    // Update: turns out I didn't need to use this function but I'm gonna leave it here
    // because it still took bloody ages D:<
    public float pointTowards(float myX, float myY, float lookAtX, float lookAtY) {
      
      float rot = 0.;
      float mx = lookAtX-myX;
      float my = myY-lookAtY;
      if (my == 0) my = 1.;
      
      if (my < 0)
        rot = atan(-mx/my);
      else
        rot = atan(-mx/my)+PI;
      return rot;
    }
    
    // A version of opendir which uses the engine's opendir but then
    // creates 3d objects that resemble each item in the directory.
    public void openDir(String dir) {
      engine.openDir(dir);
      int l = engine.currentFiles.length;
      files = new FileObject[engine.currentFiles.length];
      for (int i = 0; i < l; i++) {
        if (engine.currentFiles[i] != null) {
          // Here we determine which type of object to load into our scene.
          // If it's a folder, create a portal object.
          if (engine.currentFiles[i].file.isDirectory()) {
            DirectoryPortal portal = new DirectoryPortal(0.,0.,0.,engine.currentFiles[i].file.getAbsolutePath());
            files[i] = portal;
          }
          // If it's a file, create the corresponding object based on the file's type.
          else {
            FileObject fileobject = null;
            
            FileType type = engine.extToType(engine.currentFiles[i].fileext);
            String path = engine.currentFiles[i].file.getAbsolutePath();
            switch (type) {
              case FILE_TYPE_UNKNOWN:
              fileobject = new FileObject(path);
              fileobject.img = engine.systemImages.get(engine.currentFiles[i].icon);
              fileobject.setSize(0.5);
              fileobject.hitboxSize = BIG_HITBOX;
              break;
              case FILE_TYPE_IMAGE:
              fileobject = new ImageFileObject(path);
              break;
              default:
              fileobject = new FileObject(engine.currentFiles[i].file.getAbsolutePath());
              fileobject.img = engine.systemImages.get(engine.currentFiles[i].icon);
              fileobject.setSize(0.5);
              fileobject.hitboxSize = BIG_HITBOX;
              break;
            }
            files[i] = fileobject;
            
          }
        }
      }
    }
    
    Thread refreshThread;
    
    public void refreshRealmInSeperateThread() {
      refreshThread = new Thread(new Runnable() {
          private FileTime img_sky_1_modified = getLastModified(engine.currentDir+REALM_SKY);
          private FileTime img_tree_modified  = getLastModified(engine.currentDir+REALM_TREE);
          private FileTime img_grass_modified = getLastModified(engine.currentDir+REALM_GRASS);
          
          // Leave bgm out for now since this one is complicated.
          //private FileTime bgm_modified       = null;
          public void run() {
            delay(1000);
            while (!Thread.interrupted()) {
              try {
                Thread.sleep(1000);
              }
              catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break; // Exit the loop on interruption
              }
              if (
                fileChanged(REALM_SKY, img_sky_1_modified)  ||
                fileChanged(REALM_TREE, img_tree_modified) ||
                fileChanged(REALM_GRASS, img_grass_modified))
              {
                console.log("Change detected, reloading...");
                refreshRealm.set(true);
                img_sky_1_modified = getLastModified(engine.currentDir+REALM_SKY);
                img_tree_modified  = getLastModified(engine.currentDir+REALM_TREE);
                img_grass_modified = getLastModified(engine.currentDir+REALM_GRASS);
              }
            }
          }
      });
      refreshThread.start();
    }
    
    
    public boolean fileChanged(String name, FileTime lastLastChange) {
      FileTime t = getLastModified(engine.currentDir+name);
      
      // File doesn't exist, check if it's been added/removed.
      if (t == null) {
        // If one file exists and another doesn't, then there's been a change, so return true.
        return (lastLastChange != null);
      }
      else if (lastLastChange == null) {
        // We know t is not null at this stage so if lastLastChange is null then one exists and another doesn't,
        // therefore there's definitely been a change.
        return true;
      }
      // both should not be null at that stage.
      else {
        // if t equals lastLastChange, then there's been no change, so return false.
        return !t.equals(lastLastChange);
      }
    }
    
    public FileTime getLastModified(String path) {
      Path file = Paths.get(path);
      
      if (!file.toFile().exists()) {
        return null;
      }
      
      BasicFileAttributes attr;
      try {
        attr = Files.readAttributes(file, BasicFileAttributes.class);
      }
      catch (IOException e) {
        console.warn("Couldn't check if realm files updated: "+e.getMessage());
        return null;
      }
    
      return attr.lastModifiedTime();
    }
    
    // Temporary
    public void endRealm() {
      if (REALM_SEQ_DEFAULT != null) sequencer.stop();
      refreshThread.interrupt();
      saveTurfJson();
    }
    
    boolean loadedMusic = false;
    
    public void refreshRealm() {
      img_grass = (PImage)getRealmFile(REALM_GRASS, REALM_GRASS_DEFAULT);
      img_tree = (PImage)getRealmFile(REALM_TREE, REALM_TREE_DEFAULT);
      img_sky_1 = (PImage)getRealmFile(REALM_SKY, REALM_SKY_DEFAULT);
      //img_sky_1.resize(scene.width, scene.height);
      
        // Starts playback of the MIDI data in the currently loaded sequence.
        //sequencer.start();
      
      // For now just load music only once lmao
      
      if (!loadedMusic) {
        File f = new File(engine.currentDir+REALM_BGM);
        if (f.exists())
          engine.streamMusicWithFade(engine.currentDir+REALM_BGM);
        else
          engine.streamMusicWithFade(engine.APPPATH+REALM_BGM_DEFAULT);
        loadedMusic = true;
      }
      
      //if (!loadedMusic) {
      //  Thread t1 = new Thread(new Runnable() {
      //      public void run() {
      //        snd_bgm = (SoundFile)getRealmFile(REALM_BGM, REALM_BGM_DEFAULT);
      //        if (snd_bgm == REALM_BGM_DEFAULT) {
      //          sequencer = (Sequencer)getRealmFile(REALM_BGM, REALM_SEQ_DEFAULT);
      //          if (sequencer == REALM_SEQ_DEFAULT) if (snd_bgm != null) snd_bgm.loop();
      //        }
      //        else if (snd_bgm != null) snd_bgm.loop();
      //      }
      //  });
      //  loadedMusic = true;
      //  t1.start();
      //}
    }
    
    public Object getRealmFile(String filename, Object defaultFile) {
      File f = new File(engine.currentDir+filename);
      if (f.exists()) {
        if (engine.getExt(filename).equals("png"))
          return loadImage(engine.currentDir+filename);
        else if (engine.getExt(filename).equals("wav"))
          return new SoundFile(engine.app, engine.currentDir+filename);
        else if (engine.getExt(filename).equals("mid"))
          return loadMidiFile(engine.currentDir+filename);
        else
          return defaultFile;
      }
      else {
        return defaultFile;
      }
    }
    
    public int getHash(String path) {
      // For now, just hash the dir string to get a value from 0 to 255.
      int hash = 0;
        
      for (int i = 0; i < path.length(); i++) {
          hash += path.charAt(i)*i;
      }
      
      return hash;
    }
    
    public void renderPortal() {
      portal.beginDraw();
      //portal.clear();
      portal.background(color(0,0,255), 0);
      portal.blendMode(ADD);
      
      float w = 48, h = 48;
      
      // Because framerates, we need to speed up portal animations if the framerate is slow.
      int n = 1;
      switch (engine.powerMode) {
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
      
      for (int j = 0; j < n; j++) {
        if (int(random(0, 2)) == 0) {
          int i = 0;
          boolean finding = true;
          while (finding) {
            if (int(portPartX[i]) == -999) {
              finding = false;
              portPartVX[i] = random(-0.5, 0.5);
              portPartVY[i] = random(-0.2, 0.2);
            
              portPartX[i] = portal.width/2;
              portPartY[i] = random(h, portal.height-60);
              
              portPartTick[i] = 255;
            }
            
            i++;
            if (i >= portPartNum) {
              finding = false;
            }
          }
        }
        
        int particles = 0;
        
        for (int i = 0; i < portPartNum; i++) {
          if (int(portPartX[i]) != -999) {
            portPartVX[i] *= 0.99;
            portPartVY[i] *= 0.99;
            
            portPartX[i] += portPartVX[i];
            portPartY[i] += portPartVY[i];
            
            
            
            //portal.fill(255);
            //portal.rect(portPartX[i]-(w/2), portPartY[i]+(h/2), w, h);
            
            portPartTick[i] -= 2;
          
            if (portPartTick[i] <= 0) {
              portPartX[i] = -999;
            }
            
            particles++;
          }
        }
      }
      
      for (int i = 0; i < portPartNum; i++) {
        if (int(portPartX[i]) != -999) {
          portal.tint(color(128,128,255), portPartTick[i]);
          //portal.tint(255, portPartTick[i]);
          portal.image(img_glow, portPartX[i]-(w/2), portPartY[i]+(h/2), w, h);
        }
       
      }
      
      //println(particles);
      
      portal.blendMode(NORMAL);
      portal.endDraw();
    }
    
    boolean onGround() {
      return (ypos >= onQuadY-1.) && onGround;
    }
    
    // NOTE: dist must be pythagoras WITHOUT sqrt! We don't use sqrt because performance!!
    private float calculateFade(float dist, float fadeDist) {
      // Calculate the fade distance using the predefined fade distance setting.
      float d = (dist-fadeDist);
      // Calculate the how much we scale the fade so that it doesn't fade so fast that it looks like it
      // pops/disappears into distance. We use this funky pow statement since we're dealing with un-square-rooted
      // distances. I do it in the name of refusing to use sqrt!!
      float scale = (5./pow(GROUND_SIZE, 1.8));
      // Finally, apply the scale to the fade distance and do an "inverse" (e.g. 220 out of 255 -> 35 out of 255) so
      // that we're fading away tiles furthest from us, not closest to us.
      return 255-(d*scale);
    }
    
    private PVector calcTile(float x, float z) {
        float hilly = 100;
        float y = sin((x)*0.5)*hilly+sin((z)*0.5)*hilly;
        return new PVector(GROUND_SIZE*(x), y, GROUND_SIZE*(z));
    }
    
    private float onSurface(float x, float z) {
      float chunkx = floor(x/float(GROUND_SIZE))+1.;
      float chunkz = floor(z/float(GROUND_SIZE))+1.;  
      
      PVector pv1 = calcTile(chunkx-1., chunkz-1.);          // Left, top
      PVector pv2 = calcTile(chunkx, chunkz-1.);          // Right, top
      PVector pv3 = calcTile(chunkx, chunkz);          // Right, bottom
      PVector pv4 = calcTile(chunkx-1., chunkz);          // Left, bottom
      return getYposOnQuad(pv1, pv2, pv3, pv4, x, z); 
    }
    
    private float getYposOnQuad(PVector v1, PVector v2, PVector v3, PVector v4, float xpos, float zpos) {
      // Part 1
      float v3tov4 = v3.x-v4.x;
      float v2tov3 = v3.z-v2.z;
      float m1 = (xpos-v1.x)/(zpos-v1.z);
      PVector point1;
      boolean otherEdge = false;
      if (m1 > 1) {
        // Swappsies and inversies
        m1 = ((zpos-v1.z)/(xpos-v1.x));
        point1 = new PVector(v3.x, v1.y, v2.z+(v2tov3)*m1);
        otherEdge = true;
      }
      else {
        point1 = new PVector(v4.x+(v3tov4)*m1, v1.y, v3.z);
      }
      
      // stroke(0);
      // line(v1.x, 40, v1.z, point1.x, 40, point1.z);
      
      // Part 2
      // NOTE: we can actually skip that.
      // percentLine == m1 always.
      
      // Calculate the y height on the line
      // by using the point as a "percentage"
      // const percentLine = (point1.x-v4.x)/v3v4dist;
      // print(m1);
      
      // We still need to cal y value tho
      float point1Height = otherEdge ? lerp(v2.y, v3.y, m1) : lerp(v4.y, v3.y, m1);
      
      // Part 3
      // Pythagoras
      float len;
      if (otherEdge) {
        float v1tov2 = v2.x-v1.x;
        float v2toPoint1 = point1.z-v2.z;
        len = sqrt(v1tov2*v1tov2 + v2toPoint1*v2toPoint1);
      }
      else {
        float v1tov4 = v4.z-v1.z;
        float v4toPoint1 = point1.x-v4.x;
        len = sqrt(v1tov4*v1tov4 + v4toPoint1*v4toPoint1);
      }
      
      // Part 4
      // Yay
      // Pythagoras again
      float playerLen;
      if (otherEdge) {
        float v1toPlayer = xpos-v1.x;
        float v2toPlayer = zpos-v2.z;
        playerLen = sqrt(v1toPlayer*v1toPlayer + v2toPlayer*v2toPlayer);
      }
      else {
        float v1toPlayer = zpos-v1.z;
        float v4toPlayer = xpos-v4.x;
        playerLen = sqrt(v1toPlayer*v1toPlayer + v4toPlayer*v4toPlayer);
        
      }
      float percent = playerLen/len;
      float calculatedY = lerp(v1.y, point1Height, percent);
      
      return calculatedY;
    }
    
    boolean onGround = false;
    private void Plain3D() {
      
      // This time code here is unused. It was meant to colour the sky based on the
      // time of day. Maybe one day it will be re-used.
        int hr = 21;//hour();
        int mi = 00;//minute();
        float timeRef = (hr*60)+mi;
        
        //timeRef = time;
        //time += 5;
        //if (time > 1440) {
        //  time = 0;
        //}
        float timeWave = (-cos(radians((timeRef*0.25)+0))+1)/2;
        
        float sunset = 0;
        
        if ((timeRef > 1080) && (timeRef < 1380)) {
          sunset = (1-cos(radians((timeRef-1080)*1.2)))*70;
        }
        
        
        // TODO: Reenable night sky stars.

        //drawNightSkyStars();
        
        //if ((timeRef > 1140) || (timeRef < 300)) {
        //  starsInTheSky();
        //}
        
        //This function assumes you have not called portal.beginDraw().
        renderPortal();
        
        
        // If the file check thread has noticed a change, use the main thread to reload the files.
        // We use the main thread and not the refreshThread because we don't want to load assets
        // mid-way through rendering. That would be a disaster.
        if (refreshRealm.get() == true) {
          refreshRealm.set(false);
          // We may expect a delay, so put the fps tracking system into grace mode so that
          // it doesn't butcher the framerate just because of a drop.
          engine.putFPSSystemIntoGraceMode();
          refreshRealm();
        }
        
        
        int n = 1;
        switch (engine.powerMode) {
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
        
        if (n > 0) 
          portalCoolDown -= n;
        
        //println(scene, GUI, back);
        scene.beginDraw();
        
        scene.perspective(PI/3.0,(float)scene.width/scene.height,1,10000);
        //scene.clear();      // Might need to reenable to clear z-buffer.
        //scene.colorMode(HSB, 255);
        //scene.tint(worldThemeSky,255,255);
        //scene.clear();
        
        // Yes yes I know. Background makes everything faster and I plan to later have a bigger image
        // in the background which rotates as you look around.
        scene.background(0);
        
        scene.noTint();
        scene.noStroke();
        
        
        isWalking = false;
        float speed = WALK_SPEED;
        
          if (engine.keyAction("dash")) speed = RUN_SPEED;
          if (engine.shiftKeyPressed) speed = SNEAK_SPEED;
          
          // :3
          if (engine.keyAction("jump") && onGround()) speed *= 3;
          
          float sin_d = sin(direction);
          float cos_d = cos(direction);
          
          //if (repositionMode) {
          //  if (clipboard != null) {
          //    if (clipboard instanceof ImageFileObject) {
          //      ImageFileObject fileobject = (ImageFileObject)clipboard;
          //    }
          //  }
          //}
          
          // BIG TODO: Make it so that you can't walk through trees and other obstacles.
          // Toggle between item reposition mode and free move mode
          
        // Tab pressed.
        if (engine.keybindPressed("menu")) {
          if (!inventory.isEmpty()) repositionMode = !repositionMode;
          else { 
            menuShown = !menuShown;
            if (menuShown) tempMenuAppear.play();
          }
        }
          
        if (!menuShown) {
          for (int i = 0; i < n; i++) {
            float movex = 0.;
            float movez = 0.;
            float rot = 0.;
            if (engine.keyAction("moveForewards")) {
              movex += sin_d*speed;
              movez += cos_d*speed;
              
              isWalking = true;
            }
            if (engine.keyAction("moveLeft")) {
              movex += cos_d*speed;
              movez += -sin_d*speed;
              
              isWalking = true;
            }
            if (engine.keyAction("moveBackwards")) {
              movex += -sin_d*speed;
              movez += -cos_d*speed;
              
              isWalking = true;
            }
            if (engine.keyAction("moveRight")) {
              movex += -cos_d*speed;
              movez += sin_d*speed;
              isWalking = true;
            }
            
            
            if (engine.shiftKeyPressed) {
              if (engine.keyAction("lookRight")) rot = -SLOW_TURN_SPEED;
              if (engine.keyAction("lookLeft")) rot =  SLOW_TURN_SPEED;
            }
            else {
              if (engine.keyAction("lookRight")) rot = -TURN_SPEED;
              if (engine.keyAction("lookLeft")) rot =  TURN_SPEED;
            }
            
            
            if (repositionMode) {
              if (!inventory.isEmpty()) {
                if (inventory.top() instanceof ImageFileObject) {
                  ImageFileObject fileobject = (ImageFileObject)inventory.top();
                  fileobject.rot += rot;
                }
                inventory.top().x += movex;
                inventory.top().z += movez;
              }
            }
            else {
              direction += rot;
              xpos += movex;
              zpos += movez;
              if (isWalking)
                bob += bob_Speed;
            }
            
            // TODO: god this is messy.
            int chunkx = floor(xpos/float(GROUND_SIZE))+1;
            int chunkz = floor(zpos/float(GROUND_SIZE))+1;        
            
            flatSinDirection = sin(direction-PI+HALF_PI);
            flatCosDirection = cos(direction-PI+HALF_PI);
            
            if (engine.keyAction("jump") && onGround() && jumpTimeout < 1) {
              yvel = JUMP_STRENGTH;
              ypos -= 10;
              tempJumpSound.play();
              jumpTimeout = 10;
            }
            
            if (jumpTimeout > 0) jumpTimeout--;
            
            
            float cchunkx = float(chunkx);
            float cchunkz = float(chunkz);
            PVector pv1 = calcTile(cchunkx-1., cchunkz-1.);          // Left, top
            PVector pv2 = calcTile(cchunkx, cchunkz-1.);          // Right, top
            PVector pv3 = calcTile(cchunkx, cchunkz);          // Right, bottom
            PVector pv4 = calcTile(cchunkx-1., cchunkz);          // Left, bottom
            onQuadY = getYposOnQuad(pv1, pv2, pv3, pv4, xpos, zpos); 
            
            ypos -= yvel;
            
            if (!onGround()) {
              if (yvel < TERMINAL_VEL) yvel -= GRAVITY;
            }
            else {
              yvel = 0.;
              ypos = onQuadY;
            }
            
            if (ypos > 2000.) {
              xpos = 1000.;
              ypos = 0.;
              zpos = 1000.;
              yvel = 0.;
            }
            onGround = true;
          }
        
        
          if (engine.keyDown(BACKSPACE)) {
            endRealm();
            engine.fadeAndStopMusic();
            requestScreen(new Explorer(engine, engine.currentDir));
          }
        }
            
        int chunkx = floor(xpos/float(GROUND_SIZE))+1;
        int chunkz = floor(zpos/float(GROUND_SIZE))+1;  
        
        obstructionFront = false;
        
        
        // Render the sky.
        float skyDelta = -(direction/TWO_PI);
        float skyViewportLeft = skyDelta;
        float skyViewportRight = skyDelta+0.25;
        
        
        scene.beginShape();
        scene.texture(img_sky_1);
        scene.textureMode(NORMAL);
        scene.textureWrap(REPEAT);
        scene.texture(img_sky_1);
        scene.vertex(0, 0,                          skyViewportLeft,  0.);
        scene.vertex(scene.width,     0,            skyViewportRight, 0.);
        scene.vertex(scene.width,     scene.height, skyViewportRight, 1.);
        scene.vertex(0,               scene.height, skyViewportLeft,  1.);
        scene.endShape();
        
        //scene.image(img_sky_1,0,0,scene.width,scene.height);
        
        // Push the camera positioning.
        scene.pushMatrix();
        
        //scene.translate(-xpos+(scene.width / 2), ypos+(sin(bob)*3)+(scene.height / 2)+80, -zpos+(scene.width / 2));
        {
        float x = xpos;
        float y = ypos+(sin(bob)*3)-PLAYER_HEIGHT;
        float z = zpos;
        float LOOK_DIST = 200.;
        scene.camera(x, y, z, 
                     x+sin(direction)*LOOK_DIST, y, z+cos(direction)*LOOK_DIST, 
                     0.,1.,0.);
        }
        if (lights) scene.pointLight(255, 245, 245, xpos, ypos-PLAYER_HEIGHT, zpos);
        
        
        //Coin animation.
        
        int spinSpeed = 4/n;
        int coinFrame = int(coinSpinAnimation/spinSpeed);
        coinSpinAnimation++;
        if (coinSpinAnimation >= spinSpeed*6) {
          coinSpinAnimation = 0;
        }
        
        scene.pushMatrix();

        
        // This only uses a single cycle, dw.
        terrainObjects.empty();
        
        // TODO: fix the bug once and for all!
        scene.hint(ENABLE_DEPTH_TEST);
        
        

        for (int tilez = (chunkz-RENDER_DISTANCE-1); tilez < (chunkz+RENDER_DISTANCE); tilez++) {
          //                                                        random bug fix over here.
          for (int tilex = (chunkx-RENDER_DISTANCE-1); tilex < (chunkx+RENDER_DISTANCE); tilex++) {
            float x = GROUND_SIZE*(tilex-0.5), z = GROUND_SIZE*(tilez-0.5);
            float dist = pow((xpos-x), 2)+pow((zpos-z), 2);
            
            boolean dontRender = false;
            if (dist > FADE_DIST_GROUND) {
              float fade = calculateFade(dist, FADE_DIST_GROUND);
              if (fade > 1) scene.tint(255, fade);
              else dontRender = true;
            }
            else scene.noTint();
            
            if (!dontRender) {
              float noisePosition = noise(tilex, tilez);
            
              scene.beginShape();
              scene.textureMode(NORMAL);
              scene.textureWrap(REPEAT);
              scene.texture(img_grass);
              
              //scene.vertex(groundSize*(i-1), noise(i-1, j-1)*craziness, groundSize*(j-1), 0, 0);
              //scene.vertex(groundSize*i,     noise(i, j-1)*craziness, groundSize*(j-1), groundRepeat, 0);
              //scene.vertex(groundSize*i,     noise(i, j)*craziness, groundSize*j, groundRepeat, groundRepeat);
              //scene.vertex(groundSize*(i-1), noise(i-1, j)*craziness, groundSize*j, 0, groundRepeat);
              
              // Default flat plane
              //float y = 0;
              
              
              
              if (tilex == chunkx && tilez == chunkz) {
                //scene.tint(color(255, 127, 127));
                //console.log(str(chunkx)+" "+str(chunkz));
              }
              //if (noisePosition > 0.6 || chunkx == 0) y = 0;
              //else {
              //  //y = -10000;
              //}
              
              PVector v1 = calcTile(tilex-1., tilez-1.);          // Left, top
              PVector v2 = calcTile(tilex, tilez-1.);          // Right, top
              PVector v3 = calcTile(tilex, tilez);          // Right, bottom
              PVector v4 = calcTile(tilex-1., tilez);          // Left, bottom
              
              
              scene.vertex(v1.x, v1.y, v1.z, 0, 0);                                    
              scene.vertex(v2.x, v2.y, v2.z, GROUND_REPEAT, 0);  
              scene.vertex(v3.x, v3.y, v3.z, GROUND_REPEAT, GROUND_REPEAT);  
              scene.vertex(v4.x, v4.y, v4.z, 0, GROUND_REPEAT);       
                
              
              scene.endShape();
              scene.noTint();
              
              final float treeLikelyhood = 0.6;
              final float randomOffset = 70;
              
              if (noisePosition > treeLikelyhood) {
                float pureStaticNoise = (noisePosition-treeLikelyhood);
                float offset = -randomOffset+(pureStaticNoise*randomOffset*2);
                
                // Only create a new tree object if there isn't already one in this
                // position.
                
                String id = str(tilex)+","+str(tilez);
                if (!autogenStuff.contains(id)) {
                  float terrainX = (GROUND_SIZE*(tilex-1))+offset;
                  float terrainZ = (GROUND_SIZE*(tilez-1))+offset;
                  float terrainY = getYposOnQuad(v1,v2,v3,v4,terrainX,terrainZ)+10;
                  TerrainObject3D tree = new TerrainObject3D(
                  terrainX,
                  terrainY,
                  terrainZ,
                  3+(30*pureStaticNoise), 
                  id
                  );
                  terrainObjects.push(tree);
                }
              }
            }
          }
        }
        scene.noTint();
        scene.colorMode(RGB, 255);
        
        scene.popMatrix();
        
        objectsInteractions();
        
        render3DObjects(); //<>// //<>//
        scene.hint(DISABLE_DEPTH_TEST);
        
        
        // Pop the camera positioning.
        scene.popMatrix();
        
        scene.blendMode(ADD);
        scene.fill(portalLight);
        tempPortalSound.amp(max(portalLight/255.,0.));
        scene.noStroke();
        scene.rect(0,0,scene.width,scene.height);
        scene.blendMode(NORMAL);
        
        
        // Fade out the portal light
        float fade = 0.9;
        // Of course, it's an animation so we need to perform it n times
        switch (engine.powerMode) {
          case HIGH:
          portalLight *= fade;
          break;
          case NORMAL:
          portalLight *= fade*fade;
          break;
          case SLEEPY:
          portalLight *= fade*fade*fade*fade;
          break;
          case MINIMAL:
          portalLight *= fade;
          break;
        }
        
        scene.endDraw();
        
        
        
        image(scene, 0, myUpperBarWeight, engine.WIDTH, this.height);
        
        fill(255);
        textSize(30);
        textAlign(LEFT, TOP);
        text((str(frameRate) + "\nX:" + str(xpos) + " Y:" + str(ypos) + " Z:" + str(zpos)), 50, myUpperBarWeight+35);
        
        // We need to run the gui here otherwise it's going to look   t e r r i b l e   in the scene.
        runGUI();
        
        //image(portal,0,0, 128, 256);
    }

    public void scatterNightskyStars() {
        int selectedNum = int(app.random(MAX_NIGHT_SKY_STARS/2, MAX_NIGHT_SKY_STARS));
        nightskyStars = new NightSkyStar[selectedNum];
        
        for (int i = 0; i < selectedNum; i++) {
            nightskyStars[i] = new NightSkyStar();
            int x = int(app.random(-16, engine.WIDTH));
            int y = int(app.random(-16, this.height));
            
            int j = 0;
            boolean colliding = false;
            final int spacing = 4;
            
            while (colliding) {
              colliding = false;
              
              while ((j < i) && !colliding) {
                  if (((x+spacing+16) > (nightskyStars[j].x-spacing)) && ((x-spacing) < (nightskyStars[j].x+spacing+16)) && ((y+spacing+16) > (nightskyStars[j].y-spacing)) && ((y-spacing) < (nightskyStars[j].y+spacing+16))) {
                      colliding = true;
                  }
                  j++;
              }
            }
            
            nightskyStars[i].x = x;
            nightskyStars[i].y = y;
            nightskyStars[i].image = int(app.random(0, 5));
            nightskyStars[i].config = int(app.random(0, 4));
            nightskyStars[i].active = true;
        }
    }
    
    float closestDist = 0;
    private void render3DObjects() {
      // Update the distances from the player for all nodes
      Object3D currNode = headNode; //<>// //<>//
      while (currNode != null) {
        currNode.calculateVal();
        currNode = currNode.next;
      }
      
      
      // sort thru from furthest to shortest distances.
      operationCount = 0;
      insertionSort();
      //headNode = mergeSort(headNode);
      //console.log("Number operations: "+str(operationCount+1)+", Number objects: "+str(numObjects));
        
      // Iterate thru the list and
      // render each object.
      currNode = headNode;
      while (currNode != null) {
        currNode.display();
        currNode = currNode.next;
      }
    }


    private void drawNightSkyStars() {
        for (NightSkyStar star : nightskyStars) {
            if (star.active) {
                
                // Render the star
                engine.img("nightsky"+str(star.image), star.x, star.y, 16, 16);

                // Move the star
                star.x -= moveStarX;
                
                // If the star is off the screen, deactivate it
                if (star.x < -16 || star.x > engine.WIDTH) {
                    star.active = false;
                }
            }
            else {
                // Random chance for the star to be reborn on the right of the screen
                // Also only if it's moved
                if (int(app.random(0, 20)) == 1 && moveStarX != 0.0) {
                    star.x = engine.WIDTH;
                    star.y = int(app.random(-16, this.height));
                    star.image = int(app.random(0, 5));
                    star.config = int(app.random(0, 4));
                    star.active = true;
                }
            }
        }
    }

    

    public void content() {
      engine.setAwake();
      Plain3D(); //<>// //<>//
    }
    
    public void init3DObjects() {
    }
    
   
  
  
    // LINE/LINE
    boolean lineLine(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    
      // calculate the direction of the lines
      float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
      float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
    
      // if uA and uB are between 0-1, lines are colliding
      return (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1);
    }
    
    public void runGUI() {
      if (menuShown) {
        float wi = 800;
        float hi = 500;
        
        app.fill(0, 127);
        app.noStroke();
        app.rect(engine.WIDTH/2-wi/2, engine.HEIGHT/2-hi/2, wi, hi);
        
        if (!engine.textPromptShown) {
          engine.useSpriteSystem(guiMainToolbar);
          guiMainToolbar.interactable = false;
        
          if (engine.button("newentry", "new_entry_128", "New entry")) {
            // TODO: placeholder
            String newName = engine.currentDir+"new entry please change name"+"."+engine.ENTRY_EXTENSION;
            
            // TODO: more elegant solution required
            
            // Go to the journal
            requestScreen(new Editor(engine, newName, true));
            // "Refresh" the folder
            endRealm();
            engine.prevScreen = new PixelRealm(engine, engine.currentDir);
            endRealm();
            menuShown = false;
            tempMenuSelect.play();
            
          }
          
          if (engine.button("newfolder", "new_folder_128", "New folder")) {
            tempMenuSelect.play();
            
            Runnable r = new Runnable() {
              public void run() {
                if (engine.keyboardMessage.length() <= 1) {
                  console.log("Please enter a valid folder name!");
                  return;
                }
                String foldername = engine.currentDir+engine.keyboardMessage.substring(0, engine.keyboardMessage.length()-1);
                println(foldername);
                new File(foldername).mkdirs();
                
                // TODO: have more of an elegant solution.
                endRealm();
                engine.currScreen = new PixelRealm(engine, engine.currentDir);
                menuShown = false;
                tempMenuSelect.play();
              }
            };
        
            engine.beginTextPrompt("Folder name:", r);
          }
          
          if (engine.button("find", "find_128", "Finder")) {
            finderEnabled = !finderEnabled;
            menuShown = false;
            tempMenuSelect.play();
          }
          
          guiMainToolbar.updateSpriteSystem();
        }
        else {
          engine.displayTextPrompt();
        }
      }
    }
    
    public void objectsInteractions() {
        // Cool coin thing!
        // This is very very temp code.
        int n = 1;
        switch (engine.powerMode) {
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
        
        if (!inventory.isEmpty()) {
          // OPTIMISATION REQUIRED
          float SELECT_FAR = 300.;
          
          // Stick to in front of the player.
          if (!repositionMode) {
            float x = xpos+sin(direction)*SELECT_FAR;
            float z = zpos+cos(direction)*SELECT_FAR;
            inventory.top().x = x;
            inventory.top().z = z;
            inventory.top().y = onSurface(x,z);
            inventory.top().visible = true;
            // TODO: We don't need this...?
            if (!inventory.isEmpty()) {
              if (inventory.top() instanceof ImageFileObject) {
                ImageFileObject imgobject = (ImageFileObject)inventory.top();
                imgobject.rot = direction+HALF_PI;
              }
            }
          }
        }
        
        int l = img_coin.length;
        for (int i = 0; i < 100; i++) {
          if (coins[i] != null) {
            coins[i].img = img_coin[((int(frameCount*n)/4))%l];
            if (coins[i].touchingPlayer()) {
              tempCoinSound.play();
              coins[i].destroy();
              coins[i] = null;
              console.log("Coins: "+str(++collectedCoins));
              if (collectedCoins == 100) temp1upSound.play();
            }
          }
        }
        
        closestVal = Float.MAX_VALUE;
        closestObject = null;
        
        final float FLOAT_AMOUNT = 10.;
        boolean cancelOut = true;
        // Files.
        l = files.length;
        for (int i = 0; i < l; i++) {
          FileObject f = files[i];
          if (f != null) {
            
            // Quick inventory check; if it's empty, we don't want it to act.
            boolean holding = false;
            if (!inventory.isEmpty())
              holding = (f == inventory.top());
            
            if (!holding) {
            f.checkHovering();
              if (f instanceof DirectoryPortal) {
                // Take the player to a new directory in the world if we enter the portal.
                if (f.touchingPlayer()) {
                  if (portalCoolDown <= 0) {
                    // For now just create an entirely new screen object lmao.
                    endRealm();
                    tempShiftSound.play();
                    engine.currScreen = new PixelRealm(engine, f.dir, engine.getFilename(engine.currentDir));
                  }
                  else if (cancelOut) {
                    // Pause the portalcooldown by essentially cancelling out the values.
                    portalCoolDown += n;
                    cancelOut = true;
                  }
                }
              }
            }
            
          }
        }
        
        // Pick up the object.
        if (closestObject != null) {
          FileObject p = (FileObject)closestObject;
          
          // When clicked pick up the object.
          // Obviously don't do that if the menu is shown,
          // mouse clicks might just be clicking on the menu.
          if (p.selectedLeft() && !menuShown) {
            if (!inventory.isEmpty()) {
              //inventory.top().visible = false;
              inventory.top().y = -99999;
            } 
            inventory.push(p);
            // Cheap bug fix.
            engine.leftClick = false;
            tempPickupSound.play();
          }
          
          if (p.selectedRight()) {
            engine.open(p.dir);
          }
        }
          
        // Plonk the object down.
        // We also do not want clicks from clicking the menu to unintendedly plonk down objects.
        if (!inventory.isEmpty() && !menuShown) {
          if (engine.leftClick) {
            inventory.pop();
            if (!inventory.isEmpty()) 
              inventory.top().visible = true;
            repositionMode = false;
          }
        }
        
        for (Object3D t : terrainObjects) {
          if (t != null) {
            if (t.touchingPlayer()) {
              obstructionFront = true;
            }
          }
        }
    }
}