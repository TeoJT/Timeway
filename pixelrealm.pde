import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import java.io.BufferedInputStream;
import java.nio.file.attribute.*;
import java.nio.file.*;
import java.util.ListIterator;
import java.util.Iterator;
import java.io.RandomAccessFile;

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
  final static String COMPATIBILITY_VERSION = "2.1";
  final static String SHORTCUT_COMPATIBILITY_VERSION = "1.0";
  final static String QUICK_WARP_DATASET = "quick_warp_dataset";  // The name of this really doesn't matter as long as it's consistant when quick warping
  final static String QUICK_WARP_ID = "quick_warp_id";  // Name doesn't matter as long as it doesnt change.
  final static float  PSHAPE_SIZE_FACTOR = 100.;
  final static int    MAX_CACHE_SIZE = 512;
  final static float  BACKWARD_COMPAT_SCALE = 256./(float)MAX_CACHE_SIZE;
  private      long   MAX_MEM_USAGE = 1024L*1024L*1024L;   // 1GB 
               int    DISPLAY_SCALE = 4;
  final static int    FOLDER_SIZE_LIMIT = 500;  // If a folder has over this number of files, moving is restricted to prevent any potentially dangerous data moves.
  final static float  MIN_PORTAL_LIGHT_THRESHOLD = 19600.;   // 140 ^ 2
  final static int    CHUNK_SIZE = 8;
  final static int    MAX_CHUNKS_XZ = 32768;
  final static int    MAX_VIDEOS_ALLOWED = 0;
  
  // Movement/player constants.
  final static float BOB_SPEED = 0.4;
  final static float WALK_ACCELERATION = 5.;
  final static float RUN_SPEED = 10.0;
  final static float RUN_ACCELERATION = 0.1;
  final static float MAX_SPEED = 30.;
  final static float UNDERWATER_SPEED_MULTIPLIER = 0.4;
  final static float SNEAK_SPEED = 1.5;
  final static float TURN_SPEED = 0.05;
  final static float MEDIUM_TURN_SPEED = 0.03;
  final static float SLOW_TURN_SPEED = 0.01;
  final static float TERMINAL_VEL = 30.;
  final static float GRAVITY = 0.4;
  final static float UNDERWATER_GRAVITY = 0.1;
  final static float JUMP_STRENGTH = 8.;
  final static float UNDERWATER_JUMP_STRENGTH = 4.;
  final static float PLAYER_HEIGHT = 80;
  final static float PLAYER_WIDTH  = 20;
  final static float UNDERWATER_TEMINAL_VEL = 3.0;
  final static float SWIM_UP_SPEED = 0.8;
  final static float SLIP_THRESHOLD = 2.5;
  
  
  
  // Tool constants
  protected final static int TOOL_NORMAL = 1;
  protected final static int TOOL_GRABBER = 2;
  protected final static int TOOL_MORPHER = 3;
  
  // Morpher
  protected final static int MORPHER_BULGE   = 1;
  protected final static int MORPHER_FLAT    = 2;
  protected final static int MORPHER_BLOCK   = 3;
  protected final static int MORPHER_PIT     = 4;
  protected final static int MORPHER_RESTORE = 5;
  
  // For API
  public final int MODE_PRESCENE = 1;
  public final int MODE_SCENE = 2;
  public final int MODE_POSTSCENE = 3;
  public final int MODE_UI = 4;
  protected int apiMode = 1;
  
  
  
  // File names without an extension accept various file types (png, jpeg, gif)
  public final static String REALM_GRASS = ".pixelrealm-grass";
  public final static String REALM_SKY   = ".pixelrealm-sky";
  public final static String REALM_TREE_LEGACY  = ".pixelrealm-terrain_object";
  public final static String REALM_TREE  = ".pixelrealm-tree";
  public final static String REALM_BGM   = ".pixelrealm-bgm";
  public final static String REALM_TURF  = ".pixelrealm-turf.json";
  public final static String REALM_BGM_DEFAULT = "engine/music/pixelrealm_default_bgm.wav";
  public final static String REALM_PLUGIN = ".pixelrealm-plugin.java";
  
  // Defaults (Loaded on constructor)
  private PImage REALM_GRASS_DEFAULT;
  private PImage REALM_SKY_DEFAULT;
  private PImage REALM_TREE_DEFAULT;
  
  private PShape CASSETTE_OBJ;
  
  
  // --- Cache (sort of) ---
  private float cache_flatSinDirection;
  private float cache_flatCosDirection;
  private float cache_playerSinDirection;
  private float cache_playerCosDirection;
  private boolean primaryAction = false;
  private boolean secondaryAction = false;
  private boolean realmCaching = false;
  private boolean usingFadeShader = false;
  private RealmTexture IMG_COIN;
  private int drawnEntries = 0;
  private int entriesTotal = 0;
  private int timeInRealm  = 0;
  private float timeNotMoving = 0.;
  //protected HashMap<Integer, PVector> tilesCache = new HashMap<Integer, PVector>();
  private float lastXBlockGetHeightAction = 0.;
  private float lastZBlockGetHeightAction = 0.;
  private boolean playingWarpingSound = false;
  
  
  
  // --- Legacy backward-compatibility stuff & easter eggs ---
  protected float height = HEIGHT-myUpperBarWeight-myLowerBarWeight;
  private PGraphics legacy_portal;
  private boolean legacy_portalEasteregg = false;
  private float coinCounterBounce = 0.;
  
  public PImage REALM_GRASS_DEFAULT_LEGACY;
  public PImage REALM_SKY_DEFAULT_LEGACY;
  public PImage REALM_TREE_DEFAULT_LEGACY;
  public final static String REALM_BGM_DEFAULT_LEGACY = "engine/music/pixelrealm_default_bgm_legacy.wav";
  
  // --- Global state and working variables (doesn't require per-realm states) ---
  private PGraphics scene;
  private float runAcceleration = 0.;
  private float bob = 0.0;
  private float jumpTimeout = 0;
  private float coyoteJump = 0.;
  private boolean showExperimentalGifs = false;
  private boolean finderEnabled = false;   // Maybe this could be part of Pixel Realm state?
  protected boolean launchWhenPlaced = false; 
  protected int     currentTool = TOOL_NORMAL;
  protected int     subTool     = 0;
  private boolean isWalking = false;
  public boolean movementPaused = false;
  protected float portalLight = 255.;
  protected boolean isInWater = false;
  protected boolean isUnderwater = false;
  private float portalCoolDown = 45;
  protected boolean usePortalAllowed = true;
  protected boolean modifyTerrain = false;
  protected int nodeSound = 0;
  private boolean drawEntryOnce = true;
  protected float morpherRadius = 150.;
  protected float morpherBlockHeight = 0.;
  protected float fovx = PI/3.0;
  protected float fovy = 0.;
  private int slippingJumpsAllowed = 2;
  protected PixelRealmState.PRObject optionHighlightedItem = null;
  private boolean loadFromCache = false;
  protected String cassettePlaying = "";   // Empty string for realm bgm.
  
  private AtomicBoolean refreshRealm = new AtomicBoolean(false);
  private AtomicInteger refresherCommand = new AtomicInteger(0);
  // 0 means no command.
  public static final int REFRESHER_PAUSE = 1;          // Force pauses for 100ms. This allows us to update the list.
  public static final int REFRESHER_TERMINATE = 2;      // Stops and kills the thread.
  public static final int REFRESHER_RESTART = 3;        // Tells the thread to refresh its lastmodified list, use this when you're switching realms to prevent an unintended realm refresh.
  public static final int REFRESHER_LONGPAUSE = 4;
  public static final int REFRESHER_EXITLONGPAUSE = 5;
      
  
  
  // TODO: Animationtick not required with display.getTime()?
  private float animationTick = 0.;
  
  // Inventory//pocket
  protected LinkedList<PocketItem> pockets   = new LinkedList<PocketItem>();
  protected LinkedList<PocketItem> hotbar    = new LinkedList<PocketItem>();   // Items in hotbar are also in inventory.
  protected HashSet<String> pocketItemNames  = new HashSet<String>(); 
  protected PocketItem globalHoldingObject = null;
  protected ItemSlot<PocketItem> globalHoldingObjectSlot = null;
  
  // Debug-based variables.
  @SuppressWarnings("unused")
  private int operationCount = 0;
  
  // Memory protection (TODO: Move to engine)
  private AtomicLong memUsage = new AtomicLong(0);
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
  public PixelRealm(TWEngine engine, String dir) {
    super(engine);
    
    // --- Load default assets ---
    // TODO (eventually): load screen's assets, not everything from the loading screen (even tho that would be a minor optimisation)
    // (get rid of the . at the start cus hidden files are no good)
    REALM_SKY_DEFAULT = display.systemImages.get("pixelrealm-sky");
    REALM_TREE_DEFAULT = display.systemImages.get("pixelrealm-terrain_object");
    REALM_GRASS_DEFAULT = display.systemImages.get("pixelrealm-grass");
    
    CASSETTE_OBJ = app.loadShape(engine.APPPATH+"engine/other/cassette.obj");
    
    REALM_SKY_DEFAULT_LEGACY = display.systemImages.get("pixelrealm-sky-legacy");
    REALM_TREE_DEFAULT_LEGACY = display.systemImages.get("pixelrealm-terrain_object-legacy");
    REALM_GRASS_DEFAULT_LEGACY = display.systemImages.get("pixelrealm-grass-legacy");
  
    String[] COINS = { "coin_0", "coin_1", "coin_2", "coin_3", "coin_4", "coin_5"};
    IMG_COIN = new RealmTexture(COINS);
    
    // --- Sounds and music ---
    sound.loopSound("portal");
    sound.setSoundVolume("underwater", 0.);
    sound.loopSound("underwater");
    
    // --- Create graphics canvas ---
    // Disable texture filtering
    scene = createGraphics((int(WIDTH/DISPLAY_SCALE)), int(this.height/DISPLAY_SCALE), P3D);
    ((PGraphicsOpenGL)scene).textureSampling(2);        
    scene.hint(DISABLE_OPENGL_ERRORS);
    fovy = (float)scene.width/scene.height;
    // Only set up legacy portal when we go into the easter egg.
    // TODO: re-add. Or most likely remove it :(
    //setupLegacyPortal();
    
    // TODO: I'd love to do a performance benchmark based on the number of cores we're using.
    int numCores = Runtime.getRuntime().availableProcessors();
    // We want to reserve at least one core to run the main thread otherwise it's gonna be REALLY laggy as the
    // OS scheduler dedicates all of its processing resources to loading images.
    MAX_LOADER_THREADS = (numCores/2)-1;
    console.info("# cores reserved for loading: "+MAX_LOADER_THREADS);
    
    if (engine.lowMemory) {
      MAX_MEM_USAGE = 1024L*1024L*80L; // 64MB
    }
    
    String startRealm = file.directorify(file.getPrevDir(dir));
    
    // Start the refresher thread (to automatically refresh realms when files have been changed)
    refresherFilesList[0] = startRealm;
    startRefresherThread();
    
    
    currRealm = new PixelRealmState(dir, startRealm);
    sound.streamMusicWithFade(currRealm.musicPath);
  }
  
  public PixelRealm(TWEngine engine) {
    this(engine, engine.DEFAULT_DIR);
  }
  
  
  // Classes we need
  class RealmTexture {
    private PImage singleImg = null;
    private PImage[] aniImg = null;
    private final static float ANIMATION_INTERVAL = 10.;
    public float width = 0;
    public float height = 0;
    
    
    public RealmTexture() {
      // Nothing
    }
    
    public RealmTexture(PImage img) {
      set(img);
    }
    public void set(PImage img) {
      if (img == null) {
        //console.bugWarn("set: passing a null image");
        singleImg = display.systemImages.get("white");
        width = singleImg.width;
        height = singleImg.height;
        return;
      }
      singleImg = img;
      aniImg = null;
      width = singleImg.width;
      height = singleImg.height;
    }
    public RealmTexture(PImage[] imgs) {
      set(imgs);
    }
    public void set(PImage[] imgs) {
      if (imgs.length == 0) {
        console.bugWarn("set PImage[]: passing an empty list");
        singleImg = display.systemImages.get("white");
        width = singleImg.width;
        height = singleImg.height;
        return;
      }
      else if (imgs.length == 1) {
        singleImg = imgs[0];
        width = imgs[0].width;
        height = imgs[0].height;
        return;
      }
      singleImg = null;
      aniImg = new PImage[imgs.length];
      int i = 0;
      for (PImage p : imgs) {
        aniImg[i++] = p;
      }
      width = aniImg[0].width;
      height = aniImg[0].height;
    }
    public RealmTexture(ArrayList<PImage> imgs) {
      set(imgs);
    }
    public void set(ArrayList<PImage> imgs) {
      if (imgs.size() == 0) {
        console.bugWarn("set ArrayList: passing an empty list");
        singleImg = display.systemImages.get("white");
        return;
      }
      else if (imgs.size() == 1) {
        singleImg = imgs.get(0);
        width = singleImg.width;
        height = singleImg.height;
        return;
      }
      singleImg = null;
      aniImg = new PImage[imgs.size()];
      int i = 0;
      for (PImage p : imgs) {
        aniImg[i++] = p;
      }
      width = aniImg[0].width;
      height = aniImg[0].height;
    }
    public RealmTexture(String[] imgs) {
      set(imgs);
    }
    public void set(String[] imgs) {
      if (imgs.length == 0) {
        console.bugWarn("set String[]: passing an empty list");
        singleImg = display.systemImages.get("white");
        return;
      }
      else if (imgs.length == 1) {
        singleImg = display.systemImages.get(imgs[0]);
        width = singleImg.width;
        height = singleImg.height;
        return;
      }
      singleImg = null;
      aniImg = new PImage[imgs.length];
      int i = 0;
      for (String s : imgs) {
        aniImg[i++] = display.systemImages.get(s);
      }
      width = aniImg[0].width;
      height = aniImg[0].height;
    }
    
    
    public RealmTexture(String imgName) {
      singleImg = display.systemImages.get(imgName);
    }
    
    public int length() {
      if (singleImg != null) return 1;
      else if (aniImg != null) return aniImg.length;
      else return 1;
    }
    
    public PImage get(int index) {
      if (singleImg != null) {
        width = singleImg.width;
        height = singleImg.height;
        return singleImg;
      }
      else if (aniImg != null) {
        width = aniImg[0].width;
        height = aniImg[0].height;
        return aniImg[index%aniImg.length];
      }
      else {
        return display.errorImg;
      }
    }
    
    public PImage get() {
      return this.get(int(animationTick/ANIMATION_INTERVAL));
    }
    
    public PImage getRandom() {
      return this.get(int(app.random(0., aniImg.length)));
    }
    
    public PImage getRandom(float seed) {
      PImage p;
      if (aniImg != null) {
        p = this.get(int( engine.noise(seed) * float(aniImg.length) * 3.)%aniImg.length);
      }
      else {
        p = this.get();
      }
      width = p.width;
      height = p.height;
      return p;
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
        return false;
      }
      
      // Safety measure: can't move back certain files.
      // TODO
      
      if (!syncd) {
        // Can't move files that have the same filename as another file
        // in the pocket.
        if (isDuplicate) {
          promptPocketConflict(name);
          return false;
        }
        
        // Can't move directoryPortals with over a certain limit of files.
        if (item instanceof PixelRealmState.DirectoryPortal) {
          PixelRealmState.DirectoryPortal p = (PixelRealmState.DirectoryPortal)item;
          if (file.countFiles(p.dir) > FOLDER_SIZE_LIMIT) {
            prompt("Folder size limit", name+" has over "+str(FOLDER_SIZE_LIMIT)+" files in it. As a safety precaution, "+engine.getAppName()+" won't move large folders.", 20);
            return false;
          }
        }
        
        boolean success = file.mv(fro+name, engine.APPPATH+engine.POCKET_PATH+name);
        if (!success) {
          //console.warn("failed to move");
          //console.warn("to: "+engine.APPPATH+engine.POCKET_PATH+name);
          //console.warn("fro: "+fro+name);
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
  protected void promptNewRealm() {}
  protected void promptPickedUpItem() {}
  protected void promptPlonkedDownItem() {}
  @SuppressWarnings("unused")
  protected void promptFileOptions(PixelRealmState.FileObject probject) {}
  
  @SuppressWarnings("unused")
  protected void prompt(String title, String text, int appearDelay) {}
  @SuppressWarnings("unused")
  protected void prompt(String title, String text) {}
    
  private Thread refresherThread;
  
  protected boolean cassettePlaying() {
    return !cassettePlaying.equals("");
  }
  
  // Use by the refresher thread only, to check each file to see if it's been refreshed, and if so,
  // signal a file change.
  // NOTE: While programming this, I was originally going to check each file's lastmodified date, only to realise
  // if I check the DIRECTORY's lastmodfied date, this would be way more efficient, and thus eliminating the need
  // for a list, since I would only need to check one dir. But, imma keep it as a list, cus even if it's not used,
  // its useful functionality in case I ever do need it.
  private String[] refresherFilesList = new String[1];
  
  protected void issueRefresherCommand(int cmd) {
    refresherCommand.set(cmd);
    refresherThread.interrupt();
  }
    
  private void startRefresherThread() {
    refresherThread = new Thread(new Runnable() {
          public void run() {
            boolean active = true;
            String[] mylist = new String[refresherFilesList.length];
            boolean needsUpdate = true;
            while (active) {
              try {
                Thread.sleep(100);
              }
              catch (InterruptedException e) {
                // When interrupted, this means we're issuing a command.
                switch (refresherCommand.getAndSet(0)) {
                  case 0:
                  // Do nothing.
                  break;
                  case REFRESHER_PAUSE:
                  // Pause for 100ms.
                  try {
                    Thread.sleep(100);
                  }
                  catch (InterruptedException e2) {
                    // There really shouldn't be another command issued while in this state.
                    console.bugWarn("refresherThread: You're still issuing commands while paused! Slow down!");
                  }
                  // Then we need to update our lastmodified list.
                  needsUpdate = true;
                  break;
                  case REFRESHER_LONGPAUSE:
                  try {
                    // Wait until interrupt called.
                    Thread.sleep(99999999);
                  }
                  catch (InterruptedException e2) {
                    
                  }
                  // Then we need to update our lastmodified list.
                  needsUpdate = true;
                  break;
                  case REFRESHER_TERMINATE:
                  console.log("REFRESHER_TERMINATE");
                  active = false;
                  break;
                  case REFRESHER_RESTART:
                  needsUpdate = true;
                  break;
                }
              }
              
              // If a terminate command was issued.
              if (!active) break;
              
              if (needsUpdate) {
                // Update the list.
                mylist = new String[refresherFilesList.length];
                for (int i = 0; i < refresherFilesList.length; i++) {
                  mylist[i] = file.getLastModified(refresherFilesList[i]);
                }
                needsUpdate = false;
              }
              else {
                // Normal mode: we continously check for lastmodified changes.
                for (int i = 0; i < refresherFilesList.length; i++) {
                  if (!mylist[i].equals(file.getLastModified(refresherFilesList[i]))) {
                    needsUpdate = true;
                    refreshRealm.set(true);
                  }
                }
              }
            }
          }
    });
    refresherThread.start();
  }
    
  
  
  
  
  
  
  
  // --- Pixel realm state ---
  public class PixelRealmState {
    
    public String stateDirectory;
    public String stateFilename;
    
    // --- Player state --- 
    // (1000, 0, 1000) is our default position (and it's imporant for shortcuts)
    public float playerX = 1000.0, playerY = 0., playerZ = 1000.0;
    public float prevPlayerX = 1000.0, prevPlayerY = 0., prevPlayerZ = 1000.0;
    public float xvel = 0., yvel = 0., zvel = 0.;
    public float direction = PApplet.PI;
    
    private float lastPlacedPosX = 0;
    private float lastPlacedPosZ = 0;
    private float exitPortalX = 0;
    private float exitPortalZ = 0;
    
    // Whenever we switch realms, we need to make sure this is being updated with the global
    // state!
    public PRObject holdingObject = null;
    
    // --- Realm textures & state ---
    // Initially defaults, gets loaded with realm-specific files (if exists) later.
    public RealmTexture img_grass = new RealmTexture(REALM_GRASS_DEFAULT);
    public RealmTexture img_tree  = new RealmTexture(REALM_TREE_DEFAULT);
    public RealmTexture img_sky   = new RealmTexture(REALM_SKY_DEFAULT);
    protected TerrainAttributes terrain;
    private DirectoryPortal exitPortal = null;
    private String musicPath = engine.APPPATH+REALM_BGM_DEFAULT;
    private boolean loadMinimal = false;
    public boolean memOverload = false;
    
    private TWEngine.PluginModule.Plugin realmPlugin;
    public String realmPluginPath = "";
    private AtomicBoolean successfulCompile = new AtomicBoolean();
    private AtomicBoolean pluginCompiled = new AtomicBoolean();
    private boolean showDebugMessageOnce = true;
    
    public HashMap<Integer, TerrainChunkV2> chunks = new HashMap<Integer, TerrainChunkV2>();
    
    public String version = COMPATIBILITY_VERSION;
    public int versionCompatibility = 2;
    
    // --- Legacy stuff for backward compatibility ---
    private Stack<PixelRealmState.PRObject> legacy_terrainObjects;
    public HashSet<String> legacy_autogenStuff;
    public boolean lights = false;
    public int collectedCoins = 0;
    public boolean coins = false;
    private boolean createdCoins = false;
    public boolean terraformWarning = true;
    
    // All objects that are visible on the scene, their interactable actions are run.
    protected LinkedList<PRObject> ordering = new LinkedList<PRObject>();
    
    // Not necessary lists here, just useful and faster.
    protected LinkedList<FileObject> files = new LinkedList<FileObject>();
    
    protected LinkedList<PRObject> pocketObjects = new LinkedList<PRObject>();
    
    public ArrayList<TWEngine.UIModule.CustomNode> lightingUINodes = new ArrayList<TWEngine.UIModule.CustomNode>();
    public TWEngine.UIModule.CustomSlider ambientSlider;
    public TWEngine.UIModule.CustomSlider reffectSlider;
    public TWEngine.UIModule.CustomSlider geffectSlider;
    public TWEngine.UIModule.CustomSlider beffectSlider;
    public TWEngine.UIModule.CustomSliderInt lightDirectionSlider;
    public TWEngine.UIModule.CustomSliderInt lightHeightSlider;
    
    final int[] lightDirectionsX = { -2, -1, 0, 1, 2, 2, 2, 2, 2, 1, 0, -1, -2, -2, -2, -2 };
    final int[] lightDirectionsZ = { -2, -2, -2, -2, -2, -1, 0, 1, 2, 2, 2, 2, 2, 1, 0, -1 };
    
    
    
    // --- Constructor ---
    public PixelRealmState(String dir) {
      this.stateDirectory = file.directorify(dir);
      this.stateFilename  = file.getFilename(stateDirectory);
      
      populateLightingUINodes();
      
      loadMinimal = false;
      
      if (isNewRealm()) promptNewRealm();
      // Load realm emerging from our exit portal.
      loadRealm();
      
      // For backwards compatibility (just set version = "1.0")
      if (version.equals("1.0") || version.equals("1.1")) {
        legacy_terrainObjects = new Stack<PRObject>(int(((terrain.getRenderDistance()+5)*2)*((terrain.getRenderDistance()+5)*2)));
        legacy_autogenStuff = new HashSet<String>();
        engine.noiseSeed(getHash(dir));
      }
      if (!loadMinimal) {
        stats.increase("REALMVISITED_"+stateFilename, 1);
      }
    }
    
    public PixelRealmState(String dir, String emergeFrom) {
      this(dir);
      emergeFromPortal(file.directorify(emergeFrom));
    }
    
    
    
    
    
    private void populateLightingUINodes() {
        lightingUINodes.add(ambientSlider = ui.new CustomSlider("Ambient", 0f, 1f, 1f));
        lightingUINodes.add(reffectSlider = ui.new CustomSlider("R", -5f, 5f, 0f));
        lightingUINodes.add(geffectSlider = ui.new CustomSlider("G", -5f, 5f, 0f));
        lightingUINodes.add(beffectSlider = ui.new CustomSlider("B", -5f, 5f, 0f));
        lightingUINodes.add(lightDirectionSlider = ui.new CustomSliderInt("Direction", 0, 16, 0));
        lightingUINodes.add(lightHeightSlider = ui.new CustomSliderInt("Height", -4, 16, 1));
    }
    
    
    
    
    
    // --- Realm terrain attributes ---
    
    public abstract class TerrainAttributes {
      public ArrayList<TWEngine.UIModule.CustomNode> customNodes = new ArrayList<TWEngine.UIModule.CustomNode>();
      
      private float renderDistance = 6.;
      private float groundRepeat = 2.;
      private float groundSize = 100.;
      
      public boolean hasWater = false;
      public float waterLevel = 50.;
      
      public int chunkLimitX = Integer.MAX_VALUE;
      public int chunkLimitZ = Integer.MAX_VALUE;
      
      // Some things are needed for backward compatibilty.
      public float FADE_DIST_OBJECTS = PApplet.pow((renderDistance-4)*groundSize, 2);
      public float FADE_DIST_GROUND = PApplet.pow(PApplet.max(renderDistance-3, 0.)*groundSize, 2);
      public float BEGIN_FADE = 0.0;
      public float FADE_LENGTH = 0.0;
      public String NAME;
      
      public TerrainAttributes() {
        NAME = "[unknown]";
        update();
      }
      
      public void updateAttribs() {
        
      }
      
      
      public void update() {
        // V1
        FADE_DIST_OBJECTS = PApplet.pow((getRenderDistance()-4)*groundSize, 2);
        FADE_DIST_GROUND = PApplet.pow(max(getRenderDistance()-3, 0)*groundSize, 2);
        
        // V2
        float chunkSizeUnits = groundSize*float(CHUNK_SIZE);
        BEGIN_FADE = chunkSizeUnits*(getRenderDistance()-1.5);
        FADE_LENGTH = chunkSizeUnits;
        
        if (versionCompatibility == 2) {
          // Objects are not rendered when this distance is exceeded.
          FADE_DIST_OBJECTS = PApplet.pow((BEGIN_FADE+FADE_LENGTH+FADE_LENGTH), 2);
        }
      }
      
      // Probably not needed but for backward compatibility perposes.
      public void setRenderDistance(int renderDistance) {
        this.renderDistance = float(renderDistance);
        update();
      }
    
      public void setGroundSize(float groundSize) {
        this.groundSize = groundSize;
        update();
      }
      
      public void setChunkLimit(int x, int z) {
        chunkLimitX = x;
        chunkLimitZ = z;
      }
      
      public float getGroundSize() {
        return groundSize;
      }
      
      public float getGroundRepeat() {
        return groundRepeat;
      }
      
      public float getRenderDistance() {
        //if (modifyTerrain) return PApplet.min(renderDistance, 3.);
        return renderDistance;
      }
      
      public float getBeginFade() {
        return BEGIN_FADE;
      }
      
      @SuppressWarnings("unused")
      public void genTerrainObj(float x, float z) {
        console.bugWarn("genTerrainObj: TerrainAttributes is the base class and won't generate terrain objects.");
      }
      
      // This magical method is called whenever a new chunk needs to be generated, and is called for each point
      // for each tile in the chunk.
      // Override it to implement your own chunk generation algorithm.
      public PVector getPointXZ(float x, float z) {
        return new PVector(getGroundSize()*(x), 0, getGroundSize()*(z));
      }
      
      @SuppressWarnings("unused")
      public float getPointY(float x, float z) {
        console.bugWarn("getPointY: TerrainAttributes is the base class and won't calculate points.");
        return 0.;
      }
      
      public void save(JSONObject j) {
          j.setString("terrain_type", NAME);
          j.setBoolean("coins", coins);
          j.setString("compatibility_version", version);
          j.setInt("render_distance", (int)getRenderDistance());
          j.setFloat("ground_size", getGroundSize());
          j.setBoolean("has_water", hasWater);
          j.setFloat("water_level", waterLevel);
          j.setInt("chunk_limit_x", chunkLimitX);
          j.setInt("chunk_limit_z", chunkLimitZ);
      }
      
      public void load(JSONObject j) {
        coins = j.getBoolean("coins", false);
        setRenderDistance(j.getInt("render_distance", 6));
        setGroundSize(j.getFloat("ground_size", 100.));
        hasWater = j.getBoolean("has_water", false);
        waterLevel = j.getFloat("water_level", 50.);
        chunkLimitX = j.getInt("chunk_limit_x", Integer.MAX_VALUE);
        chunkLimitZ = j.getInt("chunk_limit_z", Integer.MAX_VALUE);
      }
      
    }
    
    // Classic lazy ass coding terrain.
    public class SinesinesineTerrain extends TerrainAttributes {
      public float hillHeight = 0.;
      public float hillFrequency = 0.5;
      
      private TWEngine.UIModule.CustomSlider hillHeightSlider;
      private TWEngine.UIModule.CustomSlider hillFrequencySlider;
      
      
      private TWEngine.UIModule.CustomSliderInt renderDistSlider;
      private TWEngine.UIModule.CustomSliderInt chunkLimitSlider;
      private TWEngine.UIModule.CustomSlider waterLevelSlider;
      private TWEngine.UIModule.CustomSlider groundSizeSlider;
      
      public SinesinesineTerrain() {
        NAME = "Sine sine sine";
        createCustomiseNode();
      }
      
      public SinesinesineTerrain(JSONObject j) {
        NAME = "Sine sine sine";
        load(j);
        createCustomiseNode();
      }
      
      private void createCustomiseNode() {
        // Quick reminder of sounds:
        // terraform_1 - Woopwoopwoopwoopwoopwoopwoopwoopwoopwoopwoop
        // terraform_2 - Sounds like you're doing some good kneading to the terrain
        // terraform_3 - Sounds like you're doing something subtle/sounds like water
        // terraform_4 - Sounds like you're doing something weird
        
        customNodes = new ArrayList<TWEngine.UIModule.CustomNode>();
        customNodes.add(hillHeightSlider = ui.new CustomSlider("Height", 0., 800., hillHeight));
        customNodes.add(hillFrequencySlider = ui.new CustomSlider("Frequency", 0.0, 3.0, hillFrequency));
        
        customNodes.add(groundSizeSlider = ui.new CustomSlider("Tile size", 20., 1000., getGroundSize()));
        customNodes.add(renderDistSlider = ui.new CustomSliderInt("Render dist", 1, 15, (int)getRenderDistance()));
        customNodes.add(chunkLimitSlider = ui.new CustomSliderInt("Chunk limit", 1, 50, 50));
        customNodes.add(waterLevelSlider = ui.new CustomSlider("Water level", -300, 300, -waterLevel));
        waterLevelSlider.setWhenMin("No water");
        chunkLimitSlider.setWhenMax("Unlimited");
      }
      
      
      public void updateAttribs() {
        
        hillHeight = hillHeightSlider.valFloat;
        hillFrequency = hillFrequencySlider.valFloat;
        
        setGroundSize(groundSizeSlider.valFloat);
        setRenderDistance(renderDistSlider.valInt);
        chunkLimitX = chunkLimitSlider.valInt;
        if (chunkLimitX == 100) chunkLimitX = Integer.MAX_VALUE;
        chunkLimitZ = chunkLimitX;
        
        // Up is minus and down is positive.
        // This may be confusing for the user.
        // So just flip the signs here.
        waterLevel = -waterLevelSlider.valFloat;
        hasWater = (waterLevel < 300.);
      }
      
      // Based on (copied from) the v1 terrain renderer,
      // Not called by legacy v1 terrain renderer
      public void genTerrainObj(float x, float z) {
        engine.noiseDetail(2, 0.5);
        float noisePosition = engine.noise(x, z);
        
        final float treeLikelyhood = 0.6;
        final float randomOffset = 70;

        if (noisePosition > treeLikelyhood) {
          float pureStaticNoise = (noisePosition-treeLikelyhood);
          float offset = -randomOffset+(pureStaticNoise*randomOffset*2);

          float terrainX = (getGroundSize()*(x-1))+offset;
          float terrainZ = (getGroundSize()*(z-1))+offset;
          float terrainY = onSurface(terrainX, terrainZ)+10;
          
          if (terrainY > waterLevel && hasWater) return;
          
          @SuppressWarnings("unused")
          TerrainPRObject tree = new TerrainPRObject(
            terrainX, 
            terrainY, 
            terrainZ, 
            3+(30*pureStaticNoise)
          );
        }
      }
      
      public float getPointY(float x, float z) {
        float y = sin(x*hillFrequency)*hillHeight+sin(z*hillFrequency)*hillHeight;
        return y;
      }
      
      public void load(JSONObject j) {
        super.load(j);
        hillHeight = j.getFloat("hill_height", 0.);
        hillFrequency = j.getFloat("hill_frequency", 0.5);
      }
      
      public void save(JSONObject j) {
        super.save(j);
        
        j.setString("terrain_type", NAME);
        j.setFloat("hill_height", hillHeight);
        j.setFloat("hill_frequency", hillFrequency);
      }
    }
    
    public class LegacyTerrain extends TerrainAttributes {
      float MAX_RANDOM_HEIGHT=0.500; 
      float VARI=0.08;
      float HILL_WIDTH=0.300; 
      float MOUNTAIN_FREQUENCY=3.; 
      float LOW_DIPS_REQUENCY=0.5; 
      float HIGHEST_MOUNTAIN=1.500; 
      float LOWEST_DIPS=1.200;
      float TREE_FREQUENCY = 0.2;
      int OCTAVE=2; 
      int NOISE_SEED = 1;
      
      public void save(JSONObject j) {
        super.save(j);
        try {
          j.setString("terrain_type", NAME);
          j.setFloat("max_random_height", MAX_RANDOM_HEIGHT);
          j.setFloat("variability", VARI);
          j.setFloat("hill_width", HILL_WIDTH);
          j.setFloat("mountain_frequency", MOUNTAIN_FREQUENCY);
          j.setFloat("low_dips_frequency", LOW_DIPS_REQUENCY);
          j.setFloat("highest_mountain", HIGHEST_MOUNTAIN);
          j.setFloat("lowest_dips", LOWEST_DIPS);
          j.setFloat("tree_frequency", TREE_FREQUENCY);
          j.setInt("noise_octave", OCTAVE);
          j.setInt("noise_seed", NOISE_SEED);
        }
        catch (NullPointerException e) { 
          console.warn("Realm info read failed: missing terrain properties(s)");
        }
        catch (RuntimeException e) {
          console.warn("Realm info read failed: Unknown JSON error.");
        }
      }
      
      public void load(JSONObject j) {
        super.load(j);
        MAX_RANDOM_HEIGHT=      j.getFloat("max_random_height");
        VARI=                   j.getFloat("variability");
        HILL_WIDTH=             j.getFloat("hill_width");
        MOUNTAIN_FREQUENCY=     j.getFloat("mountain_frequency");
        LOW_DIPS_REQUENCY=      j.getFloat("low_dips_frequency");
        HIGHEST_MOUNTAIN=       j.getFloat("highest_mountain");
        LOWEST_DIPS=            j.getFloat("lowest_dips");
        TREE_FREQUENCY =        j.getFloat("tree_frequency");
        OCTAVE=                 j.getInt("noise_octave");
        NOISE_SEED =            j.getInt("noise_seed");
      }
      
      private TWEngine.UIModule.CustomSlider maxHeightSlider;
      private TWEngine.UIModule.CustomSlider variSlider;
      private TWEngine.UIModule.CustomSlider hillFrequencySlider;
      private TWEngine.UIModule.CustomSlider treeSlider;
      private TWEngine.UIModule.CustomSliderInt octaveSlider;
      
      private TWEngine.UIModule.CustomSlider waterLevelSlider;
      private TWEngine.UIModule.CustomSliderInt renderDistSlider;
      private TWEngine.UIModule.CustomSliderInt chunkLimitSlider;
      private TWEngine.UIModule.CustomSlider groundSizeSlider;
      
      public LegacyTerrain() {
        NAME = "Legacy";
        NOISE_SEED = int(random(0., 99999999.));
        createCustomiseNode();
      }
      
      public LegacyTerrain(JSONObject j) {
        this();
        load(j);
        createCustomiseNode();
      }
      
      private void createCustomiseNode() {
        customNodes = new ArrayList<TWEngine.UIModule.CustomNode>();
        customNodes.add(maxHeightSlider  = ui.new CustomSlider("Max height", -200., 200., -HIGHEST_MOUNTAIN));
        customNodes.add(variSlider       = ui.new CustomSlider("Variability", 0., 0.5, VARI));
        customNodes.add(hillFrequencySlider = ui.new CustomSlider("Hill frequency", 0., 400., MOUNTAIN_FREQUENCY));
        customNodes.add(treeSlider = ui.new CustomSlider("Tree frequency", 0., 1.0, TREE_FREQUENCY));
        treeSlider.setWhenMin("No trees");
        customNodes.add(octaveSlider = ui.new CustomSliderInt("Noise Octave", 1, 4, OCTAVE));
        
        
        customNodes.add(groundSizeSlider = ui.new CustomSlider("Tile size", 20., 1000., getGroundSize()));
        customNodes.add(renderDistSlider = ui.new CustomSliderInt("Render dist", 1, 15, (int)getRenderDistance()));
        customNodes.add(chunkLimitSlider = ui.new CustomSliderInt("Chunk limit", 1, 50, 50));
        customNodes.add(waterLevelSlider = ui.new CustomSlider("Water level", -800, 2000, -waterLevel));
        waterLevelSlider.setWhenMin("No water");
        chunkLimitSlider.setWhenMax("Unlimited");
      }
      
      @Override
      public void updateAttribs() {
        HIGHEST_MOUNTAIN = -maxHeightSlider.valFloat;
        VARI = variSlider.valFloat;
        MOUNTAIN_FREQUENCY = hillFrequencySlider.valFloat;
        TREE_FREQUENCY = treeSlider.valFloat;
        OCTAVE = octaveSlider.valInt;
        
        setGroundSize(groundSizeSlider.valFloat);
        setRenderDistance(renderDistSlider.valInt);
        
        chunkLimitX = chunkLimitSlider.valInt;
        if (chunkLimitX == 100) chunkLimitX = Integer.MAX_VALUE;
        chunkLimitZ = chunkLimitX;
        
        // Up is minus and down is positive.
        // This may be confusing for the user.
        // So just flip the signs here.
        waterLevel = -waterLevelSlider.valFloat;
        hasWater = (waterLevel < 800.);
      }
      
      private float rand(float x, float y, float min, float max) { 
          engine.timestamp("noise");
        return engine.noise(x, y)*(max-min)+min;
      } 
      
      private float getHillHeight(float x, float y) { 
        return floor(rand(x*VARI, y*VARI, 40, 
          MAX_RANDOM_HEIGHT))+(PApplet.pow(sin(x*0.0001*MOUNTAIN_FREQUENCY)+sin(y*0.000173*MOUNTAIN_FREQUENCY), 3)*HIGHEST_MOUNTAIN*0.5+HIGHEST_MOUNTAIN)-(sin(x*0.0001*LOW_DIPS_REQUENCY)*
          LOWEST_DIPS*0.5+LOWEST_DIPS);
      }
      
      public void genTerrainObj(float x, float z) {
        engine.noiseSeed(NOISE_SEED);
        engine.noiseDetail(4, 0.5); 
        x = x*getGroundSize()+getGroundSize()*0.5;
        z = z*getGroundSize()+getGroundSize()*0.5;

        //float y = plantDown(x, z);
        float y = onSurface(x, z);
        
        if (y > waterLevel && hasWater) return;
        if (engine.noise(x*100+95423, z*9812+1934825) > TREE_FREQUENCY) return;
        
        @SuppressWarnings("unused")
        TerrainPRObject tree = new TerrainPRObject(
                x, 
                y,
                z, 
                3.+(3.*engine.noise(x+1280, z+57322))
        );
      }
      
      public float getPointY(float x, float z) {
        engine.noiseSeed(NOISE_SEED);
        engine.noiseDetail(OCTAVE, 2.); 
        
        float y = getHillHeight(x, z)*20.;
        return y;
      }
    }
    
    
    public void switchTerrain(int index) {
      switch (index) {
        case 0:
        terrain = new SinesinesineTerrain();
        break;
        case 1:
        terrain = new LegacyTerrain();
        break;
      }
    }
    
    
    
    
    public class TerrainChunkV2 {
      
      // Somewhat of a unique identifier for the chunk.
      public int chunkX = 0;
      public int chunkY = 0;
      
      public PVector[][] tiles;
      public PShape pshapeChunk = null;
      
      public TerrainChunkV2(int cx, int cy) {
        this.chunkX = cx;
        this.chunkY = cy;
        tiles = new PVector[CHUNK_SIZE+1][CHUNK_SIZE+1];
        
        
        // Terrain (ground)
        for (int y = 0; y < CHUNK_SIZE+1; y++) {
          for (int x = 0; x < CHUNK_SIZE+1; x++) {
            float xx = float(x+chunkX*CHUNK_SIZE);
            float yy = float(y+chunkY*CHUNK_SIZE);
            
            tiles[y][x] = calcTile(xx-1., yy-1.);
            
            terrain.genTerrainObj(xx-1., yy-1.);
          }
        }
        
        //joinTiles();
        
        updatePShape();
      }
      
      // Create new chunk by loading data (equivalent to a load function)
      public TerrainChunkV2(JSONObject json) {
        tiles = new PVector[CHUNK_SIZE+1][CHUNK_SIZE+1];
        chunkX = json.getInt("x", Integer.MAX_VALUE);
        chunkY = json.getInt("z", Integer.MAX_VALUE);
        
        try {
          if (!json.isNull("data")) {
            // Decoding is much easier this time lol.
            byte[] decodedBytes = Base64.getDecoder().decode( json.getString("data").getBytes() );
            loadFromBytes(decodedBytes);
          }
        }
        catch (RuntimeException e) {
          console.warn("Couldn't load chunk from JSON. Maybe chunk is corrupted?");
        }
        
        //joinTiles();
        
        updatePShape();
      }
      
      
      
      public void loadFromBytes(byte[] data) {
        try {
          float[] vectors = new float[(CHUNK_SIZE+1)*(CHUNK_SIZE+1)];
          
          // reconstruct bytes into float array.
          int floatCount = data.length / 4; // assuming each float is represented by 4 bytes
  
          // Convert Base64 to float array.
          for (int i = 0; i < floatCount; i++) {
              int intBits = 0;
              for (int j = 0; j < 4; j++) {
                  intBits |= ((data[i * 4 + j] & 0xFF) << (8 * j));
              }
              vectors[i] = Float.intBitsToFloat(intBits);
          }
          
          int i = 0;
          // Convert float array to vectors in tiles.
          for (int y = 0; y < CHUNK_SIZE+1; y++) {
            for (int x = 0; x < CHUNK_SIZE+1; x++) {
              float xx = float(x+chunkX*CHUNK_SIZE);
              float yy = float(y+chunkY*CHUNK_SIZE);
              
              PVector v = calcTileXZ(xx-1., yy-1.);
              v.y = vectors[i++];
              tiles[y][x] = v;
            }
          }
        }
        catch (RuntimeException e) {
          console.warn("Couldn't load chunk from JSON. Maybe chunk is corrupted?");
        }
      }
      
      // Assumes tiles has already been set
      private void updatePShape() {
          scene.textureWrap(REPEAT);
          pshapeChunk = createShape();
          pshapeChunk.beginShape(QUAD);
          pshapeChunk.textureMode(NORMAL);
          // TODO: add code ready for custom tile textures.
          pshapeChunk.texture(img_grass.get());
          
          // Bug fix: extra logic cus the edge tile in the minux direction is visible but has no
          // collision and it's very annoying.
          int stx = (chunkX == -terrain.chunkLimitX) ? 1 : 0;
          int sty = (chunkY == -terrain.chunkLimitZ) ? 1 : 0;
          
          boolean version2_1 = version.equals("2.1");
          int chunkSizeX = (chunkX == terrain.chunkLimitX-1 && version2_1) ? CHUNK_SIZE-1 : CHUNK_SIZE;
          int chunkSizeY = (chunkY == terrain.chunkLimitZ-1 && version2_1) ? CHUNK_SIZE-1 : CHUNK_SIZE;
          
          for (int y = sty; y < chunkSizeY; y++) {
            for (int x = stx; x < chunkSizeX; x++) {
                PVector[] v = new PVector[4];
                
                v[0] = tiles[y][x];
                v[1] = tiles[y][x+1];
                v[2] = tiles[y+1][x+1];
                v[3] = tiles[y+1][x];
                
                //if (glowingchunk == hashIndex) {
                //  if (glowingtilex == x && glowingtiley == y) {
                //    if (blink) continue;
                //  }
                //}
                
                pshapeChunk.vertex(v[0].x, v[0].y, v[0].z, 0, 0);                                    
                pshapeChunk.vertex(v[1].x, v[1].y, v[1].z, 1.0, 0);  
                pshapeChunk.vertex(v[2].x, v[2].y, v[2].z, 1.0, 1.0);  
                pshapeChunk.vertex(v[3].x, v[3].y, v[3].z, 0, 1.0);
            }
          }
              
          pshapeChunk.endShape(QUAD);
      }
      
      public byte[] getByteData() {
        float[] vectors = new float[(tiles.length) * (tiles[0].length)];
        
        int ii = 0;
        for (int y = 0; y < CHUNK_SIZE+1; y++) {
          for (int x = 0; x < CHUNK_SIZE+1; x++) {
            vectors[ii++] = tiles[y][x].y;
          }
        }
        
        // Convert float array to byte array
        byte[] byteArray = new byte[vectors.length * 4]; // 4 bytes for each float
        for (int i = 0; i < vectors.length; i++) {
            int intBits = Float.floatToRawIntBits(vectors[i]);
            byteArray[i * 4 + 3] = (byte) ((intBits >> 24) & 0xFF);
            byteArray[i * 4 + 2] = (byte) ((intBits >> 16) & 0xFF);
            byteArray[i * 4 + 1] = (byte) ((intBits >> 8) & 0xFF);
            byteArray[i * 4 + 0] = (byte) intBits;
        }
        
        return byteArray;
      }
      
      public JSONObject save() {
        JSONObject j = new JSONObject();
        j.setInt("x", chunkX);
        j.setInt("z", chunkY);
        int hashIndex = MAX_CHUNKS_XZ*chunkY + chunkX;
        j.setInt("hash", hashIndex);
        
        byte[] byteArray = getByteData();
        
        // Convert our chunk to base64!
        String data = Base64.getEncoder().encodeToString(byteArray);
        
        j.setString("data", data);
        return j;
      }
      
      boolean blink = true;
      public void renderChunk() {
        // In modifyTerrain mode, terrain is re-generated every frame (slow but dynamic, used for previewing custom terrain)
        // In non-modifyTerrain mode, terrain uses PShapes stored in GPU memory (fast but rigid, to change tile data you must re-generate entire chunk)
        if (!modifyTerrain) {
          try {
            scene.shape(pshapeChunk);
          }
          catch (RuntimeException e) {
            //console.warn("Chunk rendering GL error.");
          }
        }
        else {
          PVector[][] temp = new PVector[CHUNK_SIZE+1][CHUNK_SIZE+1];
          for (int y = 0; y < CHUNK_SIZE+1; y++) {
             for (int x = 0; x < CHUNK_SIZE+1; x++) {
                float xx = float(x+chunkX*CHUNK_SIZE);
                float yy = float(y+chunkY*CHUNK_SIZE);
                temp[y][x] = calcTile(xx-1., yy-1.);
            }
          }
          
          scene.textureWrap(REPEAT);
          scene.beginShape(QUAD);
          scene.textureMode(NORMAL);
          // TODO: add code ready for custom tile textures.
          scene.texture(img_grass.get());
          for (int y = 0; y < CHUNK_SIZE; y++) {
            for (int x = 0; x < CHUNK_SIZE; x++) {
              scene.vertex(temp[y][x].x,     temp[y][x].y,     temp[y][x].z, 0, 0);                                    
              scene.vertex(temp[y][x+1].x,   temp[y][x+1].y,   temp[y][x+1].z, 1.0, 0);  
              scene.vertex(temp[y+1][x+1].x, temp[y+1][x+1].y, temp[y+1][x+1].z, 1.0, 1.0);  
              scene.vertex(temp[y+1][x].x,   temp[y+1][x].y,   temp[y+1][x].z, 0, 1.0);
            }
          }
          scene.endShape();
        }
      }
      
      // For "testing" purposes
      public void doThing() {
        tiles[int(random(0, 9))][int(random(0, 9))].y = random(-1000, 1000);
        updatePShape();
      }


      public void regenerateTerrainObj() {
        // Terrain (ground)
        for (int y = 0; y < CHUNK_SIZE+1; y++) {
          for (int x = 0; x < CHUNK_SIZE+1; x++) {
            float xx = float(x+chunkX*CHUNK_SIZE);
            float yy = float(y+chunkY*CHUNK_SIZE);
            
            terrain.genTerrainObj(xx-1., yy-1.);
          }
        }
      }
      
      //public void setTile(int tilex, int tiley, float[] val) {
      //  vhi[tilex%CHUNK_SIZE][tiley%CHUNK_SIZE] = val;
      //}
    }
    
    
    
    
    
    
    
    
    // --- Define our PR objects. ---
    class TerrainPRObject extends PRObject {
      // Randseed is only used in version 1.x.
      private float randSeed = 0.;
      
      // Modern version 2.0.
      private int imgIndex = 0;
      
      public TerrainPRObject() {
        super();
        this.img = img_tree;
        // Small hitbox
        this.hitboxWi = wi*0.25;
        readjustSize();
      }
      
      public TerrainPRObject(float x, float y, float z, float size, String id) {
        super(x, y, z);
        this.img = img_tree;
        this.size = size;
        readjustSize();
        if (legacy_autogenStuff != null)
          legacy_autogenStuff.add(id);
        randSeed = x+y+z;
        
        // Small hitbox
        this.hitboxWi = wi*0.25;
      }
      
      public TerrainPRObject(float x, float y, float z, float size) {
        super(x, y, z);
        this.img = img_tree;
        this.size = size;
        readjustSize();
        randSeed = x+y+z;
        
        // Our RealmImage class allows us to go as high as we want :)
        imgIndex = int(random(0, 9));
        
        // Small hitbox
        this.hitboxWi = wi*0.25;
      }
      
      public void readjustSize() {
        // Set the size in case there's a realm refresh.
        if (versionCompatibility == 1) {
          this.wi = img.getRandom(randSeed).width*size;
          this.hi = img.getRandom(randSeed).height*size;
        }
        else if (versionCompatibility == 2) {
          this.wi = img.get(imgIndex).width*size;
          this.hi = img.get(imgIndex).height*size;
        }
      }
      
      public void display() {
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
        
        readjustSize();
        
        if (versionCompatibility == 1) {
          displayQuad(img.getRandom(randSeed), x1, y1, z1, x2, y1+hi, z2);
        }
        if (versionCompatibility == 2) {
          useFadeShader();
          displayQuad(img.get(imgIndex), x1, y1, z1, x2, y1+hi, z2);
        }
      }
      
      public JSONObject save() {
        JSONObject PRObject = new JSONObject();
        PRObject.setString("filename", ".pixelrealm-tree-"+str(imgIndex));
        PRObject.setFloat("x", this.x);
        PRObject.setFloat("y", this.y);
        PRObject.setFloat("z", this.z);
        PRObject.setFloat("scale", this.size);
        readjustSize();
        return PRObject;
      }
      
      
  
      public void load(JSONObject json) {
        // Every 3d object has x y z position.
        this.x = json.getFloat("x", this.x);
        this.z = json.getFloat("z", this.z);
        this.size = json.getFloat("scale", 1.);
  
        float yy = onSurface(this.x, this.z);
        this.y = json.getFloat("y", yy);

        
        String name = json.getString("filename");     
        if (!name.substring(0, 17).equals(".pixelrealm-tree-")) {
          console.bugWarn("Terrain abstract object must be named \".pixelrealm-tree-\"");
          return;
        }
        
        //console.log(".pixelrealm-tree-"+int(name.charAt(17)-48));
        imgIndex = int(name.charAt(17)-48);
        
        // If the object is below the ground, reset its position.
        if (y > yy+5.) this.y = yy;
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
        // Y-value will be automatically adjusted later.
        //this.y = onSurface(this.x, this.z);
        setFileNameAndIcon(dir);
      }
  
      public void setFileNameAndIcon(String dir) {
        dir = dir.replace('\\', '/');
        this.dir = dir;
        this.filename = file.getFilename(dir);
        display.systemImages.get(file.extIcon(this.filename));
      }
  
      public void display() {
        if (versionCompatibility == 2) {
          useFadeShader();
        }
        displayBillboard();
      }
      
      public void run() {
        
      }
      
      public void interationAction() {
        file.open(dir);
      }
      
      public void load(JSONObject json) {
        this.fileLoad(json);
      }
      
      public void fileLoad(JSONObject json) {
        // We expect the engine to have already loaded a JSON object.
        // Every 3d object has x y z position.
        
        // Prepare random (but close by to player) positioning if file previously did not exist
        // in realm.
        this.x = lastPlacedPosX+random(-500, 500);
        this.z = lastPlacedPosZ+random(-500, 500);
        if (json.isNull("x") || json.isNull("z")) {
          // Update last placed pos, but while we're here, we can
          // check to see if this fileObject happens to be the exitportal.
          // If so its position should be the exitportal position that was 
          // randomly allocated
          lastPlacedPosX = this.x;
          lastPlacedPosZ = this.z;
          
          // Expensive operation so let's do it here.
          // Check if object is within bounds. 
          // (if you're wondering, objects are loaded AFTER chunks are loaded)
          // If not, reposition to somewhere that hopefully is within bounds.
          // TODO: split it through multiple frames if we have loads of files
          // to avoid stutter.
          int count = 0;
          while (outOfBounds(this.x, this.z)) {
            this.x = random(-10000, 10000);
            this.z = random(-10000, 10000);
            count++;
            if (count > 1000) {
              console.warn("Couldn't relocate item cus we ain't smart enough.");
              break;
            }
          }
          surface();
          
          if (this == exitPortal) {
            this.x = exitPortalX;
            this.z = exitPortalZ;
          }
        }
        
        this.x = json.getFloat("x", this.x);
        this.z = json.getFloat("z", this.z);
        this.size = json.getFloat("scale", 1.)*BACKWARD_COMPAT_SCALE;
        
        // Update lastPlacedPos so that initing items can be placed near the portal.
        // In case you're wondering "what if unloaded items are init'd BEFORE the portal?"
        // Well 
        // case A. Portal already has data. Remember init items are init'd AFTER items with data.
        // case B. Portal needs to be init.  lastPlacedPos is set automatically in openDir and the
        // code below only updates lastPlacedPos if exitportal already has data, so no need to worry
        // about this.
        // 
        // Confused? Trust me bro it works.
        if (!json.isNull("x") && !json.isNull("z")) {
          lastPlacedPosX = this.x;
          lastPlacedPosZ = this.z;
        }
  
        float yy = onSurface(this.x, this.z);
        this.y = json.getFloat("y", yy);
        
        //console.log("x: "+x+" y: "+y+" z: "+z);
  
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
        addRequestToQueue(path, -1);
      }
      
      
      public void addRequestToQueue(final String path, final int shrink) {
        this.beginLoadFlag.set(false);
        loadQueue.add(this.beginLoadFlag);
        final boolean isImg = this instanceof ImageFileObject || this instanceof EntryFileObject;
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
            
            // Ram usage. When loading, we don't want to exceed the limit.
            // Depends on our RAM settings.
            long maxRam = TWEngine.MAX_RAM_NORMAL;
            if (engine.lowMemory) {
              maxRam = TWEngine.MAX_RAM_LIMITED;
            }
            int maxRamKB = (int)(maxRam/1024L);
            
            // Don't want garbage to cause an OutOfMemoryException.
            // So if we reach the max limit, stall and beg the garbage collector to free up some memory.
            // Only do it so many times before giving up.
            int count = 0;
            while (engine.getUsedMemKB() > maxRamKB) {
              count++;
              // Randomness since threads might give up at the same time and end up overloading the memory all at once.
              if (count > (int)random(10, 25)) {
                // Give up.
                break;
              }
              
              //console.log("Garbage collector beg "+maxRamKB+ " "+engine.getUsedMemKB());
              System.gc();
              try {
                Thread.sleep(100);
              }
              catch (InterruptedException e) {
                // we don't care.
              }
               
            }
            
            // First, we need to see if we have enough space to store stuff.
            long size = (long)file.getImageUncompressedSize(path);
            //long size = 512l*512l*4l;
            
            
            //console.info(filename+" size: "+(size/1024)+" kb");
            // Tbh doesn't need to be specifically thread safe, it's all an
            // approximation.
            if (memUsage.get()+size > MAX_MEM_USAGE) {
              //if (!memExceeded) 
              //console.warn("Maximum allowed memory exceeded, some items/files may be missing from this realm.");
              //memExceeded = true;
              //console.warn("Maximum allowed memory exceeded, some items/files may be missing from this realm.");
              
              //console.info(filename+" exceeds the maximum allowed memory.");
              memOverload = true;
            }
            else {
              incrementMemUsage(512*512*4);
              String ext = file.getExt(path);
              
              if (ext.equals("gif")) {
                //Gif newGif = new Gif(app, path);
                //newGif.loop();
                //img = new RealmTexture();
                //img.setLarge(newGif);
              }
              
              // TODO: idk error check here
              else {
                PImage im = display.errorImg;
                // TODO: this is NOT thread-safe here!
                if (ext.equals(engine.ENTRY_EXTENSION)) {
                  im = engine.tryLoadImageCache(path, new Runnable() {
                    public void run() {
                      ((EntryFileObject)me).loadFromSource();
                    }
                  }
                  );
                  if (im != null) {
                    img = new RealmTexture(im);
                  }
                }
                else if (ext.equals("pdf")) {
                  im = engine.pdftopng(path);
                  if (im != null) {
                    img = new RealmTexture(im);
                  }
                }
                else if ((ext.equals("mp4")
                  || ext.equals("m4v")
                  || ext.equals("mov"))) {
                  
                }
                else {
                  im = engine.tryLoadImageCache(path, new Runnable() {
                    public void run() {
                      PImage im2 = loadImage(path);
                      if (shrink != -1) {
                        engine.scaleDown(im2, shrink);
                      }
                      engine.setOriginalImage(im2);
                      if (isImg)
                        ((ImageFileObject)me).cacheFlag = true;
                      
                      System.gc();
                    }
                  }
                  );
                  img = new RealmTexture(im);
                  
                }
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
        super.fileLoad(json);
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
        display.recordRendererTime();
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
        display.recordLogicTime();
      }
      
      public void scaleUp(float amount) {
        setSize(size+amount*BACKWARD_COMPAT_SCALE);
      }
      
      public void scaleDown(float amount) {
        setSize(size-amount*BACKWARD_COMPAT_SCALE);
      }
    }
    
    
    
    
    
    
    class MusicFileObject extends FileObject {
      
      // TODO: scale each axis...?
      public float rotX = 0.;
      public float rotY = 0.;
      public float rotZ = 0.;
      
      
      public MusicFileObject(float x, float y, float z, String dir) {
        super(x, y, z, dir);
      }
  
      public MusicFileObject(String dir) {
        super(dir);
      }
      
      {
        
        this.wi = 300;
        this.hi = 300;
        this.size = 1f;
      }
      
      public void load(JSONObject json) {
        super.fileLoad(json);
      }
      
      
      public void interationAction() {
        sound.stopMusic();
        sound.streamMusic(this.dir);
        cassettePlaying = this.filename;
        console.log("Now playing "+this.filename);
      }
      
      
      public void setSize(float size) {
        this.size = size;
      }
      
      public void display() {
        
        final float SIZE = 50f;
        
        super.display();
        
        boolean dontRender = false;
        float dist = PApplet.pow((playerX-x), 2)+PApplet.pow((playerZ-z), 2);
        if (versionCompatibility == 1) {
          if (dist > terrain.FADE_DIST_OBJECTS) {
            float fade = calculateFade(dist, terrain.FADE_DIST_OBJECTS);
            if (fade > 1) {
              scene.tint(tint, fade);
              scene.fill(tint, fade);
            } else {
              dontRender = true;
            }
          } else {
            scene.tint(tint, 255);
            scene.fill(tint, 255);
          }
        }
        else if (versionCompatibility == 2) {
          float x = playerX-this.x;
          float z = playerZ-this.z;
          if (x*x+z*z > terrain.FADE_DIST_OBJECTS) {
            dontRender = true;
          }
          scene.fill(tint, 255);
        }
        
        if (!dontRender) {
          display.recordRendererTime();
          scene.pushMatrix();
          scene.translate(this.x, this.y, this.z);
          scene.scale(-SIZE);
          //scene.rotateX(rotX);
          
          scene.rotateY(rotY);
          //scene.rotateZ(rotZ);
          scene.shape(CASSETTE_OBJ);
          scene.popMatrix();
          display.recordLogicTime();
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
  
        display.recordRendererTime();
        
        scene.pushMatrix();
        scene.translate(x, y-hi-20, z);
        scene.rotateY(d);
        scene.textFont(engine.DEFAULT_FONT, 16);
        scene.textAlign(CENTER, CENTER);
        scene.fill(255);
        scene.text(filename, 0, 0, 0);
        scene.popMatrix();
        
        display.recordLogicTime();
  
        displayBillboard();
      }
    }
    
    class EntryFileObject extends ImageFileObject {
      private Editor renderedEntry = null;
      private PGraphics mycanvas = null;
      private boolean loadFromSource = false;
      
      public EntryFileObject(float x, float y, float z, String dir) {
        super(x, y, z, dir);
        setup();
      }
  
      public EntryFileObject(String dir) {
        super(dir);
        setup();
      }
      
      public EntryFileObject(String dir, boolean newFile) {
        super(dir);
        setup();
        if (newFile) {
          loadFlag = true;
          
          display.uploadAllAtOnce(true);
          if (power.powerMode != PowerMode.MINIMAL) scene.endDraw();
            
          display.setPGraphics(mycanvas);
          mycanvas.beginDraw();
          mycanvas.background(0xFF0f0f0e);
          mycanvas.endDraw();
          display.setPGraphics(g);
          if (power.powerMode != PowerMode.MINIMAL) scene.beginDraw();
          img = new RealmTexture(mycanvas);
          display.uploadAllAtOnce(false);
          setSize(0.5);
        }
      }
      
      private void setup() {
        allowTexFlipping = true;
        mycanvas = createGraphics(480, 270, P2D);
      }
      
      public void load(JSONObject json) {
        super.load(json);
      }
      
      // Yeah I'm getting too lazy now.
      public void loadNonConcurrent() {
        // Basically:
        // Run our "does this cache exist?" function.
        
        engine.tryLoadImageCache(dir, new Runnable() {
          // Here, we gotta generate cache.
          // Pretty easy in hindsight.
          public void run() {
            renderedEntry = new ReadOnlyEditor(engine, dir, mycanvas, false);
            loadFromSource = true;
          }
        });
        
      }
      
      public void loadFromSource() {
        entriesTotal++;
        renderedEntry = new ReadOnlyEditor(engine, dir, mycanvas, true);
        loadFromSource = true;
      }
      
      public void display() {
        super.display();
      }
      
      public void run() {
        super.run();
        
        if (loadFromSource && drawEntryOnce) {
          // Wait until the entry has been loaded in the seperate thread.
          if (renderedEntry != null && mycanvas != null && renderedEntry.isLoaded()) {
            // Now this is the cringy bit: stop rendering to the main scene (bad for opengl performance
            // but this is a load so it doesn't matter that much), quickly render our entry, then go back
            // to rendering to the main scene. Remember this all runs on the main thread.
            display.uploadAllAtOnce(true);
            if (power.powerMode != PowerMode.MINIMAL) scene.endDraw();
            display.setPGraphics(mycanvas);
            mycanvas.beginDraw();
            mycanvas.background(renderedEntry.BACKGROUND_COLOR);
            input.scrollOffset = -renderedEntry.UPPER_BAR_DROP_WEIGHT;
            renderedEntry.renderPlaceables();
            
            // This can have bad consiquences sometimes by random chance
            try {
              mycanvas.endDraw();
            }
            catch (RuntimeException e) {
              console.warn("Entry rendering error, continuing.");
            }
            
            display.setPGraphics(g);
            if (power.powerMode != PowerMode.MINIMAL) scene.beginDraw();
            img = new RealmTexture(mycanvas);
            display.uploadAllAtOnce(false);
            setSize(0.5);
            
            // Don't care about these two anymore
            mycanvas = null;
            renderedEntry.free();
            renderedEntry = null;
            loadFromSource = false;
            drawEntryOnce = false;
            engine.saveCacheImage(this.dir, img.get());
            drawnEntries++;
          }
        }
      }
    }
  
    class ImageFileObject extends FileObject {
      public float rot = 0.;
  
  
      public boolean loadFlag = false;
      public boolean cacheFlag = false;
      public boolean allowTexFlipping = false;
      
  
  
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
                  engine.saveCacheImage(this.dir, img.get());
                  cacheFlag = false;
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
              
              // TODO: cache and optimise
              float sin_d = sin(rot)*(hwi);
              float cos_d = cos(rot)*(hwi);
              float x1 = x + sin_d;
              float z1 = z + cos_d;
              float x2 = x - sin_d;
              float z2 = z - cos_d;
              
              if (allowTexFlipping) {
                float sin_dd = sin(rot+HALF_PI)*(hwi);
                float cos_dd = cos(rot+HALF_PI)*(hwi);
                float dx1 = playerX - (x + sin_dd);
                float dz1 = playerZ - (z + cos_dd);
                float dx2 = playerX - (x - sin_dd);
                float dz2 = playerZ - (z - cos_dd);
                flippedTexture = (abs(dx1*dx1+dz1*dz1) < abs(dx2*dx2+dz2*dz2));
              }
               
              app.fill(tint);
              displayQuad(this.img.get(), x1, y1, z1, x2, y1+hi, z2);
              
              
              // TODO: Obviously optimise...
              scene.resetShader();
            }
          }
        }
        // Reset tint
        this.tint = color(255);
      }
      
      public void load(JSONObject json) {
        super.fileLoad(json);
  
        this.rot = json.getFloat("rot", random(-PI, PI));
        
        
        // Depends on our image format:
        if (file.getExt(this.filename).equals("gif") && showExperimentalGifs) cacheFlag = false;
          
        addRequestToQueue(dir, MAX_CACHE_SIZE);
      }
      
      // Same as load, except we do NOT call addRequestToQueue(dir, MAX_CACHE_SIZE) and instead copy the multithreaded code
      // and run it in the main thread.
      public void loadNonConcurrent() {
        
        // Annnnnd yeah let's just save the cache immediately.
        // To be honest we should probably assign the result to img, but
        // let's be real: right now we're only ever using this for background caching.
        // If for whatever reason you need to load displayable images into the main thread,
        // well it's future me's problem to deal with.
        // Except I wrote a comment here explaining what exactly you're supposed to do in the
        // event that you need to load images in the main thread so you're welcome I guess.
        engine.tryLoadImageCache(dir, new Runnable() {
          public void run() {
            PImage im2 = loadImage(dir);
            engine.scaleDown(im2, MAX_CACHE_SIZE);
            engine.setOriginalImage(im2);
            engine.setCachingShrink(MAX_CACHE_SIZE, 0);
            engine.saveCacheImage(dir, im2);
          }
        }
        );
      }
  
      public JSONObject save() {
        JSONObject PRObject = super.save();
        PRObject.setFloat("rot", this.rot);
        return PRObject;
      }
    }
    
  
  
  
  
  
    private int totalVideosLoaded = 0;
  
    class VideoFileObject extends ImageFileObject {
      private boolean movieEnabled = false;
      
      public VideoFileObject(float x, float y, float z, String dir) {
        super(x, y, z, dir);
      }
  
      public VideoFileObject(String dir) {
        super(dir);
      }
      
      public void load(JSONObject json) {
        super.fileLoad(json);
  
        this.rot = json.getFloat("rot", random(-PI, PI));
        
        Movie video = new Movie(app, dir);
        video.volume(0f);
        
        // Determine if the video should load or not.
        if (
          (video.sourceWidth <= 512 || video.sourceHeight <= 512) &&  // Small enough to play without much lag, even if one dimension isn't stupidly big.
          (video.sourceWidth < 1536 && video.sourceHeight < 1536) && // Avoid weird ass files that were probably designed to throw off Timeway and make it crash.
          (totalVideosLoaded < MAX_VIDEOS_ALLOWED)) 
        {
          this.img = new RealmTexture(video);
          //this.img.getD().pimage = video;
          movieEnabled = true;
        }
        else {
          this.img = new RealmTexture(display.systemImages.get("video_nothumb"));
          movieEnabled = false;
        }
        totalVideosLoaded++;
      }
      
      public void display() {
        if (visible) {
          // Extra code for the big movies
          if (!movieEnabled) {
            super.display();
            return;
          }
          
          if (this.img != null) {
              
              //setSize(1.);
              
              if (this.img.get() instanceof Movie) {
                Movie video = (Movie)this.img.get();
                if (!video.isPlaying()) {
                  video.loop();
                  video.volume(0f);
                }
                if (video.available()) {
                  video.read(); 
                }
                this.wi = (float)video.sourceWidth*size;
                this.hi = (float)video.sourceHeight*size;
              }
              
              float y1 = y-hi;
              // There's no y2 huehue.
              
              
              // Half width
              float hwi = wi/2;
              
              // TODO: cache and optimise
              float sin_d = sin(rot)*(hwi);
              float cos_d = cos(rot)*(hwi);
              float x1 = x + sin_d;
              float z1 = z + cos_d;
              float x2 = x - sin_d;
              float z2 = z - cos_d;
              
              
              displayQuad(this.img.get(), x1, y1, z1, x2, y1+hi, z2);
          }
        }
        // Reset tint
        this.tint = color(255);
      }
      
      
      public void finalize() {
        // Loads of obsessive checks
        if (this.img != null
        &&  this.img.get() != null
        &&  this.img.get() != null
        &&  this.img.get() instanceof Movie)
        {
          // Stop the hidden video
          ((Movie)this.img.get()).stop();
        }
      }
    }
    
    
    
    
    
    
    
    
    
    
    
    public String createShortcut() {
      String dir = stateDirectory;
      // Create a shortcut with a unique name.
      
      // SHORTCUT_EXTENSION[0] is the latest shortcut version.
      String folderName = file.getFilename(dir);
      String shortcutName = folderName+"."+engine.SHORTCUT_EXTENSION;
      String shortcutPath = dir+shortcutName;
      shortcutPath.replaceAll("\\\\", "/");
      
      // If it already exists select another name until we find one that hasn't been taken.
      File f = new File(shortcutPath);
      int i = 1;
      while (f.exists()) {
        shortcutName = file.getFilename(dir)+"-"+str(i++)+"."+engine.SHORTCUT_EXTENSION;
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
      stats.increase("shortcuts_created", 1);
      
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
      
      public JSONObject save() {
        // Imagine we move a shortcut into a different dir.
        // Suddenly, the relative path will be incorrect.
        // So we need to update it each time to ensure it's correct.
      
        if (file.exists(this.dir)) {
          JSONObject sh = app.loadJSONObject(this.dir);
          String relative = file.getRelativeDir(stateDirectory, shortcutDir);
          sh.setString("relative_dir", relative);
          app.saveJSONObject(sh, this.dir);
        }
        
        // We actually return an entirely different json so ignore this line lmaoao
        return super.save();
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
            
            boolean exists = false;
            // Check shortcut exists.
            if (!file.exists(shortcutDir)) {
              //console.warn("Shortcut to "+file.getFilename(this.filename)+" doesn't exist!");
              
              // If not, try to get the relative path
              if (!sh.isNull("relative_dir")) {
                shortcutDir = file.relativeToAbsolute(file.getDir(this.dir), sh.getString("relative_dir"));
                if (file.exists(shortcutDir)) {
                  // If found, update shortcut's path
                  sh.setString("shortcut_dir", shortcutDir);
                  app.saveJSONObject(sh, this.dir);
                  exists = true;
                }
                else {
                  //console.log("Couldn't find relative dir: "+shortcutDir);
                }
              }
              // If we can't get anything that's fine, just means we will be bump'd back when
              // we try to enter the portal
            }
            else exists = true;
            
            shortcutName = sh.getString("shortcut_name", "[corrupted]");
            
            // Yup, shortcut_name is unnecessary. But hey might as well self-fix if broken.
            if (shortcutName.equals("[corrupted]")) {
              shortcutName = file.getFilename(shortcutDir);
            }
            
            if (exists) {
              // If at this point we should have the shortcut dir.
              requestRealmSky(shortcutDir);
              
              // Speaking of self-fix, old shortcuts won't have relative_dir. Let's calculate a relative_dir if it don't exist already.
              String relative = file.getRelativeDir(file.getDir(this.dir), shortcutDir);
              sh.setString("relative_dir", relative);
              app.saveJSONObject(sh, this.dir);
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
        if (dist < MIN_PORTAL_LIGHT_THRESHOLD && !movementPaused) {
          // If close to the portal, set the portal light to create a portal enter/transistion effect.
          portalLight = max(portalLight, (1.-(dist/MIN_PORTAL_LIGHT_THRESHOLD))*255.);
        }
        
        // Entering the portal.
        if (touchingPlayer() && portalCoolDown < 1.) {
          if (!usePortalAllowed) {
            console.log("You can't go here just yet!");
            bumpBack();
            return;
          }
          
          if (!file.exists(this.shortcutDir)) {
            console.log("Shortcut to "+this.shortcutDir+" doesn't exist!");
            bumpBack();
            return;
          }
          
          sound.playSound("shift");
          //prevRealm = currRealm;
          stats.increase("shortcut_portals_entered", 1);
          gotoRealm(this.shortcutDir);
        }
      }
      
      
      public void interationAction() {
        file.open(this.shortcutDir);
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
        setupSelf();
      }
  
      public DirectoryPortal(String dir) {
        super(dir);
        setupSelf();
      }
      
      private void setupSelf()
      {
        this.img = new RealmTexture(display.errorImg); 
        
        requestRealmSky(dir);
        
        this.wi = 128;
        this.hi = 128+96;
        
        // Set hitbox size to small
        this.hitboxWi = wi*0.5;
        if (legacy_portalEasteregg) setSize(0.8);
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
          //this.img = new RealmTexture(REALM_SKY_DEFAULT_LEGACY);
          this.img = new RealmTexture(display.errorImg);
        }
      }
      
      public void run() {
        // Screen glow effect.
        // Calculate distance to portal
        float dist = PApplet.pow(x-playerX, 2)+PApplet.pow(z-playerZ, 2);
        if (dist < MIN_PORTAL_LIGHT_THRESHOLD && !movementPaused) {
          // If close to the portal, set the portal light to create a portal enter/transistion effect.
          portalLight = max(portalLight, (1.-(dist/MIN_PORTAL_LIGHT_THRESHOLD))*255.);
        }
        
        // Entering the portal.
        if (touchingPlayer() && portalCoolDown < 1.) {
          if (!usePortalAllowed) {
            console.log("You can't go here just yet!");
            bumpBack();
            return;
          }
          
          sound.playSound("shift");
          // Perfectly optimised. Creating a new state instead of a new screen
          stats.increase("directory_portals_entered", 1);
          gotoRealm(this.dir, stateDirectory);
        }
      }
  
      public void display() {
        if (visible) {
          display.recordRendererTime();
          
          usingFadeShader = false;
          display.shader(scene, "portal_plus", "u_time", display.getTimeSecondsLoop(), "u_dir", -direction/(PI*2));
          
          scene.fill(this.tint);
          displayBillboard();
          if (versionCompatibility == 2) {
            useFadeShader();
          }
          else if (versionCompatibility == 1) {
            scene.resetShader();
          }
          
  
          // Display text over the portal showing the directory.
          float d = direction-PI;
          //float w = img.width*size;
          
          scene.pushMatrix();
          scene.translate(x, y-hi, z);
          scene.rotateY(d);
          scene.textSize(24);
          scene.textFont(engine.DEFAULT_FONT);
          scene.textAlign(CENTER, CENTER);
          scene.text(filename, 0, 0, 0);
          scene.popMatrix();
          
          
          display.recordLogicTime();
  
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
        this.img = IMG_COIN;
        setSize(0.25);
        this.hitboxWi = wi;
      }
      
      public void display() {
        super.display();
      }
      
      public void run() {
        if (touchingPlayer()) {
          coinCounterBounce = 1.;
          sound.playSound("coin");
          stats.increase("coins_collected", 1);
          collectedCoins++;
          if (collectedCoins % 100 == 0) {
            sound.playSound("oneup");
            stats.increase("oneups", 1);
          }
          this.destroy();
        }
      }
    }
    
    
    
    
    
    
    
    
  
    class PRObject {
      public int id;
      public float x;
      public float y;
      public float z;
      public RealmTexture img = null;
      protected float size = 1.;
      protected float wi = 0.;
      protected float hi = 0.;
      protected float hitboxWi;
      public boolean visible = true;         // Used for manual turning on/off visibility
      public color tint = color(255);
      protected ItemSlot<PRObject> myOrderingNode = null;
      protected boolean flippedTexture = false;
      
  
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
      
      public void surface() {
        y = onSurface(x, z);
      }
  
      public boolean touchingPlayer() {
        float spw = PLAYER_WIDTH*0.5;
        float sw = (hitboxWi*0.5)+spw;
        boolean left =   lineLine(prevPlayerX,prevPlayerZ,playerX,playerZ,    x-sw,z-sw,   x-sw,z+sw);
        boolean right =  lineLine(prevPlayerX,prevPlayerZ,playerX,playerZ,    x+sw,z-sw,   x+sw,z+sw);
        boolean top =    lineLine(prevPlayerX,prevPlayerZ,playerX,playerZ,    x-sw,z-sw,   x+sw,z-sw);
        boolean bottom = lineLine(prevPlayerX,prevPlayerZ,playerX,playerZ,    x-sw,z+sw,   x+sw,z+sw);
        
        boolean midFrameCollision = left || right || top || bottom;
        
        return (midFrameCollision)
          && (playerY-PLAYER_HEIGHT < (y)) 
          && (playerY > (y-hi));
      }
      
      public JSONObject save() {
        JSONObject PRObject = new JSONObject();
        PRObject.setFloat("x", this.x);
        PRObject.setFloat("y", this.y);
        PRObject.setFloat("z", this.z);
        PRObject.setFloat("scale", this.size/BACKWARD_COMPAT_SCALE);
        return PRObject;
      }
  
      public void load(JSONObject json) {
        // We expect the engine to have already loaded a JSON object.
        // Every 3d object has x y z position.
        this.x = json.getFloat("x", this.x);
        this.z = json.getFloat("z", this.z);
        this.size = json.getFloat("scale", 1.);
  
        float yy = onSurface(this.x, this.z);
        this.y = json.getFloat("y", yy);
        
        //console.log("x: "+x+" y: "+y+" z: "+z);
  
        // If the object is below the ground, reset its position.
        if (y > yy+5.) this.y = yy;
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
  
        float beamX2 = playerX+cache_playerSinDirection*SELECT_FAR;
        float beamZ2 = playerZ+cache_playerCosDirection*SELECT_FAR;
  
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
          if (currentTool == TOOL_GRABBER) {
            this.tint = color(255, 200, 200);
          }
          return true;
        } else {
          return false;
        }
      }
      
      public void interationAction() {
        
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
        this.wi = img.width*size;
        this.hi = img.height*size;
      }
      
      public void run() {
        // By default nothing.
      }
  
      public void display() {
        if (versionCompatibility == 2) {
          useFadeShader();
        }
        displayBillboard();
      }
      
      
      
      protected void displayBillboard() {
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
  
          displayQuad(this.img.get(), x1, y1, z1, x2, y1+hi, z2);
  
          // Reset tint
          this.tint = color(255);
        }
      }
      
      protected void displayQuad(PImage im, float x1, float y1, float z1, float x2, float y2, float z2) {
        // An exception is known to happen here
        if (im == null) return;
        
        //boolean selected = lineLine(x1,z1,x2,z2,beamX1,beamZ1,beamX2,beamZ2);
        //color selectedColor = color(255);
        //if (hovering()) {
        //  selectedColor = color(255, 127, 127);
        //}
  
        boolean useFinder = false;
        useFinder &= finderEnabled;
  
        //Now render the image in 3D!!!
  
        //Add some fog for objects as they get further away.
        //Note that if the transparacy is 100%, the object will not be rendered at all.
        float dist = PApplet.pow((playerX-x), 2)+PApplet.pow((playerZ-z), 2);
  
        boolean dontRender = false;
        
        // Only for versions 1.0 and 1.1 since 2.0 has completely different fading mechanics.
        if (versionCompatibility == 1) {
          if (dist > terrain.FADE_DIST_OBJECTS) {
            float fade = calculateFade(dist, terrain.FADE_DIST_OBJECTS);
            if (fade > 1) {
              scene.tint(tint, fade);
              scene.fill(tint, fade);
            } else {
              dontRender = true;
            }
          } else {
            scene.tint(tint, 255);
            scene.fill(tint, 255);
          }
        }
        else if (versionCompatibility == 2) {
          float x = playerX-this.x;
          float z = playerZ-this.z;
          if (x*x+z*z > terrain.FADE_DIST_OBJECTS) {
            dontRender = true;
          }
          scene.fill(tint, 255);
        }
    
        if (useFinder) {
          scene.stroke(255, 127, 127);
          scene.strokeWeight(2.);
          //scene.fill(255);
        } else {
          scene.noStroke();
        }
        
        display.recordRendererTime();
        if (!dontRender || useFinder) {
          scene.pushMatrix();
  
  
          scene.beginShape();
          float uvx = 0.999f;
          float uvy = 0f;
          float uvxx = 0f;
          float uvyy = 0.999f;
          if (!dontRender) {
            scene.textureMode(NORMAL);
            scene.textureWrap(REPEAT);
            
            scene.texture(im);
          }
          
          if (flippedTexture) {
            float tmp = uvx;
            uvx = uvxx;
            uvxx = tmp;
          }
          
          
          scene.vertex(x1, y1, z1, uvx, uvy);           // Bottom left
          scene.vertex(x2, y1, z2, uvxx, uvy);    // Bottom right
          scene.vertex(x2, y2, z2, uvxx, uvyy); // Top right
          scene.vertex(x1, y2, z1, uvx, uvyy);  // Top left
          if (useFinder) scene.vertex(x1, y1, z1, 0, 0);  // Extra vertex to render a complete square if finder is enabled.
          // Not necessary if just rendering the quad without the line.
          scene.noTint();
          scene.fill(255);
          scene.endShape();
  
          scene.popMatrix();
        }
        display.recordLogicTime();
      }
    }
    // End PRObject classes.
    
    
    
    // --- State-dependant functions that our realm (And PRObjects) use ---
    boolean onGround() {
      return (playerY >= onSurface(playerX, playerZ)-1.);
    }
    
    private boolean outOfBounds(float x, float z) {
      if (terrain == null) return false;
      float tilex = floor(x/terrain.groundSize)+1.;
      float tilez = floor(z/terrain.groundSize)+1.;
      
      if (version.equals("2.0")) {
        return (
          int(tilex)/CHUNK_SIZE > terrain.chunkLimitX ||
          int(tilex)/CHUNK_SIZE < -terrain.chunkLimitX+1 ||
          int(tilez)/CHUNK_SIZE > terrain.chunkLimitZ ||
          int(tilez)/CHUNK_SIZE < -terrain.chunkLimitZ+1
        );
      }
      else if (version.equals("2.1")) {
        // In 2.1:
        // One less chunk in chunklimit
        // One less tile on the edge in the positive range so that it's easier to fix bugs with the
        // morpher tool
        TerrainChunkV2 ch = getChunkAt(x, z);
        if (ch == null) {
          // NOTE: I guess it's just easier to check out of bounds
          // if the chunk is null
          return true;
        }
        
        return (
          int(tilex)/CHUNK_SIZE > terrain.chunkLimitX-1 ||
          int(tilex)/CHUNK_SIZE < -terrain.chunkLimitX+1 ||
          int(tilez)/CHUNK_SIZE > terrain.chunkLimitZ-1 ||
          int(tilez)/CHUNK_SIZE < -terrain.chunkLimitZ+1
        );
      }
      else return false;
    }
    
    private float onSurface(float x, float z) {
      if (terrain == null) {
        //console.bugWarn("onSurface() needs the terrain to be loaded before it's called!");
        return 0.;
      }
      if (outOfBounds(x,z)) {
        return 999999;
      }
      float tilex = floor(x/terrain.groundSize)+1.;
      float tilez = floor(z/terrain.groundSize)+1.;
      PVector pv1 = calcTile(tilex-1, tilez-1);          // Left, top
      PVector pv2 = calcTile(tilex, tilez-1);          // Right, top
      PVector pv3 = calcTile(tilex, tilez);          // Right, bottom
      PVector pv4 = calcTile(tilex-1, tilez);          // Left, bottom
      
      return getplayerYOnQuad(pv1, pv2, pv3, pv4, x, z);
    }
    
    // Similar to plantDown but guarentees than the object in question will not be levitating on a sloped surface.
    //private float plantDown(float x, float z) {
    //  if (terrain == null) {
    //    //console.bugWarn("onSurface() needs the terrain to be loaded before it's called!");
    //    return 0.;
    //  }
    //  if (outOfBounds(x,z)) {
    //    return 999999;
    //  }
    //  float tilex = floor(x/terrain.groundSize)+1.;
    //  float tilez = floor(z/terrain.groundSize)+1.;
      
    //  float lowest = -999999; // Very high in the sky, we want the lowest in the ground.
    //  lowest = max(calcTileY(tilex-1., tilez-1.), lowest);          // Left, top
    //  lowest = max(calcTileY(tilex, tilez-1.), lowest);          // Right, top
    //  lowest = max(calcTileY(tilex, tilez), lowest);          // Right, bottom
    //  lowest = max(calcTileY(tilex-1., tilez), lowest);          // Left, bottom
    //  return lowest;
    //}
    
    
  
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
    
    private PVector calcTile(float x, float z) {
      PVector v = calcTileXZ(x,z);
      v.y = calcTileY(x,z);
      return v;
    }
    
    private PVector calcTileXZ(float x, float z) {
      PVector v = terrain.getPointXZ(x,z);
      v.y = calcTileY(x,z);
      return v;
    }
    
    
    //private float calcTileY(float x, float z) {
    //  return calcTileY(x, z, false);
    //}
    
    private int[] getTileIndicies(float x, float z) {
      int tilex = 0;
      int tilez = 0;
      if (x >= 0) {
        tilex = (int(x+1)%(CHUNK_SIZE));
      }
      else {
        tilex = CHUNK_SIZE-abs(int(x+1)%(CHUNK_SIZE));
      }
      
      if (z >= 0) {
        tilez = (int(z+1)%(CHUNK_SIZE));
      }
      else {
        tilez = CHUNK_SIZE-abs(int(z+1)%(CHUNK_SIZE));
      }
      
      int[] ret = new int[2];
      ret[0] = abs(tilex);
      ret[1] = abs(tilez);
      
      return ret;
    }
    
    private TerrainChunkV2 getChunkAt(float x, float z) {
      if (terrain == null) return null;
      float tilex = floor(x/terrain.groundSize)+1.;
      float tilez = floor(z/terrain.groundSize)+1.;
      return getChunkUsingIndices(tilex, tilez);
    }
    
    private TerrainChunkV2 getChunkUsingIndices(float x, float z) {
      int chunkx = int((x+1)/float(CHUNK_SIZE)) - (x < 0 ? 1 : 0);
      int chunkz = int((z+1)/float(CHUNK_SIZE)) - (z < 0 ? 1 : 0);
      return getChunk(chunkx, chunkz);
    }
    
    // In chunk coords here.
    private TerrainChunkV2 getChunk(int chunkx, int chunkz) {
      int hashIndex = (MAX_CHUNKS_XZ)*chunkz + chunkx;
      return chunks.get(hashIndex);
    }
    
    private PVector getTileAt(float x, float z) {
      float tilex = floor(x/terrain.groundSize)+1.;
      float tilez = floor(z/terrain.groundSize)+1.;
      
      return getTileUsingIndicies(tilex, tilez);
    }
    
    boolean debug = false;
    private PVector getTileUsingIndicies(float x, float z) {
      if (versionCompatibility == 1) {
        console.bugWarn("getTileAt: Not compatible in realms with v1.x");
        return new PVector(0,0,0);
      }
      TerrainChunkV2 ch = getChunkUsingIndices(x, z);
      
      
      int[] indicies = getTileIndicies(x, z);
      
      if (ch != null) {
        
        //if (debug) {
        //  console.log("B "+indicies[0]+" "+indicies[1]);
        //  console.log("A "+int(x)+" "+int(z));
        //}
        
        // Due to a bug where tiles that are in between terrain won't link to each other,
        // we need to exclusively tell the tiles to link to each other when accessing it.
        // Kinda a kerfuffle since the chunk we need might not exist so let's just hope
        // for the best.
        if (int(x)%8 == 0) {
          TerrainChunkV2 neighbour = getChunk(ch.chunkX-1, ch.chunkY);
          if (neighbour != null) 
            ch.tiles[indicies[1]][0] = neighbour.tiles[indicies[1]][8];
        }
        if (int(z)%8 == 0) {
          TerrainChunkV2 neighbour = getChunk(ch.chunkX, ch.chunkY-1);
          if (neighbour != null) 
            ch.tiles[0][indicies[0]] = neighbour.tiles[8][indicies[0]];
        }
        
        return ch.tiles[indicies[1]][indicies[0]];
      }
      else {
        // Our code should know what to expect
        return new PVector(x, terrain.getPointY(x,z), z);
      }
    }
    
    int count = 0;
    
    int glowingchunk = 0;
    int glowingtilex = 0;
    int glowingtiley = 0;
    private float calcTileY(float x, float z) {
      
      
      if (versionCompatibility == 1) return terrain.getPointY(x,z);
      else {
        // Skip all that if we just wanna modify terrain
        if (modifyTerrain) return terrain.getPointY(x,z);
        
        PVector v = getTileUsingIndicies(x, z);
        
        return v.y;
        // return cached tile.
        //if (v != null) {
        //}
        //// If the chunk has not been cached or we want the terrain to change real-time...
        //else {
        //  return terrain.getPointY(x,z);
        //}
      }
    }
    
    protected ItemSlot<PocketItem> addToPockets(PRObject item) {
      String name = getHoldingName(item);
      // Anything that isn't *the* physical file is abstract.
      boolean abstractObject = false;
      
      // We absolutely do NOT want to move the exit portal!!
      if (item == exitPortal)
        abstractObject = true;
        
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
      promptPickedUpItem();  // This is for tutorial only
      
      globalHoldingObjectSlot = addToPockets(p);
      updateHoldingItem(globalHoldingObjectSlot);
      stats.increase("items_picked_up", 1);
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
      if (!loadMinimal)
        stats.increase("realms_loaded", 1);
      // Reset memory usage
      memUsage.set(0);
      // TODO: we should also prolly kill all active loading threads too somehow...
      
      // Get all files (creates the FileObject instances)
      openDir();
      
      // NOTE: Due to differing versions being sensitive to the ordering of loadRealmAssets(),
      // loadRealmAssets is called in loadRealmTerrain in order to prevent a bug. Unmaintainable, yes,
      // but hey we're choosing backward compatibility so it's a cost we gotta pay.
      
      // Read the JSON (load terrain information and position of these objects)
      loadRealmTerrain();
      
      if (terrain == null) terrain = new SinesinesineTerrain();
      
    }
    
    public void refreshFiles() {
      stats.increase("refreshes", 1);
      // Reset memory usage
      memUsage.set(0);
      files = new LinkedList<FileObject>();
      ordering = new LinkedList<PRObject>();
      
      // Reload everything!
      openDir();
      loadRealmTerrain();
      if (terrain == null) terrain = new SinesinesineTerrain();
    }
    
    public void refreshEverything() {
      issueRefresherCommand(REFRESHER_PAUSE);
      saveRealmJson();
      portalLight = 255;
      refreshFiles();
    }
    
    public FileObject createPRObjectAndPickup(String path) {
      if (!file.exists(path)) {
        console.bugWarn("createPRObjectAndPickup: "+path+"doesn't exist!");
      }
      FileObject o = createPRObject(path);
      files.add(o);
      pickupItem(o);
      currentTool = TOOL_GRABBER;
      return o;
    }
    
    public FileObject findFileObjectByName(String name) {
      for (FileObject f : files) {
        if (f != null) {
          if (f.filename.equals(name)) {
            return f;
          }
        }
      }
      return null;
    }
    
    public FileObject createPRObject(String path) {
      if (!file.exists(path)) {
        console.bugWarn("createPRObject: "+path+" doesn't exist!");
      }
      
      // If it's a folder, create a portal object.
      if (file.isDirectory(path)) {
        DirectoryPortal portal = new DirectoryPortal(path);
        return portal;
      }
      // If it's a file, create the corresponding object based on the file's type.
      else {
        FileObject fileobject = null;

        FileType type = file.extToType(file.getExt(path));
        switch (type) {
        case FILE_TYPE_UNKNOWN:
          fileobject = new UnknownTypeFileObject(path);
          fileobject.img = new RealmTexture(engine.display.systemImages.get(file.typeToIco(type)));
          fileobject.setSize(0.5);
          // NOTE: Put back hitbox size in case it becomes important later
          break;
        case FILE_TYPE_IMAGE:
          fileobject = new ImageFileObject(path);
          break;
        case FILE_TYPE_PDF:
          fileobject = new ImageFileObject(path);
          ((ImageFileObject)fileobject).allowTexFlipping = true;
          break;
        case FILE_TYPE_VIDEO:
          fileobject = new VideoFileObject(path);
          break;
        case FILE_TYPE_MUSIC:
          fileobject = new MusicFileObject(path);
          break;
        case FILE_TYPE_TIMEWAYENTRY:
          fileobject = new EntryFileObject(path, true);
          break;
        case FILE_TYPE_SHORTCUT:
          fileobject = new ShortcutPortal(path);
          break;
        case FILE_TYPE_MODEL:
          fileobject = new OBJFileObject(path);
          break;
        default:
          fileobject = new UnknownTypeFileObject(path);
          fileobject.img = new RealmTexture(display.systemImages.get(file.typeToIco(type)));
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
      
      entriesTotal = 0;
      drawnEntries = 0;
      timeInRealm  = 0;
      
      String dir = this.stateDirectory;
      file.openDir(dir);
      int l = file.currentFiles.length;
      
      for (int i = 0; i < l; i++) {
        if (file.currentFiles[i] != null) {
          
          // To address the unhidden realm files as of 0.1.2
          String isolatedName = file.getIsolatedFilename(file.currentFiles[i].filename);
          if (isolatedName.equals(file.unhide(REALM_GRASS))) continue;
          if (isolatedName.equals(file.unhide(REALM_TREE))) continue;
          if (isolatedName.equals(file.unhide(REALM_TREE_LEGACY))) continue;
          if (isolatedName.equals(file.unhide(REALM_SKY))) continue;
          if (isolatedName.equals(file.unhide(REALM_BGM))) continue;
          if (file.currentFiles[i].filename.equals(file.unhide(REALM_TURF))) continue;
          if (isolatedName.equals("load_list")) continue;
          for (int j = 1; j < 9; j++) {
            if (isolatedName.equals(file.unhide(REALM_TREE+"-"+j))) continue;
            if (isolatedName.equals(file.unhide(REALM_TREE_LEGACY+"-"+j))) continue;
            if (isolatedName.equals(file.unhide(REALM_SKY+"-"+j))) continue;
          }
          
          // Here we determine which type of object to load into our scene.
          FileObject o = createPRObject(file.currentFiles[i].path);
          
          files.add(o);
          if (file.currentFiles[i].filename.equals("[Prev dir]") && o instanceof DirectoryPortal) {
            exitPortal = (DirectoryPortal)o;
            // Create random position just in case it's a new realm.
            lastPlacedPosX = app.random(-800, 800);
            lastPlacedPosZ = app.random(-800, 800);
            exitPortalX = lastPlacedPosX;
            exitPortalZ = lastPlacedPosZ;
          }
        }
      }
      
      // Oh, and we need to load our pocket objects
      // First reset all our lists.
      pocketObjects = new LinkedList<PRObject>();
      pocketItemNames = new HashSet<String>();
      pockets = new LinkedList<PocketItem>();
      
      
      JSONObject somejson = new JSONObject();
      
      // Create pocket folder if it doesn't exist to prevent Timeway from sh*tting itself
      if (!file.exists(engine.APPPATH+engine.POCKET_PATH)) new File(engine.APPPATH+engine.POCKET_PATH).mkdir();
      
      // For now, we can't put stuff into our pockets in android mode.
      if (!isAndroid()) {
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
      }
      
      updateHoldingItem(globalHoldingObjectSlot);
    }
    
    public boolean isNewRealm() {
      return file.anyImageFile(stateDirectory+REALM_GRASS) == null
      && file.anyImageFile(stateDirectory+REALM_SKY) == null
      && file.anyImageFile(stateDirectory+REALM_SKY+"-1") == null
      && file.anyImageFile(stateDirectory+REALM_TREE) == null
      && file.anyImageFile(stateDirectory+REALM_TREE_LEGACY+"-1") == null
      && file.anyImageFile(stateDirectory+REALM_TREE+"-1") == null
      
      // TODO: unhidden files.
      
      && file.anyMusicFile(stateDirectory+REALM_BGM) == null
      && file.exists(stateDirectory+REALM_TURF) == false;
    }
    
    public void loadRealmTerrain() {
      loadRealmTerrain(this.stateDirectory);
    }
    
    private void runPlugin() {
      if (realmPlugin != null && pluginCompiled.get() && successfulCompile.get()) {
        realmPlugin.run();
      }
      
      if (pluginCompiled.get() && showDebugMessageOnce) {
        showDebugMessageOnce = false;
        if (successfulCompile.get()) {
          console.log("Successful plugin compilation!");
        }
        else {
          console.log("Compilation error: "+realmPlugin.errorOutput);
        }
      }
    }
    
    public void loadRealmTerrain(String dir) {
      // Find out if the directory has a turf file.
      JSONObject jsonFile = null;
      
      String realm_turf = REALM_TURF;
      if (!file.exists(dir+realm_turf)) {
        realm_turf = file.unhide(REALM_TURF);
      }
      
      if (file.exists(dir+realm_turf)) {
        try {
          jsonFile = app.loadJSONObject(dir+realm_turf);
        }
        catch (RuntimeException e) {
          if (!(dir+realm_turf).contains(engine.APPPATH+engine.TEMPLATES_PATH)) {
            console.warn("There's an error in the folder's turf file (exception). Will now act as if the turf is new.");
            file.backupMove(dir+realm_turf);
          }
          else {
            console.warn("There's an error in the folder's turf file (exception).");
          }
          //saveRealmJson();
          return;
        }
        if (jsonFile == null) {
          file.backupMove(dir+realm_turf);
          
          if (!(dir+realm_turf).contains(engine.APPPATH+engine.TEMPLATES_PATH)) {
            console.warn("There's an error in the folder's turf file (null). Will now act as if the turf is new.");
            file.backupMove(dir+realm_turf);
          }
          else {
            console.warn("There's an error in the folder's turf file (null).");
          }
          //saveRealmJson();
          return;
        }
        
        
        // backward compatibility checking time!
        // Also the time we load realm assets since 
        // 1.x -> assets need to be loaded AFTER getting version.
        // 2.x -> assets need to be loaded BEFORE loading terrain (cus PShapes in gpu memory n all. Makes sense?)
        version = jsonFile.getString("compatibility_version", "");
        if (version.equals("1.0") || version.equals("1.1")) {
          versionCompatibility = 1;
          // While we're here, make sure we're not in the morpher tool
          if (currentTool == TOOL_MORPHER) currentTool = TOOL_NORMAL;
        }
        else if (version.equals("2.0") || version.equals("2.1")) {
          versionCompatibility = 2;
        }
        // Satisfies the 2 conditions stated above for 1.x and 2.x!
        loadRealmAssets(dir);
        
        
        
        // Our current version
        if (version.equals("2.0")) {
          loadRealmV2(jsonFile);
          stats.increase("load_v_2_0", 1);
        }
        else if (version.equals("2.1")) {
          loadRealmV2(jsonFile);
          stats.increase("load_v_2_1", 1);
        }
        
        // Legacy "world_3d" version where everything was simple and a mess lol.
        else if (version.equals("1.0") || version.equals("1.1")) {
          loadRealmV1(jsonFile);
          if (version.equals("1.0"))
            stats.increase("load_v_1_0", 1);
          else if (version.equals("1.1"))
            stats.increase("load_v_1_1", 1);
        }
        // Unknown version.
        else {
          console.log(dir.replaceAll("\\\\", "/"));
          console.log(engine.TEMPLATES_PATH);
          if (dir.replaceAll("\\\\", "/").indexOf(engine.TEMPLATES_PATH) == -1) {
            console.log("Incompatible turf file, backing up old and creating new turf.");
            file.backupMove(dir+realm_turf);
            issueRefresherCommand(REFRESHER_PAUSE);
            saveRealmJson();
          }
        }
        
        
      // File doesn't exist; create new turf file.
      } else {
        if (!loadMinimal) {
          console.log("Creating new realm turf file.");
        }
        
        if (version.equals("1.0") || version.equals("1.1")) terrain = new SinesinesineTerrain();
        else if (version.equals("2.0") || version.equals("2.1")) {
          //playerX = 0.0;
          //playerZ = 0.0;
          SinesinesineTerrain t = new SinesinesineTerrain();
          t.setRenderDistance(3);
          t.setGroundSize(150.);
          terrain = t;          
          stats.increase("new_realms_created", 1);
        }
        
        if (loadMinimal) return;
        
        // None of the objects are loaded from file but we still need to
        // call load() since this contains code to init the objects.
        // We need a blank jsonobject to make each fileobject think it hasn't
        // existed in the realm before.
        JSONObject emptyJSON = new JSONObject();
        for (FileObject o : files) {
          if (o != null) {
            o.load(emptyJSON);
          }
        }
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
      if (legacy_autogenStuff == null) {
        legacy_autogenStuff = new HashSet<String>();
      }
      engine.noiseSeed(getHash(stateDirectory));
      
      if (loadMinimal) return;

      int l = objects3d.size();
      // Loop thru each file object in the array. Remember each object is uniquely identified by its filename.
      for (int i = 0; i < l; i++) {
        try {
          JSONObject probjjson = objects3d.getJSONObject(i);
          
          // Each object is uniquely identified by its filename/folder name.
          String name = probjjson.getString("filename", "");
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
      
      // Any remaining objects must have its load method called anyways to initialise its random position.
      JSONObject emptyJSON = new JSONObject();
      for (FileObject o : namesToObjects.values()) {
          o.load(emptyJSON);
      }
      
      
      if (createCoins && !createdCoins) {
        float x = random(-1000, 1000);
        float z = random(-1000, 1000);
        for (int i = 0; i < 100; i++) {
          @SuppressWarnings("unused")
          PRCoin coin = new PRCoin(x, onSurface(x,z), z);
          x += random(-500, 500);
          z += random(-500, 500);
        }
        createdCoins = true;
      }
    }
    
    // (as of Jan 2024) our latest and current version where we load turf files from.
    public void loadRealmV2(JSONObject jsonFile) {
      // create pr_objects array
      JSONArray objects3d = jsonFile.getJSONArray("pr_objects");
      if (objects3d == null) {
        console.warn("Realm info read failed, pr_objects array is missing/misnamed.");
        return;
      }
      
      // Load terrain information.
      // Based on terrain type.
      String terrainType = jsonFile.getString("terrain_type");
      if (terrainType.equals("Sine sine sine"))
        terrain = new SinesinesineTerrain(jsonFile);
      else if (terrainType.equals("Legacy"))
        terrain = new LegacyTerrain(jsonFile);
      else {
        console.warn("Realm info read failed, "+terrainType+" terrain type unknown");
        terrain = new SinesinesineTerrain();
      }
      
      // Load chunks
      JSONArray chunksArray = jsonFile.getJSONArray("chunks");
      
      //if (engine.cacheExists(stateDirectory+"terrain_cache.tmp")) {
      if (false) {
        chunks = decodeTerrainCache(engine.tryGetCachePath(stateDirectory+"terrain_cache.tmp"));
        console.log("Cache load!");
        loadFromCache = true;
      }
      else {
        int l = chunksArray.size();
        for (int i = 0; i < l; i++) {
          try {
            JSONObject chunkdata = chunksArray.getJSONObject(i);
            
            // Load data and put into chunks data.
            // If has is unassigned a value, put the new chunk into the void where it will never be reached lmao.
            chunks.put(chunkdata.getInt("hash", Integer.MAX_VALUE), new TerrainChunkV2(chunkdata));
          }
          
          // Just in case teehee.
          catch (RuntimeException e) {
          }
        }
      }
      
        
      // Put FileObjects into hashmap by filename
      HashMap<String, FileObject> namesToObjects = new HashMap<String, FileObject>();
      for (FileObject o : files) {
        if (o != null) {
          namesToObjects.put(o.filename, o);
        }
      }
      
      if (loadMinimal) return;
      
      int l = objects3d.size();
      // Loop thru each file object in the array. Remember each object is uniquely identified by its filename.
      for (int i = 0; i < l; i++) {
        //try {
          JSONObject probjjson = objects3d.getJSONObject(i);
          
          // Each object is uniquely identified by its filename/folder name.
          String name = probjjson.getString("filename", "[null]");
          
          // If the name begins with a "." then it is an abstract object (file that can appear multiple times in one realm)
          // For now we just have terrain objects (aka trees)
          if (name.length() >= 17 && name.substring(0, 17).equals(".pixelrealm-tree-")) {
            TerrainPRObject tree = new TerrainPRObject();
            tree.load(probjjson);
          }

          // Get the object by name so we can do a lil bit of things to it.
          FileObject o = namesToObjects.remove(name);
          if (o == null) {
            // This may happen if a folder/file has been renamed/deleted. Just move
            // on to the next item.
            continue;
          }
          

          o.load(probjjson);
        //}
        // For some reason we can get unexplained nullpointerexceptions.
        // Just a lazy way to overcome it, literally doesn't affect anything.
        // Totally. Totally doesn't affect anything.
        //catch (RuntimeException e) {
        //  console.bugWarn(e.getMessage());
        //}
      }
      
      
      // For any remaiining items (still in the hashmap because they  are new files that were not
      // in the json file), call the load function to init them.
      JSONObject emptyJSON = new JSONObject();
      for (FileObject o : namesToObjects.values()) {
          o.load(emptyJSON);
      }
      
      // Load lighting
      ambientSlider.valFloat = jsonFile.getFloat("light_ambient", 1f);
      reffectSlider.valFloat = jsonFile.getFloat("light_reffect", 0f);
      geffectSlider.valFloat = jsonFile.getFloat("light_geffect", 0f);
      beffectSlider.valFloat = jsonFile.getFloat("light_beffect", 0f);
      lightDirectionSlider.valInt = jsonFile.getInt("light_direction", 0);
      lightHeightSlider.valInt = jsonFile.getInt("light_height", 2);
      
      // Bye bye Evolving Gateway coins :(
      coins = false;
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
      if (versionCompatibility == 1) {
        success = saveRealmV1(turfJson);
      }
      else if (versionCompatibility == 2) {
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
      jsonFile.setJSONArray("objects3d", objects3d);
      
      // Terrain will most definitely be a sinesinesine terrain.
      if (!(terrain instanceof SinesinesineTerrain)) {
        console.bugWarn("saveRealmV1: incompatible terrain, should be type SinesinesineTerrain. Abort save.");
        return false;
      }
      SinesinesineTerrain t = (SinesinesineTerrain)terrain;
  
      jsonFile.setString("compatibility_version", version);
      jsonFile.setInt("render_distance", (int)t.getRenderDistance());
      jsonFile.setFloat("ground_size", t.getGroundSize());
      jsonFile.setFloat("hill_height", t.hillHeight);
      jsonFile.setFloat("hill_frequency", t.hillFrequency);
      
      jsonFile.setBoolean("coins", coins);
      
      //console.log("Saved realm");
      
      return true;
    }
    
    
    public boolean saveRealmV2(JSONObject jsonFile) {
      jsonFile.setString("compatibility_version", version);
      
      // Save file objects
      JSONArray objects3d = new JSONArray();
      int i = 0;
      for (FileObject o : files) {
        if (o != null) {
          objects3d.setJSONObject(i++, o.save());
        }
      }
      
      for (PRObject o : ordering) {
        if (o != null && o instanceof TerrainPRObject) {
          objects3d.setJSONObject(i++, o.save());
        }
      }
      
      jsonFile.setJSONArray("pr_objects", objects3d);
      
      // Save terrain information
      terrain.save(jsonFile);
      
      // Save realm chunks
      i = 0;
      JSONArray chunksArray = new JSONArray();
      HashSet<TerrainChunkV2> chunksSet = new HashSet<TerrainChunkV2>();
      for (TerrainChunkV2 chunk : chunks.values()) {
        chunksArray.setJSONObject(i++, chunk.save());
        chunksSet.add(chunk);
      }
      jsonFile.setJSONArray("chunks", chunksArray);
      
      // Save lighting
      jsonFile.setFloat("light_ambient", ambientSlider.valFloat);
      jsonFile.setFloat("light_reffect", reffectSlider.valFloat);
      jsonFile.setFloat("light_geffect", geffectSlider.valFloat);
      jsonFile.setFloat("light_beffect", beffectSlider.valFloat);
      jsonFile.setInt("light_direction", lightDirectionSlider.valInt);
      jsonFile.setInt("light_height", lightHeightSlider.valInt);
      
      // Save the cache
      app.saveBytes(engine.saveCacheEntry(stateDirectory+"terrain_cache.tmp", 6942), encodeTerrainCache(chunksSet));
      
      // And we're done already!
      //console.log("Saved realm");
      
      return true;
    }
    
    
    // I just happen to know it.
    // Should be set automatically but eh can't be bothered.
    // Maybe I should add a TODO?
    // Sure.
    // TODO: Make this get set automatically.
    final int CHUNK_BYTES_SIZE = 324;
    final int TERRAIN_CACHE_VERSION = 1;
    
    // converts 0 1 2 3 4 5 to 0 1 -1 2 -2
    private int denumerate(int x) {
      if (x == 0) {
        return 0;
      }
      // even
      else if (x%2 == 0) {
        return -x/2;
      }
      // odd
      else {
        return (x/2)+1;
      }
    }
    
    // converts 0 1 -1 2 -2 to 0 1 2 3 4 5
    // 0 1 -1 2 -2 3
    // 0 1 2  3  4 5
    private int enumerate(int x) {
      if (x == 0) {
        return 0;
      } else if (x > 0) {
        return (x*2)-1;
      } else {
        return -(x*2);
      }
    }
    
    
    public void writeInt(int value, byte[] byteArray, int offset) {
    
      // Writing the integer into the byte array
      byteArray[offset+0] = (byte) (value >> 24); // Most significant byte
      byteArray[offset+1] = (byte) (value >> 16);
      byteArray[offset+2] = (byte) (value >> 8);
      byteArray[offset+3] = (byte) value; // Least significant byte
    }
    
    public int getInt(byte[] byteArray, int offset) {
      
      // Reading the integer from the byte array
      return ((byteArray[offset+0] & 0xFF) << 24) |
        ((byteArray[offset+1] & 0xFF) << 16) |
        ((byteArray[offset+2] & 0xFF) << 8)  |
        ( byteArray[offset+3] & 0xFF);
    }

    
    private byte[] encodeTerrainCache(HashSet<TerrainChunkV2> chunks) {
      HashMap<Integer, byte[]> yposToRow = new HashMap<Integer, byte[]>();
      HashMap<Integer, Integer> yposToRowSize = new HashMap<Integer, Integer>();
    
      // Needed for determining header size
      int maxY = 0;
    
      // Generate rows, put them into the yposToRow hasmap.
      // chunks.entrySet() will be in an arbritrary order so
      // we need to keep a hashset and use the ypos of the chunk
      // to access it
      for (TerrainChunkV2 ch : chunks) {
    
        // values could be negative.
        // convert to natural numbers
        int x = enumerate(ch.chunkX);
        int y = enumerate(ch.chunkY);
        int index = x*CHUNK_BYTES_SIZE;
    
        // New yposToRow entry if it doesn't exist.
        // TODO: MAX_XY_LIMIT is not a good size for byte, maybe we could do some sort of cheap size calculation...?
        if (!yposToRow.containsKey(y)) {
          byte[] bytes = new byte[MAX_CHUNKS_XZ];
          
          //for (int i = 0; i < bytes.length; i++) {
          //  bytes[i] = -1;
          //}
          yposToRow.put(y, bytes);
        }
    
        // Now that we know the yposToRow entry exists we can access it
        byte[] row = yposToRow.get(y);
        byte[] chunkBytes = ch.getByteData();
        
        // Error checking
        if (chunkBytes.length != CHUNK_BYTES_SIZE) {
          // Warn
          console.warn("CHUNK_SIZE set to "+CHUNK_BYTES_SIZE+" but actual size is "+chunkBytes.length+".");
          return null;
        }
    
        // copy chunk to the bytes at the correct index in the row.
        // For example if x = 1 then
        // 0000000000000000000
        // to
        // 0000000001111111111...
        for (int i = 0; i < CHUNK_BYTES_SIZE; i++) {
          row[index+i] = chunkBytes[i];
        }
    
        // Need actual size of row.
        // Remember the TODO I put up there?
        // Yeah, it's hard to decide on a size because we don't know the size until the row is filled.
        //
        // Also, if you're confused, remember, let's say we only have one chunk at x pos 10
        // Data would look something like this:
        // 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111
        // The whole point of this is it's like an array where we access it at an index. Meaning you can access
        // the 1's by going to chunk 10 in the bytes.
        if (yposToRowSize.containsKey(y)) {
          yposToRowSize.put(y, max(yposToRowSize.get(y), index+CHUNK_BYTES_SIZE));
        } else {
          yposToRowSize.put(y, index+CHUNK_BYTES_SIZE);
        }
    
        if (y > maxY) maxY = y;
      }
      maxY++;
    
      // Next step: find the row indicies.
      HashMap<Integer, Integer> yposToRowIndex = new HashMap<Integer, Integer>();
    
      // Calculate total size of byte block.
      int totalSize = 0;
      for (int size : yposToRowSize.values()) {
        totalSize += size;
      }
    
      // In the size of bytes we define here, we add a little more to add space for header info, i.e. version, length, pointers to rows.
      // TODO: If you need an extra pointer for terrain objects, change *2 to *3.
      int headerSize = maxY*Float.BYTES*2 + Float.BYTES*2;  // one for version, one for headersize.
      byte[] bytes = new byte[totalSize + headerSize];
    
      // Now copy the rows to the byte block and get the indicies of each row.
      {
        // Start just after header.
        int i = headerSize;
    
        for (HashMap.Entry<Integer, byte[]> e : yposToRow.entrySet()) {
          int y = e.getKey();
          byte[] row = e.getValue();
          // Get the index here.
          yposToRowIndex.put(y, i);
          // Now copy data from the row
          for (int j = 0; j < yposToRowSize.get(y); j++) {
            bytes[i++] = row[j];
          }
        }
      }
    
      // Final step: header and row indices.
      {
        // Write version
        writeInt(TERRAIN_CACHE_VERSION, bytes, 0);
        writeInt(headerSize, bytes, 4);
        // Start after version
        // TODO: terrain objects, if you are adding that, change this to 12.
        int i = 8;
        // Need to go from 0 to maxY and do this whole weird containsKey thing because remember that some y rows might simply not exist.
        // Also remember y has already been denumerated.
        for (int y = 0; y < maxY; y++) {
          if (yposToRowIndex.containsKey(y)) {
            // Dont need to add headerSize because i = headerSize when this was set.
            writeInt(yposToRowIndex.get(y), bytes, i);
            writeInt(yposToRowSize.get(y), bytes, i+4);
          } else {
            // -1 indicates no row.
            writeInt(-1, bytes, i);
            writeInt(-1, bytes, i+4);
          }
          i+=8;
        }
      }
    
    
      return bytes;
    }
    
    
    
    
    
    private HashMap<Integer, Integer> rowPointers = null;
    private HashMap<Integer, Integer> rowLengths = null;
    private RandomAccessFile chunkCacheBlock = null;
    
    private HashMap<Integer, TerrainChunkV2> decodeTerrainCache(String path) {
      HashMap<Integer, TerrainChunkV2> chunks = new HashMap<Integer, TerrainChunkV2>();
      
      try {
        chunkCacheBlock = new RandomAccessFile(path, "r");
      
        chunkCacheBlock.seek(0);
        byte[] bytes = new byte[16];
        chunkCacheBlock.read(bytes);
        // get header info
        int version = getInt(bytes, 0);
        int headerSize = getInt(bytes, 4);
      
        if (version != TERRAIN_CACHE_VERSION) {
          // TODO: error handling code here.
          return null;
        }
      
        // converted ypos
        rowPointers = new HashMap<Integer, Integer>();
        rowLengths  = new HashMap<Integer, Integer>();
      
        // Get the pointers to each row.
        // TODO: change to 12 if you need an extra pointer.
        int HEADER_START = 8;
        
        chunkCacheBlock.seek(HEADER_START);
        bytes = new byte[headerSize];
        chunkCacheBlock.read(bytes);
      
        {
          int y = 0;
          for (int i = HEADER_START; i < headerSize; i+=8) {
            int ptr = getInt(bytes, i);
            if (ptr != -1) {
              rowPointers.put(denumerate(y), ptr);
              rowLengths.put(denumerate(y), getInt(bytes, i+4));
            }
            y++;
          }
        }
        
      
      
      }
      catch (IOException e) {
        console.warn("decodeTerrainCache: "+e.getMessage());
      }
    
    
      return chunks;
    }
    
    
    
    private byte[] getChunkCache(int x, int y) {
      byte[] bytes = new byte[CHUNK_BYTES_SIZE];
      if (!rowPointers.containsKey(y)) {
        return null;
      }
      int rowPointer = rowPointers.get(y);
    
      int xindex = enumerate(x)*CHUNK_BYTES_SIZE;
       //|| rowPointer+xindex+CHUNK_BYTES_SIZE > chunkCacheBlock.length
      if (xindex >= rowLengths.get(y)) {
        return null;
      }
    
      boolean missingData = true;
      
      
      try {
        chunkCacheBlock.seek((long)(rowPointer+xindex));
        chunkCacheBlock.read(bytes);
      }
      catch (IOException e) {
        console.warn("getChunkCache: "+e.getMessage());
      }
      
      for (int i = 0; i < CHUNK_BYTES_SIZE; i++) {
        if (bytes[i] != 0) missingData = false;
      }
      if (missingData) return null;
      return bytes;
    }
        
    
    
    
    public void emergeFromPortal(String emergeFrom) {
      // Secure code stuff
      if (emergeFrom.length() > 0)
        if (emergeFrom.charAt(emergeFrom.length()-1) == '/')  emergeFrom = emergeFrom.substring(0, emergeFrom.length()-1);
        
      // TODO: obviously we need to fix for macos and linux. (I think)
      // Really really stupid bug fix.
      if (emergeFrom.equals("C:")) emergeFrom = "C:/";
      emergeFrom     = file.getFilename(emergeFrom);
      
      DirectoryPortal emergePortal = null;
      
      // Find the exit portal.
      for (FileObject o : files) {
        if (emergeFrom.equals(o.filename)) {
          emergePortal = (DirectoryPortal)o;
        }
      }
      
      // If for some reason we're at the root
      // (or some strange place)
      // then just reset to normal position.
      if (emergePortal == null) {
        tp(1000., 0., 1000.);
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
            if (o.x > emergePortal.x-AREA_WIDTH && o.x < emergePortal.x+AREA_WIDTH) {
              // +z
              if (o.z > emergePortal.z+AREA_OFFSET && o.z < emergePortal.z+AREA_LENGTH)
                portalCount[1] += 1;
              // -z
              if (o.z < emergePortal.z-AREA_OFFSET && o.z > emergePortal.z-AREA_LENGTH)
                portalCount[3] += 1;
            }
            if (o.z > emergePortal.z-AREA_WIDTH && o.z < emergePortal.z+AREA_WIDTH) {
              // +x
              if (o.x > emergePortal.x+AREA_OFFSET && o.x < emergePortal.x+AREA_LENGTH)
                portalCount[0] += 1;
              // -x
              if (o.x < emergePortal.x-AREA_OFFSET && o.x > emergePortal.x-AREA_LENGTH)
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
        if (input.keyAction("move_backward", 's')) {
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
          tp(emergePortal.x+FROM_DIST, emergePortal.y, emergePortal.z);
          direction = HALF_PI + additionalDir;
          break;
          // +z
        case 1:
          tp(emergePortal.x, emergePortal.y, emergePortal.z+FROM_DIST);
          direction = 0. + additionalDir;
          break;
          // -x
        case 2:
          tp(emergePortal.x-FROM_DIST, emergePortal.y, emergePortal.z);
          direction = -HALF_PI + additionalDir;
          break;
          // -z
        case 3:
          tp(emergePortal.x, emergePortal.y, emergePortal.z-FROM_DIST);
          direction = PI + additionalDir;
          break;
        }
      }
    }
    
    public Object getRealmFile(Object defaultFile, String... paths) {
      for (String path : paths) {
        if (file.exists(path)) {
          if (file.getExt(path).equals("png") || file.getExt(path).equals("gif") || file.getExt(path).equals("jpg") || file.getExt(path).equals("bmp")) {
            incrementMemUsage(file.getImageUncompressedSize(path));
            return loadImage(path);
          }
          //else if (file.getExt(path).equals("wav"))
          //  return new SoundFile(engine.app, stateDirectory+path);
        }
        
        // Alt version without the hidden file.
        String unhidden = file.unhide(path);
        if (file.exists(unhidden)) {
          if (file.getExt(unhidden).equals("png") || file.getExt(unhidden).equals("gif") || file.getExt(path).equals("jpg")) {
            incrementMemUsage(file.getImageUncompressedSize(unhidden));
            return loadImage(unhidden);
          }
          //else if (file.getExt(path).equals("wav"))
          //  return new SoundFile(engine.app, stateDirectory+path);
        }
      }
      return defaultFile;
    }
    
    public void loadRealmAssets() {
      loadRealmAssets(this.stateDirectory);
    }
  
    
    // Used with a flash to refresh the sky
    // TODO: Needs tidying up (especially since we have a imageFileExists method now)
    public void loadRealmAssets(String dir) {
      // Portal light to make it look like a transition effect
      //portalLight = 255;
      
      PImage DEFAULT_GRASS = REALM_GRASS_DEFAULT;
      PImage DEFAULT_TREE = REALM_TREE_DEFAULT;
      PImage DEFAULT_SKY = REALM_SKY_DEFAULT;
      String DEFAULT_BGM = REALM_BGM_DEFAULT;
      
      
      // Classic backwards compatibility for old realms
      // that had a field as the default realm.
      if (version.equals("1.0")) {
        DEFAULT_GRASS = REALM_GRASS_DEFAULT_LEGACY;
        DEFAULT_TREE = REALM_TREE_DEFAULT_LEGACY;
        DEFAULT_SKY = REALM_SKY_DEFAULT_LEGACY;
        DEFAULT_BGM = REALM_BGM_DEFAULT_LEGACY;
      }
      
      
      String ppath = dir+REALM_GRASS;
      
      img_grass = new RealmTexture((PImage)getRealmFile(DEFAULT_GRASS, ppath+".png", ppath+".jpg", ppath+".bmp"));
      
      /// here we search for the terrain objects textures from the dir.
      ArrayList<PImage> imgs = new ArrayList<PImage>();
  
      if (file.exists(DEFAULT_SKY+".gif")) {
        img_sky = new RealmTexture();
        //img_sky.setLarge(((Gif)getRealmFile(DEFAULT_SKY, dir+REALM_SKY+".gif")).getPImages());
        //if (img_sky.get().width != 1500)
        //  console.warn("Width of "+REALM_SKY+" is "+str(img_sky.get().width)+"px, should be 1500px for best visual results!");
      }
      else {
        
        ppath = dir+REALM_SKY;
        // Get either a sky called sky-1 or just sky
        int i = 1;
        PImage sky = (PImage)getRealmFile(DEFAULT_SKY, ppath+".png", ppath+"-1.png", ppath+".jpg", ppath+"-1.jpg", ppath+".bmp", ppath+"-1.bmp");
        imgs.add(sky);
        
        // If we find a sky, keep looking for sky-2, sky-3 etc
        while (sky != DEFAULT_SKY && i <= 9) {
          ppath = dir+REALM_SKY+"-"+str(i+1);
          sky = (PImage)getRealmFile(DEFAULT_SKY, ppath+".png", ppath+".jpg", ppath+".bmp");
          if (sky != DEFAULT_SKY) {
            //if (sky.width != 1500)
            //  console.warn("Width of "+REALM_SKY+" is "+str(sky.width)+"px, should be 1500px for best visual results!");
            imgs.add(sky);
          }
          i++;
        }
        
        img_sky = new RealmTexture(imgs);
      }
      
      
      imgs = new ArrayList<PImage>();
  
      // Try to find the first terrain object texture, it will return default if not found
      PImage terrainobj = (PImage)getRealmFile(DEFAULT_TREE, dir+REALM_TREE_LEGACY+"-1.png", dir+REALM_TREE+"-1.png", dir+REALM_TREE+".png");
      imgs.add(terrainobj);
  
      int i = 1;
      // Run this loop only if the terrain_objects files exist and only for how many pixelrealm-terrain_objects
      // there are in the folder.
      while (terrainobj != DEFAULT_TREE && i <= 9) {
        terrainobj = (PImage)getRealmFile(DEFAULT_TREE, dir+REALM_TREE_LEGACY+"-"+str(i+1)+".png", dir+REALM_TREE+"-"+str(i+1)+".png");
        if (terrainobj != DEFAULT_TREE) {
          imgs.add(terrainobj);
        }
        i++;
      }
  
      // New array and plonk that all in there.
      if (img_tree != null) {
        img_tree.set(imgs);
      }
      else {
        img_tree = new RealmTexture(imgs);
      }
  
      //if (!loadedMusic) {
      String[] soundFileFormats = {".wav", ".mp3", ".ogg", ".flac"};
      boolean found = false;
      i = 0;
      
      // TODO: Tidy this code up with file.anyMusicFile
      // Search until one of the pixelrealm-bgm with the appropriate file format is found.
      while (i < soundFileFormats.length && !found) {
        String ext = soundFileFormats[i++];
        if (file.exists(dir+REALM_BGM+ext)) {
          found = true;
          musicPath = dir+REALM_BGM+ext;
        }
        
        // One for the unhidden files too since android is a thing we're supporting now (it's a long story)
        if (file.exists(file.unhide(dir+REALM_BGM+ext))) {
          found = true;
          musicPath = file.unhide(dir+REALM_BGM+ext);
        }
      }
      
      // If none found use default bgm
      if (!found) {
        musicPath = engine.APPPATH+DEFAULT_BGM;
      }
      
      // And finally, the pixelrealm-plugin
      if (settings.getBoolean("enable_plugins", false)) {
        if (file.exists(dir+REALM_PLUGIN)) {
          // load the code,
          realmPluginPath = dir+REALM_PLUGIN;
          String[] lines = app.loadStrings(dir+REALM_PLUGIN);
          String ccode = "";
          for (String line : lines) {
            ccode += line+"\n";
          }
          final String code = ccode;
          
          
          realmPlugin = plugins.createPlugin();
          pluginCompiled.set(false);
          showDebugMessageOnce = true;
          Thread t1 = new Thread(new Runnable() {
            public void run() {
              successfulCompile.set(realmPlugin.compile(code));
              pluginCompiled.set(true);
            }
          });
          t1.start();
        }
      }
  
    }
    
    
    
    
    
    boolean wasInWater = false;
    
    boolean wasOnGround = false;
    
    // Finally, the most important code of all
    
    // ----- Pixel Realm logic code -----
    
    
    
    public void runPlayer() {
      
      prevPlayerX = playerX;
      prevPlayerY = playerY;
      prevPlayerZ = playerZ;
      
      if (!movementPaused) {
        
      primaryAction = input.keyActionOnce("primary_action", 'o');
      secondaryAction = input.keyActionOnce("secondary_action", 'p');
        
      isWalking = false;
      float speed = WALK_ACCELERATION;
  
      if (input.keyAction("dash", TWEngine.InputModule.SHIFT_KEY)) {
        speed = RUN_SPEED+runAcceleration;
        if (RUN_SPEED+runAcceleration <= MAX_SPEED) runAcceleration+=RUN_ACCELERATION;
      } else runAcceleration = 0.;
      
      // TODO: Make keybinding instead of fixed.
      if (input.keyAction("move_slow", TWEngine.InputModule.ALT_KEY)) {
        speed = SNEAK_SPEED;
        runAcceleration = 0.;
      }
      
      boolean splash = (!wasInWater && isInWater);
  
      // :3
      if (input.keyAction("jump", ' ') && (onGround() || coyoteJump > 0.)) speed *= 3;
  
      float sin_d = sin(direction);
      float cos_d = cos(direction);
      
      cache_playerSinDirection = sin_d;
      cache_playerCosDirection = cos_d;
      
      // Less movement control while in the air.
      if (!onGround()) {
        speed *= 0.1*display.getDelta();
      }
      
      if (isInWater) {
        speed *= UNDERWATER_SPEED_MULTIPLIER;
      }
      
      
      //if
  
      // TODO: re-enable reposition mode
      //if (repositionMode) {
      //  if (clipboard != null) {
      //    if (clipboard instanceof ImageFileObject) {
      //      ImageFileObject fileobject = (ImageFileObject)clipboard;
      //    }
      //  }
      //}
      
      if (input.keyActionOnce("prev_directory", '\b') && usePortalAllowed) {
        //sound.fadeAndStopMusic();
        //requestScreen(new Explorer(engine, stateDirectory));
        if (!file.atRootDir(stateDirectory)) {
          gotoRealm(file.getPrevDir(stateDirectory), stateDirectory);
          stats.increase("previous_directory_traversals", 1);
        }
      }
  
      
      
          // Adjust for lower framerates than the target.
          speed *= display.getDelta();
          float rot = 0.;
          float movex = 0.;
          float movez = 0.;
          float ypoint1 = 0.;
          float ypoint2 = 0.;
          
          if (input.keyAction("move_forward", 'w')) {
            movex += sin_d*speed;
            movez += cos_d*speed;
            ypoint1 = onSurface(playerX+sin_d, playerZ+cos_d);  // Front
            ypoint2 = onSurface(playerX-sin_d, playerZ-cos_d);  // Behind
  
            isWalking = true;
          }
          if (input.keyAction("move_left", 'a')) {
            movex += cos_d*speed;
            movez += -sin_d*speed;
            ypoint1 = onSurface(playerX+cos_d, playerZ-sin_d);  // Left
            ypoint2 = onSurface(playerX-cos_d, playerZ+sin_d);  // Right
  
            isWalking = true;
          }
          if (input.keyAction("move_backward", 's')) {
            movex += -sin_d*speed;
            movez += -cos_d*speed;
            ypoint1 = onSurface(playerX-sin_d, playerZ-cos_d);  // Behind
            ypoint2 = onSurface(playerX+sin_d, playerZ+cos_d);  // Front
  
            isWalking = true;
          }
          if (input.keyAction("move_right", 'd')) {
            movex += -cos_d*speed;
            movez += sin_d*speed;
            ypoint1 = onSurface(playerX-cos_d, playerZ+sin_d);  // Right
            ypoint2 = onSurface(playerX+cos_d, playerZ-sin_d);  // Left
            
            isWalking = true;
          }
          
          float slopeness = ypoint2-ypoint1;
          if (slopeness != 0. && onGround()) {
            float allowance = 1.0-(min(max(slopeness, 0.), 3.)/3.);
            
            movex *= allowance;
            movez *= allowance;
          }
  
  
          if (input.keyAction("move_slow", TWEngine.InputModule.ALT_KEY)) {
            if (input.keyAction("turn_right", 'e')) rot = -SLOW_TURN_SPEED*display.getDelta();
            if (input.keyAction("turn_left", 'q')) rot =  SLOW_TURN_SPEED*display.getDelta();
          } else {
            if (input.keyAction("turn_right", 'e')) rot = -TURN_SPEED*display.getDelta();
            if (input.keyAction("turn_left", 'q')) rot =  TURN_SPEED*display.getDelta();
          }
          
          //if (input.keyAction("look_right_touch", 'e')) rot = -MEDIUM_TURN_SPEED*display.getDelta();
          //if (input.keyAction("look_left_touch", 'q')) rot =  MEDIUM_TURN_SPEED*display.getDelta();
  
  
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
            direction += rot;
            xvel += movex;
            zvel += movez;
            
            boolean slipping = false;
            if (onGround() && !isInWater) {
              float x_ypoint1 = onSurface(playerX+1, playerZ);  // Front
              float x_ypoint2 = onSurface(playerX-1, playerZ);  // Behind
              float z_ypoint1 = onSurface(playerX, playerZ+1);  // Right
              float z_ypoint2 = onSurface(playerX, playerZ-1);  // Left
              
              float x_slope = (x_ypoint2-x_ypoint1);
              float z_slope = (z_ypoint2-z_ypoint1);
              
              if ((abs(x_slope) > SLIP_THRESHOLD || abs(z_slope) > SLIP_THRESHOLD)) {
                xvel = max(min(xvel-x_slope*0.05, 5.), -5.0);
                zvel = max(min(zvel-z_slope*0.05, 5.), -5.0);
                slipping = true;
              }
              else {
                slippingJumpsAllowed = 2;
              }
            }
            
            playerX += xvel;
            playerZ += zvel;
            
            // slippingDown can only be true when player is on ground.
            if (slipping) playerY = onSurface(playerX, playerZ);
            
            float deacceleration = 0.5;
            if (!onGround())
              deacceleration = 0.97;
            else if (slipping) 
              deacceleration = 0.99;
            xvel *= pow(deacceleration, display.getDelta());
            zvel *= pow(deacceleration, display.getDelta());
            
            if (isWalking && onGround()) {
              float bob_speed = speed*0.075;
              
              float maxBobSpeed = display.getDelta()*1.5;
              
              stats.increase("distance_travelled", speed);
  
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
                stats.increase("steps", 1);
                //if (isInWater) 
                //  // TODO: get an actual water step sound effect
                //  sound.playSound("water_jump", random(1.9, 2.5));
                //else
              }
              
              
              timeNotMoving = 0; 
            }
            else {
              if (!input.keyAction("turn_right", 'e') && !input.keyAction("turn_left", 'q') && !input.keyAction("jump", ' ') && !input.keyAction("primary_action", 'o')) {
                timeNotMoving += display.getDelta();
              }
            }
          
          cache_flatSinDirection = sin(direction-PI+HALF_PI);
          cache_flatCosDirection = cos(direction-PI+HALF_PI);
          
          // --- Jump & gravity physics ---
          if (input.keyAction("jump", ' ')) {
            float jumpStrength = JUMP_STRENGTH;
            if (isInWater) {
              yvel = min(yvel+SWIM_UP_SPEED, UNDERWATER_TEMINAL_VEL);
              jumpStrength = UNDERWATER_JUMP_STRENGTH;
              if (jumpTimeout <= 0.) {
                sound.loopSound("swimming");
                sound.pauseSound("underwater");
              }
            }
            // No longer in water.
            else {
              sound.pauseSound("swimming");
            }
            
            if ((onGround() || coyoteJump > 0.) && jumpTimeout < 1.) {
              // Don't allow the player to jump anymore if they slippin' and
              // don't have any jumps left.
              if ((slipping && slippingJumpsAllowed > 0) || !slipping) {
                coyoteJump = 0.;
                yvel = jumpStrength;
                playerY -= 10;
                stats.increase("jumps", 1);
                slippingJumpsAllowed--;
                if (isInWater) {
                  sound.playSound("water_jump");
                  jumpTimeout = 40.;
                }
                else {
                  sound.playSound("jump");
                  jumpTimeout = 30.;
                }
              }
            }
          }
          // No longer pressing space,
          // don't need to check if we're underwater
          else {
            sound.pauseSound("swimming");
            if (isUnderwater) sound.loopSound("underwater");
          }
  
          if (jumpTimeout > 0) jumpTimeout -= display.getDelta();
          if (coyoteJump > 0) coyoteJump -= display.getDelta();
          playerY -= yvel*display.getDelta();
          
          if (onGround()) {
            playerY = onSurface(playerX, playerZ);
            yvel = 0.;
            coyoteJump = 9.;
            //console.log(playerY-prevYPos);
          }
          else if (splash) {
            yvel = 0.;
            sound.playSound("splash", random(0.8, 1.4));
            stats.increase("splashes", 1);
          }
          else {
            // Change yvel while we're in the air
            float gravity = GRAVITY;
            float terminalVel = TERMINAL_VEL;
            if (isInWater) {
              gravity = UNDERWATER_GRAVITY;
              terminalVel = UNDERWATER_TEMINAL_VEL;
            }
            
            yvel = max(yvel-gravity*display.getDelta(), -terminalVel);
          }
  
          if (playerY > 2000.) {
            if (outOfBounds(1000., 1000.)) {
              tp(0., 0., 0.);
            }
            else {
              tp(1000., 0., 1000.);
            }
            
            yvel = 0.;
          }
          
          wasInWater = isInWater;
          isInWater = playerY > terrain.waterLevel  &&  !outOfBounds(playerX, playerZ) && terrain.hasWater;
          
          // Head under the water.
          isUnderwater = playerY+(sin(bob)*3.)-PLAYER_HEIGHT-1. > terrain.waterLevel && !outOfBounds(playerX, playerZ) && terrain.hasWater;
          if (isUnderwater) stats.recordTime("time_underwater");
          
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
            if (input.keyActionOnce("inventory_select_left", ',') && globalHoldingObjectSlot.prev != null) {
              launchWhenPlaced = false;
              globalHoldingObjectSlot = globalHoldingObjectSlot.prev;
              updateHoldingItem(globalHoldingObjectSlot);
              sound.playSound("pickup");
            }
            
            if (input.keyActionOnce("inventory_select_right", '.') && globalHoldingObjectSlot.next != null) {
              launchWhenPlaced = false;
              globalHoldingObjectSlot = globalHoldingObjectSlot.next;
              updateHoldingItem(globalHoldingObjectSlot);
              sound.playSound("pickup");
            }
          }
      }
      else {
        primaryAction = false;
        secondaryAction = false;
      }
      
      if (modifyTerrain) {
        playerY = onSurface(playerX, playerZ);
      }
      
      wasOnGround = onGround();
    }
    
    
    public void runMorpherTool() {
      if (currentTool == TOOL_MORPHER) {
        // Some keyboard actions and controls (i dont need to explain that)
        if (input.keyAction("scale_up", '=')) {
          if (subTool == MORPHER_BULGE || subTool == MORPHER_FLAT) {
            morpherRadius *= pow(1.01, display.getDelta());
          }
          else if (subTool == MORPHER_BLOCK) {
            if (input.keyAction("move_slow", TWEngine.InputModule.ALT_KEY)) {
              morpherBlockHeight -= 2.*display.getDelta();
            }
            else {
              morpherBlockHeight -= 6.*display.getDelta();
            }
          }
        }
        if (input.keyAction("scale_down", '-')) {
          if (subTool == MORPHER_BULGE || subTool == MORPHER_FLAT) {
            morpherRadius *= pow(0.99, display.getDelta());
          }
          else if (subTool == MORPHER_BLOCK) {
            if (input.keyAction("move_slow", TWEngine.InputModule.ALT_KEY)) {
              morpherBlockHeight += 2.*display.getDelta();
            }
            else {
              morpherBlockHeight += 6.*display.getDelta();
            }
          }
        }
        if (input.keyActionOnce("next_subtool", ']')) {
          subTool++;
          if (subTool > 4) subTool = 1;
          sound.playSound("switch_subtool");
        }
        else if (input.keyActionOnce("prev_subtool", '[')) {
          subTool--;
          if (subTool <= 0) subTool = 4;
          sound.playSound("switch_subtool");
        }
        
        
        morpherRadius = min(max(morpherRadius, 25.), 2000.);
        
        // Place cursor in front of player.
        float SELECT_FAR = 300.;
        float px = playerX+sin(direction)*SELECT_FAR;
        float pz = playerZ+cos(direction)*SELECT_FAR;
        
        // For getting height in block subtool mode later in the code.
        float snappedx = 0.;
        float snappedz = 0.;
        
        // Bulge tool
        if (subTool == MORPHER_BULGE || subTool == MORPHER_FLAT) {
          // Here we display the cool ass morpher circle.
          float size = (morpherRadius*2.)/8.;
          float uvSize = 1.0/8.;
          scene.beginShape(QUAD);
          scene.textureMode(NORMAL);
          scene.textureWrap(REPEAT);
          
          // Prepare the texture depending on subtool
          if (subTool == MORPHER_BULGE) {
            scene.texture(display.systemImages.get("morpher_circle_bulge"));
          }
          else if (subTool == MORPHER_FLAT) {
            scene.texture(display.systemImages.get("morpher_circle_flat"));
          }
          
          // Now, go through a grid, getting y points on the terrain, and place a nice
          // blanket of circle texture on top, wrapping around the terrain.
          for (float z = -4.; z < 4.; z += 1.0) {
            float v = (z+4.)/8.;
            float tz = pz+z*size;
            for (float x = -4.; x < 4.; x+=1.0) {
              float u = (x+4.)/8.;
              float tx = px+x*size;
              
              scene.vertex(tx,      onSurface(tx, tz)-10.,           tz,      u,        v);
              scene.vertex(tx+size, onSurface(tx+size, tz)-10.,      tz,      u+uvSize, v);
              scene.vertex(tx+size, onSurface(tx+size, tz+size)-10., tz+size, u+uvSize, v+uvSize);
              scene.vertex(tx,      onSurface(tx, tz+size)-10.,      tz+size, u,        v+uvSize);
            }
          }
          scene.endShape();
        }
        // Now for the block subtool
        else if (subTool == MORPHER_BLOCK || subTool == MORPHER_PIT) {
          // Render cursor
          // Texture doesn't work let's just switch shaders who cares.
          // Let's destroy good performance here.
          //scene.texture(display.errorImg);
          scene.resetShader();
          scene.stroke(0);
          scene.strokeWeight(1);
          if (subTool == MORPHER_BLOCK) { 
            scene.fill(127, 60, 0, 127);
          }
          else if (subTool == MORPHER_PIT) {
            scene.fill(127, 0, 0, 127);
          }
          
          // Here we render a box large enough that it goes off-camera at the bottom of the world.
          final float BOX_HEIGHT = 2000.;
          
          // Snap box to the tiles
          snappedx = (floor(px/terrain.groundSize)+0.5)*terrain.groundSize;
          snappedz = (floor(pz/terrain.groundSize)+0.5)*terrain.groundSize;
          
          float hheight = morpherBlockHeight;
          
          
          boolean disabledDepthTest = false;
          // If you're confused, remember, up is negative in Processing.
          float currSurfaceHeight = onSurface(snappedx, snappedz);
          if (morpherBlockHeight > currSurfaceHeight || subTool == MORPHER_PIT) {
            // I'm reallly sorry, just a lil performance hit is all.
            scene.hint(DISABLE_DEPTH_TEST);
            disabledDepthTest = true;
          }
          
          if (subTool == MORPHER_PIT) {
            hheight = currSurfaceHeight;
          }
          
          scene.pushMatrix();
          scene.translate(snappedx, (BOX_HEIGHT+hheight)/2, snappedz);
          scene.box(terrain.groundSize, BOX_HEIGHT-hheight+1, terrain.groundSize);
          scene.popMatrix();
          //console.log(x+" "+onSurface(x, z)+" "+z);
          
          if (disabledDepthTest) scene.hint(ENABLE_DEPTH_TEST);
        }
        // Finish rendering
        
        // This part of the code is what actually morphs the terrain.
        if (input.keyAction("primary_action", 'o') || input.keyAction("secondary_action", 'p')) {
          // Need this hashset so that only one unique chunk is in there at a time (I think)
          HashSet<TerrainChunkV2> chunksModified = new HashSet<TerrainChunkV2>();
          
          if (subTool == MORPHER_BULGE || subTool == MORPHER_FLAT) {
            
            // Another grid, but for morphing this time
            for (float z = -morpherRadius-terrain.groundSize; z < morpherRadius; z += terrain.groundSize) {
              
              // zrange and xrange are values from 0 to 1 so that we can use it to determine the bulge/circle shape.
              // Apologies if it looks complicated but just know that it goes from 0 to 1 in this loop, no higher.
              float zrange = (z+morpherRadius+terrain.groundSize)/(morpherRadius+morpherRadius+terrain.groundSize);
              
              for (float x = -morpherRadius-terrain.groundSize; x < morpherRadius; x += terrain.groundSize) {
                float xrange = (x+morpherRadius+terrain.groundSize)/(morpherRadius+morpherRadius+terrain.groundSize);
                
                // Calculate bulge. It's just like creating a basic circle in glsl shaders.
                float bulge = sin(xrange*PI)*sin(zrange*PI);
                
                // Slow down morphing if shift pressed
                float morphSpeed = 5.;
                if (input.keyAction("move_slow", TWEngine.InputModule.ALT_KEY)) {
                  morphSpeed = 1.5;
                }
                
                morphSpeed *= display.getDelta();
                
                // If it's flat, "pixelate" it so that its one value or the other,
                // not anything in between.
                // Basically nerd term for saying it rises/sinks the terrain in a flat way.
                if (subTool == MORPHER_FLAT) {
                  bulge = bulge > 0.5 ? 1. : 0.;
                }
                
                // Modify tile y-values (the actual morphing!)
                debug = true;
                if (input.keyAction("primary_action", 'o'))
                  getTileAt(px+x, pz+z).y += bulge*morphSpeed;
                else
                  getTileAt(px+x, pz+z).y -= bulge*morphSpeed;
                debug = false;
                  
                
                // And of course, we need to update the display of the chunk once we're
                // done with our tiles. So add it to the list (unique values only) so
                // that we can update it after.
                TerrainChunkV2 ch = getChunkAt(px+x, pz+z);
                
                // TODO: see if this is really needed.
                if (ch != null) chunksModified.add(ch);
                
                ch = getChunkAt(px+x+terrain.groundSize, pz+z);
                if (ch != null) chunksModified.add(ch);
                
                ch = getChunkAt(px+x, pz+z+terrain.groundSize);
                if (ch != null) chunksModified.add(ch);
                
                
                ch = getChunkAt(px+x-terrain.groundSize, pz+z);
                if (ch != null) chunksModified.add(ch);
                
                ch = getChunkAt(px+x, pz+z-terrain.groundSize);
                if (ch != null) chunksModified.add(ch);
                
                // Play warping sound
                if (!playingWarpingSound) {
                  sound.loopSound("terraform_1");
                  playingWarpingSound = true;
                }
              }
            }              
            // And update the pshape (effectively updates the display on-screen)
            //console.log(chunksModified.size());
            for (TerrainChunkV2 ch : chunksModified) {
              ch.updatePShape();
            }            
          }
          // End bulge and flat subtools
          // Begin block tool >:)
          else if (subTool == MORPHER_BLOCK || subTool == MORPHER_PIT) {
            // woops while testing it was in the wrong place.
            // let's just do this.
            // I'm sure nothing bad will happen...
            px -= terrain.groundSize;
            pz -= terrain.groundSize;
            
            if (subTool == MORPHER_PIT) {
              // Lowest possible height for a tile (up is negative).
              morpherBlockHeight = 9999999.;
            }
            
            // This one is pretty easy. We just modify the tile points
            // for a nice block shape.
            if ((getTileAt(px, pz).y != morpherBlockHeight 
             || getTileAt(px+terrain.groundSize, pz).y != morpherBlockHeight
             || getTileAt(px+terrain.groundSize, pz+terrain.groundSize).y != morpherBlockHeight
             || getTileAt(px, pz+terrain.groundSize).y != morpherBlockHeight)
             && !outOfBounds(px+terrain.groundSize, pz+terrain.groundSize) // This is just to prevent an annoying sound bug from happening.
             ) {
              
             
              if (input.keyAction("secondary_action", 'p')) {
                getTileAt(px, pz).y                                       = morpherBlockHeight;
                getTileAt(px+terrain.groundSize, pz).y                    = morpherBlockHeight;
                getTileAt(px+terrain.groundSize, pz+terrain.groundSize).y = morpherBlockHeight;
                getTileAt(px, pz+terrain.groundSize).y                    = morpherBlockHeight;
                
                // I could prolly write this to be a lot neater but let's be real:
                // do you really need explaining what this code below does?
                // (ok I'll explain: it tries to add each tile, top, bottom, left, right to the modified list
                // so the chunks can be updated)
                // We mult groundSize by two since technically our modified tile is a little bigger than one
                // cubic tile if a point is lying on a chunk border.
                TerrainChunkV2 ch = getChunkAt(px, pz);
                if (ch != null) chunksModified.add(ch);
                ch = getChunkAt(px+terrain.groundSize*2, pz);
                if (ch != null) chunksModified.add(ch);
                ch = getChunkAt(px+terrain.groundSize*2, pz+terrain.groundSize*2);
                if (ch != null) chunksModified.add(ch);
                ch = getChunkAt(px, pz+terrain.groundSize*2);
                if (ch != null) chunksModified.add(ch);
                
                ch = getChunkAt(px-terrain.groundSize, pz);
                if (ch != null) chunksModified.add(ch);
                ch = getChunkAt(px, pz-terrain.groundSize);
                if (ch != null) chunksModified.add(ch);
                
                sound.playSound("blockdd");
                // And update the pshape (effectively updates the display on-screen)
                //console.log(chunksModified.size());
                for (TerrainChunkV2 chh : chunksModified) {
                  chh.updatePShape();
                }
              }
            }
            
            if (input.keyAction("primary_action", 'o') && subTool == MORPHER_BLOCK && (snappedx != lastXBlockGetHeightAction || snappedz != lastZBlockGetHeightAction)) {
              // Let's calculate the highest point!
              // We use min because remember: up => numbers go down.
              morpherBlockHeight = min(getTileAt(px, pz).y, 
              min(getTileAt(px+terrain.groundSize, pz).y, 
              min(getTileAt(px+terrain.groundSize, pz+terrain.groundSize).y, getTileAt(px, pz+terrain.groundSize).y)));
              
              lastXBlockGetHeightAction = snappedx;
              lastZBlockGetHeightAction = snappedz;
              
              sound.playSound("blockdd", 0.8);
            }
          }
        }
        // End pressing action keys
        else {
          // stop sounds if they're playing
          if (playingWarpingSound) {
            playingWarpingSound = false;
            sound.stopSound("terraform_1");
          }
        }
      }
    }
    
    
    
    public void renderTerrain() {
      if (versionCompatibility == 1) {
        renderTerrainV1();
      }
      else if (versionCompatibility == 2) {
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
      
      engine.noiseDetail(4, 0.5); 
        
      scene.pushMatrix();
      float chunkx = floor(playerX/tt.getGroundSize())+1.;
      float chunkz = floor(playerZ/tt.getGroundSize())+1.; 
  
      // This only uses a single cycle, dw.
      legacy_terrainObjects.empty();
      
      
      display.recordRendererTime();
      
      scene.hint(ENABLE_DEPTH_TEST);
      display.recordLogicTime();
  
      for (float tilez = chunkz-tt.getRenderDistance()-1; tilez < chunkz+tt.getRenderDistance(); tilez += 1.) {
        //                                                        random bug fix over here.
        for (float tilex = chunkx-tt.getRenderDistance()-1; tilex < chunkx+tt.getRenderDistance(); tilex += 1.) {
          float x = tt.getGroundSize()*(tilex-0.5), z = tt.getGroundSize()*(tilez-0.5);
          float dist = PApplet.pow((playerX-x), 2)+PApplet.pow((playerZ-z), 2);
  
          boolean dontRender = false;
          if (dist > tt.FADE_DIST_GROUND) {
            float fade = calculateFade(dist, tt.FADE_DIST_GROUND);
            if (fade > 1) {scene.tint(255, fade);
            scene.fill(255, fade); }
            else dontRender = true;
          } else {
            scene.noTint();
            scene.fill(255);
          }
  
          if (!dontRender) {
            float noisePosition = engine.noise(tilex, tilez);
            
            display.recordRendererTime();
            scene.beginShape();
            scene.textureMode(NORMAL);
            scene.textureWrap(REPEAT);
            scene.texture(img_grass.get());
            display.recordLogicTime();
  
  
            if (tilex == chunkx && tilez == chunkz) {
              //scene.tint(color(255, 127, 127));
              //console.log(str(chunkx)+" "+str(chunkz));
            }
            PVector v1 = calcTile(tilex-1., tilez-1.);          // Left, top
            PVector v2 = calcTile(tilex, tilez-1.);          // Right, top
            PVector v3 = calcTile(tilex, tilez);          // Right, bottom
            PVector v4 = calcTile(tilex-1., tilez);          // Left, bottom
            
            
            display.recordRendererTime();
            scene.vertex(v1.x, v1.y, v1.z, 0, 0);                                    
            scene.vertex(v2.x, v2.y, v2.z, tt.getGroundRepeat(), 0);  
            scene.vertex(v3.x, v3.y, v3.z,tt.getGroundRepeat(), tt.getGroundRepeat());  
            scene.vertex(v4.x, v4.y, v4.z, 0, tt.getGroundRepeat());       
  
  
            scene.endShape();
            //scene.noTint();
            display.recordLogicTime();
  
            final float treeLikelyhood = 0.6;
            final float randomOffset = 70;
  
            if (noisePosition > treeLikelyhood) {
              float pureStaticNoise = (noisePosition-treeLikelyhood);
              float offset = -randomOffset+(pureStaticNoise*randomOffset*2);
  
              // I hate this piece of code so much
              // But this is backwards-compatible legacy code.
              String id = str(tilex)+","+str(tilez);
              if (!legacy_autogenStuff.contains(id)) {
                float terrainX = (tt.getGroundSize()*(tilex-1))+offset;
                float terrainZ = (tt.getGroundSize()*(tilez-1))+offset;
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
      
      //renderWaterTest();
      
      display.recordRendererTime();
      scene.noTint();
      scene.fill(255);
      scene.colorMode(RGB, 255);
  
      scene.popMatrix();
      display.recordLogicTime();
    }
    
    
    private void useFadeShader() {
      if (!usingFadeShader) {
        display.recordRendererTime();
        //display.shader(scene, "unlit_fog", "fadeStart", terrain.BEGIN_FADE, "fadeLength", terrain.FADE_LENGTH);
        
        //float x = sin(lightDirectionSlider.valFloat)*2.2f;
        //float y = -lightHeightSlider.valFloat;
        //float z = cos(lightDirectionSlider.valFloat)*2.2f;
        float x = (float)lightDirectionsX[lightDirectionSlider.valInt%16];
        float y = -((float)lightHeightSlider.valInt)*0.25f;
        float z = (float)lightDirectionsZ[lightDirectionSlider.valInt%16];
        float l = sqrt(x*x + y*y + z*z);
        x /= l;
        y /= l;
        z /= l;
            
        display.shader(scene, "lit_fog", 
        "fadeStart", terrain.BEGIN_FADE, 
        "fadeLength", terrain.FADE_LENGTH,
        "ambient", ambientSlider.valFloat,
        "reffect", reffectSlider.valFloat,
        "geffect", geffectSlider.valFloat,
        "beffect", beffectSlider.valFloat,
        "lightDirection", x, y, z
        );
        
        
        
        display.recordLogicTime();
        usingFadeShader = true;
      }
    }  
    
    public void renderTerrainV2() {
      useFadeShader();
      
      float groundSize = terrain.getGroundSize();
      
      int renderDistance = int(terrain.getRenderDistance());
      
      float chunkWiHi = groundSize*float(CHUNK_SIZE);
      
      int chunkx = round((playerX)/(chunkWiHi))-renderDistance-1;
      int chunkz = round((playerZ)/(chunkWiHi))-renderDistance;

      display.recordRendererTime();
      scene.hint(ENABLE_DEPTH_TEST);
      display.recordLogicTime();
      
      scene.pushMatrix();
      
      int xstart = chunkx;
      for (int y = 0; y < renderDistance*2; y++) {
        chunkx = xstart;
        for (int x = 0; x < renderDistance*2; x++) {
          chunkx++;
          
          if (version.equals("2.0")) {
            if (
              chunkx > terrain.chunkLimitX ||
              chunkx < -terrain.chunkLimitX ||
              chunkz > terrain.chunkLimitZ ||
              chunkz < -terrain.chunkLimitZ
            ) continue;
          }
          else if (version.equals("2.1")) {
            if (
              chunkx > terrain.chunkLimitX-1 ||
              chunkx < -terrain.chunkLimitX ||
              chunkz > terrain.chunkLimitZ-1 ||
              chunkz < -terrain.chunkLimitZ
            ) continue;
          }
          
          int hashIndex = MAX_CHUNKS_XZ*chunkz + chunkx;
          
          TerrainChunkV2 chunk = chunks.get(hashIndex);
          
          if (chunk == null) {
            chunk = new TerrainChunkV2(chunkx, chunkz);
            if (loadFromCache) {
              byte[] chunkbytes = getChunkCache(chunkx, chunkz);
              if (chunkbytes != null) {
                chunk.loadFromBytes(chunkbytes);
                chunk.updatePShape();
              }
              chunks.put(hashIndex, chunk);
            }
            else {
              chunk = new TerrainChunkV2(chunkx, chunkz);
            }
            chunks.put(hashIndex, chunk);
          }
          
          chunk.renderChunk();
          
        }
        chunkz++;
      }
      
      if (terrain.hasWater)
        renderWater();
        
      scene.popMatrix();
    }
    
    
    
    
    public void renderWater() {
      scene.noTint();
      scene.fill(255);
      
      scene.beginShape(QUAD);
      scene.textureMode(NORMAL);
      scene.textureWrap(REPEAT);
      scene.texture(display.systemImages.get("water"));
      
      
      float terrainchunkWiHi = terrain.getGroundSize()*float(CHUNK_SIZE);
      float waterSize   = 400.;
      
      float factorthing = (terrainchunkWiHi/waterSize);
      float renderDistance = (factorthing*terrain.getRenderDistance());
      float tilex = round((playerX)/(waterSize))-renderDistance-1;
      float tilez = round((playerZ)/(waterSize))-renderDistance;
      
      float limitX = factorthing*float(terrain.chunkLimitX)*waterSize;
      float limitZ = factorthing*float(terrain.chunkLimitZ)*waterSize;
      float chunkSize = factorthing*waterSize;
      float fff = waterSize*float(CHUNK_SIZE)*0.25;
      
      int irenderDist = int(renderDistance);
      
      float xstart = tilex;
      float ttt = display.getTime()*0.002;
      
      for (int y = 0; y < irenderDist*2; y++) {
        tilex = xstart;
        for (int x = 0; x < irenderDist*2; x++) {
          tilex += 1.0;
          
          float xx1, zz1, xx2, zz2;
          
          // Remmeber, in 2.1 the maximum bounds of chunks at chunklimitxz is reduced.
          if (version.equals("2.1")) {
            xx1 = min(max(tilex*waterSize, -limitX), limitX-chunkSize+fff);
            zz1 = min(max(tilez*waterSize, -limitZ), limitZ-chunkSize+fff);
            xx2 = min(max(tilex*waterSize+waterSize, -limitX), limitX-chunkSize+fff);
            zz2 = min(max(tilez*waterSize+waterSize, -limitZ), limitZ-chunkSize+fff);
          }
          // This was the original code.
          else {
            xx1 = min(max(tilex*waterSize, -limitX), limitX+fff);
            zz1 = min(max(tilez*waterSize, -limitZ), limitZ+fff);
            xx2 = min(max(tilex*waterSize+waterSize, -limitX), limitX+fff);
            zz2 = min(max(tilez*waterSize+waterSize, -limitZ), limitZ+fff);
          }
                    
          scene.vertex(xx1,           terrain.waterLevel, zz1, ttt, ttt);                                    
          scene.vertex(xx2,           terrain.waterLevel, zz1, ttt+1., ttt);  
          scene.vertex(xx2,           terrain.waterLevel, zz2, ttt+1., ttt+1.);  
          scene.vertex(xx1,           terrain.waterLevel, zz2, ttt, ttt+1.);  
          
          
        }
        tilez += 1.0;
      }
      scene.endShape();
    }
    
    
    
    
    
    public void renderSky() {
      display.recordRendererTime();
      // Clear canvas (we need to do that because opengl is big stoopid)
      // TODO: benchmark; scene.clear or scene.background()?
      scene.perspective(PI/3.0, (float)scene.width/scene.height, 10., 1000000.);
      scene.background(0);
      scene.noTint();
      scene.noStroke();
      scene.fill(255);
      
      float pixelsCorrectness = float(4/DISPLAY_SCALE);
      
      float sky_fov = (float(scene.width)/float(img_sky.get().width))/pixelsCorrectness;
      
      // Render the sky.
      float skyDelta = -(direction/TWO_PI);
      float skyViewportLeft = skyDelta;
      float skyViewportRight = skyDelta+sky_fov;
  
      scene.beginShape();
      scene.textureMode(NORMAL);
      scene.textureWrap(REPEAT);
      scene.texture(img_sky.get());
      
      
      scene.vertex(0, 0, skyViewportLeft, 0.);
      scene.vertex(scene.width, 0, skyViewportRight, 0.);
      scene.vertex(scene.width, img_sky.get().height*pixelsCorrectness, skyViewportRight, 1.);
      scene.vertex(0, img_sky.get().height*pixelsCorrectness, skyViewportLeft, 1.);
      
      scene.vertex(0, img_sky.get().height*pixelsCorrectness, skyViewportLeft, 1.);
      scene.vertex(scene.width, img_sky.get().height*pixelsCorrectness, skyViewportRight, 1.);
      scene.vertex(scene.width, height, skyViewportRight, 0.9999);
      scene.vertex(0,   height, skyViewportLeft, 0.9999);
      
      scene.endShape();
      scene.flush();
      scene.resetShader();
      display.recordLogicTime();
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
          
          // Ooh, remember to add the file to the linkedlist.
          // I think that was the cause of a very annoying bug.
          // Also, due to if conditions earlier, this is guarenteed to NOT be an abstract object.
          files.add((FileObject)holdingObject);
        }
        
        // Need to do a few things when we move files like that.a
        // But NOT if it's an abstract item! (i.e. exit portal)
        if (!globalHoldingObject.abstractObject) {
          if (holdingObject instanceof PixelRealmState.FileObject) {
            PixelRealmState.FileObject obj = (PixelRealmState.FileObject)holdingObject;
            obj.dir = file.directorify(currRealm.stateDirectory)+obj.filename;
          }
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
        
        
        ItemSlot tmp = null;
        // Switch to next item in the queue
        if (globalHoldingObjectSlot.next != null) tmp = globalHoldingObjectSlot.next;
        else if (globalHoldingObjectSlot.prev != null) tmp = globalHoldingObjectSlot.prev;
        
        // Remove from inventory
        pockets.remove(globalHoldingObjectSlot);
        // Remove from names
        pocketItemNames.remove(getHoldingName());
        
        // For the tutorial.
        promptPlonkedDownItem();
        
        // Simply setting it to null will "release"
        // the object, setting it in place.
        holdingObject = null;
        
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
        if (currentTool == TOOL_NORMAL && optionHighlightedItem == f) {
          f.tint = color(255, 200, 200);
        }
      }
      // Also check for pocket items
      for (PRObject f : pocketObjects) {
        f.checkHovering();
      }
      
      // Pick up code
      if (closestObject != null) {
        FileObject p = (FileObject)closestObject;
        if (primaryAction) {
          switch (currentTool) {
            case TOOL_GRABBER:
            pickupItem(p);
            sound.playSound("pickup");
            break;
            case TOOL_NORMAL:
            p.interationAction();
            break;
            default:
            break;
          }
        }
        
        if (secondaryAction) {
          switch (currentTool) {
            case TOOL_NORMAL:
            // Bring up menu
            if (p != exitPortal) {
              optionHighlightedItem = p;
              promptFileOptions(p);
            }
            break;
            default:
            break;
          }
        }
      }
      
      // Plonking down objects
      if (currentTool == TOOL_GRABBER && currRealm.holdingObject != null && secondaryAction) {
        issueRefresherCommand(REFRESHER_PAUSE);
        placeDownObject();
        sound.playSound("plonk");
        stats.increase("items_plonked_down", 1);
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
          
          // Fade the held object so we can actually see where we're going.
          holdingObject.tint = color(255, 80);
          if (onGround())
            holdingObject.y = onSurface(x, z);
          else
            holdingObject.y = playerY;
            
          if (holdingObject instanceof ImageFileObject) {
            ImageFileObject imgobject = (ImageFileObject)holdingObject;
            imgobject.rot = direction+HALF_PI;
          }
          else if (holdingObject instanceof MusicFileObject) {
            MusicFileObject imgobject = (MusicFileObject)holdingObject;
            imgobject.rotY = direction;
          }
        }
      }
      //else if (holdingObject != null) {
      //  holdingObject.destroy();
      //  holdingObject = null;
      //}
      
      // Reset to true for EntryFileObjects so that they don't all draw at the same
      // time clobbering up the fps.
      drawEntryOnce = true;
      
      for (PRObject o : ordering) {
        o.run();
        o.calculateVal();
        //console.log(o.getClass().getSimpleName());
      }
      ordering.insertionSort();
    }
    
    public void regenerateTrees() {
      for (PixelRealmState.PRObject o : currRealm.ordering) {
        if (o != null && o instanceof PixelRealmState.TerrainPRObject) {
          o.destroy();
        }
      }
      
      for (PixelRealmState.TerrainChunkV2 ch : currRealm.chunks.values()) {
        if (ch != null) {
          ch.regenerateTerrainObj();
        }
      }
    }
    
    private String getHoldingName(PRObject item) {
      String name = "Unknown";
      if (item instanceof FileObject) {
        FileObject o = (FileObject)item;
        name = o.filename;
      }
      return name;
    }
    
    private String getHoldingName() {
      return getHoldingName(holdingObject);
    }
    
    float closestDist = 0;
    public void renderPRObjects() {
      for (PRObject o : ordering) {
        if (currentTool == TOOL_GRABBER && closestObject == o)
          o.tint = color(255, 200, 200);
        o.display();
      }
    }
    
    public void tp(float x, float y, float z) {
      playerX = x;
      playerY = y;
      playerZ = z;
      prevPlayerX = x;
      prevPlayerY = y;
      prevPlayerZ = z;
    }
    
    public void tp(float x, float y, float z, float dir) {
      playerX = x;
      playerY = y;
      playerZ = z;
      prevPlayerX = x;
      prevPlayerY = y;
      prevPlayerZ = z;
      currRealm.direction = dir;
    }
    
    
    // That "effect" is just the portal glow.
    public void renderEffects() {
      scene.perspective(PI/3.0, (float)scene.width/scene.height, 10., 1000000.);
      float FADE = 0.9;
      display.recordRendererTime();
      if (isUnderwater) {
        sound.setSoundVolume("underwater", 1.0);
        scene.beginShape();
        scene.textureMode(NORMAL);
        scene.textureWrap(REPEAT);
        scene.texture(display.systemImages.get("water"));
        scene.tint(255, 210);
        
        
        float ttt = 0.5; //display.getTime()*0.001;
        
        float uvx = 0.0;
        float uvy = 0.0;
        
        scene.vertex(0, 0, ttt, ttt);
        scene.vertex(scene.width, 0, uvx+ttt, ttt);
        scene.vertex(scene.width, scene.height, uvx+ttt, uvy+ttt);
        scene.vertex(0, scene.height, ttt, uvy+ttt);
        
        scene.endShape();
      }
      else {
        sound.setSoundVolume("underwater", 0.0);
      }
      
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
      display.recordLogicTime();
      
    
      // When we exit a portal, there's usually a bit of lag as we read files/perform loading,
      // which causes the delta to be high and try to boost us forwards like 30 frames.
      // However, with the old FPS system, SLEEPY mode was the minimum at 15fps, which meant we could
      // only skip at most 4 frames at a time. We wanna keep that cool bug :sunglasses:
      portalLight *= PApplet.pow(FADE, min(display.getDelta(), 4));

    }
    
    
    
  }
  // End PixelRealm state class.
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  // --- All of PixelRealm's non-state realm platformer code. ---
  
  // This famous code positions the player in the correct place on a quad.
  private float getplayerYOnQuad(PVector v1, PVector v2, PVector v3, PVector v4, float playerX, float playerZ) {
    // Part 1
    // Here we're calculating x/z coordinates here so: flat on ground.
    // Calculate the slope-iness of the line touching one of the quad's 4 points and the player.
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
    // This gets the height at a certain point on one of the quad's line, depending how sloped it is.
    float point1Height = otherEdge ? lerp(v2.y, v3.y, m1) : lerp(v4.y, v3.y, m1);

    // Part 3
    // Pythagoras
    // Here we calculate the length of the line from quad's point to player in x/z space.
    // Think: you're looking at the quad from a bird's eye view and drawing a triangle where the Hypotenuse
    // the quad's point and the player's pos.
    // This is to calculate the length of the line
    // Please note that no y positions are used/calculated in this stage.
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
    // We do a very similar process, still bird's eye view and still in x/z space, but this time
    // from the quad's point to the player (whereas before it was quad's point -> point on the line).
    // We do this to compare the two hypotenuse's lines and calculate a percentage as to which point
    // the player is on the line.
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
    
    // And ayo, we get to calculate our percentage, use it to lerp between quad's point
    // and the y-value on the line we calculated before, and successfully get the y height on the quad!
    float percent = playerLen/len;
    float calculatedY = lerp(v1.y, point1Height, percent);
    
    return calculatedY;
  }
  
  // Note: Wow that's an old function.
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
    portalCoolDown = 10.;
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
    // Error checking
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
    
    // Gotta wait until entries are loaded to prevent concurrency exceptions.
    // For whatever reason, there could be a state where we're at 9/10 entries loaded
    // but it never increases to 10/10.
    // Cuz im too lazy to solve the bug, let's just timeout after 180 frames. All entries
    // should most definitely be loaded by then.
    if (drawnEntries < entriesTotal && (timeInRealm < 180)) {
      console.log("Please wait until all entries have loaded! ("+drawnEntries+"/"+entriesTotal+")");
      bumpBack();
      return;
    }
    
    // Prevent the player going into directories that would make Timeway implode on itself
    if (file.directorify(to).equals(file.directorify(engine.APPPATH+engine.POCKET_PATH))) {
      prompt("Nice try", "You can't go into "+engine.getAppName()+"'s pocket directory. Doing so would cause a paradox.", 20);
      bumpBack();
      return;
    }
    if (file.directorify(to).equals(file.directorify(engine.CACHE_PATH))) {
      prompt("Nice try", "You can't go into "+engine.getAppName()+"'s cache directory. Doing so would cause a paradox.", 20);
      bumpBack();
      return;
    }
    
    portalLight = 255.;
    portalCoolDown = 10.;
    
    // Before we do anything with files, we need to tell the refresher thread to take a quick nap.
    // Let's also update the list while we're at it.
    issueRefresherCommand(REFRESHER_PAUSE);
    // Now it's asleep.
    refresherFilesList[0] = to;
    // Remember, calling pause will automatically update its lastmodified list too.
    
    
    // Update inventory for moving realms (move files)
    boolean success = true;
    // Abort if unsuccessful.
    for (PocketItem p : pockets) {
      success &= p.changeRealm(currRealm.stateDirectory);;
    }
    if (!success) {
      // bump back the player lol.
      bumpBack();
      
      return;
    }
    
    // Save before we leave (I can't believe I forgot that)
    currRealm.saveRealmJson();
    
    // Do caching here.
    if (realmCaching) {
      if (prevRealm != null) {
        if (prevRealm.stateDirectory.equals(file.directorify(to))) {
          PixelRealmState tmp = currRealm;
          currRealm = prevRealm;
          // currRealm is now prevrealm
          prevRealm = tmp;
          if (fro.length() > 0)
            currRealm.emergeFromPortal(fro);
          else {
            currRealm.tp(1000., 0., 1000.);
            currRealm.direction = PApplet.PI;
          }
          switchToRealm(currRealm);
          return;
        }
      }
      
      prevRealm = currRealm;
    }
    
    //tilesCache.clear();
    
    if (fro.length() == 0)
      currRealm = new PixelRealmState(to);
    else
      currRealm = new PixelRealmState(to, fro);
    
    stats.increase("realms_traversed", 1);
      
      
    backgroundRealm = null;
    realmsToVisit.clear();
    //visitedBackgroundRealms.add(to);
    
    
    // Creating a new realm won't start the music automatically cus we like manual bug-free control.
    if (!cassettePlaying()) {
      sound.streamMusicWithFade(currRealm.musicPath);
    }
      
    // so that our currently holding item doesn't disappear when we go into the next realm.
    if (currentTool == TOOL_GRABBER) {
      currRealm.updateHoldingItem(globalHoldingObjectSlot);
    }
    
    indexer.startIndexingThread(to);
    
    System.gc();
  }
  
  
  
  protected void switchToRealm(PixelRealmState r) {
    issueRefresherCommand(REFRESHER_PAUSE);
    refresherFilesList[0] = r.stateDirectory;
    
    // Update inventory for moving realms (move files)
    boolean success = true;
    // Abort if unsuccessful.
    for (PocketItem p : pockets) {
      success &= p.changeRealm(currRealm.stateDirectory);;
    }
    if (!success) {
      sound.playSound("nope");
      return;
    }
    currRealm.saveRealmJson();
    
    //cassettePlaying = "";
    
    if (!cassettePlaying()) {
      sound.streamMusicWithFade(r.musicPath);
    }
    
    portalCoolDown = 10.;
    currRealm = r;
    currRealm.refreshFiles();
    // so that our currently holding item doesn't disappear when we go into the next realm.
    currRealm.updateHoldingItem(globalHoldingObjectSlot);
    
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
    memUsage.getAndAdd((long)val);
  }
  
  public void incrementMemUsage(long val) {
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
    display.recordRendererTime();
    long used = (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory());
    //float percentage = (float)used/(float)MAX_MEM_USAGE;
    long total = Runtime.getRuntime().totalMemory();
    float percentage = (float)used/(float)total;
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
    text("Mem: "+(used/1024)+" kb / "+(total/1024)+" kb", 105, myUpperBarWeight+45);
    display.recordLogicTime();
  }
  
  private void setPerspective() {
    float zNear = 10.;
    if (movementPaused) zNear = 120.;
    scene.perspective(fovx, fovy, zNear, 1000000.);
  }
    
    
  boolean beginBackgroundCaching = true;
  
  protected void runPlugin(int mode) {
    apiMode = mode;
    currRealm.runPlugin();
  }
    
        
  // Finally, the most important code of all
  
  // ----- Pixel Realm logic code -----
  private void runPixelRealm() {
    
    // Pre-rendering stuff.
    portalCoolDown -= display.getDelta();
    animationTick += display.getDelta();
    // Trollolloloolloollolloll
    // (This is so that we can begin in a new caching location if we decide to move)
    //backgroundRealm = null;
    //if (realmsToVisit.size() > 0) {
    //  realmsToVisit.clear();
    //}
    
    if (timeNotMoving > 2000) {
      if (!power.getPowerSaver()) {
        //doBackgroundCaching(15);
      }
      if (beginBackgroundCaching) {
        //console.log("zzz...");
        //beginBackgroundCaching = false;
      }
    }
    else {
      //beginBackgroundCaching = true;
    }
    
    runMultithreadedLoader();
    if (refreshRealm.getAndSet(false) == true) {
      console.log("Change detected, refreshing realm.");
      currRealm.refreshEverything();
    }
    
    //This function assumes you have not called portal.beginDraw().
    if (legacy_portalEasteregg) evolvingGatewayRenderPortal();
    
    // Do all non-display logic (for stuff that is displayed)
    // Stuff that is currently on-screen is stored in ordering list.
    currRealm.runPlayer();
    currRealm.runPRObjects();
    scene.resetShader();
    usingFadeShader = false;
    
    // Now begin all the drawing!
    display.recordRendererTime(); 
    scene.beginDraw();
    if (currRealm.realmPlugin != null) currRealm.realmPlugin.sketchioGraphics = scene;
    display.recordLogicTime();
    currRealm.renderSky();
    setPerspective();
    display.recordRendererTime();
    // Make us see really really farrrrrrr
    scene.pushMatrix();
    display.recordLogicTime();

    //scene.translate(-xpos+(scene.width / 2), ypos+(sin(bob)*3)+(scene.height / 2)+80, -zpos+(scene.width / 2));
    {
      float x = currRealm.playerX;
      float y = currRealm.playerY+(sin(bob)*3)-PLAYER_HEIGHT;
      float z = currRealm.playerZ;
      float LOOK_DIST = 200.;
      display.recordRendererTime();
      scene.camera(x, y, z, 
        x+sin(currRealm.direction)*LOOK_DIST, y, z+cos(currRealm.direction)*LOOK_DIST, 
        0., 1., 0.);
      if (currRealm.lights) scene.pointLight(255, 245, 245, x, y, z);
      display.recordLogicTime();
    }

    currRealm.renderTerrain();
    currRealm.runMorpherTool();
    currRealm.renderPRObjects(); 
    runPlugin(MODE_SCENE);
    scene.resetShader();
    
    // Pop the camera.
    scene.popMatrix();
    
    // PERFORMANCE ISSUE: OpenGL state machine is a bitchass!
    // This takes a long itme to do!!
    display.recordRendererTime();
    scene.hint(DISABLE_DEPTH_TEST);
    currRealm.renderEffects();
    runPlugin(MODE_POSTSCENE);
    
    display.recordRendererTime();
    scene.endDraw();
    if (currRealm.realmPlugin != null) currRealm.realmPlugin.sketchioGraphics = app.g;
    float wi = scene.width*DISPLAY_SCALE;
    float hi = this.height;
    
    app.image(scene, (WIDTH/2)-wi/2, (HEIGHT/2)-hi/2, wi, hi);
    
    display.recordLogicTime();
    
    
    if (showMemUsage)
      displayMemUsageBar();
      
    // Quickwarp controls (outside of player controls because we need non-state
    // class to run it)
    // TODO: This should really be in runPlayer yet it's here for some reason?
    if (!movementPaused && !engine.commandPromptShown) {
      for (int i = 0; i < 10; i++) {
        // Go through all the keys 0-9 and check if it's being pressed
        if (input.keyActionOnce("quick_warp_"+str(i), str(i).charAt(0)) && usePortalAllowed) {
          // Save current realm
          quickWarpRealms[quickWarpIndex] = currRealm;
          
          if (i == quickWarpIndex) console.log("Going back to default dir");
          if (quickWarpRealms[i] == null || i == quickWarpIndex) {
            String dir = engine.DEFAULT_DIR;
            gotoRealm(dir, file.directorify(file.getPrevDir(dir)));
          }
          else {
            switchToRealm (quickWarpRealms[i]);
          }
          stats.increase("warps", 1);
          quickWarpIndex = i;
          sound.playSound("swish");
          portalLight = 255;
          break;
        }
      }
      
    }
    
    timeInRealm++;
    stats.recordTime("time_in_pixelrealm");
    stats.recordTime("REALMTIME_"+currRealm.stateFilename);
  }
  
  
  
  
  // --- Screen standard code ---
  
  public void content() {
    if (engine.power.getSleepyMode()) engine.power.setAwake();
    runPixelRealm(); 
    stats.increase("total_frames_pixelrealm", 1);
  }
  
  PixelRealmState backgroundRealm = null;
  HashSet<String> visitedBackgroundRealms = new HashSet<String>();
  ArrayList<String> realmsToVisit = new ArrayList<String>();
  ArrayList<PixelRealmState.ImageFileObject> entriesToLoad = new ArrayList<PixelRealmState.ImageFileObject>();
  AtomicBoolean completeBackgroundLoading = new AtomicBoolean(false);
  PixelRealmState.EntryFileObject backgroundEntry;
  
  int intervalBackground = 0;
  
  protected void runMinimal() {
    //if (!power.getPowerSaver()) {
    //  doBackgroundCaching(1);
    //}
  }
  
  // Save our breadcrumbs
  public void shutdown() {
  }
  
  // TODO: no longer used
  protected void doBackgroundCaching(int interval) {
    intervalBackground++;
    
    
    // Skip a turn and wait for loading to complete.
    if (completeBackgroundLoading.get() == true) {
      return;
    }
    
    // Once the entry has been loaded, rendering stage and save to disk
    if (backgroundEntry != null) {
      drawEntryOnce = true;
      backgroundEntry.run();
      
      //println("In "+backgroundRealm.stateDirectory);
      //if (!drawEntryOnce) {
      //  println(backgroundEntry.filename+" loaded.");
      //}
      //else println(backgroundEntry.filename+" is already cached.");
      backgroundEntry = null;
      return;
    }
    
    // Ready the individual entries
    if (entriesToLoad.size() > 0) {
      PixelRealmState.ImageFileObject p = null;
      PImage result = display.errorImg;
      while (entriesToLoad.size() > 0 && result != null) {
        // Until we get an entry that actually needs caching so we don't wait forever.
        // Run it so that we trigger the "once per frame" entries loading.
        p = entriesToLoad.remove(0);
        
        // Let's just use it to check if cache exists.
        result = engine.tryLoadImageCache(p.dir, new Runnable() {public void run() { }});
      }
      
      if (result == null && p != null) {
        if (p instanceof PixelRealmState.EntryFileObject) {
          backgroundEntry = (PixelRealmState.EntryFileObject)p;
        }
        else {
          backgroundEntry = null;
        }
        final PixelRealmState.ImageFileObject pp = p;
        Thread t1 = new Thread(new Runnable() {
          public void run() {
            pp.loadNonConcurrent();
            
            completeBackgroundLoading.set(false);
          }
        }
        );
        completeBackgroundLoading.set(true);
        t1.start();
        //Enough work done.
        return;
      }
    }
    
    // Go into realms and find stuff.
    if (intervalBackground > interval) {
      intervalBackground = 0;
      
      if (backgroundRealm == null) {
        realmsToVisit.add(currRealm.stateDirectory);
      }
      
      
      if (realmsToVisit.size() > 0) {
        String nextRealm = realmsToVisit.remove(0);
        
        while (visitedBackgroundRealms.contains(nextRealm)) {
          //println("Already visited "+nextRealm+"!");
          
          // Nothing left, cancel everything.
          if (realmsToVisit.size() == 0) {
            return;
          }
          
          nextRealm = realmsToVisit.remove(0);
        }
        
        // We get to load our realm here
        backgroundRealm = null;
        // Quick garbage cleaning to get rid of the gunk and prevent memory from overloading
        System.gc();
        
        // No more inefficient shitass loading
        //backgroundRealm = new PixelRealmState(nextRealm, true);
        visitedBackgroundRealms.add(nextRealm);
        // The part of the code where we "run" our pixelrealm
        for (PixelRealmState.FileObject p : backgroundRealm.files) {
          // Add it to our list for a "recursive" behaviour but once every second.
          if (p instanceof PixelRealmState.DirectoryPortal && !(p instanceof PixelRealmState.ShortcutPortal)) {
            realmsToVisit.add(((PixelRealmState.DirectoryPortal)p).dir);
          }
          
          if (p instanceof PixelRealmState.ImageFileObject) {
            entriesToLoad.add((PixelRealmState.ImageFileObject)p);
          }
        }
        
        // Just debug stuff.
        //println("------------------------------");
        //for (String item : realmsToVisit) {
        //  println(item);
        //}
        //println("Visited "+nextRealm);
        
        engine.saveCacheInfoNow();
      }
      else {
        
        console.log("nothing left");
      }
    }
  }
  
  public void upperBar() {
    super.upperBar();
    display.recordRendererTime();
    app.textAlign(LEFT, TOP);
    app.fill(0);
    app.textFont(engine.DEFAULT_FONT, 36);
    
    if (currRealm == null) return;
    
    if (engine.mouseX() > 0. && engine.mouseX() < app.textWidth(currRealm.stateDirectory) && engine.mouseY() > 0. && engine.mouseY() < myUpperBarWeight) {
      app.fill(50);
      if (input.secondaryOnce) {
        // Create minimenu.
          
        String[] labels = new String[2];
        Runnable[] actions = new Runnable[2];
        
        labels[0] = "Open";
        actions[0] = new Runnable() {public void run() {
            
          file.open(currRealm.stateDirectory);
            
        }};
        
        
        labels[1] = "Copy";
        actions[1] = new Runnable() {public void run() {
            
          console.log("Path copied!");
          clipboard.copyString(currRealm.stateDirectory);
            
        }};
        
        ui.createOptionsMenu(labels, actions);
      }
      else if (input.primaryOnce) {
        console.log("Path copied!");
        clipboard.copyString(currRealm.stateDirectory);
      }
    }
    else {
      app.fill(0);
    }
    app.textFont(engine.DEFAULT_FONT, 36);
    app.text(currRealm.stateDirectory, 10, 10);
    
    if (currRealm.memOverload) {
      display.img("error", WIDTH-myUpperBarWeight-10f, 0f, myUpperBarWeight, myUpperBarWeight);
    }
    else if (loading > 0 || sound.loadingMusic()) {
      ui.loadingIcon(WIDTH-myUpperBarWeight/2-10, myUpperBarWeight/2, myUpperBarWeight);
      
      // Doesn't matter too much that it's being converted to an int,
      // it doesn't need to be accurate.
      // It's simply an approximate timeout timer for the loading icon to disappear.
      loading -= (int)display.getDelta();
      if (loading <= 0 && engine.lowMemory) {
        System.gc();
      }
    }
    display.recordLogicTime();
  }
  
  
  public void startupAnimation() {
    if (engine.showUpdateScreen) {
      requestScreen(new Updater(engine, engine.updateInfo));
      engine.showUpdateScreen = false;
    }
  }
  
  public void endScreenAnimation() {
    //issueRefresherCommand(REFRESHER_TERMINATE);
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
    else if (command.equals("/refreshassets")) {
      console.log("Refreshing assets...");
      currRealm.loadRealmAssets();
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
        sharedResources.set("legacy_evolvinggateway_easteregg", false);
        legacy_portalEasteregg = false;
        console.log("Legacy Evolving Gateway style portals disabled.");
        
        // Resize all the portals to the modern size.
        for (PixelRealmState.FileObject o : currRealm.files) {if (o != null) {if (o instanceof PixelRealmState.DirectoryPortal) {
              o.setSize(0.8);
        }}}
      }
      else {
        sharedResources.set("legacy_evolvinggateway_easteregg", true);
        legacy_portalEasteregg = true;
        console.log("Welcome back to Evolving Gateway!");
        
        // Resize all the portals to the legacy size.
        for (PixelRealmState.FileObject o : currRealm.files) {if (o != null) {if (o instanceof PixelRealmState.DirectoryPortal) {
              o.setSize(1.);
        }}}
      }
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
      currRealm.tp(xyz[0], xyz[1], xyz[2], xyz[3]);
      
      console.log("Teleported to ("+str(currRealm.playerX)+", "+str(currRealm.playerY)+", "+str(currRealm.playerZ)+").");

      return true;
    }
    else if (engine.commandEquals(command, "/docoolthing")) {
      for (PixelRealmState.TerrainChunkV2 chunk : currRealm.chunks.values()) {
        console.log("aa");
        chunk.doThing();
      }
      stats.increase("cool_things_done", 1);
      return true;
    }
    else if (engine.commandEquals(command, "/regeneratetrees")) {
      currRealm.regenerateTrees();
      console.log("Regenerated stuff.");
      return true;
    }
    else if (engine.commandEquals(command, "/goto")) {
      String[] args = getArgs(command);
      if (args.length >= 1) {
        String path = args[0].trim().replaceAll("\\\\", "/");
        if (file.exists(path) && file.isDirectory(path)) {
          console.log("Transported to realm "+path+".");
          gotoRealm(path);
        }
        else {
          console.log(path+" is not a valid realm/folder!");
        }
      }
      else {
        console.log("Please provide a path where you want to go!");
      }
      return true;
    }
    else if (engine.commandEquals(command, "/fov")) {
      String[] args = getArgs(command);
      int i = 0;
      float xy[] = {PI/3.,(float)scene.width/scene.height};
      for (String arg : args) {
        if (i >= xy.length) break;
        xy[i++] = float(arg);
      }
      
      fovx = xy[0];
      fovy = xy[1];
      
      console.log("FOV updated.");
      
      return true;
    }
    else if (engine.commandEquals(command, "/hiresmode") || engine.commandEquals(command, "/hires")) {
      DISPLAY_SCALE = 2;
      scene = createGraphics((int(WIDTH/DISPLAY_SCALE)), int(this.height/DISPLAY_SCALE), P3D);
      ((PGraphicsOpenGL)scene).textureSampling(2);     
      console.log("High res mode enabled.");
      console.log("Please restart to switch back");
      return true;
    }
    else if (engine.commandEquals(command, "/puthere")) {
      int successfulRelocations = 0;
      for (PixelRealmState.PRObject p : currRealm.files) {
        int count = 0;
        boolean moved = false;
        while (currRealm.outOfBounds(p.x, p.z)) {
          p.x = random(-10000, 10000);
          p.z = random(-10000, 10000);
          count++;
          if (count > 1000) {
            console.warn("Couldn't relocate item cus we ain't smart enough.");
            break;
          }
          moved = true;
        }
        if (moved)
          successfulRelocations++;
          
        p.surface();
      }
      console.log("Relocated "+successfulRelocations+" items.");
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
  public WorldLegacy(TWEngine engine) { 
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
    engine.noiseSeed(myRandomSeed);
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
    engine.noiseDetail(OCTAVE, 2.); 
    display.img("sky_1", 0, myUpperBarWeight, 
      WIDTH, this.height); 
    if (displayStars) drawNightSkyStars(); 
    float hillWidth=HILL_WIDTH; 
    float prevWaveHeight=WATER_LEVEL;
    float prevHeight=0; 
    float floorPos=this.height+myUpperBarWeight; 
    if (input.primaryOnce) xscroll+=5; 
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
    if (input.keyDownOnce(BACKSPACE)) previousScreen();
  }
}
