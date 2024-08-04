import processing.core.*;
import processing.data.*;
import processing.event.*;
import processing.opengl.*;

public class CustomPlugin {

  public PApplet app;
  public PGraphics g;
  public final float PI = PApplet.PI;
  public final float HALF_PI = PApplet.HALF_PI;
  public final float TWO_PI = PApplet.TWO_PI;

  // API calls.

  public String test(int number) {
    apiOpCode = 1;
    args[0] = number;
    apiCall.run();
    return (String)ret;
  }

  public void sprite(String name, String img) {
    apiOpCode = 2;
    args[0] = name;
    args[1] = img;
    apiCall.run();
  }

  public void sprite(String name) {
    sprite(name, name);
  }

  public void print(Object... stufftoprint) {
    apiOpCode = 3;
    if (stufftoprint.length >= 127) {
      warn("You've put too many args in print()!");
      return;
    }
    // First arg used for length of list
    args[0] = stufftoprint.length+1;
    // Continue here.
    for (int i = 1; i < stufftoprint.length+1; i++) {
      args[i] = stufftoprint[i-1];
    }
    apiCall.run();
  }

  public void warn(String message) {
    apiOpCode = 4;
    args[0] = message;
    apiCall.run();
  }

  public void moveSprite(String name, float x, float y) {
    apiOpCode = 5;
    args[0] = name;
    args[1] = x;
    args[2] = y;
    apiCall.run();
  }

  public float getTime() {
    apiOpCode = 6;
    apiCall.run();
    return (float)ret;
  }
  
  public float getDelta() {
    apiOpCode = 7;
    apiCall.run();
    return (float)ret;
  }

  public float getTimeSeconds() {
    apiOpCode = 8;
    apiCall.run();
    return (float)ret;
  }
  

// We need a start() and run() method here which is
// automatically inserted by the generator.

// when parsing this line is automatically replaced
// by plugin code.
[plugin_code]





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

  public void setup(PApplet p, Runnable api, PGraphics g) {
    this.app = p;
    this.apiCall = api;
    this.g = g;

    // Start doesn't exist in this file alone,
    // but should be there after generator processes
    // plugin.
    start();
  }
}