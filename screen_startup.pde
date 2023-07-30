

public class Startup extends Screen {
    float floatIn = 1.0;
    float floatOut = 1.0;
    int timeFromStart = 0;
    boolean nextScreen = false;

    public Startup(Engine engine) {
        super(engine);
        
        
        File f = new File(engine.DEFAULT_DIR+PixelRealm.REALM_BGM);
        if (f.exists())
          engine.streamMusic(engine.DEFAULT_DIR+PixelRealm.REALM_BGM);
        else
          engine.streamMusic(engine.APPPATH+PixelRealm.REALM_BGM_DEFAULT);
        tempIntroSound.play();
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
        app.rect(0, 0, engine.WIDTH, engine.HEIGHT);
    }

    public void transitionAnimation() {

    }

    public void content() {
        
        switch (engine.powerMode) {
          case HIGH:
          timeFromStart++;
          break;
          case NORMAL:
          timeFromStart += 2;
          break;
          case SLEEPY:
          timeFromStart += 4;
          break;
          case MINIMAL:
          timeFromStart++;
          break;
        }
        
        // BIG MASSIVE TODO: This doesn't actually wait for Timeway to load. It's just mostly a lil hello thing lmao.
        // Obviously we need to make the loading actually work in a seperate thread while this screen loads everything.
        // Render logo
        if (engine.isLoading() || timeFromStart < 60) {
            floatIn *= 0.9;
            app.tint(255, 255-(255*floatIn));
            engine.imgCentre("logo", engine.WIDTH/2, engine.HEIGHT/2 - floatIn*100);

            engine.loadingIcon(engine.WIDTH/2, engine.HEIGHT*0.8);
        }
        // Logo fade out as the screen moves away.
        else {
            floatOut *= 0.9;
            app.tint(255, (255*floatOut));
            engine.imgCentre("logo", engine.WIDTH/2, engine.HEIGHT/2);
            
            // Only executes once
            if (!nextScreen) {
              nextScreen = true;
              String dir = engine.DEFAULT_DIR;
              
              // Setting this to true will tell the engine to give a quick fps test to the first
              // screen we go into so that we can smoothly go into a suitable framerate.
              engine.initialScreen = true;
              
              engine.stopMusic();
              // This is the part where we exit the welcome screen and go to our main screen.
              requestScreen(new PixelRealm(engine, dir));
            }
        }
        app.noTint();
        
        // Version in bottom-right.
        app.fill(255);
        app.noStroke();
        app.textAlign(LEFT, CENTER);
        app.textFont(engine.DEFAULT_FONT);
        app.textSize(30);
        app.text(engine.VERSION, 10, engine.HEIGHT-60);
    }
}