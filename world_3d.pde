// Byebye, it was fun while it lasted.



    

    // If the file check thread has noticed a change, use the main thread to reload the files.
    // We use the main thread and not the refreshThread because we don't want to load assets
    // mid-way through rendering. That would be a disaster.
    //if (refreshRealm.get() == true) {
    //  refreshRealm.set(false);
    //  // We may expect a delay, so put the fps tracking system into grace mode so that
    //  // it doesn't butcher the framerate just because of a drop.
    //  engine.power.putFPSSystemIntoGraceMode();
    //  refreshRealm(); //<>// //<>// //<>// //<>// //<>// //<>// //<>//
    

    

    //fill(255);
    //textSize(30);
    //textAlign(LEFT, TOP);
    //text((str(frameRate) + "\nX:" + str(xpos) + " Y:" + str(ypos) + " Z:" + str(zpos)), 50, myUpperBarWeight+35);


    // We need to run the gui here otherwise it's going to look   t e r r i b l e   in the scene.
 //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//

   //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
  
  


  //public int menuID = 1;
  //public final static int MENU_MAIN = 1;
  //public final static int MENU_CREATOR = 2;
  //public final static int MENU_CREATE_FOLDER_PROMPT = 3;

  //private int buttonCount = 0;
  //private int selectedButton = 0;

  //public boolean button(String spriteName, String ico, String label) {
  //  buttonCount++;

  //  return engine.button(spriteName, ico, label);
  //}


  //public void runGUI() {
  //  buttonCount = 0;

  //  // Controls for the inventory
  //  if (inventorySelectedItem != null) {
  //    inventorySelectedItem.carrying.visible = false;
  //    if (engine.keyActionOnce("inventorySelectLeft")) {
  //      if (inventorySelectedItem.prev != null) {
  //        inventorySelectedItem.carrying.x = -999999;
  //        inventorySelectedItem = inventorySelectedItem.prev;
  //        sound.playSound("pickup");
  //      }
  //    } else if (engine.keyActionOnce("inventorySelectRight")) {
  //      if (inventorySelectedItem.next != null) {
  //        inventorySelectedItem.carrying.x = -999999;
  //        inventorySelectedItem = inventorySelectedItem.next;
  //        sound.playSound("pickup");
  //      }
  //    }
  //    inventorySelectedItem.carrying.visible = true;
  //  }


  //  // Render the inventory
  //  float invx = 10;
  //  float invy = this.height-80;
  //  ItemSlot slot = inventoryHead;

  //  while (slot != null) {
  //    PImage ico = slot.carrying.img;

  //    invy = this.height-80;
  //    if (slot == inventorySelectedItem) invy -= 30;

  //    if (ico != null) 
  //      image(ico, invx, invy, 64, 64);
  //    invx += 70;
  //    slot = slot.next;
  //  }

  //  if (menuShown) {
  //    // These are default width and height for the gui prompt.
  //    // These can be changed in the switch statement below, have fun!
  //    float promptWi = 800;
  //    float promptHi = 500;

  //    engine.useSpriteSystem(guiMainToolbar);
  //    switch (menuID) {
  //    case MENU_MAIN:
  //      app.fill(0, 127);
  //      app.noStroke();
  //      app.rect(WIDTH/2-promptWi/2, HEIGHT/2-promptHi/2, promptWi, promptHi);
  //      if (engine.button("notool_1", "notool_128", "No tool")) {
  //        currentTool = TOOL_NORMAL;
  //        menuShown = false;
  //        dropInventory();
  //        sound.playSound("menu_select");
  //      }
  //      if (engine.button("creator_1", "new_entry_128", "Creator")) {
  //        currentTool = TOOL_CREATOR;
  //        sound.playSound("menu_select");
  //        menuID = MENU_CREATOR;
  //      }
  //      if (engine.button("cuber_1", "cuber_tool_128", "Cuber")) {
  //        //dropInventory();
  //        console.log("Not yet functional!");
  //      }
  //      if (engine.button("bomber_1", "bomber_128", "Bomber")) {
  //        //dropInventory();
  //        console.log("Not yet functional!");
  //      }
  //      break;
  //    case MENU_CREATOR: 
  //      promptWi = 700;
  //      promptHi = 200;

  //      app.fill(0, 127);
  //      app.noStroke();
  //      app.rect(WIDTH/2-promptWi/2, HEIGHT/2-promptHi/2, promptWi, promptHi);
  //      if (engine.button("newentry", "new_entry_128", "New entry")) {
  //        sound.playSound("menu_select");

  //        Runnable r = new Runnable() {
  //          public void run() {
  //            if (engine.keyboardMessage.length() <= 1) {
  //              console.log("Please enter a valid entry name!");
  //              menuShown = false;
  //              return;
  //            }

  //            String newName = file.currentDir+engine.keyboardMessage+"."+engine.ENTRY_EXTENSION;
  //            // Create a new empty file so that we can hold it and place it down, editor will handle the rest.
  //            try {
  //              FileWriter emptyFile = new FileWriter(newName);
  //              emptyFile.write("");
  //              emptyFile.close();
  //            } catch (IOException e2) {
  //              console.warn("Couldn't create entry, IO error!");
  //              console.warn(e2.getMessage());
  //              console.warn("Error path: "+newName);
  //              menuShown = false;
  //              return;
  //            }

  //            refreshRealm();
  //            pickupItem(newName);

  //            launchWhenPlaced = true;

  //            //engine.currScreen = new PixelRealm(engine, engine.currentDir, engine.currentDir);
  //            //endRealm();
  //            menuShown = false;
  //            sound.playSound("menu_select");
  //          }
  //        };

  //        engine.beginInputPrompt("Entry name:", r);

  //        // TODO: rename MENU_CREATE_FOLDER_PROMPT since it's not just for folders.
  //        menuID = MENU_CREATE_FOLDER_PROMPT;
  //      }

  //      if (engine.button("newfolder", "new_folder_128", "New folder")) {
  //        sound.playSound("menu_select");

  //        Runnable r = new Runnable() {
  //          public void run() {
  //            if (engine.keyboardMessage.length() <= 1) {
  //              console.log("Please enter a valid folder name!");
  //              return;
  //            }
  //            String foldername = file.currentDir+engine.keyboardMessage;
  //            new File(foldername).mkdirs();

  //            refreshRealm();
  //            pickupItem(foldername);

  //            menuShown = false;
  //            sound.playSound("menu_select");
  //          }
  //        };

  //        engine.beginInputPrompt("Folder name:", r);
  //        menuID = MENU_CREATE_FOLDER_PROMPT;
  //      }
        
  //      if (engine.button("newshortcut", "create_shortcut_128", "New shortcut")) {
  //        sound.playSound("menu_select");
  //        String shortcutPath = createShortcut(file.currentDir);
  //        refreshRealm();
  //        pickupItem(shortcutPath);
  //        menuShown = false;
  //      }

  //      //if (engine.button("find", "find_128", "Finder")) {
  //      //  finderEnabled = !finderEnabled;
  //      //  menuShown = false;
  //      //  engine.playSound("menu_select");
  //      //}
  //      break;
  //    case MENU_CREATE_FOLDER_PROMPT:
  //      app.fill(0, 127);
  //      app.noStroke();
  //      app.rect(WIDTH/2-promptWi/2, HEIGHT/2-promptHi/2, promptWi, promptHi);
  //      engine.displayInputPrompt();
  //      break;
  //    }

  //    guiMainToolbar.updateSpriteSystem();
  //  }
  //}

  

  //public void objectsInteractions() {
    

  //  if (droppingInventory) {
  //    currentTool = TOOL_NORMAL;

  //    if (dropInventoryItem != null) {
  //      dropInventoryYVel += display.getDelta();
  //      dropInventoryItem.y += dropInventoryYVel;
  //    }

  //    // Once the currently dropping item has hit the ground or
  //    // we're dropping the first item.
  //    if (dropInventoryItem.y > onSurface(dropInventoryItem.x, dropInventoryItem.z)) {

  //      // Position to the ground so it doesn't get stuck too deep in the ground
  //      dropInventoryItem.y = onSurface(dropInventoryItem.x, dropInventoryItem.z);
  //      if (inventorySelectedItem != null && inventoryHead != null) {
  //        PRObject o = inventoryHead.carrying;
  //        o.y = onSurface(o.x, o.z)-100;
  //        o.visible = true;


  //        dropInventoryYVel = 0.;
  //        dropInventoryItem = o;
  //        // Remove from inventory
  //        inventoryHead.remove();
  //      } else {
  //        droppingInventory = false;
  //      }
  //    }
  //  }

  //  if (inventorySelectedItem != null) {
  //    // TODO: OPTIMISATION REQUIRED
  //    float SELECT_FAR = 300.;

  //    // Stick to in front of the player.
  //    if (currentTool == TOOL_GRABBER_NORMAL) {
  //      float x = xpos+sin(direction)*SELECT_FAR;
  //      float z = zpos+cos(direction)*SELECT_FAR;
  //      PRObject o = inventorySelectedItem.carrying;
  //      o.x = x;
  //      o.z = z;
  //      if (onGround())
  //        o.y = onSurface(x, z);
  //      else
  //        o.y = ypos;
  //      o.visible = true;
  //      if (inventorySelectedItem.carrying instanceof ImageFileObject) {
  //        ImageFileObject imgobject = (ImageFileObject)inventorySelectedItem.carrying;
  //        imgobject.rot = direction+HALF_PI;
  //      }
  //    }
  //  }

  //  int l = img_coin.length;
  //  if (coins != null) {
  //    for (int i = 0; i < 100; i++) {
  //      if (coins[i] != null) {
  //        coins[i].img = img_coin[coinFrame];
  //        if (coins[i].touchingPlayer()) {
  //          sound.playSound("coin");
  //          coins[i].destroy();
  //          coins[i] = null;
  //          console.log("Coins: "+str(++collectedCoins));
  //          if (collectedCoins == 100) sound.playSound("oneup");
  //        }
  //      }
  //    }
  //  }

  //  closestVal = Float.MAX_VALUE;
  //  closestObject = null;

  //  final float FLOAT_AMOUNT = 10.;
  //  boolean cancelOut = true;
  //  // Files.
  //  l = files.length;
  //  for (int i = 0; i < l; i++) {
  //    FileObject f = files[i];
  //    if (f != null) {

  //      // Quick inventory check; if it's empty, we don't want it to act.
  //      boolean holding = false;
  //      if (inventorySelectedItem != null)
  //        holding = (f == inventorySelectedItem.carrying);

  //      if (!holding) {
  //        f.checkHovering();
  //        if (f instanceof DirectoryPortal) {
  //          // Take the player to a new directory in the world if we enter the portal.
  //          if (f.touchingPlayer()) {
  //            if (portalCoolDown <= 0.) {
  //              // For now just create an entirely new screen object lmao.
  //              endRealm();
  //              sound.playSound("shift");

  //              // Go into the new world
  //              // If it's a shortcut, go to where the shortcut points to.
                
  //              try {
  //                if (f instanceof ShortcutPortal) {
  //                  // SECRET EASTER EGG TOP SECRET
  //                  if (((ShortcutPortal)f).shortcutName.equals("Neo_2222?")) {
  //                    requestScreen(new WorldLegacy(engine));
  //                    f.destroy();
  //                  }
  //                  // Normal non-easter egg action
  //                  else
  //                    enterNewRealm(((ShortcutPortal)f).shortcutDir);
  //                }
  //                // Otherwise go to where the directory points to.
  //                else enterNewRealm(f.dir);
  //              }
  //              catch (RuntimeException e) {
  //                console.warn("The shortcut portal you've just entered is corrupted!");
  //                f.destroy();
  //              }
  //            } else if (cancelOut) {
  //              // Pause the portalcooldown by essentially cancelling out the values.
  //              portalCoolDown += display.getDelta();
  //              cancelOut = true;
  //            }
  //          }
  //        }
  //      }
  //    }
  //  }

  //  // Pick up the object.
  //  if (closestObject != null && !menuShown) {
  //    FileObject p = (FileObject)closestObject;

  //    // Open the file/directory if clicked
  //    if (currentTool == TOOL_NORMAL) {
  //      if (p.selectedLeft()) {
  //        file.open(p.dir);
  //      }
  //    }

  //    // GRABBER TOOL
  //    
  //  }

  //  // Plonk the object down.
  //  // We also do not want clicks from clicking the menu to unintendedly plonk down objects.
  //  if (inventorySelectedItem != null && !menuShown) {
  //    if ((parentTool(currentTool) == TOOL_GRABBER) && secondaryAction) {
  //      // Used for if we're launching an entry/other files after placing it down
  //      String itemPath = inventorySelectedItem.carrying.dir;

  //      inventorySelectedItem.remove();
  //      sound.playSound("plonk");

  //      // If not null here, inventory's not empty and we can plonk down next item.
  //      if (inventorySelectedItem != null) {
  //        inventorySelectedItem.carrying.visible = true;
  //        // switch back to normal for the next item
  //        currentTool = TOOL_GRABBER_NORMAL;
  //      }


  //      if (launchWhenPlaced) {
  //        launchWhenPlaced = false;
  //        // "Refresh" the folder
  //        endRealm();
  //        // Go to the journal
  //        file.open(itemPath);
  //        currentTool = TOOL_NORMAL;
  //      }

  //      // Otherwise once the inventory's empty just switch back to normal mode.
  //      //else currentTool = TOOL_NORMAL;
  //    }
  //  }
