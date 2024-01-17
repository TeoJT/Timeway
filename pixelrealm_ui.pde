



public class PixelRealmWithUI extends PixelRealm {
  
  private PImage IMG_BORDER_TILE;
  
  private boolean menuShown = false;
  private SpriteSystemPlaceholder gui = null;
  
  private Menu menu = null;
  
  // --- Constructors ---
  public PixelRealmWithUI(Engine engine, String dir) {
    super(engine, dir);
    
    IMG_BORDER_TILE = display.systemImages.get("menuborder");

    gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"gui/pixelrealm/");
    gui.interactable = false;
  }
  
  
  // --- UI classes ---
  class Menu {
    public void display() {}
    
    boolean cached = false;
    
    float cache_backX = 0.;
    float cache_backY = 0.;
    int cache_tilesWi = 0;
    int cache_tilesHi = 0;
    
    protected void displayBackground(String backgroundName) {
      gui.sprite(backgroundName, "black");
      
      if (!cached || gui.interactable) {
        cache_backX = gui.getSprite(backgroundName).getX();
        cache_backY = gui.getSprite(backgroundName).getY();
        int wi   = gui.getSprite(backgroundName).getWidth();
        int hi   = gui.getSprite(backgroundName).getHeight();
        
        cache_tilesWi = wi/IMG_BORDER_TILE.width;
        cache_tilesHi = hi/IMG_BORDER_TILE.height;
        
        cached = true;
      }
      
      display.recordRendererTime();
      
      // Horizontal
      float x = cache_backX;
      float y = cache_backY;
      float bottomOffset = float(cache_tilesHi*IMG_BORDER_TILE.height);
      for (int ix = 0; ix < cache_tilesWi; ix++) {
        image(IMG_BORDER_TILE, x, y);
        image(IMG_BORDER_TILE, x, y+bottomOffset);
        x += IMG_BORDER_TILE.width;
      }
      
      // Vertical
      x = cache_backX;
      y = cache_backY;
      float sideOffset = float(cache_tilesWi*IMG_BORDER_TILE.width);
      for (int iy = 0; iy < cache_tilesHi+1; iy++) {
        image(IMG_BORDER_TILE, x, y);
        image(IMG_BORDER_TILE, x+sideOffset, y);
        y += IMG_BORDER_TILE.height;
      }
      
      display.recordLogicTime();
    }
    
  }
  
  class MainMenu extends Menu {
    public MainMenu() {}
    public void display() {
      displayBackground("back-mainmenu");
      
      // --- Creator menu ---
      if (engine.button("creator_1", "new_entry_128", "Creator")) {
        sound.playSound("menu_select");
        menu = new CreatorMenu();
      }
      
      if (engine.button("pocket_menu", "new_entry_128", "Pockets")) {
        sound.playSound("menu_select");
        menu = new PocketMenu();
      }
      if (engine.button("grabber_1", "grabber_tool_128", "Grabber")) {
        // Select the last item in the inventory if not already selected.
        if (globalHoldingObject == null) {
          if (pockets.tail != null) {
            globalHoldingObjectSlot = pockets.tail;
          }
        }
        currRealm.updateHoldingItem(globalHoldingObjectSlot);
        
        currentTool = TOOL_GRABBER;
        menuShown = false;
        sound.playSound("menu_select");
      }
      if (engine.button("notool_1", "notool_128", "No tool")) {
        currentTool = TOOL_NORMAL;
        globalHoldingObjectSlot = null;
        currRealm.updateHoldingItem(globalHoldingObjectSlot);
        menuShown = false;
        sound.playSound("menu_select");
      }
    }
  }
  
  class CreatorMenu extends Menu {
    public CreatorMenu() {}
    public void display() {
      displayBackground("back-creatormenu");
      if (engine.button("newentry", "new_entry_128", "New entry")) {
        sound.playSound("menu_select");
        newEntry();
      }
      
      
      if (engine.button("newfolder", "new_folder_128", "New folder")) {
        sound.playSound("menu_select");
        newFolder();
      }
      
      if (engine.button("newshortcut", "create_shortcut_128", "New shortcut")) {
        sound.playSound("menu_select");
        ((PixelRealmState.ShortcutPortal)currRealm.createPRObjectAndPickup(currRealm.createShortcut())).loadShortcut();
        menuShown = false;
      }
    }
    
    public void newFolder() {
      sound.playSound("menu_select");

      Runnable r = new Runnable() {
        public void run() {
          if (engine.keyboardMessage.length() <= 1) {
            console.log("Please enter a valid folder name!");
            return;
          }
          String folderpath = currRealm.stateDirectory+engine.keyboardMessage;
          if (!file.exists(folderpath)) {
            new File(folderpath).mkdirs();
          }
          else {
            sound.playSound("nope");
            console.log(engine.keyboardMessage+" already exists!");
            return;
          }
          
          currRealm.createPRObjectAndPickup(folderpath);
          currentTool = TOOL_GRABBER;

          menuShown = false;
          sound.playSound("menu_select");
        }
      };

      engine.beginInputPrompt("Folder name:", r);
      menu = new InputPromptMenu();
    }
    
    public void newEntry() {
      sound.playSound("menu_select");

      Runnable r = new Runnable() {
        public void run() {
          if (engine.keyboardMessage.length() <= 1) {
            console.log("Please enter a valid folder name!");
            return;
          }
          
          String path = currRealm.stateDirectory+engine.keyboardMessage+"."+engine.ENTRY_EXTENSION;
          if (file.exists(path)) {
            sound.playSound("nope");
            console.log(engine.keyboardMessage+" already exists!");
            return;
          }
          
          // Create a new empty file so that we can hold it and place it down, editor will handle the rest.
          try {
            FileWriter emptyFile = new FileWriter(path);
            emptyFile.write("");
            emptyFile.close();
          } catch (IOException e2) {
            console.warn("Couldn't create entry, IO error!");
            menuShown = false;
            return;
          }
          
          currRealm.createPRObjectAndPickup(path);
          currentTool = TOOL_GRABBER;
          
          launchWhenPlaced = true;

          menuShown = false;
          sound.playSound("menu_select");
        }
      };

      engine.beginInputPrompt("Entry name:", r);
      menu = new InputPromptMenu();
    }
  }
  
  class PocketMenu extends Menu {
    
    public void display() {
      displayBackground("back-pocketmenu");
      
      gui.sprite("pocket_line1", "white");
      gui.sprite("pocket_line2", "white");
      
      
      if (engine.button("pocket_back", "back_arrow_128", "")) {
        sound.playSound("menu_select");
        menu = new Menu();
      }
    }
  }
  
  class InputPromptMenu extends Menu {
    public void display() {
      displayBackground("back-inputprompt");
      engine.displayInputPrompt();
    }
  }
  
  
  
  
  
  
  
  
  
  
  public void runMenu() {
    if (menuShown && menu != null) {
      engine.useSpriteSystem(gui);
      menu.display();
      gui.updateSpriteSystem();
    }
  }
  
  public void runGUI() {
    // Display inventory
    if (!menuShown && currentTool == TOOL_GRABBER && globalHoldingObject != null) {
      float invx = 10;
      float invy = this.height-80;
      
      display.recordRendererTime();
      textFont(engine.DEFAULT_FONT, 40);
      textAlign(LEFT, TOP);
      fill(255);
      text(globalHoldingObject.name, 15, this.height-140);
      for (PocketItem p : pockets) {
        invy = this.height-80;
        if (p == globalHoldingObject) invy -= 20;
  
        float x = invx;
        float y = invy;
        
        if (p.abstractObject || p.isDuplicate) {
          x += app.random(-5, 5);
          y += app.random(-5, 5);
        }
  
        if (p.item != null && p.item.img != null) 
          image(p.item.img, x, y, 64, 64);
        invx += 70;
      }
      display.recordLogicTime();
    }
  }
  
  
  
  
  
  public void controls() {
    // Tab pressed.
    if (engine.keybindPressed("menu") && !engine.commandPromptShown) {
      menuShown = !menuShown;
      menu = new MainMenu();
      
      // If we're editing a folder/entry name, pressing tab should make the menu disappear
      // and then we can continue moving. If we forget to turn the inputPrompt off, the engine
      // will think we're still typing and won't allow us to move.
      engine.inputPromptShown = false;
      if (menuShown)
        sound.playSound("menu_appear");
    }
    // Allow the command prompt to be shown only if the menu isn't displayed.
    engine.allowShowCommandPrompt = !menuShown;
    super.movementPaused = menuShown;
  }
  
  
  
  public void content() {
    super.content();
    this.controls();
    this.runMenu();
    this.runGUI();
  }
  
  
}
