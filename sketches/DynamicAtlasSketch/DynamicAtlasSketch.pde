
ArrayList<PImage> imgs = new ArrayList<PImage>();
ArrayList<UVImage> uvimgs = new ArrayList<UVImage>();

PFont typewriter;

TextRendererClone renderText;

LargeImage scrnsht;
Canvas myScreen;

class Canvas {
  public PGraphics graphics;
  public PShape shape;
  
  public Canvas(int w, int h, String renderer) {
    graphics = createGraphics(w, h, renderer);
    shape = createShape();
    shape.beginShape(QUADS);
    shape.texture(graphics);
    shape.noStroke();
    shape.vertex(0, 0, 0, 0);
    shape.vertex(1, 0, graphics.width, 0);
    shape.vertex(1, 1, graphics.width, graphics.height);
    shape.vertex(0, 1, 0, graphics.height);
    shape.endShape();
  }
  
  public Canvas(int w, int h) {
    graphics = createGraphics(w, h, P2D);
    shape = createShape();
    shape.beginShape(QUADS);
    shape.texture(graphics);
    shape.noStroke();
    shape.vertex(0, 0, 0, 0);
    shape.vertex(1, 0, graphics.width, 0);
    shape.vertex(1, 1, graphics.width, graphics.height);
    shape.vertex(0, 1, 0, graphics.height);
    shape.endShape();
  }
  
  void display(float x, float y, float w, float h) {
    pushMatrix();
    translate(x, y);
    scale(w, h);
    shape(shape);
    popMatrix();
  }
  
  void display(float x, float y) {
    display(x, y, graphics.width, graphics.height);
  }
}


void setup() {
  size(768, 768, P2D);
  
  currentPG = g;
  stencilMapDisplay = new Canvas(256, 256, JAVA2D);
  
  typewriter = loadFont("Typewriter.vlw");
  renderText = new TextRendererClone(typewriter);
  myScreen = new Canvas(256, 256);
  
  scrnsht = createLargeImage(loadImage("screen.png"));
  
   //Not related to atlas.
  File[] files = (new File(sketchPath()+"/data/")).listFiles();
  for (File f : files) {
    println(f.getAbsolutePath());
    imgs.add(loadImage(f.getAbsolutePath()));
  }
    textFont(typewriter);
    
  frameRate(60);
}

int index = 0;

void keyPressed() {
  if (key == ' ') {
    UVImage im = createUVImage(imgs.get(index%(imgs.size()-1)), 2., 2.);
    if (im != null) uvimgs.add(im);
    update();
    index++;
    println("Count:", index);
  }
  else if (key == BACKSPACE) {
    if (uvimgs.size() > 0) {
      uvimgs.remove(int(random(0, uvimgs.size())));
      System.gc();
    }
  }
  mssg += key;
}

String mssg = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

void draw() {
  background(0);
  if (keyPressed && key == 'r') {
  //if (true) {
  }
  else {    
    
    shader(atlasShader);
    textureWrap(REPEAT);
    scrnsht.setUV((frameCount*0.01),0.,(frameCount*0.01)+1.,1.0);
    image(scrnsht, 0, -45, width, height);
    
    fill(255);
    
    //myScreen.graphics.beginDraw();
    //myScreen.graphics.background(0);
    //usePGraphics(myScreen.graphics);
    bind();
    
    float ttt = frameCount*0.005-floor(frameCount*0.005);
    for (UVImage uv : uvimgs)  {
      //image(uv, random(0, myScreen.graphics.width), random(0, myScreen.graphics.height), 100, 100);
      uv.setUV(ttt, ttt, ttt+1., ttt+1.);
      image(uv, 0, 0);
    }
    //myScreen.graphics.endDraw();
    //myScreen.display(0, 0);
    
    //usePGraphics(g);
    //beginFast();
    
    
    
    
    //    fill(0,0,255);
    //renderText.textSize(24);
    //renderText.textAlign(LEFT, TOP);
    //renderText.text(mssg, 0, 40, width, height);
    
    //resetShader();
    //fill(255);
    //textSize(24);
    //textAlign(LEFT, TOP);
    //text(mssg, 0, 40, width, height);
    //showStencilMap(0, 0, 64, 64);
  }
  
  shader(atlasShader);
  bind();
  //resetShader();
  //fill(0);
  //rect(0, 0, 50, 20);
  fill(255);
  renderText.textSize(24);
  renderText.textAlign(LEFT, TOP);
  renderText.text("fps: "+str(int(frameRate)), 0, 0);
  
  //println("l: "+str(mssg.length())+"\nfps: "+str(int(frameRate)));
  
}
