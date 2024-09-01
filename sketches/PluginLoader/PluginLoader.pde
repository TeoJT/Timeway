import java.net.URLClassLoader;
import java.net.URL;
import java.lang.reflect.Method;
import java.lang.reflect.Parameter;
import java.io.*;

String pluginBoilerplateCode_1;
String pluginBoilerplateCode_2;
String javapath;

PApplet app;

int mssgtmr = 0;
int cacheEntry = 0;

class Plugin {
  private Class pluginClass;
  private Method pluginRunPoint;
  private Method pluginGetOpCode;
  private Method pluginGetArgs;
  private Method pluginSetRet;
  private Object pluginIntance;
  private Plugin thisPlugin;
  public boolean compiled = false;
  public String errorOutput = "";
  
  private Runnable callAPI = new Runnable() {
        public void run() {
          runAPI(thisPlugin);
        }
  };
  
  public Plugin() {
    this.thisPlugin = this;
  }
  
  
  void run() {
    if (compiled && pluginRunPoint != null && pluginIntance != null) {
      try {
        pluginRunPoint.invoke(pluginIntance);
      }
      catch (Exception e) {
        System.err.println("Run plugin exception: "+ e.getClass().getSimpleName());
        exit();
      }
    }
  }
  
  // Loads class from file.
  void loadPlugin(String pluginPath) {
    System.out.println("Loading plugin "+pluginPath);
    
    URLClassLoader child = null;
    try {
      child = new URLClassLoader(
              new URL[] {new File(pluginPath).toURI().toURL()},
              this.getClass().getClassLoader()
      );
    }
    catch (Exception e) {
      System.err.println("URL Exception: "+ e.getClass().getSimpleName());
      exit();
    }
    
    pluginClass = null;
    try {
      pluginClass = Class.forName("CustomPlugin", true, child);
      pluginRunPoint = pluginClass.getDeclaredMethod("run");
      pluginGetOpCode = pluginClass.getDeclaredMethod("getCallOpCode");
      pluginGetArgs = pluginClass.getDeclaredMethod("getArgs");
      pluginSetRet = pluginClass.getDeclaredMethod("setRet", Object.class);
      pluginIntance = pluginClass.getDeclaredConstructor().newInstance();
    }
    catch (Exception e) {
      System.err.println("LoadPlugin Exception: "+ e.getClass().getSimpleName());
      exit();
    }
    //listMethods();
    
    try {
      Method passAppletMethod = pluginClass.getDeclaredMethod("setup", PApplet.class, Runnable.class);
      
      passAppletMethod.invoke(pluginIntance, app, callAPI);
    }
    catch (Exception e) {
      System.err.println("passPApplet Exception: "+ e.getClass().getSimpleName());
      System.err.println(e.getMessage());
      //exit();
    }
  }
  
  
  // Compiles the code into a file, then loads the file.
  public boolean compile(String code) {
    cacheEntry++;
    compiled = false;
    mssgtmr = 60;
    
    println("Compiling plugin...");
    
    final String javaFileOut = sketchPath()+"/data/pluginCache/CustomPlugin.java";
    final String classFileOut = sketchPath()+"/data/pluginCache/CustomPlugin.class";
    
    String fullCode = pluginBoilerplateCode_1+code+pluginBoilerplateCode_2;
    println(fullCode);
    
    saveStrings(javaFileOut, fullCode.split("\n"));
    
    CmdOutput cmd = toClassFile(javaFileOut);
    compiled = cmd.success;
    
    if (!compiled) {
      this.errorOutput = cmd.message;
      return false;
    }
    this.errorOutput = "";
    loadPlugin(toJarFile(classFileOut));
    return true;
  }
  
  public void ret(Object val) {
    try {
      pluginSetRet.invoke(pluginIntance, val);
    }
    catch (Exception e) {
      println("Ohno");
    }
  }
  
  public int getOpCode() {
    try {
      return (int) pluginGetOpCode.invoke(pluginIntance);
    }
    catch (Exception e) {
      println("Ohno");
      return -1;
    }
  }
  
  public Object[] getArgs() {
    try {
      return (Object[]) pluginGetArgs.invoke(pluginIntance);
    }
    catch (Exception e) {
      println("Ohno");
      return null;
    }
  }
}

// "C:\mydata\apps\processing-4.3\java\bin\javac.exe" -cp "C:\mydata\apps\processing-4.3\core\library\core.jar" CustomPlugin.java
// "C:\mydata\apps\processing-4.3\java\bin\jar.exe" cvf CustomPlugin.jar *.class


float bump = 0;


Plugin myplugin;
String code = null;

void setup() {
  size(1024, 1024, P2D);
  scale(2);
  app = this;
  System.out.println("Host running.");
  System.out.println("Compiling plugin...");
  consoleFont = createFont("Courier New Bold", 32);
  textFont(consoleFont, 40);
  
  // Get the java executables path.
  String pp = (new File(".").getAbsolutePath());
  javapath = pp.substring(0, pp.length()-2).replaceAll("\\\\", "/")+"/java";
  println(javapath);
  
  
  myplugin = new Plugin();
  
  // Load the boilerplate code
  pluginBoilerplateCode_1 = "";
  pluginBoilerplateCode_2 = "";
  boolean secondPart = false;
  String[] txts = loadStrings("data/plugin_boilerplate.java");
  for (String s : txts) {
    if (!secondPart && s.trim().equals("[plugin_code]")) {
      secondPart = true;
    }
    else if (!secondPart)
      pluginBoilerplateCode_1 += s+"\n";
    else
      pluginBoilerplateCode_2 += s+"\n";
  }
  
  // Our code as a string (omg)
  code = """
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
  """;
  
  //// Compile the code.
  myplugin.compile(code);
}






CmdOutput toClassFile(String inputFile) {
  final String javacPath = javapath+"/bin/javac.exe";
  final String processingCorePath = "C:/mydata/apps/processing-4.3/core/library/core.jar";
  final String pluginPath = sketchPath()+"/data/pluginCache/";
  
  CmdOutput cmd = runOSCommand("\""+javacPath+"\" -cp \""+processingCorePath+";"+pluginPath+"\" \""+inputFile+"\"");
  return cmd;
}

String toJarFile(String classFile) {
  final String jarExePath = "C:/mydata/apps/processing-4.3/java/bin/jar.exe";
  final String out = sketchPath()+"/data/pluginCache/cache-"+cacheEntry+".jar";
  final String classPath = (new File(classFile)).getParent().toString();
  final String className = (new File(classFile)).getName();
  runOSCommand("\""+jarExePath+"\" cvf \""+out+"\" -C \""+classPath+"\" "+className);
  return out;
}

void mouseClicked() {
  myplugin.compile(code);
}

PFont consoleFont;

void draw() {
  if (myplugin.compiled) {
    background(200);
    myplugin.run();
    
    if (bump > 0.01) {
      blendMode(ADD);
      fill(bump*255);
      noStroke();
      rect(0, 0, width, height);
      blendMode(NORMAL);
    }
    bump *= 0.9;
  }
  else {
    background(0);
    textSize(30);
    textAlign(LEFT, TOP);
    fill(255, 127, 127);
    text(myplugin.errorOutput, 0, 0, width, height);
  }
  
  
  if (mssgtmr > 0) {
    textSize(40);
    textAlign(LEFT, TOP);
    if (!myplugin.compiled) {
      fill(255, 0, 0);
      text("Compile error!", 0, 0);
    }
    else {
      fill(0, 0, 255);
      text("Recompiled.", 0, 0);
    }
    mssgtmr--;
  }
}





public CmdOutput runOSCommand(String cmd) {
  try {
    Process process = Runtime.getRuntime().exec(cmd);
    
    BufferedReader stdInput = new BufferedReader(new InputStreamReader(process.getInputStream()));
    BufferedReader stdError = new BufferedReader(new InputStreamReader(process.getErrorStream()));
    
    int exitCode = process.waitFor();
    
    String s = null;
    
    String stdoutput = "";
    
    if (exitCode == 1) {
      while ((s = stdInput.readLine()) != null) {
          stdoutput += s+"\n";
      }
      while ((s = stdError.readLine()) != null) {
          stdoutput += s+"\n";
      }
      
      System.out.println(stdoutput);
    }
    
    System.out.println("Exit code: "+exitCode);
    return new CmdOutput(exitCode, stdoutput);
  }
  catch (Exception e) {
    System.err.println("OS command exception: "+ e.getClass().getSimpleName());
    System.err.println(e.getMessage());
    return new CmdOutput(666, e.getClass().getSimpleName());
  }
}

class CmdOutput {
  public int exitCode = -1;
  public boolean success = false;
  public String message = "";
  
  
  public CmdOutput(int ec, String mssg) {
    exitCode = ec;
    success =  (exitCode == 0);
    message = mssg;
  }
}





int specialNumber() {
  return 6969;
}


  
