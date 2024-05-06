
import java.net.URLClassLoader;
import java.net.URL;
import java.lang.reflect.Method;
import java.lang.reflect.Parameter;
import java.io.*;

String pluginBoilerplateCode_1;
String pluginBoilerplateCode_2;



Class pluginClass;
Method pluginRunPoint;
Method pluginGetOpCode;
Method pluginGetArgs;
Method pluginSetRet;
Object pluginIntance;

Runnable callAPI = new Runnable() {
      public void run() {
        runAPI();
      }
};


// "C:\mydata\apps\processing-4.3\java\bin\javac.exe" -cp "C:\mydata\apps\processing-4.3\core\library\core.jar" CustomPlugin.java
// "C:\mydata\apps\processing-4.3\java\bin\jar.exe" cvf CustomPlugin.jar *.class


float bump = 0;

String javapath;

void setup() {
  size(1024, 1024, P2D);
  scale(2);
  System.out.println("Host running.");
  System.out.println("Compiling plugin...");
  consoleFont = createFont("Courier New Bold", 32);
  textFont(consoleFont, 40);
  
  // Get the java executables path.
  String pp = (new File(".").getAbsolutePath());
  javapath = pp.substring(0, pp.length()-2).replaceAll("\\\\", "/")+"/java";
  println(javapath);
  
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
  String code = """
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
  
  // Compile the code.
  compile(code);
}

void runPlugin() {
  if (pluginRunPoint != null && pluginIntance != null) {
  
    try {
      pluginRunPoint.invoke(pluginIntance);
    }
    catch (Exception e) {
      System.err.println("Run plugin exception: "+ e.getClass().getSimpleName());
      exit();
    }
  }
}

boolean compileError = false;
int mssgtmr = 0;
int nn = 0;
String errorOutput = "";

void compile(String code) {
  nn++;
  compileError = false;
  mssgtmr = 60;
  
  println("Compiling plugin...");
  
  final String javaFileOut = sketchPath()+"/data/pluginCache/CustomPlugin.java";
  final String classFileOut = sketchPath()+"/data/pluginCache/CustomPlugin.class";
  
  String fullCode = pluginBoilerplateCode_1+code+pluginBoilerplateCode_2;
  println(fullCode);
  
  saveStrings(javaFileOut, fullCode.split("\n"));
  
  toClassFile(javaFileOut); 
  loadPlugin(toJarFile(classFileOut));
}

boolean toClassFile(String inputFile) {
  final String javacPath = javapath+"/bin/javac.exe";
  final String processingCorePath = "C:/mydata/apps/processing-4.3/core/library/core.jar";
  final String pluginPath = sketchPath()+"/data/pluginCache/";
  
  int s = runOSCommand("\""+javacPath+"\" -cp \""+processingCorePath+";"+pluginPath+"\" \""+inputFile+"\"");
  if (s != 0) {
    compileError = true;
    return false;
  }
  
  return true;
}

String toJarFile(String classFile) {
  final String jarExePath = "C:/mydata/apps/processing-4.3/java/bin/jar.exe";
  final String out = sketchPath()+"/data/pluginCache/cache-"+nn+".jar";
  final String classPath = (new File(classFile)).getParent().toString();
  final String className = (new File(classFile)).getName();
  runOSCommand("\""+jarExePath+"\" cvf \""+out+"\" -C \""+classPath+"\" "+className);
  return out;
}

void mouseClicked() {
  //compile();
}

PFont consoleFont;

void draw() {
  if (!compileError) {
    if (lalalaMode) {
      background(sin(frameCount*0.5)*64+64, 0, 255);
    }
    else
      background(200);
    lalalaMode = false;
    runPlugin();
    
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
    text(errorOutput, 0, 0, width, height);
  }
  
  
  if (mssgtmr > 0) {
    textSize(40);
    textAlign(LEFT, TOP);
    if (compileError) {
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
    
    passAppletMethod.invoke(pluginIntance, (PApplet)this, callAPI);
  }
  catch (Exception e) {
    System.err.println("passPApplet Exception: "+ e.getClass().getSimpleName());
    System.err.println(e.getMessage());
    //exit();
  }
}

public int runOSCommand(String cmd) {
  try {
    Process process = Runtime.getRuntime().exec(cmd);
    
    BufferedReader stdInput = new BufferedReader(new InputStreamReader(process.getInputStream()));
    BufferedReader stdError = new BufferedReader(new InputStreamReader(process.getErrorStream()));
    
    int exitCode = process.waitFor();
    
    String s = null;
    
    if (exitCode == 1) {
      errorOutput = "";
      
      while ((s = stdInput.readLine()) != null) {
          errorOutput += s+"\n";
      }
      while ((s = stdError.readLine()) != null) {
          errorOutput += s+"\n";
      }
      
      System.out.println(errorOutput);
    }
    
    System.out.println("Exit code: "+exitCode);
    return exitCode;
  }
  catch (Exception e) {
    System.err.println("OS command exception: "+ e.getClass().getSimpleName());
    System.err.println(e.getMessage());
    return 666;
  }
}



public void runAPI() {
  // The getCallOpCode method takes no arguments and returns an int
  // The getArgs method takes no arguments and returns an Object[]
  // The setRet method takes an Object as argument and returns void
  int opcode = -1;
  Object[] args = null;
  try {
    opcode = (int) pluginGetOpCode.invoke(pluginIntance);
    args = (Object[]) pluginGetArgs.invoke(pluginIntance);
  }
  catch (Exception e) {
    println("Ohno");
    return;
  }
  switch (opcode) {
    case 1:
    bump = (float)args[0];
    break;
    case 2:
    ret(specialNumber());
    break;
    default:
    println("Unknown opcode "+opcode);
    break;
  }
}

int specialNumber() {
  return 6969;
}

void ret(Object val) {
  try {
    pluginSetRet.invoke(pluginIntance, val);
  }
  catch (Exception e) {
    println("Ohno");
  }
}

boolean lalalaMode = false;
public void lalala() {
  lalalaMode = true;
}
  
  
