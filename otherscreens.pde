public class Updater extends Screen {
  String updateName = "";
  String headerText = "An update is available!";
  String displayMessage = "This update contains the following additions, changes, and/or fixes:\n";
  String footerMessage = "Downloading and installing will run in the background as "+engine.getAppName()+" runs, so please leave Timeway running until the update completes. Don't worry, none of your personal data will be modified.";
  String patchNotes = "";
  boolean startedMusic = false;
  JSONObject updateInfo;
  
  public Updater(TWEngine engine, JSONObject updateInfo) {
    super(engine);
    this.updateInfo = updateInfo;
    //sound.streamMusicWithFade(engine.APPPATH+UPDATE_MUSIC);
    myUpperBarWeight = 70;
    try {
      updateName = updateInfo.getString("update-name");
      
      if (!updateInfo.getString("display-header", "[default]").equals("[default]"))
        headerText = updateInfo.getString("display-header");
        
      if (!updateInfo.getString("display-message", "[default]").equals("[default]"))
        displayMessage = updateInfo.getString("display-message");
        
      if (!updateInfo.getString("message-footer", "[default]").equals("[default]"))
        footerMessage = updateInfo.getString("message-footer");
      else if (!updateInfo.getString("display-footer", "[default]").equals("[default]"))  // Oops
        footerMessage = updateInfo.getString("display-footer");
      
      patchNotes = updateInfo.getString("patch-notes", "");
    }
    catch (RuntimeException e) {
      console.warn("Something went wrong with getting update info.");
      e.printStackTrace();
    }
  }
  
  public void upperBar() {
    super.upperBar();
    app.textFont(engine.DEFAULT_FONT);
    app.textSize(50);
    app.textAlign(CENTER, TOP);
    app.fill(0);
    app.text("Update", WIDTH/2, 10);
  }
  
  public boolean button(String display, float x, float y) {
    x = x+10;
    float wi = (WIDTH/2)-40;    // idk why 40
    float hi = 50;
    return ui.basicButton(display, x, y, wi, hi);
  }
  
  public void content() {
    
    float x, y;
    app.textFont(engine.DEFAULT_FONT);
    app.textSize(50);
    app.textAlign(LEFT, TOP);
    app.fill(255);
    x = 10;
    y = myUpperBarWeight+50;
    app.text(headerText, x, y);
    
    app.textSize(30);
    app.fill(255, 255, 200);
    x = 10;
    y = myUpperBarWeight+100;
    app.text(updateName, x, y);
    
    app.textSize(30);
    app.fill(255);
    x = 10;
    y = myUpperBarWeight+150;
    app.text(displayMessage, x, y, WIDTH-x*2, 100);
    
    app.textSize(20);
    app.fill(255);
    x = 10;
    y = myUpperBarWeight+250;
    float footerY = 150;
    app.text(patchNotes, x, y, WIDTH-x*2, HEIGHT-myLowerBarWeight-y-footerY);
    
    app.textSize(20);
    app.fill(200);
    x = 10;
    y = HEIGHT-myLowerBarWeight-footerY;
    app.text(footerMessage, x, y, WIDTH-x*2, footerY);
    
    if (button("Later", 0, HEIGHT-myLowerBarWeight-60)) {
      previousScreen();
    }
      
    if (button("Update", WIDTH/2, HEIGHT-myLowerBarWeight-60)) {
      String downloadURL = "";
      String downloadLocation = file.getMyDir()+"timeway-update-download.zip";
      if (isWindows()) {
          downloadURL = updateInfo.getString("windows-download", "");
      }
      else if (isLinux()) {
          downloadURL = updateInfo.getString("linux-download", "");
      }
      else if (isMacOS()) {
          downloadURL = updateInfo.getString("macos-download", "");
      }
      engine.beginUpdate(downloadURL, downloadLocation);
      previousScreen();
    }
  }
}



























public class Benchmark extends Screen {
  
  public SpriteSystem gui;
  
  private float highestTime = 0f;
  
  public Benchmark(TWEngine e) {
    super(e);
    textFont(engine.DEFAULT_FONT);
    gui = new SpriteSystem(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/benchmark/");
    ui.useSpriteSystem(gui);
    myUpperBarColor = color(100);
    gui.interactable = false;
    
    // Find highest benchmark time (used to scale results relative to highest time).
    for (int i = 1; i < engine.benchmarkArray.length; i++) {
      float time = (float)((int)engine.benchmarkArray[i]);
      
      if (time > highestTime) {
        highestTime = time;
      }
    }
  }
  
  public void upperBar() {
    super.upperBar();
    if (ui.button("back", "back_arrow_128", "")) {
      previousScreen();
    }
    gui.updateSpriteSystem();
  }
  
  public void content() {
    // We expect the benchmark to have completed
    
    textAlign(LEFT, TOP);
    textFont(engine.DEFAULT_FONT, 16f);
    
    text("Benchmark results", 10, myUpperBarWeight+10);
    
    
    float x = 10f;
    float y = myUpperBarWeight+50f;
    
    float c = 0f;
    
    noStroke();
    colorMode(HSB, 255);
    for (int i = 1; i < engine.benchmarkResults.size(); i++) {
      float time = (float)((int)engine.benchmarkArray[i]);
      
      fill(c, 255, 128);
      c += 40.;
      c %= 255.;
      float WI = WIDTH-20f;
      rect(x, y, (time/highestTime)*WI, 20);
      
      fill(255);
      text(engine.benchmarkResults.get(i), x, y+3);
      
      y += 25f;
      
    }
    colorMode(RGB, 255);
  }
}





























public class Explorer extends Screen {
  
  
  //private String currentDir = DEFAULT_DIR;
  
  
  //DisplayableFile backButtonDisplayable = null;
  SpriteSystem gui;
  private int numTimewayEntries;
  public  float scrollBottom = 0.0;
  private float scrollOffset = 0f;
  
  public Explorer(TWEngine engine) {
        super(engine);
        
        file.openDirInNewThread(engine.DEFAULT_DIR);
        gui = new SpriteSystem(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/explorer/");
        gui.repositionSpritesToScale();
        gui.interactable = false;
        
        //myLowerBarColor   = color(120);
        //myUpperBarColor   = color(120);
        myBackgroundColor = color(0);
  }
  
  // Sorry for code duplication!
  public Explorer(TWEngine engine, String dir) {
        super(engine);
        
        file.openDirInNewThread(dir);
        gui = new SpriteSystem(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/explorer/");
        gui.repositionSpritesToScale();
        gui.interactable = false;
        
        //myLowerBarColor   = color(120);
        //myUpperBarColor   = color(120);
        myBackgroundColor = color(0);
        
        //engine.openDir(dir);
  }
  
  // This method shall render all the files in the current dir
  private void renderDir() {
    
    final float TEXT_SIZE = 50;
    final float BOTTOM_SCROLL_EXTEND = 300;   // The scroll doesn't go all the way down to the bottom for whatever reason.
                                              // So let's add a little more room to scroll down to the bottom.
    
    app.textFont(engine.DEFAULT_FONT, 50);
    app.textSize(TEXT_SIZE);
    for (int i = 0; i < file.currentFiles.length; i++) {
      float textHeight = app.textAscent() + app.textDescent();
      float x = 50;
      float wi = TEXT_SIZE + 20;
      float y = 150 + i*TEXT_SIZE+scrollOffset;
      
      // Sorry not sorry
      try {
        if (file.currentFiles[i] != null) {
          if (engine.mouseX() > x && engine.mouseX() < x + app.textWidth(file.currentFiles[i].filename) + wi && engine.mouseY() > y && engine.mouseY() < textHeight + y) {
            // if mouse is overing over text, change the color of the text
            app.fill(100, 0, 255);
            app.tint(100, 0, 255);
            // if mouse is hovering over text and left click is pressed, go to this directory/open the file
            if (input.primaryOnce) {
              if (file.currentFiles[i].isDirectory())
                scrollOffset = 0.;
                
              file.open(file.currentFiles[i]);
            }
          } else {
            app.noTint();
            app.fill(255);
          }
          
          if (file.currentFiles[i].icon != null)
            display.img(file.currentFiles[i].icon, 50, y, TEXT_SIZE, TEXT_SIZE);
          app.textAlign(LEFT, TOP);
          app.text(file.currentFiles[i].filename, x + wi, y);
          app.noTint();
        }
      }
      catch (ArrayIndexOutOfBoundsException e) {
        
      }
      catch (NullPointerException ex) {
        
      }
    }
    
    scrollBottom = max(0, (file.currentFiles.length*TEXT_SIZE-HEIGHT+BOTTOM_SCROLL_EXTEND));
  }
  
  // THIS IS COPIED from the editor tab.
  // TODO: make this use one script from the engine or something.
  // For the time being let's just have it copy+pasted here.
  private boolean button(String name, String texture, String displayText) {

        // This doesn't change at all.
        // I just wanna keep it in case it comes in useful later on.
        boolean guiClickable = true;

        // Don't want our messy code to spam the console lol.
        gui.suppressSpriteWarning = true;

        boolean hover = false;

        // Full brightness when not hovering
        app.tint(255);
        app.fill(255);

        // To click:
        // - Must not be in a minimenu
        // - Must not be in gui move sprite / edit mode.
        // - also the guiClickable thing.
        if (gui.buttonHover(name) && guiClickable && !gui.interactable) {

            // Slight gray to indicate hover
            app.tint(210);
            app.fill(210);
            hover = true;
        }

        // Display the button, will be affected by the hover color.
        gui.button(name, texture, displayText);
        app.noTint();

        // Don't have "the boy who called wolf", situation, turn back on warnings
        // for genuine troubleshooting.
        gui.suppressSpriteWarning = false;

        // Only when the button is actually clicked.
        return hover && input.primaryOnce;
    }
    
  
  
  private void renderGui() {
    
    //************NEW ENTRY************
    if (button("new_entry", "new_entry_128", "New entry")) {
      // Man this code here is ANCIENT
      //String newName = file.currentDir+engine.appendZeros(numTimewayEntries, 5)+"."+engine.ENTRY_EXTENSION;
      //requestScreen(new Editor(engine, newName));
      
      // Here's some newer code.
      Runnable r = new Runnable() {
        public void run() {
          if (engine.promptInput.length() <= 1) {
            console.log("Please enter a valid entry name!");
            return;
          }
          String entryname = file.currentDir+engine.promptInput+"."+engine.ENTRY_EXTENSION;
          new File(entryname).mkdirs();
          refreshDir();
          requestScreen(new Editor(engine, entryname));
        }
      };
      
      engine.beginInputPrompt("Entry name:", r);
    }
    
    //************NEW FOLDER************
    if (button("new_folder", "new_folder_128", "New folder")) {
      
      Runnable r = new Runnable() {
        public void run() {
          if (engine.promptInput.length() <= 1) {
            console.log("Please enter a valid folder name!");
            return;
          }
          String foldername = file.currentDir+engine.promptInput;
          new File(foldername).mkdirs();
          refreshDir();
        }
      };
      
      engine.beginInputPrompt("Folder name:", r);
    }
    
    //***********CLOSE BUTTON***********
    //if (button("cross", "cross", "")) {
    //  exit();
    //}
    
    //***********PixeL REALM BUTTON***********
    //if (button("world", "world_128", "Pixel Realm")) {
    //  requestScreen(new PixelRealmWithUI(engine, file.currentDir));
    //}
    
    //***********BACK BUTTON***********
    if (button("back", "back_arrow_128", "")) {
      previousScreen();
    }
    
    gui.updateSpriteSystem();
    
  }
  
  // Just use the default background
  public void backg() {
        app.fill(myBackgroundColor);
        app.noStroke();
        app.rect(0, 0, WIDTH, HEIGHT);
  }
  
  public void upperBar() {
    display.shader("fabric", "color", 0.5,0.5,0.5,1., "intensity", 0.1);
    super.upperBar();
    app.resetShader();
    renderGui();
  }
  
    
  public void lowerBar() {
    app.fill(myBackgroundColor);
    app.noStroke();
    app.noStroke();
    app.rect(0, HEIGHT-myLowerBarWeight, WIDTH, myLowerBarWeight);
    
    display.shader("fabric", "color", 0.5,0.5,0.5,1., "intensity", 0.1);
    super.lowerBar();
    display.resetShader();
  }
    
  
  public void refreshDir() {
    file.openDirInNewThread(file.currentDir);
  }
  
  
  // Let's render our stuff.
  public void content() {
      
      if (file.loading) {
        ui.loadingIcon(WIDTH/2, HEIGHT/2);
      }
      else {
        scrollOffset = input.processScroll(scrollOffset, 0., scrollBottom+1.0);
        renderDir();
      }
      
      app.fill(myBackgroundColor);
      app.noStroke();
      app.rect(0, 0, WIDTH, 150);
      
      app.fill(255);
      app.textFont(engine.DEFAULT_FONT, 50);
      app.textSize(70);
      app.textAlign(LEFT, TOP);
      app.text("Explorer", 50, 80);
      
      engine.displayInputPrompt();
  }
}









public class HomeScreen extends Screen {
    private SpriteSystem gui = null;

    public HomeScreen(TWEngine engine) {
        super(engine);
        myBackgroundColor = color(10);
        myUpperBarColor = color(50);
        myLowerBarColor = color(50);
        
        gui = new SpriteSystem(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/homescreen/");
        gui.interactable = false;
    }


    public void transitionAnimation() {

    }
    
    
    protected void previousReturnAnimation() {
      buttonOnce = true;
    }
    
    private int before = 0;
    private boolean buttonOnce = true;
    private float floatIn = 1f;

    public void content() {
      
        
        //app.noStroke();
        //app.textAlign(CENTER, CENTER);
        //app.textFont(engine.DEFAULT_FONT, 34);
        //app.fill(0, 255-(255*floatIn));
        //app.text("by Teo Taylor", WIDTH/2-3, HEIGHT/2+150-3);
        //app.fill(255, 255-(255*floatIn));
        //app.text("by Teo Taylor", WIDTH/2, HEIGHT/2+150);
        
        
        
        // Title logo
        app.tint(255, 255-(255*floatIn));
        gui.spriteVary("homescreen-title");
        app.noTint();
        
        //gui.getSprite("homescreen-title").move(0f, 
        
        SpriteSystem.Sprite logoSprite = gui.getSprite("homescreen-title");
        float offY = logoSprite.getY()+logoSprite.getHeight()-60;
        
        app.noStroke();
        app.textAlign(CENTER, CENTER);
        app.textFont(engine.DEFAULT_FONT, 34);
        app.fill(0, 255-(255*floatIn));
        app.text("by Teo Taylor", WIDTH/2-3, offY);
        app.fill(255, 255-(255*floatIn));
        app.text("by Teo Taylor", WIDTH/2, offY);
        
        //offY += 34;
        
        floatIn *= PApplet.pow(0.95, display.getDelta());
        
        // Version in bottom-right.
        app.fill(255);
        app.noStroke();
        app.textAlign(LEFT, CENTER);
        app.textFont(engine.DEFAULT_FONT, 30);
        app.fill(0);
        app.text(TWEngine.VERSION, 10-3, HEIGHT-myLowerBarWeight-30-3);
        app.fill(255);
        app.text(TWEngine.VERSION, 10, HEIGHT-myLowerBarWeight-30);
        
        boolean pixelrealmButton = ui.basicButton("Pixel Realm", display.WIDTH/2-400, (offY += 60), 800, 50);
        boolean explorerButton = ui.basicButton("Explorer", display.WIDTH/2-400, (offY += 60), 800, 50);
        boolean binButton = ui.basicButton("Recycle bin", display.WIDTH/2-400, (offY += 60), 800, 50);
        boolean settingsButton = ui.basicButton("Settings", display.WIDTH/2-400, (offY += 60), 800, 50);
        boolean creditsButton = ui.basicButton("Credits", display.WIDTH/2-400, (offY += 60), 800, 50);
        
        if (buttonOnce) {
          
        }
        
        if (pixelrealmButton) {
          PixelRealmWithUI pixelrealm = new PixelRealmWithUI(engine, engine.DEFAULT_DIR);
          requestScreen(pixelrealm);
          buttonOnce = false;
        }
        
        if (explorerButton) {
          requestScreen(new Explorer(engine));
          buttonOnce = false;
        }
        
        if (settingsButton) {
          requestScreen(new SettingsScreen(engine));
          buttonOnce = false;
        }
        
        if (creditsButton) {
          if (file.exists(engine.APPPATH+CreditsScreen.CREDITS_PATH)) {
            requestScreen(new CreditsScreen(engine));
            buttonOnce = false;
          }
          else {
            console.warn("Credits file is missing.");
          }
        }
        
        if (binButton) {
          requestScreen(new RecycleBinScreen(engine));
        }
        
        gui.updateSpriteSystem();
        
    }
}










public class RecycleBinScreen extends Screen {
  //private String currentDir = DEFAULT_DIR;
  
  private SpriteSystem gui;
  
  //DisplayableFile backButtonDisplayable = null;
 
  private float scrollBottom = 0.0f;
  private float prevMouseY = 0.0f;
  private float scrollVelocity = 0f;
  private boolean scrolling = false;
  private boolean scrolled = false;
  private float scrollOffset = 0f;
  private boolean prompt = false;
  private boolean itemExistsError = false;
  private int itemToRestore = 0;
  
  private ArrayList<String> originalFilenames;
  private ArrayList<String> names;
  private ArrayList<String> originalExts;
  private ArrayList<String> originalLocations;
  private AtomicBoolean runChecker = new AtomicBoolean(true);
  private AtomicBoolean pauseChecker = new AtomicBoolean(false);
  private AtomicBoolean changeDetected = new AtomicBoolean(false);
  
  private final float ITEM_HEIGHT = 80f;
  final float BOTTOM_SCROLL_EXTEND = 300;
  
  public RecycleBinScreen(TWEngine engine) {
        super(engine);
        
        gui = new SpriteSystem(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/recyclebin/");
        ui.useSpriteSystem(gui);
        gui.interactable = false;
        
    
        myLowerBarColor   = color(50);
        myUpperBarColor   = color(50);
        myBackgroundColor = color(25);
        myUpperBarWeight  = 80f;
        myLowerBarWeight  = 120f;
        
        refresh();
        startCheckerThread();
  }
  
  private void startCheckerThread() {
    Thread t1 = new Thread(new Runnable() {
      public void run() {
        try {
          String lastModified = file.getLastModified(engine.APPPATH+file.RECYCLE_BIN_PATH);
          
          while (runChecker.get()) {
            try {
              Thread.sleep(1000);
            }
            catch (InterruptedException e) {
              // we don't care.
            }
            
            // Pause by just skipping the check.
            if (pauseChecker.getAndSet(false)) {
              lastModified = file.getLastModified(engine.APPPATH+file.RECYCLE_BIN_PATH);
              continue;
            }
            
            String newLastModified = file.getLastModified(engine.APPPATH+file.RECYCLE_BIN_PATH);
            
            if (!lastModified.equals(newLastModified)) {
              lastModified = file.getLastModified(engine.APPPATH+file.RECYCLE_BIN_PATH);
              changeDetected.set(true);
            }
          }
        }
        catch (NullPointerException e) {
          
        }
      }
    }
    );
    //t1.setDaemon(true);
    t1.start();
  }
  
  
  private void refresh() {
    file.recycleJsonLoaded = false;
    originalLocations = file.getOldLocationListFromRecycle();
    names = file.getNameListFromRecycle();
    originalFilenames = new ArrayList<String>();
    originalExts = new ArrayList<String>();
    for (int i = 0; i < originalLocations.size(); i++) {
      originalFilenames.add(i, file.getFilename(originalLocations.get(i)));
      originalExts.add(i, file.getExt(originalFilenames.get(i)));
    }
    updateMenu();
  }
  
  private void updateMenu() {
    scrollBottom = max(0, (originalFilenames.size()*ITEM_HEIGHT-HEIGHT+BOTTOM_SCROLL_EXTEND));
  }
  
  // Just use the default background
  public void backg() {
        app.fill(myBackgroundColor);
        app.noStroke();
        app.rect(0, 0, WIDTH, HEIGHT);
  }
  
  public void upperBar() {
    myUpperBarWeight  = 80f;
    myLowerBarWeight  = 120f;
    
    //display.shader("fabric", "color", 0.5,0.5,0.5,1., "intensity", 0.1);
    super.upperBar();
    //app.resetShader();
    
    app.fill(255);
    app.textFont(engine.DEFAULT_FONT, 70f);
    app.textAlign(LEFT, TOP);
    app.text("Recycle bin", 100f, 10f);
    
    ui.useSpriteSystem(gui);
    if (!prompt) {
      if (ui.button("back", "back_arrow_128", "")) {
        previousScreen();
      }
    }
    gui.updateSpriteSystem();
  }
  
  
    
  public void lowerBar() {
    //display.shader("fabric", "color", 0.5,0.5,0.5,1., "intensity", 0.1);
    super.lowerBar();
    //display.resetShader();
    
    app.fill(255f, 127f, 127f);
    app.textFont(engine.DEFAULT_FONT, 16f);
    app.textAlign(CENTER, TOP);
    
    if (!prompt) {
      float x = WIDTH*0.1f, y = HEIGHT-myLowerBarWeight+10f, wi = WIDTH*0.8f, hi = myLowerBarWeight;
      app.text("For safety reasons, Timeway cannot permanently delete files in the recycle bin. If you wish to empty your recycling bin, please do so manually via your system's file explorer.\nClick here to open the recycle bin folder.",
      x, y, wi, hi);
      if (ui.mouseInArea(x, y, wi, hi) && input.primaryOnce) {
        sound.playSound("select_any");
        file.open(engine.APPPATH+file.RECYCLE_BIN_PATH);
      }
    }
  }
  
  private void restore(int item) {
    pauseChecker.set(true);
    boolean success = file.mv(engine.APPPATH+file.RECYCLE_BIN_PATH+names.get(item), originalLocations.get(item));
    
    if (success) {
      console.log("Restored \""+originalFilenames.get(itemToRestore)+"\".");
      originalFilenames.remove(itemToRestore);
      originalLocations.remove(itemToRestore);
      names.remove(itemToRestore);
      originalExts.remove(itemToRestore);
      updateMenu();
    }
    else {
      console.log("Failed to restore \""+originalFilenames.get(itemToRestore)+"\".");
    }
  }
  
  protected void displayItem(int i) {
        if (originalFilenames.get(i) == null) return;
        
        float x = 30f;
        float y = myUpperBarWeight+30f+i*ITEM_HEIGHT+scrollOffset;
        
        // Restore button
        float wi = 200f, hi = 50f;
        float RESTORE_BUTTON_X = WIDTH-wi-60f;
        
        // Open (preview) file if clicked
        app.fill(255f);
        if (ui.mouseInArea(x, y, RESTORE_BUTTON_X-50f, ITEM_HEIGHT) && !prompt) {
          app.fill(210f);
          if (input.primarySolid && mouseWwithinContent()) {
            sound.playSound("select_any");
            
            String location = engine.APPPATH+file.RECYCLE_BIN_PATH+originalFilenames.get(i);
            
            if (originalExts.get(i).equals(engine.ENTRY_EXTENSION)) {
              file.openEntryReadonly(location);
            }
            else {
              file.open(location);
            }
            
          }
        }
        
        // Don't bother rendering item if offscreen
        if (y < -ITEM_HEIGHT || y > HEIGHT) return;
        
        // Icon
        float ICON_WIDTH = 58f;
        display.img(file.extIcon(originalExts.get(i)), x, y, ICON_WIDTH, ICON_WIDTH);
        
        x += ICON_WIDTH+10f;
        
        // Filename
        app.textFont(engine.DEFAULT_FONT, 34f);
        app.textAlign(LEFT, TOP);
        if (originalFilenames.get(i).length() > 66) {
          app.text(originalFilenames.get(i).substring(0, 64)+"...", x, y);
        }
        else {
          app.text(originalFilenames.get(i), x, y);
        }
        
        // Original location
        app.fill(100f);
        app.textFont(engine.DEFAULT_FONT, 20f);
        
        if (originalLocations.get(i).length() > 130) {
          app.text(originalLocations.get(i).substring(0, 128)+"...", x, y+38f);
        }
        else {
          app.text(originalLocations.get(i), x, y+38f);
        }
        
        
        
        
        x = RESTORE_BUTTON_X;
        y += 20f;
        
        app.stroke(255f);
        app.strokeWeight(1f);
        if (ui.mouseInArea(x, y, wi, hi) && !prompt) {
          app.fill(160, 140, 200); 
          
          if (input.primarySolid) {
            sound.playSound("select_any");
            prompt = true;
            scrolling = false;
            itemToRestore = i;
            
            // We can't move the item to its original location if another file already exists there.
            if (file.exists(originalLocations.get(i))) {
              itemExistsError = true;
            }
          }
        }
        else {
          app.fill(160-40, 140-40, 200-40); 
        }
        
        app.rect(x, y, wi, hi);
        
        // Text
        app.fill(255);
        app.textSize(36f);
        app.text("Restore", x+25f, y+10f);
  }
  
  protected void displayPrompt() {
    // Restore item prompt (yes/no prompt)
    if (prompt) {
      gui.sprite("recyclebin_restore_back", "black");
      
      float x = gui.getSprite("recyclebin_restore_back").getX();
      float y = gui.getSprite("recyclebin_restore_back").getY();
      float wi = gui.getSprite("recyclebin_restore_back").getWidth();
      app.textSize(24f);
      app.textAlign(CENTER, TOP);
      if (itemExistsError) {
        app.text("Cannot restore \""+originalFilenames.get(itemToRestore)+"\" because a file already exists at \""+originalLocations.get(itemToRestore)+"\".", x, y+30f, wi, HEIGHT);
        
        if (ui.buttonVary("recyclebin_restore_ok", "cross_128", "Dismiss") || input.enterOnce) {
          sound.playSound("select_any");
          prompt = false;
          itemExistsError = false;
          input.accidentalClickPrevention();
        }
      }
      else {
        app.text("Restore \""+originalFilenames.get(itemToRestore)+"\"?", x, y+30f, wi, HEIGHT);
        
        gui.sprite("recyclebin_icontorestore", file.extIcon(originalExts.get(itemToRestore)));
        
        if (ui.buttonVary("recyclebin_restore_yes", "tick_128", "Yes") || input.enterOnce) {
          sound.playSound("select_any");
          prompt = false;
          restore(itemToRestore);
          input.accidentalClickPrevention();
        }
        if (ui.buttonVary("recyclebin_restore_no", "cross_128", "No")) {
          sound.playSound("select_any");
          prompt = false;
          input.accidentalClickPrevention();
        }
      }
    }
    
    engine.displayInputPrompt();
  }
  
  protected void baseLogic() {
        
    if (changeDetected.compareAndSet(true, false)) {
      refresh();
      console.log("Updated recycle bin.");
    }
    
    if (originalFilenames.size() == 0) {
      app.fill(100);
      app.textFont(engine.DEFAULT_FONT, 40f);
      app.textAlign(CENTER, TOP);
      app.text("Recycle bin is empty.", WIDTH/2, myUpperBarWeight+200f);
    }
  }
  
  // Let's render our stuff.
  public void content() {
    
      // Scrolling logic 
      // TODO: This should really be part of the engine code.
      if (input.primaryOnce && input.mouseY() > myUpperBarWeight && input.mouseY() < HEIGHT-myLowerBarWeight) {
        scrolling = true;
      }
      if (input.primaryReleased || input.accidentalClickPreventionTimer > 0) {
        scrolling = false;
      }
      
      if (scrolling) {
        power.setAwake();
        
        scrollVelocity = (input.mouseY()-prevMouseY);
        
        if (input.mouseY()-prevMouseY != 0.0) {
          scrolled = true;
        }
      }
      else {
        scrollVelocity *= PApplet.pow(0.92, display.getDelta());
      }
      //if (!clickAllowed()) {
      //  scrollVelocity = 0f;
      //}
      
      
      prevMouseY = input.mouseY();
      
      
      if (!prompt) {
        scrollOffset += scrollVelocity;
        scrollOffset = input.processScroll(scrollOffset, 0., scrollBottom+1.0);
      }
      
      baseLogic();
      
      // DIsplay all the files
      for (int i = 0; i < originalFilenames.size(); i++) {
        displayItem(i);
      }
        
      displayPrompt();
  }
  
  
  protected void previousReturnAnimation() {
    startCheckerThread();
    input.accidentalClickPrevention();
  }
  
  
  public void endScreenAnimation() {
    runChecker.set(false);
  }
}
