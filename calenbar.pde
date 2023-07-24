
public class Calenbar extends Screen {
  // Ohgod I'm gonna have to remake a date/time system aren't I?
  
  int numSquares = 6;   // pls make sure that's an even number.
  boolean intro = true;  // True when we initially launch timeway.
  float shift = 0.;
  
  int delay = 0;
  int delayTick = 0;
  
  public Calenbar(Engine engine) {
    super(engine);
    this.delay(60);
  }
  
  public Calenbar(Engine engine, boolean intro) {
    super(engine);
    this.intro = intro;
    if (intro) shift = 1.0;
    this.delay(60);
  }
  
  private void delay(int d) {
    delay = d;
    delayTick = 0;
  }
  
  public void renderCalenbar() {
    int n = numSquares;
    if (intro) n++;
    float squareWidth = engine.WIDTH/numSquares;
    float y = (engine.HEIGHT/2)-(squareWidth/2);
    app.noFill();
    app.stroke(5);
    // Even numSquares.
    if (numSquares%2 == 0) {
      for (int i = 0; i < n; i++) {
        float x = (i*squareWidth)-(squareWidth/2)-(squareWidth*(1.-shift));
        app.rect(x, y, squareWidth, squareWidth);
        // And then we display stuff inside of the square can't be bothered I'll do it later.
        
      }
    }
    else {
      // Not implemented.
      engine.console.logOnce("What.");
    }
    
    
    if (intro) {
      float SHIFT_THING = 0.95;
      switch (engine.powerMode) {
          case HIGH:
          shift *= SHIFT_THING;
          break;
          case NORMAL:
          shift *= SHIFT_THING*SHIFT_THING;
          break;
          case SLEEPY:
          shift *= SHIFT_THING*SHIFT_THING*SHIFT_THING*SHIFT_THING;
          break;
          case MINIMAL:
          shift *= SHIFT_THING;
          break;
        }
    }
  }
  
  protected void content() {
    if (delayTick < delay) {
      
    }
    else {
      app.stroke(0);
      renderCalenbar();
      
      app.fill(255);
      app.textFont(engine.DEFAULT_FONT, 50);
      app.textSize(70);
      app.textAlign(LEFT, TOP);
      app.text("Welcome!", 50, 70);
      
      // Render the calenbar.
      app.stroke(255);
      renderCalenbar();
      
      if (intro && shift <= 0.001) {
        requestScreen(new Editor(engine, engine.APPPATH+engine.DAILY_ENTRY));
        engine.prevScreen = new Explorer(engine);
      }
    }
    switch (engine.powerMode) {
      case HIGH:
      delayTick++;
      break;
      case NORMAL:
      delayTick += 2;
      break;
      case SLEEPY:
      delayTick += 4;
      break;
      case MINIMAL:
      delayTick += 1;
      break;
    }
  }
}
