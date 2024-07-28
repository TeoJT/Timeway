import processing.core.*;
import processing.data.*;
import processing.event.*;
import processing.opengl.*;

public class CustomPlugin {

  public PApplet app;

  // API calls.
  public void bump(float intensity) {
    apiOpCode = 1;
    args[0] = intensity;
    apiCall.run();
  }

  public int specialNumber() {
    apiOpCode = 2;
    apiCall.run();
    return (int)ret;
  }

  

// We need a start() and run() method here which is
// automatically inserted by the generator.

// when parsing this line is automatically replaced
// by plugin code.

    public void start() {
      app.println("Hello worlddd");
    }
    
    int tmr = 0;
    public void run() {
      app.background(0);
      tmr++;
      if (tmr % 60 == 0) {
        bump(0.5f);
      }
    }
  




  // Plugin-host communication methods
  private Runnable apiCall;
  private int apiOpCode = 0;
  private Object[] args = new Object[128];
  private Object ret;

  public int getCallOpCode() {
    return apiOpCode;
  }

  public Object[] getArgs() {
    return args;
  }

  public void setRet(Object ret) {
    this.ret = ret;
  }

  public void setup(PApplet p, Runnable api) {
    this.app = p;
    this.apiCall = api;

    // Start doesn't exist in this file alone,
    // but should be there after generator processes
    // plugin.
    start();
  }
}
