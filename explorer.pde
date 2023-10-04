import java.awt.Desktop;

public class Explorer extends Screen {
  private String DEFAULT_FONT = "";
  
  
  //private String currentDir = DEFAULT_DIR;
  
  
  //DisplayableFile backButtonDisplayable = null;
  SpriteSystemPlaceholder gui;
  private float scrollOffset = 0.0;
  private float scrollBottom = 0.0;
  private int numTimewayEntries;
  
  public Explorer(Engine engine) {
        super(engine);
        DEFAULT_FONT = engine.DEFAULT_FONT_NAME;
        
        engine.openDirInNewThread(engine.DEFAULT_DIR);
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
        DEFAULT_FONT = engine.DEFAULT_FONT_NAME;
        
        engine.openDirInNewThread(dir);
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
    for (int i = 0; i < engine.currentFiles.length; i++) {
      float textHeight = app.textAscent() + app.textDescent();
      float x = 50;
      float wi = TEXT_SIZE + 20;
      float y = 150 + i*TEXT_SIZE+scrollOffset;
      
      // Sorry not sorry
      try {
        if (engine.currentFiles[i] != null) {
          if (engine.mouseX() > x && engine.mouseX() < x + app.textWidth(engine.currentFiles[i].filename) + wi && engine.mouseY() > y && engine.mouseY() < textHeight + y) {
            // if mouse is overing over text, change the color of the text
            app.fill(100, 0, 255);
            app.tint(100, 0, 255);
            // if mouse is hovering over text and left click is pressed, go to this directory/open the file
            if (engine.pressDown) {
              if (engine.currentFiles[i].file.isDirectory())
                scrollOffset = 0.;
                
              engine.open(engine.currentFiles[i]);
            }
          } else {
            app.noTint();
            app.fill(255);
          }
          
          if (engine.currentFiles[i].icon != null)
            engine.img(engine.currentFiles[i].icon, 50, y, TEXT_SIZE, TEXT_SIZE);
          app.textAlign(LEFT, TOP);
          app.text(engine.currentFiles[i].filename, x + wi, y);
          app.noTint();
        }
      }
      catch (ArrayIndexOutOfBoundsException e) {
        
      }
      catch (NullPointerException ex) {
        
      }
    }
    
    scrollBottom = max(0, (engine.currentFiles.length*TEXT_SIZE-engine.HEIGHT+BOTTOM_SCROLL_EXTEND));
  }
  
  private void processScroll(float top, float bottom) {
    final float ELASTIC_MAX = 100.;
    
    if (engine.scroll != 0.0) {
      engine.setAwake();
    }
    else {
      engine.setSleepy();
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
    
    // Sorry not sorry
    for (int i = 0; i < n; i++) {
      if (scrollOffset > top) {
          scrollOffset -= (scrollOffset-top)*0.1;
          if (engine.scroll < 0.0) scrollOffset += engine.scroll;
          else scrollOffset += engine.scroll*(max(0.0, ((ELASTIC_MAX+top)-scrollOffset)/ELASTIC_MAX));
      }
      else if (-scrollOffset > bottom) {
          // TODO: Actually get some pen and paper and make the elastic band edge work.
          // This is just a placeholder so that it's usable.
          scrollOffset = -bottom;
        
          //scrollOffset += (bottom-scrollOffset)*0.1;
          //if (engine.scroll > 0.0) scrollOffset += engine.scroll;
          //else scrollOffset += engine.scroll*(max(0.0, ((-scrollOffset)-(ELASTIC_MAX+bottom))/ELASTIC_MAX));
      }
      else scrollOffset += engine.scroll;
    }
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
        return hover && engine.mouseEventClick;
    }
    
  
  
  private void renderGui() {
    
    //************NEW ENTRY************
    if (button("new_entry", "new_entry_128", "New entry")) {
      // TODO: placeholder
      String newName = engine.currentDir+engine.appendZeros(numTimewayEntries, 5)+"."+engine.ENTRY_EXTENSION;
      requestScreen(new Editor(engine, newName));
    }
    
    //************NEW FOLDER************
    if (button("new_folder", "new_folder_128", "New folder")) {
      
      Runnable r = new Runnable() {
        public void run() {
          if (engine.keyboardMessage.length() <= 1) {
            console.log("Please enter a valid folder name!");
            return;
          }
          String foldername = engine.currentDir+engine.keyboardMessage;
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
      requestScreen(new PixelRealm(engine, engine.currentDir));
    }
    
    gui.updateSpriteSystem();
    
  }
  
  // Just use the default background
  public void backg() {
        app.fill(myBackgroundColor);
        app.noStroke();
        app.rect(0, 0, engine.WIDTH, engine.HEIGHT);
  }
  
  public void upperBar() {
    app.shader(engine.getShaderWithParams("fabric", "color", 0.5,0.5,0.5,1., "intensity", 0.1));
    super.upperBar();
    app.resetShader();
    renderGui();
  }
  
    
  public void lowerBar() {
    app.shader(engine.getShaderWithParams("fabric", "color", 0.5,0.5,0.5,1., "intensity", 0.1));
    super.lowerBar();
    engine.defaultShader();
  }
    
  
  public void refreshDir() {
    engine.openDirInNewThread(engine.currentDir);
  }
  
  
  // Let's render our stuff.
  public void content() {
    // TODO: Should have a function with this to remove code bloat?
      app.fill(255);
      app.textFont(engine.DEFAULT_FONT, 50);
      app.textSize(70);
      app.textAlign(LEFT, TOP);
      app.text("Explorer", 50, 80);
      
      if (engine.loading) {
        engine.loadingIcon(engine.WIDTH/2, engine.HEIGHT/2);
      }
      else {
        processScroll(0., scrollBottom+1.0);
        renderDir();
      }
      
      engine.displayInputPrompt();
  }
  
}
