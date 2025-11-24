
// Wanna find a name of a realm template without searching through tons of folders?
// grep -ir "[realm name]" $(find ./ -type f -name "realmtemplate")


public class PixelRealmWithUI extends PixelRealm {

  private final String TEMPLATE_METADATA_FILENAME = "realmtemplate.json";

  private PImage IMG_BORDER_TILE;


  private String musicInfo = "";
  private String musicURL = "";

  public boolean menuShown = false;
  private boolean showPlayerPos = false;
  private SpriteSystem gui = null;
  private Menu menu = null;
  private boolean touchControlsEnabled = false;
  
  // We have this outside the pocket class because it's nice for it to remember which tab we're on.
  private int selectedPocketTab = 0;

  
  // Dear god I really need to re-do this entire tutorial at some point.
  
  private String[] dm_welcome = {
    "Welcome to Timeway.",
    "Your folders are your realms.",
    "Your computer is your universe.",
    "But first, let me show you the ropes.",
    "This place you are in right now is actually your home folder.",
    "This is a realm. Your files inside your home folder are in this realm.",
    "Go have a look around, use WSAD to move and Q+E to look left/right."
  };
  private String[] dm_tutorial_1 = {
    "Well done.",
    "It's a bit blank for a realm though, isn't it?",
    "Let's give it a proper look and feel.",
    "Select a template."
  };
  private String[] dm_tutorial_2 = {
    "Good choice.",
    "But your files look a bit scattered and messy...",
    "Let's learn how to organise things.",
    "Press <tab>, then select \"Grabber\"."
  };
  // For when the player didn't choose a realm
  private String[] dm_tutorial_2_alt = {
    "You... didn't really choose anything, did you?",
    "Doesn't matter. Let's move on.",
    "Your files look a bit scattered and messy...",
    "Let's learn how to organise things.",
    "Press <tab>, then select \"Grabber\"."
  };
  // For when there's no realm templates
  private String[] dm_tutorial_2_alt_2 = {
    "Well done.",
    "Your files look a bit scattered and messy...",
    "Let's learn how to organise things.",
    "Press <tab>, then select \"Grabber\"."
  };
  private String[] dm_tutorial_3 = {
    "Now press the 'o' key to pick up some items."
  };
  private String[] dm_tutorial_4 = {
    "Move it around, and place them down with 'p'."
  };
  private String[] dm_tutorial_end = {
    "Well done. You have mastered the essentials.",
    "Remember, all the items you see in your realms are files on your computer.",
    "Portals resemble folders. Walk into them to go to enter the folder, or \"realm\".",
    "You should be able to figure out the rest yourself, it's not too complicated.",
    "Timeway is an ongoing project. There may be bugs and missing features.",
    "But there are many more things to come.",
    "In the meantime, I hope you enjoy this demo."
  };

  //private String[] dm_hint_1 = {
  //  "Did you know you can create your own realm assets?",
  //  "Realms have 5 assets that make up its look and feel: sky, grass, trees, background music, and properties.",
  //  "These files can be found under the name .pixelrealm-... in your folders on your computer.",
  //  "If you are on MacOS or Linux, these files may be hidden.",
  //  "Try customising them, see what you can create.",
  //};



  // --- Constructors ---
  public PixelRealmWithUI(TWEngine engine, String dir) {
    super(engine, dir);
    
    myUpperBarColor = color(123, 119, 128);
    myLowerBarColor = myUpperBarColor;
    
    
    // Ugh. whatever.
    IMG_BORDER_TILE = display.getImg("menuborder");

    touchControlsEnabled = settings.getBoolean("touch_controls", false);
    // Obviously needed on phones, regardless of settings.
    if (isAndroid()) {
      touchControlsEnabled = true;
    }

    gui = new SpriteSystem(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/pixelrealm/");
    gui.suppressSpriteWarning = true;
    gui.interactable = false;
    ui.useSpriteSystem(gui);

    // Indicates first time running, run the tutorial.
    boolean statsExists = false;
    statsExists = isAndroid() ? file.exists(getAndroidWriteableDir()+engine.STATS_FILE()) : file.exists(engine.APPPATH+engine.STATS_FILE());

    if (!statsExists) {
      // No tutorial for now, it sucks. We can redesign the tutorial later.
      //this.requestTutorial();
    }
  }
  
  private void beginInputPrompt(String text, Runnable r) {
    engine.beginInputPrompt(text, r);
    menu = new InputPromptMenu();
  }


  // --- UI classes ---
  class Menu {
    public void display() {
    }

    boolean cached = false;

    float cache_backX = 0.;
    float cache_backY = 0.;
    float cache_backWi = 0.;
    float cache_backHi = 0.;
    int cache_tilesWi = 0;
    int cache_tilesHi = 0;
    String cache_backgroundName = "";

    protected float getX() {
      if (!cached || ui.getInUseSpriteSystem().interactable) return ui.getInUseSpriteSystem().getSprite(cache_backgroundName).getX();
      return cache_backX;
    }
    
    protected SpriteSystem gui() {
      return ui.getInUseSpriteSystem();
    }

    protected float getY() {
      if (!cached || gui().interactable) return gui().getSprite(cache_backgroundName).getY();
      return cache_backY;
    }

    protected float getWidth() {
      if (!cached || gui().interactable) return (float)gui().getSprite(cache_backgroundName).getWidth();
      else return cache_backWi;
    }

    protected float getHeight() {
      if (!cached || gui().interactable) return (float)gui().getSprite(cache_backgroundName).getHeight();
      else return cache_backHi;
    }

    protected float getXmid() {
      if (!cached || gui().interactable) return gui().getSprite(cache_backgroundName).getX()+(float)gui().getSprite(cache_backgroundName).getWidth()*0.5;
      return cache_backX+cache_backWi*0.5;
    }

    protected float getYmid() {
      if (!cached || gui().interactable) return gui().getSprite(cache_backgroundName).getY()+(float)gui().getSprite(cache_backgroundName).getHeight()*0.5;
      return cache_backY+cache_backHi*0.5;
    }

    protected float getYbottom() {
      if (!cached || gui().interactable) return gui.getSprite(cache_backgroundName).getY()+(float)gui().getSprite(cache_backgroundName).getHeight();
      return cache_backY+cache_backHi;
    }

    protected void displayBackground(String backgroundName) {
      gui().spriteVary(backgroundName, "black");
      if (display.phoneMode) backgroundName += "-phone";
      if (!cached || gui().interactable) {
        cache_backgroundName = backgroundName;
        cache_backX = gui().getSprite(backgroundName).getX();
        cache_backY = gui().getSprite(backgroundName).getY();
        int wi   = gui().getSprite(backgroundName).getWidth();
        int hi   = gui().getSprite(backgroundName).getHeight();
        cache_backWi = (float)wi;
        cache_backHi = (float)hi;

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


    // Code called when menu is closed via (tab)
    public void close() {
    }
  }

  class TitleMenu extends Menu {
    protected SpriteSystem.Sprite back;
    protected String title;
    protected String bgName;

    public TitleMenu(String title, String backgroundName) {
      super();
      back = gui.getSprite(backgroundName);
      this.title = title;
      this.bgName = backgroundName;
    }

    public void setTitle(String t) {
      this.title = t;
    }

    public void display() {
      displayBackground(bgName);

      fill(255);
      textFont(engine.DEFAULT_FONT, 32);
      textAlign(CENTER, TOP);
      text(title, getXmid(), getY()+50.);
    }
  }

  class DialogMenu extends TitleMenu {
    private String[] dialog;
    private int dialogIndex = 0;
    protected Runnable runWhenDone = null;
    private float appearTimer = 0;
    private boolean enterToContinue = true;
    private boolean playedSound = false;
    private int time = 0;

    public DialogMenu(String title, String backgroundName, String txt) {
      super(title, backgroundName);
      dialog = new String[1];
      dialog[0] = txt;
    }

    public DialogMenu(String title, String backgroundName, String[] txt) {
      super(title, backgroundName);
      dialog = txt;
    }

    public DialogMenu(String title, String backgroundName, String[] txt, Runnable r) {
      this(title, backgroundName, txt);
      runWhenDone = r;
    }

    public DialogMenu(String title, String backgroundName, String txt, Runnable r) {
      this(title, backgroundName, txt);
      runWhenDone = r;
    }

    public void runWhenDone(Runnable r) {
      runWhenDone = r;
    }

    public void setAppearTimer(int t) {
      appearTimer = (float)t;
    }

    public void setEnterToContinue(boolean onoff) {
      enterToContinue = onoff;
    }

    public void display() {
      if (appearTimer > 0.) {
        appearTimer -= display.getDelta();
        movementPaused = false;
        return;
      }
      time++;
      if (!playedSound) {
        sound.playSound("menu_prompt");
        playedSound = true;
      }


      displayBackground(bgName);


      // Below is enter to continue (ignored if enterToContinue is off);
      fill(255);
      textFont(engine.DEFAULT_FONT, 30);
      textAlign(CENTER, CENTER);
      text(dialog[dialogIndex], getX()+40, getY(), getWidth()-80, getHeight());

      if (!enterToContinue) return;
      textSize(18);
      text("(Enter/return to continue)", getXmid(), getYbottom()-70);

      boolean enterPressed = input.enterOnce;
      if (touchControlsEnabled) {
        enterPressed |= input.primaryOnce && time > 4;
      }

      if (enterPressed) {
        sound.playSound("menu_select");
        dialogIndex++;
        time = 0;
        if (dialogIndex >= dialog.length) {
          menuShown = false;
          menu = null;
          if (runWhenDone != null)
            runWhenDone.run();
        }
      }
    }
  }

  class YesNoMenu extends DialogMenu {
    protected Runnable runWhenDeclined = null;

    public YesNoMenu(String title, String txt) {
      super(title, "back-yesno", txt);
      setEnterToContinue(false);
    }

    public YesNoMenu(String title, String txt, Runnable runYes) {
      super(title, "back-yesno", txt, runYes);
      setEnterToContinue(false);
    }

    public YesNoMenu(String title, String txt, Runnable runYes, Runnable runNo) {
      super(title, "back-yesno", txt, runYes);
      runWhenDeclined = runNo;
      setEnterToContinue(false);
    }

    public void display() {
      super.display();

      if (ui.buttonVary("menu_yes", "tick_128", "Yes") || input.enterOnce) {
        sound.playSound("menu_select");
        menuShown = false;
        menu = null;
        if (runWhenDone != null)
          runWhenDone.run();
      }
      if (ui.buttonVary("menu_no", "cross_128", "No")) {
        sound.playSound("menu_select");
        menuShown = false;
        menu = null;
        if (runWhenDeclined != null)
          runWhenDeclined.run();
      }
    }
  }






  class ConflictMenu extends DialogMenu {
    protected Runnable runWhenDeclined = null;
    
    private PixelRealmState.FileObject oldFile, newFile;

    public ConflictMenu(String title, String txt, PixelRealmState.FileObject oldfileObject, PixelRealmState.FileObject newfileObject) {
      super(title, "back-conflict", txt);
      oldFile = oldfileObject;
      newFile = newfileObject;
      
      setEnterToContinue(false);
    }


    public void display() {
      super.display();
      
      // Rename
      if (ui.buttonVary("conflict_rename", "rename_256", "Rename")) {
        sound.playSound("menu_select");
        
        Runnable r = new Runnable() {
          public void run() {
            if (engine.promptInput.length() == 0) {
              return;
            }
            String newFilename = engine.promptInput;
            
            String newPath = file.directorify(file.getDir(oldFile.dir))+newFilename;
            
            if (file.exists(newPath)) {
              menu = new DialogMenu("Can't rename file", "back-newrealm", "The filename is still the same. Could not place item in realm, please try again with a different name.");
              return;
            }
            
            issueRefresherCommand(REFRESHER_PAUSE);
            if (file.mv(newFile.dir, newPath)) {
              float x = newFile.x;
              float y = newFile.y;
              float z = newFile.z;
              console.log("File renamed to "+file.getFilename(newPath));
              currRealm.refreshFiles();
              PixelRealmState.FileObject newf = currRealm.findFileObjectByName(newFilename);
              newf.x = x;
              newf.y = y;
              newf.z = z;
            }
            else {
              console.warn("Couldn't rename item: "+file.getFileError());
            }
            
            sound.playSound("menu_select");
            
            closeMenu();
          }
        };
  
        beginInputPrompt("Rename to:", r);
        if (newFile.filename.contains(".")) {
          engine.promptInput = "."+file.getExt(newFile.filename);
          input.cursorX = 0;
        }
        
      }
      
      
      // Replace
      if (ui.buttonVary("conflict_replace", "replace_256", "Replace")) {
        sound.playSound("menu_select");
        
        Runnable yes = new Runnable() {
          public void run() {
            issueRefresherCommand(REFRESHER_PAUSE);
            
            cassetteCheck(oldFile.filename);
            
            if (file.recycle(oldFile.dir)) {
              currRealm.poofAt(oldFile);
              oldFile.destroy();
              sound.playSound("poof");
              
              currRealm.placeDownObject();
            }
            else {
              console.warn("Failed to recycle item: "+file.getFileError());
            }
          }
        };
        
        menu = new YesNoMenu("Replace", "The existing file will be moved to the recycle bin before being replaced by the moved file.\nDo you want to proceed?", yes);
      }
      
      // Swap
      //if (ui.buttonVary("conflict_swap", "swap_256", "Swap")) {
      //  sound.playSound("menu_select");
        
      //  //float x = newFile.x;
      //  //float y = newFile.y;
      //  //float z = newFile.z;
        
      //  //int oldIndex = holdingItemIndex;
      //  //currRealm.pickupItem(oldFile);
        
      //  closeMenu();
      //}
      
      // Dismiss
      if (ui.buttonVary("conflict_dismiss", "cross_128", "Dismiss")) {
        sound.playSound("menu_select");
        closeMenu();
      }
    }
  } 




  class MainMenu extends TitleMenu {
    public MainMenu() {
      super("--- M E N U ---", "back-mainmenu");
    }
    public void display() {
      super.display();

      // --- Creator menu ---
      if (ui.buttonVary("creator_1", "new_entry_128", "Creator")) {
        sound.playSound("menu_select");
        
        if (hotbar.size() < HOTBAR_LIMIT) {
          menu = new CreatorMenu();
        }
        else {
          errorPrompt("Hotbar full", "Your hotbar is full! Please remove some items from your hotbar before creating new files.", 0);
        }
      }

      // --- Pocket menu ---
      if (ui.buttonVary("pocket_menu", "pockets_128", "Pockets")) {
        sound.playSound("menu_select");
        openPocketMenu();
      }
      
      
      // --- Command menu (for phone) ---
      if (display.phoneMode) {
        if (ui.buttonVary("command_button", "command_256", "Command")) {
          engine.showCommandPrompt();
          menu = null;
          menuShown = false;
        }
      }

      // --- Edit terrain menu ---
      if (ui.buttonVary("terraform_menu", "terrain_128", "Terrain")) {
        if (currRealm.versionCompatibility == 1 || currRealm.versionCompatibility != 2) {
          Runnable rno = new Runnable() {
            public void run() {
              menuShown = true;
              menu = new MainMenu();
            }
          };
          
          // Additional functionality for upgrading the realm.
          Runnable ryes = new Runnable() {
            public void run() {
              if (!COMPATIBILITY_VERSION.equals("2.0") && !COMPATIBILITY_VERSION.equals("2.1")) {
                menuShown = false;
                menu = null;
                console.bugWarn("Expecting COMPATIBILITY_VERSION "+COMPATIBILITY_VERSION+". Please remember to change this part of the code!");
                return;
              }

              currRealm.version = COMPATIBILITY_VERSION;
              currRealm.versionCompatibility = 2;

              menu = new TerrainMenu();
              menuShown = true;
              currRealm.terraformWarning = false;
            }
          };
          menu = new YesNoMenu("Old version", "This realm uses an older save file version which does not support terrain options. Would you like to upgrade the realm save file?", ryes, rno);
        }
        else {
          sound.playSound("menu_select");
          menu = new TerrainMenu();
        }
        
      }
      
      // -- Home screen --
      if (ui.buttonVary("home_screen", "home_128", "Home screen")) {
        requestScreen(new HomeScreen(engine));
        //sound.stopMusic();
        menu = null;
        menuShown = false;
      }
      
      // --- Gardner tool ---
      if (ui.buttonVary("gardener_1", "gardener_tool_128", "Gardener")) {
        if (currRealm.versionCompatibility == 1) {
          menu = new DialogMenu("Can't use morpher", "back-newrealm", "This realm uses an older version and you can't use the gardener tool here. Please upgrade by selecting \"Terrain\" from the menu to use this tool.");
        }
        else {
          switchTool(TOOL_GARDENER);
          menuShown = false;
          sound.playSound("menu_select");
        }
      }
      
      // --- Morpher tool ---
      if (ui.buttonVary("morpher_1", "morpher_tool_128", "Morpher")) {
        if (currRealm.versionCompatibility == 1) {
          menu = new DialogMenu("Can't use morpher", "back-newrealm", "This realm uses an older version and you can't use the morpher tool here. Please upgrade by selecting \"Terrain\" from the menu to use this tool.");
        }
        else {
          switchTool(TOOL_MORPHER);
          menuShown = false;
          sound.playSound("menu_select");
        }
      }

      // --- Grabber tool ---
      if (ui.buttonVary("grabber_1", "grabber_tool_128", "Grabber")) {
        // Select the last item in the inventory if not already selected.
        //currRealm.updateHoldingItem();
        switchTool(TOOL_GRABBER);
        menuShown = false;
        sound.playSound("menu_select");
      }

      // --- No tool ---
      if (ui.buttonVary("notool_1", "notool_128", "No tool")) {
        //currRealm.updateHoldingItem(globalHoldingObjectSlot);
        switchTool(TOOL_NORMAL);
        menuShown = false;
        sound.playSound("menu_select");
      }
    }
  }
  
  
  private void renamePrompt(PixelRealmState.FileObject probject) {
    renamePrompt(probject, file.directorify(file.getDir(probject.dir)));
  }
  
  
  private void renamePrompt(PixelRealmState.FileObject probject, String newDir) {
    
        Runnable r = new Runnable() {
          public void run() {
            if (engine.promptInput.length() == 0) {
              return;
            }
            String newFilename = engine.promptInput;
            
            String newPath = newDir+newFilename;
            
            if (file.exists(newPath)) {
              //prompt("Can't rename file", newFilename+" already exists. Please choose a different name.");
              
              Runnable rno = new Runnable() {
                public void run() {
                  closeMenu();
                }
              };

              Runnable ryes = new Runnable() {
                public void run() {
                  issueRefresherCommand(REFRESHER_PAUSE);
                  
                  String oldpath = probject.dir;
                  
                  boolean successful = true;
                  
                  // Rename existing item to temp name so we don't replace it
                  successful &= file.mv(newPath, newPath+"-tempname");
                  
                  // Rename current item
                  if (successful) successful &= file.mv(oldpath, newPath);
                  
                  // Rename existing item to old name
                  if (successful) successful &= file.mv(newPath+"-tempname", oldpath);
                  
                  if (successful) {
                    // Need to refresh cus too lazy to get the right PRObjects.
                    currRealm.saveRealmJson();
                    currRealm.refreshFiles();
                    console.log("Swapped file names "+file.getFilename(oldpath)+" and "+file.getFilename(newPath));
                  }
                  else {
                    console.warn("Couldn't swap file names: "+file.getFileError());
                  }
                  closeMenu();
                }
              };
              menu = new YesNoMenu("Can't rename file", newFilename+" already exists. Want to swap the file names?", ryes, rno);
              
              return;
            }
            
            
            issueRefresherCommand(REFRESHER_PAUSE);
            if (file.mv(probject.dir, newPath)) {
              probject.dir = newPath;
              probject.filename = file.getFilename(newPath);
              console.log("File renamed to "+file.getFilename(newPath));
            }
            else {
              console.warn("Couldn't rename item: "+file.getFileError());
            }
            
            sound.playSound("menu_select");
            
            closeMenu();
          }
        };
  
        beginInputPrompt("Rename to:", r);
        if (probject.filename.contains(".")) {
          engine.promptInput = "."+file.getExt(probject.filename);
          input.cursorX = 0;
        }
  }
  
  // Stops the cassette music from playing if the specified file is indeed playing.
  private void cassetteCheck(String filename) {
    if (cassettePlaying.equals(filename)) {
      sound.stopMusic();
      sound.streamMusic(currRealm.musicPath);
      cassettePlaying = "";
      delay(100);  // Don't care about the delay you won't notice a thing (probably)
    }
  }
  
  
  class FileOptionsMenu extends TitleMenu {
    private String filename = "";
    private PixelRealmState.FileObject probject = null;
    
    public FileOptionsMenu(PixelRealmState.FileObject o) {
      super("", "back-fileoptionsmenu");
      this.probject = o;
      this.filename = file.getFilename(probject.dir);
      
      if (filename.length() > 38) {
        this.title = filename.substring(0, 36)+"...";
      }
      else {
        this.title = filename;
      }
    }
    
    
    
    
    public void display() {
      super.display();
      if (ui.buttonVary("op-delete", "recycle_256", "Delete")) {
        sound.playSound("menu_select");
        
        issueRefresherCommand(REFRESHER_PAUSE);
        
        cassetteCheck(this.filename);
        if (file.recycle(probject.dir)) {
          currRealm.poofAt(probject);
          probject.destroy();
          sound.playSound("poof");
          console.log(filename+" moved to recycle bin.");
        }
        else {
          console.warn("Failed to recycle item: "+file.getFileError());
        }
        
        closeMenu();
      }
      if (ui.buttonVary("op-rename", "rename_256", "Rename")) {
        sound.playSound("menu_select");
        
        renamePrompt(probject);
        //closeMenu();
      }
      if (ui.buttonVary("op-duplicate", "copy_256", "Copy")) {
        sound.playSound("menu_select");
        
        
        // TODO: Files may take a while to copy. Run this in a separate thread.
        if (hotbar.size() < HOTBAR_LIMIT) {
          issueRefresherCommand(REFRESHER_PAUSE);
          String copypath = file.duplicateFile(probject.dir);
          if (copypath != null) {
            console.log("Duplicated "+probject.filename+".");
            
            // Call load here on our new probject so that yknow it loads (bug fix)
            currRealm.createPRObjectAndPickup(copypath).load(new JSONObject());
            currentTool = TOOL_GRABBER;
          }
          else {
            errorPrompt("Could not copy", "Failed to copy the item. Maybe permissions have been denied?");
          }
        }
        else {
          console.log("Your hotbar is full! Remove some items from your hotbar before creating new files.");
        }
        
        
        closeMenu();
      }
      
      if (this.probject instanceof PixelRealmState.EntryFileObject) {
        if (ui.buttonVary("op-openreadonly", "lock_128", "Read only")) {
          sound.playSound("menu_select");
          file.openEntryReadonly(this.probject.dir);
          closeMenu();
        }
      }
    }
    
    public void close() {
      optionHighlightedItem = null;
    }
  }
  

  class CreatorMenu extends Menu {
    public CreatorMenu() {
    }
    public void display() {
      displayBackground("back-creatormenu");
      if (ui.buttonVary("newentry", "new_entry_128", "New entry")) {
        sound.playSound("menu_select");
        newEntry();
      }


      if (ui.buttonVary("newfolder", "new_folder_128", "New folder")) {
        if (hotbar.size() < HOTBAR_LIMIT) {
          sound.playSound("menu_select");
          newFolder();
        }
        else {
          errorPrompt("Hotbar full", "Your hotbar is full! Please remove some items before creating a shortcut.");
        }
          
      }

      if (ui.buttonVary("newshortcut", "create_shortcut_128", "New shortcut")) {
        if (hotbar.size() < HOTBAR_LIMIT) {
          sound.playSound("menu_select");
          issueRefresherCommand(REFRESHER_PAUSE);
          ((PixelRealmState.ShortcutPortal)currRealm.createPRObjectAndPickup(currRealm.createShortcut())).loadShortcut();
        }
        else {
          console.log("Your hotbar is full! Please remove some items before creating a shortcut.");
        }
        menuShown = false;
      }
    }

    public void newFolder() {
      sound.playSound("menu_select");

      Runnable r = new Runnable() {
        public void run() {
          if (engine.promptInput.length() == 0) {
            return;
          }
          String folderpath = currRealm.stateDirectory+engine.promptInput;
          if (!file.exists(folderpath)) {
            issueRefresherCommand(REFRESHER_PAUSE);
            new File(folderpath).mkdirs();
            stats.increase("folders_created", 1);
          } else {
            sound.playSound("nope");
            console.log(engine.promptInput+" already exists!");
            menuShown = false;
            menu = null;
            return;
          }

          currRealm.createPRObjectAndPickup(folderpath);
          currentTool = TOOL_GRABBER;

          menuShown = false;
          sound.playSound("menu_select");
        }
      };

      if (hotbar.size() < HOTBAR_LIMIT) {
        beginInputPrompt("Folder name:", r);
      }
      else {
        console.log("Your hotbar is full! Please remove some items before creating a shortcut.");
        menuShown = false;
      }
    }

    public void newEntry() {
      sound.playSound("menu_select");

      Runnable r = new Runnable() {
        public void run() {
          if (engine.promptInput.length() == 0) {
            menuShown = false;
            return;
          }

          String path = currRealm.stateDirectory+engine.promptInput+"."+engine.ENTRY_EXTENSION;
          if (file.exists(path)) {
            sound.playSound("nope");
            console.log(engine.promptInput+" already exists!");
            menuShown = false;
            menu = null;
            return;
          }

          // Create a new empty file so that we can hold it and place it down, editor will handle the rest.
          try {
            issueRefresherCommand(REFRESHER_PAUSE);
            FileWriter emptyFile = new FileWriter(path);
            emptyFile.write("");
            emptyFile.close();
            stats.increase("entries_created", 1);
          }
          catch (IOException e2) {
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

      if (hotbar.size() < HOTBAR_LIMIT) {
        beginInputPrompt("Entry name:", r);
      }
      else {
        console.log("Your hotbar is full! Please remove some items before creating an entry.");
        menuShown = false;
      }
    }
  }
  
  

  class TerrainMenu extends Menu {
    public TerrainMenu() {
    }
    public void display() {
      displayBackground("back-terrainmenu");
      if (ui.buttonVary("lighting", "lightbulb_128", "Look & feel")) {
        sound.playSound("menu_select");
        lighting();
      }


      if (ui.buttonVary("terraformer", "terraformer_128", "Terraform")) {
        sound.playSound("menu_select");
        terraformer();
      }
    }
    
    private void lighting() {
        if (currRealm.versionCompatibility == 1) {
          menu = new DialogMenu("Can't use lighting", "back-newrealm", "You can't customise lighting in older 1.x versions. Please upgrade realm via the terraformer.");
        }
        else {
          menu = new CustomiseLookAndFeelMenu();
        }
    }
    
    private void terraformer() {
        Runnable ryes = new Runnable() {
          public void run() {
            menu = new CustomiseTerrainMenu();
            menuShown = true;
            currRealm.terraformWarning = false;
          }
        };

        Runnable rno = new Runnable() {
          public void run() {
            menuShown = true;
            menu = new MainMenu();
          }
        };

        if (currRealm.terraformWarning) {
          menu = new YesNoMenu("Warning", "Modifying the terrain generator will reset all the terrain in this realm.\nContinue?", ryes, rno);
        } else {
          menu = new CustomiseTerrainMenu();
          menuShown = true;
          currRealm.terraformWarning = false;
        }
    }
  }
  
  
  
    
    
  // Just our own exception class to get the heckk outta here when things go wrong while loading.
  private class PocketPanicException extends RuntimeException {
    public static final int ERR_UNKNOWN = 0;
    public static final int ERR_TOO_FULL = 1;
    private int err = 0;
    public PocketPanicException(int err) {
      super();
      this.err = err;
    }
    
    public int getErr() {
      return err;
    }
  }
  
  
  // Pocket menu tab plans:
  //  Hotbar
  //  Realm assets
  //  Files in Pixelrealm
  
  // REMINDER NOTES THAT I REALLY HOPE YOU'LL SEE:
  // - When removing items, remember- 
  // pitem.item.destroy(); (the override method will remove it from the files list)
  
  // TODO: There is a bug where hotbar is cleared after closing menu.

  class PocketMenu extends Menu {
    
    private Grid pocketsGrid;
    private Grid hotbarGrid;
    private Grid realmGrid;
    private Grid filesGrid;
    
    private JSONObject pocketInfo;
    
    private PocketItem draggingItem = null;
    
    // When the user moves an item in the grid, it might go back to the original position or swap places
    // with another item. For this, we need to know the original location where the item moved from,
    // which is kinda overly complicated since we need to know which grid and square ID we moved from.
    private Grid originalGridLocation = null;
    private int originalCellLocation = 0;
    protected int itemIndex = 0;
    private boolean stickItemToMouse = false;
    protected Grid currGrid = null;
    private String promptMessage = null; // When this is null, prompt is hidden
    private boolean showInputField = false;
    private String promptInput = "";
    private Runnable promptInputRunWhenEnter = null;
    
    private String hoverLabel = null;
    private color  hoverLabelColor = color(0);
    
    private boolean keyDelay = true;
    private float doubleClickTimer = 0f;
    private boolean switchToGrabberOnExit = false;
    private boolean preventShiftClick = false;
    
    private long prevMemUsage = 0L;
    
    
    // dummy pocketitems for some weird quirks for the grid
    private PocketItem blankCellDummy = new PocketItem("blank", true);
    
    
    
    private class Grid {
      private float scroll = 0;
      private Runnable moveInAction = null;
      private Runnable shiftMoveToAction = null;
      
      // Set this if you want a lil space between your rows.
      public float verticalSpacing = 0f;
      public boolean refreshRealmWhenFileDeletedFlag = false;  // This is used as a cheap way to refresh the realm when a realm asset is deleted in the realm grid.
      public boolean allowRename = true;  // Another cheap way to allow/disallow renaming in the realm grid.
      
      public PocketItem[] grid;
      
      public Grid(int size) {
        grid = new PocketItem[size];
      }
      
      // Runnable to execute when an item is placed into a cell in the grid.
      public void setMoveInAction(Runnable r) {
        moveInAction = r;
      }
      public void setShiftMoveToAction(Runnable r) {
        shiftMoveToAction = r;
      }
      
      public void runMoveInAction() {
        if (moveInAction != null) {
          moveInAction.run();
        }
      }
      
      public void reset() {
        for (int i = 0; i < grid.length; i++) {
          if (grid[i] != null && !grid[i].isWeird) {
            grid[i] = null;
          }
        }
      }
      
      public void insert(ArrayList<PocketItem> arr) {
        for (int i = 0; i < arr.size(); i++) {
          grid[i] = arr.get(i);
        }
      }
      
      public int findFreeCell() {
        for (int i = 0; i < grid.length; i++) {
          if (grid[i] == null) {
            return i;
          }
        }
        
        // If we cannot find a free cell, time to raise the alarms.
        // And by that, I mean open a prompt and tell the user to solve the problem themselves.
        throw new PocketPanicException(PocketPanicException.ERR_TOO_FULL);
      }
      
      
      public void insertIntoFreeCell(PocketItem pitem) {
        grid[findFreeCell()] = pitem;
      }
      
      public void load(int coll) {
        file.mkdir(engine.APPPATH+engine.POCKET_PATH);
        
        HashSet<Integer> takenCells = new HashSet<Integer>();
        
        // God I really need to move this functionality to the engine code.
        File[] pocketFolder = (new File(engine.APPPATH+engine.POCKET_PATH)).listFiles();
          for (File f : pocketFolder) {
            String path = f.getAbsolutePath().replaceAll("\\\\", "/");
            String name = file.getFilename(path);
            if (name.equals(POCKET_INFO)) continue;
            
            JSONObject o = pocketInfo.getJSONObject(name);
            if (o != null) {
              // "coll" : 2  means it's in the hotbar
              if (o.getInt("coll", 1) == coll) {
                
                int freeSpot = 0;
                if (o.isNull("loc")) freeSpot = findFreeCell();
                
                // If an item has the same cell location as another item, it will simply override the previous item,
                // making it appear as if it never existed in the dir (even tho it does exist in the pockets folder)
                // so overlaps need to be dealt with.
                // There are points in the program (especially with swapping files in the realms tab) where files might
                // be moved to the same cells as other items because of nested moves and errors occuring, so this is
                // pretty important when those errors occur.
                int cell = o.getInt("loc", freeSpot);
                if (takenCells.contains(cell)) { 
                  // Space taken, find a random spot instead.
                  cell = findFreeCell();
                }
                grid[cell] = currRealm.loadPocketItem(path);
                takenCells.add(cell);
              }
            }
            // If not found in the JSON file and we're loading the pocket, find a slot in the inventory for it.
            else if (coll == 1) {
              int cell = findFreeCell();
              grid[cell] = currRealm.loadPocketItem(path);
              takenCells.add(cell);
            }
        }
      }
      
      // For the following two methods below (setBlankCell and setLabelledCell), you should NEVER
      // use it in the pocket grid or the hotbar grid or otherwise any grid where items are kept in the pocket folder.
      public void setBlankCell(int index) {
        grid[index] = blankCellDummy;
      }
      
      public void setBlankCell(int fro, int to) {
        for (int i = fro; i <= to; i++) {
          grid[i] = blankCellDummy;
        }
      }
      
      public void setLabelledCell(int index, String txt) {
        grid[index] = new PocketItem(txt, true);
      }
      
      public void display(float gridx, float gridy, float wi, float hii) {
        final int SLOTS_WI = 18;
        
        // Vars for square size calculation.
        float squarewihi = (wi-90f)/SLOTS_WI;
        int ly = int(grid.length/SLOTS_WI);
        
        float bottom = ly*(squarewihi + verticalSpacing);
        
        // Scroll, use special functionality in that we're always processing the scroll, but only receiving wheel inputs when
        // mouse is in area. This will keep the grids animated even if we're switching between the grids
        if (!promptShown()) {
          scroll = input.processScroll(scroll, 10f, bottom-hii+10f, ui.mouseInArea(gridx, gridy, (squarewihi + verticalSpacing)*SLOTS_WI+5f, hii));
        }
        
        if (!input.primaryDown) preventShiftClick = false;
        
        // Limit viewspace of grid
        display.clip(gridx, gridy, squarewihi*SLOTS_WI+5f, hii);
        // Now draw each square
        for (int y = 0; y < ly; y++) {
          float actualy = gridy + y * (squarewihi + verticalSpacing) + scroll+2f;
          
          if (actualy > gridy-squarewihi && actualy < gridy+hii) {
            for (int x = 0; x < SLOTS_WI; x++) {
              int i = y*SLOTS_WI+x;
              
              // End at the end of the grid
              if (i >= grid.length) {
                break;
              }
              
              // Weirdass special conditions for custom cells.
              if (grid[i] != null && grid[i].isWeird) {
                // This one leaves a gap if it's using the blank dummy.
                if (grid[i] == blankCellDummy) {
                  continue;
                }
                
                // Otherwise, display all others as text.
                app.fill(255f);
                app.textFont(engine.DEFAULT_FONT, 26f);
                app.textAlign(LEFT, CENTER);
                app.text(grid[i].name, gridx + x * squarewihi+5f, actualy+squarewihi*0.5f);
                continue;
              }
              
              // This one draws text 
              
              // Draw cell (empty so far)
              app.stroke(80f);
              app.fill(67f, 127f);
              app.strokeWeight(1f);
              app.rect(gridx + x * squarewihi, actualy, squarewihi, squarewihi);
              
              
              app.noStroke();
              
              
              // Here, we execute user input logic on the current item (as well as display it)
              PocketItem pitem = grid[i];
              if (pitem != null && pitem.item != null) {
                pitem.displayIcon(gridx + x * squarewihi, actualy, squarewihi);
              }
              
              // Mouse hovers over square.
              if (ui.mouseInArea(gridx + x * squarewihi, actualy, squarewihi, squarewihi) && (input.mouseY() < gridy+hii) && (input.mouseY() >= gridy) && !promptShown()) {
                // Show item name
                if (pitem != null) {
                  hoverLabel = pitem.name;
                  if (pitem.abstractObject) {
                    hoverLabelColor = color(255, 130, 130, 255);
                  }
                  else {
                    hoverLabelColor = color(255);
                  }
                  
                  // TODO: Duplicate highlight color red and add "(duplicate)" when i fix that thing.refresh();
                }
                
                // Highlight item
                app.fill(255f, 60f);
                app.rect(gridx + x * squarewihi, actualy, squarewihi, squarewihi);
                
                
                //if (input.primaryOnce) {
                //  console.log(i);
                //}
                
                // Pick up item when clicked & held
                if ((input.primaryOnce || (input.shiftDown && input.primaryDown)) && grid[i] != null && !stickItemToMouse) {
                  
                  // If shift pressed, run special move action.
                  if (input.shiftDown) {
                    // The !preventShiftClick prevents the action from executing every frame.
                    if (!preventShiftClick) {
                      //console.log("Shift-click action");
                      draggingItem = grid[i];
                      originalGridLocation = this;
                      originalCellLocation = i;
                      grid[i] = null;
                      
                      stickItemToMouse = false;
                      
                      if (shiftMoveToAction != null) shiftMoveToAction.run();
                    }
                  }
                  // If double-clicked, open file
                  else if (doubleClickTimer > 0f && pitem != null && pitem.item != null && pitem.item instanceof PixelRealmState.FileObject) {
                    // TODO: This is an awful solution.
                    if (pitem.item instanceof PixelRealmState.MusicFileObject) {
                      playCassette(((PixelRealmState.FileObject)pitem.item).dir);
                    }
                    else {
                      file.open(((PixelRealmState.FileObject)pitem.item).dir);
                    }
                  }
                  // If single clicked, begin to drag & move file.
                  else {
                    draggingItem = grid[i];
                    originalGridLocation = this;
                    originalCellLocation = i;
                    doubleClickTimer = 15f;
                    grid[i] = null;
                    sound.playSound("pocket_pickup");
                  }
                }
                
                
                // Show options when right-clicked.
                if (input.secondaryOnce && grid[i] != null && pitem != null) {
                  
                  if (!pitem.abstractObject) {
                    
                    // If we're in the realm grid (or allowRename is false), only create 2 options (ommitting the "rename" option)
                    String[] labels;
                    Runnable[] actions;
                    
                    if (allowRename) {
                      labels = new String[4];
                      actions = new Runnable[4];
                    }
                    else {
                      labels = new String[3];
                      actions = new Runnable[3];
                    }
                    
                    labels[0] = "Open";
                    actions[0] = new Runnable() {public void run() {
                        if (pitem.item instanceof PixelRealmState.MusicFileObject) {
                          playCassette(((PixelRealmState.FileObject)pitem.item).dir);
                        }
                        else {
                          file.open(((PixelRealmState.FileObject)pitem.item).dir);
                        }
                    }};
                    
                    
                    
                    labels[1] = "Copy";
                    actions[1] = new Runnable() {public void run() {
                        rpause();
                      
                        String name = file.getFilename(pitem.getPath());
                        String copypath = file.duplicateFile(pitem.getPath(), engine.APPPATH+engine.POCKET_PATH+renamePixelrealmFile(name));
                        if (copypath != null) {
                          console.log("Duplicated "+pitem.name+".");
                          draggingItem = currRealm.loadPocketItem(copypath);
                          stickItemToMouse = true;
                        }
                        else {
                          console.warn("Failed to duplicate file.");
                        }
                        
                    }};
                    
                    
                    
                    final int index = i;
                    
                    // We want delete (the unsafest option) to always be at the bottom, but sometimes "rename" can appear instead,
                    // so shuffle it to the bottom so "rename" can take its place.
                    int labelPos = 2;
                    if (allowRename) labelPos = 3;
                    
                    labels[labelPos] = "Delete";
                    actions[labelPos] = new Runnable() {public void run() {
                        rpause();
                      
                        // Sound file check:
                        cassetteCheck(pitem.name);
                        
                        // Checks for .pixelrealm-bgm
                        // If the music is playing in the background, stop that music.
                        if (currRealm.musicPath.equals(pitem.getPath())) {
                          playDefaultMusic();
                        }
                        
                        boolean success = file.recycle(pitem.getPath());
                        
                        if (!success) {
                          console.warn("Could not recycle "+pitem.name+": "+file.getFileError());
                        }
                        else {
                          // Destroy probject associated with pitem
                          if (pitem.item != null) pitem.item.destroy();
                          // Remove item from hotbar (because tho hotbar will reload it will keep unsynced items)
                          hotbar.remove(pitem);
                          
                          console.log(pitem.name+" moved to recycle bin.");
                          grid[index] = null;
                          sound.playSound("poof");
                          
                          if (refreshRealmWhenFileDeletedFlag) currRealm.loadRealmAssets();
                        }
                        
                    }};
                    
                    
                    // Only add to options if renaming is allowed as a grid option.
                    if (allowRename) {
                      labels[2] = "Rename";
                      actions[2] = new Runnable() {public void run() {
                          rpause();
                          showInputField = true;
                          promptMessage = "Rename to:";
                          showInputField = true;
                          
                          if (pitem.name.contains(".")) {
                            promptInput = "."+file.getExt(pitem.name);
                            input.cursorX = 0;
                          }
                          else {
                            promptInput = "";
                          }
                          
                          promptInputRunWhenEnter = new Runnable() {
                            public void run() {
                              final PocketItem thisitem = pitem;
                              renameFileAction(promptInput, thisitem);
                            }
                          };
                      }};
                    }
                    
                    
                    ui.createOptionsMenu(labels, actions);
                  }
                }
                
                boolean drop = false;
                
                // Drop an item into a cell when mouse released.
                // If the cell is blank, place the item there.
                // If the cell has an existing item, swap it.
                // However, there will be exceptions with different file types later on.
                if (stickItemToMouse) {
                  drop = (draggingItem != null && input.primaryOnce && !promptShown() && grid[i] == null);
                }
                else {
                  drop = (draggingItem != null && input.primaryReleased && !promptShown());
                }
                
                if (drop) {
                  itemIndex = i;
                  currGrid = this;
                  stickItemToMouse = false;
                  runMoveInAction();
                }
              }
              
              i++;
            }
          }
        }
        
        display.noClip();
      }
    }
    
    final int POCKET = 1;
    final int HOTBAR = 2;
    final int REALM = 2;
    final int FILES = 2;
    
      
    final int SKY_TEXTURE_SLOT = 6;
    final int TREE_TEXTURE_SLOT = 24;
    final int GROUND_TEXTURE_SLOT = 42;
    final int MUSIC_SLOT = 60;
    final int PLUGIN_SLOT = 96;
    
    public void refresh() {
      // Save first
      app.saveJSONObject(pocketInfo, engine.APPPATH+engine.POCKET_PATH+POCKET_INFO);
      
      try {
        // Reload first!
        currRealm.loadHotbar();
        pocketInfo = openPocketsFile();
        
        
        // Pocket
        pocketsGrid.reset();
        pocketsGrid.load(1);
        
        // Hotbar
        hotbarGrid.reset();
        hotbarGrid.insert(hotbar);
        
        // Realm
        realmGrid.reset();
        loadRealmGrid();
      }
      catch (PocketPanicException e) {
        handlePocketPanic(e);
      }
    }
    
    private void rpause() {
      issueRefresherCommand(REFRESHER_PAUSE);
    }
    
    public PocketMenu() {
      super();
      
      // Outofmem protection features can prevent our files from loading
      // if we open and close the menu too much. So we must restore the state
      // of memusage when we close the menu.
      prevMemUsage = memUsage.get();
      
      // Open pocket info. Will be saved when window closes.
      pocketInfo = openPocketsFile();
      
      // Initialise pocketsgrid
      pocketsGrid = new Grid(288);
      
      Runnable rpockets = new Runnable() {public void run() {
        // Just to avoid the refresher twice when swapping.
        itemToSwap = null;
        
        // Only do the rest of this run statement if we're moving from a different grid.
        // No need to run pocketMove for items already in the pockets.
        if (originalGridLocation == pocketsGrid) {
          beginSwapIfOccupied();
          moveItemToNewCell(POCKET);
          
          performSwap();
          return;
        }
        
        
        
        // if we're moving from the realm tab, we do an extra step:
        // rename the file. Simply changing pocketItem.name will do the trick (I hope)
        String moveName = draggingItem.name;
        //boolean moveMusic = false;
        if (originalGridLocation == realmGrid) {
          moveName = renamePixelrealmFile(draggingItem.name);
          moveName = duplicateCheck(moveName);
          
          // Release music handles while we're at it.
          if (moveName.contains("BGM")) {
            //moveMusic = true;
            playDefaultMusic();
          }
        }
        
        rpause();
        
        // Move the item
        // This will effectively move the item from the current realm to the pockets folder.
        if (draggingItem.pocketMove(currRealm.stateDirectory, moveName)) {
          // Valid move operation...
          
          // If we're moving from hotbar etc then we don't do anything extra. If we're interacting with the realms grid however,
          // we're refreshing the realm assets.
          // Definitely not the most efficient approach in terms of performance.
          // But certainly the most secure and bug-free.
          if (originalGridLocation == realmGrid) {
            //if (currGrid.grid[itemIndex] != null) {
            //  prompt("Not implemented yet!");
            //  return;
            //}
            beginSwapIfOccupied();
            
            // Refresh
            currRealm.loadRealmAssets();
            
            //if (moveMusic) {
              //sound.streamMusicWithFade(currRealm.musicPath);
            //}
            
            moveItemToNewCell(POCKET);
          }
          else {
            // If there's an existing item in the cell...
            // Swap places (move the item to the original cell)
            beginSwapIfOccupied();
            moveItemToNewCell(POCKET);
          }
        }
        else {
          // Error, show prompt (done by pocketMove), and return item to original cell...
          returnDraggingItemToOriginalCell();
          return;
        }
        
        performSwap();
      }};
      pocketsGrid.setMoveInAction(rpockets);
      
      
      // When the user shift clicks the item, we move from pockets to whichever tab is selected:
      
      // - Hotbar tab: simply find a free spot and call it a day.
      
      // - Realm tab: depends on the file:
      //   - wide (1500 pixels) image:   sky tab
      //   - small and has transparency: tree tab
      //   - otherwise: grass tab
      //   - If grass tab is already full: find any free tab, sky, tree.
      //   - Music file: obviously the music slot.
      //   - No slots are available: console message and don't do anything.
      Runnable shiftMovePocketsAction = new Runnable() {public void run() {
        final int TAB_HOTBAR = 0;
        final int TAB_REALM  = 1;
        final int TAB_FILES  = 2;
        
        
        switch (selectedPocketTab) {
          case TAB_HOTBAR:
          try {
            // We gotta set these for ourselves.
            itemIndex = hotbarGrid.findFreeCell();
            currGrid = hotbarGrid;
            moveItemToNewCell(HOTBAR);
            
            switchToGrabberOnExit = true;
          }
          catch (PocketPanicException e) {
            // Do nothing and just print an exception thing.
            console.log("No more space in hotbar!");
            returnDraggingItemToOriginalCell();
            preventShiftClick = true;
          }
          break;
          
          case TAB_REALM:
          currGrid = realmGrid;
          itemIndex = -1;
          
          // Images
          if (file.isImage(draggingItem.name) && (draggingItem.item instanceof PixelRealmState.ImageFileObject)) {
            PImage img = ((PixelRealmState.ImageFileObject)draggingItem.item).img.get();
            
            
            // Time for some analysis
            // Check for width of 1500
            // Except the image we're checking is actually cached.
            // So instead, check for 512x75 or 512x102
            if (img.width == 512 && (img.height == 75 || img.height == 102)) {
              // sky 
              itemIndex = realmGridFindFreeSlot(SKY_TEXTURE_SLOT, SKY_TEXTURE_SLOT+9);
            }
            else if (img.width <= 256 && img.height <= 256 && hasTransparency(img)) {
              // tree 
              itemIndex = realmGridFindFreeSlot(TREE_TEXTURE_SLOT, TREE_TEXTURE_SLOT+9);
            }
            else if (realmGrid.grid[GROUND_TEXTURE_SLOT] == null) {
              itemIndex = GROUND_TEXTURE_SLOT;
            }
            
            // Attempt to find any slot to place the item in if no condition above could be met (or the slots were full).
            if (itemIndex == -1) {
              itemIndex = realmGridFindFreeSlot(SKY_TEXTURE_SLOT, SKY_TEXTURE_SLOT+9);
              if (itemIndex == -1) itemIndex = realmGridFindFreeSlot(TREE_TEXTURE_SLOT, TREE_TEXTURE_SLOT+9);
              if (itemIndex == -1 && realmGrid.grid[GROUND_TEXTURE_SLOT] == null) itemIndex = GROUND_TEXTURE_SLOT;
            }
            
            
          }
          // End image check
          
          else if (file.isAudioFile(draggingItem.name)) {
            if (currGrid.grid[MUSIC_SLOT] == null) itemIndex = MUSIC_SLOT;
          }
          
          // Slot has been found
          if (itemIndex != -1) {
            rpause();
            // rename the file to .pixelrealm- (etc), if successful move item and perform swaps if necessary.
            if (moveIntoRealmFileSlot()) {
              moveItemToNewCell(REALM);
            }
            else {
              // If the move fails, we have a complicated situation because if we swapped the file, there's no easy way to
              // undo those changes. At least not without getting tangled in spaghetti code.
              // Easiest thing to do is to refresh the whole menu. It won't be as good as undoing it, but the swapped item
              // will be in a different slot in the pockets and all our items will be displayed correctly (without cells overlapping)
              // at the very least.
              returnDraggingItemToOriginalCell();
              refresh();
            }
          }
          // Typical indicator of all slots being full
          else {
            console.log("No available slots!");
            returnDraggingItemToOriginalCell();
            preventShiftClick = true;
          }
            
          break;
          case TAB_FILES:
          
          break;
        }
      }};
      
      pocketsGrid.setShiftMoveToAction(shiftMovePocketsAction);
      
      pocketsGrid.load(1);
      
      
      
      
      
      // Next our hotbar grid.
      hotbarGrid = new Grid(HOTBAR_LIMIT);
      
      Runnable rhotbar = new Runnable() {public void run() {
        itemToSwap = null;
        // Here, if we swap an item and it goes into the pocket, then this item will be required to 
        // undergo the same operation as moving an item into the pocket.
        if (currGrid.grid[itemIndex] != null) {        // Check we are moving it into an occupied slot
          if (originalGridLocation == pocketsGrid) { // check that we are indeed moving it into the pockets grid and call pocketMove
            rpause();
            if (currGrid.grid[itemIndex].pocketMove(currRealm.stateDirectory)) {
              beginSwapIfOccupied();         // Swap places
              moveItemToNewCell(HOTBAR);      // Move the current item.
              switchToGrabberOnExit = true;
            }
            else {
              returnDraggingItemToOriginalCell();
              return;
            }
          }
          else { // Condition here is that this is not the pockets grid (it's a different cell in the same grid). No need to call pocketMove.
            beginSwapIfOccupied();
            moveItemToNewCell(HOTBAR);
          }
        }
        // Move item from pocket to hotbar
        else {
          moveItemToNewCell(HOTBAR);
          switchToGrabberOnExit = true;
        }
        
        performSwap();
      }};
      hotbarGrid.setMoveInAction(rhotbar);
      
      
      Runnable shiftMoveHotbarAction = new Runnable() {public void run() {
        String moveName = draggingItem.name;
        currGrid = pocketsGrid;
        
        try {
          // We gotta set these for ourselves.
          itemIndex = pocketsGrid.findFreeCell();
          currGrid = pocketsGrid;
          
          // Move item into pocket (will sync item if unsynced)
          rpause();
          if (draggingItem.pocketMove(currRealm.stateDirectory, moveName)) {
            moveItemToNewCell(POCKET);
          }
          else {
            // Nothing... pocketMove will show the prompt.
          }
        }
        catch (PocketPanicException e) {
          console.log("No more space in pockets!");
          returnDraggingItemToOriginalCell();
          preventShiftClick = true;
        }
      }};
      hotbarGrid.setShiftMoveToAction(shiftMoveHotbarAction);
      
      
      // Process our hotbar and insert it into our grid
      hotbarGrid.insert(hotbar);
      
      
      
      
      
      // Our realm grid next.
      realmGrid = new Grid(18*6);
      
      realmGrid.verticalSpacing = 9f;
      realmGrid.refreshRealmWhenFileDeletedFlag = true;
      realmGrid.allowRename = false;
      
      // Setup the labels and slots.
      realmGrid.setLabelledCell(0,"Sky texture");   
      realmGrid.setBlankCell(1, 5);                   // Clean area around label
      realmGrid.setBlankCell(15, 17);                 // Clean extra slots after 9 sky slots
      realmGrid.setLabelledCell(18,"Tree texture");
      realmGrid.setBlankCell(19, 23);                 // Clean area around label
      realmGrid.setBlankCell(33, 35);                 // Clean extra slots after 9 tree slots
      realmGrid.setLabelledCell(36,"Ground texture");
      realmGrid.setBlankCell(37, 41);                 // Clean area around label
      realmGrid.setBlankCell(43, 53);                 // Clean extra slots after 1 ground slot
      realmGrid.setLabelledCell(54,"Music");
      realmGrid.setBlankCell(55, 59);                 // Clean area around label
      realmGrid.setBlankCell(61, 71);                 // Clean extra slots after 1 music slot
      
      realmGrid.setBlankCell(72, 89);          // Clean whole row as a gap for the plugin
      realmGrid.setLabelledCell(90,"Plugin");         // Clean area around label
      realmGrid.setBlankCell(91, 95);
      realmGrid.setBlankCell(97, 107);                // Clean extra slots after 1 plugin slot
      
      
      
      
      
      // This one is complex, because here we're actually moving an item out of the pockets.
      Runnable rrealmgrid = new Runnable() {public void run() {
        boolean isSwap = false; // For properly calling refresh() when slot check fails during file swap.
        if (itemToSwap != null) isSwap = true;
        itemToSwap = null;
        
        // Perform initial slot check first
        // dont ask why its a string lmao.
        String slotCheckRes = checkRealmFileSlot();
        if (slotCheckRes != null) { // Non-null means success.
          
          // Now we need to know whether we're moving from pocket to realm grids
          // or moving an item in the realm grid (not moving it from the pocket grid)
          // Swapping 2 items in the realm grid comes with complications.
          
          // Swap 2 items in realm grid
          if (originalGridLocation == realmGrid && currGrid == realmGrid) {
            // Don't do anything if it's the same cell (click and then immediately release)
            if (originalCellLocation != itemIndex) {
              rpause();
              
              // There are 2 different ways we move it here:
              // 1. Move to an empty slot in the realmGrid
              // 2. Swap 2 items in realmGrid.
              
              // 1. Move to empty slot
              if (currGrid.grid[itemIndex] == null) {
                // Move the file (that's right, we're directly moving it)
                boolean success = file.mv(draggingItem.getPath(), file.directorify(currRealm.stateDirectory)+slotCheckRes);
                if (success) {
                  draggingItem.updatePath(file.directorify(currRealm.stateDirectory)+slotCheckRes);
                  moveItemToNewCell(REALM);
                  // Refresh dir
                  currRealm.loadRealmAssets();
                }
                else {
                  returnDraggingItemToOriginalCell();
                  prompt("Move failed: "+file.getFileError());
                }
              }
              
              // 2. Swap items.
              // Complicated, because we can't just swap filenames.
              // We have to go:
              // .pixelrealm-tree-1.png .pixelrealm-tree-2.png         Start
              // temp (1).png .pixelrealm-tree-2.png                   Placeholder name
              // temp (1).png .pixelrealm-tree-1                       Rename the second
              // .pixelrealm-tree-2 .pixelrealm-tree-1                 Rename the file with the placeholder name (first file)
              // Done!
              
              // If you think the placeholdername is overly complicated (i.e. why don't we just rename it to something like ".pixelrealm-tree-2.temp"??),
              // the reason is because if the move fails, then we'll need to undo our actions (which results in messy overly complex code), and if that fails,
              // we'll need to undo the undoing, etc. Too messy, too complicated.
              // So, should it fail, naming it to temp (1).png will keep the file visible, and will give the user the chance to fix the problem, without
              // worrying about hidden files and such.
              else {
                PocketItem file1 = draggingItem;
                PocketItem file2 = currGrid.grid[itemIndex];
                String rename1 = slotCheckRes;
                String rename2 = checkRealmFileSlot(file2, originalCellLocation);
                
                // Of course we need to check second item is going into valid swap space.
                // We'll get the prompt automatically from checkRealmFileSlot.
                if (rename2 == null) {
                  returnDraggingItemToOriginalCell();
                  refresh();
                  return;
                }
                
                // Rename to Placeholder name (renaming file 1)
                String dir = file.directorify(currRealm.stateDirectory);
                String placeholderName = file.duplicateCheck(dir+"Temp"+file.getExt(file1.name));
                if (!file.mv(file1.getPath(), placeholderName)) {
                  returnDraggingItemToOriginalCell();
                  prompt("There was an error while swapping the items: "+file.getFileError());
                  refresh();
                  return;
                }
                
                // Rename the second
                if (!file.mv(file2.getPath(), dir+rename2)) {
                  returnDraggingItemToOriginalCell();
                  prompt("There was an error while swapping the items: "+file.getFileError());
                  refresh();
                  return;
                }
                
                //Rename the file with the placeholder name (first file)
                if (!file.mv(placeholderName, dir+rename1)) {
                  returnDraggingItemToOriginalCell();
                  prompt("There was an error while swapping the items: "+file.getFileError());
                  refresh();
                  return;
                }
                
                file1.updatePath(dir+rename1);
                file2.updatePath(dir+rename2);
                
                originalGridLocation.grid[originalCellLocation] = file2;
                moveItemToNewCell(REALM);
                
                // Refresh dir
                currRealm.loadRealmAssets();
              }
            }
          }
          
          // Move item from pocket (potential swapping)
          else {
            rpause();
            realmGridSwap();
            
            // rename the file to .pixelrealm- (etc), if successful move item and perform swaps if necessary.
            if (moveIntoRealmFileSlot()) {
              moveItemToNewCell(REALM);
            }
            else {
              // If the move fails, we have a complicated situation because if we swapped the file, there's no easy way to
              // undo those changes. At least not without getting tangled in spaghetti code.
              // Easiest thing to do is to refresh the whole menu. It won't be as good as undoing it, but the swapped item
              // will be in a different slot in the pockets and all our items will be displayed correctly (without cells overlapping)
              // at the very least.
              returnDraggingItemToOriginalCell();
              refresh();
            }
          }
        }
        else { // If realm asset slot check fails.
          returnDraggingItemToOriginalCell();
          if (isSwap) {
            refresh();
          }
        }
        
      }};
      realmGrid.setMoveInAction(rrealmgrid);
      
      
      
      Runnable shiftMoveRealmAction = new Runnable() {public void run() {
        String moveName = draggingItem.name;
        currGrid = pocketsGrid;
        
        try {
          // We gotta set these for ourselves.
          itemIndex = pocketsGrid.findFreeCell();
          currGrid = pocketsGrid;
          
          // Move item into pocket (will sync item if unsynced)
          moveName = renamePixelrealmFile(draggingItem.name);
          moveName = duplicateCheck(moveName);
          if (moveName.contains("BGM")) {
            playDefaultMusic();
          }
          
          rpause();
          if (draggingItem.pocketMove(currRealm.stateDirectory, moveName)) {
            moveItemToNewCell(POCKET);
            currRealm.loadRealmAssets();
          }
          else {
            // Don't do anything here, prompt will appear automatically...
          }
        }
        catch (PocketPanicException e) {
          console.log("No more space in pockets!");
          returnDraggingItemToOriginalCell();
          preventShiftClick = true;
        }
      }};
      realmGrid.setShiftMoveToAction(shiftMoveRealmAction);
      
      
      loadRealmGrid();
      
      // Shouldn't need originalGridLocation but this is just to prevent a crash should there be a bug.
      originalGridLocation = pocketsGrid;
      
    }
    
    
    private boolean hasTransparency(PImage img) {
      img.loadPixels();
      for (int i = 0; i < img.pixels.length; i++) {
        if (alpha(img.pixels[i]) < 128) {
          return true;
        }
      }
      return false;
    }
    
    private int realmGridFindFreeSlot(int from, int to) {
      for (int i = from; i < to; i++) {
        if (realmGrid.grid[i] == null) return i; 
      }
      return -1;
    }
    
    
    private void loadRealmGrid() {
      
      // Setup the realm grid with existing items already in the pixelrealm.
      
      // Sky
      realmGrid.grid[SKY_TEXTURE_SLOT] = createRealmAssetPocketItem(".pixelrealm-sky");
      int strt = SKY_TEXTURE_SLOT+1;
      if (realmGrid.grid[SKY_TEXTURE_SLOT] == null) {
        strt = SKY_TEXTURE_SLOT;
      }
      int j;
      j = 1;
      for (int i = strt; i < SKY_TEXTURE_SLOT+9; i++) {
        realmGrid.grid[i] = createRealmAssetPocketItem(".pixelrealm-sky-"+(j++));
      }
      
      // Trees
      j = 1;
      for (int i = TREE_TEXTURE_SLOT; i < TREE_TEXTURE_SLOT+9; i++) {
        realmGrid.grid[i] = createRealmAssetPocketItem(".pixelrealm-tree-"+j);
        // Of course terrain_object still exists so check for that too if "tree" not found (backwards compatibility yayyyyy).
        if (realmGrid.grid[i] == null) {
          realmGrid.grid[i] = createRealmAssetPocketItem(".pixelrealm-terrain_object-"+j);
        }
        j++;
      }
      
      // Ground (or grass as the filenames call it)
      realmGrid.grid[GROUND_TEXTURE_SLOT] = createRealmAssetPocketItem(".pixelrealm-grass");
      
      // Realm bgm
      realmGrid.grid[MUSIC_SLOT] = createRealmAssetPocketItem(".pixelrealm-bgm", 1); // the 1 argument means it's a music file instead of a texture.
      
      // Annnnnd I'll do plugins later.
    }
    
    // Rename the file if a duplicate exists in the pocket.
    // If for example Sky-2.png already exists, rename it to Sky-2 (1).png, or Sky-2 (2).png etc.
    // Also yes I added it to the file module in the engine code but I wanna keep this one here
    // cus I don't wanna break things and can't be bothered to remove duplicate code.
    private String duplicateCheck(String original) {
      String filename = file.getIsolatedFilename(original);
      String ext = file.getExt(original);
      
      String newname = original;
      int i = 1;
      while (file.exists(engine.APPPATH+engine.POCKET_PATH+newname)) {
        newname = filename+" ("+i+")."+ext;
        i++;
      }
      
      return newname;
    }
    
    private void renameFileAction(String newFilename, PocketItem item) {
        
        // Nothing means don't do anything.
        if (newFilename.length() == 0) {
          promptMessage = null;
          return;
        }
        
        // Make new path with new input name.
        String newPath = file.directorify(file.getDir(item.getPath()))+newFilename;
        
        // File already exists (note: not really mandatory but not really a reason to remove it either)
        if (file.exists(newPath)) {
          prompt("The filename is still the same. Could not place item in realm, please try again with a different name.");
          return;
        }
        
        // Renaming file causes modification in dir, prevent realm refresh.
        rpause();
        
        // Attempt rename
        String oldName = item.name;
        if (file.mv(item.getPath(), newPath)) {
          console.log("File renamed to "+file.getFilename(newPath));
          item.updatePath(newPath);
          
          // Also must update the json pocket info with the new name
          // Honestly, if we implemented it perfectly, we would have to pass indexes
          // and collections and honestly it's not worth it, so if we don't have this
          // information, then it doesn't matter if the renamed item is misplaced.
          JSONObject jsonitem = pocketInfo.getJSONObject(oldName);
          if (jsonitem != null) {
            // At this point the name will be updated.
            pocketInfo.setJSONObject(item.name, jsonitem);
          }
          
          
          promptMessage = null;     // Close minimenu.
        }
        else {
          prompt("Couldn't rename item: "+file.getFileError());
        }
        
        sound.playSound("menu_select");
    }
    
    
    // For the realm grid specifically, because of problems with duplicate item names,
    // we need to complete the move of the swapped item first before we finish with our own item.
    // So that's exactly what this method does here. Of course, we need to restore our prior state before we continue.
    private void realmGridSwap() {
      // Temporarily store state
      int originalcelllocation_temp = originalCellLocation;
      int itemIndex_temp = itemIndex;
      Grid orignalgrid_temp = originalGridLocation;
      Grid currGrid_temp = currGrid;
      PocketItem dragging_temp = draggingItem;
      
      beginSwapIfOccupied();
      performSwap();
      
      originalCellLocation = originalcelllocation_temp;
      itemIndex = itemIndex_temp;
      originalGridLocation = orignalgrid_temp;
      currGrid = currGrid_temp;
      draggingItem = dragging_temp;
    }
    
    
    private String renamePixelrealmFile(String name) {
      String moveName = name;
      String ext = file.getExt(name);
      if (file.getIsolatedFilename(file.unhide(name)).equals("pixelrealm-sky")) moveName = "Sky-1."+ext;
      if (file.getIsolatedFilename(file.unhide(name)).equals("pixelrealm-grass")) moveName = "Grass."+ext;
      
      if (file.getIsolatedFilename(file.unhide(name)).equals("pixelrealm-bgm")) moveName = "BGM."+ext;
      
      for (int i = 1; i <= 9; i++) {
        if (file.getIsolatedFilename(file.unhide(name)).equals("pixelrealm-sky-"+i)) moveName = "Sky-"+i+"."+ext;
        if (file.getIsolatedFilename(file.unhide(name)).equals("pixelrealm-tree-"+i)) moveName = "Tree-"+i+"."+ext;
        if (file.getIsolatedFilename(file.unhide(name)).equals("pixelrealm-terrain_object-"+i)) moveName = "Tree-"+i+"."+ext;
      }
      
      return moveName;
    }
    
    
    // Type: [0 = image] [1 = music] [2 = plugin file]
    private PocketItem createRealmAssetPocketItem(String filenameWithoutExt, int type) {
      String pathwithoutext = currRealm.stateDirectory+filenameWithoutExt;
      String path = "";
      switch (type) {
        case 0:
        path = file.anyImageFile(pathwithoutext);
        break;
        case 1:
        path = file.anyMusicFile(pathwithoutext);
        break;
        // ill do 2 later.
      }
      
      if (path != null) {
        PixelRealmState.FileObject fileObject = currRealm.createPRObject(path);
        
        // Ya need to call load as you know.
        fileObject.load(new JSONObject());
        
        // Create pocket item
        PocketItem p = new PocketItem(file.getFilename(path), fileObject, false);
        p.syncd = false;  // Very much not sync'd.
        
        // Yeet it into the void so we can't see it.
        currRealm.throwItIntoTheVoid(p.item);
        
        return p;
      }
      else {
        return null;
      }
    }
    
    private PocketItem createRealmAssetPocketItem(String filenameWithoutExt) {
      return createRealmAssetPocketItem(filenameWithoutExt, 0);
    }
    
    private String checkRealmFileSlot() {
      return checkRealmFileSlot(draggingItem, itemIndex);
    }
    
    // Returns null if check failed, returns new name when check succeeds.
    private String checkRealmFileSlot(PocketItem itemToCheck, int index) {
      String ext = file.getExt(itemToCheck.name);
      String newName = "";
      
      // First, check if the moving file type is the correct type for the slot.
      if (index >= SKY_TEXTURE_SLOT && index < SKY_TEXTURE_SLOT+9) {
        // This file must be an image type
        // Additionally, perform an additional check to see if it's 1500 pixels wide.
        if (!file.isImage(itemToCheck.name)) {
          prompt("Only image file types can go into this slot.");
          return null;
        }
        
        newName = ".pixelrealm-sky-"+str(index-SKY_TEXTURE_SLOT+1)+"."+ext;
      }
      else if (index >= TREE_TEXTURE_SLOT && index < TREE_TEXTURE_SLOT+9) {
        // This file must be an image type
        // Additionally perform check to enxure image is not too big (but it's ok if it's tall).
        if (!file.isImage(itemToCheck.name)) {
          prompt("Only image file types can go into this slot.");
          return null;
        }
        
        newName = ".pixelrealm-tree-"+str(index-TREE_TEXTURE_SLOT+1)+"."+ext;
      }
      else if (index == GROUND_TEXTURE_SLOT) {
        // This file must be an image type
        if (!file.isImage(itemToCheck.name)) {
          prompt("Only image file types can go into this slot.");
          return null;
        }
        
        newName = ".pixelrealm-grass."+ext;
      }
      else if (index == MUSIC_SLOT) {
        // This file must be a music type
        // Additionally, perform an additional check to see if it's 1500 pixels wide.
        if (!file.isAudioFile(itemToCheck.name)) {
          prompt("Only audio file types can go into this slot.");
          return null;
        }
        
        newName = ".pixelrealm-bgm."+ext;
      }
      else if (index == PLUGIN_SLOT) {
          prompt("Not supported yet, sorry!");
          return null;
      }
      else {
        console.bugWarn("moveIntoRealmFileSlot: Unknown cell "+index);
        return null;
      }
      
      return newName;
    }
    
    
    private boolean moveIntoRealmFileSlot() {
      String newName = checkRealmFileSlot();
      if (newName == null) return false;
      rpause();
      
      // Checks passed from this point onwards.
      // Move item and if it fails, return false once again.
      if (!currRealm.moveFromPocket(draggingItem, file.directorify(currRealm.stateDirectory)+newName)) {
        return false;
      }
      
      // Move successful and confirmed, refresh dir.
      currRealm.loadRealmAssets();
      
      // Play music if that's what was changed
      if (itemIndex == MUSIC_SLOT) {
        streamMusicWithFade(file.directorify(currRealm.stateDirectory)+newName);
      }
      
      return true;
    }
    
    private void moveItemToNewCell(int coll) {
      currGrid.grid[itemIndex] = draggingItem;  // Move item
      draggingItem = null;  // No more dragging
      sound.playSound("pocket_placedown");
      
      //int coll = -1;
      //if (currGrid == hotbarGrid) {
      //  coll = HOTBAR;
      //}
      //else if (currGrid == pocketsGrid) {
      //  coll = POCKET;
      //}
      
      if (coll == -1) return;
      
      // Save info (collection and the index)
      JSONObject o = new JSONObject();
      o.setInt("coll", coll);   // 1: pockets, 2: hotbar
      if (coll == 1) o.setInt("loc", itemIndex);
      pocketInfo.setJSONObject(currGrid.grid[itemIndex].name, o);
    }
    
    private void performSwap() {
      if (itemToSwap != null) {
        // In order to perform the swap, we must move the item into originalGridLocation
        
        // Gotta have those variables before we run them
        int originalcelllocation_temp = originalCellLocation;
        int itemIndex_temp = itemIndex;
        Grid orignalgrid_temp = originalGridLocation;
        Grid currGrid_temp = currGrid;
        
        // Set the variables so we can perform the opposite grid's moveIn action.
        draggingItem = itemToSwap;
        originalGridLocation = currGrid_temp;
        currGrid = orignalgrid_temp;
        originalCellLocation = itemIndex_temp;
        itemIndex = originalcelllocation_temp;
        
        orignalgrid_temp.runMoveInAction();
        //currGrid.grid[itemIndex]
        sound.playSound("swish", 2f);
      }
    }
    
    private PocketItem itemToSwap = null;
    
    private void beginSwapIfOccupied() {
      // If the cell is occupied
      if (currGrid.grid[itemIndex] != null) {
        itemToSwap = currGrid.grid[itemIndex];   // Store temporarily for performSwap later on
        //currGrid.grid[itemIndex] = null;   // Not needed but it's good to have the mindset that this cell should really be empty.
                                           // Don't worry, it's stored in itemToSwap.
        
      }
    }
    
    private void returnDraggingItemToOriginalCell() {
      originalGridLocation.grid[originalCellLocation] = draggingItem;
      draggingItem = null;
      sound.playSound("pocket_placedown");
    }
    
    private boolean promptShown() {
      return promptMessage != null;
    }
    
    private void playDefaultMusic() {
      sound.stopMusic();
      if (currRealm.versionCompatibility == 1) {
        sound.streamMusic(engine.APPPATH+REALM_BGM_DEFAULT_LEGACY);
      }
      else if (currRealm.versionCompatibility >= 2) {
        sound.streamMusic(engine.APPPATH+REALM_BGM_DEFAULT);
      }
    }
    
    private final String[] tabTitles = { "Hotbar", "Realm" /*, "Files"*/ };

    public void display() {
      // Background
      displayBackground("back-pocketmenu");
      
      hoverLabel = null;
      doubleClickTimer -= display.getDelta();
      
      
      // Pocket positioning in the form of a sprite
      gui.spriteVary("pocket_yourpocket", "nothing");
      float xxx = gui.getSprite("pocket_yourpocket").getX();
      float yyy = gui.getSprite("pocket_yourpocket").getY();
      float hii = gui.getSprite("pocket_yourpocket").getHeight();
      
      // Title
      app.fill(255f);
      app.textFont(engine.DEFAULT_FONT, 40f);
      app.textAlign(LEFT, TOP);
      app.text("Pocket", xxx+80f, yyy+5f);
      
      // Pockets grid
      pocketsGrid.display(xxx, yyy+60f, getWidth(), hii);
      
      // Outer grid selection tab (hotbar, realm assets, or folder files)
      // First get sprite position of outer grid (tabs go above that)
      gui.spriteVary("pocket_hotbar", "nothing");
      xxx = gui.getSprite("pocket_hotbar").getX();
      yyy = gui.getSprite("pocket_hotbar").getY();
      hii = gui.getSprite("pocket_hotbar").getHeight();
      
      // Tab select
      app.textSize(20f);
      final float BAR_TAB_HEIGHT = 30f;
      for (int i = 0; i < tabTitles.length; i++) {
        app.stroke(255);
        app.strokeWeight(1);
        
        // Purple highlight if selected
        if (i == selectedPocketTab) {
          app.fill(160*0.75f, 140*0.75f, 200*0.75f);
        }
        // Brighter highlight if hovering (click to select tab)
        else if (ui.mouseInArea(xxx+(i*200f), yyy-BAR_TAB_HEIGHT, 200f, BAR_TAB_HEIGHT-1f) && promptMessage == null) {
          app.fill(55f);
          if (input.primaryOnce) {
            selectedPocketTab = i;
            sound.playSound("submenu_"+str(i+1));
          }
        }
        // Default grey
        else {
          app.fill(40f);
        }
        
        // Draw tab and text.
        app.rect(xxx+(i*200f), yyy-BAR_TAB_HEIGHT, 200f, BAR_TAB_HEIGHT);
        app.fill(255);
        app.text(tabTitles[i], xxx+(i*200f)+10f, yyy-BAR_TAB_HEIGHT+7f);
      }
      
      // Outer grid 
      // This can either be hotbar, realm assets, or folder files.
      // Hotbar grid.
      switch (selectedPocketTab) {
        case 0:
        hotbarGrid.display(xxx, yyy, getWidth(), hii);
        break;
        case 1:
        realmGrid.display(xxx, yyy, getWidth(), hii);
        break;
        case 2:
        break;
      }
      
      
      // This section of code must run after all grid display() calls.
      if (draggingItem != null) {
        draggingItem.displayIcon(input.mouseX()-32f, input.mouseY()-32f, 64f);
        
        // Mouse released outside of a grid square (snap back to the originalSquare)
        if (input.primaryReleased && !stickItemToMouse) {
          returnDraggingItemToOriginalCell();
        }
      }

      // Back button
      if (!promptShown()) {
        if (ui.buttonVary("pocket_back", "back_arrow_128", "")) {
          close();
          sound.playSound("menu_select");
          menu = new MainMenu();
        }
      }
      
      // Debug only pretty much (though would be neat to find a little corner for it at some point)
      //if (!promptShown()) {
      //  if (ui.buttonVary("pocket_refresh", "swap_256", "Refresh")) {
      //    sound.playSound("menu_select");
      //    refresh();
      //  }
      //}
      
      
      // Hide menu when pocket menu button pressed.
      // The keydelay thing is just so that the menu doesn't immediately disappear on the same frame as it appearing when pressing
      // 'i' to make it appear.
      if (promptMessage == null && !keyDelay) {
        if (input.keyActionOnce("open_pocket", 'i')) {
          close();
          menuShown = false;
          menu = null;
        }
      }
      else {
        keyDelay = false;
      }
      
      // Hover label
      if (hoverLabel != null) {
        app.noStroke();
        app.fill(0, 0, 0, 180);
        app.textFont(engine.DEFAULT_FONT, 26);
        app.textAlign(LEFT, TOP);
        
        float wi = app.textWidth(hoverLabel)+20f;
        float hi = 34f;
        float x  = max(min(input.mouseX(), WIDTH-wi), 0f);
        float y  = input.mouseY()-hi;
        
        app.rect(x-10f, y-6f, wi, hi);
        app.fill(hoverLabelColor);
        app.text(hoverLabel, x, y);
      }
      
      
      // Prompt (this appears when a pocketMove() operation fails) 
      if (promptMessage != null) {
        // Display background
        gui().sprite("pockets_prompt_back", "darkgrey");
        float xx = gui.getSprite("pockets_prompt_back").getX();
        float yy = gui.getSprite("pockets_prompt_back").getY();
        float wi = gui.getSprite("pockets_prompt_back").getWidth();
        float hi = gui.getSprite("pockets_prompt_back").getHeight();
        app.fill(255);
        app.textFont(engine.DEFAULT_FONT, 24);
        
        // Display prompt text (make it higher when there's a prompt shown)
        app.textAlign(CENTER, CENTER);
        app.text(promptMessage, xx+20f, yy, wi-40f, hi-90);
        
        // Display input field.
        if (showInputField) {
          promptInput = input.getTyping(promptInput, false);
          app.textAlign(CENTER, CENTER);
          app.text(input.keyboardMessageDisplay(promptInput), xx+wi*0.5f, yy+hi*0.70f);
          
          
          // Dismiss button (input prompt shown)
          if (ui.button("pockets_prompt_close_inputshown", "cross_128", "Dismiss")) {
            sound.playSound("menu_select");
            promptMessage = null;
          }
          
          // Ok button (input prompt shown)
          boolean okbutton = ui.button("pockets_prompt_ok_inputshown", "tick_128", "OK");
          if (okbutton || input.enterOnce && promptInputRunWhenEnter != null) {
            promptInputRunWhenEnter.run();
          }
        }
        
        // Dismiss button (no input prompt)
        else {
          if (ui.button("pockets_prompt_close", "cross_128", "Dismiss")) {
            sound.playSound("menu_select");
            promptMessage = null;
          }
        }
        
      }
    }
    
    public void prompt(String message) {
      sound.playSound("menu_prompt");
      showInputField = false;
      promptMessage = message;
    }
    
    // When the menu closes, we need to save our pocket configuration and reload the hotbar.
    @Override
    public void close() {
      // Save pocket info file
      app.saveJSONObject(pocketInfo, engine.APPPATH+engine.POCKET_PATH+POCKET_INFO);
      
      // Reload hotbar
      currRealm.loadHotbar();
      
      // Equip grabber
      if (switchToGrabberOnExit) {
        switchTool(TOOL_GRABBER);
      }
      
      
      // Restore old memusage state
      memUsage.set(prevMemUsage);
    }
  }
  
  
  
  
  private void openPocketMenu() {
    try {
      menu = new PocketMenu();
    }
    catch (PocketPanicException e) {
      handlePocketPanic(e);
    }
  }
  
  private void handlePocketPanic(PocketPanicException e) {
    switch (e.getErr()) {
      case PocketPanicException.ERR_TOO_FULL:
      Runnable r = new Runnable() {
        public void run() {
          file.open(engine.APPPATH+engine.POCKET_PATH);
        }
      };
      menu = new DialogMenu("Pocket load error", "back-newrealm", "Your pockets are too full and could not be loaded. Please remove some items from the pocket folder.", r);
      break;
      case PocketPanicException.ERR_UNKNOWN:
      prompt("Unknown error", "An unknown problem occured while trying to open the pockets. You may need to remove all files from the pocket folder.");
      break;
    }
  }
  
  
  
  
  
  
  
  

  class InputPromptMenu extends Menu {
    public void display() {
      displayBackground("back-inputprompt");
      engine.displayInputPrompt();
    }
  }
  
  
  
  
  
  
  
  
  
  
  

  class NewRealmMenu extends TitleMenu {
    int tempIndex = -1;
    float coolDown = 0.1f;

    // Slight delay before we show the menu, for a bug fix.
    int tmr = 0;

    ArrayList<String> templates = new ArrayList<String>();
    String previewName = "";

    public NewRealmMenu() {
      super("Welcome to your new realm", "back-newrealm");

      if (!file.exists(engine.APPPATH+engine.TEMPLATES_PATH)) {
        console.warn("Templates folder not found.");
        menuShown = false;
      }
      
      // Can't list our own files, gotta use the load_lists.txt
      if (isAndroid()) {
        String[] realms = loadStrings(engine.APPPATH+engine.TEMPLATES_PATH+"load_list.txt");
        for (String path : realms) {
          // Same as isDirectory() but check the string directly.
          if (path.charAt(path.length()-1) == '/') {
            templates.add(path);
          }
        }
      }
      else {
        File realms = new File(engine.APPPATH+engine.TEMPLATES_PATH);
        for (File f : realms.listFiles()) {
          if (f.isDirectory()) {
            templates.add(file.directorify(f.getAbsolutePath()));
          }
        }
      }
    }

    private void preview(int index) {
      String path = templates.get(index);
      sound.playSound("menu_select");
      changedTemplate = true;
      coolDown = 1f;

      previewName = "";
      // Load template information.
      if (file.exists(path+TEMPLATE_METADATA_FILENAME)) {
        try {
          JSONObject json = app.loadJSONObject(path+TEMPLATE_METADATA_FILENAME);
          previewName = json.getString("realm_name", "");
          musicInfo   = json.getString("music_name", "");
          musicURL    = json.getString("music_url", "");
        }
        catch (RuntimeException e) {
          console.warn("There's a problem with this "+TEMPLATE_METADATA_FILENAME+"!");
        }
      }
      
      // Need to clear terrain objects when we load a new realm otherwise we end up with wayyyy too much
      // in our face.
      currRealm.chunks.clear();
      //tilesCache.clear();
      currRealm.ordering = new LinkedList();
      currRealm.legacy_autogenStuff = new HashSet<String>();


      // Load terrain
      currRealm.loadRealmTerrain(path);
      
      // clearing ordering also clears our fileobjects.
      // We need to re-add them back.
      // And, while we're at it, let's put them level with the ground.
      for (PixelRealmState.FileObject o : currRealm.files) {
        currRealm.ordering.add(o);
        o.surface();
      }
      
      //for (PixelRealmState.PRObject p : currRealm.ordering) {
      //  p.surface();
      //  if (p instanceof PixelRealmState.TerrainPRObject) {
      //    PixelRealmState.TerrainPRObject t = (PixelRealmState.TerrainPRObject)p;
      //    t.readjustSize();
      //  }
      //}
      currRealm.playerY = currRealm.onSurface(currRealm.playerX, currRealm.playerZ);
      sound.stopMusic();
      sound.streamMusic(currRealm.musicPath);
    }
    
    
    private void createRealmFiles() {
      sound.playSound("menu_select");

        // User didn't select any realm.
        if (tempIndex == -1) {
          menuShown = false;
          menu = null;
          return;
        }

        // begin to copy the realm assets.

        ArrayList<String> movefiles = new ArrayList<String>();
        // get the realm files
        String realmDir = file.directorify(templates.get(tempIndex));
        File realmfile = new File(realmDir);
        String dest = file.directorify(currRealm.stateDirectory);
        
        
        if (isAndroid()) {
          String[] files = loadStrings(realmDir+"load_list.txt");
          for (String src : files) {
            String name = file.getFilename(src);
            
            // The realmtemplate file is an exception
            if (name.equals(TEMPLATE_METADATA_FILENAME))
              continue;
  
            //if (file.exists(dest+name)) {
            //  conflict = true;
            //  break;
            //}
  
            movefiles.add(src);
          }
        }
        else {
          for (File f : realmfile.listFiles()) {
            String src = f.getAbsolutePath().replaceAll("\\\\", "/");
            String name = file.getFilename(src);
  
            // The realmtemplate file is an exception
            if (name.equals(TEMPLATE_METADATA_FILENAME) || name.equals("load_list.txt"))
              continue;
  
            //if (file.exists(dest+name)) {
            //  conflict = true;
            //  break;
            //}
  
            movefiles.add(src);
          }
        }
        
        issueRefresherCommand(REFRESHER_PAUSE);
        for (String src : movefiles) {
          // Make it hidden
          String filename = file.getFilename(src);
          if (filename.charAt(0) != '.') filename = "."+filename;
          
          
          if (!file.copy(src, dest+filename)) {
            prompt("Copy error", "An error occured while copying realm template files: "+file.getFileError());
            // Return here so the menu stays open.
            return;
          }
        }

        // Successful so we can close the menu.
        menuShown = false;
        menu = null;
        stats.increase("realm_templates_created", 1);
    }
    

    public void display() {
      super.display();
      // Text settings from title should still be applied here.
      app.textSize(22);
      app.text("Select a template", getXmid(), getY()+90);

      app.textAlign(CENTER, CENTER);
      app.textSize(30);
      app.text(previewName, getXmid(), getYmid());
      app.textSize(16);
      //String left = str(settings.getKeybinding("inventorySelectLeft"));
      //String right = str(settings.getKeybinding("inventorySelectRight"));
      app.text("Navigate with left and right arrow keys, press <enter/return> to confirm.", getXmid(), getYbottom()-40);
      
      // Debug stuff mostly for making realm templates
      //gui().sprite("realm name thing", "nothing");
      //float xxx = gui().getSprite("realm name thing").getX();
      //float yyy = gui().getSprite("realm name thing").getY();
      //try {
      //  app.text(file.getFilename(templates.get(tempIndex)), xxx, yyy);
      //  if (ui.buttonVary("newrealm-goto", "folder_128", "Goto")) {
      //    gotoRealm(templates.get(tempIndex));
      //    menuShown = false;
      //    menu = null;
      //    return;
      //  }
      //}
      //catch (IndexOutOfBoundsException e) {}
      
      // Lil easter egg for the glitched realm
      if (previewName.equals("YOUR FAVOURITE REALM")) {
        app.noStroke();
        app.fill(255);
        int l = int(random(5, 30));
        for (int i = 0; i < l; i++)
          app.rect(random(getXmid()-200, getXmid()+200), random(getYmid()-20, getYmid()+20), random(10, 50), random(5, 20));
      }

      // Special condition to make sure we can't go to the last realm that isn't cached on our first playthrough
      boolean allow = (sound.loadingMusic() && tempIndex > 0) || !sound.loadingMusic();
      
      if (allow) {
        if ((input.leftOnce
          || ui.buttonVary("newrealm-prev", "back_arrow_128", ""))
          && coolDown <= 0f) {
          tempIndex--;
          if (tempIndex < 0) tempIndex = templates.size()-1;
          preview(tempIndex);
        }
      }
      
      if ((input.rightOnce
        || ui.buttonVary("newrealm-next", "forward_arrow_128", ""))
        && coolDown <= 0f) {
        tempIndex++;
        if (tempIndex > templates.size()-1) tempIndex = 0;
        preview(tempIndex);
      }
      if (input.enterOnce || ui.buttonVary("newrealm-confirm", "tick_128", "")) {
        createRealmFiles();
      }

      // Bug fix: immediately pausing movement causes cached sin and cos directions to be outdated
      // resulting in weird billboard 3d objects facing the wrong angle.
      // Delay the pausing of movement just a lil bit to let it update.
      movementPaused = (tmr++ > 2);
      if (coolDown > 0f) coolDown -= display.getDelta();
    }
    
    @Override
    public void close() {
      createRealmFiles();
    }
  }









  class CustomNodeMenu extends TitleMenu {
    
    private boolean mouseDown = true;
    
    
    public CustomNodeMenu(String title, String spriteName) {
      super(title, spriteName);
    }
    
    
    protected void runCustomNodes(ArrayList<TWEngine.UIModule.CustomNode> customNodes) {
      

      // Display all parameters for the specified generator that is selected.
      float x = cache_backX+50;
      float y = cache_backY+50+95;
      nodeSound = 0;

      // True upon the menu appearing, and stays true as long as the user holds down the mouse.
      // Once the user lets go, mouseDown is permantally set to false.
      // This is used to avoid a slider from being unintentionally clicked when the mouse is down
      // from the previous menu.
      mouseDown &= input.primaryDown;

      if (!mouseDown) {
        for (TWEngine.UIModule.CustomNode n : customNodes) {
          n.wi = cache_backWi-100.;

          n.display(x, y);

          y += n.getHeight();
        }
      }

      if (nodeSound != 0)
        sound.loopSound("terraform_"+str(nodeSound));
      else {
        sound.pauseSound("terraform_1");
        sound.pauseSound("terraform_2");
        sound.pauseSound("terraform_3");
        sound.pauseSound("terraform_4");
      }
    }
  }



  class CustomiseTerrainMenu extends CustomNodeMenu {

    private int generatorIndex = 0;


    public CustomiseTerrainMenu() {
      super("", "back-customise");
      
      generatorIndex = currRealm.terrainTypeToInt();
    }


    //private void switchGenerator(int index) {
    // we can try doing this another day.
    //try {
    //  //currRealm.terrain = (PixelRealmState.TerrainAttributes)Class.forName(terrainGenerators[index]).getConstructor().newInstance();
    //  Class.forName(terrainGenerators[index]).getConstructor(String.class);
    //  console.log(currRealm.terrain.getClass().getSimpleName());
    //}
    //catch (ClassNotFoundException e) {
    //  console.log("Cant get class name");
    //}
    //catch (Exception e) {
    //  console.bugWarn(""+e.getMessage());
    //  console.bugWarn("Unknown error: "+e.getClass().getSimpleName());

    //}
    //}

    public static final int NUM_GENERATORS = 2;

    public void display() {
      setTitle("");
      super.display();


      app.fill(255);
      app.textFont(engine.DEFAULT_FONT, 20);
      app.textAlign(LEFT, TOP);
      app.text("Generator", cache_backX+50, cache_backY+85);

      app.textAlign(CENTER, TOP);
      app.textSize(24);
      app.text(currRealm.terrain.NAME, cache_backX+cache_backWi/2, cache_backY+85);


      if (ui.buttonVary("customise-prev", "back_arrow_128", "")) {
        sound.playSound("menu_select");
        generatorIndex--;
        if (generatorIndex < 0) generatorIndex = NUM_GENERATORS-1;
        //switchGenerator(generatorIndex);
        currRealm.switchTerrain(generatorIndex);
      }
      if (ui.buttonVary("customise-next", "forward_arrow_128", "")) {
        sound.playSound("menu_select");
        generatorIndex++;
        if (generatorIndex >= NUM_GENERATORS) generatorIndex = 0;
        currRealm.switchTerrain(generatorIndex);
      }

      if (ui.buttonVary("customise-ok", "tick_128", "Done")) {
        sound.playSound("menu_select");
        close();
        menuShown = false;
        menu = null;
      }

      runCustomNodes(currRealm.terrain.customNodes);

      currRealm.terrain.updateAttribs();
      modifyTerrain = true;
    }

    public void close() {
      currRealm.chunks.clear();
      //tilesCache.clear();
      currRealm.resetTrees();
      //currRealm.regenerateTrees();
      //chunks = new HashMap<Integer, TerrainChunkV2>();
    }
  }
  
  
  
  
  
  
  
  
  class CustomiseLookAndFeelMenu extends CustomNodeMenu {
    
    public CustomiseLookAndFeelMenu() {
      super("", "back-lighting");
    }
    
    public void display() {
      setTitle("-- Look & feel --");
      super.display();

      if (ui.buttonVary("lighting-reset", "cross_128", "Reset lights")) {
        currRealm.ambientSlider.valFloat = 1f;
        currRealm.reffectSlider.valFloat = 0f;
        currRealm.geffectSlider.valFloat = 0f;
        currRealm.beffectSlider.valFloat = 0f;
        currRealm.lightDirectionSlider.valInt = 1;
        currRealm.lightHeightSlider.valInt = 2;
      }


      if (ui.buttonVary("lighting-ok", "tick_128", "Done")) {
        sound.playSound("menu_select");
        close();
        menuShown = false;
        menu = null;
      }

      runCustomNodes(currRealm.lookAndFeelUINodes);
      
      currRealm.terrain.updateMinimalAttribs();
    }
  }
  
  
  
  
  
  
  
  class SearchPromptMenu extends TitleMenu {
    
    ArrayList<String> results = null;
    
    private String queryInput = "";
    
    public SearchPromptMenu() {
      super("", "back-search");
      input.cursorX = 0;
    }
    
    private void open(String path) {
      String ext = file.getExt(path);
      if (file.exists(path)) {
        if (file.isDirectory(path)) {
          gotoRealm(path);
        }
        else if (ext.equals("mp3") || ext.equals("ogg") || ext.equals("wav") || ext.equals("flac")) {
          sound.stopMusic();
          sound.streamMusic(path);
          cassettePlaying = file.getFilename(path);
        }
        else {
          file.open(path);
        }
      }
    }
    
    public void close() {
      searchMenuTimeout = 10;
      menu = null;
      menuShown = false;
    }
    
    // Physically teleports the player to the item if in the same dir,
    // or if not in the same dir, goes to that dir and then physicially teleports the player.
    public void gotoFile(String path) {
      String stateDir = file.directorify(currRealm.stateDirectory);
      
      // If we're in same realm as file, simply teleport
      console.log(file.getDir(path)+" "+(stateDir));
      String parent = file.directorify(file.getDir(path));
      if (!parent.equals(stateDir)) {
        gotoRealm(parent);
      }
      
      
      PixelRealmState.FileObject fobject = currRealm.findFileObjectByName(file.getFilename(path));
      if (fobject == null) {
        console.warn("Couldn't locate "+file.getFilename(path));
      }
      else {
        currRealm.tp(fobject.x-200, fobject.y, fobject.z, HALF_PI);
      }
    }
    
    public void display() {
      setTitle("-- Search --");
      super.display();
      
      display.clip(getX(), getY(), getWidth(), getHeight());
      
      queryInput = input.getTyping(queryInput, false);
      
      app.fill(255);
      app.textSize(40);
      app.textAlign(CENTER, TOP);
      app.text(input.keyboardMessageDisplay(queryInput), getXmid(), getY()+100f);
      
      if (input.keyOnce) {
        results = indexer.search(queryInput, currRealm.stateDirectory);
      }
      
      if (input.enterOnce && searchMenuTimeout <= 0) {
        if (results != null && results.size() > 0) {
          gotoFile(results.get(0));
        }
        close();
      }
      
      if (results != null) {
        app.textSize(20);
        app.text(results.size()+" results.", getXmid(), getY()+160f);
        
        app.textSize(30);
        float y = getY()+200f;
        int count = 0;
        for (String result : results) {
          
          if (input.mouseY() > y && input.mouseY() < y+30f) {
            app.fill(255, 200, 0);
            if (input.primaryDown) {
              gotoFile(result);
              close();
            }
            if (input.secondaryDown) {
              open(result);
              close();
            }
          }
          else {
            app.fill(255);
          }
          String txt = file.getFilename(result);
          if (txt.length() >= 43) {
            app.text(txt.substring(0, 41)+"...", getXmid(), y);
          }
          else {
            app.text(txt, getXmid(), y);
          }
          
          
          y += 30f;
          count++;
          if (count > 4) break;
        }
      }
      
      display.noClip();
    }
  }
  
  // To be used by TWIT.
  class CustomMenu extends TitleMenu {
    private Runnable displayRunnable = null;
    
    public CustomMenu(String title, String name) {
      super(title, name);
    }
    
    public void display() {
      super.display();
      
      if (displayRunnable != null) displayRunnable.run();
    }
    
    public void setDisplayRunnable(Runnable r) {
      displayRunnable = r;
    }
  }
  
  
  public void createCustomMenu(String title, String backname, Runnable displayRunnable) {
    CustomMenu m = new CustomMenu(title, backname);
    m.setDisplayRunnable(displayRunnable);
    menu = m;
    menuShown = true;
  }









  // Called from base pixelrealm
  private void errorPrompt(String title, String mssg, int delay) {
    if (gui == null) return;
    
    // The pockets menu has a special sub-menu showing the error.
    if (menuShown && menu instanceof PocketMenu) {
      ((PocketMenu)menu).prompt(mssg);
    }
    else {
      DialogMenu m = new DialogMenu(title, "back-newrealm", mssg);
      m.setAppearTimer(delay);
      menu = m;
      menuShown = true;
    }
  }
  
  private void errorPrompt(String title, String mssg) {
    errorPrompt(title, mssg, 20);
  }

  protected void promptPocketConflict(String filename) {
    String txt = "You have a duplicate file in your pocket ("+filename+"). Please drop or rename the duplicate item before continuing.";
    errorPrompt("Pocket conflict!", txt);
  }

  protected void promptFailedToMove(String filename) {
    String txt = "Failed to move "+filename+": "+file.getFileError();
    errorPrompt("Move failed", txt);
  }

  protected void promptFileConflict(PixelRealmState.FileObject oldFile, PixelRealmState.FileObject newFile) {
    if (menuShown && menu instanceof PocketMenu) {
      errorPrompt("File conflict", "There is a duplicate file in this folder ("+newFile.filename+").");
    }
    else {
      String txt = newFile.filename+" already exists in this realm.\nYou can do the following:";
      DialogMenu m = new ConflictMenu("File conflict", txt, oldFile, newFile);
      menu = m;
      menuShown = true;
    }
  }

  protected void promptMoveAbstractObject(String filename) {
    String txt = filename+" is a non-file item and can't be moved outside of its realm.";
    errorPrompt("Move non-file item restricted", txt);
  }

  protected void prompt(String title, String text) {
    prompt(title, text, 0);
  }

  protected void prompt(String title, String text, int appearDelay) {
    if (gui == null) return;
    DialogMenu m = new DialogMenu(title, "back-newrealm", text);
    m.setAppearTimer(appearDelay);
    menu = m;
    menuShown = true;
  }

  protected void promptNewRealm() {
    if (gui == null) return;
    if (!file.exists(engine.APPPATH+engine.TEMPLATES_PATH)) return;
    menu = new NewRealmMenu();
    menuShown = true;
  }
  
  protected void promptFileOptions(PixelRealmState.FileObject probject) {
    sound.playSound("menu_select");
    menu = new FileOptionsMenu(probject);
    menuShown = true;
  }
  












  public void runMenu() {
    modifyTerrain = false;
    if (menuShown && menu != null) {
      // Custom menus means that it's being used by a TWIT plugin.
      // Users will most likely use their own custom sprite system in these scenarios
      if (menu instanceof CustomMenu) {
        // May not be using custom sprite system, in which case use our normal sprite system
        // (not recommended for programmer but they'll be sent a warning)
        if (!ui.usingTWITSpriteSystem) {
          console.warnOnce("You aren't using your own sprite system. It is highly recommended to use your own sprite system with custom menus.");
          ui.useSpriteSystem(gui);
        }
      }
      else {
        ui.useSpriteSystem(gui);
      }
      menu.display();
    }
    else {
      optionHighlightedItem = null;
    }
  }


  private boolean touchForward = false;
  private boolean touchLeft  = false;
  private boolean touchRight = false;
  private boolean touch = false;
  private boolean showOnceTouch = true;
  private boolean dash = false;
  private float doubleTapTimer = 0.0;
  private float prevMouseX = 0.;
  private float sensitivity = 500.;
  private boolean prevReset = false;

  public void runGUI() {
    // Display touch controls
    if (!menuShown && touchControlsEnabled) {
      ui.useSpriteSystem(gui);
      
      boolean click = false;
      
      // Buttons on the top-right
      if (ui.buttonVary("touch-menu", "touch_menu", "")) {
        input.setAction("menu", '\t');
        click = true;
      }
      if (ui.buttonVary("touch-prevrealm", "touch_prevrealm", "")) {
        input.setAction("prev_directory", '\b');
        click = true;
      }
      if (ui.buttonVary("touch-home", "touch_home", "")) {
        input.setAction("quick_warp_1", '1');
        click = true;
      }
      
      // The move buttons on the bottom-left
      // When the button is pressed, initiate movement
      // We stop movement when the user lifts their finger from
      // any part of the screen.
      // But as long as the user is touching anywhere on the screen
      // after intially pressing a move button, we keep moving.
      boolean touchOnce = false;
      if (ui.buttonVary("touch-move", "touch_forward", "")) {
        touchForward = true;
        touchOnce = true;
      }
      if (ui.buttonVary("touch-left", "touch_left", "")) {
        touchLeft = true;
        touchOnce = true;
      }
      if (ui.buttonVary("touch-right", "touch_right", "")) {
        touchRight = true;
        touchOnce = true;
      }
      
      // Double-tap dash for the left, forwards, and right buttons
      if (touchOnce) {
        touch = true;
        if (doubleTapTimer > 0.) {
          dash = true;
        }
        doubleTapTimer = 20.;
      }
      if (doubleTapTimer > 0.) {
        doubleTapTimer -= display.getDelta();
      }
      
      // Once the user releases their finger, stop movement.
      if (!input.primaryDown) {
        touch = false;
        dash = false;
        touchForward = false;
        touchLeft = false;
        touchRight = false;
      }
      
      // Buttons on the bottom-right; action buttons
      if (ui.buttonVary("touch-a", "touch_a", "")) {
        input.setAction("primary_action", 'o');
        click = true;
      }
      if (ui.buttonVary("touch-b", "touch_b", "")) {
        input.setAction("secondary_action", 'p');
        click = true;
      }
      
      // Basically to overcome quirk in the sprite system
      // and to make hover areas visible while editing
      if (gui.interactable || showOnceTouch) {
        ui.buttonVary("touch-jump", "black", "");
        ui.buttonVary("touch-look-left", "black", "");
        ui.buttonVary("touch-look-right", "black", "");
        ui.buttonVary("touch-walkback", "black", "");
        showOnceTouch = false;
      }
      
      // bug fix
      if (!input.primaryDown) {
        prevMouseX = input.mouseX();
        prevReset =  true;
      }
      // Reset prevInput for one more frame
      else if (prevReset) {
        prevMouseX = input.mouseX();
        prevReset =  false;
      }
      
      // While the user has touched a move button,
      // the user can move their finger to one of the
      // hover areas to jump, turn left, or turn right
      // (as well as move backwards) while still moving.
      if (touch) {
        if (dash) {
          input.setAction("dash", TWEngine.InputModule.CTRL_KEY);
        }
        
        if (touchLeft) {
          input.setAction("move_left", 'a');
        }
        else if (touchRight) {
          input.setAction("move_right", 'd');
        }


        if (ui.buttonHoverVary("touch-jump")) {
          input.setAction("jump", ' ');
        }
        
        if (touchForward) {
          if (ui.buttonHoverVary("touch-walkback")) {
            input.setAction("move_backward", 's');
          } else {
            input.setAction("move_forward", 'w');
          }
          
          //if (ui.buttonHoverVary("touch-look-left")) {
          //  input.setAction("lookLeftTouch");
          //}
          //if (ui.buttonHoverVary("touch-look-right")) {
          //  input.setAction("lookRightTouch");
          //}
        }
      }
      // But if the user touches a blank space and drags,
      // turn instead.
      else if (input.primaryDown && !click) {
        currRealm.direction += (input.mouseX()-prevMouseX)/sensitivity;
        prevMouseX = input.mouseX();
      }
      
      
    }

    // Display inventory
    if (!menuShown && currentTool == TOOL_GRABBER && currRealm.getHoldingItem() != null) {
      float invx = 10;
      float invy = this.height-80;

      display.recordRendererTime();
      textFont(engine.DEFAULT_FONT, 40);
      textAlign(LEFT, TOP);
      fill(255);
      text(currRealm.getHoldingItem().name, 15, this.height-140);
      for (PocketItem p : hotbar) {
        invy = this.height-80;
        if (p == currRealm.getHoldingItem()) invy -= 20;

        float x = invx;
        float y = invy;

        if (p.abstractObject || p.isDuplicate) {
          x += app.random(-5, 5);
          y += app.random(-5, 5);
        }

        if (p.item != null)
          p.displayIcon(x, y, 64);
          
        invx += 70;
      }

      if (touchControlsEnabled) {

        if (ui.buttonVary("touch-slot-left", "touch_left", "")) {
          input.setAction("inventory_select_left", ',');
        }
        if (ui.buttonVary("touch-slot-right", "touch_right", "")) {
          input.setAction("inventory_select_right", '.');
        }
      }

      display.recordLogicTime();
    }

    if (showPlayerPos) {
      textFont(engine.DEFAULT_FONT, 40);
      textAlign(LEFT, TOP);
      fill(0);
      text("x "+currRealm.playerX+ "  y "+currRealm.playerY+"  z "+currRealm.playerZ, 20-2, myUpperBarWeight+100-2);
      fill(255);
      text("x "+currRealm.playerX+ "  y "+currRealm.playerY+"  z "+currRealm.playerZ, 20, myUpperBarWeight+100);
    }
  }

  int searchMenuTimeout = 0;
  public void controls() {
    // Tab pressed.
    // Hacky way of allowing an exception for our input prompt menu's
    boolean tmp = engine.inputPromptShown;
    engine.inputPromptShown = false;
    if (!engine.commandPromptShown && !ui.miniMenuShown()) {
      if (input.keyActionOnce("menu", '\t')) {
        // Do not allow menu to be closed when set to be on.
        if (menuShown && doNotAllowCloseMenu) {
          engine.inputPromptShown = tmp;
          return;
        }
  
        menuShown = !menuShown;
        if (menuShown) {
          menu = new MainMenu();
        } else {
          if (menu != null) menu.close();
          engine.inputPromptShown = false;
          tmp = false;
        }
  
        // If we're editing a folder/entry name, pressing tab should make the menu disappear
        // and then we can continue moving. If we forget to turn the inputPrompt off, the engine
        // will think we're still typing and won't allow us to move.
        engine.inputPromptShown = false;
        if (menuShown)
          sound.playSound("menu_appear");
      }
    }
      
    searchMenuTimeout--;
    if (!engine.commandPromptShown && !menuShown && searchMenuTimeout <= 0 && input.keyActionOnce("search", '\n')) {
      menuShown = true;
      menu = new SearchPromptMenu();
      searchMenuTimeout = 10;
    }
    
    if (!engine.commandPromptShown && !menuShown && input.keyActionOnce("open_pocket", 'i')) {
      sound.playSound("menu_select");
      menuShown = true;
      openPocketMenu();
    }
    
    engine.inputPromptShown = tmp;
    // Allow the command prompt to be shown only if the menu isn't displayed.
    engine.allowShowCommandPrompt = !menuShown;
    super.movementPaused = menuShown;
  }



  public void content() {
    super.content();
    this.controls();
    this.runMenu();
    this.runGUI();
    this.runTutorial();
    
    if (engine.showMemUsage)
      displayMemUsageBar();
    
    if (tutorialStage == 0) runPlugin(MODE_UI);
    gui.updateSpriteSystem();
  }
  
  
  
  private float cassetteTextScroll = 0f;
  private String playingBefore = "";

  protected void lowerBar() {
    super.lowerBar();
    
    if (engine.playWhileUnfocused) tint(255);
    else tint(200);
    boolean backmusicClicked = ui.buttonImg("music_time_128", 10f, HEIGHT-myLowerBarWeight, myLowerBarWeight, myLowerBarWeight);
    app.noTint();
    
    if (backmusicClicked) {
      engine.toggleUnfocusedMusic();
      if (engine.playWhileUnfocused) 
        sound.playSound("select_general");
      else
        sound.playSound("select_general");
    }
    
    if (musicInfo.length() > 0 && menuShown && menu != null && menu instanceof NewRealmMenu) {
      app.textFont(engine.DEFAULT_FONT, 30);
      app.textAlign(RIGHT, CENTER);
      float x = WIDTH-20;
      float y = HEIGHT-myLowerBarWeight/2;
      app.fill(0);
      app.text(musicInfo, x, y);
      // Glowing text
      color c = color(255, 200, 192.+sin(display.getTime()*0.1)*64. );
      app.fill(c);
      app.text(musicInfo, x-2, y-2);

      // Music icon.
      float wi = textWidth(musicInfo);
      app.tint(0);
      display.imgCentre("music", x-wi-30+2, y+2, 40, 40);
      app.tint(c);
      display.imgCentre("music", x-wi-30, y, 40, 40);
      app.noTint();

      if (musicURL.length() > 0 && engine.mouseY() > y && input.primaryOnce) {
        app.link(musicURL);
      }
    } 
    else if (cassettePlaying()) {
      float SCROLL_SPEED = 2f;
      
      float MUSIC_TEXT_X = WIDTH*0.15f;
      float MUSIC_TEXT_WI = WIDTH*0.2f;
      float MUSIC_TEXT_X_END = MUSIC_TEXT_X+MUSIC_TEXT_WI;
      float STOP_BUTTON_X = MUSIC_TEXT_X_END+10f;
      float PLAY_PAUSE_BUTTON_X = STOP_BUTTON_X+myLowerBarWeight+10f;
      float BAR_X_START = PLAY_PAUSE_BUTTON_X+myLowerBarWeight+10f;
      float BAR_X_LENGTH = WIDTH*0.8f-BAR_X_START;
      
        
      {
      // Display "now playing" menu
      app.textFont(engine.DEFAULT_FONT, 30);
      app.textAlign(LEFT, CENTER);
      float x = MUSIC_TEXT_X;
      float y = HEIGHT-myLowerBarWeight/2;
      app.fill(0);
      
      // Clip to scroll text
      float clipwi = MUSIC_TEXT_WI;
      display.clip(x, HEIGHT-myLowerBarWeight, clipwi, myLowerBarWeight);
      
      // Funky way of resetting cassettteTextScroll if music is changed
      if (playingBefore != cassettePlaying) {
        playingBefore = cassettePlaying;
        cassetteTextScroll = clipwi;
      }
      
      float textwi = app.textWidth(cassettePlaying)+clipwi+15f;
      float textx = x-(cassetteTextScroll%textwi)+clipwi;
      app.text(cassettePlaying, textx, y);
      // Glowing text
      color c = color(255, 200, 192.+sin(display.getTime()*0.1)*64. );
      app.fill(c);
      app.text(cassettePlaying, textx-2, y-2);
      display.noClip();

      // Music icon.
      app.tint(0);
      display.imgCentre("music", x-30+2, y+2, 40, 40);
      app.tint(c);
      display.imgCentre("music", x-30, y, 40, 40);
      app.noTint();
      
      
      }
      
      {
      
        // Display timeline
        // bar
        float y = HEIGHT-myLowerBarWeight;
        app.fill(50);
        app.noStroke();
        app.rect(BAR_X_START, y+(myLowerBarWeight/2)-2, BAR_X_LENGTH, 4);
        
        // Times
        app.textAlign(LEFT, CENTER);
        app.fill(255);
        app.textFont(engine.DEFAULT_FONT, 22);
        
        float time = sound.getTime();
        float dur = sound.getCurrentMusicDuration();
        int minutes = (int)(time/60f);
        int seconds = (int)(time%60f);
        int minutesDur = (int)(dur/60f);
        int secondsDur = (int)(dur%60f);
        String disp = nf(minutes, 2)+":"+nf(seconds, 2)+"/"+nf(minutesDur, 2)+":"+nf(secondsDur, 2);
        fill(0);
        app.text(disp, BAR_X_START+BAR_X_LENGTH+10-2, y+(myLowerBarWeight/2)-2);
        fill(255);
        app.text(disp, BAR_X_START+BAR_X_LENGTH+10, y+(myLowerBarWeight/2));
        
        float percent = time/dur;
        float timeNotchPos = BAR_X_START+BAR_X_LENGTH*percent;
        
        // Notch
        app.fill(255);
        app.rect(timeNotchPos-4, y+(myLowerBarWeight/2)-25, 8, 50); 
        
        // Play/pause button
        boolean playpauseClicked = ui.buttonImg(sound.musicIsPlaying() ? "pause_128" : "play_128", PLAY_PAUSE_BUTTON_X, y, myLowerBarWeight, myLowerBarWeight);
        boolean stopClicked = ui.buttonImg("stop_128", STOP_BUTTON_X, y, myLowerBarWeight, myLowerBarWeight);
        
        // Buttons
        if (playpauseClicked) {
          sound.playSound("select_any");
          if (sound.musicIsPlaying()) {
            sound.pauseMusic();
          }
          else {
            sound.continueMusic();
          }
        }
        
        if (stopClicked) {
          sound.playSound("select_any");
          sound.streamMusicWithFade(currRealm.musicPath);
          cassettePlaying = "";
        }
        
        
        // Bar input control (seek time)
        if (input.mouseX() > BAR_X_START && input.mouseX() < BAR_X_START+BAR_X_LENGTH && input.mouseY() > HEIGHT-myLowerBarWeight && input.primaryDown) {
          float notchPercent = min(max((input.mouseX()-BAR_X_START)/BAR_X_LENGTH, 0.), 1.);
          sound.syncMusic(notchPercent*dur);
        }
        
      }
      
      
      cassetteTextScroll += display.getDelta()*SCROLL_SPEED;
    }
    else {
      musicInfo = "";
      musicURL = "";
    }
  }











  // --- Tutorial ----
  private boolean changedTemplate = false;
  private float moveAmount = 0;
  private int tutorialStage = 0;
  private int numItemsTotal = 0;
  private int numItemsHeld  = 0;
  private boolean doNotAllowCloseMenu = false;

  @SuppressWarnings("unused")
    public void requestTutorial() {
    numItemsHeld = 0;

    // Count how many items we have (yes I know, we don't have a todo)
    numItemsTotal = 0;
    for (PixelRealmState.FileObject o : currRealm.files) {
      numItemsTotal++;
    }

    changedTemplate = false;
    usePortalAllowed = false;
    doNotAllowCloseMenu = true;
    Runnable r = new Runnable() {
      public void run() {
        tutorialStage = 1;
      }
    };
    menuShown = true;
    menu = new DialogMenu("", "back-newrealm", dm_welcome, r);
  }

  protected void promptPickedUpItem() {
    // Pick up item tutorial.
    if (tutorialStage == 4 || tutorialStage == 5) {
      numItemsHeld++;

      if (tutorialStage == 4) {
        if (numItemsHeld >= 5 || numItemsHeld >= numItemsTotal) {
          tutorialStage = 0;
          menuShown = true;
          Runnable r = new Runnable() {
            public void run() {
              tutorialStage = 5;
            }
          };
          tutorialStage = 0;
          menu = new DialogMenu("", "back_welcome", dm_tutorial_4, r);
        }
      }
    }
  }
  
  public void endTutorial() {
    usePortalAllowed = true;
    tutorialStage = 0;
    doNotAllowCloseMenu = false;
    stats.set("last_closed", (int)(System.currentTimeMillis() / 1000L));
    // For now just save some file so that it exists.
    if (isAndroid()) {
      // Save without requiring the file to exist first.
      stats.save(false);
    }
    else {
      stats.save(false);
    }
  }

  protected void promptPlonkedDownItem() {
    if (tutorialStage == 4 || tutorialStage == 5) {
      numItemsHeld--;

      if (tutorialStage == 5) {
        if (numItemsHeld <= 0) {
          tutorialStage = 0;
          menuShown = true;
          Runnable r = new Runnable() {
            public void run() {
              endTutorial();
            }
          };
          tutorialStage = 0;
          menu = new DialogMenu("", "back_welcome", dm_tutorial_end, r);
        }
      }
    }
  }


  public boolean customCommands(String command) {
    if (super.customCommands(command)) {
      return true;
    } else if (engine.commandEquals(command, "/tutorial")) {
      this.requestTutorial();
      return true;
    } else if (engine.commandEquals(command, "/playerpos")) {
      showPlayerPos = !showPlayerPos;
      if (showPlayerPos) console.log("Now showing player's position.");
      else console.log("Player position hidden.");
      return true;
    } else if (command.equals("/editgui")) {
      gui.interactable = !gui.interactable;
      if (gui.interactable) console.log("GUI now interactable.");
      else  console.log("GUI is no longer interactable.");
      return true;
    } else if (engine.commandEquals(command, "/touchcontrols")) {
      touchControlsEnabled = !touchControlsEnabled;
      if (touchControlsEnabled) console.log("Touch controls shown.");
      else console.log("Touch controls hidden.");
      return true;
    }
    else if (engine.commandEquals(command, "/sensitivity")) {
      String[] args = getArgs(command);
      if (args.length >= 1) {
        sensitivity = float(args[0]);
        console.log("Sensitivity set to "+sensitivity);
      }
      else console.log("No arg provided!");
      return true;
    } 
    else if (engine.commandEquals(command, "/realmtemplate") || engine.commandEquals(command, "/realmtemplates") || engine.commandEquals(command, "/templates") || engine.commandEquals(command, "/template")) {
      promptNewRealm();
      return true;
    }
    // To cache realm templates music
    else if (engine.commandEquals(command, "/cachetemplates")) {
      if (isAndroid()) {
        console.log("Not available in Android version!");
        return true;
      }
      
      // Get arg which is how many music files to cache.
      // Default is 10.
      int numRealmsToCache = 10;
      String arg = "";
      if (command.length() > 16) {
        arg = command.substring(16);
        numRealmsToCache = int(arg);
      }
      
      int count = 0;
      // Now loop and cache each file.
      File realms = new File(engine.APPPATH+engine.TEMPLATES_PATH);
      for (File f : realms.listFiles()) {
        if (f.isDirectory()) {
          String dir = (file.directorify(f.getAbsolutePath().replaceAll("\\\\", "/")));
          String path = "";
          // Find .pixelrealm-bgm
          // either .wav, .mp3 or .ogg.
          path = dir+file.unhide(PixelRealm.REALM_BGM)+".wav";
          if (!file.exists(path)) path = dir+file.unhide(PixelRealm.REALM_BGM)+".ogg";
          if (!file.exists(path)) path = dir+file.unhide(PixelRealm.REALM_BGM)+".mp3";
          
          // If none exist, the default realm sound will already be cached of course. Let's continue
          // since we won't be caching anything.
          if (!file.exists(path)) continue;
          
          // Now, engine is of course
          
          // Honestly updateMusicCache should be named to createMusicCache lmao
          // And let's set it to a score of 10000, it's small enough that this startup
          // premade cache will eventually get cleared out when cache is full, it's 
          // big enough to evict any larger cache music files that may be there
          // for whatever reason.
          sound.updateMusicCache(path);
          
          
          
          // Remember do x times where x = our argument.
          count++;
          if (count > numRealmsToCache) {
            // End it here if we reach our number of realms to cache
            break;
          }
        }
      }
      
      console.log("Caching music in "+numRealmsToCache+" realm templates.");
      console.log("Please wait a bit. Caching takes some time.");
      return true;
    }
    else return false;
  }


  public void closeMenu() {
    menuShown = false;
    menu = null;
  }

















  public void runTutorial() {
    if (tutorialStage == 0) return;
    String mssg = "";
    int numgoal = min(5, numItemsTotal);


    switch (tutorialStage) {

      // Lesson 1: moving.
    case 1:
      {
        mssg = "Let's try moving!\nWSAD: Move, Q/E: look left/right, R: run, [space]: jump, [shift]: walk slowly.";

        // Let the player run around a bit, then move on to the next tutorial.
        if (input.keyAction("move_forward", 'w') || input.keyAction("move_backward", 's') || input.keyAction("move_left", 'a') || input.keyAction("move_right", 'd')) {
          moveAmount += display.getDelta();
          if (moveAmount >= 350.) {
            moveAmount = 0.;


            // Next tutorial.
            menuShown = true;
            Runnable r = new Runnable() {
              public void run() {
                promptNewRealm();
                tutorialStage = 2;
              }
            };


            Runnable r_alt = new Runnable() {
              public void run() {
                promptNewRealm();
                tutorialStage = 3;
              }
            };
            tutorialStage = 0;
            if (!file.exists(engine.APPPATH+engine.TEMPLATES_PATH)) {
              menu = new DialogMenu("", "back_welcome", dm_tutorial_2_alt_2, r_alt);
            } else {
              menu = new DialogMenu("", "back_welcome", dm_tutorial_1, r);
            }
          }
        }
      }
      break;

      // Lesson 2: choosing a realm.
    case 2:
      {
        // Simply wait until the player closes the menu.
        if (!menuShown) {

          Runnable r = new Runnable() {
            public void run() {
              tutorialStage = 3;
              currentTool = TOOL_NORMAL;
              // Allow temporarily to open/close menu so player can open/close main menu.
              doNotAllowCloseMenu = false;
            }
          };

          tutorialStage = 0;
          menuShown = true;
          // If the player hasn't chosen anything, show the alt dialog
          if (changedTemplate) {
            menu = new DialogMenu("", "back_welcome", dm_tutorial_2, r);
          } else {
            menu = new DialogMenu("", "back_welcome", dm_tutorial_2_alt, r);
          }
        }

        // Don't show any tutorial message during selecting a template.
      }
      break;

      // Lesson 3: select the grabber tool.
    case 3:
      {
        mssg = "Use the grabber tool!\nPress <tab>.";
        // Main menu opened.
        if (menuShown && menu != null && menu instanceof MainMenu) {
          mssg = "Now click the grabber tool.";
        }

        // Condition to get to the next tutorial stage.
        if (currentTool == TOOL_GRABBER) {
          doNotAllowCloseMenu = true;
          tutorialStage = 0;
          menuShown = true;
          Runnable r = new Runnable() {
            public void run() {
              tutorialStage = 4;
            }
          };
          menu = new DialogMenu("", "back_welcome", dm_tutorial_3, r);
        }
      }
      break;

      // Lesson 4: pick up an object
    case 4:
      {
        if (numItemsHeld == 0)
          mssg = "Pick up objects. Look at an object, then press 'o'!";
        else if (numgoal-numItemsHeld == 1)
          mssg = "Pick up 1 more item!";
        else
        mssg = "Pick up "+str(numgoal-numItemsHeld)+" more items!";


        if (currentTool != TOOL_GRABBER) {
          console.log("Please finish the tutorial before changing tools!");
          currentTool = TOOL_GRABBER;
        }
      }
      break;
    case 5:
      {
        if (numItemsHeld == numgoal)
          mssg = "Move the item somewhere else, then press 'p'!";
        else
          mssg = "Put down all your held items!";


        if (currentTool != TOOL_GRABBER) {
          console.log("Please finish the tutorial before changing tools!");
          currentTool = TOOL_GRABBER;
        }
      }
      break;
    }

    if (mssg.length() > 0) {
      app.noStroke();
      app.fill(0, 127);
      app.rect(WIDTH*0.1, 70, WIDTH*0.8, 200);

      app.fill(255);
      app.textFont(engine.DEFAULT_FONT, 38);
      app.textAlign(CENTER, CENTER);
      app.text(mssg, WIDTH*0.1, 70, WIDTH*0.8, 200);
    }
    
    if (ui.basicButton("Skip tutorial", display.WIDTH/2-200, display.HEIGHT-40-myUpperBarWeight, 400, 30)) {
      endTutorial();
      console.log("Skipped tutorial.");
    }
  }
}
