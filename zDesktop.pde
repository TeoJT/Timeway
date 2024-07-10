// How to enable Desktop mode in your code:
// ctrl+a
// ctrl+/
// Yes. That's really now you do it.
// Make sure to do it to zAndroid too.


import com.jogamp.newt.opengl.GLWindow;
import java.awt.Toolkit;
import java.awt.event.MouseWheelEvent;
import java.awt.event.MouseWheelListener;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.Transferable;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.awt.datatransfer.StringSelection;
import java.awt.Toolkit;
import java.awt.datatransfer.Clipboard;
import java.awt.image.BufferedImage;
import java.awt.Desktop;
import javax.swing.JOptionPane;
import processing.sound.*;

// Sometimes it can be called if it's exclusive to android, and no action happens in Java mode.
// If calling said funciton affects how things work in Java mode, this should be used to warn,
// but not if it only does nothing.
private void shouldNotBeCalled(String funcitonName) {
  timewayEngine.console.bugWarnOnce(funcitonName+": You should not call this in Java/Desktop mode!"); 
}

public boolean isLinux() {
  return (platform == LINUX);
}

public boolean isWindows() {
  return (platform == WINDOWS);
}

public boolean isMacOS() {
  return (platform == MACOS);
}

public boolean isAndroid() {
  return false;
}

public void setDesktopIcon(String iconPath) {
  PJOGL.setIcon(iconPath);
}

public String sketchPath() {
  return super.sketchPath();
}

protected PSurface initSurface() {
    PSurface s = super.initSurface();
    
    // Windows is annoying with maximised screens
    // So let's do this hack to make the screen maximised.
    boolean maximise = true;
    
    if (maximise) {
      if (platform == WINDOWS) {
        try {
          // Set maximised.
          Object o = surface.getNative();
          if (o instanceof GLWindow) {
            GLWindow window = (GLWindow)o;
            window.setMaximized(true, true);
          }
        }
        catch (Exception e) {
          sketch_openErrorLog(
              "Maximise error. This is a bug."
              );
        }
      }
    }
    s.setTitle(Engine.APP_NAME);
    s.setResizable(true);
    return s;
}

protected void selectOutputSketch(String promptMessage, String outputFileSelected) {
  // TODO: implement file selector.
  super.selectOutput(promptMessage, outputFileSelected);
}

public Object getFromClipboardStringFlavour() {
  return getFromClipboard(DataFlavor.stringFlavor);
}

public Object getFromClipboardImageFlavour() {
  return getFromClipboard(DataFlavor.imageFlavor);
}

public Object getFromClipboard(DataFlavor flavor)
    {
      Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
      Transferable contents;
      try {
        contents = clipboard.getContents(null);
      }
      catch (IllegalStateException e) {
        contents = null;
      }
  
      Object obj = null;
      if (contents != null && contents.isDataFlavorSupported(flavor))
      {
        try
        {
          obj = contents.getTransferData(flavor);
        }
        catch (UnsupportedFlavorException exu) // Unlikely but we must catch it
        {
          timewayEngine.console.warn("(Copy/paste) Unsupported flavor");
          //~  exu.printStackTrace();
        }
        catch (java.io.IOException exi)
        {
          timewayEngine.console.warn("(Copy/paste) Unavailable data: " + exi);
          //~  exi.printStackTrace();
        }
      }
      return obj;
    } 
    
@SuppressWarnings("deprecation")
public PImage getPImageFromClipboard()
{
  PImage img = null;
  
  java.awt.Image image = (java.awt.Image) getFromClipboard(DataFlavor.imageFlavor);
  
  if (image != null)
  {
    img = new PImage(image);
  }
  return img;
}


public void copyStringToClipboard(String s) {
  StringSelection stringSelection = new StringSelection(s);
  Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
  clipboard.setContents(stringSelection, null);
}

public boolean isClipboardImage(Object o) {
  return (o instanceof java.awt.Image);
}

public void desktopOpen(String file) {
  if (Desktop.isDesktopSupported()) {
    // Open desktop app with this snippet of code that I stole.
    try {
      Desktop desktop = Desktop.getDesktop();
      File myFile = new File(file);
      try {
        desktop.open(myFile);
      }
      catch (IllegalArgumentException fileNotFound) {
        timewayEngine.console.log("This file or dir no longer exists!");
        timewayEngine.file.refreshDir();
      }
    } 
    catch (IOException ex) {
      timewayEngine.console.warn("Couldn't open file IOException");
    }
  } else {
    timewayEngine.console.warn("Couldn't open file, isDesktopSupported=false.");
  }
}

public void openErrorLog() {
  if (Desktop.isDesktopSupported()) {
    // Open desktop app with this snippet of code that I stole.
    try {
      Desktop desktop = Desktop.getDesktop();
      File myFile = new File(sketch_ERR_LOG_PATH);
      desktop.open(myFile);
    } 
    catch (IOException ex) {
    }
  }
}

public void minimalErrorDialog(String mssg) {
  JOptionPane.showMessageDialog(null,mssg,Engine.APP_NAME,1);
}

public void requestAndroidPermissions() {
}

void openTouchKeyboard() {
  
}

void closeTouchKeyboard() {
  
}

public String getAndroidCacheDir() {
  shouldNotBeCalled("getAndroidCacheDir");
  return "";
}

public String getAndroidWriteableDir() {
  shouldNotBeCalled("getAndroidWriteableDir");
  return "";
}


public PImage getDCaptureImage(DSCapture capture) {
    PImage img = createImage(width, height, RGB);
    BufferedImage bimg = capture.getImage();
    bimg.getRGB(0, 0, img.width, img.height, img.pixels, 0, img.width);
    img.updatePixels();
    return img;
}

public int getDCaptureWidth(DSCapture capture) {
  return capture.getDisplaySize().width;
}

public int getDCaptureHeight(DSCapture capture) {
  return capture.getDisplaySize().height;
}
