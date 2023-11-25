import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.Transferable;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.awt.Window;
import processing.awt.PSurfaceAWT;
import javax.swing.JFrame;
import java.awt.Toolkit;

String pastedMessage;
PImage pastedImage;


void setup()
{
  size(1024, 1024, P3D);
  PFont f = createFont("Arial", 12);
  textFont(f);
}

void draw()
{
    pastedMessage = GetTextFromClipboard();
    pastedImage = GetImageFromClipboard();
  background(255);
  if (pastedImage != null)
  {
    image(pastedImage, 0, 0);
  }
  if (pastedMessage != null)
  {
    fill(#008800);
    text(pastedMessage, 5, 15);
  }
}

void keyPressed()
{
  //if (key == 0x16) // Ctrl+v
  //{
    pastedMessage = GetTextFromClipboard();
    pastedImage = GetImageFromClipboard();
}

String GetTextFromClipboard()
{
  String text = (String) GetFromClipboard(DataFlavor.stringFlavor);
  return text;
}

PImage GetImageFromClipboard()
{
  PImage img = null;
  java.awt.Image image = (java.awt.Image) GetFromClipboard(DataFlavor.imageFlavor);
  if (image != null)
  {
    img = new PImage(image);
  }
  return img;
}

public Toolkit getToolkit() {
  return Toolkit.getDefaultToolkit();
  //try {
  //  PSurfaceAWT surf = (PSurfaceAWT) getSurface();
  //  PSurfaceAWT.SmoothCanvas canvas = (PSurfaceAWT.SmoothCanvas) surf.getNative();
  //  JFrame j = (JFrame) canvas.getFrame();
  //  return j.getToolkit();
  //}
  //catch (ClassCastException e) {
  //  PSurfaceJOGL surf = (PSurfaceJOGL) getSurface();
  //  return surf.getComponent().getToolkit();
  //}
}

Object GetFromClipboard(DataFlavor flavor)
{
  Clipboard clipboard;
  clipboard = getToolkit().getSystemClipboard();
  //try {
  //  SmoothCanvas w = (SmoothCanvas)surface.getNative();
  //  clipboard = w.getToolkit().getSystemClipboard();
  //}
  //catch (ClassCastException e) {
  //  GLWindow w = (GLWindow)surface.getNative();
  //  Window ww = w.
  //  ww.getToolkit().getSystemClipboard();
  //}
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
 println("Unsupported flavor: " + exu);
//~  exu.printStackTrace();
    }
    catch (java.io.IOException exi)
    {
 println("Unavailable data: " + exi);
//~  exi.printStackTrace();
    }
  }
  return obj;
} 
