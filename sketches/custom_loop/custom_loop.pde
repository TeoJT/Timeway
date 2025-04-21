
import java.util.Timer;
import java.util.TimerTask;

class AnimatorTask extends TimerTask {
    Timer timer;
    float fps = 60.0f;

    public AnimatorTask(float fps) {
      super();
      this.fps = fps;
    }

    public void start() {
      final long period = 0 < fps ? (long) (1000.0f / fps) : 1; // 0 -> 1: IllegalArgumentException: Non-positive period
      timer = new Timer();
      timer.scheduleAtFixedRate(this, 0, period);
    }

    long then = 0;

    @Override
    public void run() {
      redraw();
    }
}

private AnimatorTask animationThread;

void setup() {
  size(1024, 1024, P2D);
  noLoop();
  //frameRate(60);
  //Thread t = new Thread(new Runnable() {
  //  public void run() {
  //    while (true) {
  //      try {
  //        redraw();
  //        Thread.sleep(16);
  //      }
  //      catch (InterruptedException e) {
          
  //      }
  //    }
  //  }
  //});
  //t.start();
  animationThread = new AnimatorTask(60f);
  animationThread.start();
  
}

public int getUsedMemKB() {
  long used = (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory());
  return (int)(used/1024L);
}

String message = "";

void draw() {
  background(255);
  noStroke();
  fill(255,0,0);
  float wi = width/2;
  ellipse(sin(frameCount*0.03)*wi+wi, height/2, 100, 100);
  fill(0);
  textAlign(LEFT, TOP);
  textSize(40);
  text(nf(frameRate, 0, 2)+"\n"+getUsedMemKB()+"\n"+message, 10, 10, width, height);
}

void keyPressed() {
  message += key;
  redraw();
}

void mouseMoved() {
  redraw();
}
