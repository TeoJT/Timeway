

void setup() {
  size(1024, 1024, P2D);
  noLoop();
  Thread t = new Thread(new Runnable() {
    public void run() {
      while (true) {
        try {
          redraw();
          Thread.sleep(1000);
        }
        catch (InterruptedException e) {
          
        }
      }
    }
  });
  t.start();
}

String message = "";

void draw() {
  background(255);
  noStroke();
  fill(255,0,0);
  float wi = width/2;
  ellipse(sin(frameCount*0.1)*wi+wi, height/2, 100, 100);
  fill(0);
  textAlign(LEFT, TOP);
  textSize(40);
  text(message, 10, 10, width, height);
}

void keyPressed() {
  message += key;
  redraw();
}

void mouseMoved() {
  redraw();
}
