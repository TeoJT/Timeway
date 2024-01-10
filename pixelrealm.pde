import java.util.concurrent.atomic.AtomicBoolean;
import javax.sound.midi.*;
import java.io.BufferedInputStream;
import processing.sound.*;
import java.nio.file.attribute.*;
import java.nio.file.*;
import java.util.ListIterator;
import java.util.Iterator;

// Optimisations to be made:
// - PRObject value is technically calculated twice, once for rendering (for dist) and other for sorting (calculateVal)
// - Hovering and rendering flat 3d objects done twice; have temporary values that are calculated ONCE in the object3D
//   class rather than re-calculating everything for each Object3D.



// ---- The Pixel Realm screen -----
// Your folders are realms, your hard drive is a universe.
//
// There are two parts to it:
// - The screen which contains things like the canvas, default textures, constants, and basically
//   anything that doesn't rely on a single state.
// - The specific state of the realm e.g. the files in the realm, the sky/terrain/grass textures,
//   the player's positions. You know. All of the important stuff.
public class PixelRealm extends Screen {
  // Constants and stuff
  final static String COMPATIBILITY_VERSION = "2.0";
  final static String SHORTCUT_COMPATIBILITY_VERSION = "1.0";
  final static String QUICK_WARP_DATASET = "quick_warp_dataset";  // The name of this really doesn't matter as long as it's consistant when quick warping
  final static String QUICK_WARP_ID = "quick_warp_id";  // Name doesn't matter as long as it doesnt change.
  final static float  PSHAPE_SIZE_FACTOR = 100.;
  final static int    MAX_CACHE_SIZE = 512;
  final static float  BACKWARD_COMPAT_SCALE = 256./(float)MAX_CACHE_SIZE;
  final static int    MAX_MEM_USAGE = 1024*1024*1024;   // 1GB
  final static int    DISPLAY_SCALE = 4;
  
  // Movement/player constants.
  final static float BOB_SPEED = 0.4;
  final static float WALK_ACCELERATION = 5.;
  final static float RUN_SPEED = 10.0;
  final static float RUN_ACCELERATION = 0.1;
  final static float MAX_SPEED = 30.;
  final static float SNEAK_SPEED = 1.5;
  final static float TURN_SPEED = 0.05;
  final static float SLOW_TURN_SPEED = 0.01;
  final static float TERMINAL_VEL = 100.;
  final static float GRAVITY = 0.4;
  final static float JUMP_STRENGTH = 8.;
  final static float PLAYER_HEIGHT = 80;
  final static float PLAYER_WIDTH  = 20;
  final static float MIN_PORTAL_LIGHT_THRESHOLD = 19600.;   // 140 ^ 2
  
  // Tool constants
  protected final static int TOOL_NORMAL = 1;
  protected final static int TOOL_GRABBER = 2;
  protected final static int TOOL_CUBER = 3;
  protected final static int TOOL_BOMBER = 4;
  protected final static int TOOL_CREATOR = 5;
  
  // File names without an extension accept various file types (png, jpeg, gif)
  public final static String REALM_GRASS = ".pixelrealm-grass";
  public final static String REALM_SKY   = ".pixelrealm-sky";
  public final static String REALM_TREE_LEGACY  = ".pixelrealm-terrain_object";
  public final static String REALM_TREE  = ".pixelrealm-tree";
  public final static String REALM_BGM   = ".pixelrealm-bgm";
  public final static String REALM_TURF  = ".pixelrealm-turf.json";
  public final static String REALM_BGM_DEFAULT = "data/engine/music/pixelrealm_default_bgm.wav";
  
  // Defaults (Loaded on constructor)
  private RealmTexture REALM_GRASS_DEFAULT;
  private RealmTexture REALM_MUSIC_DEFAULT;
  private RealmTexture REALM_SKY_DEFAULT;
  private RealmTexture REALM_TREE_DEFAULT;
  
  // Other assets (might remove later)
  private RealmTexture IMG_COIN;
  
  
  // --- Cache (sort of) ---
  private float cache_flatSinDirection;
  private float cache_flatCosDirection;
  private float cache_playerSinDirection;
  private float cache_playerCosDirection;
  private boolean primaryAction = false;
  private boolean secondaryAction = false;
  
  
  // --- Legacy backward-compatibility stuff & easter eggs ---
  protected float height = HEIGHT-myUpperBarWeight-myLowerBarWeight;
  private PGraphics legacy_portal;
  private boolean legacy_portalEasteregg = false;
  private float coinCounterBounce = 0.;
  
  // --- Global state and working variables (doesn't require per-realm states) ---
  private PGraphics scene;
  private float runAcceleration = 0.;
  private float bob = 0.0;
  private float jumpTimeout = 0;
  private boolean showExperimentalGifs = false;
  private boolean finderEnabled = false;   // Maybe this could be part of Pixel Realm state?
  protected boolean launchWhenPlaced = false; 
  protected int     currentTool = TOOL_NORMAL;
  private boolean isWalking = false;
  private boolean nearObject = false;
  public boolean movementPaused = false;
  private float lastPlacedPosX = 0;
  private float lastPlacedPosZ = 0;
  private AtomicBoolean refreshRealm = new AtomicBoolean(false);
  private float portalLight = 255.;
  private float portalCoolDown = 45;
  private float animationTick = 0.;
  
  // Inventory//pocket
  protected LinkedList<PocketItem> pockets   = new LinkedList<PocketItem>();
  protected LinkedList<PocketItem> hotbar    = new LinkedList<PocketItem>();   // Items in hotbar are also in inventory.
  protected HashSet<String> pocketItemNames  = new HashSet<String>(); 
  protected PocketItem globalHoldingObject = null;
  protected ItemSlot<PocketItem> globalHoldingObjectSlot = null;
  
  // Debug-based variables.
  private int operationCount = 0;
  
  // Memory protection (TODO: Move to engine)
  private AtomicInteger memUsage = new AtomicInteger(0);
  private boolean memExceeded = false;
  private boolean showMemUsage = false;
  private int loading = 0;
  private int MAX_LOADER_THREADS;
  private AtomicInteger loadThreadsUsed = new AtomicInteger(0);
  private ArrayList<AtomicBoolean> loadQueue = new ArrayList<AtomicBoolean>();
  
  
  
  
  
  // --- Pixel realm state ---
  protected PixelRealmState currRealm = null;
  private PixelRealmState[] quickWarpRealms = new PixelRealmState[10];
  private int quickWarpIndex = 1;   // 1 because we start from 1 on our keyboard
  private PixelRealmState prevRealm = null;   // For caching and to use the backspace button
  
  
  
  
  
  // --- Our constructors ---
  // Remember, these are for the screen which does NOT rely on per-realm states.
  // i.e. canvas creation, asset loading etc should only be done ONCE.
  public PixelRealm(Engine engine, String dir) {
    super(engine);
    
    // --- Load default assets ---
    // TODO (eventually): load screen's assets, not everything from the loading screen (even tho that would be a minor optimisation)
    REALM_SKY_DEFAULT = new RealmTexture(REALM_SKY);
    REALM_TREE_DEFAULT = new RealmTexture(REALM_TREE_LEGACY);
    REALM_GRASS_DEFAULT = new RealmTexture(REALM_GRASS);
  
    String[] COINS = { "coin_0", "coin_1", "coin_2", "coin_3", "coin_4", "coin_5"};;
    IMG_COIN = new RealmTexture(COINS);
    
    // --- Sounds and music ---
    sound.loopSound("portal");
    


    // TODO: Make canvas width 640 pixels ALWAYS with backwards compat for 1500x221 skies.
    
    // --- Create graphics canvas ---
    // Disable texture filtering
    scene = createGraphics((int(WIDTH/DISPLAY_SCALE)), int(this.height/DISPLAY_SCALE), P3D);
    ((PGraphicsOpenGL)scene).textureSampling(2);        
    scene.hint(DISABLE_OPENGL_ERRORS);
    
    // Only set up legacy portal when we go into the easter egg.
    //setupLegacyPortal();
    
    // TODO: I'd love to do a performance benchmark based on the number of cores we're using.
    int numCores = Runtime.getRuntime().availableProcessors();
    // We want to reserve at least one core to run the main thread otherwise it's gonna be REALLY laggy as the
    // OS scheduler dedicates all of its processing resources to loading images.
    MAX_LOADER_THREADS = (numCores/2)-1;
    console.info("# cores reserved for loading: "+MAX_LOADER_THREADS);
    
    
    // Because our stack holds the generated terrain objects which is generated by the floor tiles,
    // this means that there could theoretically be at most renderDistance in the x axis times
    // renderDistance in the z axis. Hope that makes sense.
    
    currRealm = new PixelRealmState(dir, file.directorify(file.getPrevDir(dir)));
    sound.streamMusicWithFade(currRealm.musicPath);
  }
  
  public PixelRealm(Engine engine) {
    this(engine, engine.DEFAULT_DIR);
  }
  
  
  // --- R E S E T ---
  public void reset() {
    runAcceleration = 0.;
    bob = 0.0;
    jumpTimeout = 0;
    showExperimentalGifs = false;
    currentTool = TOOL_NORMAL;
    finderEnabled = false;   // Maybe this could be part of Pixel Realm state?
    launchWhenPlaced = false; 
    //legacy_portalEasteregg = false;
  }
  
  
  
  
  // Classes we need
  class RealmTexture {
    private PImage singleImg = null;
    private PImage[] aniImg = null;
    private final static float ANIMATION_INTERVAL = 10.;
    
    public RealmTexture(PImage img) {
      if (img == null) {
        console.bugWarn("RealmTexture: passing a null image");
        singleImg = display.systemImages.get("white");
        return;
      }
      singleImg = img;
    }
    public RealmTexture(PImage[] imgs) {
      if (imgs.length == 0) {
        console.bugWarn("RealmTexture PImage[]: passing an empty list");
        singleImg = display.systemImages.get("white");
        return;
      }
      singleImg = null;
      aniImg = new PImage[imgs.length];
      int i = 0;
      for (PImage p : imgs) {
        aniImg[i++] = p;
      }
    }
    public RealmTexture(ArrayList<PImage> imgs) {
      if (imgs.size() == 0) {
        console.bugWarn("RealmTexture ArrayList: passing an empty list");
        singleImg = display.systemImages.get("white");
        return;
      }
      singleImg = null;
      aniImg = new PImage[imgs.size()];
      int i = 0;
      for (PImage p : imgs) {
        aniImg[i++] = p;
      }
    }
    public RealmTexture(String[] imgs) {
      if (imgs.length == 0) {
        console.bugWarn("RealmTexture String[]: passing an empty list");
        singleImg = display.systemImages.get("white");
        return;
      }
      singleImg = null;
      aniImg = new PImage[imgs.length];
      int i = 0;
      for (String s : imgs) {
        aniImg[i++] = display.systemImages.get(s);
      }
    }
    public RealmTexture(String imgName) {
      singleImg = display.systemImages.get(imgName);
    }
    
    public PImage get(int index) {
      if (singleImg != null) return singleImg;
      else return aniImg[index%aniImg.length];
    }
    
    public PImage get() {
      return this.get(int(animationTick/ANIMATION_INTERVAL));
    }
    
    public PImage getRandom() {
      return this.get(int(app.random(0., aniImg.length)));
    }
  }
  
  
  

  // We need some linkedlist functionality
  // --- Linked list stuff ---
  class ItemSlot<T> {
      public ItemSlot next = null;
      public ItemSlot prev = null;
      public T carrying = null;
      public float val = 0.;
  
      public ItemSlot(T o) {
        this.carrying = o;
      }
  
      //public void remove() {
      //  if (this == head)
      //    head = this.next;
  
      //  if (this == tail)
      //    tail = this.prev;
  
      //  if (this == inventorySelectedItem) {
      //    inventorySelectedItem = this.prev;
      //    if (inventorySelectedItem == null) 
      //      inventorySelectedItem = this.next;
      //    // Will be null as intended if next is null too.
      //    // i.e., the item just removed happens to be the last item in the inventory.
      //  }
  
      //  if (this.prev != null)
      //    this.prev.next = this.next;
  
      //  if (this.next != null)
      //    this.next.prev = this.prev;
      //}
  
      //public void addAfterMe(ItemSlot newNode) {
  
      //  ItemSlot prev = this;
      //  ItemSlot next = this.next;
  
      //  newNode.next = next;
      //  newNode.prev = prev;
      //  if (next != null) next.prev = newNode;
      //  prev.next = newNode;
  
      //  if (this == tail) {
      //    tail = prev;
      //  }
      //}
  
      //public void addEnd() {
      //  if (head == null) {  
      //    head = this;
      //    tail = this;
      //    head.prev = null;
      //    tail.next = null;
      //    inventorySelectedItem = this;
      //  } else {  
      //    //add newNode to the end of list. tail->next set to newNode  
      //    tail.next = this;  
      //    //newNode->previous set to tail  
      //    this.prev = tail;  
      //    //newNode becomes new tail  
      //    tail = this;  
      //    //tail's next point to null  
      //    tail.next = null;
      //  }
      //  inventorySelectedItem = this;
      //}
    }
  
  class LinkedList<T> implements Iterable<T> {
    public ItemSlot<T> head = null;
    public ItemSlot<T> tail = null;
    public ItemSlot<T> inventorySelectedItem = null;
    
    public Iterator<T> iterator() {
      ArrayList<T> ll = new ArrayList<T>();
      itCurr = head;
      ItemSlot<T> n = head;
      int counter = 0;
      while (n != null) {
        ll.add(n.carrying);
        n = n.next;
        
        // Safety check
        counter++;
        if (counter > 5000000) {
          // Hard to recover from.
          // We don't really have a choice but to crash the program at this point
          throw new RuntimeException("A fatal linkedlist bug occured. Program self-crashed to save your computer from exploding.");
        }
      }
      
      return ll.iterator();
    }
    
    ItemSlot itCurr = null;
    
    //public T next() { 
    //  ItemSlot tmp = itCurr;
    //  itCurr = itCurr.next;
    //  return tmp.carrying;
    //} 
    
    //public boolean hasNext() {
    //  return itCurr != null;
    //}
  
    public ItemSlot add(T o) {
      ItemSlot node = new ItemSlot(o);
      this.add(node);
      return node;
    }
    
    public ItemSlot add(ItemSlot node) {
      if (head == null) {  
        head = tail = node;
        head.prev = null;
        tail.next = null;
      } else {  
        //add newNode to the end of list. tail->next set to newNode  
        tail.next = node;  
        //newNode->previous set to tail  
        node.prev = tail;  
        //newNode becomes new tail  
        tail = node;  
        //tail's next point to null  
        tail.next = null;
      }  
      return node;
    }
  
    public ItemSlot remove(ItemSlot node) {
      if (node == head)
        head = node.next;
  
      if (node == tail)
        tail = node.prev;
  
      if (node.prev != null)
        node.prev.next = node.next;
  
      if (node.next != null)
        node.next.prev = node.prev;
  
      // Object should be dereferenced now.
      return node;
    }
    
    public void insertionSort() {
      operationCount = 0;
      if (head == null || head.next == null) {
        return; // List is empty or has only one element, so it is already sorted
      }
  
      ItemSlot current = head.next; // Node to be inserted into the sorted portion
  
      while (current != null) {
        ItemSlot nextNode = current.next; // Store the next node before modifying current.next
  
        boolean run = true;
        while (current.prev != null && run) {
          operationCount++;
          if (current.prev.val < current.val) {
            // Swap them.
            ItemSlot previous = current.prev;
            ItemSlot next = current.next;
  
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
  
            if (head == previous) {
              head = current;
            }
            if (tail == current) {
              tail = previous;
            }
          } else run = false;
        }
  
        current = nextNode; // Move to the next node
      }
  
      if (head == null) console.bugWarn("Null head!");
      if (tail == null) console.bugWarn("Null tail!");
    }
  }
  
  
  
  
  protected class PocketItem {
    
    public String name = "";
    
    // Abstract objects are PRObjects (most likely fileobjects) that aren't actually files on computers.
    // Non-abstract if it is null
    public PixelRealmState.PRObject item = null;
    
    public boolean abstractObject = false;
    
    // Inventory is stored in folder in files.
    public boolean syncd = false;
    
    public boolean isDuplicate = false;
    
    public PocketItem(String name, PixelRealmState.PRObject item, boolean abstractObject) {
      this.name = name;
      this.abstractObject = abstractObject;
      this.item = item;
      
      // If there's a duplicate, it's ok for the time being, 
      // but if we exit the realm and try to sync the duplicate item,
      // throw a big fat error.
      if (pocketItemNames.contains(name)) {
        isDuplicate = true;
      }
    }
    
    // This method is called when we change realms
    // any item that's in the inventory but not sync'd must be moved to the inventory.
    // Returns true if successful.
    // If unsuccessful, the change realm operation must be terminated if even one item
    // returns false on this method.
    // Any file changes (e.g. mv to inventory) won't affect things.
    // This method handles specific-error cases using the upper pixelrealm_ui class.
    public boolean changeRealm(String fro) {
      fro = file.directorify(fro);
      
      // Can't move abstract objects.
      if (abstractObject) {
        promptMoveAbstractObject(name);
        console.warn("Abstract file");
        return false;
      }
      
      if (!syncd) {
        // Can't move files that have the same filename as another file
        // in the pocket.
        if (isDuplicate) {
          console.warn("is duplicate");
          promptPocketConflict(name);
          return false;
        }
        
        boolean success = file.mv(fro+name, engine.APPPATH+engine.POCKET_PATH+name);
        if (!success) {
          console.warn("failed to move");
          console.warn("to: "+engine.APPPATH+engine.POCKET_PATH+name);
          console.warn("fro: "+fro+name);
          promptFailedToMove(name);
          return false;
        }
        // At this point, the file should be moved therefore it is now sync'd with the memory
        // as we move realms.
        this.syncd = true;
      }
      
      return true;
    }
  }
  
  // Overridden by the upper pixelrealm_ui class.
  @SuppressWarnings("unused")
  protected void promptPocketConflict(String filename) {}
  @SuppressWarnings("unused")
  protected void promptFileConflict(String filename) {}
  @SuppressWarnings("unused")
  protected void promptMoveAbstractObject(String filename) {}
  @SuppressWarnings("unused")
  protected void promptFailedToMove(String filename) {}
    
    
    
    
    
  
  
  
  
  
  
  
  // --- Pixel realm state ---
  public class PixelRealmState {
    
    public String stateDirectory;
    
    // --- Player state --- 
    // (1000, 0, 1000) is our default position (and it's imporant for shortcuts)
    public float playerX = 1000.0, playerY = 0., playerZ = 1000.0;
    public float xvel = 0., yvel = 0., zvel = 0.;
    public float direction = PApplet.PI;
    
    // Whenever we switch realms, we need to make sure this is being updated with the global
    // state!
    public PRObject holdingObject = null;
    
    // --- Realm textures & state ---
    // Initially defaults, gets loaded with realm-specific files (if exists) later.
    public RealmTexture img_grass = REALM_GRASS_DEFAULT;
    public RealmTexture img_tree  = REALM_TREE_DEFAULT;
    public RealmTexture img_sky   = REALM_SKY_DEFAULT;
    private TerrainAttributes terrain;
    private DirectoryPortal exitPortal = null;
    private String musicPath;
    
    // TODO: change to COMPATIBILITY_VERSION
    private String version = "1.0";
    
    // --- Legacy stuff for backward compatibility ---
    private Stack<PixelRealmState.PRObject> legacy_terrainObjects;
    private HashSet<String> legacy_autogenStuff;
    public boolean lights = false;
    public int collectedCoins = 0;
    public boolean coins = false;
    
    // All objects that are visible on the scene, their interactable actions are run.
    private LinkedList<PRObject> ordering = new LinkedList<PRObject>();
    
    // Not necessary lists here, just useful and faster.
    private LinkedList<FileObject> files = new LinkedList<FileObject>();
    
    private LinkedList<PRObject> pocketObjects = new LinkedList<PRObject>();
    
    
    // --- Constructor ---
    public PixelRealmState(String dir, String emergeFrom) {
      this.stateDirectory = file.directorify(dir);
      
      loadRealm();
      emergeFromExitPortal(file.directorify(emergeFrom));
      
      // For testing purposes (just set version = "1.0")
      if (version.equals("1.0")) {
        legacy_terrainObjects = new Stack<PRObject>(int(((terrain.renderDistance+5)*2)*((terrain.renderDistance+5)*2)));
        legacy_autogenStuff = new HashSet<String>();
        app.noiseSeed(getHash(dir));
      }
    }
    
    public PixelRealmState(String dir) {
      this.stateDirectory = file.directorify(dir);
      
      // Load realm emerging from our exit portal.
      loadRealm();
      
      // For testing purposes (just set version = "1.0")
      if (version.equals("1.0")) {
        legacy_terrainObjects = new Stack<PRObject>(int(((terrain.renderDistance+5)*2)*((terrain.renderDistance+5)*2)));
        legacy_autogenStuff = new HashSet<String>();
        app.noiseSeed(getHash(dir));
      }
    }
    
    
    // --- Realm terrain attributes ---
    
    public abstract class TerrainAttributes {
      public float renderDistance = 6.;
      public float groundRepeat = 2.;
      public float groundSize = 400.;
      public float FADE_DIST_OBJECTS = PApplet.pow((renderDistance-4)*groundSize, 2);
      public float FADE_DIST_GROUND = PApplet.pow(PApplet.max(renderDistance-3, 0.)*groundSize, 2);
      public String NAME;
      
      public TerrainAttributes() {
        NAME = "[unknown]";
      }
      
      public void update() {
        FADE_DIST_OBJECTS = PApplet.pow((renderDistance-4)*groundSize, 2);
        FADE_DIST_GROUND = PApplet.pow(max(renderDistance-3, 0)*groundSize, 2);
      }
      
      // Probably not needed but for backward compatibility perposes.
      public void setRenderDistance(int renderDistance) {
        this.renderDistance = renderDistance;
        update();
      }
    
      public void setGroundSize(float groundSize) {
        this.groundSize = groundSize;
        update();
      }
    }
    
    // Classic lazy ass coding terrain.
    public class SinesinesineTerrain extends TerrainAttributes {
      public float hillHeight = 0.;
      public float hillFrequency = 0.5;
      
      public SinesinesineTerrain() {
        NAME = "Sine sine sine";
      }
    }
    
    
    
    
    
    
    
    
    
    
    // --- Define our PR objects. ---
    class TerrainPRObject extends PRObject {
      public TerrainPRObject(float x, float y, float z, float size, String id) {
        super(x, y, z);
        this.img = img_tree.getRandom();
        this.setSize(size);
        legacy_autogenStuff.add(id);
        
        // Small hitbox
        this.hitboxWi = wi*0.25;
      }
    }
  
  
    abstract class FileObject extends PRObject {
      public String dir;
      public String filename;
      
      // Blocks a thread from loading an image until it's next in the queue.
      public AtomicBoolean beginLoadFlag = new AtomicBoolean(false);
      
      public FileObject(float x, float y, float z, String dir) {
        super(x, y, z);
        setFileNameAndIcon(dir);
      }
      
      // Without coords provided, the x,y,z positions will be random
      public FileObject(String dir) {
        super();
        this.x = lastPlacedPosX+random(-500, 500);
        this.z = lastPlacedPosZ+random(-500, 500);
        // Y-value will be automatically adjusted later.
        //this.y = onSurface(this.x, this.z);
        lastPlacedPosX = this.x;
        lastPlacedPosZ = this.z;
        setFileNameAndIcon(dir);
      }
  
      public void setFileNameAndIcon(String dir) {
        dir = dir.replace('\\', '/');
        this.dir = dir;
        this.filename = file.getFilename(dir);
        display.systemImages.get(file.extIcon(this.filename));
      }
  
      public void display() {
        super.display(true);
      }
      
      public void run() {
        // TODO: based on different modes etc.
        if (selectedLeft() && currentTool == TOOL_NORMAL) {
          file.open(dir);
        }
      }
      
      public void load(JSONObject json) {
        // We expect the engine to have already loaded a JSON object.
        // Every 3d object has x y z position.
        this.x = json.getFloat("x", lastPlacedPosX+random(-500, 500));
        this.z = json.getFloat("z", lastPlacedPosX+random(-500, 500));
        this.size = json.getFloat("scale", 1.)*BACKWARD_COMPAT_SCALE;
        lastPlacedPosX = this.x;
        lastPlacedPosZ = this.z;
  
        float yy = onSurface(this.x, this.z);
        this.y = json.getFloat("y", yy);
  
        // If the object is below the ground, reset its position.
        if (y > yy+5.) this.y = yy;
      }
  
      public JSONObject save() {
        JSONObject PRObject = new JSONObject();
        PRObject.setString("filename", this.filename);
        PRObject.setFloat("x", this.x);
        PRObject.setFloat("y", this.y);
        PRObject.setFloat("z", this.z);
        PRObject.setFloat("scale", this.size/BACKWARD_COMPAT_SCALE);
        return PRObject;
      }
      
      public void scaleUp(float amount) {
        // Use a curve to make it scale a little when small and scale a lot when larger
        setSize(size+max((amount*amount), 0.001));
      }
      
      public void scaleDown(float amount) {
        // Use a curve to make it scale a little when small and scale a lot when larger
        setSize(size-max((amount*amount), 0.001));
      }
      
      public void addRequestToQueue(final String path) {
        this.beginLoadFlag.set(false);
        loadQueue.add(this.beginLoadFlag);
        final boolean isImg = this instanceof ImageFileObject;
        final FileObject me = this;
        
        Thread t1 = new Thread(new Runnable() {
          public void run() {
            // Wait until we're allowed our turn.
            while (!beginLoadFlag.get()) {
              try {
                Thread.sleep(10);
              }
              catch (InterruptedException e) {
                // we don't care.
              }
            }
            
            // First, we need to see if we have enough space to store stuff.
            int size = file.getImageUncompressedSize(path);
            //console.info(filename+" size: "+(size/1024)+" kb");
            // Tbh doesn't need to be specifically thread safe, it's all an
            // approximation.
            if (memUsage.get()+size > MAX_MEM_USAGE) {
              if (!memExceeded) console.warn("Maximum allowed memory exceeded, some items/files may be missing from this realm.");
              memExceeded = true;
              //console.info(filename+" exceeds the maximum allowed memory.");
            }
            else {
              incrementMemUsage(size);
              if (file.getExt(path).equals("gif")) {
                Gif newGif = new Gif(app, path);
                newGif.loop();
                img = newGif;
              }
              // TODO: idk error check here
              else {
                // TODO: this is NOT thread-safe here!
                img = engine.tryLoadImageCache(path, new Runnable() {
                  public void run() {
                    if (isImg)
                      ((ImageFileObject)me).cacheFlag = true;
                    engine.setOriginalImage(loadImage(path));
                  }
                }
                );
              }
            }
            
            // Once we're done we need to free our slot so that other threads have a turn to use the core.
            loadThreadsUsed.decrementAndGet();
          }
        }
        );
        t1.start();
      }
    }
    
    class OBJFileObject extends FileObject {
      public PShape model = null;
      
      private float biggestDepthAxis = 0.;
      
      // TODO: scale each axis...?
      public float rotX = 0.;
      public float rotY = 0.;
      public float rotZ = 0.;
      
      
      public OBJFileObject(float x, float y, float z, String dir) {
        super(x, y, z, dir);
        this.wi = 300;
        this.hi = 300;
        this.size = 1.*BACKWARD_COMPAT_SCALE;
      }
  
      public OBJFileObject(String dir) {
        super(dir);
      }
      
      public void load(JSONObject json) {
        super.load(json);
        // TODO: load in seperate thread.
        model = app.loadShape(dir);
        //console.log("vertex count: "+model.getVertexCount());
        //console.log("width: "+model.getWidth());
        //console.log("height: "+model.getHeight());
        //console.log("depth: "+model.getDepth());
        
        // We need axis to display the shape, we don't care about height
        
        biggestDepthAxis = model.getWidth() > model.getDepth() ? model.getWidth() : model.getDepth();
        
        size = 1.;
        
        // Tbh we only really care about the width and depth (I think)
      }
      
      
      public void setSize(float size) {
        this.size = size;
      }
      
      public void display() {
        super.display();
        if (model != null && visible) {
          scene.pushMatrix();
          scene.translate(this.x, this.y, this.z);
          scene.scale(-PSHAPE_SIZE_FACTOR*(1/biggestDepthAxis)*size);
          scene.rotateX(rotX);
          scene.rotateY(rotY);
          scene.rotateZ(rotZ);
          scene.shape(model);
          scene.popMatrix();
        }
      }
      
      public void scaleUp(float amount) {
        setSize(size+amount*BACKWARD_COMPAT_SCALE);
      }
      
      public void scaleDown(float amount) {
        setSize(size-amount*BACKWARD_COMPAT_SCALE);
      }
    }
  
    class UnknownTypeFileObject extends FileObject {
  
      public UnknownTypeFileObject(float x, float y, float z, String dir) {
        super(x, y, z, dir);
      }
  
      public UnknownTypeFileObject(String dir) {
        super(dir);
      }
  
      public void display() {
        // Display the name of the file
        float d = direction-PI;
  
        if (lights) scene.noLights();
        scene.pushMatrix();
        scene.translate(x, y-hi-20, z);
        scene.rotateY(d);
        scene.textFont(engine.DEFAULT_FONT, 16);
        scene.textAlign(CENTER, CENTER);
        scene.fill(255);
        scene.text(filename, 0, 0, 0);
        scene.popMatrix();
        if (lights) scene.lights();
  
        super.display(true);
      }
    }
  
    class ImageFileObject extends FileObject {
      public float rot = 0.;
  
  
      public boolean loadFlag = false;
      public boolean cacheFlag = false;
      
  
  
      public ImageFileObject(float x, float y, float z, String dir) {
        super(x, y, z, dir);
      }
  
      public ImageFileObject(String dir) {
        super(dir);
      }
      
      
      public void calculateVal() {
        
        // TODO: obvious optimisation required!
        // Cache variables from display()!
        float hwi = wi/2;
        float sin_d = cache_flatSinDirection*(hwi);
        float cos_d = cache_flatCosDirection*(hwi);
        float xx1 = x + sin_d;
        float zz1 = z + cos_d;
        float xx2 = x - sin_d;
        float zz2 = z - cos_d;
        
        float x1 = playerX-xx1;
        float y1 = playerY-this.y;
        float z1 = playerZ-zz1;
        
        float x2 = playerX-xx2;
        float y2 = y1;
        float z2 = playerZ-zz2;
        
        // BUG FIX:
        // Calculate the edge with the furthest distance to the player (camera).
        float val1 = x1*x1 + y1*y1 + z1*z1;
        float val2 = x2*x2 + y2*y2 + z2*z2;
        
        this.myOrderingNode.val = val1 > val2 ? val1 : val2;
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
                  engine.setCachingShrink(MAX_CACHE_SIZE, 0);
                  //this.img = engine.experimentalScaleDown(img);
                  engine.saveCacheImage(this.dir, img);
                  cacheFlag = true;
                }
  
                // Set load flag to true
                loadFlag = true;
              }
            }
            if (img.width > 0 && img.height > 0 && loadFlag) {
              //setSize(1.);
              this.wi = img.width*size;
              this.hi = img.height*size;
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
  
              displayQuad(x1, y1, z1, x2, y1+hi, z2, true);
            }
          }
        }
        // Reset tint
        this.tint = color(255);
      }
  
      public void load(JSONObject json) {
        super.load(json);
  
        this.rot = json.getFloat("rot", random(-PI, PI));
        
        
        // Depends on our image format:
        if (file.getExt(this.filename).equals("gif") && showExperimentalGifs) cacheFlag = false;
          
        addRequestToQueue(dir);
      }
  
      public JSONObject save() {
        JSONObject PRObject = super.save();
        PRObject.setFloat("rot", this.rot);
        return PRObject;
      }
    }
    
    public String createShortcut() {
      String dir = stateDirectory;
      // Create a shortcut with a unique name.
      
      // SHORTCUT_EXTENSION[0] is the latest shortcut version.
      String folderName = file.getFilename(dir);
      String shortcutName = folderName+"."+engine.SHORTCUT_EXTENSION[0];
      String shortcutPath = dir+shortcutName;
      shortcutPath.replaceAll("\\\\", "/");
      
      // If it already exists select another name until we find one that hasn't been taken.
      File f = new File(shortcutPath);
      int i = 1;
      while (f.exists()) {
        shortcutName = file.getFilename(dir)+"-"+str(i++)+"."+engine.SHORTCUT_EXTENSION[0];
        shortcutPath = dir+shortcutName;
        f = new File(shortcutPath);
      }
      
      JSONObject sh = new JSONObject();
      sh.setString("compatibilty_version", SHORTCUT_COMPATIBILITY_VERSION);
      sh.setString("shortcut_dir", dir);
      sh.setString("shortcut_name", folderName);  // Remove extension.
      
      try {
        app.saveJSONObject(sh, shortcutPath);
      }
      catch (RuntimeException e) {
        console.warn("A problem occured with creating the shortcut file...");
        console.warn(e.getMessage());
      }
      
      return shortcutPath;
    }
  
    class ShortcutPortal extends DirectoryPortal {
      public String shortcutDir;
      public String shortcutName = null;
      
      public ShortcutPortal(float x, float y, float z, String dir) {
        super(x, y, z, dir);
      }
  
      public ShortcutPortal(String dir) {
        super(dir);
      }
      
      public void load(JSONObject json) {
        super.load(json);
        loadShortcut();
      }
      
      public void loadShortcut() {
        // Open our own file and get the shortcut
        if (file.exists(this.dir)) {
          try {
            JSONObject sh = app.loadJSONObject(this.dir);
            
            String compat_ver = sh.getString("compatibilty_version", "[err]");
            if (!compat_ver.equals(SHORTCUT_COMPATIBILITY_VERSION)) {
              console.warn("Incompatiable shortcut "+file.getFilename(this.filename));
              return;
            }
            
            shortcutDir = sh.getString("shortcut_dir", "[corrupted]");
            if (shortcutDir.equals("[corrupted]")) {
              console.warn("Corrupted shortcut "+file.getFilename(this.filename));
              return;
            }
            // Check shortcut exists.
            if (!file.exists(shortcutDir)) {
              console.warn("Shortcut to "+file.getFilename(this.filename)+" doesn't exist!");
              return;
            }
            // If at this point we should have the shortcut dir.
            requestRealmSky(shortcutDir);
            
            shortcutName = sh.getString("shortcut_name", "[corrupted]");
            
            // Yup, shortcut_name is unnecessary. But hey might as well self-fix if broken.
            if (shortcutName.equals("[corrupted]")) {
              shortcutName = file.getFilename(shortcutDir);
            }
          }
          catch (RuntimeException e) {
            console.warn(file.getFilename(this.filename)+" shortcut json error!");
            this.destroy();
            return;
          }
        }
        else {
          console.bugWarn("setShortcut: shortcut file doesn't exist??");
          return;
        }
      }
      
      public void run() {
        // Screen glow effect.
        // Calculate distance to portal
        float dist = PApplet.pow(x-playerX, 2)+PApplet.pow(z-playerZ, 2);
        if (dist < MIN_PORTAL_LIGHT_THRESHOLD) {
          // If close to the portal, set the portal light to create a portal enter/transistion effect.
          portalLight = max(portalLight, (1.-(dist/MIN_PORTAL_LIGHT_THRESHOLD))*255.);
        }
        
        // Entering the portal.
        if (touchingPlayer() && portalCoolDown < 1.) {
          sound.playSound("shift");
          prevRealm = currRealm;
          gotoRealm(this.shortcutDir);
        }
        
        if (selectedLeft() && currentTool == TOOL_NORMAL) {
          file.open(this.shortcutDir);
        }
      }
  
      public void display() {
        String filenameOriginal = this.filename;
        // Cheap hacky way of getting the shortcutName to display instead of the shortcut's filename :v)
        if (shortcutName != null) this.filename = shortcutName;
        if (visible) {
          this.tint = color(150, 255, 255);
          super.display();
        }
        this.filename = filenameOriginal;
      }
    }
  
    class DirectoryPortal extends FileObject {
  
      public DirectoryPortal(float x, float y, float z, String dir) {
        super(x, y, z, dir);
        this.img = display.systemImages.get("white"); 
        
        requestRealmSky(dir);
        
        this.wi = 128;
        this.hi = 128+96;
        
        // Set hitbox size to small
        this.hitboxWi = wi*0.5;
        if (legacy_portalEasteregg) setSize(0.8);
      }
  
      public DirectoryPortal(String dir) {
        super(dir);
      }
      
      public void requestRealmSky(String d) {
        // Normal (single) sky or
        String sky = file.anyImageFile(d+"/"+REALM_SKY);
        // Animated sky
        String sky1 = file.anyImageFile(d+"/"+REALM_SKY+"-1");
        
        // If not null there exists some image of that file.
        if (sky != null) {
          addRequestToQueue(sky);
        }
        else if (sky1 != null) {
          addRequestToQueue(sky1);
        }
        else {
          // No img sky found, get default sky
          this.img = REALM_SKY_DEFAULT.get();
        }
      }
      
      public void run() {
        // Screen glow effect.
        // Calculate distance to portal
        float dist = PApplet.pow(x-playerX, 2)+PApplet.pow(z-playerZ, 2);
        if (dist < MIN_PORTAL_LIGHT_THRESHOLD) {
          // If close to the portal, set the portal light to create a portal enter/transistion effect.
          portalLight = max(portalLight, (1.-(dist/MIN_PORTAL_LIGHT_THRESHOLD))*255.);
        }
        
        // Entering the portal.
        if (touchingPlayer() && portalCoolDown < 1.) {
          sound.playSound("shift");
          // Perfectly optimised. Creating a new state instead of a new screen
          gotoRealm(this.dir, stateDirectory);
        }
      }
  
      public void display() {
        if (visible) {
          scene.shader(
            display.getShaderWithParams("portal_plus", "u_resolution", (float)scene.width, (float)scene.height, "u_time", display.getTimeSeconds(), "u_dir", -direction/(PI*2))
          );
          super.display();
          scene.resetShader();
          
  
          scene.noTint();
  
          // Display text over the portal showing the directory.
          float d = direction-PI;
          //float w = img.width*size;
          if (lights) scene.noLights();
          scene.pushMatrix();
          scene.translate(x, y-hi, z);
          scene.rotateY(d);
          scene.textSize(24);
          scene.textFont(engine.DEFAULT_FONT);
          scene.textAlign(CENTER, CENTER);
          scene.fill(255);
          scene.text(filename, 0, 0, 0);
          scene.popMatrix();
          if (lights) scene.lights();
  
          // Reset tint
          this.tint = color(255);
        }
      }
    }
  
    public PRObject closestObject = null;
    public float closestVal = 0.;
    
    class PRCoin extends PRObject {
      
      public PRCoin(float x, float y, float z) {
        super(x,y,z);
        this.img = IMG_COIN.get();
        setSize(0.25);
        this.hitboxWi = wi;
      }
      
      public void display() {
        this.img = IMG_COIN.get();
        super.display();
      }
      
      public void run() {
        if (touchingPlayer()) {
          coinCounterBounce = 1.;
          sound.playSound("coin");
          collectedCoins++;
          if (collectedCoins % 100 == 0)
            sound.playSound("oneup");
          this.destroy();
        }
      }
    }
  
    class PRObject {
      public int id;
      public float x;
      public float y;
      public float z;
      public PImage img = null;
      protected float size = 1.;
      protected float wi = 0.;
      protected float hi = 0.;
      protected float hitboxWi;
      public boolean visible = true;         // Used for manual turning on/off visibility
      public color tint = color(255);
      protected ItemSlot<PRObject> myOrderingNode = null;
  
      public PRObject() {
        myOrderingNode = ordering.add(this);
      }
  
      public PRObject(float x, float y, float z) {
        this();
        this.x = x;
        this.y = y;
        this.z = z;
      }
  
      public void calculateVal() {
        float xx = playerX-x;
        float zz = playerZ-z;
        this.myOrderingNode.val = xx*xx + zz*zz + wi*0.5;
      }
  
      public boolean touchingPlayer() {
        float sw = hitboxWi*0.5;
        float spw = PLAYER_WIDTH*0.5;
        return (playerX-spw < (x+sw)
          && (playerX+spw > (x-sw)) 
          && ((playerZ-spw) < (z+sw)) 
          && ((playerZ+spw) > (z-sw)) 
          && (playerY-PLAYER_HEIGHT < (y)) 
          && (playerY > (y-hi)));
      }
      
      
  
  
      public void checkHovering() {
        float d_sin = cache_flatSinDirection*(wi/2);
        float d_cos = cache_flatCosDirection*(wi/2);
        float x1 = x + d_sin;
        float z1 = z + d_cos;
        float x2 = x - d_sin;
        float z2 = z - d_cos;
  
        final float SELECT_FAR = 500.;
  
        float beamX1 = playerX;
        float beamZ1 = playerZ;
  
        // TODO: optimise.
        float beamX2 = playerX+sin(direction)*SELECT_FAR;
        float beamZ2 = playerZ+cos(direction)*SELECT_FAR;
  
        //boolean withinYrange = (y-hi < playerY-
  
        if (lineLine(x1, z1, x2, z2, beamX1, beamZ1, beamX2, beamZ2)) {
          if (this.myOrderingNode.val < closestVal && holdingObject != this) {
            closestVal = this.myOrderingNode.val;
            closestObject = this;
          }
        }
      }
  
      // Note: you need to run checkHovering for all hoverable 3d objects first.
      public boolean hovering() {
        if (closestObject == this) {
          // Highlight the object if its being hovered over.
          // We only hover on certain tools where the object's interactable.
          // TODO: bring back currentTools or something
          if (currentTool == TOOL_GRABBER)
            this.tint = color(255, 230, 200);
          return true;
        } else {
          return false;
        }
      }
  
      public boolean selectedLeft() {
        return hovering() && primaryAction;
      }
  
      public boolean selectedRight() {
        return hovering() && secondaryAction;
      }
  
      public void destroy() {
        ordering.remove(myOrderingNode);
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
      
      public void run() {
        // By default nothing.
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
          float sin_d = cache_flatSinDirection*(hwi);
          float cos_d = cache_flatCosDirection*(hwi);
          float x1 = x + sin_d;
          float z1 = z + cos_d;
          float x2 = x - sin_d;
          float z2 = z - cos_d;
  
          displayQuad(x1, y1, z1, x2, y1+hi, z2, useFinder);
  
          // Reset tint
          this.tint = color(255);
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
        float dist = PApplet.pow((playerX-x), 2)+PApplet.pow((playerZ-z), 2);
  
        boolean dontRender = false;
        if (dist > terrain.FADE_DIST_OBJECTS) {
          float fade = calculateFade(dist, terrain.FADE_DIST_OBJECTS);
          if (fade > 1) {
            scene.tint(tint, fade);
          } else {
            dontRender = true;
          }
        } else scene.tint(tint, 255);
  
  
        if (useFinder) {
          scene.stroke(255, 127, 127);
          scene.strokeWeight(2.);
          scene.noFill();
        } else {
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
          scene.vertex(x2, y1, z2, 0.995, 0);    // Bottom right
          scene.vertex(x2, y2, z2, 0.995, 0.995); // Top right
          scene.vertex(x1, y2, z1, 0, 0.995);  // Top left
          if (useFinder) scene.vertex(x1, y1, z1, 0, 0);  // Extra vertex to render a complete square if finder is enabled.
          // Not necessary if just rendering the quad without the line.
          scene.noTint();
          scene.endShape();
  
          scene.popMatrix();
        }
      }
    }
    // End PRObject classes.
    
    
    
    // --- State-dependant functions that our realm (And PRObjects) use ---
    boolean onGround() {
      return (playerY >= onSurface(playerX, playerZ)-1.);
    }
    
    
    private float onSurface(float x, float z) {
      if (terrain == null) {
        //console.bugWarn("onSurface() needs the terrain to be loaded before it's called!");
        return 0.;
      }
      float chunkx = floor(x/terrain.groundSize)+1.;
      float chunkz = floor(z/terrain.groundSize)+1.;  
  
      PVector pv1 = calcTile(chunkx-1., chunkz-1.);          // Left, top
      PVector pv2 = calcTile(chunkx, chunkz-1.);          // Right, top
      PVector pv3 = calcTile(chunkx, chunkz);          // Right, bottom
      PVector pv4 = calcTile(chunkx-1., chunkz);          // Left, bottom
      return getplayerYOnQuad(pv1, pv2, pv3, pv4, x, z);
    }
    
    
  
    private float calculateFade(float dist, float fadeDist) {
      // Calculate the fade distance using the predefined fade distance setting.
      float d = (dist-fadeDist);
      // Calculate the how much we scale the fade so that it doesn't fade so fast that it looks like it
      // pops/disappears into distance. We use this funky pow statement since we're dealing with un-square-rooted
      // distances. I do it in the name of refusing to use sqrt!!
      float scale = (5./PApplet.pow(terrain.groundSize, 1.8));
      // Finally, apply the scale to the fade distance and do an "inverse" (e.g. 220 out of 255 -> 35 out of 255) so
      // that we're fading away tiles furthest from us, not closest to us.
      return 255-(d*scale);
    }
  
    // BIG TODO: Adapt for custom terrain.
    private PVector calcTile(float x, float z) {
      if (terrain instanceof SinesinesineTerrain) {
        SinesinesineTerrain t = (SinesinesineTerrain)terrain;
        float y = sin(x*t.hillFrequency)*t.hillHeight+sin(z*t.hillFrequency)*t.hillHeight;
        return new PVector(t.groundSize*(x), y, t.groundSize*(z));
      }
      else {
        console.bugWarn("calcTile: Unimplemented terrain type.");
        return new PVector(0,0,0);
      }
    }
    
    
    protected ItemSlot<PocketItem> addToPockets(PRObject item) {
      String name = "Unknown";
      // Anything that isn't *the* physical file is abstract.
      boolean abstractObject = false;
      if (item instanceof FileObject) {
        FileObject o = (FileObject)item;
        name = o.filename;
        
        // We absolutely do NOT want to move the exit portal!!
        if (item == exitPortal)
          abstractObject = true;
      }
      PocketItem p = new PocketItem(name, item, abstractObject);
      pocketItemNames.add(name);
      ItemSlot<PocketItem> ii = pockets.add(p);
      return ii;
    }
    
    private void throwItIntoTheVoid(PRObject o) {
      o.x += 9999999.;
      o.y += 9999999.;
      o.z += 9999999.;
    }
    
    protected void pickupItem(PRObject p) {
      globalHoldingObjectSlot = addToPockets(p);
      updateHoldingItem(globalHoldingObjectSlot);
    }
    
    protected void updateHoldingItem(ItemSlot<PocketItem> newSlot) {
      // So that it isn't just left there when we switch.
      if (holdingObject != null) {
        throwItIntoTheVoid(holdingObject);
      }
      
      if (newSlot != null)
        globalHoldingObject = newSlot.carrying;
      else 
        globalHoldingObject = null;
      
      if (globalHoldingObject != null) {
        holdingObject = globalHoldingObject.item;
        // Depends on our object and its state
        // This case, it's an abstract object.
        //if (globalHoldingObject.abstractObject) {
        //  holdingObject = globalHoldingObject.item;
        //}
        //// Case: it's not syncd.
        //// File is not in pockets and is instead still in the realm
        //// we could technically cache it but let's just re-create the object.
        //// It makes no difference.
        //else if (!globalHoldingObject.syncd) {
        //  // Recreate the FileObject in this realm.
        //  holdingObject = createPRObject(file.directorify(stateDirectory)+globalHoldingObject.name);
        //}
        //// Otherwise, it is indeed in our pockets. 
        //// Recreate it in this realm.
        //else {
        //  holdingObject = createPRObject(engine.APPPATH+engine.POCKET_PATH+globalHoldingObject.name);
        //}
      }
      // Case: globalHoldingObject is null.
      // Remember that globalHoldingObject is kind of cache more than anything. It relies on globalHoldingObjectSlot.
      // So if globalHoldingObjectSlot is null, it means there's no more items in the inventory and yada yada
      // I don't think there's anything else to do here.
      else {
        holdingObject = null;
      }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // ----- LOAD REALM CODE -----
    
    // Load realm but we don't emerge out of anywhere.
    public void loadRealm() {
      // Get all files (creates the FileObject instances)
      openDir();
      
      // Read the JSON (load terrain information and position of these objects)
      loadRealmTerrain();
      if (terrain == null) terrain = new SinesinesineTerrain();
      
      // Get realm's terrain assets (sky, grass, trees, music)
      loadRealmTextures();
    }
    
    public void refreshFiles() {
      // Get rid of all the old files
      for (FileObject o : files) {
        o.destroy();
        o = null;
      }
      // also destroy the pocketobjects
      for (PRObject o : pocketObjects) {
        o.destroy();
        o = null;
      }
      files = new LinkedList<FileObject>();
      
      // Reload everything!
      openDir();
      loadRealmTerrain();
      if (terrain == null) terrain = new SinesinesineTerrain();
    }
    
    public void refreshEverything() {
      portalLight = 255;
      refreshFiles();
      loadRealmTextures();
    }
    
    public FileObject createPRObjectAndPickup(String path) {
      if (!file.exists(path)) {
        console.bugWarn("createPRObjectAndPickup: "+path+"doesn't exist!");
      }
      FileObject o = createPRObject(path);
      files.add(o);
      pickupItem(o);
      return o;
    }
    
    public FileObject createPRObject(String path) {
      if (!file.exists(path)) {
        console.bugWarn("createPRObject: "+path+" doesn't exist!");
      }
      
      // If it's a folder, create a portal object.
      if (file.isDirectory(path)) {
        DirectoryPortal portal = new DirectoryPortal(0., 0., 0., path);
        return portal;
      }
      // If it's a file, create the corresponding object based on the file's type.
      else {
        FileObject fileobject = null;

        FileType type = file.extToType(file.getExt(path));
        switch (type) {
        case FILE_TYPE_UNKNOWN:
          fileobject = new UnknownTypeFileObject(path);
          fileobject.img = engine.display.systemImages.get(file.typeToIco(type));
          fileobject.setSize(0.5);
          // NOTE: Put back hitbox size in case it becomes important later
          break;
        case FILE_TYPE_IMAGE:
          fileobject = new ImageFileObject(path);
          break;
        case FILE_TYPE_SHORTCUT:
          fileobject = new ShortcutPortal(0., 0., 0., path);
          break;
        case FILE_TYPE_MODEL:
          fileobject = new OBJFileObject(0., 0., 0., path);
          break;
        default:
          fileobject = new UnknownTypeFileObject(path);
          fileobject.img = display.systemImages.get(file.typeToIco(type));
          fileobject.setSize(0.5);
          // NOTE: Put back hitbox size in case it becomes important later
          break;
        }
        return fileobject;
      }
    }
    
    // A version of opendir which uses the engine's opendir but then
    // creates 3d objects that resemble each item in the directory.
    // NOTE: SHOULD ONLY BE CALLED ONCE UPON CREATING THE REALMSTATE.
    
    // NOTE: If any file changes state, rather than reloading the whole realm,
    // why not just update the files without the portal flash?
    // I.e. this should only be called once
    public void openDir() {
      // First, we need to destroy all file objects since these will be reloaded.
      if (files != null) {
        for (FileObject f : files) {
          if (f != null) f.destroy();
        }
      }
      
      String dir = this.stateDirectory;
      file.openDir(dir);
      int l = file.currentFiles.length;
      
      for (int i = 0; i < l; i++) {
        if (file.currentFiles[i] != null) {
          // Here we determine which type of object to load into our scene.
          files.add(createPRObject(file.currentFiles[i].path));
        }
      }
      
      // Oh, and we need to load our pocket objects
      // First reset all our lists.
      pocketObjects = new LinkedList<PRObject>();
      pocketItemNames = new HashSet<String>();
      pockets = new LinkedList<PocketItem>();
      
      
      JSONObject somejson = new JSONObject();
      File[] pocketFolder = (new File(engine.APPPATH+engine.POCKET_PATH)).listFiles();
      for (File f : pocketFolder) {
        String path = f.getAbsolutePath();
        
        // Create actual file object
        FileObject fileObject = createPRObject(path);
        fileObject.load(somejson);
        
        // Create pocket item
        PocketItem p = new PocketItem(f.getName(), fileObject, false);
        p.syncd = true;
        
        // Add it to za lists
        pocketItemNames.add(f.getName());
        pocketObjects.add(fileObject);
        globalHoldingObjectSlot = pockets.add(p);
        
        // Yeet it into the void so we can't see it.
        throwItIntoTheVoid(fileObject);
      }
      
      updateHoldingItem(globalHoldingObjectSlot);
    }
    
    public void loadRealmTerrain() {
      String dir = this.stateDirectory;
      // Find out if the directory has a turf file.
      JSONObject jsonFile = null;
      
      
      if (file.exists(dir+REALM_TURF)) {
        try {
          jsonFile = app.loadJSONObject(dir+REALM_TURF);
        }
        catch (RuntimeException e) {
          console.warn("There's an error in the folder's turf file (exception). Will now act as if the turf is new.");
          file.backupMove(dir+REALM_TURF);
          saveRealmJson();
          return;
        }
        if (jsonFile == null) {
          console.warn("There's an error in the folder's turf file (null). Will now act as if the turf is new.");
          file.backupMove(dir+REALM_TURF);
          saveRealmJson();
          return;
        }
        
        
        // backward compatibility checking time!
        version = jsonFile.getString("compatibility_version", "");
        
        
        // JUST FOR TESTING!!!
        loadRealmV1(jsonFile);
        
        // Our current version
        //if (version.equals(COMPATIBILITY_VERSION)) {
        //  loadRealmV2(jsonFile);
        //}
        //// Legacy "world_3d" version where everything was simple and a mess lol.
        //else if (version.equals("1.0")) {
        //  loadRealmV1(jsonFile);
        //}
        //// Unknown version.
        //else {
        //  console.log("Incompatible turf file, backing up old and creating new turf.");
        //  file.backupMove(dir+REALM_TURF);
        //  saveRealmJson();
        //}
        
        
      // File doesn't exist; create new turf file.
      } else {
        console.log("Creating new realm turf file.");
        if (version.equals("1.0")) terrain = new SinesinesineTerrain();
        saveRealmJson();
      }
    }
    
    public void loadRealmV1(JSONObject jsonFile) {
      boolean createCoins = false;
      
      JSONArray objects3d = jsonFile.getJSONArray("objects3d");
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
      // Load settings
      // All old versions use the sinsinsin terrain type.
      SinesinesineTerrain t = new SinesinesineTerrain();
      
      t.setRenderDistance(jsonFile.getInt("render_distance", 6));
      t.setGroundSize(jsonFile.getFloat("ground_size", 400.));
      t.hillHeight = jsonFile.getFloat("hill_height", 0.);
      t.hillFrequency = jsonFile.getFloat("hill_frequency", 0.5);
      createCoins = jsonFile.getBoolean("coins", true);
      coins = createCoins;
      
      terrain = t;
      if (terrain == null) console.bugWarn("loadRealmV1: Terrain is still null!");
      
      // Because it relies on this *very* inefficient legacy system,
      // we need to create the appropriate objects for V1 legacy.
      legacy_terrainObjects = new Stack<PRObject>(int(((terrain.renderDistance+5)*2)*((terrain.renderDistance+5)*2)));
      legacy_autogenStuff = new HashSet<String>();
      app.noiseSeed(getHash(stateDirectory));

      int l = objects3d.size();
      // Loop thru each file object in the array. Remember each object is uniquely identified by its filename.
      for (int i = 0; i < l; i++) {
        try {
          JSONObject probjjson = objects3d.getJSONObject(i);
          
          // Each object is uniquely identified by its filename/folder name.
          String name = probjjson.getString("filename", engine.APPPATH+engine.GLITCHED_REALM);
          // Due to the filename used to be called "dir", check for legacy names.

          // Get the object by name so we can do a lil bit of things to it.
          FileObject o = namesToObjects.remove(name);
          if (o == null) {
            // This may happen if a folder/file has been renamed/deleted. Just move
            // on to the next item.
            continue;
          }

          // From here, the way the object is loaded is depending on its type.
          o.load(probjjson);
        }
        // For some reason we can get unexplained nullpointerexceptions.
        // Just a lazy way to overcome it, literally doesn't affect anything.
        // Totally. Totally doesn't affect anything.
        catch (RuntimeException e) {
        }
      }
      
      
      // TODO: ill do it later (maybe)
      
      if (createCoins) {
        float x = random(-1000, 1000);
        float z = random(-1000, 1000);
        for (int i = 0; i < 100; i++) {
          PRCoin coin = new PRCoin(x, onSurface(x,z), z);
          x += random(-500, 500);
          z += random(-500, 500);
        }
      }
    }
    
    // (as of Jan 2024) our latest and current version where we load turf files from.
    public void loadRealmV2(JSONObject jsonFile) {
      
    }
    
    
    
    
    public void saveRealmJson() {
      boolean allowSaving = true;  // Debug flag to be safe while we're testing on our own files.
      if (!allowSaving) {
        console.log("NOTE: Saving disabled.");
        return;
      }
      
      JSONObject turfJson = new JSONObject();
      boolean success = true;
      // Based on the version...
      if (version.equals("1.0")) {
        success = saveRealmV1(turfJson);
      }
      else if (version.equals(COMPATIBILITY_VERSION)) {
        success = saveRealmV2(turfJson);
      }
      else {
        console.bugWarn("saveRealmJson: version "+version+" unknown.");
      }
      
      if (!success) {
        console.warn("Turf file saving failed (not related to an IO error!)");
        return;
      }
      
      try {
        file.backupAndSaveJSON(turfJson, this.stateDirectory+REALM_TURF);
      }
      catch (RuntimeException e) {
        console.log("Maybe permissions are denied for this folder?");
        console.warn("Couldn't save turf json: "+e.getMessage());
      }
    }
    
    public boolean saveRealmV1(JSONObject jsonFile) {
      JSONArray objects3d = new JSONArray();
      int i = 0;
      for (FileObject o : files) {
        if (o != null) {
          objects3d.setJSONObject(i++, o.save());
        }
      }
      
      // Terrain will most definitely be a sinesinesine terrain.
      if (!(terrain instanceof SinesinesineTerrain)) {
        console.bugWarn("saveRealmV1: incompatible terrain, when it should be compatbile. Abort save.");
        return false;
      }
      SinesinesineTerrain t = (SinesinesineTerrain)terrain;
  
      jsonFile.setJSONArray("objects3d", objects3d);
      jsonFile.setString("compatibility_version", "1.0");
      jsonFile.setInt("render_distance", (int)t.renderDistance);
      jsonFile.setFloat("ground_size", t.groundSize);
      jsonFile.setFloat("hill_height", t.hillHeight);
      jsonFile.setFloat("hill_frequency", t.hillFrequency);
      
      jsonFile.setBoolean("coins", coins);
      
      return true;
    }
    
    
    public boolean saveRealmV2(JSONObject jsonFile) {
      return false;
    }
    
    
    
    
    public void emergeFromExitPortal(String emergeFrom) {
      // Secure code stuff
      if (emergeFrom.length() > 0)
        if (emergeFrom.charAt(emergeFrom.length()-1) == '/')  emergeFrom = emergeFrom.substring(0, emergeFrom.length()-1);
        
      // TODO: obviously we need to fix for macos and linux. (I think)
      // Really really stupid bug fix.
      if (emergeFrom.equals("C:")) emergeFrom = "C:/";
      emergeFrom     = file.getFilename(emergeFrom);
      
      // Find the exit portal.
      for (FileObject o : files) {
        // While we're at it we can figure out which portal we're emerging from.
        if (emergeFrom.equals(o.filename)) {
          exitPortal = (DirectoryPortal)o;
        }
      }
      
      // If for some reason we're at the root
      // (or some strange place)
      // then just reset to normal position.
      if (exitPortal == null) {
        playerX = 1000.;
        playerY = 0.;
        playerZ = 1000.;
        direction = PI;
        return;
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
      for (PRObject o : files) {
        if (o != null) {
          if (o instanceof DirectoryPortal) {

            // This is +z and -z
            if (o.x > exitPortal.x-AREA_WIDTH && o.x < exitPortal.x+AREA_WIDTH) {
              // +z
              if (o.z > exitPortal.z+AREA_OFFSET && o.z < exitPortal.z+AREA_LENGTH)
                portalCount[1] += 1;
              // -z
              if (o.z < exitPortal.z-AREA_OFFSET && o.z > exitPortal.z-AREA_LENGTH)
                portalCount[3] += 1;
            }
            if (o.z > exitPortal.z-AREA_WIDTH && o.z < exitPortal.z+AREA_WIDTH) {
              // +x
              if (o.x > exitPortal.x+AREA_OFFSET && o.x < exitPortal.x+AREA_LENGTH)
                portalCount[0] += 1;
              // -x
              if (o.x < exitPortal.x-AREA_OFFSET && o.x > exitPortal.x-AREA_LENGTH)
                portalCount[2] += 1;
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
          playerX = exitPortal.x+FROM_DIST;
          playerZ = exitPortal.z;
          direction = HALF_PI + additionalDir;
          break;
          // +z
        case 1:
          playerX = exitPortal.x;
          playerZ = exitPortal.z+FROM_DIST;
          direction = 0. + additionalDir;
          break;
          // -x
        case 2:
          playerX = exitPortal.x-FROM_DIST;
          playerZ = exitPortal.z;
          direction = -HALF_PI + additionalDir;
          break;
          // -z
        case 3:
          playerX = exitPortal.x;
          playerZ = exitPortal.z-FROM_DIST;
          direction = PI + additionalDir;
          break;
        }
      }
    }
    
    public Object getRealmFile(Object defaultFile, String... paths) {
      for (String path : paths) {
        if (file.exists(path)) {
          if (file.getExt(path).equals("png") || file.getExt(path).equals("gif")) {
            incrementMemUsage(file.getImageUncompressedSize(path));
            return loadImage(path);
          }
          else if (file.getExt(path).equals("wav"))
            return new SoundFile(engine.app, stateDirectory+path);
        }
      }
      return defaultFile;
    }
  
  
    
    // Used with a flash to refresh the sky
    // TODO: Needs tidying up (especially since we have a imageFileExists method now)
    public void loadRealmTextures() {
      String dir = this.stateDirectory;
      // Refresh the dir without resetting the position.
      
      // Reset memory usage
      memUsage.set(0);
      // TODO: we should also prolly kill all active loading threads too somehow...
  
      // Portal light to make it look like a transition effect
      portalLight = 255;
      
      // TODO: read any image format (png, gif, etc)
      img_grass = new RealmTexture((PImage)getRealmFile(REALM_GRASS_DEFAULT.get(), dir+REALM_GRASS+".png"));
      
      /// here we search for the terrain objects textures from the dir.
      ArrayList<PImage> imgs = new ArrayList<PImage>();
  
      if (file.exists(REALM_SKY+".gif"))
        img_sky = new RealmTexture(((Gif)getRealmFile(REALM_SKY_DEFAULT.get(), dir+REALM_SKY+".gif")).getPImages());
      else {
        
        // Get either a sky called sky-1 or just sky
        int i = 1;
        PImage sky = (PImage)getRealmFile(REALM_SKY_DEFAULT.get(), dir+REALM_SKY+".png", dir+REALM_SKY+"-1.png");
        imgs.add(sky);
        
        // If we find a sky, keep looking for sky-2, sky-3 etc
        while (sky != REALM_SKY_DEFAULT.get() && i <= 9) {
          sky = (PImage)getRealmFile(REALM_SKY_DEFAULT.get(), dir+REALM_SKY+"-"+str(i+1)+".png");
          if (sky != REALM_SKY_DEFAULT.get()) {
            imgs.add(sky);
          }
          i++;
        }
        
        img_sky = new RealmTexture(imgs);
      }
      
      imgs = new ArrayList<PImage>();
  
      // Try to find the first terrain object texture, it will return default if not found
      PImage terrainobj = (PImage)getRealmFile(REALM_TREE_DEFAULT.get(), dir+REALM_TREE_LEGACY+"-1.png", dir+REALM_TREE+"-1.png", dir+REALM_TREE+".png");
      imgs.add(terrainobj);
  
      int i = 1;
      // Run this loop only if the terrain_objects files exist and only for how many pixelrealm-terrain_objects
      // there are in the folder.
      while (terrainobj != null && i <= 9) {
        terrainobj = (PImage)getRealmFile(null, dir+REALM_TREE_LEGACY+"-"+str(i+1)+".png", dir+REALM_TREE+"-"+str(i+1)+".png");
        if (terrainobj != null) {
          imgs.add(terrainobj);
        }
        i++;
      }
  
      // New array and plonk that all in there.
      img_tree = new RealmTexture(imgs);
  
      //if (!loadedMusic) {
      String[] soundFileFormats = {".wav", ".mp3", ".ogg", ".flac"};
      boolean found = false;
      i = 0;
  
      // Search until one of the pixelrealm-bgm with the appropriate file format is found.
      while (i < soundFileFormats.length && !found) {
        String ext = soundFileFormats[i++];
        File f = new File(stateDirectory+REALM_BGM+ext);
        if (f.exists()) {
          found = true;
          musicPath = stateDirectory+REALM_BGM+ext;
        }
      }
  
      // If none found use default bgm
      if (!found) {
        musicPath = engine.APPPATH+REALM_BGM_DEFAULT;
      }
    }
    
    
    
    
    
    
    
    
    
    // Finally, the most important code of all
    
    // ----- Pixel Realm logic code -----
    
    public void runPlayer() {
      primaryAction = engine.keyActionOnce("primaryAction");
      secondaryAction = engine.keyActionOnce("secondaryAction");
      
      isWalking = false;
      float speed = WALK_ACCELERATION;
  
      if (engine.keyAction("dash")) {
        speed = RUN_SPEED+runAcceleration;
        if (RUN_SPEED+runAcceleration <= MAX_SPEED) runAcceleration+=RUN_ACCELERATION;
      } else runAcceleration = 0.;
      if (engine.shiftKeyPressed) {
        speed = SNEAK_SPEED;
        runAcceleration = 0.;
      }
  
      // :3
      if (engine.keyAction("jump") && onGround()) speed *= 3;
  
      float sin_d = sin(direction);
      float cos_d = cos(direction);
      
      // Less movement control while in the air.
      if (!onGround()) {
        speed *= 0.1;
      }
  
      // TODO: re-enable reposition mode
      //if (repositionMode) {
      //  if (clipboard != null) {
      //    if (clipboard instanceof ImageFileObject) {
      //      ImageFileObject fileobject = (ImageFileObject)clipboard;
      //    }
      //  }
      //}
      
      if (engine.keyActionOnce("prevDirectory")) {
        //sound.fadeAndStopMusic();
        //requestScreen(new Explorer(engine, stateDirectory));
        if (!file.atRootDir(stateDirectory)) {
          gotoRealm(file.getPrevDir(stateDirectory), stateDirectory);
        }
      }
  
      
      
      // Adjust for lower framerates than the target.
      speed *= display.getDelta();
      
  
      if (!movementPaused) {
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
            if (engine.keyAction("lookRight")) rot = -SLOW_TURN_SPEED*display.getDelta();
            if (engine.keyAction("lookLeft")) rot =  SLOW_TURN_SPEED*display.getDelta();
          } else {
            if (engine.keyAction("lookRight")) rot = -TURN_SPEED*display.getDelta();
            if (engine.keyAction("lookLeft")) rot =  TURN_SPEED*display.getDelta();
          }
  
  
          // If holding item and we're in reposition mode, move the object instead of the player.
          //if (currentTool == TOOL_GRABBER_REPOSITION) {
          //  if (inventorySelectedItem != null) {
  
          //    // Rotate if the object is an image or related.
          //    if (inventorySelectedItem.carrying instanceof ImageFileObject) {
          //      ImageFileObject fileobject = (ImageFileObject)inventorySelectedItem.carrying;
          //      fileobject.rot += rot;
          //    }
  
          //    inventorySelectedItem.carrying.x += movex;
          //    inventorySelectedItem.carrying.z += movez;
          //  }
          //} else
          {
            direction += rot;
            xvel += movex;
            zvel += movez;
            playerX += xvel;
            playerZ += zvel;
            
            float deacceleration = 0.5;
            if (!onGround())
              deacceleration = 0.97;
            xvel *= pow(deacceleration, display.getDelta());
            zvel *= pow(deacceleration, display.getDelta());
            
            if (isWalking && onGround()) {
              float bob_speed = speed*0.075;
              
              float maxBobSpeed = display.getDelta()*1.5;
  
              // If we bob too much, the bob will jiggle wayyyy to much
              // and the sound effect will be played too much and end up reallllly glitchy
              if (bob_speed < maxBobSpeed) {
                bob += bob_speed;
              }
              else {
                bob += maxBobSpeed;
              }
                
              if (bob-HALF_PI > TWO_PI-HALF_PI) {
                bob = 0.;
                sound.playSound("step", random(0.9, 1.2));
              }
            }
          }
          
          cache_flatSinDirection = sin(direction-PI+HALF_PI);
          cache_flatCosDirection = cos(direction-PI+HALF_PI);
          
          // --- Jump & gravity physics ---
          if (engine.keyAction("jump") && onGround() && jumpTimeout < 1.) {
            yvel = JUMP_STRENGTH;
            playerY -= 10;
            sound.playSound("jump");
            jumpTimeout = 30.;
          }
  
          if (jumpTimeout > 0) jumpTimeout -= display.getDelta();
          playerY -= yvel*display.getDelta();
          
          if (onGround()) {
            yvel = 0.;
            playerY = onSurface(playerX, playerZ);
          } 
          else {
            // Change yvel while we're in the air
            yvel = min(yvel-GRAVITY*display.getDelta(), TERMINAL_VEL);
          }
  
          if (playerY > 2000.) {
            playerX = 1000.;
            playerY = 0.;
            playerZ = 1000.;
            yvel = 0.;
          }
          
          // If holding an item, allow scaling up and down.
          //if (inventorySelectedItem != null) {
          //  if (engine.keyAction("scaleUp")) {
          //    inventorySelectedItem.carrying.scaleUp(0.10*display.getDelta());
          //  }
          //  if (engine.keyAction("scaleDown")) {
          //    inventorySelectedItem.carrying.scaleDown(0.10*display.getDelta());
          //  }
          //  if (engine.keyAction("scaleUpSlow")) {
          //    inventorySelectedItem.carrying.scaleUp(0.03*display.getDelta());
          //  }
          //  if (engine.keyAction("scaleDownSlow")) {
          //    inventorySelectedItem.carrying.scaleDown(0.03*display.getDelta());
          //  }
          //}
          
          
          // Sorry for the cluster of code but if you read it it's really simpleeeeeeeee
          if (globalHoldingObjectSlot != null) {
            if (engine.keyActionOnce("inventorySelectLeft") && globalHoldingObjectSlot.prev != null) {
              launchWhenPlaced = false;
              globalHoldingObjectSlot = globalHoldingObjectSlot.prev;
              updateHoldingItem(globalHoldingObjectSlot);
              sound.playSound("pickup");
            }
            
            if (engine.keyActionOnce("inventorySelectRight") && globalHoldingObjectSlot.next != null) {
              launchWhenPlaced = false;
              globalHoldingObjectSlot = globalHoldingObjectSlot.next;
              updateHoldingItem(globalHoldingObjectSlot);
              sound.playSound("pickup");
            }
          }
      }
    }
    
    
    public void renderTerrain() {
      if (version.equals("1.0")) {
        renderTerrainV1();
      }
      else if (version.equals("2.0")) {
        renderTerrainV2();
      }
      else {
        console.bugWarn("renderTerrain: unknown version"+version);
        return;
      }
    }
    
    public void renderTerrainV1() {
      // Terrain should always be Sinesinesine
      if (!(terrain instanceof SinesinesineTerrain)) {
        console.bugWarn("renderTerrainV1: Terrain type should be sinesinesine for legacy terrain.");
        return;
      }
      // Otherwise, proceed.
      SinesinesineTerrain tt = (SinesinesineTerrain)terrain;
      
      scene.pushMatrix();
      float chunkx = floor(playerX/tt.groundSize)+1.;
      float chunkz = floor(playerZ/tt.groundSize)+1.; 
  
      // This only uses a single cycle, dw.
      legacy_terrainObjects.empty();
  
      // TODO: fix the bug once and for all!
      scene.hint(ENABLE_DEPTH_TEST);
  
      for (float tilez = chunkz-tt.renderDistance-1; tilez < chunkz+tt.renderDistance; tilez += 1.) {
        //                                                        random bug fix over here.
        for (float tilex = chunkx-tt.renderDistance-1; tilex < chunkx+tt.renderDistance; tilex += 1.) {
          float x = tt.groundSize*(tilex-0.5), z = tt.groundSize*(tilez-0.5);
          float dist = PApplet.pow((playerX-x), 2)+PApplet.pow((playerZ-z), 2);
  
          boolean dontRender = false;
          if (dist > tt.FADE_DIST_GROUND) {
            float fade = calculateFade(dist, tt.FADE_DIST_GROUND);
            if (fade > 1) scene.tint(255, fade);
            else dontRender = true;
          } else scene.noTint();
  
          if (!dontRender) {
            float noisePosition = noise(tilex, tilez);
  
            scene.beginShape();
            scene.textureMode(NORMAL);
            scene.textureWrap(REPEAT);
            scene.texture(img_grass.get());
  
  
            if (tilex == chunkx && tilez == chunkz) {
              //scene.tint(color(255, 127, 127));
              //console.log(str(chunkx)+" "+str(chunkz));
            }
  
            PVector v1 = calcTile(tilex-1., tilez-1.);          // Left, top
            PVector v2 = calcTile(tilex, tilez-1.);          // Right, top
            PVector v3 = calcTile(tilex, tilez);          // Right, bottom
            PVector v4 = calcTile(tilex-1., tilez);          // Left, bottom
  
            scene.vertex(v1.x, v1.y, v1.z, 0, 0);                                    
            scene.vertex(v2.x, v2.y, v2.z, tt.groundRepeat, 0);  
            scene.vertex(v3.x, v3.y, v3.z,tt.groundRepeat, tt.groundRepeat);  
            scene.vertex(v4.x, v4.y, v4.z, 0, tt.groundRepeat);       
  
  
            scene.endShape();
            //scene.noTint();
  
            final float treeLikelyhood = 0.6;
            final float randomOffset = 70;
  
            if (noisePosition > treeLikelyhood) {
              float pureStaticNoise = (noisePosition-treeLikelyhood);
              float offset = -randomOffset+(pureStaticNoise*randomOffset*2);
  
              // Only create a new tree object if there isn't already one in this
              // position.
  
              String id = str(tilex)+","+str(tilez);
              if (!legacy_autogenStuff.contains(id)) {
                float terrainX = (tt.groundSize*(tilex-1))+offset;
                float terrainZ = (tt.groundSize*(tilez-1))+offset;
                float terrainY = onSurface(terrainX, terrainZ)+10;
                TerrainPRObject tree = new TerrainPRObject(
                  terrainX, 
                  terrainY, 
                  terrainZ, 
                  3+(30*pureStaticNoise), 
                  id
                  );
                legacy_terrainObjects.push(tree);
              }
            }
          }
        }
      }
      scene.noTint();
      scene.colorMode(RGB, 255);
  
      scene.popMatrix();
    }
    
    public void renderTerrainV2() {
      console.bugWarn("renderTerrainV2: Not implemented yet!");
    }
    
    public void renderSky() {
      // Clear canvas (we need to do that because opengl is big stoopid)
      // TODO: benchmark; scene.clear or scene.background()?
      scene.background(0);
      scene.noTint();
      scene.noStroke();
      
      // Render the sky.
      float skyDelta = -(direction/TWO_PI);
      float skyViewportLeft = skyDelta;
      float skyViewportRight = skyDelta+0.25;
  
      scene.beginShape();
      scene.textureMode(NORMAL);
      scene.textureWrap(REPEAT);
      scene.texture(img_sky.get());
      scene.vertex(0, 0, skyViewportLeft, 0.);
      scene.vertex(scene.width, 0, skyViewportRight, 0.);
      scene.vertex(scene.width, scene.height, skyViewportRight, 1.);
      scene.vertex(0, scene.height, skyViewportLeft, 1.);
      scene.endShape();
    }
    
    private void placeDownObject() {
      if (globalHoldingObject != null && currRealm.holdingObject == null) console.bugWarn("placeDownObject: globalHoldingObject != null currRealm.holdingObject == null");
      if (globalHoldingObject == null && currRealm.holdingObject != null) console.bugWarn("placeDownObject: globalHoldingObject == null currRealm.holdingObject != null");
      if (globalHoldingObject != null && currRealm.holdingObject != null) {
        
        // If it's abstract (or unsynced), there's no file to move.
        if (globalHoldingObject.abstractObject || !globalHoldingObject.syncd) {
          
        }
        // Perform file move operation.
        else {
          // Catch the following errors:
          // - File is not in the pockets folder (for some reason)
          // - File already exists
          // - Failed to move
          
          // Yes, it should already be directorified. But we play it safe here.
          String fro = engine.APPPATH+engine.POCKET_PATH+globalHoldingObject.name;
          String to = file.directorify(currRealm.stateDirectory)+globalHoldingObject.name;
          // File is not in the pockets folder (for some reason)
          if (!file.exists(fro)) {
            console.warn(globalHoldingObject.name+" is no longer in the pocket for some reason!");
            currRealm.holdingObject.destroy();
          }
          // File already exists
          else if (file.exists(to)) {
            promptFileConflict(globalHoldingObject.name);
            // DO NOT DO any further actions here!!
            return;
          }
          // Perform the move!
          // ... in an if statement.
          // handle Failed to move case.
          // If we continue from here, we guchii
          else if (!file.mv(fro, to)) {
            promptFailedToMove(globalHoldingObject.name);
            // DO NOT DO any further actions here!!
            return;
          }
          // If we get past this point we gutch!!
        }
        
        // Need to do a few things when we move files like that.
        // Update folder's destination location)
        if (holdingObject instanceof PixelRealmState.DirectoryPortal) {
          PixelRealmState.DirectoryPortal portal = (PixelRealmState.DirectoryPortal)holdingObject;
          portal.dir = file.directorify(currRealm.stateDirectory)+portal.filename;
        }
        
        // Open the file if requested (i.e. create new entry)
        if (launchWhenPlaced) {
          if (currRealm.holdingObject instanceof FileObject) {
            FileObject o = (FileObject)currRealm.holdingObject;
            file.open(o.dir);
            currentTool = TOOL_NORMAL;
            launchWhenPlaced = false;
          }
        }
        
        // Simply setting it to null will "release"
        // the object, setting it in place.
        holdingObject = null;
        
        ItemSlot tmp = null;
        // Switch to next item in the queue
        if (globalHoldingObjectSlot.next != null) tmp = globalHoldingObjectSlot.next;
        else if (globalHoldingObjectSlot.prev != null) tmp = globalHoldingObjectSlot.prev;
        
        // Remove from inventory
        pockets.remove(globalHoldingObjectSlot);
        
        // Set the new "holdingitem" to the item we switched to in the queue/hotbar.
        globalHoldingObjectSlot = tmp;
          
        updateHoldingItem(globalHoldingObjectSlot);
      }
    }
    
    public void runPRObjects() {
      // Collision check (for now lets only do it to fileobjects)
      closestVal = Float.MAX_VALUE;
      closestObject = null;
      for (FileObject f : files) {
        f.checkHovering();
      }
      // Also check for pocket items
      for (PRObject f : pocketObjects) {
        f.checkHovering();
      }
      
      // Pick up code
      if (closestObject != null) {
        FileObject p = (FileObject)closestObject;
        
        // When clicked pick up the object.
        if (currentTool == TOOL_GRABBER) {
          if (primaryAction) {
            pickupItem(p);
            
            sound.playSound("pickup");
          }
        }
      }
      
      // Plonking down objects
      if (currentTool == TOOL_GRABBER && currRealm.holdingObject != null && secondaryAction) {
        placeDownObject();
        sound.playSound("plonk");
      }
      
      // Holding object
      if (currentTool == TOOL_GRABBER) {
        // TODO: Subtools
        if (holdingObject != null) {
          float SELECT_FAR = 300.;
          float x = playerX+sin(direction)*SELECT_FAR;
          float z = playerZ+cos(direction)*SELECT_FAR;
          holdingObject.x = x;
          holdingObject.z = z;
          if (onGround())
            holdingObject.y = onSurface(x, z);
          else
            holdingObject.y = playerY;
            
          if (holdingObject instanceof ImageFileObject) {
            ImageFileObject imgobject = (ImageFileObject)holdingObject;
            imgobject.rot = direction+HALF_PI;
          }
        }
      }
      //else if (holdingObject != null) {
      //  holdingObject.destroy();
      //  holdingObject = null;
      //}
      if (!movementPaused) {
        for (PRObject o : ordering) {
          o.run();
          o.calculateVal();
          //console.log(o.getClass().getSimpleName());
        }
        ordering.insertionSort();
      }
    }
    
    float closestDist = 0;
    public void renderPRObjects() {
      for (PRObject o : ordering) {
        o.display();
      }
    }
    
    // That "effect" is just the portal glow.
    public void renderEffects() {
      float FADE = 0.9;
      if (portalLight > 0.1) {
        scene.blendMode(ADD);
        scene.fill(portalLight);
  
        sound.setSoundVolume("portal", max(portalLight/255., 0.));
        scene.noStroke();
        scene.rect(0, 0, scene.width, scene.height);
        scene.blendMode(NORMAL);
      }
      
      // Sorry not sorry for putting this in "effects".
      if (currRealm.collectedCoins > 0 && currRealm.collectedCoins < 100) {
        scene.textFont(engine.DEFAULT_FONT, 16);
        float y = 8.-coinCounterBounce*6.;
        scene.image(IMG_COIN.get(), 10, y, 16, 17);
        scene.textAlign(LEFT, TOP);
        scene.fill(255);
        scene.text("x "+str(collectedCoins), 30, y);
        
        coinCounterBounce *= pow(0.85, display.getDelta());
      }
      
    
      // When we exit a portal, there's usually a bit of lag as we read files/perform loading,
      // which causes the delta to be high and try to boost us forwards like 30 frames.
      // However, with the old FPS system, SLEEPY mode was the minimum at 15fps, which meant we could
      // only skip at most 4 frames at a time. We wanna keep that cool bug :sunglasses:
      portalLight *= PApplet.pow(FADE, min(display.getDelta(), 4));

    }
    
    
    
  }
  // End PixelRealm state class.
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  // --- All of PixelRealm's non-state realm platformer code. ---
  private float getplayerYOnQuad(PVector v1, PVector v2, PVector v3, PVector v4, float playerX, float playerZ) {
    // Part 1
    float v3tov4 = v3.x-v4.x;
    float v2tov3 = v3.z-v2.z;
    float m1 = 0.;
    if ((playerZ-v1.z) != 0.) m1 = (playerX-v1.x)/(playerZ-v1.z);
    
    PVector point1;
    boolean otherEdge = false;
    if (m1 > 1) {
      // Swappsies and inversies
      m1 = ((playerZ-v1.z)/(playerX-v1.x));
      point1 = new PVector(v3.x, v1.y, v2.z+(v2tov3)*m1);
      otherEdge = true;
    } else {
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
    float len = 0.;
    if (otherEdge) {
      float v1tov2 = v2.x-v1.x;
      float v2toPoint1 = point1.z-v2.z;
      len = sqrt(v1tov2*v1tov2 + v2toPoint1*v2toPoint1);
    } else {
      float v1tov4 = v4.z-v1.z;
      float v4toPoint1 = point1.x-v4.x;
      len = sqrt(v1tov4*v1tov4 + v4toPoint1*v4toPoint1);
    }

    // Part 4
    // Yay
    // Pythagoras again
    float playerLen = 0.0;
    if (otherEdge) {
      float v1toPlayer = playerX-v1.x;
      float v2toPlayer = playerZ-v2.z;
      playerLen = sqrt(v1toPlayer*v1toPlayer + v2toPlayer*v2toPlayer);
    } else {
      float v1toPlayer = playerZ-v1.z;
      float v4toPlayer = playerX-v4.x;
      playerLen = sqrt(v1toPlayer*v1toPlayer + v4toPlayer*v4toPlayer);
    }
    float percent = playerLen/len;
    float calculatedY = lerp(v1.y, point1Height, percent);

    return calculatedY;
  }
  
  private int getHash(String path) {
    // For now, just hash the dir string to get a value from 0 to 255.
    int hash = 0;

    for (int i = 0; i < path.length(); i++) {
      hash += path.charAt(i)*i;
    }

    return hash;
  }
  
  // LINE/LINE
  private boolean lineLine(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {

    // calculate the direction of the lines
    float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
    float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));

    // if uA and uB are between 0-1, lines are colliding
    return (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1);
  }
  
  protected void bumpBack() {
    portalCoolDown = 30.;
    sound.playSound("nope");
    portalLight = 10;
    currRealm.playerY -= 10.;
    currRealm.xvel *= -6.;
    currRealm.zvel *= -6.;
    currRealm.yvel = 5.;
  }
  
  public void gotoRealm(String to) {
    gotoRealm(to, "");
  }
  
  public void gotoRealm(String to, String fro) {
    if (to == null) {
      console.bugWarn("gotoRealm: null to location!");
      bumpBack();
      return;
    }
    if (!file.exists(to)) {
      console.bugWarn("gotoRealm: "+to+" doesn't exist!");
      bumpBack();
      return;
    }
    portalLight = 255.;
    
    // Update inventory for moving realms (move files)
    boolean success = true;
    // Abort if unsuccessful.
    for (PocketItem p : pockets) {
      success &= p.changeRealm(currRealm.stateDirectory);
    }
    if (!success) {
      // bump back the player lol.
      bumpBack();
      
      return;
    }
    
    // Do caching here.
    if (prevRealm != null) {
      if (prevRealm.stateDirectory.equals(file.directorify(to))) {
        PixelRealmState tmp = currRealm;
        currRealm = prevRealm;
        // currRealm is now prevrealm
        prevRealm = tmp;
        if (fro.length() > 0)
          currRealm.emergeFromExitPortal(fro);
        else {
          currRealm.playerX = 1000.;
          currRealm.playerY = 0.;
          currRealm.playerZ = 1000.;
          currRealm.direction = PApplet.PI;
        }
        switchToRealm(currRealm);
        return;
      }
    }
    
    prevRealm = currRealm;
    if (fro.length() == 0)
      currRealm = new PixelRealmState(to);
    else
      currRealm = new PixelRealmState(to, fro);
      
    // Refresh the files since we need to update the inventory.
    currRealm.refreshFiles();
    
    // Creating a new realm won't start the music automatically cus we like manual bug-free control.
    sound.streamMusicWithFade(currRealm.musicPath);
      
    // so that our currently holding item doesn't disappear when we go into the next realm.
    if (currentTool == TOOL_GRABBER) {
      currRealm.updateHoldingItem(globalHoldingObjectSlot);
    }
  }
  
  
  
  protected void switchToRealm(PixelRealmState r) {
    
    // Update inventory for moving realms (move files)
    boolean success = true;
    // Abort if unsuccessful.
    for (PocketItem p : pockets) {
      success &= p.changeRealm(currRealm.stateDirectory);
    }
    if (!success) {
      sound.playSound("nope");
      return;
    }
    currRealm.saveRealmJson();
    currRealm.refreshFiles();
    currRealm.updateHoldingItem(globalHoldingObjectSlot);
    sound.streamMusicWithFade(r.musicPath);
    currRealm = r;
  }
  
  // This took bloody ages to figure out so it better work 100% of the timeee
  // Update: turns out I didn't need to use this function but I'm gonna leave it here
  // because it still took bloody ages D:<
  //private float pointTowards(float myX, float myY, float lookAtX, float lookAtY) {
  //  float rot = 0.;
  //  float mx = lookAtX-myX;
  //  float my = myY-lookAtY;
  //  if (my == 0) my = 1.;

  //  if (my < 0)
  //    rot = atan(-mx/my);
  //  else
  //    rot = atan(-mx/my)+PI;
  //  return rot;
  //}
  
  // --- Memory overflow avoidance (TODO: move to engine) ---
  public void incrementMemUsage(int val) {
    memUsage.getAndAdd(val);
  }
  
  
  public void runMultithreadedLoader() {
    // If there's items available, attempt to assign one of the loader threads with a job.
      int originalValue = loadThreadsUsed.get();
      int max_threads = MAX_LOADER_THREADS;
      
      // In powersaver mode,
      // reduce power usage by only allowing one thread at a time to load content, hence
      // reducing total cpu usage.
      if (power.getPowerSaver()) max_threads = 1;
      
      while ((originalValue = loadThreadsUsed.get()) < max_threads && loadQueue.size() > 0) {
          /// Technically not the best solution,
          //  between int originalValue = loadThreadsAvailable.get();
          //  and the comparison there could be an update.
          //  However it is technically thread safe, because we check again
          //  to ensure that it is still at the expected value.
          //  So worst comes to worst, we will just need to wait until another frame until
          //  we can attempt to allow a thread to load again.
          boolean accessGranted = loadThreadsUsed.compareAndSet(originalValue, originalValue + 1);
          if (accessGranted) {
            // At this point we've got confirmation that we've got our hands on an available resource.
            // So we can set off the next thread to begin loading.
            AtomicBoolean loadFlag = loadQueue.remove(0);
            
            // Tell it to begin its loading thing-!
            loadFlag.set(true);
          }
          
          loading = 10;
      }
  }
  
  public void displayMemUsageBar() {
    int used = memUsage.get();
    float percentage = (float)used/(float)MAX_MEM_USAGE;
    noStroke();
    fill(0, 0, 0, 127);
    rect(100, myUpperBarWeight+20, (WIDTH-200.), 50);
    
    if (memExceeded)
      fill(255, 50, 50); // Mem full.
    else if (percentage > 0.8) 
      fill(255, 140, 20); // Low mem
    else 
      fill(50, 50, 255);  // Normal
    rect(100, myUpperBarWeight+20, (WIDTH-200.)*percentage, 50);
    fill(255);
    textFont(engine.DEFAULT_FONT, 30);
    textAlign(LEFT, CENTER);
    text("Mem: "+(used/1024)+" kb / "+(MAX_MEM_USAGE/1024)+" kb", 105, myUpperBarWeight+45);
  }
  
    
    
    
    
    
    
  // Finally, the most important code of all
  
  // ----- Pixel Realm logic code -----
  private void runPixelRealm() {
    // Pre-rendering stuff.
    portalCoolDown -= display.getDelta();
    animationTick += display.getDelta();
    runMultithreadedLoader();
    
    //This function assumes you have not called portal.beginDraw().
    if (legacy_portalEasteregg) evolvingGatewayRenderPortal();
    
    // Do all non-display logic (for stuff that is displayed)
    // Stuff that is currently on-screen is stored in ordering list.
    currRealm.runPlayer();
    currRealm.runPRObjects();
    
    // Now begin all the drawing!
    scene.beginDraw();
    currRealm.renderSky();
    
    // Make us see really really farrrrrrr
    scene.perspective(PI/3.0, (float)scene.width/scene.height, 1, 10000);
    scene.pushMatrix();

    //scene.translate(-xpos+(scene.width / 2), ypos+(sin(bob)*3)+(scene.height / 2)+80, -zpos+(scene.width / 2));
    {
      float x = currRealm.playerX;
      float y = currRealm.playerY+(sin(bob)*3)-PLAYER_HEIGHT;
      float z = currRealm.playerZ;
      float LOOK_DIST = 200.;
      scene.camera(x, y, z, 
        x+sin(currRealm.direction)*LOOK_DIST, y, z+cos(currRealm.direction)*LOOK_DIST, 
        0., 1., 0.);
      if (currRealm.lights) scene.pointLight(255, 245, 245, x, y, z);
    }

    currRealm.renderTerrain();
    currRealm.renderPRObjects(); 
    
    // Pop the camera.
    scene.popMatrix();
    
    // PERFORMANCE ISSUE: OpenGL state machine is a bitchass!
    // This takes a long itme to do!!
    scene.hint(DISABLE_DEPTH_TEST);
    currRealm.renderEffects();
    
    scene.endDraw();
    image(scene, 0, myUpperBarWeight, WIDTH, this.height);
    
    // TODO: show gui.
    //runGUI();
    if (showMemUsage)
      displayMemUsageBar();
      
    // Quickwarp controls (outside of player controls because we need non-state
    // class to run it)
    for (int i = 0; i < 10; i++) {
      // Go through all the keys 0-9 and check if it's being pressed
      if (engine.keyActionOnce("quickWarp"+str(i))) {
        // Save current realm
        quickWarpRealms[quickWarpIndex] = currRealm;
        
        if (i == quickWarpIndex) console.log("Going back to default dir");
        if (quickWarpRealms[i] == null || i == quickWarpIndex) {
          String dir = engine.DEFAULT_DIR;
          switchToRealm( new PixelRealmState(dir, file.directorify(file.getPrevDir(dir))) );
        }
        else {
          switchToRealm (quickWarpRealms[i]);
        }
        quickWarpIndex = i;
        sound.playSound("swish");
        portalLight = 255;
        break;
      }
    }
  }
  
  
  
  
  // --- Screen standard code ---
  
  public void content() {
    if (engine.power.getSleepyMode()) engine.power.setAwake();
    runPixelRealm(); 
  }
  
  public void upperBar() {
    super.upperBar();
    app.textFont(engine.DEFAULT_FONT);
    app.textSize(36);
    app.textAlign(LEFT, TOP);
    app.fill(0);
    
    if (currRealm == null) return;
    
    if (engine.mouseX() > 0. && engine.mouseX() < app.textWidth(currRealm.stateDirectory) && engine.mouseY() > 0. && engine.mouseY() < myUpperBarWeight) {
      app.fill(50);
      if (engine.leftClick) {
        console.log("Path copied!");
        clipboard.copyString(currRealm.stateDirectory);
      }
    }
    else 
      app.fill(0);
    app.text(currRealm.stateDirectory, 10, 10);
    
    
    if (loading > 0) {
      engine.loadingIcon(WIDTH-myUpperBarWeight/2-10, myUpperBarWeight/2, myUpperBarWeight);
      
      // Doesn't matter too much that it's being converted to an int,
      // it doesn't need to be accurate.
      loading -= (int)display.getDelta();
    }
  }
  
  
  public void startupAnimation() {
    if (engine.showUpdateScreen) {
      requestScreen(new Updater(engine, engine.updateInfo));
      engine.showUpdateScreen = false;
    }
  }
  
  
  
  
  
  
  
  
  
  
  
  
  public boolean customCommands(String command) {
    if (command.equals("/refresh")) {
      console.log("Refreshing dir...");
      currRealm.refreshEverything();
      return true;
    }
    else if (command.equals("/refreshdir")) {
      console.log("Refreshing dir...");
      currRealm.refreshFiles();
      return true;
    }
    //else if (command.equals("/editgui")) {
    //  guiMainToolbar.interactable = !guiMainToolbar.interactable;
    //  if (guiMainToolbar.interactable) console.log("GUI now interactable.");
    //  else  console.log("GUI is no longer interactable.");
    //  return true;
    //} 
    else if (command.equals("/evolvinggateway")) {
      if (legacy_portalEasteregg) {
        sharedResources.set("legacy_evolvinggateway_easteregg", new Boolean(false));
        legacy_portalEasteregg = false;
        console.log("Legacy Evolving Gateway style portals disabled.");
        
        // Resize all the portals to the modern size.
        for (PixelRealmState.FileObject o : currRealm.files) {if (o != null) {if (o instanceof PixelRealmState.DirectoryPortal) {
              o.setSize(0.8);
        }}}
      }
      else {
        sharedResources.set("legacy_evolvinggateway_easteregg", new Boolean(true));
        legacy_portalEasteregg = true;
        console.log("Welcome back to Evolving Gateway!");
        
        // Resize all the portals to the legacy size.
        for (PixelRealmState.FileObject o : currRealm.files) {if (o != null) {if (o instanceof PixelRealmState.DirectoryPortal) {
              o.setSize(1.);
        }}}
      }
      return true;
    }
    else if (command.equals("/memusage")) {
      showMemUsage = !showMemUsage;
      sharedResources.set("show_mem_bar", new Boolean(showMemUsage));
      if (showMemUsage) console.log("Memory usage bar shown.");
      else console.log("Memory usage bar hidden.");
      return true;
    }
    else if (engine.commandEquals(command, "/tp")) {
      String[] args = getArgs(command);
      int i = 0;
      float xyz[] = {1000.,0.,1000.,PI};
      for (String arg : args) {
        if (i >= xyz.length) break;
        xyz[i++] = int(arg);
      }
      currRealm.playerX = xyz[0];
      currRealm.playerY = xyz[1];
      currRealm.playerZ = xyz[2];
      currRealm.direction = xyz[3];
      
      console.log("Teleported to ("+str(currRealm.playerX)+", "+str(currRealm.playerY)+", "+str(currRealm.playerZ)+").");

      return true;
    }
    else return false;
  }
  
  
  // TODO: This should really be in engine-!!!!
  public String[] getArgs(String input) {
    if (input.indexOf(' ') <= -1) {
      return new String[0];
    }
    else {
      String[] arr = input.split(" ");
      String[] args = new String[arr.length-1];
      for (int i = 0; i < args.length; i++) {
        args[i] = arr[i+1];
      }
      return args;
    }
  }
  
  
  
  
  
  
  
  // Easter egg code
  final int portPartNum = 90;
  float portPartX[] = new float[portPartNum];
  float portPartY[] = new float[portPartNum];
  float portPartVX[] = new float[portPartNum];
  float portPartVY[] = new float[portPartNum];
  float portPartTick[] = new float[portPartNum];
  void setupLegacyPortal() {legacy_portal = createGraphics(128, 128+96, P2D); ((PGraphicsOpenGL)legacy_portal).textureSampling(2); legacy_portal.hint(DISABLE_OPENGL_ERRORS);for (int i = 0; i < portPartNum; i++) {portPartX[i] = -999;}}
  public void evolvingGatewayRenderPortal() {     legacy_portal.beginDraw(); legacy_portal.background(color(0, 0, 255), 0); legacy_portal.blendMode(ADD);     float w = 48, h = 48;     int n = 1;     switch (engine.power.getPowerMode()) {     case HIGH:       n = 1;       break;     case NORMAL:       n = 2;       break;     case SLEEPY:       n = 4;       break;     case MINIMAL:       n = 1;       break;     }      for (int j = 0; j < n; j++) {       if (int(random(0, 2)) == 0) {         int i = 0;
boolean finding = true;         while (finding) {           if (int(portPartX[i]) == -999) {             finding = false;             portPartVX[i] = random(-0.5, 0.5);             portPartVY[i] = random(-0.2, 0.2);              portPartX[i] = legacy_portal.width/2;             portPartY[i] = random(h, legacy_portal.height-60);              portPartTick[i] = 255;
  }            i++;           if (i >= portPartNum) {             finding = false;           }         }       }               for (int i = 0; i < portPartNum; i++) {         if (int(portPartX[i]) != -999) {           portPartVX[i] *= 0.99;           portPartVY[i] *= 0.99;            portPartX[i] += portPartVX[i];           portPartY[i] += portPartVY[i];              portPartTick[i] -= 2;            if (portPartTick[i] <= 0) {             portPartX[i] = -999;           }    }       }     }      for (int i = 0; i < portPartNum; i++) {       if (int(portPartX[i]) != -999) {         legacy_portal.tint(color(128, 128, 255), portPartTick[i]);            legacy_portal.image(display.systemImages.get("glow"), portPartX[i]-(w/2), portPartY[i]+(h/2), w, h);       }     }      legacy_portal.blendMode(NORMAL);     legacy_portal.endDraw();   }
}




// How bout a lil easter egg from code from forever ago?
// Also sorry not sorry for the code compression

class WorldLegacy extends Screen { 
  public float height=0; 
  int myRandomSeed=0; 
  float xscroll=0; 
  float yscroll=0; 
  float moveStarX=0;
  boolean displayStars=true; 
  class NightSkyStar { 
    boolean active; 
    float x; 
    float y; 
    int image; 
    int config;
  } 
  NightSkyStar[] nightskyStars;
  int MAX_NIGHT_SKY_STARS=100; 
  float TREE_SPACE=50; 
  float MAX_RANDOM_HEIGHT=500; 
  float WATER_LEVEL=300; 
  float VARI=0.0009;
  float HILL_WIDTH=300; 
  float MOUNTAIN_FREQUENCY=3.; 
  float LOW_DIPS_REQUENCY=0.5; 
  float HIGHEST_MOUNTAIN=1500; 
  float LOWEST_DIPS=1200;
  int OCTAVE=2; 
  public WorldLegacy(Engine engine) { 
    super(engine); 
    this.height=HEIGHT-myLowerBarWeight-myUpperBarWeight;
    myRandomSeed=(int)app.random(100000); 
    scatterNightskyStars();
    console.log("Neo's Legacy World");
  } 
  public void scatterNightskyStars() { 
    int selectedNum=int(app.random(MAX_NIGHT_SKY_STARS/2, MAX_NIGHT_SKY_STARS)); 
    nightskyStars=new NightSkyStar[selectedNum]; 
    for (int i=0; i<selectedNum; i++) { 
      nightskyStars[i]=new NightSkyStar();
      int x=int(app.random(-16, WIDTH)); 
      int y=int(app.random(-16, this.height)); 
      int j=0; 
      boolean colliding=false; 
      final int spacing=4; 
      while (colliding) { 
        colliding=false; 
        while ((j<i)&&!colliding) { 
          if (((x+spacing+16)>(nightskyStars[j].x-spacing))
            &&((x-spacing)<(nightskyStars[j].x+spacing+16))&&((y+spacing+16)>(nightskyStars[j].y-spacing))&&((y-spacing)<(nightskyStars[j].y
            +spacing+16))) { 
            colliding=true;
          } 
          j++;
        }
      } 
      nightskyStars[i].x=x; 
      nightskyStars[i].y=y; 
      nightskyStars[i].image=int(app.random(0, 5)); 
      nightskyStars[i].config=int(app.random(0, 4)); 
      nightskyStars[i].active=true;
    }
  } 
  private void drawNightSkyStars() { 
    for (NightSkyStar star : nightskyStars) { 
      if (star.active) { 
        display.img("nightsky"+str(star.image), star.x, star.y, 16, 16); 
        star.x-=moveStarX; 
        if (star.x<-16||star.x>WIDTH) { 
          star.active=false;
        }
      } else { 
        if (int(app.random(0, 20))==1&&moveStarX!=0.0) { 
          star.x=WIDTH; 
          star.y=int(app.random(-16, this.height)); 
          star.image=int(app.random(0, 5)); 
          star.config=int(app.random(0, 4)); 
          star.active=true;
        }
      }
    }
  }
  private void beginRandom() { 
    app.noiseSeed(myRandomSeed);
  } 
  public float rand(float i, float min, float max) { 
    beginRandom();
    return app.noise(i)*(max-min)+min;
  } 
  public float getHillHeight(float x) { 
    float slow=x*0.0001; 
    return floor(rand(x*VARI, 40, 
      MAX_RANDOM_HEIGHT))+(PApplet.pow(sin(slow*MOUNTAIN_FREQUENCY), 3)*HIGHEST_MOUNTAIN*0.5+HIGHEST_MOUNTAIN)-(sin(slow*LOW_DIPS_REQUENCY)*
      LOWEST_DIPS*0.5+LOWEST_DIPS);
  } 
  public float interpolate(float arr[], float x) { 
    float y1=arr[int(x)]; 
    float y2=arr[int(x)+1];
    float i=(x/HILL_WIDTH); 
    return lerp(y1, y2, i);
  } 
  public void content() { 
    app.noiseDetail(OCTAVE, 2.); 
    display.img("sky_1", 0, myUpperBarWeight, 
      WIDTH, this.height); 
    if (displayStars) drawNightSkyStars(); 
    float hillWidth=HILL_WIDTH; 
    float prevWaveHeight=WATER_LEVEL;
    float prevHeight=0; 
    float floorPos=this.height+myUpperBarWeight; 
    if (engine.mouseEventClick) xscroll+=5; 
    xscroll+=50; 
    moveStarX=1;
    float[] chunks=new float[int(WIDTH/hillWidth)*2]; 
    int j=0; 
    float w=WIDTH+hillWidth; 
    for (float i=-hillWidth; i<w; i+=hillWidth)
    { 
      float x=i+floor(xscroll/hillWidth)*hillWidth; 
      float hillHeight=getHillHeight(x); 
      if (i>WIDTH/2-hillWidth&&i<WIDTH/2
        +hillWidth) { 
        yscroll=lerp(yscroll, hillHeight-300, 0.01);
      } 
      chunks[j++]=hillHeight; 
      float off=float(int(xscroll)%int(hillWidth));
      app.beginShape(); 
      app.fill(0); 
      app.vertex(i-off, floorPos-prevHeight+yscroll); 
      app.vertex(i-off, floorPos); 
      app.vertex(i-off+hillWidth, 
        floorPos); 
      app.vertex(i-off+hillWidth, floorPos-hillHeight+yscroll); 
      app.endShape(); 
      app.beginShape(); 
      app.fill(0, 127, 255, 100); 
      float wave=WATER_LEVEL+sin(x*0.01+app.frameCount*0.1)*10; 
      app.vertex(i-off, max(floorPos-prevWaveHeight+yscroll, 0)); 
      app.vertex(i-off, 
        floorPos); 
      app.vertex(i-off+hillWidth, floorPos); 
      app.vertex(i-off+hillWidth, max(floorPos-wave+yscroll, 0)); 
      app.endShape(); 
      prevHeight=hillHeight; 
      prevWaveHeight=wave;
      app.fill(0);
      app.textFont(engine.DEFAULT_FONT, 40);
      app.textAlign(LEFT, TOP);
      app.text("Press backspace to go back", 10, myUpperBarWeight+5);
    } 
    if (engine.keyDown(BACKSPACE)) previousScreen();
  }
}
