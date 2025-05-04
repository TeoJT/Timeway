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
    textFont(engine.DEFAULT_FONT);
    textSize(50);
    textAlign(CENTER, TOP);
    fill(0);
    text("Update", WIDTH/2, 10);
  }
  
  public boolean button(String display, float x, float y) {
    x = x+10;
    float wi = (WIDTH/2)-40;    // idk why 40
    float hi = 50;
    return ui.basicButton(display, x, y, wi, hi);
  }
  
  public void content() {
    
    float x, y;
    textFont(engine.DEFAULT_FONT);
    textSize(50);
    textAlign(LEFT, TOP);
    fill(255);
    x = 10;
    y = myUpperBarWeight+50;
    text(headerText, x, y);
    
    textSize(30);
    fill(255, 255, 200);
    x = 10;
    y = myUpperBarWeight+100;
    text(updateName, x, y);
    
    textSize(30);
    fill(255);
    x = 10;
    y = myUpperBarWeight+150;
    text(displayMessage, x, y, WIDTH-x*2, 100);
    
    textSize(20);
    fill(255);
    x = 10;
    y = myUpperBarWeight+250;
    float footerY = 150;
    text(patchNotes, x, y, WIDTH-x*2, HEIGHT-myLowerBarWeight-y-footerY);
    
    textSize(20);
    fill(200);
    x = 10;
    y = HEIGHT-myLowerBarWeight-footerY;
    text(footerMessage, x, y, WIDTH-x*2, footerY);
    
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
  
  public SpriteSystemPlaceholder gui;
  
  private float highestTime = 0f;
  
  public Benchmark(TWEngine e) {
    super(e);
    textFont(engine.DEFAULT_FONT);
    gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/benchmark/");
    ui.useSpriteSystem(gui);
    myUpperBarColor = color(100);
    gui.interactable = false;
    
    // Find highest benchmark time (used to scale results relative to highest time).
    for (long longTime : engine.benchmarkArray) {
      float time = (float)((int)longTime);
      
      // Stupid hack (end to start times end up causing everything else to look small)
      if (time > 10000f) {
        continue;
      }
      
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
    for (int i = 0; i < engine.benchmarkResults.size(); i++) {
      float time = (float)((int)engine.benchmarkArray[i]);
      
      // Stupid hack (end to start times end up causing everything else to look small)
      if (time > 10000f) {
        continue;
      }
      
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
  SpriteSystemPlaceholder gui;
  private int numTimewayEntries;
  public  float scrollBottom = 0.0;
  
  public Explorer(TWEngine engine) {
        super(engine);
        
        file.openDirInNewThread(engine.DEFAULT_DIR);
        gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/explorer/");
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
        gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/explorer/");
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
      float y = 150 + i*TEXT_SIZE+input.scrollOffset;
      
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
                input.scrollOffset = 0.;
                
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
          if (input.keyboardMessage.length() <= 1) {
            console.log("Please enter a valid entry name!");
            return;
          }
          String entryname = file.currentDir+input.keyboardMessage+"."+engine.ENTRY_EXTENSION;
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
          if (input.keyboardMessage.length() <= 1) {
            console.log("Please enter a valid folder name!");
            return;
          }
          String foldername = file.currentDir+input.keyboardMessage;
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
        input.processScroll(0., scrollBottom+1.0);
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
    private SpriteSystemPlaceholder gui = null;

    public HomeScreen(TWEngine engine) {
        super(engine);
        myBackgroundColor = color(10);
        myUpperBarColor = color(50);
        myLowerBarColor = color(50);
        
        gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/homescreen/");
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
        
        SpriteSystemPlaceholder.Sprite logoSprite = gui.getSprite("homescreen-title");
        float offY = logoSprite.getY()+logoSprite.getHeight()-60;
        
        app.noStroke();
        app.textAlign(CENTER, CENTER);
        app.textFont(engine.DEFAULT_FONT, 34);
        app.fill(0, 255-(255*floatIn));
        app.text("by Teo Taylor", WIDTH/2-3, offY);
        app.fill(255, 255-(255*floatIn));
        app.text("by Teo Taylor", WIDTH/2, offY);
        
        offY += 34;
        
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
        
        gui.updateSpriteSystem();
        
    }
}
