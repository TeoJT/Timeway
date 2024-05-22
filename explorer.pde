import java.awt.Desktop;

public class Explorer extends Screen {
  
  
  //private String currentDir = DEFAULT_DIR;
  
  
  //DisplayableFile backButtonDisplayable = null;
  SpriteSystemPlaceholder gui;
  private int numTimewayEntries;
  public  float scrollBottom = 0.0;
  
  public Explorer(Engine engine) {
        super(engine);
        
        file.openDirInNewThread(engine.DEFAULT_DIR);
        gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"gui/explorer/");
        gui.repositionSpritesToScale();
        gui.interactable = false;
        
        //myLowerBarColor   = color(120);
        //myUpperBarColor   = color(120);
        myBackgroundColor = color(0);
  }
  
  // Sorry for code duplication!
  public Explorer(Engine engine, String dir) {
        super(engine);
        
        file.openDirInNewThread(dir);
        gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"gui/explorer/");
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
            if (input.primaryClick) {
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
        return hover && input.primaryClick;
    }
    
  
  
  private void renderGui() {
    
    //************NEW ENTRY************
    if (button("new_entry", "new_entry_128", "New entry")) {
      // TODO: placeholder
      String newName = file.currentDir+engine.appendZeros(numTimewayEntries, 5)+"."+engine.ENTRY_EXTENSION;
      requestScreen(new Editor(engine, newName));
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
    if (button("cross", "cross", "")) {
      exit();
    }
    
    //***********PIXeL REALM BUTTON***********
    if (button("world", "world_128", "Pixel Realm")) {
      requestScreen(new PixelRealmWithUI(engine, file.currentDir));
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
    display.shader("fabric", "color", 0.5,0.5,0.5,1., "intensity", 0.1);
    super.lowerBar();
    display.defaultShader();
  }
    
  
  public void refreshDir() {
    file.openDirInNewThread(file.currentDir);
  }
  
  
  // Let's render our stuff.
  public void content() {
    // TODO: Should have a function with this to remove code bloat?
      app.fill(255);
      app.textFont(engine.DEFAULT_FONT, 50);
      app.textSize(70);
      app.textAlign(LEFT, TOP);
      app.text("Explorer", 50, 80);
      
      if (file.loading) {
        ui.loadingIcon(WIDTH/2, HEIGHT/2);
      }
      else {
        input.processScroll(0., scrollBottom+1.0);
        renderDir();
      }
      
      engine.displayInputPrompt();
  }
  
}
