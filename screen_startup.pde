

public class Startup extends Screen {
    float floatIn = 1.0;
    float floatOut = 1.0;
    int timeFromStart = 0;
    boolean nextScreen = false;
    boolean firstTimeStartup = false;

    public Startup(TWEngine engine) {
        super(engine);
        
        // Kickstart gstreamer by playing default realm music (but also not really playing it)
        File f = new File(engine.DEFAULT_DIR+PixelRealm.REALM_BGM);
        if (f.exists())
          sound.streamMusic(engine.DEFAULT_DIR+PixelRealm.REALM_BGM);
        else
          sound.streamMusic(engine.APPPATH+PixelRealm.REALM_BGM_DEFAULT);
        //sound.playSound("intro");
        
        // if stats.json is missing, this means user is starting timeway for the first time.
        firstTimeStartup = !file.exists(engine.APPPATH+engine.STATS_FILE());
    }

    public void upperBar() {
        // Don't render the upper bar
    }

    public void lowerBar() {
        // Don't render the lower bar
    }

    public void backg() {
        app.fill(myBackgroundColor);
        app.noStroke();
        app.rect(0, 0, WIDTH, HEIGHT);
    }

    public void transitionAnimation() {

    }
    

    public void content() {
        
        
        // Yup we deliberately make the loading time longer just so we can display the logo
        // long enough lol.
        if (engine.isLoading() || display.getTime() < 1f) {
            floatIn *= 0.9;
            app.tint(255, 255-(255*floatIn));
            display.imgCentre("logo", WIDTH/2, HEIGHT/2 - floatIn*100);

            ui.loadingIcon(WIDTH/2, HEIGHT*0.8);
            
            // TODO: add loading notes
        }
        // Logo fade out as the screen moves away.
        else {
            floatOut *= 0.9;
            app.tint(255, (255*floatOut));
            display.imgCentre("logo", WIDTH/2, HEIGHT/2);
            
            // Only executes once
            if (!nextScreen) {
              nextScreen = true;
              String dir = engine.DEFAULT_DIR;
              
              // Setting this to true will tell the engine to give a quick fps test to the first
              // screen we go into so that we can smoothly go into a suitable framerate.
              engine.initialScreen = true;
              
              // This is the part where we exit the welcome screen and go to our main screen.
              PixelRealmWithUI pixelrealm = new PixelRealmWithUI(engine, dir);
              requestScreen(pixelrealm);
            }
        }
        
        // Author name below
        app.noStroke();
        app.textAlign(CENTER, CENTER);
        app.textFont(engine.DEFAULT_FONT, 34);
        app.fill(0, 255-(255*floatIn));
        app.text("by Téo Taylor", WIDTH/2-3, HEIGHT/2+150-3);
        app.fill(255, 255-(255*floatIn));
        app.text("by Téo Taylor", WIDTH/2, HEIGHT/2+150);
        
        
        // First time startup
        //if (firstTimeStartup) {
        //  app.text("First startup make take some time, please wait...", WIDTH/2, HEIGHT/2+400);
        //}
        
        
        // Version in bottom-right.
        app.noTint();
        app.fill(255);
        app.noStroke();
        app.textAlign(LEFT, CENTER);
        app.textFont(engine.DEFAULT_FONT, 30);
        app.fill(0, 255-(255*floatIn));
        app.text("v"+engine.getVersion(), 10-3, HEIGHT-30-3);
        app.fill(255, 255-(255*floatIn));
        app.text("v"+engine.getVersion(), 10, HEIGHT-30);
        
        stats.recordTime("time_in_startscreen");
    }
}
