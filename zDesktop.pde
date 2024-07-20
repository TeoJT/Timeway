//// How to enable Desktop mode in your code:
//// ctrl+a
//// ctrl+/
//// Yes. That's really now you do it.
//// Make sure to do it to zAndroid too.


//import com.jogamp.newt.opengl.GLWindow;
//import java.awt.Toolkit;
//import java.awt.event.MouseWheelEvent;
//import java.awt.event.MouseWheelListener;
//import java.awt.datatransfer.Clipboard;
//import java.awt.datatransfer.Transferable;
//import java.awt.datatransfer.DataFlavor;
//import java.awt.datatransfer.UnsupportedFlavorException;
//import java.awt.datatransfer.StringSelection;
//import java.awt.Toolkit;
//import java.awt.datatransfer.Clipboard;
//import java.awt.image.BufferedImage;
//import java.awt.Desktop;
//import javax.swing.JOptionPane;
//import processing.soundde.*;
//import javax.sound.sampled.AudioSystem;
//import javax.sound.sampled.AudioFileFormat;
//import javax.sound.sampled.AudioFormat;
//import javax.sound.sampled.AudioInputStream;


//// Sometimes it can be called if it's exclusive to android, and no action happens in Java mode.
//// If calling said funciton affects how things work in Java mode, this should be used to warn,
//// but not if it only does nothing.
//private void shouldNotBeCalled(String funcitonName) {
//  timewayEngine.console.bugWarnOnce(funcitonName+": You should not call this in Java/Desktop mode!"); 
//}

//public boolean isLinux() {
//  return (platform == LINUX);
//}

//public boolean isWindows() {
//  return (platform == WINDOWS);
//}

//public boolean isMacOS() {
//  return (platform == MACOS);
//}

//public boolean isAndroid() {
//  return false;
//}

//public void setDesktopIcon(String iconPath) {
//  PJOGL.setIcon(iconPath);
//}

//public String sketchPath() {
//  return super.sketchPath();
//}

//protected PSurface initSurface() {
//    PSurface s = super.initSurface();
    
//    // Windows is annoying with maximised screens
//    // So let's do this hack to make the screen maximised.
//    boolean maximise = sketch_MAXIMISE;
    
//    if (maximise) {
//      if (platform == WINDOWS) {
//        try {
//          // Set maximised.
//          Object o = surface.getNative();
//          if (o instanceof GLWindow) {
//            GLWindow window = (GLWindow)o;
//            window.setMaximized(true, true);
//          }
//        }
//        catch (Exception e) {
//          sketch_openErrorLog(
//              "Maximise error. This is a bug."
//              );
//        }
//      }
//    }
//    s.setTitle(Engine.APP_NAME);
//    s.setResizable(true);
//    return s;
//}

//protected void selectOutputSketch(String promptMessage, String outputFileSelected) {
//  // TODO: implement file selector.
//  super.selectOutput(promptMessage, outputFileSelected);
//}

//public Object getFromClipboardStringFlavour() {
//  return getFromClipboard(DataFlavor.stringFlavor);
//}

//public Object getFromClipboardImageFlavour() {
//  return getFromClipboard(DataFlavor.imageFlavor);
//}

//public Object getFromClipboard(DataFlavor flavor)
//    {
//      Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
//      Transferable contents;
//      try {
//        contents = clipboard.getContents(null);
//      }
//      catch (IllegalStateException e) {
//        contents = null;
//      }
  
//      Object obj = null;
//      if (contents != null && contents.isDataFlavorSupported(flavor))
//      {
//        try
//        {
//          obj = contents.getTransferData(flavor);
//        }
//        catch (UnsupportedFlavorException exu) // Unlikely but we must catch it
//        {
//          timewayEngine.console.warn("(Copy/paste) Unsupported flavor");
//          //~  exu.printStackTrace();
//        }
//        catch (java.io.IOException exi)
//        {
//          timewayEngine.console.warn("(Copy/paste) Unavailable data: " + exi);
//          //~  exi.printStackTrace();
//        }
//      }
//      return obj;
//    } 
    
//@SuppressWarnings("deprecation")
//public PImage getPImageFromClipboard()
//{
//  PImage img = null;
  
//  java.awt.Image image = (java.awt.Image) getFromClipboard(DataFlavor.imageFlavor);
  
//  if (image != null)
//  {
//    img = new PImage(image);
//  }
//  return img;
//}


//public void copyStringToClipboard(String s) {
//  StringSelection stringSelection = new StringSelection(s);
//  Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
//  clipboard.setContents(stringSelection, null);
//}


//public void desktopOpen(String file) {
//  if (Desktop.isDesktopSupported()) {
//    // Open desktop app with this snippet of code that I stole.
//    try {
//      Desktop desktop = Desktop.getDesktop();
//      File myFile = new File(file);
//      try {
//        desktop.open(myFile);
//      }
//      catch (IllegalArgumentException fileNotFound) {
//        timewayEngine.console.log("This file or dir no longer exists!");
//        timewayEngine.file.refreshDir();
//      }
//    } 
//    catch (IOException ex) {
//      timewayEngine.console.warn("Couldn't open file IOException");
//    }
//  } else {
//    timewayEngine.console.warn("Couldn't open file, isDesktopSupported=false.");
//  }
//}

//public void openErrorLog() {
//  if (Desktop.isDesktopSupported()) {
//    // Open desktop app with this snippet of code that I stole.
//    try {
//      Desktop desktop = Desktop.getDesktop();
//      File myFile = new File(sketch_ERR_LOG_PATH);
//      desktop.open(myFile);
//    } 
//    catch (IOException ex) {
//    }
//  }
//}

//public void minimalErrorDialog(String mssg) {
//  JOptionPane.showMessageDialog(null,mssg,Engine.APP_NAME,1);
//}

//public void requestAndroidPermissions() {
//}

//void openTouchKeyboard() {
  
//}

//void closeTouchKeyboard() {
  
//}

//public String getAndroidCacheDir() {
//  shouldNotBeCalled("getAndroidCacheDir");
//  return "";
//}

//public String getAndroidWriteableDir() {
//  shouldNotBeCalled("getAndroidWriteableDir");
//  return "";
//}


//public PImage getDCaptureImage(DSCapture capture) {
//    PImage img = createImage(capture.getDisplaySize().width, capture.getDisplaySize().height, RGB);
//    BufferedImage bimg = capture.getImage();
//    bimg.getRGB(0, 0, img.width, img.height, img.pixels, 0, img.width);
//    img.updatePixels();
//    return img;
//}

//public int getDCaptureWidth(DSCapture capture) {
//  return capture.getDisplaySize().width;
//}

//public int getDCaptureHeight(DSCapture capture) {
//  return capture.getDisplaySize().height;
//}

//public void openAndroidCamera() {
  
//}

//public void saveByteArrayAsWAV(byte[] audioData, int sampleRate, int bitDepth, int numChannels, String path) {
//  AudioFormat audioFormat = new AudioFormat(sampleRate, bitDepth, numChannels, true, false);
  
//  try {
//      ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(audioData);
//      AudioInputStream audioInputStream = new AudioInputStream(byteArrayInputStream, audioFormat, (audioData.length / 4) / numChannels);
//      AudioSystem.write(audioInputStream, AudioFileFormat.Type.WAVE, new File(path));
//  } catch (IOException e) {
//      e.printStackTrace();
//  }
//}

//// In Java/Desktop mode, this class remains completely unused, we just
//// have it here to keep Java complaining "WAHH MAH CLASSES ARE MISSENG";
//public class AndroidMedia {
//  @SuppressWarnings("unused")
//  public AndroidMedia(String path) {
//  }
  
//  public void play() {
//  }
  
//  public void loop() {
//  }
  
//  public void stop() {
//  }
  
//  @SuppressWarnings("unused")
//  public void volume(float vol) {
//  }
  
//  public boolean isPlaying() {
//    return false;
//  }
//}
