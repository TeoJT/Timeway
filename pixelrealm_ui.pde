
// Wanna find a name of a realm template without searching through tons of folders?
// grep -r "[realm name]" $(find ./ -type f -name "realmtemplate")


public class PixelRealmWithUI extends PixelRealm {

  private final String TEMPLATE_METADATA_FILENAME = "realmtemplate.json";

  private PImage IMG_BORDER_TILE;


  private String musicInfo = "";
  private String musicURL = "";

  private boolean menuShown = false;
  private boolean showPlayerPos = false;
  private SpriteSystemPlaceholder gui = null;
  private Menu menu = null;
  private boolean touchControlsEnabled = false;


  private String[] dm_welcome = {
    "Welcome to "+Engine.APP_NAME+".",
    "Your folders are realms.",
    "Your computer is a universe.",
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
    Engine.APP_NAME+" is an ongoing project. There may be bugs and missing features.",
    "But there are many more things to come.",
    "In the meantime, I hope you enjoy this demo."
  };

  //private String[] dm_hint_1 = {
  //  "Did you know you can create your own realm assets?",
  //  "Realms have 5 assets that make up its look and feel: sky, grass, trees, background music, and properties.",
  //  "These files can be found under the name .pixelrealm-... in your folders on your computer.",
  //  "If you are on MacOS or Linux, these files may be hidden.",
  //  "Try customising them, see what you can create.",
  //  "And feel free to submit your creations, somebody (Téo lol) would love to see them."
  //};



  // --- Constructors ---
  public PixelRealmWithUI(Engine engine, String dir) {
    super(engine, dir);
    // Ugh. whatever.

    IMG_BORDER_TILE = display.systemImages.get("menuborder").pimage;

    touchControlsEnabled = settings.getBoolean("touch_controls");
    // Obviously needed on phones, regardless of settings.
    if (isAndroid()) {
      touchControlsEnabled = true;
    }

    gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"gui/pixelrealm/");
    gui.suppressSpriteWarning = true;
    gui.interactable = false;
    ui.useSpriteSystem(gui);

    // Indicates first time running, run the tutorial.
    boolean statsExists = false;
    statsExists = isAndroid() ? file.exists(getAndroidWriteableDir()+engine.STATS_FILE) : file.exists(engine.APPPATH+engine.STATS_FILE);
    
    if (!statsExists) {
      this.requestTutorial();
    }
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
      if (!cached || gui.interactable) return gui.getSprite(cache_backgroundName).getX();
      return cache_backX;
    }

    protected float getY() {
      if (!cached || gui.interactable) return gui.getSprite(cache_backgroundName).getY();
      return cache_backY;
    }

    protected float getWidth() {
      if (!cached || gui.interactable) return (float)gui.getSprite(cache_backgroundName).getWidth();
      else return cache_backWi;
    }

    protected float getHeight() {
      if (!cached || gui.interactable) return (float)gui.getSprite(cache_backgroundName).getHeight();
      else return cache_backHi;
    }

    protected float getXmid() {
      if (!cached || gui.interactable) return gui.getSprite(cache_backgroundName).getX()+(float)gui.getSprite(cache_backgroundName).getWidth()*0.5;
      return cache_backX+cache_backWi*0.5;
    }

    protected float getYmid() {
      if (!cached || gui.interactable) return gui.getSprite(cache_backgroundName).getY()+(float)gui.getSprite(cache_backgroundName).getHeight()*0.5;
      return cache_backY+cache_backHi*0.5;
    }

    protected float getYbottom() {
      if (!cached || gui.interactable) return gui.getSprite(cache_backgroundName).getY()+(float)gui.getSprite(cache_backgroundName).getHeight();
      return cache_backY+cache_backHi;
    }

    protected void displayBackground(String backgroundName) {
      gui.spriteVary(backgroundName, "black");
      if (display.phoneMode) backgroundName += "-phone";
      if (!cached || gui.interactable) {
        cache_backgroundName = backgroundName;
        cache_backX = gui.getSprite(backgroundName).getX();
        cache_backY = gui.getSprite(backgroundName).getY();
        int wi   = gui.getSprite(backgroundName).getWidth();
        int hi   = gui.getSprite(backgroundName).getHeight();
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
    protected SpriteSystemPlaceholder.Sprite back;
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
      text("(Enter/return to contunue)", getXmid(), getYbottom()-70);

      boolean enterPressed = input.enterOnce;
      if (touchControlsEnabled) {
        enterPressed |= input.primaryClick && time > 4;
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

      if (ui.buttonVary("menu_yes", "tick_128", "Yes")) {
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





  class MainMenu extends TitleMenu {
    public MainMenu() {
      super("--- M E N U ---", "back-mainmenu");
    }
    public void display() {
      super.display();

      // --- Creator menu ---
      if (ui.buttonVary("creator_1", "new_entry_128", "Creator")) {
        sound.playSound("menu_select");
        menu = new CreatorMenu();
      }

      // --- Pocket menu ---
      if (ui.buttonVary("pocket_menu", "new_entry_128", "Pockets")) {
        sound.playSound("menu_select");
        menu = new PocketMenu();
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
      if (ui.buttonVary("terraform_menu", "new_entry_128", "Terraform")) {
        sound.playSound("menu_select");

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

        if (currRealm.versionCompatibility == 1 || currRealm.versionCompatibility != 2) {
          // Additional functionality for upgrading the realm.
          ryes = new Runnable() {
            public void run() {
              if (!COMPATIBILITY_VERSION.equals("2.0")) {
                menuShown = false;
                menu = null;
                console.bugWarn("Expecting COMPATIBILITY_VERSION "+COMPATIBILITY_VERSION+". Please remember to change this part of the code!");
                return;
              }

              currRealm.version = COMPATIBILITY_VERSION;
              currRealm.versionCompatibility = 2;

              menu = new CustomiseTerrainMenu();
              menuShown = true;
              currRealm.terraformWarning = false;
            }
          };
          menu = new YesNoMenu("Old version", "This realm uses version "+currRealm.version+" and needs to be upgraded to "+COMPATIBILITY_VERSION+" to be terraformed. Upgrade now and continue?", ryes, rno);
        } else if (currRealm.terraformWarning) {
          menu = new YesNoMenu("Warning", "Modifying the terrain generator will reset all terrain data in this realm.\nContinue?", ryes, rno);
        } else {
          menu = new CustomiseTerrainMenu();
          menuShown = true;
          currRealm.terraformWarning = false;
        }
      }

      // --- Grabber tool ---
      if (ui.buttonVary("grabber_1", "grabber_tool_128", "Grabber")) {
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

      // --- No tool ---
      if (ui.buttonVary("notool_1", "notool_128", "No tool")) {
        currentTool = TOOL_NORMAL;
        globalHoldingObjectSlot = null;
        currRealm.updateHoldingItem(globalHoldingObjectSlot);
        menuShown = false;
        sound.playSound("menu_select");
      }
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
        sound.playSound("menu_select");
        newFolder();
      }

      if (ui.buttonVary("newshortcut", "create_shortcut_128", "New shortcut")) {
        sound.playSound("menu_select");
        issueRefresherCommand(REFRESHER_PAUSE);
        ((PixelRealmState.ShortcutPortal)currRealm.createPRObjectAndPickup(currRealm.createShortcut())).loadShortcut();
        menuShown = false;
      }
    }

    public void newFolder() {
      sound.playSound("menu_select");

      Runnable r = new Runnable() {
        public void run() {
          if (input.keyboardMessage.length() == 0) {
            menuShown = false;
            return;
          }
          String folderpath = currRealm.stateDirectory+input.keyboardMessage;
          if (!file.exists(folderpath)) {
            issueRefresherCommand(REFRESHER_PAUSE);
            new File(folderpath).mkdirs();
          } else {
            sound.playSound("nope");
            console.log(input.keyboardMessage+" already exists!");
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

      engine.beginInputPrompt("Folder name:", r);
      menu = new InputPromptMenu();
    }

    public void newEntry() {
      sound.playSound("menu_select");

      Runnable r = new Runnable() {
        public void run() {
          if (input.keyboardMessage.length() == 0) {
            menuShown = false;
            return;
          }

          String path = currRealm.stateDirectory+input.keyboardMessage+"."+engine.ENTRY_EXTENSION;
          if (file.exists(path)) {
            sound.playSound("nope");
            console.log(input.keyboardMessage+" already exists!");
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

      engine.beginInputPrompt("Entry name:", r);
      menu = new InputPromptMenu();
    }
  }

  class PocketMenu extends Menu {

    public void display() {
      displayBackground("back-pocketmenu");

      gui.spriteVary("pocket_line1", "white");
      gui.spriteVary("pocket_line2", "white");


      if (ui.buttonVary("pocket_back", "back_arrow_128", "")) {
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

  class NewRealmMenu extends TitleMenu {
    int tempIndex = -1;
    int coolDown = 0;

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
      coolDown = 5;

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
      app.text("Navigate with < and > keys, press <enter/return> to confirm.", getXmid(), getYbottom()-40);

      // Lil easter egg for the glitched realm
      if (previewName.equals("YOUR FAVOURITE REALM")) {
        app.noStroke();
        app.fill(255);
        int l = int(random(5, 30));
        for (int i = 0; i < l; i++)
          app.rect(random(getXmid()-200, getXmid()+200), random(getYmid()-20, getYmid()+20), random(10, 50), random(5, 20));
      }


      if ((input.keyActionOnce("inventorySelectLeft")
        || ui.buttonVary("newrealm-prev", "back_arrow_128", ""))
        && coolDown == 0) {
        tempIndex--;
        if (tempIndex < 0) tempIndex = templates.size()-1;
        preview(tempIndex);
      }
      if ((input.keyActionOnce("inventorySelectRight")
        || ui.buttonVary("newrealm-next", "forward_arrow_128", ""))
        && coolDown == 0) {
        tempIndex++;
        if (tempIndex > templates.size()-1) tempIndex = 0;
        preview(tempIndex);
      }
      if (input.enterOnce || ui.buttonVary("newrealm-confirm", "tick_128", "")) {
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
        boolean conflict = false;
        
        // I've commented about it so many times at this point that, do you really need to know?
        // Actually for all I know this might be the first time you read this.
        // Basically, can't list files in our own files on Android.
        //if (isAndroid()) {
        //  currRealm.img_grass.get().save(dest+REALM_GRASS+".png");
          
        //  for (int i = 0; i < currRealm.img_sky.length(); i++) {
        //    currRealm.img_sky.get(i).save(dest+REALM_SKY+"-"+str(i+1)+".png");
        //  }
          
        //  for (int i = 0; i < currRealm.img_tree.length(); i++) {
        //    currRealm.img_tree.get(i).save(dest+REALM_TREE+"-"+str(i+1)+".png");
        //  }
          
        //  JSONObject json = null; 
        //  if (file.exists(realmDir+REALM_TURF)) {
        //    json = loadJSONObject(realmDir+REALM_TURF);
        //  }
        //  else if (file.exists(file.unhide(realmDir+REALM_TURF))) {
        //    json = loadJSONObject(file.unhide(realmDir+REALM_TURF));
        //  }
        //  if (json != null) saveJSONObject(json, dest+REALM_TURF);
        //}
        
        if (isAndroid()) {
          String[] files = loadStrings(realmDir+"load_list.txt");
          for (String src : files) {
            String name = file.getFilename(src);
            
            // The realmtemplate file is an exception
            if (name.equals(TEMPLATE_METADATA_FILENAME))
              continue;
  
            if (file.exists(dest+name)) {
              conflict = true;
              break;
            }
  
            movefiles.add(src);
          }
        }
        else {
          for (File f : realmfile.listFiles()) {
            String src = f.getAbsolutePath().replaceAll("\\\\", "/");
            String name = file.getFilename(src);
  
            // The realmtemplate file is an exception
            if (name.equals(TEMPLATE_METADATA_FILENAME))
              continue;
  
            if (file.exists(dest+name)) {
              conflict = true;
              break;
            }
  
            movefiles.add(src);
          }
        }
        
        issueRefresherCommand(REFRESHER_PAUSE);
        if (!conflict) {
          for (String src : movefiles) {
            if (!file.copy(src, dest+file.getFilename(src))) {
              prompt("Copy error", "An error occured while copying realm template files. Maybe permissions are denied?");
              // Return here so the menu stays open.
              return;
            }
          }

          // Successful so we can close the menu.
          menuShown = false;
          menu = null;
        } else {
          prompt("Can't copy template", "You already have realm asset files in this folder.");
        }
      }

      // Bug fix: immediately pausing movement causes cached sin and cos directions to be outdated
      // resulting in weird billboard 3d objects facing the wrong angle.
      // Delay the pausing of movement just a lil bit to let it update.
      movementPaused = (tmr++ > 2);
      if (coolDown > 0) coolDown--;
    }
  }



  class CustomiseTerrainMenu extends TitleMenu {

    private int generatorIndex = 1;

    private boolean mouseDown = true;

    public CustomiseTerrainMenu() {
      super("", "back-customise");
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
        for (PixelRealmState.CustomNode n : currRealm.terrain.customNodes) {
          n.x = x;
          n.wi = cache_backWi-100.;

          n.display(y);

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

      currRealm.terrain.updateAttribs();
    }

    public void close() {
      currRealm.chunks.clear();
      currRealm.regenerateTrees();
      //chunks = new HashMap<Integer, TerrainChunkV2>();
    }
  }









  // Called from base pixelrealm
  private void errorPrompt(String title, String mssg) {
    if (gui == null) return;
    DialogMenu m = new DialogMenu(title, "back-newrealm", mssg);
    m.setAppearTimer(20);
    menu = m;
    menuShown = true;
  }

  protected void promptPocketConflict(String filename) {
    String txt = "You have a duplicate file in your pocket ("+filename+"). You can't move between realms with duplicate items in your pockets.";
    errorPrompt("Pocket conflict!", txt);
  }

  protected void promptFailedToMove(String filename) {
    String txt = "Failed to move "+filename+". Maybe permissions denied?";
    errorPrompt("Move failed", txt);
  }

  protected void promptFileConflict(String filename) {
    String txt = filename+" already exists in this realm.";
    DialogMenu m = new DialogMenu("File conflict", "back-newrealm", txt);
    menu = m;
    menuShown = true;
  }

  protected void promptMoveAbstractObject(String filename) {
    String txt = filename+" is a non-file item and can't be moved outside of its realm. Please place down the item here.";
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












  public void runMenu() {
    modifyTerrain = false;
    if (menuShown && menu != null) {
      ui.useSpriteSystem(gui);
      menu.display();

      modifyTerrain = (menu instanceof CustomiseTerrainMenu);
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
        input.setAction("menu");
        click = true;
      }
      if (ui.buttonVary("touch-prevrealm", "touch_prevrealm", "")) {
        input.setAction("prevDirectory");
        click = true;
      }
      if (ui.buttonVary("touch-home", "touch_home", "")) {
        input.setAction("quickWarp1");
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
        input.setAction("primaryAction");
        click = true;
      }
      if (ui.buttonVary("touch-b", "touch_b", "")) {
        input.setAction("secondaryAction");
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
          input.setAction("dash");
        }
        
        if (touchLeft) {
          input.setAction("moveLeft");
        }
        else if (touchRight) {
          input.setAction("moveRight");
        }


        if (ui.buttonHoverVary("touch-jump")) {
          input.setAction("jump");
        }
        
        if (touchForward) {
          if (ui.buttonHoverVary("touch-walkback")) {
            input.setAction("moveBackwards");
          } else {
            input.setAction("moveForewards");
          }
          
          if (ui.buttonHoverVary("touch-look-left")) {
            input.setAction("lookLeftTouch");
          }
          if (ui.buttonHoverVary("touch-look-right")) {
            input.setAction("lookRightTouch");
          }
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
          image(p.item.img.get(), x, y, 64, 64);
        invx += 70;
      }

      if (touchControlsEnabled) {

        if (ui.buttonVary("touch-slot-left", "touch_left", "")) {
          input.setAction("inventorySelectLeft");
        }
        if (ui.buttonVary("touch-slot-right", "touch_right", "")) {
          input.setAction("inventorySelectRight");
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


  public void controls() {
    // Tab pressed.
    // Hacky way of allowing an exception for our input prompt menu's
    boolean tmp = engine.inputPromptShown;
    engine.inputPromptShown = false;
    if (input.keyActionOnce("menu") && !engine.commandPromptShown) {
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
    gui.updateSpriteSystem();
  }

  protected void lowerBar() {
    super.lowerBar();
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

      if (musicURL.length() > 0 && engine.mouseY() > y && input.primaryClick) {
        app.link(musicURL);
      }
    } else {
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
    // For now just save some file so that it exists.
    if (isAndroid()) {
      app.saveJSONObject(new JSONObject(), getAndroidWriteableDir()+engine.STATS_FILE);
    }
    else {
      app.saveJSONObject(new JSONObject(), engine.APPPATH+engine.STATS_FILE);
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
        if (input.keyAction("moveForewards") || input.keyAction("moveBackwards") || input.keyAction("moveLeft") || input.keyAction("moveRight")) {
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
