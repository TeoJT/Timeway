public class Updater extends Screen {
  String updateName = "";
  String headerText = "An update is available!";
  String displayMessage = "This update contains the following additions, changes, and/or fixes:\n";
  String footerMessage = "Downloading and installing will run in the background as Timeway runs, so please leave Timeway running until the update completes. Don't worry, none of your personal data will be modified.";
  String patchNotes = "";
  boolean startedMusic = false;
  JSONObject updateInfo;
  
  public Updater(Engine engine, JSONObject updateInfo) {
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
    color c = color(200);
    
    x = x+10;
    float wi = (WIDTH/2)-40;    // idk why 40
    float hi = 50;
    boolean hovering = (engine.mouseX() > x && engine.mouseY() > y && engine.mouseX() < x+wi && engine.mouseY() < y+hi);
    if (hovering) c = color(255);
    
    noFill();
    stroke(c);
    rect(x+10, y, wi, hi);
    
    textSize(32);
    textAlign(CENTER, CENTER);
    fill(c);
    text(display, x+wi/2, y+hi/2);
    return hovering && engine.click;
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
      switch (platform) {
        case WINDOWS:
          downloadURL = updateInfo.getString("windows-download", "");
          break;
        case LINUX:
          downloadURL = updateInfo.getString("linux-download", "");
          break;
        case MACOSX:
          downloadURL = updateInfo.getString("macos-download", "");
          break;
      }
      engine.beginUpdate(downloadURL, downloadLocation);
      previousScreen();
    }
  }
}
