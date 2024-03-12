


public class Benchmark extends Screen {
  
  public SpriteSystemPlaceholder gui;
  
  public Benchmark(Engine e) {
    super(e);
    textFont(engine.DEFAULT_FONT);
    gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"gui/benchmark/");
    ui.useSpriteSystem(gui);
    myUpperBarColor = color(100);
    gui.interactable = false;
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
    textSize(40);
    text("Benchmark results", 10, myUpperBarWeight+10);
    
    
    float x = 10;
    float y = myUpperBarWeight+50;
    
    int i = 0;
    float c = 0;
    
    noStroke();
    textSize(20);
    colorMode(HSB, 255);
    for (String res : engine.benchmarkResults) {
      fill(c, 255, 128);
      c += 40.;
      c %= 255.;
      rect(x, y, ((int)engine.benchmarkArray[i])/2, 20);
      
      fill(255);
      text(res, x, y-3);
      
      i++;
      y += 25;
      
    }
    colorMode(RGB, 255);
  }
}
