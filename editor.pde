import java.util.Base64;
import de.humatic.dsj.DSCapture;
import processing.video.Capture;
//import java.awt.image.BufferedImage;
import java.util.concurrent.atomic.AtomicInteger;

class CameraException extends RuntimeException {};

abstract class EditorCapture {
  public int width, height;
  protected TWEngine engine;
  
  public AtomicBoolean ready = new AtomicBoolean(false);
  public AtomicBoolean error = new AtomicBoolean(false);
  public AtomicInteger errorCode = new AtomicInteger(0);
  public int selectedCamera = 0;
  
  public abstract void setup();
  public abstract void turnOffCamera();
  public abstract void switchNextCamera();
  public abstract PImage updateImage();
  public abstract int numberDevices();
}

class PCapture extends EditorCapture {
  
  private String[] cameraDevices = null;
  private Capture capture = null;
  private PImage currCapture = null;
  
  public PCapture(TWEngine e) {
    ready.set(false);
    error.set(false);
    engine = e;
    currCapture = engine.display.errorImg;
  }
  
  
  public void setup() {
    ready.set(false);
    error.set(false);
    
    try {
      cameraDevices = Capture.list();
      
      if (cameraDevices.length <= 0) {
          error.set(true);
          errorCode.set(Editor.ERR_NO_CAMERA_DEVICES);
          return;
      }
      
      if (cameraDevices == null) {
        //engine.console.log("Unable to get cameras, but I'll try to start default camera anyway...");
        
        //boolean failed = false;
        //try {
        //  capture = new Capture(engine.app);
          
        //  if (capture == null) {
        //    failed = true;
        //  }
        //}
        //catch (Exception e) {
        //  failed = true;
        //}
        
        //if (failed) {
        //  engine.console.warn("I tried. Unable to start default camera.");
        //  error.set(true);
        //  errorCode.set(Editor.ERR_UNKNOWN);
        //  return;
        //}
        //// At this point it has been successful so spoof
        //// camera device
        //cameraDevices = new String[1];
        //cameraDevices[0] = "Unknown device";
        
        // TODO: at least try the default camera
        error.set(true);
        errorCode.set(Editor.ERR_UNKNOWN);
        return;
      }
    }
    catch (Exception e) {
      error.set(true);
      errorCode.set(Editor.ERR_UNKNOWN);
      return;
    }
    
    selectedCamera = (int)engine.sharedResources.get("lastusedcamera", 0);
    activateCamera();
    
    ready.set(true);
  }
  
  // Activate currently selected camera, switching to next camera if it doesn't work
  private void activateCamera() {
    boolean success = false;
    int originalSelection = selectedCamera;
    
    while (!success) {
      try {
        // Activate the next camera in the list.
        // Some cameras may not work. Skip them if they don't work. If none of them work, throw an error.
        capture = new Capture(engine.app, cameraDevices[selectedCamera]);
        success = true;
      }
      catch (DSJException e) {
        success = false; // Keep trying
        // Increase index by 1, reset to 0 if we're at end of list.
        selectedCamera = ((selectedCamera+1)%(cameraDevices.length));
        
        // If we're back where we started, then there's been a problem :(
        if (originalSelection == selectedCamera) {
          error.set(true);
          errorCode.set(Editor.ERR_FAILED_TO_SWITCH);
          return;
        }
      }
    }
    
    capture.start();
    capture.read();
    
    width = capture.width;
    height = capture.height;
  }
  
  
  public PImage updateImage() {
    if (capture == null) {
      engine.console.bugWarnOnce("No capture available.");
      return engine.display.errorImg;
    }
    if (capture.available()) {
      capture.read();
      currCapture = capture;
    }
    return currCapture;
  }
  
  public void switchNextCamera() {
    // Only run if a camera isn't currently being setup.
    if (ready.compareAndSet(true, false)) {
      if (cameraDevices == null) return;
      if (cameraDevices.length == 0) return;
      
      // Turn off last used camera.
      turnOffCamera();
      
      // Increase index by 1, reset to 0 if we're at end of list.
      selectedCamera = ((selectedCamera+1)%(cameraDevices.length));
      activateCamera();
      
      ready.set(true);
    }
  }
  
  public int numberDevices() {
    return cameraDevices.length;
  }
  
  public void turnOffCamera() {
    if (capture != null) capture.stop();
  }
  
  
}

class DCapture extends EditorCapture implements java.beans.PropertyChangeListener {
  private DSCapture capture;
  public final int DEVICE_NONE = -1;
  public final int DEVICE_CAMERA     = 0;
  public final int DEVICE_MICROPHONE = 1;
  
  public ArrayList<DSFilterInfo> cameraDevices;
 
  public DCapture(TWEngine e) {
    ready.set(false);
    error.set(false);
    engine = e;
  }
  
  // Lmao don't care 
  @SuppressWarnings("deprecation")
  private boolean isCamera(DSFilterInfo dsi) {
    return (dsi.getType() == DEVICE_CAMERA
    && !dsi.getName().contains("OBS Virtual Camera")  // This will make timeway crash.
    );
  }
  
  public void setup() {
    ready.set(false);
    error.set(false);
    
    try {
      DSFilterInfo[][] dsi = DSCapture.queryDevices();
      cameraDevices = new ArrayList<DSFilterInfo>();
      
      for (int y = 0; y < dsi.length; y++) {
        for (int x = 0; x < dsi[y].length; x++) {
          if (isCamera(dsi[y][x])) {
            //println("("+x+", "+y+") "+dsi[y][x].getName(), dsi[y][x].getType());
            cameraDevices.add(dsi[y][x]);
          }
        }
      }
      
      if (cameraDevices.size() <= 0) {
        error.set(true);
        errorCode.set(Editor.ERR_NO_CAMERA_DEVICES);
        return;
      }
    }
    catch (UnsatisfiedLinkError e) {
        error.set(true);
        errorCode.set(Editor.ERR_UNSUPPORTED_SYSTEM);
        return;
    }
    catch (NoClassDefFoundError e) {
        error.set(true);
        errorCode.set(Editor.ERR_UNSUPPORTED_SYSTEM);
        return;
    }
    catch (Exception e) {
        error.set(true);
        errorCode.set(Editor.ERR_UNKNOWN);
        return;
    }
    
    
    selectedCamera = (int)engine.sharedResources.get("lastusedcamera", 0);
    activateCamera();
    
    ready.set(true);
  }
  
  public void turnOffCamera() {
    if (capture != null) capture.dispose();
  }
  
  // Activate currently selected camera, switching to next camera if it doesn't work
  private void activateCamera() {
    boolean success = false;
    int originalSelection = selectedCamera;
    
    while (!success) {
      try {
        // Activate the next camera in the list.
        // Some cameras may not work. Skip them if they don't work. If none of them work, throw an error.
        capture = new DSCapture(DSFiltergraph.DD7, cameraDevices.get(selectedCamera), false, DSFilterInfo.doNotRender(), this);
        success = true;
      }
      catch (DSJException e) {
        success = false; // Keep trying
        // Increase index by 1, reset to 0 if we're at end of list.
        selectedCamera = ((selectedCamera+1)%(cameraDevices.size()));
        
        // If we're back where we started, then there's been a problem :(
        if (originalSelection == selectedCamera) {
          error.set(true);
          errorCode.set(Editor.ERR_FAILED_TO_SWITCH);
          return;
        }
      }
    }
    
    width =  getDCaptureWidth(capture);
    height = getDCaptureHeight(capture);
  }
  
  public void switchNextCamera() {
    // Only run if a camera isn't currently being setup.
    if (ready.compareAndSet(true, false)) {
      if (cameraDevices == null) return;
      if (cameraDevices.size() == 0) return;
      
      // Turn off last used camera.
      turnOffCamera();
      
      // Increase index by 1, reset to 0 if we're at end of list.
      selectedCamera = ((selectedCamera+1)%(cameraDevices.size()));
      activateCamera();
      
      ready.set(true);
    }
  }
  
  public int numberDevices() {
    return cameraDevices.size();
  }
 
  public PImage updateImage() {
    return getDCaptureImage(capture);
  }
 
  public void propertyChange(java.beans.PropertyChangeEvent e) {
    switch (DSJUtils.getEventType(e)) {
    }
  }
}













// Pretty much a copy+paste of Processing's source code, but specifically for software rendering,
// and also being multi-threading friendly.
public class SoftwareRenderer {
  public PFont textFont;
  protected char[] textBuffer = new char[8 * 1024];
  protected char[] textWidthBuffer = new char[8 * 1024];
  
  protected int textBreakCount;
  protected int[] textBreakStart;
  protected int[] textBreakStop;
  
  private PImage canvas;
  
  private float scaleX = 0f;
  private float scaleY = 0f;
  
  private color fillColor = 0;
  
  /** The current text align (read-only) */
  public int textAlign = LEFT;

  /** The current vertical text alignment (read-only) */
  public int textAlignY = BASELINE;

  /** The current text mode (read-only) */
  public int textMode = MODEL;

  /** The current text size (read-only) */
  public float textSize = 16;

  /** The current text leading (read-only) */
  public float textLeading;

  /** Used internally to check whether still using the default font */
  protected String defaultFontName;

  static final protected String ERROR_TEXTFONT_NULL_PFONT =
    "A null PFont was passed to textFont()";
  
  
  public SoftwareRenderer(PImage canvas) {
    fillColor = color(255);
    textSize = 12;
    textLeading = 14;
    textAlign = LEFT;
    textMode = MODEL;
    this.canvas = canvas;
  }
  
  public void beginDraw() {
    canvas.loadPixels();
  }
  
  public void clear() {
    for (int y = 0; y < canvas.height; y++) {
      for (int x = 0; x < canvas.width; x++) {
        canvas.pixels[y*canvas.width + x] = 0xFF0f0f0e;
      }
    }
  }
  
  public void endDraw() {
    canvas.updatePixels();
  }
  
  public void textLeading(float leading) {
    textLeading = leading;
  }
  
  // Just to keep code consistant and clean(-ish)
  public void fill(color c) {
    //fill(c);
    fillColor = c;
  }
  public void fill(float c) {
    //fill(c);
    fillColor = color(c);
  }
  public void fill(color c, float a) {
    //fill(c, a);
    fillColor = color(c, a);
  }
  public void fill(float c, float a) {
    //fill(c, a);
    fillColor = color(c, a);
  }
  public void fill(float r, float g, float b) {
    //fill(r,g,b);
    fillColor = color(r, g, b);
  }
  public void fill(float r, float g, float b, float a) {
    //fill(r,g,b,a);
    fillColor = color(r, g, b, a);
  }
  
  
  public void text(String str, float x, float y) {
      if (textFont == null) {
        // TODO: Add warning
        return;
      }
  
      int length = str.length();
      if (length > textBuffer.length) {
        textBuffer = new char[length + 10];
      }
      str.getChars(0, length, textBuffer, 0);
      text(textBuffer, 0, length, x, y);
    }
    
    
    
    public void text(char[] chars, int start, int stop, float x, float y) {
      // If multiple lines, sum the height of the additional lines
      float high = 0; //-textAscent();
      for (int i = start; i < stop; i++) {
        if (chars[i] == '\n') {
          high += textLeading;
        }
      }
      if (textAlignY == CENTER) {
        // for a single line, this adds half the textAscent to y
        // for multiple lines, subtract half the additional height
        //y += (textAscent() - textDescent() - high)/2;
        y += (textAscent() - high)/2;
      } else if (textAlignY == TOP) {
        // for a single line, need to add textAscent to y
        // for multiple lines, no different
        y += textAscent();
      } else if (textAlignY == BOTTOM) {
        // for a single line, this is just offset by the descent
        // for multiple lines, subtract leading for each line
        y -= textDescent() + high;
      //} else if (textAlignY == BASELINE) {
        // do nothing
      }
  
  //    int start = 0;
      int index = 0;
      while (index < stop) { //length) {
        if (chars[index] == '\n') {
          textLineAlignImpl(chars, start, index, x, y);
          start = index + 1;
          y += textLeading;
        }
        index++;
      }
      if (start < stop) {  //length) {
        textLineAlignImpl(chars, start, index, x, y);
      }
    }
  
  
  
  
  public void text(String str, float x1, float y1, float x2, float y2) {
      if (textFont == null) {
        
      }
      
      // NOTE: Removed switch statement here.
      x2 += x1;
      y2 += y1;
      
      if (x2 < x1) {
        float temp = x1; x1 = x2; x2 = temp;
      }
      if (y2 < y1) {
        float temp = y1; y1 = y2; y2 = temp;
      }
  
  //    float currentY = y1;
      float boxWidth = x2 - x1;
  
  //    // ala illustrator, the text itself must fit inside the box
  //    currentY += textAscent(); //ascent() * textSize;
  //    // if the box is already too small, tell em to f off
  //    if (currentY > y2) return;
  
  //    float spaceWidth = textWidth(' ');
  
      if (textBreakStart == null) {
        textBreakStart = new int[20];
        textBreakStop = new int[20];
      }
      textBreakCount = 0;
  
      int length = str.length();
      if (length + 1 > textBuffer.length) {
        textBuffer = new char[length + 1];
      }
      str.getChars(0, length, textBuffer, 0);
      // add a fake newline to simplify calculations
      textBuffer[length++] = '\n';
  
      int sentenceStart = 0;
      for (int i = 0; i < length; i++) {
        if (textBuffer[i] == '\n') {
  //        currentY = textSentence(textBuffer, sentenceStart, i,
  //                                lineX, boxWidth, currentY, y2, spaceWidth);
          boolean legit =
            textSentence(textBuffer, sentenceStart, i, boxWidth);
          if (!legit) break;
  //      if (Float.isNaN(currentY)) break;  // word too big (or error)
  //      if (currentY > y2) break;  // past the box
          sentenceStart = i + 1;
        }
      }
  
      // lineX is the position where the text starts, which is adjusted
      // to left/center/right based on the current textAlign
      float lineX = x1; //boxX1;
      if (textAlign == CENTER) {
        lineX = lineX + boxWidth/2f;
      } else if (textAlign == RIGHT) {
        lineX = x2; //boxX2;
      }
  
      float boxHeight = y2 - y1;
      //int lineFitCount = 1 + PApplet.floor((boxHeight - textAscent()) / textLeading);
      // incorporate textAscent() for the top (baseline will be y1 + ascent)
      // and textDescent() for the bottom, so that lower parts of letters aren't
      // outside the box. [0151]
      float topAndBottom = textAscent() + textDescent();
      int lineFitCount = 1 + PApplet.floor((boxHeight - topAndBottom) / textLeading);
      int lineCount = Math.min(textBreakCount, lineFitCount);
  
      if (textAlignY == CENTER) {
        float lineHigh = textAscent() + textLeading * (lineCount - 1);
        float y = y1 + textAscent() + (boxHeight - lineHigh) / 2;
        for (int i = 0; i < lineCount; i++) {
          textLineAlignImpl(textBuffer, textBreakStart[i], textBreakStop[i], lineX, y);
          y += textLeading;
        }
  
      } else if (textAlignY == BOTTOM) {
        float y = y2 - textDescent() - textLeading * (lineCount - 1);
        for (int i = 0; i < lineCount; i++) {
          textLineAlignImpl(textBuffer, textBreakStart[i], textBreakStop[i], lineX, y);
          y += textLeading;
        }
  
      } else {  // TOP or BASELINE just go to the default
        float y = y1 + textAscent();
        for (int i = 0; i < lineCount; i++) {
          textLineAlignImpl(textBuffer, textBreakStart[i], textBreakStop[i], lineX, y);
          y += textLeading;
        }
      }
    }
    
    
    
    protected void textLineAlignImpl(char[] buffer, int start, int stop,
                                     float x, float y) {
      if (textAlign == CENTER) {
        x -= textWidthImpl(buffer, start, stop) / 2f;
  
      } else if (textAlign == RIGHT) {
        x -= textWidthImpl(buffer, start, stop);
      }
  
      textLineImpl(buffer, start, stop, x, y);
    }
  
  
    /**
     * Implementation of actual drawing for a line of text.
     */
    protected void textLineImpl(char[] buffer, int start, int stop,
                                float x, float y) {
      for (int index = start; index < stop; index++) {
        textCharImpl(buffer[index], x, y);
  
        // this doesn't account for kerning
        x += this.textWidth(buffer[index]);
      }
  //    textX = x;
  //    textY = y;
  //    textZ = 0;  // this will get set by the caller if non-zero
    }
  
  
    protected void textCharImpl(char ch, float x, float y) { //, float z) {
      PFont.Glyph glyph = textFont.getGlyph(ch);
      if (glyph != null) {
        if (textMode == MODEL) {
          float floatSize = textFont.getSize();
          float high = glyph.height / floatSize;
          float wide = glyph.width / floatSize;
          float leftExtent = glyph.leftExtent / floatSize;
          float topExtent = glyph.topExtent  / floatSize;
  
          float x1 = x + leftExtent * textSize;
          float y1 = y - topExtent * textSize;
          float x2 = x1 + wide * textSize;
          float y2 = y1 + high * textSize;
          
  
          textCharModelImpl(glyph.image,
                            x1, y1, x2, y2,
                        glyph.width, glyph.height);
        }
      } else if (ch != ' ' && ch != 127) {
        println("No glyph found for the " + ch + " (\\u" + PApplet.hex(ch, 4) + ") character");
      }
    }
    
    private boolean imgText = false;
  
  
    protected void textCharModelImpl(PImage glyph,
                                 float x1, float y1, //float z1,
                                 float x2, float y2, //float z2,
                                 int u2, int v2) {
      imgText = true;
      imageImpl(glyph, x1, y1, x2, y2, 0, 0, u2, v2); 
      imgText = false;
    }
    
    protected void imageImpl(PImage img,
                         float x1, float y1, float x2, float y2,
                         int u1, int v1, int u2, int v2) {
      img.loadPixels();
      
      x1 *= scaleX;
      y1 *= scaleY;
      x2 *= scaleX;
      y2 *= scaleY;
      
      float r = red(fillColor)/255f;
      float g = green(fillColor)/255f;
      float b = blue(fillColor)/255f;
      //float a = alpha(fillColor);
      
      int wi = int(canvas.width);
      
                           
      // Assumes app.loadPixels has already been called.
      for (int y = (int)y1; y < (int)y2; y++) {
        for (int x = (int)x1; x < (int)x2; x++) {
          int samplerX = u1+int((((float)(x-x1))/((float)(x2-x1)))*(float)u2);
          int samplerY = v1+int((((float)(y-y1))/((float)(y2-y1)))*(float)v2);
          
          color c = 0;
          if (samplerX >= 0 && samplerX < img.width && samplerY >= 0 && samplerY < img.height)
            c = img.pixels[samplerY*img.width + samplerX];
          
          if (x >= 0 && x < canvas.width && y >= 0 && y < canvas.height) {
            if (imgText) {
              if (blue(c) > 0) {
                canvas.pixels[y * wi + x] = color(blue(c)*r, blue(c)*g, blue(c)*b, 255);
              }
            }
            else {
              if (alpha(c) > 0) {
                canvas.pixels[y * wi + x] = color(red(c)*r, green(c)*g, blue(c)*b, 255);
              }
            }
          }
        }
      }
    }
    
    public void scale(float x) {
      scaleX = x;
      scaleY = x;
    }
    
    public void scale(float x, float y) {
      scaleX = x;
      scaleY = y;
    }
    
    public void image(PImage img, float a, float b) {
      if (img.width == -1 || img.height == -1) return;
  
      imageImpl(img,
                a, b, a+img.width, b+img.height,
                0, 0, img.width, img.height);
    }
  
    public void image(PImage img, float a, float b, float c, float d) {
      image(img, a, b, c, d, 0, 0, img.width, img.height);
    }
    
    public void image(PImage img,
                  float a, float b, float c, float d,
                  int u1, int v1, int u2, int v2) {
  // Starting in release 0144, image errors are simply ignored.
  // loadImageAsync() sets width and height to -1 when loading fails.
  if (img.width == -1 || img.height == -1) return;

  if (c < 0) {  // reset a negative width
    a += c; c = -c;
  }
  if (d < 0) {  // reset a negative height
    b += d; d = -d;
  }

  imageImpl(img,
            a, b, a + c, b + d,
            u1, v1, u2, v2);

}
  
  
  
    protected void textSentenceBreak(int start, int stop) {
      if (textBreakCount == textBreakStart.length) {
        textBreakStart = PApplet.expand(textBreakStart);
        textBreakStop = PApplet.expand(textBreakStop);
      }
      textBreakStart[textBreakCount] = start;
      textBreakStop[textBreakCount] = stop;
      textBreakCount++;
    }
    
    protected boolean textSentence(char[] buffer, int start, int stop,
                                   float boxWidth) {
      float runningX = 0;
  
      // Keep track of this separately from index, since we'll need to back up
      // from index when breaking words that are too long to fit.
      int lineStart = start;
      int wordStart = start;
      int index = start;
      while (index <= stop) {
        // boundary of a word or end of this sentence
        if ((buffer[index] == ' ') || (index == stop)) {
  //        System.out.println((index == stop) + " " + wordStart + " " + index);
          float wordWidth = 0;
          if (index > wordStart) {
            // we have a non-empty word, measure it
            wordWidth = textWidthImpl(buffer, wordStart, index);
          }
  
          if (runningX + wordWidth >= boxWidth) {
            if (runningX != 0) {
              // Next word is too big, output the current line and advance
              index = wordStart;
              textSentenceBreak(lineStart, index);
              // Eat whitespace before the first word on the next line.
              while ((index < stop) && (buffer[index] == ' ')) {
                index++;
              }
            } else {  // (runningX == 0)
              // If this is the first word on the line, and its width is greater
              // than the width of the text box, then break the word where at the
              // max width, and send the rest of the word to the next line.
              if (index - wordStart < 25) {
                do {
                  index--;
                  if (index == wordStart) {
                    // Not a single char will fit on this line. screw 'em.
                    return false;
                  }
                  wordWidth = textWidthImpl(buffer, wordStart, index);
                } while (wordWidth > boxWidth);
              } else {
                // This word is more than 25 characters long, might be faster to
                // start from the beginning of the text rather than shaving from
                // the end of it, which is super slow if it's 1000s of letters.
                // https://github.com/processing/processing/issues/211
                int lastIndex = index;
                index = wordStart + 1;
                // walk to the right while things fit
  //              while ((wordWidth = textWidthImpl(buffer, wordStart, index)) < boxWidth) {
                while (textWidthImpl(buffer, wordStart, index) < boxWidth) {
                  index++;
                  if (index > lastIndex) {  // Unreachable?
                    break;
                  }
                }
                index--;
                if (index == wordStart) {
                  return false;  // nothing fits
                }
              }
  
              //textLineImpl(buffer, lineStart, index, x, y);
              textSentenceBreak(lineStart, index);
            }
            lineStart = index;
            wordStart = index;
            runningX = 0;
  
          } else if (index == stop) {
            // last line in the block, time to unload
            //textLineImpl(buffer, lineStart, index, x, y);
            textSentenceBreak(lineStart, index);
  //          y += textLeading;
            index++;
  
          } else {  // this word will fit, just add it to the line
            runningX += wordWidth;
            wordStart = index ;  // move on to the next word including the space before the word
            index++;
          }
        } else {  // not a space or the last character
          index++;  // this is just another letter
        }
      }
  //    return y;
      return true;
    }
    
    
    protected float textWidthImpl(char[] buffer, int start, int stop) {
      float wide = 0;
      for (int i = start; i < stop; i++) {
        // could add kerning here, but it just ain't implemented
        wide += textFont.width(buffer[i]) * textSize;
      }
      return wide;
    }
    
    protected void handleTextSize(float size) {
      textSize = size;
      textLeading = (this.textAscent() + this.textDescent()) * 1.275f;
    }
    
    public void textSize(float size) {
      handleTextSize(size);
    }
    
    public float textAscent() {
      return textFont.ascent() * textSize;
    }
    
    public float textDescent() {
      return textFont.descent() * textSize;
    }
    
    protected void textFontImpl(PFont which, float size) {
      textFont = which;
      handleTextSize(size);
    }
    
    public void textFont(PFont which, float size) {
      textFontImpl(which, size);
    }
    
    public void textAlign(int alignX, int alignY) {
      textAlign = alignX;
      textAlignY = alignY;
    }
    
    public float textWidth(char c) {
      textWidthBuffer[0] = c;
      return textWidthImpl(textWidthBuffer, 0, 1);
    }
}















public class Editor extends Screen {
    private boolean showGUI = false;
    private float upperbarExpand = 0;
    protected SpriteSystem gui;
    private SpriteSystem placeableSprites;
    protected HashMap<String, Placeable> placeableset;
    private ArrayList<String> imagesInEntry;  // This is so that we can know what to remove when we exit this screen.
    private Placeable editingPlaceable = null;
    private EditorCapture camera;
    private String entryName;
    private String entryPath;
    private String entryDir;
    private color selectedColor = color(255, 255, 255);
    private float selectedFontSize = 30f;
    private color clipboardColor = color(255, 255, 255);
    private float clipboardFontSize = 30f;
    private PFont clipboardFontStyle = engine.DEFAULT_FONT;
    private TextPlaceable entryNameText;
    private boolean cameraMode = false;
    private boolean autoScaleDown = false;
    private boolean changesMade = false;
    private int upperBarDrop = INITIALISE_DROP_ANIMATION;
    private boolean useSoftwareRendering = false;
    private SoftwareRenderer softwareRender;
    private PImage softwareRenderCanvas;
    private float canvasScale;
    private JSONArray loadedJsonArray;
    protected boolean readOnly = false;
    private boolean forcedScrollBugFix = false;
    public float scrollOffset;
    
    // X goes unused for now but could be useful later.
    private float extentX = 0.;
    private float extentY = 0.;
    private float scrollLimitY = 0.;
    private float prevMouseY = 0.;
    private float scrollVelocity = 0.;
    
    public static final int INITIALISE_DROP_ANIMATION = 0;
    public static final int CAMERA_ON_ANIMATION = 1;
    public static final int CAMERA_OFF_ANIMATION = 2;
    
    final String RENAMEABLE_NAME         = "title";                // The name of the sprite object which is used to rename entries
    final float  EXPAND_HITBOX           = 10;                     // For the (unused) ERS system to slightly increase the erase area to prevent glitches
    final String DEFAULT_FONT            = "Typewriter";           // Default font for entries
    final float  STANDARD_FONT_SIZE      = 64;                     // You get the idea
          float  DEFAULT_FONT_SIZE       = 30;
    final color  DEFAULT_FONT_COLOR      = color(255, 255, 255);
    final float  MIN_FONT_SIZE           = 8.;
    final float  UPPER_BAR_DROP_WEIGHT   = 150;                    
    final int    SCALE_DOWN_SIZE         = 512;
    final float  SCROLL_LIMIT            = 600.;
    
    final color BACKGROUND_COLOR = 0xFF0f0f0e;
    
    // Camera errors
    public final static int ERR_UNKNOWN = 0;
    public final static int ERR_NO_CAMERA_DEVICES = 1;
    public final static int ERR_FAILED_TO_SWITCH = 2;
    public final static int ERR_UNSUPPORTED_SYSTEM = 3;


    

    
    
    private void textOptions() {
      String[] labels = new String[2];
      Runnable[] actions = new Runnable[2];
      
      labels[0] = "Copy";
      actions[0] = new Runnable() {public void run() {
          
          copy();
          
      }};
      
      
      labels[1] = "Delete";
      actions[1] = new Runnable() {public void run() {
          
          if (editingPlaceable != null) {
            placeableset.remove(editingPlaceable.id);
            changesMade = true;
          }
          
      }};
      
      
      
      ui.createOptionsMenu(labels, actions);
    }
    
    
    private void imageOptions() {
      
      String[] labels = new String[5];
      Runnable[] actions = new Runnable[5];
      
      labels[0] = "Copy";
      actions[0] = new Runnable() {public void run() {
        
        copy();
        
      }};
      
      labels[1] = "Flip horizontally";
      actions[1] = new Runnable() {public void run() {
        if (editingPlaceable != null && editingPlaceable instanceof ImagePlaceable) {
          ImagePlaceable im = (ImagePlaceable)editingPlaceable;
          PImage img = display.getImg(im.imageName);
          
          PImage newImg = app.createImage(img.width, img.height, ARGB);
          img.loadPixels();
          newImg.loadPixels();
          for (int y = 0; y < img.height; y++) {
            for (int x = 0; x < img.width; x++) {
              newImg.pixels[y * img.width + x] = img.pixels[y * img.width + (img.width-x-1)];
            }
          }
          
          display.systemImages.put(im.imageName, newImg);
        }
        
      }};
      
      labels[2] = "Flip vertically";
      actions[2] = new Runnable() {public void run() {
        if (editingPlaceable != null && editingPlaceable instanceof ImagePlaceable) {
          ImagePlaceable im = (ImagePlaceable)editingPlaceable;
          PImage img = display.getImg(im.imageName);
          
          PImage newImg = app.createImage(img.width, img.height, ARGB);
          img.loadPixels();
          newImg.loadPixels();
          for (int y = 0; y < img.height; y++) {
            for (int x = 0; x < img.width; x++) {
              newImg.pixels[y * img.width + x] = img.pixels[(img.height-y-1) * img.width + x];
            }
          }
          newImg.updatePixels();
          
          display.systemImages.put(im.imageName, newImg);
        }
        
      }};
      
      
      labels[3] = "Save";
      actions[3] = new Runnable() {public void run() {
          
        if (editingPlaceable != null && editingPlaceable instanceof ImagePlaceable) {
          ImagePlaceable im = (ImagePlaceable)editingPlaceable;
          file.selectOutput("Save image...", im.getImage());
        }
          
      }};
      
      labels[4] = "Delete";
      actions[4] = new Runnable() {public void run() {
          
        if (editingPlaceable != null) {
          placeableset.remove(editingPlaceable.id);
          changesMade = true;
        }
          
      }};
      
      ui.createOptionsMenu(labels, actions);
    }
    
    
    private void blankOptions() {
      String[] labels = new String[6];
      Runnable[] actions = new Runnable[6];
      
      labels[0] = "New input field";
      actions[0] = new Runnable() {public void run() {
        insertText("Input field", engine.mouseX(), engine.mouseY()-20, TYPE_INPUT_FIELD);
      }};
      
      
      labels[1] = "New boolean field";
      actions[1] = new Runnable() {public void run() {
        insertText("Boolean field", engine.mouseX(), engine.mouseY()-20, TYPE_BOOLEAN_FIELD);
      }};
      
      labels[2] = "New slider field";
      actions[2] = new Runnable() {public void run() {
        insertText("Slider field", engine.mouseX(), engine.mouseY()-20, TYPE_SLIDER_FIELD);
      }};
      
      
      labels[3] = "New int slider field";
      actions[3] = new Runnable() {public void run() {
        insertText("Int slider field", engine.mouseX(), engine.mouseY()-20, TYPE_SLIDERINT_FIELD);
      }};
      
      labels[4] = "New options menu";
      actions[4] = new Runnable() {public void run() {
        insertText("Options menu field", engine.mouseX(), engine.mouseY()-20, TYPE_OPTIONS_FIELD);
      }};
      
      labels[5] = "New button";
      actions[5] = new Runnable() {public void run() {
        insertText("Button", engine.mouseX(), engine.mouseY()-20, TYPE_BUTTON);
      }};
      
      // We only want to display these if we're actually editing a system timewayentry.
      // Wouldn't make sense to display these UI fields for normal entries, as sad as it
      // is not to expose them during normal use.
      if (entryPath.contains(engine.APPPATH+"engine/entryscreens")) {
        ui.createOptionsMenu(labels, actions);
      }
    }
    
    
    private String generateRandomID() {
      String id = nf(random(0, 99999999), 8, 0);
      while (placeableset.containsKey(id)) {
        id = nf(random(0, 99999999), 8, 0);
      }
      return id;
    }
    
    protected Placeable get(String name) {
      if (!placeableset.containsKey(name)) {
        console.warn("Setting "+name+" not found.");
        return new Placeable("null");
      }
      return placeableset.get(name);
    }


    public class Placeable {
        public SpriteSystem.Sprite sprite;
        public String id;
        public boolean visible = true;

        //public Placeable() {
        //    String name = generateRandomID();
        //    placeableSprites.placeable(name);
        //    sprite = placeableSprites.getSprite(name);
            
        //    if (!placeableset.containsValue(this)) {
        //        placeableset.put(name, this);
        //    }
        //}
        
        public Placeable(String id) {
            this.id = id;
            placeableSprites.placeable(id);
            sprite = placeableSprites.getSprite(id);
            
            if (!placeableset.containsValue(this)) {
                placeableset.put(id, this);
            }
        }
        
        
        protected boolean placeableSelected() {
          if (input.mouseY() < myUpperBarWeight) return false;
          return (sprite.mouseWithinHitbox() && placeableSprites.selectedSprite == sprite && input.primaryDown && !input.mouseMoved);
        }

        protected boolean placeableSelectedSecondary() {
          return (sprite.mouseWithinHitbox() && placeableSprites.selectedSprite == sprite && input.secondaryDown && !input.mouseMoved);
        }
        
        
        @SuppressWarnings("unused")
        public void save(JSONObject json) {
            console.bugWarn("Missing code! Couldn't save unknown placeable: "+this.toString());
        }

        
        // Just a placeholder display for the base class.
        // You shouldn't use super.display() for inherited classes.
        public void display() {
          if (!useSoftwareRendering) {
            app.fill(255, 0, 0);
            app.rect(sprite.xpos, sprite.ypos, sprite.wi, sprite.hi);
          }
        }

        public void update() {
            sprite.offmove(0, scrollOffset);
            if (visible) {
              display();
            }
            placeableSprites.placeable(sprite);
        }
    }


    public class TextPlaceable extends Placeable {
        public String text = "";
        public float fontSize = DEFAULT_FONT_SIZE;
        public PFont fontStyle;
        public color textColor = DEFAULT_FONT_COLOR;
        public float lineSpacing = 8;
        int newlines = 0;

        public TextPlaceable(String name) {
            super(name);
            sprite.allowResizing = false;
            sprite.setImg("nothing");
            fontStyle = display.getFont(DEFAULT_FONT);
            selectedFontSize = this.fontSize;
        }

        protected boolean editing() {
            if (editingPlaceable == this) {
              changesMade = true;
            }
            return editingPlaceable == this;
        }

        protected int countNewlines(String t) {
            int count = 0;
            for (int i = 0; i < t.length(); i++) {
                if (t.charAt(i) == '\n') {
                    count++;
                }
            }
            newlines = count;
            return count;
        }

        public void display() {
          
          String displayText = "";
          if (editing()) {
              displayText = input.keyboardMessageDisplay(text);
          }
          else {
              displayText = text;
          }
          
          if (useSoftwareRendering) {
            softwareRender.scale(canvasScale);
            softwareRender.fill(textColor);
            softwareRender.textAlign(LEFT, TOP);
            softwareRender.textFont(fontStyle, fontSize);
            softwareRender.textLeading(fontSize+lineSpacing);
            softwareRender.text(displayText, sprite.xpos, sprite.ypos-app.textDescent()+EXPAND_HITBOX/2+10);
          }
          else {
            app.pushMatrix();
            app.scale(canvasScale);
            app.fill(textColor);
            app.textAlign(LEFT, TOP);
            app.textFont(fontStyle, fontSize);
            app.textLeading(fontSize+lineSpacing);
            app.text(displayText, sprite.xpos, sprite.ypos-app.textDescent()+EXPAND_HITBOX/2+10);
            app.popMatrix();
          }
        }
        
        public void updateDimensions() {
          placeableSprites.hackSpriteDimensions(sprite, int(app.textWidth(text)), int((app.textAscent()+app.textDescent()+lineSpacing)*(countNewlines(text)+1) + EXPAND_HITBOX));
        }
        
        public void save(JSONObject obj) {
          this.sprite.offmove(0,0);
          obj.setString("ID", this.sprite.name);
          obj.setInt("type", TYPE_TEXT);
          obj.setInt("x", int(this.sprite.getX()));
          obj.setInt("y", int(this.sprite.getY()));
          obj.setFloat("size", this.fontSize);
          obj.setString("text", this.text);
          obj.setString("color_hex", hex(this.textColor));
        }

        public void update() {
          
            //fontSize = (float)sprite.getWidth()/40.;
            app.textFont(fontStyle, fontSize);
            app.textLeading(fontSize+lineSpacing);

            // The famous hitbox hack where we set the hitbox to the text size.
            // For width we simply check the textWidth with the handy function.
            // For text height we account for the ascent/descent thing, expand hitbox to make it slightly larger
            // and times it by the number of newlines.
            
            if (sprite.isSelected()) {
              updateDimensions();
            }
            
            if (editing()) {
                input.addNewlineWhenEnterPressed = true;
                // Oh my god if this bug fix doesn't work I'm gonna lose it
                // DO NOT allow the command prompt to appear by pressing '/' and make the current text we're writing disappear
                // while writing text
                engine.allowShowCommandPrompt = false;
                text = input.getTyping(text, true);
            }
            
            if (placeableSelected() || placeableSelectedSecondary()) {
                engine.allowShowCommandPrompt = false;
                editingPlaceable = this;
                input.cursorX = text.length();
                selectedFontSize = this.fontSize;
            }
                // Mini menu for text
            if (placeableSelectedSecondary()) {
              textOptions();
            }
            super.update();
        }

    }
    

    public class ImagePlaceable extends Placeable {
        // You'd think we'd assign a PImage object to each ImagePlaceable.
        // However, because of the Sprite implementation, that's not how things
        // are done unfortunately.
        // Instead, we must add the image to the engine's image hashmap and then
        // give it a name that the sprite will use to find the correct image.
        // Stupid workaround but it's the least complicated way of doing things lol.
        // We must also remember to remove the image from the engine when we leave
        // this screen otherwise we'll technically create a memory leak.
        public String imageName;

        public ImagePlaceable(String name) {
            super(name);
            sprite.allowResizing = true;
        }
        
        public ImagePlaceable(String id, PImage img) {
            super(id);
            sprite.allowResizing = true;
            
            // Ok yes I see the flaws in this, I'll figure out a more robust system later maybe.
            int uniqueIdentifier = int(random(0, 2147483646));
            String name = "cache-"+str(uniqueIdentifier);
            this.imageName = name;
            
            // I feel so bad using systemImages because it was only ever intended
            // for images loaded by the engine only >.<
            display.systemImages.put(name, img);
            imagesInEntry.add(name);
        }
        
        public void setImage(PImage img, String imgName) {
          this.imageName = imgName;
          display.systemImages.put(imgName, img);
          //app.image(img,0,0);
          imagesInEntry.add(imgName);
        }
        
        public PImage getImage() {
          return display.getImg(this.imageName);
        }
        
        public void display() {
          
        }
        
        
        public void save(JSONObject obj) {
          // First, we need the png image data.
          PImage image = display.systemImages.get(this.sprite.imgName);
          if (image == null) {
            console.bugWarn("Trying to save image placeable, and image doesn't exist in memory?? Possible bug??");
            return;
          }
          
          // No multithreading please!
          // And no shrinking please!
          engine.setCachingShrink(0,0);
          
          
          String cachePath = engine.saveCacheImage(entryPath+"_"+str(numImages++), image);
          
          byte[] cacheBytes = loadBytes(cachePath);
          
          
          // NullPointerException
          String encodedPng = new String(Base64.getEncoder().encode(cacheBytes));
          
          this.sprite.offmove(0,0);
          
          obj.setString("ID", this.sprite.name);
          obj.setInt("type", TYPE_IMAGE);
          obj.setInt("x", int(this.sprite.getX()));
          obj.setInt("y", int(this.sprite.getY()));
          obj.setInt("wi", int(this.sprite.wi));
          obj.setInt("hi", int(this.sprite.hi));
          obj.setString("imgName", this.sprite.imgName);
          obj.setString("png", encodedPng);
          
        }
        
        public void update() {
            sprite.offmove(0, scrollOffset);
            if (placeableSelectedSecondary()) {
              editingPlaceable = this;
              imageOptions();
            }
            if (placeableSelected()) {
                editingPlaceable = this;
            }
            
            if (useSoftwareRendering) {
              PImage img = display.systemImages.get(imageName);
              if (img == null) return;
              
              softwareRender.scale(canvasScale);
              softwareRender.fill(255, 255, 255, 255);
              softwareRender.image(img, sprite.getX(), sprite.getY(), sprite.getWidth(), sprite.getHeight());
            }
            else {
              app.pushMatrix();
              app.scale(canvasScale);
              placeableSprites.sprite(sprite.getName(), imageName);
              app.popMatrix();
            }
        }
    }
    
    public class InputFieldPlaceable extends TextPlaceable {
      
        public InputFieldPlaceable(String name) {
          super(name);
        }
      
        protected final float MIN_FIELD_VISIBLE_SIZE = 150f;
        public String inputText = "";
      
        public void display() {
            app.pushMatrix();
            app.scale(canvasScale);
            app.textAlign(LEFT, TOP);
            app.textFont(fontStyle, fontSize);
            app.textLeading(fontSize+lineSpacing);

            String displayText = "";
            if (editing()) {
              displayText = input.keyboardMessageDisplay(text);
            }
            else if (readOnly && modifyingField == this) {
              inputText = input.getTyping(inputText, false);
              displayText = text+" "+input.keyboardMessageDisplay(inputText);
            }
            else {
                displayText = text+" "+inputText;
            }
            float x = sprite.xpos;
            float y = sprite.ypos-app.textDescent()+EXPAND_HITBOX/2+10;
            app.stroke(255f);
            app.strokeWeight(1f);
            app.fill(100, 60);
            app.rect(x+app.textWidth(text+" ")-10f, y-EXPAND_HITBOX, PApplet.max(app.textWidth(inputText)+30f, MIN_FIELD_VISIBLE_SIZE)+EXPAND_HITBOX*2f+10f, sprite.getHeight());
            app.fill(textColor);
            app.text(displayText, x, y);
            app.popMatrix();
        }
        
        public void updateDimensions() {
          float textww = app.textWidth(text+" ");
          float inputfield = app.textWidth(inputText+" ");
          float ww = PApplet.max(textww+inputfield, textww+MIN_FIELD_VISIBLE_SIZE);
          placeableSprites.hackSpriteDimensions(sprite, int(ww), int((app.textAscent()+app.textDescent()+lineSpacing)*(countNewlines(text)+1) + EXPAND_HITBOX));
        }
        
        // Need a custom click method since we can't have selected placeables in read-only mode.
        private boolean myClick() {
          return sprite.mouseWithinHitbox() && input.primaryOnce && !input.mouseMoved;
        }
        
        public void update() {
          super.update();
          
          // Select for text modifying and 
          if (myClick() && readOnly) {
              engine.allowShowCommandPrompt = false;
              modifyingField = this;
              input.cursorX = inputText.length();
          }
          
          if (modifyingField == this && readOnly) {
            input.addNewlineWhenEnterPressed = false;
          }
          updateDimensions();
        }
        
        public void save(JSONObject obj) {
          super.save(obj);
          obj.setInt("type", TYPE_INPUT_FIELD);
        }
    }
    
    
    
    public class BooleanFieldPlaceable extends TextPlaceable {
      
        public BooleanFieldPlaceable(String name) {
          super(name);
        }
      
        public boolean state = false;
        public float animationInverted = 0f;
      
        public void display() {
            app.pushMatrix();
            app.scale(canvasScale);
            app.textAlign(LEFT, TOP);
            app.textFont(fontStyle, fontSize);
            app.textLeading(fontSize+lineSpacing);

            String displayText = "";
            if (editing()) {
                displayText = input.keyboardMessageDisplay(text);
            }
            else {
                displayText = text;
            }
            float textx = sprite.xpos;
            float texty = sprite.ypos-app.textDescent()+EXPAND_HITBOX/2+10;
            float x = textx+app.textWidth(text)+20f;
            float y = texty-EXPAND_HITBOX;
            float wi = sprite.getHeight()*1.8f;
            float hi = sprite.getHeight();
            
            if (ui.buttonImg("nothing", x, y, wi, hi)) {
              sound.playSound("switch_interact");
              // Switch state and init switch animation.
              state = !state;
              animationInverted = 1f;
            }
            
            // Mathy stuff for rendering switch and knob
            final float KNOB_PADDING = 5f;
            final color COLOR_OFF = color(50f, 50f, 50f);
            final color COLOR_ON  = color(100f, 100f, 255f);
            
            float knobwi = hi-KNOB_PADDING*2f;
            float knobx = x+KNOB_PADDING;
            
            float animation = 1f-animationInverted;
            
            if (state == true) {
              knobx += (wi-knobwi-KNOB_PADDING*2f)*animation;
              app.fill(app.lerpColor(COLOR_OFF, COLOR_ON, animation));
            }
            else {
              knobx += (wi-knobwi-KNOB_PADDING*2f)*(1f-animation);
              app.fill(app.lerpColor(COLOR_ON, COLOR_OFF, animation));
            }
            
            // Draw switch
            app.stroke(255f);
            app.strokeWeight(2f);
            app.rect(x, y, wi, hi);
            
            // Knob
            app.noStroke();
            app.fill(255f); 
            app.rect(knobx, y+KNOB_PADDING, knobwi, knobwi);
            
            // Text
            app.fill(textColor);
            app.text(displayText, textx, texty);
            app.popMatrix();
            
            animationInverted *= PApplet.pow(0.85f, display.getDelta());
            updateDimensions();
        }
        
        //public void updateDimensions() {
        //  float textww = app.textWidth(text+" ");
        //  float inputfield = app.textWidth(inputText+" ");
        //  float ww = PApplet.max(textww+inputfield, textww+MIN_FIELD_VISIBLE_SIZE);
        //  placeableSprites.hackSpriteDimensions(sprite, int(ww), int((app.textAscent()+app.textDescent()+lineSpacing)*(countNewlines(text)+1) + EXPAND_HITBOX));
        //}
        
        //public void update() {
        //  super.update();
          
        //  // Select for text modifying and 
        //  if (myClick() && readOnly) {
        //      engine.allowShowCommandPrompt = false;
        //      modifyingField = this;
        //      input.keyboardMessage = inputText;
        //      input.cursorX = input.keyboardMessage.length();
        //  }
          
        //  if (modifyingField == this && readOnly) {
        //    input.addNewlineWhenEnterPressed = false;
        //    inputText = input.keyboardMessage;
        //  }
        //  updateDimensions();
        //}
        
        public void save(JSONObject obj) {
          super.save(obj);
          obj.setInt("type", TYPE_BOOLEAN_FIELD);
        }
    }
    
    
    private boolean movingSlider = false;
    
    public class SliderFieldPlaceable extends TextPlaceable {
      
        public SliderFieldPlaceable(String name) {
          super(name);
        }
        
        // MUST be called on creation
        public void createSlider(float min, float max, float init) {
          slider = ui.new CustomSlider("", min, max, init);
        }
        
        
        protected TWEngine.UIModule.CustomSlider slider;
        
        public float getVal() {
          if (slider == null) return 0f;
          return slider.valFloat;
        }
        
        public void setVal(float x) {
          if (slider == null) return;
          slider.valFloat = x;
        }
        
        public boolean mouseDown() {
          return slider.mouseDown();
        }
        
      
        public void display() {
            //app.pushMatrix();
            //app.scale(canvasScale);
            app.textAlign(LEFT, TOP);
            app.textFont(fontStyle, fontSize);
            app.textLeading(fontSize+lineSpacing);

            String displayText = "";
            if (editing()) {
                displayText = input.keyboardMessageDisplay(text);
            }
            else {
                displayText = text;
            }
            
            float textx = sprite.xpos;
            float texty = sprite.ypos-app.textDescent()+EXPAND_HITBOX/2+10;
            
            if (!useSoftwareRendering) {
              slider.label = displayText;
              slider.wi = 750f;
              slider.display(textx, texty);
            }
            
            if (!movingSlider && slider.inBox() && input.primaryOnce) {
              movingSlider = true;
            }
            
            //app.popMatrix();
            updateDimensions();
        }
        
        public void setMinLabel(String label) {
          slider.setWhenMin(label);
        }
        
        public void setMaxLabel(String label) {
          slider.setWhenMax(label);
        }
        
        public void save(JSONObject obj) {
          super.save(obj);
          obj.setFloat("min_value", slider.min);
          obj.setFloat("max_value", slider.max);
          obj.setInt("type", TYPE_SLIDER_FIELD);
        }
    }
    
    public class SliderIntFieldPlaceable extends SliderFieldPlaceable {
      
        public SliderIntFieldPlaceable(String name) {
          super(name);
        }
        
        public int getValInt() {
          if (slider == null) return 0;
          return slider.valInt;
        }
        
        public void setVal(int x) {
          if (slider == null) return;
          slider.setVal(x);
        }
        
        // MUST be called on creation
        public void createSlider(int min, int max, int init) {
          slider = ui.new CustomSliderInt("", min, max, init);
        }
        
        public void save(JSONObject obj) {
          super.save(obj);
          // Should override the float settings from the inherited method.
          obj.setInt("min_value", (int)slider.min);
          obj.setInt("max_value", (int)slider.max);
          obj.setInt("type", TYPE_SLIDERINT_FIELD);
        }
    }
    
    
    public class OptionsFieldPlaceable extends TextPlaceable {
      
        public OptionsFieldPlaceable(String name) {
          super(name);
        }
        
        public String[] options;
        public String selectedOption = "Sample option";
        
        private final float BOX_X_POS  = 400f;
        private final float BOX_X_SIZE = 520f;
        
        public void createOptions(JSONArray array) {
          options = new String[array.size()];
          for (int i = 0; i < array.size(); i++) {
            options[i] = array.getString(i, "---");
          }
        }
        
        public void createOptions(String... array) {
          options = array;
        }
      
        public void display() {
            app.pushMatrix();
            app.scale(canvasScale);
            app.textAlign(LEFT, TOP);
            app.textFont(fontStyle, fontSize);
            app.textLeading(fontSize+lineSpacing);

            String displayText = "";
            if (editing()) {
                displayText = input.keyboardMessageDisplay(text);
            }
            else {
                displayText = text;
            }
            float x = sprite.xpos;
            float y = sprite.ypos-app.textDescent()+EXPAND_HITBOX/2+10;
            app.stroke(255f);
            app.strokeWeight(1f);
            app.fill(100, 60);
            app.rect(x+BOX_X_POS, y-EXPAND_HITBOX, BOX_X_SIZE, sprite.getHeight());
            display.img("down_triangle_64", x+BOX_X_POS+BOX_X_SIZE-69f, y, sprite.getHeight()-20f, sprite.getHeight()-20f);
            
            app.fill(textColor);
            // Label text
            app.text(displayText, x, y);
            // Selected option text
            app.fill(255f);
            
            // Quick visual fix (vrey bad coding but im lazy)
            app.text(selectedOption.length() > 28 ? selectedOption.substring(0, 25)+"..." : selectedOption, x+BOX_X_POS+10f, y);
            app.popMatrix();
        }
        
        //public void updateDimensions() {
        //  float textww = app.textWidth(text+" ");
        //  float inputfield = app.textWidth(inputText+" ");
        //  float ww = PApplet.max(textww+inputfield, textww+MIN_FIELD_VISIBLE_SIZE);
        //  placeableSprites.hackSpriteDimensions(sprite, int(ww), int((app.textAscent()+app.textDescent()+lineSpacing)*(countNewlines(text)+1) + EXPAND_HITBOX));
        //}
        
        // Need a custom click method since we can't have selected placeables in read-only mode.
        private boolean myClick() {
          float x = sprite.xpos;
          float y = sprite.ypos-app.textDescent()+EXPAND_HITBOX/2+10;
          return ui.buttonImg("nothing", x+BOX_X_POS, y-EXPAND_HITBOX, BOX_X_SIZE, sprite.getHeight()) && input.primaryOnce && !input.mouseMoved;
        }
        
        public void update() {
          super.update();
          
          // Select for text modifying and 
          if (myClick() && readOnly) {
            Runnable[] actions = new Runnable[options.length];
            
            for (int i = 0; i < options.length; i++) {
              final String finalOption = options[i];
              actions[i] = new Runnable() {public void run() {
                  selectedOption = finalOption;
              }};
            }
            
            ui.createOptionsMenu(options, actions);
          }
          
          updateDimensions();
        }
        
        public void save(JSONObject obj) {
          super.save(obj);
          obj.setInt("type", TYPE_OPTIONS_FIELD);
          JSONArray array = new JSONArray();
          
          for (int i = 0; i < options.length; i++) {
            array.setString(i, options[i]);
          }
          obj.setJSONArray("options", array);
        }
    }
    
    
    public class ButtonPlaceable extends TextPlaceable {
      
        public ButtonPlaceable(String name) {
          super(name);
        }
        
        public color rgb = 0xFF614d7d;
        public color rgbHover = 0xFF8d70b5;
        public boolean clicked = false;
      
        public void display() {
            app.pushMatrix();
            app.scale(canvasScale);
            app.textAlign(LEFT, TOP);
            app.textFont(fontStyle, fontSize);
            app.textLeading(fontSize+lineSpacing);

            String displayText = "";
            if (editing()) {
                displayText = input.keyboardMessageDisplay(text);
            }
            else {
                displayText = text;
            }
            
            float PADDING = 5f;
            float textx = sprite.xpos;
            float texty = sprite.ypos-app.textDescent()+EXPAND_HITBOX/2+10;
            float x = textx-10f-PADDING;
            float y = texty-EXPAND_HITBOX-PADDING;
            float wi = sprite.getWidth()+20f+PADDING*2f;
            float hi = sprite.getHeight()+PADDING*2f;
            
            
            app.stroke(255f);
            app.strokeWeight(1f);
            if (ui.mouseInArea(x, y, wi, hi)) {
              app.fill(rgbHover); 
            }
            else {
              app.fill(rgb); 
            }
            
            app.rect(x, y, wi, hi);
            clicked = readOnly && ui.buttonImg("nothing", x, y, wi, hi);
            
            // Text
            app.fill(textColor);
            app.text(displayText, textx, texty);
            app.popMatrix();
            
            
            updateDimensions();
        }
        
        public void save(JSONObject obj) {
          super.save(obj);
          obj.setInt("type", TYPE_BUTTON);
          obj.setString("button_color", hex(rgb));
          obj.setString("button_color_hover", hex(rgbHover));
        }
    }
    
    
    
    
    //**************************************************************************************
    //**********************************EDITOR SCREEN CODE**********************************
    //**************************************************************************************  
    // Pls don't use this constructor in your code if you are sane.
    public Editor(TWEngine engine, String entryPath, boolean full, boolean loadMultithreaded) {
        super(engine);
        this.entryPath = entryPath;
        if (full) {
          gui = new SpriteSystem(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/editor/");
          gui.repositionSpritesToScale();
          gui.interactable = false;
          
          // Bug fix: run once so that text element in GUI being at pos 0,0 isn't shown.
          runGUI();
          
          if (isWindows()) {
            camera = new DCapture(engine);
          }
          else if (isAndroid()) {
            camera = new PCapture(engine);
          }
          // In android we use our own camera.
        
        }
        
        if (isAndroid()) {
          DEFAULT_FONT_SIZE = 50;
        }
        
        placeableSprites = new SpriteSystem(engine);
        placeableSprites.allowSelectOffContentPane = false;
        imagesInEntry = new ArrayList<String>();
        placeableset = new HashMap<String, Placeable>();
        
        // Get the path without the file name
        int lindex = entryPath.lastIndexOf('/');
        if (lindex == -1) {
          lindex = entryPath.lastIndexOf('\\');
          if (lindex == -1) console.bugWarn("Could not find entry's dir, possible bug?");
        }
        if (lindex != -1) {
          this.entryDir = entryPath.substring(0, lindex+1);
          this.entryName = entryPath.substring(lindex+1, entryPath.lastIndexOf('.'));
        }

        autoScaleDown = settings.getBoolean("auto_scale_down", false);
        scrollOffset = 0.;
        
        if (!full) {
          softwareRenderCanvas = app.createImage(480, 270, ARGB);
          softwareRender = new SoftwareRenderer(softwareRenderCanvas);
          canvasScale = 480f/(WIDTH);
          useSoftwareRendering = true;
          forcedScrollBugFix = true;
        }
        else {
          canvasScale = app.width/(WIDTH*display.getScale());
        }

        myLowerBarColor   = 0xFF37353A;
        myUpperBarColor   = myLowerBarColor;
        myBackgroundColor = BACKGROUND_COLOR;
        //myBackgroundColor = color(255,0,0);
        
        if (loadMultithreaded) 
          readEntryJSONInSeperateThread();
        else {
          readEntryJSON();
          loading = false;
        }
    }
    
    public Editor(TWEngine e, String entryPath) {
      this(e, entryPath, true, true);
    }
    
    public void beginSoftwareRendering() {
      if (useSoftwareRendering) {
        softwareRender.beginDraw();
        softwareRender.clear();
      }
      else {
        console.bugWarn("beginSoftwareRendering(): useSoftwareRendering is false.");
      }
    }
    
    public void bug() {
      softwareRenderCanvas.loadPixels();
    }
    
    public void endSoftwareDraw() {
      if (useSoftwareRendering) {
        softwareRender.endDraw();
      }
      else {
        console.bugWarn("endSoftwareDraw(): useSoftwareRendering is false.");
      }
      
    }
    
    public PImage getSoftwareRenderedCanvas() {
      if (useSoftwareRendering) {
        return softwareRenderCanvas;
      }
      else {
        console.bugWarn("getSoftwareRenderedCanvas(): useSoftwareRendering is false.");
        return display.getImg("white");
      }
    }

    //*****************************************************************
    //***********************PLACEABLE TYPES***************************
    //*****************************************************************
    public final int TYPE_UNKNOWN         = 0;
    public final int TYPE_TEXT            = 1;
    public final int TYPE_IMAGE           = 2;
    public final int TYPE_INPUT_FIELD     = 3;
    public final int TYPE_BOOLEAN_FIELD   = 4;
    public final int TYPE_SLIDER_FIELD    = 5;
    public final int TYPE_SLIDERINT_FIELD = 6;
    public final int TYPE_OPTIONS_FIELD   = 7;
    public final int TYPE_BUTTON          = 8;

    //*****************************************************************
    //**************************SAVE PAGE******************************
    //*****************************************************************
    public void saveEntryJSON() {
      // Only save if any changes were made.
      if (changesMade) {
        numImages = 0;
        //JSONObject json = new JSONObject();
        JSONArray array = new JSONArray();
        for (Placeable p : placeableset.values()) {
          // Lil optimisation
            if (p instanceof TextPlaceable) {
              if (((TextPlaceable)p).text.length() == 0) {
                continue;
              }
            }
          
            JSONObject obj = new JSONObject();
            p.save(obj);
            array.append(obj);
        }
        
        
        engine.app.saveJSONArray(array, entryPath);
        
        sound.playSound("chime");
      }
    }
    
    public int numImages = 0;
    
    
    // Util json ancient functions moved from Engine
    public int getJSONArrayInt(int index, String property, int defaultValue) {
      if (loadedJsonArray == null) {
        console.bugWarn("Cannot get property, entry not opened.");
        return defaultValue;
      }
      if (index > loadedJsonArray.size()) {
        console.bugWarn("No more elements.");
        return defaultValue;
      }
  
      int result = 0;
      try {
        result = loadedJsonArray.getJSONObject(index).getInt(property);
      }
      catch (Exception e) {
        return defaultValue;
      }
  
      return result;
    }
  
    public String getJSONArrayString(int index, String property, String defaultValue) {
      if (loadedJsonArray == null) {
        console.bugWarn("Cannot get property, entry not opened.");
        return defaultValue;
      }
      if (index > loadedJsonArray.size()) {
        console.bugWarn("No more elements.");
        return defaultValue;
      }
  
      String result = "";
      try {
        result = loadedJsonArray.getJSONObject(index).getString(property);
      }
      catch (Exception e) {
        return defaultValue;
      }
      
      if (result == null) {
        return defaultValue;
      }
  
      return result;
    }
  
    public float getJSONArrayFloat(int index, String property, float defaultValue) {
      if (loadedJsonArray == null) {
        console.warn("Cannot get property, entry not opened.");
        return defaultValue;
      }
      if (index > loadedJsonArray.size()) {
        console.warn("No more elements.");
        return defaultValue;
      }
  
      float result = 0;
      try {
        result = loadedJsonArray.getJSONObject(index).getFloat(property);
      }
      catch (Exception e) {
        return defaultValue;
      }
  
      return result;
    }

    //*****************************************************************
    //**************************SAVE PAGE******************************
    //*****************************************************************
    public void readEntryJSON() {
        // check if file exists
        if (!file.exists(entryPath) || file.fileSize(entryPath) <= 2) {
          // If it doesn't exist or is blank, create a new placeable for the name of the entry
            entryNameText = new TextPlaceable(RENAMEABLE_NAME);
            entryNameText.sprite.move(20., UPPER_BAR_DROP_WEIGHT + 80);
            entryNameText.fontSize = 60.;
            entryNameText.textColor = color(255);
            entryNameText.text = entryName;
            entryNameText.updateDimensions();
            
            // Create date
            TextPlaceable date = new TextPlaceable("datetime");
            String d = engine.appendZeros(day(), 2)+"/"+engine.appendZeros(month(), 2)+"/"+year()+"\n"+engine.appendZeros(hour(), 2)+":"+engine.appendZeros(minute(), 2)+":"+engine.appendZeros(second(), 2);
            date.sprite.move(WIDTH-app.textWidth(d)*2., 250);
            date.text = d;
            date.updateDimensions();
            
            // New entry, new default template, ofc we want to save changes!
            changesMade = true;
            
            loading = false;
            return;
        }
        
        // Open json array
        // (This function used to be in the engine code and was ancient)
        try {
          loadedJsonArray = app.loadJSONArray(entryPath);
        }
        catch (RuntimeException e) {
          console.warn("Failed to open JSON file, there was an error: "+e.getMessage());
          return;
        }
        // If the file doesn't exist
        if (loadedJsonArray == null) {
          console.warn("What. The file doesn't exist.");
          return;
        }
        
        for (int i = 0; i < loadedJsonArray.size(); i++) {
            int type = getJSONArrayInt(i, "type", 0);

            switch (type) {
                case TYPE_UNKNOWN:
                    console.warn("Corrupted element, skipping.");
                break;
                case TYPE_TEXT: 
                    TextPlaceable t = readTextPlaceable(i);
                    // Title text element should always be 000
                    if (t.sprite.name.equals(RENAMEABLE_NAME)) entryNameText = t;
                break;
                case TYPE_IMAGE: 
                    readImagePlaceable(i);
                break;
                case TYPE_INPUT_FIELD:
                    readInputFieldPlaceable(i);
                break;
                case TYPE_BOOLEAN_FIELD:
                    readBooleanFieldPlaceable(i);
                break;
                case TYPE_SLIDER_FIELD:
                    readSliderFieldPlaceable(i);
                break;
                case TYPE_SLIDERINT_FIELD:
                    readSliderIntFieldPlaceable(i);
                break;
                case TYPE_OPTIONS_FIELD:
                    readOptionsFieldPlaceable(i);
                break;
                case TYPE_BUTTON:
                    readButtonPlaceable(i);
                break;
                default:
                    console.warn("Corrupted element, skipping.");
                break;
            }
        }
        loading = false;
    }
    
    // Helper function
    private void getTextAttribs(TextPlaceable t, int i) {
        t.sprite.setX((float)getJSONArrayInt(i, "x", (int)WIDTH/2));
        t.sprite.setY((float)getJSONArrayInt(i, "y", (int)HEIGHT/2));
        t.sprite.name = getJSONArrayString(i, "ID", t.id);
        t.text = getJSONArrayString(i, "text", "");
        t.fontSize = getJSONArrayFloat(i, "size", 12.);
        
        // We now read color in hexadecimal format.
        // But before, there were loads of entries that read text in decimal format.
        // So: read old decimal format. If there's none, read (new) hexadecimal format. 
        // And if there's still none, default to white.
        t.textColor = getJSONArrayInt(i, "color", unhex(getJSONArrayString(i, "color_hex", "FFFFFFFF")));
        t.updateDimensions();
    }
    private TextPlaceable readTextPlaceable(int i) {
        TextPlaceable t = new TextPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        getTextAttribs(t, i);
        return t;
    }
    private InputFieldPlaceable readInputFieldPlaceable(int i) {
        InputFieldPlaceable t = new InputFieldPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        getTextAttribs(t, i);
        return t;
    }
    private ButtonPlaceable readButtonPlaceable(int i) {
        ButtonPlaceable t = new ButtonPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        t.rgb = unhex(getJSONArrayString(i, "button_color", "FF614d7d"));
        t.rgbHover = unhex(getJSONArrayString(i, "button_color_hover", "FF8d70b5"));
        getTextAttribs(t, i);
        return t;
    }
    private BooleanFieldPlaceable readBooleanFieldPlaceable(int i) {
        BooleanFieldPlaceable t = new BooleanFieldPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        getTextAttribs(t, i);
        return t;
    }
    private SliderFieldPlaceable readSliderFieldPlaceable(int i) {
        SliderFieldPlaceable t = new SliderFieldPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        t.createSlider(getJSONArrayFloat(i, "min_value", 0f), getJSONArrayFloat(i, "max_value", 100f), 50f);
        getTextAttribs(t, i);
        return t;
    }
    private SliderIntFieldPlaceable readSliderIntFieldPlaceable(int i) {
        SliderIntFieldPlaceable t = new SliderIntFieldPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        t.createSlider(getJSONArrayInt(i, "min_value", 0), getJSONArrayInt(i, "max_value", 10), 5);
        getTextAttribs(t, i);
        return t;
    }
    private OptionsFieldPlaceable readOptionsFieldPlaceable(int i) {
        OptionsFieldPlaceable t = new OptionsFieldPlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        
        if (!loadedJsonArray.getJSONObject(i).isNull("options")) {
          t.createOptions(loadedJsonArray.getJSONObject(i).getJSONArray("options"));
        }
        else {
          t.createOptions("Item 1", "Item 2", "Item 3");
        }
        
        getTextAttribs(t, i);
        return t;
    }
    private ImagePlaceable readImagePlaceable(final int i) {
        ImagePlaceable im = new ImagePlaceable(getJSONArrayString(i, "ID", generateRandomID()));
        im.sprite.setX((float)getJSONArrayInt(i, "x", (int)WIDTH/2));
        im.sprite.setY((float)getJSONArrayInt(i, "y", (int)HEIGHT/2));
        im.sprite.wi   = getJSONArrayInt(i, "wi", 512);
        im.sprite.hi   = getJSONArrayInt(i, "hi", 512);
        im.sprite.name = im.id;
        String imageName = getJSONArrayString(i, "imgName", "");
        
        // If there's cache, don't bother decoding the base64 string.
        // Otherwise, read the base64 string, generate cache, read from that cache.
        
        Runnable loadFromEntry = new Runnable() {
          public void run() {
            // Decode the string of base64
            String encoded   = getJSONArrayString(i, "png", "");
            
            // Png image data in json is missing
            if (encoded.length() == 0) {
              console.warn("while loading entry: png image data in json is missing.");
            }
            // Everything is found as expected.
            else {
              byte[] decodedBytes = Base64.getDecoder().decode(encoded.getBytes());
              
              PImage img = engine.saveCacheImageBytes(entryPath+"_"+str(i), decodedBytes, "png");
              
              // An error occured, data may have been tampered with/corrupted.
              if (img == null) 
                console.warn("while loading entry: png image data is corrupted or cachepath is invalid.");
              else 
                engine.setOriginalImage(img);
            }
          }
        };
        PImage img = engine.tryLoadImageCache(this.entryPath+"_"+str(i), loadFromEntry);
        
        im.setImage(img, imageName);
        
        return im;
    }
    
    
    public boolean loading = false;
    public void readEntryJSONInSeperateThread() {
      loading = true;
      Thread t = new Thread(new Runnable() {
          public void run() {
              readEntryJSON();
          }
      });
      t.start();
    }
    
    public boolean isLoaded() {
      return !loading;
    }
    
    protected boolean customCommands(String command) {
      if (command.equals("/editgui")) {
        gui.interactable = !gui.interactable;
        if (gui.interactable) console.log("GUI now interactable.");
        else  console.log("GUI is no longer interactable.");
        return true;
      }
      else if (command.equals("/alignbuttons")) {
        console.log("Align buttons to mouse.");
        for (Placeable p : placeableset.values()) {
          if (p instanceof ButtonPlaceable) {
            p.sprite.setX(input.mouseX());
          }
        }
        return true;
      }
      else return false;
    }


    //*****************************************************************
    //*********************GUI BUTTONS AND ACTIONS*********************
    //*****************************************************************

    public void runGUI() {
        ui.useSpriteSystem(gui);
        ui.spriteSystemClickable = !ui.miniMenuShown();

        
        if (!cameraMode) {
  
          // The lines nothin to see here
          gui.guiElement("line_1");
          gui.guiElement("line_2");
          gui.guiElement("line_3");
  
          app.noTint();
          app.textFont(engine.DEFAULT_FONT);
  
          //************BACK BUTTON************
          if (ui.buttonOnce("back", "back_arrow_128", "Save & back")) {
            try {
               saveEntryJSON();
               if (engine.getPrevScreen() instanceof Explorer) {
                 Explorer prevExplorerScreen = (Explorer)engine.getPrevScreen();
                 prevExplorerScreen.refreshDir();
               }
               
               // Remove all the images from this entry before we head back,
               // we don't wanna cause any memory leaks.
               
               // Update 25/09/23
               // ... where's the code? Hmmmmmmmmmmmm
               // Oh wait it's in the endAnimation function.
               // Bit misleading there, past me.
               
               closeTouchKeyboard();
               previousScreen();
            }
            catch (RuntimeException e) {
              // TODO: dear god we need a proper solution for this!!!!
              console.warn("Failed to save entry :(");
            }
          }
  
          //************FONT COLOUR************
          if (ui.button("font_color", "fonts_128", "Colour")) {
              SpriteSystem.Sprite s = gui.getSprite("font_color");
              
              Runnable r = new Runnable() {
                public void run() {
                  // Set the color of the text placeable
                  if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                      TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                      selectedColor = ui.getPickedColor();
                      editingTextPlaceable.textColor = selectedColor;
                  }
                }
              };
              
              ui.colorPicker(s.xpos, s.ypos+100, r);
          }
  
          //************BIGGER FONT************
          if (ui.button("bigger_font", "bigger_text_128", "Bigger")) {
              power.setAwake();
              if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                  TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                  selectedFontSize = editingTextPlaceable.fontSize + 2;
                  editingTextPlaceable.fontSize = selectedFontSize;
              }
              else {
                  selectedFontSize += 2;
              }
              sound.playSound("select_any");
          }
  
          //************SMALLER FONT************
          if (ui.button("smaller_font", "smaller_text_128", "Smaller")) {
              power.setAwake();
              if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                  TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                  selectedFontSize = editingTextPlaceable.fontSize - 2;
                  editingTextPlaceable.fontSize = selectedFontSize;
              }
              else {
                  selectedFontSize -= 2;
              }
  
              // Minimum font size
              if (selectedFontSize < MIN_FONT_SIZE) {
                  selectedFontSize = MIN_FONT_SIZE;
              }
              sound.playSound("select_any");
          }
  
          //************FONT SIZE************
          
          // Sprite might not be loaded by the time we want to check for hovering
          // so suppress warnings so we don't get an ugly warning.
          // Nothing bad will happen other than that.
          gui.suppressSpriteWarning = true;
          SpriteSystem.Sprite s = gui.getSprite("font_size");
          // Draw text where the sprite is
          app.textAlign(CENTER, CENTER);
          app.textSize(20);
  
          // Added this line cus other elements caused the text size to gray.
          app.fill(255);
          // Bug fix: don't show the sprite on the first frame of the animation start
          // (showGUI is set later)
          if (showGUI)
            app.text(selectedFontSize, s.xpos+s.wi/2, s.ypos+s.hi/2);
  
          // The button code
          if (ui.button("font_size", "nothing", "Font size")) {
              if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                  TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                  // Doesn't really do anything yet really.
                  editingTextPlaceable.fontSize = selectedFontSize;
              }
          }
  
          // Turn warnings back on.
          gui.suppressSpriteWarning = false;
          
          //************CAMERA************
          if (ui.button("camera", "camera_128", "Take photo")) {
            sound.playSound("select_any");
            this.beginCamera();
          }
          
          
          //************COPY BUTTON************
          //if (ui.button("copy", "copy_button_128", "Copy")) {
          //  sound.playSound("select_any");
          //  this.copy();
          //}
          
          //************PASTE BUTTON************
          //if (ui.button("paste", "paste_button_128", "Paste")) {
          //  sound.playSound("select_any");
          //  this.paste();
          //}
        }
        else {
          
          if (ui.button("camera_back", "back_arrow_128", "")) {
            sound.playSound("select_any");
            this.endCamera();
          }
          
          if (!camera.error.get() && camera.ready.get()) {
            if (ui.button("snap", "snap_button_128", "") || input.keyDownOnce(' ') || input.enterOnce) {
              sound.playSound("select_snap");
              stats.increase("photos_taken", 1);
              insertImage(camera.updateImage());
              
              // Rest of the stuff is just for cosmetic effects :sparkle_emoji:
              takePhoto = true;
              cameraFlashEffect = 255.;
            }
            
            // TODO: Add some automatic "position at bottom" function to the messy class.
            gui.getSprite("snap").setY(HEIGHT-myLowerBarWeight+20);
            
            if (camera.numberDevices() > 1) {
              if (ui.button("camera_flip", "flip_camera_128", "Switch camera")) {
                sound.playSound("select_any");
                preparingCameraMessage = "Switching camera...";
                camera.switchNextCamera();
              }
            }
            gui.getSprite("camera_flip").setY(HEIGHT-myLowerBarWeight+10);
          }
          
        }

        // We want to render the gui sprite system above the upper bar
        // so we do it here instead of content()
        gui.updateSpriteSystem();


    }
    
    public void beginCamera() {
      // In android, we don't do anything below us, and just
      // launch the system camera. EZ.
      if (isAndroid()) {
        openAndroidCamera();
        return;
      }
      
      upperBarDrop = CAMERA_ON_ANIMATION;        // Set to 
      upperbarExpand = 1.;
      cameraMode = true;
      myBackgroundColor = color(0);
      
      // Because rendering cameraDisplay takes time on the first run, we should prompt the user
      // that the display is getting set up. I hate this so much.
      app.textFont(engine.DEFAULT_FONT);
      ui.loadingIcon(WIDTH/2, HEIGHT/2);
      fill(255);
      textSize(30);
      textAlign(CENTER, CENTER);
      text("Starting camera display...", WIDTH/2, HEIGHT/2+120);
      
      // Start up the camera.
      Thread t = new Thread(new Runnable() {
          public void run() {
             camera.setup();
          }
      });
      t.start();
      preparingCameraMessage = "Starting camera...";
    }
    
    public void endCamera() {
      upperBarDrop = CAMERA_OFF_ANIMATION;
      upperbarExpand = 1.;
      cameraMode = false;
      camera.turnOffCamera();
      myBackgroundColor = BACKGROUND_COLOR;       // Restore original background color
      engine.sharedResources.set("lastusedcamera", camera.selectedCamera);
    }
    
    public void endCameraAndroid(PImage photo) {
      insertImage(photo);
    }

    // New name without the following path.
    // TODO: safer to move instead of delete
    public void renameEntry(String newName) {
      String newPath = entryDir+newName+"."+engine.ENTRY_EXTENSION;
      boolean success = file.mv(entryPath, newPath);
      
      if (success) {
        entryPath = newPath;
        console.log("Entry renamed to "+newName+"."+engine.ENTRY_EXTENSION);
      }
      else {
        console.warn("Failed to rename file.");
      }
      
      //File f = new File(entryPath);
      //if (f.exists()) {
      //  if (!f.delete()) console.warn("Couldn't rename entry; old file couldn't be deleted.");
      //}
      //entryPath = entryDir+newName+"."+engine.ENTRY_EXTENSION;
      //entryName = newName;
      //try {
      //  saveEntryJSON();
      //}
      //catch (RuntimeException e) {
      //  // TODO: dear god we need a proper solution for this!!!!
      //  console.warn("Failed to save entry :(");
      //}
    }
    
    protected void fabric() {
      display.shader("fabric", 
      "color", 
      red(myUpperBarColor)/255. ,
      green(myUpperBarColor)/255. ,
      blue(myUpperBarColor)/255. ,
      1. , 
      "intensity", 0.03f);
    }

    // I don't think you'll really need to modify this code much.
    public void upperBar() {
        // The upper bar expand down animation when the screen loads.
        if (upperbarExpand > 0.001) {
            power.setAwake();
            upperbarExpand *= PApplet.pow(0.8, display.getDelta());
            
            float newBarWeight = UPPER_BAR_DROP_WEIGHT;
            
            if (upperBarDrop == CAMERA_OFF_ANIMATION || upperBarDrop == INITIALISE_DROP_ANIMATION)
              myUpperBarWeight = UPPER_BAR_WEIGHT + newBarWeight - (newBarWeight * upperbarExpand);
            else myUpperBarWeight = UPPER_BAR_WEIGHT + (newBarWeight * upperbarExpand);
            
            
            
            if (upperbarExpand <= 0.001) power.setSleepy();
        }
        
        fabric();
        
        if (!ui.miniMenuShown() && !cameraMode) 
          display.clip(0, 0, WIDTH, myUpperBarWeight);
        super.upperBar();
        display.resetShader();
        
        if (showGUI)
          runGUI();
        app.noClip();
    }
    
    public void lowerBar() {
      fabric();
      
      float LOWER_BAR_EXPAND = 100.;
      if (upperBarDrop == CAMERA_ON_ANIMATION) myLowerBarWeight = LOWER_BAR_WEIGHT+(LOWER_BAR_EXPAND * (1.-upperbarExpand));
      if (upperBarDrop == CAMERA_OFF_ANIMATION) myLowerBarWeight = LOWER_BAR_WEIGHT+(LOWER_BAR_EXPAND * (upperbarExpand));
      
      super.lowerBar();
      display.resetShader();
    }
    
    public float insertedXpos = 10;
    public float insertedYpos = this.myUpperBarWeight;
    
    private void insertImage(PImage img) {
      if (readOnly) return;
        
      // Because this could potentially take a while to load and cache into the Processing engine,
      // we should expect framerate drops here.
      engine.power.resetFPSSystem();
      
      // TODO: Check whether we have text or image in the clipboard.
      if (!ui.miniMenuShown()) {
        if (img == null) console.log("Can't paste image from clipboard!");
        else {
          // Resize the image if autoScaleDown is enabled for faster performance.
          if (autoScaleDown) {
            engine.scaleDown(img, SCALE_DOWN_SIZE);
          }
          
          ImagePlaceable imagePlaceable = new ImagePlaceable(generateRandomID(), img);
          if (editingPlaceable != null) {
            // Grab the position of the text that was there previously
            // so we can plonk an image in its place, but only if there was
            // no text to begin with.
            if (editingPlaceable instanceof TextPlaceable) {
              TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
              float x = editingPlaceable.sprite.xpos;
              float y = editingPlaceable.sprite.ypos;
              int hi = editingPlaceable.sprite.hi;
              
              if (editingTextPlaceable.text.length() == 0) {
                  placeableset.remove(editingPlaceable.id);
                  imagePlaceable.sprite.setX(x);
                  imagePlaceable.sprite.setY(y-scrollOffset);
              }
              else {
                  imagePlaceable.sprite.setX(x);
                  imagePlaceable.sprite.setY(y+hi);
              }
            }
          }
          else {
            // If no text is being edited then place the image in the default location.
            imagePlaceable.sprite.setX(insertedXpos);
            imagePlaceable.sprite.setY(insertedYpos);
            insertedXpos += 20;
            insertedYpos += 20;
          }
          // Dont want our image stretched
          imagePlaceable.sprite.wi = img.width;
          imagePlaceable.sprite.hi = img.height;
          
          
          float aspect = float(img.height)/float(img.width);
          // If the image is too large, make it smaller quickly
          if (imagePlaceable.sprite.wi > WIDTH*0.5) {
            imagePlaceable.sprite.wi = int((WIDTH*0.5));
            imagePlaceable.sprite.hi = int((WIDTH*0.5)*aspect);
          }
          
          // Select the image we just pasted.
          editingPlaceable = imagePlaceable;
          changesMade = true;
          stats.increase("images_created", 1);
        }
      }
    }
    
    // Just normal text by default.
    private TextPlaceable insertText(String initText, float x, float y) {
      return insertText(initText, x, y, TYPE_TEXT);
    }
    
    private TextPlaceable insertText(String initText, float x, float y, int type) {
        // Don't do anything if readonly enabled.
        if (readOnly) return null;
        
        TextPlaceable editingTextPlaceable;
        if (type == TYPE_INPUT_FIELD) {
          editingTextPlaceable = new InputFieldPlaceable(generateRandomID());
        }
        else if (type == TYPE_SLIDER_FIELD) {
          SliderFieldPlaceable t = new SliderFieldPlaceable(generateRandomID());
          t.createSlider(0f, 100f, 50f);
          editingTextPlaceable = t;
        }
        else if (type == TYPE_BUTTON) {
          ButtonPlaceable t = new ButtonPlaceable(generateRandomID());
          editingTextPlaceable = t;
        }
        else if (type == TYPE_OPTIONS_FIELD) {
          OptionsFieldPlaceable t = new OptionsFieldPlaceable(generateRandomID());
          t.createOptions("Item 1", "Item 2", "Item 3");
          editingTextPlaceable = t;
        }
        else if (type == TYPE_SLIDERINT_FIELD) {
          SliderIntFieldPlaceable t = new SliderIntFieldPlaceable(generateRandomID());
          t.createSlider(0, 10, 5);
          editingTextPlaceable = t;
        }
        else if (type == TYPE_BOOLEAN_FIELD) {
          editingTextPlaceable = new BooleanFieldPlaceable(generateRandomID());
        }
        else if (type == TYPE_TEXT) {
          editingTextPlaceable = new TextPlaceable(generateRandomID());
        }
        else {
          editingTextPlaceable = new TextPlaceable(generateRandomID());
        }
        
        editingTextPlaceable.textColor = selectedColor;
        placeableSprites.selectedSprite = editingTextPlaceable.sprite;
        editingTextPlaceable.sprite.setX(x);
        editingTextPlaceable.sprite.setY(y-scrollOffset);
        editingPlaceable = editingTextPlaceable;
        
        input.cursorX = initText.length();
        editingTextPlaceable.updateDimensions();
        engine.allowShowCommandPrompt = false;
        stats.increase("text_created", 1);
        
        return editingTextPlaceable;
    }
    
    protected void renderPlaceables() {
        placeableSprites.interactable = !readOnly;
      
        placeableSprites.updateSpriteSystem();
        
        // Because every placeable is placed at a slight offset due to the ribbon bar,
        // readonly doesn't have this bar and hence we should limit scroll at where the
        // ribbon bar normally is.
        if (forcedScrollBugFix) {
          scrollOffset = -UPPER_BAR_DROP_WEIGHT;
        }
        else {
          if (!readOnly)
            scrollOffset = input.processScroll(scrollOffset, 0., scrollLimitY);
          else 
            scrollOffset = input.processScroll(scrollOffset, -UPPER_BAR_DROP_WEIGHT, scrollLimitY);
        }
          
        extentX = 0;
        extentY = 0;
        // Run all placeable objects
        for (Placeable p : placeableset.values()) {
          try {
            p.update();
          }
          catch (RuntimeException e) {
            //console.warn("Entry rendering error, continuing.");
          }
            
            // Don't care I can tidy things up later.
            // Update extentX and extentY
            float newx = (p.sprite.defxpos+p.sprite.getWidth());
            if (newx > extentX) extentX = newx;
            float newy = (p.sprite.defypos+p.sprite.getHeight());
            if (newy > extentY) extentY = newy;
        }
        
        // Update max scroll.
        scrollLimitY = max(extentY+SCROLL_LIMIT-HEIGHT+myLowerBarWeight, 0);
    }
    
    private void copy() {
      if (editingPlaceable != null) {
        if (editingPlaceable instanceof TextPlaceable) {
          TextPlaceable t = (TextPlaceable)editingPlaceable;
          boolean success = clipboard.copyString(t.text);
          if (success) {
            clipboardFontSize = t.fontSize;
            clipboardColor = t.textColor;
            clipboardFontStyle = t.fontStyle;
            console.log("Copied!");

          }
        }
        else if (editingPlaceable instanceof ImagePlaceable) {
          ImagePlaceable img = (ImagePlaceable)editingPlaceable;
          boolean success = clipboard.copyImage(display.getImg(img.imageName));
          if (success)
            console.log("Copied!");
        }
        else console.log("Copying of element not supported yet, sorry!");
      }
    }
    
    private void paste() {
      if (clipboard.isImage()) {
        PImage pastedImage = clipboard.getImage();
        if (pastedImage == null) console.log("Can't paste image from clipboard!");
        else {
          insertImage(pastedImage);
          stats.increase("images_pasted", 1);
        }
      }
      else if (clipboard.isString()) {
        String pastedString = clipboard.getText();
        if (editingPlaceable != null) {
          // If we're currently editing text, append it
          if (editingPlaceable instanceof TextPlaceable) {
            TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
            if (editingTextPlaceable.text.length() == 0) {
                editingTextPlaceable.fontSize = clipboardFontSize;
                editingTextPlaceable.textColor = clipboardColor;
                editingTextPlaceable.fontStyle = clipboardFontStyle;
            }
          }
          else if (editingPlaceable instanceof ImagePlaceable) {
            // Place it just underneath the image.
            float imx = editingPlaceable.sprite.xpos;
            float imy = editingPlaceable.sprite.ypos;
            int imhi = editingPlaceable.sprite.hi;
            TextPlaceable newText = insertText(pastedString, imx, imy+imhi);
            
            newText.fontSize = clipboardFontSize;
            newText.textColor = clipboardColor;
            newText.fontStyle = clipboardFontStyle;
          }
        }
        // No text or image being edited, just plonk it whereever.
        else {
          insertedXpos += 20;
          insertedYpos += 20;
          TextPlaceable newText = insertText(pastedString, insertedXpos, insertedYpos);
          
          newText.fontSize = clipboardFontSize;
          newText.textColor = clipboardColor;
          newText.fontStyle = clipboardFontStyle;
        }
        stats.increase("strings_pasted", 1);
      }
      else console.log("Can't paste item from clipboard!");
    }
    
    
    boolean scrolling = false;
    boolean prevReset = false;
    
    // Only used in readonly mode
    private InputFieldPlaceable modifyingField = null;
    
    private void renderEditor() {
      //yview += engine.scroll;
        // In order to know if we clicked on an object or a blank area,
        // this is what we do:
        // 1 Keep track of a click and do some stuff (like deleting a placeable object)
        // it it's empty
        // 2 Update all objects which will check if any of them have been clicked.
        // 3 If there's been a click from step 1 then check if any object has been clicked.
        boolean clickedThing = false;
        boolean mouseInUpperbar = engine.mouseY() < myUpperBarWeight;
        
        
        if (!input.primaryDown) {
          prevMouseY = input.mouseY();
          prevReset =  true;
        }
      // Reset prevInput for one more frame
        else if (prevReset) {
          prevMouseY = input.mouseY();
          prevReset =  false;
        }
        
        if (input.primaryOnce && !mouseInUpperbar) {
          scrolling = true;
        }
        
        if (input.primaryReleased) {
            if (!input.mouseMoved) {
                clickedThing = true;
            }
            scrolling = false;
        }

        // The part of the code that actually deselects an element when clicking in
        // a blank area.
        // However, we don't want to deselect text in the following:
        // 1. If the minimenu is open
        // 2. GUI element is clicked (we just check the mouse is in the upper bar
        // to check that condition)
        if (input.primaryOnce) {
            if(!ui.miniMenuShown() && !mouseInUpperbar) {

                if (editingPlaceable != null) {
                  if (editingPlaceable instanceof TextPlaceable) {
                    TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                    if (editingTextPlaceable.text.length() == 0) {
                        placeableset.remove(editingPlaceable.id);
                    }
                  }
                  // Rename the entry if we're clicking off the title text.
                  if (editingPlaceable == entryNameText) {
                    if (entryNameText.text.matches("^[a-zA-Z0-9_ ,\\-]+$()") && entryNameText.text.length() > 0) {
                      renameEntry(entryNameText.text);
                    }
                    else {
                      console.log("Invalid characters in entry name!");
                      entryNameText.text = entryName;
                    }
                  }
                  
                  // Otherwise anything else should be deselected automatically.
                  editingPlaceable = null;
                  engine.allowShowCommandPrompt = true;
                  //saveEntryJSON();
                }
                
                // This is ok to place here because fields are selected in renderPlaceables(), and renderPlaceables()
                // is just below this section.
                modifyingField = null;

            }
        }
        
        // Right click menu in a blank space.
        else if (input.secondaryOnce) {
            if(!ui.miniMenuShown() && !mouseInUpperbar && !readOnly) {
                // To ensure we're clicking in a blank space, make sure we're either:
                // A. have an object selected but not right-clicking on it
                // B. don't have an object selected and right-clicking a blank area.
                boolean rightClickMenu = false;
                if (editingPlaceable != null) {
                  rightClickMenu = !editingPlaceable.placeableSelectedSecondary();
                }
                else {
                  rightClickMenu = true;
                }
                
                if (rightClickMenu) {
                  blankOptions();
                }
            }
        }
        
        if (movingSlider && !input.primaryDown) {
          movingSlider = false;
        }
        
        
        if (input.ctrlDown && input.keyDownOnce('c')) { // Ctrl+c
          this.copy();
        }
        
        if (input.ctrlDown && input.keyDownOnce('v')) // Ctrl+v
        {
          this.paste();
        }
        
        
        // I HATE THE DELETE KEY!!!!!!!!!!!!
        // (I'll re-enable it when undoing is eventually added)
        
        //if (input.keyDownOnce(char(127))) {
        //  if (editingPlaceable != null) {
        //    placeableset.remove(editingPlaceable.id);
        //    changesMade = true;
        //  }
        //}
        
        renderPlaceables();

        
        // Create new text if a blank area has been clicked.
        // Clicking in a blank area will create new text
        // however, there's some exceptions to that rule
        // and the following conditions need to be met:
        // 1. There's no minimenu open
        // 2. There's no gui element being interacted with
        // Oh also scroll if we're dragging instead.
        if (editingPlaceable == null && !ui.miniMenuShown()) {
          // Check back to see if something's been clicked.
          if (clickedThing) {
            if (!readOnly) {
              insertText("", engine.mouseX(), engine.mouseY()-20);
              // And in android
              openTouchKeyboard();
            }
          }
          else {
            closeTouchKeyboard();
          }
          
          if (scrolling && !movingSlider) {
            power.setAwake();
            scrollVelocity = (input.mouseY()-prevMouseY);
          }
          else {
            scrollVelocity *= PApplet.pow(0.92, display.getDelta());
          }
        }
        prevMouseY = input.mouseY();
        scrollOffset += scrollVelocity;
        

        
        // Power stuff
        // If we're dragging a sprite, we want framerates to be smooth, so temporarily
        // set framerates higher while we're dragging around.
        if (placeableSprites.selectedSprite != null) {
          if (placeableSprites.selectedSprite.repositionDrag.isDragging() || placeableSprites.selectedSprite.resizeDrag.isDragging()) {
            engine.power.setAwake();
            
            // While we're here, a sprite is being dragged which means changes to the file.
            changesMade = true;
          }
          else {
            engine.power.setSleepy();
          }
          
          // Just check for changes
          // Technically (as of now) just for images (text will never see this code)
          // but can also apply to any new future placeables in the future.
          if (placeableSprites.selectedSprite.resizeDrag.isDragging()) {
            changesMade = true;
          }
        }
    }
    
    public String preparingCameraMessage = "Starting camera...";
    public boolean takePhoto = false;
    public float cameraFlashEffect = 0.;
    public void renderPhotoTaker() {
      app.textFont(engine.DEFAULT_FONT);
      if (!camera.ready.get()) {
        
        textAlign(CENTER, CENTER);
        textSize(30);
        if (camera.error.get() == true) {
          display.imgCentre("error", WIDTH/2, HEIGHT/2);
          String errorMessage = "";
          fill(255, 0, 0);
          switch (camera.errorCode.get()) {
            case ERR_UNKNOWN:
              errorMessage = "An unknown error has occured.";
            break;
            case ERR_NO_CAMERA_DEVICES:
              errorMessage = "No camera devices found.";
            break;
            case ERR_FAILED_TO_SWITCH:
              errorMessage = "A weird error occured with switching cameras.";
            break;
            case ERR_UNSUPPORTED_SYSTEM:
              errorMessage = "Camera is unsupported on your system, sorry :(";
            break;
            default:
              errorMessage = "An unknown error has occured.";
              console.bugWarnOnce("renderPhotoTaker: Unused error code.");
            break;
          }
          text(errorMessage, WIDTH/2, HEIGHT/2+120);
        }
        else {
          ui.loadingIcon(WIDTH/2, HEIGHT/2);
          fill(255);
          text("Starting camera...", WIDTH/2, HEIGHT/2+120);
        }
      }
      else {
        PImage pic = camera.updateImage();
        if (pic != null && pic.width > 0 && pic.height > 0) {
          
          float aspect = float(pic.height)/float(pic.width);
          app.image(pic, 0, 0, WIDTH, WIDTH*aspect);
          if (takePhoto) {
            app.blendMode(ADD);
            app.noStroke();
            app.fill(cameraFlashEffect);
            app.rect(0,0, WIDTH, HEIGHT);
            app.blendMode(NORMAL);
            cameraFlashEffect -= 20.*display.getDelta();
            if (cameraFlashEffect < 10.) {
              takePhoto = false;
              this.endCamera();
            }
          }
        }
        //engine.timestamp("start image");
        //app.beginShape();
        //engine.timestamp("texture");
        //app.texture(pic);
        //engine.timestamp("verticies");
        //app.vertex(x1, y1, 0, 0);           // Bottom left
        //app.vertex(x2,     y1, 1., 0);    // Bottom right
        //app.vertex(x2,     y2, 1., 1.); // Top right
        //app.vertex(x1,       y2, 0, 1.);  // Top left
        //app.endShape();
        //engine.timestamp("end image");
      }
    }
    
    public void display() {
      if (engine.power.getPowerMode() != PowerMode.MINIMAL) {
        app.pushMatrix();
        app.translate(screenx,screeny);
        app.scale(display.getScale());
        this.backg();
        
        this.content();
        this.lowerBar();
        this.upperBar();
        app.popMatrix();
      }
    }
    
    int before = 0;

    public void content() {
      if (loading) {
        ui.loadingIcon(WIDTH/2, HEIGHT/2);
        stats.recordTime("editor_loading_time");
      }
      else {
        if (cameraMode) {
          renderPhotoTaker();
        }
        else {
          // We pretty much just render all of the placeables here.
          renderEditor();
        }
      }
      
      stats.recordTime("time_in_editor");
      stats.increase("total_frames_editor", 1);
    }

    public void startupAnimation() {
        // As soon as the window finishes sliding in, roll down the upper bar.
        // Beautiful animation :twinkle_emoji:
        upperBarDrop = INITIALISE_DROP_ANIMATION;
        upperbarExpand = 1.0;
        showGUI = true;
    }
    
    public void endScreenAnimation() {
      free();
      engine.allowShowCommandPrompt = true;
    }
    
    public void finalize() {
      //free();
    }
    
    public void free() {
       // Clear the images from systemimages to clear up used images.
       for (String s : imagesInEntry) {
         display.systemImages.remove(s);
       }
       imagesInEntry.clear();
    }
}





















public class ReadOnlyEditor extends Editor {
  protected SpriteSystem readonlyEditorUI;
  
  public ReadOnlyEditor(TWEngine engine, String entryPath, boolean full, boolean loadMultithreaded) {
    super(engine, entryPath, full, loadMultithreaded);
    setupp();
  }
  
  public ReadOnlyEditor(TWEngine e, String entryPath) {
    super(e, entryPath);
    setupp();
  }
  
  void setupp()
  {
    readOnly = true;
    scrollOffset = -UPPER_BAR_DROP_WEIGHT;
    
    readonlyEditorUI = new SpriteSystem(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/readonlyeditor/");
    readonlyEditorUI.repositionSpritesToScale();
    readonlyEditorUI.interactable = false;
  }
  
  public void upperBar() {
    fabric();
    display.recordRendererTime();
    app.fill(myUpperBarColor);
    app.noStroke();
    app.rect(0, 0, WIDTH, myUpperBarWeight);
    display.recordLogicTime();
    display.resetShader();
    
    // display our very small ui
    ui.useSpriteSystem(readonlyEditorUI);
    
    if (ui.buttonVaryOnce("back-button", "back_arrow_128", "Back")) {
      // This only exists because we can only have one prev screen at a time
      // and I swear to god I hate this and this is gonna get changed sooner or later.
      // In fact I may call this with a TODO.
      // TODO: Please change this. A weak spot that makes the editor class non-modular.
      if (!(engine.getPrevScreen() instanceof PixelRealmWithUI)) {
        //sound.stopMusic();
        previousScreen();
        //requestScreen(new Startup(engine));
      }
      else {
        previousScreen();
      }
    }
    
    readonlyEditorUI.updateSpriteSystem();
  }
  
  public void lowerBar() {
    fabric();
    display.recordRendererTime();
    app.fill(myLowerBarColor);
    app.noStroke();
    app.rect(0, HEIGHT-myLowerBarWeight, WIDTH, myLowerBarWeight);
    display.recordLogicTime();
    display.resetShader();
  }
}



public class CreditsScreen extends ReadOnlyEditor {
  public final static String CREDITS_PATH        = "engine/entryscreens/acknowledgements.timewayentry";
  public final static String CREDITS_PATH_PHONE  = "engine/entryscreens/acknowledgements_phone.timewayentry";
  
  public CreditsScreen(TWEngine engine) {
    // Kinda overcoming an unnecessary java limitation where super must be the first statement,
    // we choose the phone version (for condensed screens) or the normal version.
    super(engine, engine.display.phoneMode ? engine.APPPATH+CREDITS_PATH_PHONE : engine.APPPATH+CREDITS_PATH);
  }
  
  public void content() {
    scrollOffset -= display.getDelta()*0.7;
    power.setAwake();
    super.content();
  }
  
  protected boolean customCommands(String command) {
    if (command.equals("/edit") || command.equals("/editcredits")) {
      console.log("Editing acknowledgements.");
      requestScreen(new Editor(engine, display.phoneMode ? engine.APPPATH+CREDITS_PATH_PHONE : engine.APPPATH+CREDITS_PATH));
      return true;
    }
    else return false;
  }
}


// TODO: Add minimized setting.

public class SettingsScreen extends ReadOnlyEditor {
  public final static String SETTINGS_PATH        = "engine/entryscreens/settings.timewayentry";
  public final static String SETTINGS_PATH_PHONE  = "engine/entryscreens/settings_phone.timewayentry";
  
  private PGraphics[] mockSceneScales = new PGraphics[5];
  private PGraphics mockScene = null;
  private int mockSceneHeight = 0;
  
  public SettingsScreen(TWEngine engine) {
    // Kinda overcoming an unnecessary java limitation where super must be the first statement,
    // we choose the phone version (for condensed screens) or the normal version.
    //super(engine, engine.display.phoneMode ? engine.APPPATH+SETTINGS_PATH_PHONE : engine.APPPATH+SETTINGS_PATH, null, false);
    super(engine, engine.APPPATH+SETTINGS_PATH, true, false);
    
    loadSettings();
    get("invalid_path_error").visible = !(file.exists(getInputField("home_directory").inputText) && file.isDirectory(getInputField("home_directory").inputText));
    
    // Populate options field for audio devices
    String[] devices = sound.getAudioDevices();
    String[] devicesWithAuto = new String[devices.length+1];
    devicesWithAuto[0] = "Auto";
    for (int i = 0; i < devices.length; i++) {
      devicesWithAuto[i+1] = devices[i];
    }
    getOptionsField("audio_device").createOptions(devicesWithAuto);
    
    
    mockSceneHeight = (int)(HEIGHT-myUpperBarWeight-myLowerBarWeight);
  }
  
  
  
  
    
  protected BooleanFieldPlaceable getBooleanField(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new BooleanFieldPlaceable("null");
    }
    try {
      return (BooleanFieldPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access BooleanFieldPlaceable but is "+get(name).getClass().getSimpleName());
      return new BooleanFieldPlaceable("null");
    }
  }
  
  protected ButtonPlaceable getButton(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new ButtonPlaceable("null");
    }
    try {
      return (ButtonPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access ButtonPlaceable but is "+get(name).getClass().getSimpleName());
      return new ButtonPlaceable("null");
    }
  }
  
  protected InputFieldPlaceable getInputField(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new InputFieldPlaceable("null");
    }
    try {
    return (InputFieldPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access InputFieldPlaceable but is "+get(name).getClass().getSimpleName());
      return new InputFieldPlaceable("null");
    }
  }
  
  protected SliderFieldPlaceable getSliderField(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new SliderFieldPlaceable("null");
    }
    try {
    return (SliderFieldPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access SliderFieldPlaceable but is "+get(name).getClass().getSimpleName());
      return new SliderFieldPlaceable("null");
    }
  }
  
  protected SliderIntFieldPlaceable getSliderIntField(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new SliderIntFieldPlaceable("null");
    }
    try {
      return (SliderIntFieldPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access SliderIntFieldPlaceable but is "+get(name).getClass().getSimpleName());
      return new SliderIntFieldPlaceable("null");
    }
  }

  protected OptionsFieldPlaceable getOptionsField(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new OptionsFieldPlaceable("null");
    }
    try {
    return (OptionsFieldPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access OptionsFieldPlaceable but is "+get(name).getClass().getSimpleName());
      return new OptionsFieldPlaceable("null");
    }
  }
  
  
  private void loadSettings() {
    getBooleanField("dynamic_framerate").state = settings.getBoolean("dynamic_framerate", true);
    getBooleanField("more_ram").state = !settings.getBoolean("low_memory", false);
    getBooleanField("scale_down_images").state = settings.getBoolean("auto_scale_down", false);
    getSliderField("scroll_sensitivity").setVal(settings.getFloat("scroll_sensitivity", 20f));
    
    String selectedAudioDevice = settings.getString("audio_device", "Auto");
    getOptionsField("audio_device").selectedOption = "Auto"; // Auto by default
    String[] devices = getOptionsField("audio_device").options; // Will also include "Auto" which saves us from having to implement a special check for that.
    // An extra check here in case the audio device that used to be here is no longer there.
    for (String device : devices) {
      if (device.equals(selectedAudioDevice)) {
        getOptionsField("audio_device").selectedOption = selectedAudioDevice;
        break;
      }
    }
    
    
    String newRealmAction = settings.getString("new_realm_action", "prompt");
    if (newRealmAction.equals("prompt")) newRealmAction = "Prompt realm templates";
    if (newRealmAction.equals("default")) newRealmAction = "Create default realm files";
    if (newRealmAction.equals("nothing")) newRealmAction = "Do nothing";
    getOptionsField("new_realm").selectedOption = newRealmAction;
    
    getSliderIntField("pixelation_scale").setVal(settings.getInt("pixelation_scale", 4));
    getBooleanField("enable_caching").state = settings.getBoolean("caching", true);
    
    String powerMode = settings.getString("force_power_mode", "Auto");
    if (powerMode.equals("HIGH")) powerMode = "60 FPS";
    if (powerMode.equals("NORMAL")) powerMode = "30 FPS";
    if (powerMode.equals("SLEEPY")) powerMode = "10 FPS";
    if (powerMode.equals("AUTO")) powerMode = "Auto";
    getOptionsField("target_framerate").selectedOption = powerMode;
    getBooleanField("sleep_when_inactive").state = settings.getBoolean("sleep_when_inactive", true);
    
    
    getInputField("home_directory").inputText = settings.getString("home_directory", System.getProperty("user.home").replace('\\', '/'));
    getBooleanField("backup_realm_files").state = settings.getBoolean("backup_realm_files", true);
    getSliderField("field_of_view").setVal(settings.getFloat("fov", 60f));
    getSliderField("volume").setVal(settings.getFloat("volume_normal", 1f));
    getSliderField("minimized_volume").setVal(settings.getFloat("volume_quiet", 0.25f));
    getBooleanField("show_fps").state = settings.getBoolean("show_fps", false);
    getBooleanField("enable_plugins").state = settings.getBoolean("enable_plugins", false);
  }
  
  public void endScreenAnimation() {
    super.endScreenAnimation();
    power.setDynamicFramerate(settings.setBoolean("dynamic_framerate", getBooleanField("dynamic_framerate").state));
    engine.setLowMemory(!getBooleanField("more_ram").state);
    settings.setBoolean("auto_scale_down", getBooleanField("scale_down_images").state);
    input.scrollSensitivity = settings.setFloat("scroll_sensitivity", getSliderField("scroll_sensitivity").getVal());
    
    settings.setString("audio_device", getOptionsField("audio_device").selectedOption);
    //sound.selectAudioDevice(getOptionsField("audio_device").selectedOption);
    
    String selected = getOptionsField("new_realm").selectedOption;
    if (selected.equals("Prompt realm templates")) {
      settings.setString("new_realm_action", "prompt");
    }
    else if (selected.equals("Create default realm files")) {
      settings.setString("new_realm_action", "default");
    }
    else if (selected.equals("Create default (legacy) realm files")) {
      settings.setString("new_realm_action", "default_legacy");
    }
    else if (selected.equals("Do nothing")) {
      settings.setString("new_realm_action", "nothing");
    }
    
    settings.setInt("pixelation_scale", getSliderIntField("pixelation_scale").getValInt());
    settings.setBoolean("caching", getBooleanField("enable_caching").state);
    power.allowMinimizedMode = settings.setBoolean("sleep_when_inactive", getBooleanField("sleep_when_inactive").state);
    
    selected = getOptionsField("target_framerate").selectedOption;
    if (selected.equals("60 FPS")) selected = settings.setString("force_power_mode", "HIGH");
    else if (selected.equals("30 FPS")) selected = settings.setString("force_power_mode", "NORMAL");
    else if (selected.equals("10 FPS")) selected = settings.setString("force_power_mode", "SLEEPY");
    else if (selected.equals("Auto")) selected = settings.setString("force_power_mode", "AUTO");
    power.setForcedPowerMode(selected);
    
    
    engine.DEFAULT_DIR = settings.setString("home_directory", file.directorify(getInputField("home_directory").inputText));
    settings.setBoolean("backup_realm_files", getBooleanField("backup_realm_files").state); 
    settings.setFloat("fov", getSliderField("field_of_view").getVal());
    sound.volumeNormal = settings.setFloat("volume_normal", getSliderField("volume").getVal());
    sound.volumeQuiet = settings.setFloat("volume_quiet", getSliderField("minimized_volume").getVal());
    display.showFPS = settings.setBoolean("show_fps", getBooleanField("show_fps").state);
    settings.setBoolean("enable_plugins", getBooleanField("enable_plugins").state);
    
    System.gc();
  }
  
  private float backgroundFade = 255f;
  
  public void backg() {
    // When sliding the mockSceneSlider, fade in the mock pixelrealm scene.
    boolean showMockScene = getSliderIntField("pixelation_scale").mouseDown();
    showMockScene |= getSliderField("field_of_view").mouseDown();
    //showMockScene = true;
    
    // Fade in/out.
    if (showMockScene) {
      backgroundFade -= 5f*display.getDelta();
    }
    else {
      backgroundFade += 5f*display.getDelta();
    }
    // constraint
    backgroundFade = max(min(backgroundFade, 255f), 127f);
    
    // Render the scene
    if (backgroundFade < 255f) {
      // Select the scale of the scene.
      // Using the mockSceneScales array is sort of like caching the scenes so we don't need to waste performance
      // creating a new scene every frame (gross).
      int scale = getSliderIntField("pixelation_scale").getValInt();
      if (scale == 0) return;
      if (mockSceneScales[scale] == null) {
        // Create (make sure it's pixelated)
        mockScene = createGraphics((int)(WIDTH/float(scale)), (int)(mockSceneHeight/float(scale)), P3D);
        ((PGraphicsOpenGL)mockScene).textureSampling(2);
        
        // Cache newly created scaled scene.
        mockSceneScales[scale] = mockScene;
      }
      mockScene = mockSceneScales[scale];
      
      renderPixelRealmMockup();
      //renderObjects();
      app.image(mockScene, 0, myUpperBarWeight, WIDTH, mockSceneHeight);
    }
    
    // Render the actual background on top as a transparent layer (if sliding the slider, otherwise fully opaque when fully faded in).
    app.fill(red(myBackgroundColor), green(myBackgroundColor), blue(myBackgroundColor), backgroundFade);
    app.noStroke();
    app.rect(0, myUpperBarWeight, WIDTH, HEIGHT-myUpperBarWeight-myLowerBarWeight);
    
  }
  
  public void content() {
    //power.setAwake();
    super.content();
    
    input.scrollSensitivity = getSliderField("scroll_sensitivity").getVal();
    
    display.showFPS = getBooleanField("show_fps").state;
    
    // Update volume (once every 10 frames cus I'm scared of changing it every frame).
    if (app.frameCount % 10 == 0) {
      sound.setMasterVolume(getSliderField("volume").getVal());
    }
    power.allowMinimizedMode = getBooleanField("sleep_when_inactive").state;
    
    // Show "not recommended" warning when target framerate is set to SLEEPY.
    get("target_framerate_warning").visible = getOptionsField("target_framerate").selectedOption.equals("10 FPS");
    
    // Show "not found" error if home dir path is not valid.
    if (input.keyOnce) {
      if (file.exists(getInputField("home_directory").inputText) && file.isDirectory(getInputField("home_directory").inputText)) {
        get("invalid_path_error").visible = false;
      }
      else {
        get("invalid_path_error").visible = true;
      }
    }
    
    
    if (getButton("keybind_settings").clicked) {
      sound.playSound("select_general");
      requestScreen(new KeybindSettingsScreen(engine));
    }
  }
  
  protected boolean customCommands(String command) {
    if (command.equals("/edit")) {
      console.log("Editing settings.");
      requestScreen(new Editor(engine, display.phoneMode ? engine.APPPATH+SETTINGS_PATH_PHONE : engine.APPPATH+SETTINGS_PATH));
      return true;
    }
    else return false;
  }
  
  float LOOK_DIST = 50f;
  float direction = 0;
  float groundSize = 400;
  // I was originally going to simply record a pixel realm scene as an obj file and then display it with a single line of
  // code. Turns out, exporting an obj of the scene is a lot harder than I thought. So unfortunately we're doing immediate
  // mode rendering of the default scene using this copy+paste but massively dumbed down.
  private void renderPixelRealmMockup() {
      mockScene.beginDraw();
      mockScene.background(0);
      mockScene.noStroke();
      mockScene.hint(DISABLE_DEPTH_TEST);
      mockScene.perspective(PI/3.0, (float)mockScene.width/mockScene.height, 10., 1000000.);
      mockScene.image(display.getImg("pixelrealm-sky-legacy"), 0, 0, mockScene.width, mockScene.height);
      mockScene.flush();
      mockScene.hint(ENABLE_DEPTH_TEST);
      
      mockScene.pushMatrix();
      
      float playerX = 0f;
      float playerY = 0f;
      float playerZ = 0f;
      
      mockScene.camera(playerX, playerY-80f, playerZ, 
        playerX+sin(direction)*LOOK_DIST, playerY-80f, playerZ+cos(direction)*LOOK_DIST, 
        0., 1., 0.);
      setPerspective();
      
      int renderDistance = 6;
      float chunkx = floor(playerX/groundSize)+1.;
      float chunkz = floor(playerZ/groundSize)+1.; 
      float FADE_DIST_GROUND = PApplet.pow(PApplet.max(renderDistance-3, 0.)*groundSize, 2);
      for (float tilez = chunkz-renderDistance-1; tilez < chunkz+renderDistance; tilez += 1.) {
        for (float tilex = chunkx-renderDistance-1; tilex < chunkx+renderDistance; tilex += 1.) {
          float x = groundSize*(tilex-0.5), z = groundSize*(tilez-0.5);
          float dist = PApplet.pow((playerX-x), 2)+PApplet.pow((playerZ-z), 2);
          boolean dontRender = false;
          if (dist > FADE_DIST_GROUND) {
            float fade = calculateFade(dist, FADE_DIST_GROUND);
            if (fade > 1) {
              mockScene.tint(255, fade);
              mockScene.fill(255, fade); 
            }
            else dontRender = true;
          } else {
            mockScene.noTint();
            mockScene.fill(255);
          } 
          if (!dontRender) {
            mockScene.beginShape();
            mockScene.textureMode(NORMAL);
            mockScene.textureWrap(REPEAT);
            mockScene.texture(display.getImg("pixelrealm-grass-legacy"));
            
            PVector v1 = new PVector((tilex-1.)*groundSize, 0f, (tilez-1.)*groundSize);          // Left, top
            PVector v2 = new PVector((tilex)*groundSize, 0f,  (tilez-1.)*groundSize);          // Right, top
            PVector v3 = new PVector((tilex)*groundSize, 0f,  (tilez)*groundSize);          // Right, bottom
            PVector v4 = new PVector((tilex-1.)*groundSize, 0f,  (tilez)*groundSize);          // Left, bottom
            
            mockScene.vertex(v1.x, v1.y, v1.z, 0, 0);                                    
            mockScene.vertex(v2.x, v2.y, v2.z, 2, 0);  
            mockScene.vertex(v3.x, v3.y, v3.z, 2, 2);  
            mockScene.vertex(v4.x, v4.y, v4.z, 0, 2);       
  
            mockScene.endShape();
          }
        }
      }
      mockScene.noTint();
      mockScene.fill(255);
      
      renderObjects();
      
      mockScene.endDraw();
      
  
      mockScene.popMatrix();
    }
    
    private void renderObjects() {
      mockScene.beginShape(QUADS);
      mockScene.texture(display.getImg("pixelrealm-terrain_object-legacy"));
      //mockScene.fill(255);
      mockScene.pushMatrix();
      //mockScene.translate(-input.mouseX(), 0f, -input.mouseY());
      mockScene.tint(255, 9.856995);
      mockScene.vertex(852.4165, -279.81158, -1418.4941, 0.999, 0.0);
      mockScene.vertex(1142.228, -279.81158, -1418.4941, 0.0, 0.0);
      mockScene.vertex(1142.228, 10.0, -1418.4941, 0.0, 0.999);
      mockScene.vertex(852.4165, 10.0, -1418.4941, 0.999, 0.999);
      mockScene.tint(255, 11.663315);
      mockScene.vertex(1254.8113, -273.69412, -1019.15796, 0.999, 0.0);
      mockScene.vertex(1538.5056, -273.69412, -1019.15796, 0.0, 0.0);
      mockScene.vertex(1538.5056, 10.0, -1019.15796, 0.0, 0.999);
      mockScene.vertex(1254.8113, 10.0, -1019.15796, 0.999, 0.999);
      mockScene.tint(255, 20.580292);
      mockScene.vertex(-1094.7216, -144.77814, 1366.8511, 0.999, 0.0);
      mockScene.vertex(-939.9435, -144.77814, 1366.8511, 0.0, 0.0);
      mockScene.vertex(-939.9435, 10.0, 1366.8511, 0.0, 0.999);
      mockScene.vertex(-1094.7216, 10.0, 1366.8511, 0.999, 0.999);
      mockScene.tint(255, 80.44942);
      mockScene.vertex(-1569.7898, -336.5367, -612.3378, 0.999, 0.0);
      mockScene.vertex(-1223.2532, -336.5367, -612.3378, 0.0, 0.0);
      mockScene.vertex(-1223.2532, 10.0, -612.3378, 0.0, 0.999);
      mockScene.vertex(-1569.7898, 10.0, -612.3378, 0.999, 0.999);
      mockScene.tint(255, 104.15323);
      mockScene.vertex(-1099.9895, -158.2349, -1031.6885, 0.999, 0.0);
      mockScene.vertex(-931.75464, -158.2349, -1031.6885, 0.0, 0.0);
      mockScene.vertex(-931.75464, 10.0, -1031.6885, 0.0, 0.999);
      mockScene.vertex(-1099.9895, 10.0, -1031.6885, 0.999, 0.999);
      mockScene.tint(255, 121.6434);
      mockScene.vertex(-313.464, -192.6547, 1372.0471, 0.999, 0.0);
      mockScene.vertex(-110.809204, -192.6547, 1372.0471, 0.0, 0.0);
      mockScene.vertex(-110.809204, 10.0, 1372.0471, 0.0, 0.999);
      mockScene.vertex(-313.464, 10.0, 1372.0471, 0.999, 0.999);
      mockScene.tint(255, 178.64462);
      mockScene.vertex(852.4165, -279.81158, -618.4941, 0.999, 0.0);
      mockScene.vertex(1142.228, -279.81158, -618.494, 0.0, 0.0);
      mockScene.vertex(1142.228, 10.0, -618.494, 0.0, 0.999);
      mockScene.vertex(852.4165, 10.0, -618.4941, 0.999, 0.999);
      mockScene.tint(255, 181.92719);
      mockScene.vertex(-1139.1392, -258.2411, 579.165, 0.999, 0.0);
      mockScene.vertex(-870.89813, -258.2411, 579.165, 0.0, 0.0);
      mockScene.vertex(-870.89813, 10.0, 579.165, 0.0, 0.999);
      mockScene.vertex(-1139.1392, 10.0, 579.165, 0.999, 0.999);
      mockScene.tint(255, 185.11197);
      mockScene.vertex(-688.7383, -129.4941, 965.19244, 0.999, 0.0);
      mockScene.vertex(-549.24414, -129.4941, 965.19244, 0.0, 0.0);
      mockScene.vertex(-549.24414, 10.0, 965.19244, 0.0, 0.999);
      mockScene.vertex(-688.7383, 10.0, 965.19244, 0.999, 0.999);
      mockScene.tint(255, 220.32867);
      mockScene.vertex(94.99255, -171.05307, 969.7027, 0.999, 0.0);
      mockScene.vertex(276.04553, -171.05307, 969.7027, 0.0, 0.0);
      mockScene.vertex(276.04553, 10.0, 969.7027, 0.0, 0.999);
      mockScene.vertex(94.99255, 10.0, 969.7027, 0.999, 0.999);
      mockScene.tint(255, 252.50594);
      mockScene.vertex(500.17358, -157.81845, 568.2664, 0.999, 0.0);
      mockScene.vertex(667.99194, -157.81845, 568.2664, 0.0, 0.0);
      mockScene.vertex(667.99194, 10.0, 568.2664, 0.0, 0.999);
      mockScene.vertex(500.17358, 10.0, 568.2664, 0.999, 0.999);
      mockScene.tint(255, 255);
      mockScene.vertex(-696.7269, -149.90054, -232.59293, 0.999, 0.0);
      mockScene.vertex(-536.8263, -149.90054, -232.59293, 0.0, 0.0);
      mockScene.vertex(-536.8263, 10.0, -232.59293, 0.0, 0.999);
      mockScene.vertex(-696.7269, 10.0, -232.59293, 0.999, 0.999);
      mockScene.tint(255, 255);
      mockScene.vertex(-422.34216, -470.7794, 602.23114, 0.999, 0.0);
      mockScene.vertex(58.437134, -470.7794, 602.23114, 0.0, 0.0);
      mockScene.vertex(58.437134, 10.0, 602.23114, 0.0, 0.999);
      mockScene.vertex(-422.34216, 10.0, 602.23114, 0.999, 0.999);
      mockScene.tint(255, 255);
      mockScene.vertex(59.6792, -261.2592, 579.4925, 0.999, 0.0);
      mockScene.vertex(330.93848, -261.2592, 579.4925, 0.0, 0.0);
      mockScene.vertex(330.93848, 10.0, 579.4925, 0.0, 0.999);
      mockScene.vertex(59.6792, 10.0, 579.4925, 0.999, 0.999);
      mockScene.endShape();
      mockScene.flush();
      
      display.shader(mockScene, "portal_plus", "u_time", display.getTimeSecondsLoop(), "u_dir", -direction/(PI*2));
      mockScene.beginShape(QUADS);
      mockScene.texture(display.getImg("white"));
      mockScene.vertex(-152.54541, -224.0, 391.89288, 0.999, 0.0);
      mockScene.vertex(-24.54541, -224.0, 391.89288, 0.0, 0.0);
      mockScene.vertex(-24.54541, 0.0, 391.89288, 0.0, 0.999);
      mockScene.vertex(-152.54541, 0.0, 391.89288, 0.999, 0.999);
      mockScene.endShape();
      mockScene.flush();
      
      mockScene.resetShader();
      mockScene.beginShape(QUADS);
      mockScene.texture(display.getImg("pixelrealm-terrain_object-legacy"));
      mockScene.tint(255, 255);
      mockScene.vertex(-324.22778, -220.15033, -224.96893, 0.999, 0.0);
      mockScene.vertex(-94.07739, -220.15033, -224.96893, 0.0, 0.0);
      mockScene.vertex(-94.07739, 10.0, -224.96893, 0.0, 0.999);
      mockScene.vertex(-324.22778, 10.0, -224.96893, 0.999, 0.999);
      mockScene.tint(255, 255);
      mockScene.vertex(28.769653, -340.21637, 188.06152, 0.999, 0.0);
      mockScene.vertex(378.98608, -340.21637, 188.06152, 0.0, 0.0);
      mockScene.vertex(378.98608, 10.0, 188.06152, 0.0, 0.999);
      mockScene.vertex(28.769653, 10.0, 188.06152, 0.999, 0.999);
      
      mockScene.endShape();
      mockScene.popMatrix();
    }
    
    private float calculateFade(float dist, float fadeDist) {
      float d = (dist-fadeDist);
      float scale = (5./PApplet.pow(groundSize, 1.8));
      return 255-(d*scale);
    }
    
    private void setPerspective() {
      float fovx = radians(getSliderField("field_of_view").getVal());
      float fovy = (float)mockScene.width/mockScene.height;
      mockScene.perspective(fovx, fovy, 10f, 1000000.);
    }
    
}




public class KeybindSettingsScreen extends ReadOnlyEditor {
  public final static String KEYBIND_SETTING_PATH        = "engine/entryscreens/keybindSettings.timewayentry";
  public final static String KEYBIND_SETTING_PATH_PHONE  = "engine/entryscreens/keybindSettings_phone.timewayentry";
  
  // When set to true, a prompt asking the user to enter a key or click will appear,
  // which appears when changing a keybinding.
  private boolean enterInputPrompt = false;
  private boolean resetPrompt = false;
  private String settingKey = "";
  
  // Technically, the settings and this code is so bad because it's redundant and doing things like changing
  // the default controls means you need to change all instances of the controls used, PLUS you need to change
  // the code here. 
  // Bad coding practice, but I can't really see a way around it with the current system, and quite frankly, it
  // isn't my top priority to keep this part of the code redundant-proof.
  // It is, somehow, my priority to type long comments like this tho.
  private String[] keybindings = {
      "move_forward",
      "move_backward",
      "move_right",
      "move_left",
      "turn_right",
      "turn_left",
      "dash",
      "search",
      "jump",
      "primary_action",
      "secondary_action",
      "menu",
      "inventory_select_right",
      "inventory_select_left",
      "next_subtool",
      "prev_subtool",
      "scale_up",
      "scale_down",
      "prev_directory",
      "move_slow",
      "open_pocket"
  };
  
  private char[] defaultBindings = {
      'w',
      's',
      'd',
      'a',
      'e',
      'q',
      TWEngine.InputModule.CTRL_KEY,
      '\n',
      ' ',
      'o',
      'p',
      '\t',
      '.',
      ',',
      ']',
      '[',
      '=',
      '-',
      '\b',
      TWEngine.InputModule.SHIFT_KEY,
      'i'
  };
  
  // Duplicate code but whatever.
  protected ButtonPlaceable getButton(String name) {
    if (!placeableset.containsKey(name)) {
      console.warn("Setting "+name+" not found.");
      return new ButtonPlaceable("null");
    }
    try {
      return (ButtonPlaceable)get(name);
    }
    catch (ClassCastException e) {
      console.bugWarn(name+" Wrong access type (trying to access ButtonPlaceable but is "+get(name).getClass().getSimpleName());
      return new ButtonPlaceable("null");
    }
  }
  
  public KeybindSettingsScreen(TWEngine engine) {
    //super(engine, engine.display.phoneMode ? engine.APPPATH+CREDITS_PATH_PHONE : engine.APPPATH+CREDITS_PATH);
    super(engine, engine.APPPATH+KEYBIND_SETTING_PATH, true, false);
    loadSettings();
  }
  
  private void loadSettings() {
    for (int i = 0; i < keybindings.length; i++) {
      getButton(keybindings[i]).text = input.keyTextForm(settings.getKeybinding(keybindings[i], defaultBindings[i]));
    }
  }
  
  public void content() {
    power.setAwake();
    super.content();

    app.fill(255);
    app.textFont(engine.DEFAULT_FONT, 24);
    app.textAlign(CENTER, CENTER);
    if (enterInputPrompt) {
      ui.useSpriteSystem(readonlyEditorUI);
      //readonlyEditorUI.interactable = true;
      readonlyEditorUI.sprite("keybinding_prompt_back", "black");
      float x = readonlyEditorUI.getSprite("keybinding_prompt_back").getX();
      float y = readonlyEditorUI.getSprite("keybinding_prompt_back").getY();
      app.text("Enter key or mouse input...", x+300f, y+80f);
      
      if (display.getTimeSeconds() % 1f < 0.5f) {
        display.imgCentre("keybinding_1_128", x+300f, y+130f);
      }
      else {
        display.imgCentre("keybinding_2_128", x+300f, y+130f);
      }
      
      if (input.anyKeyOnce()) {
        enterInputPrompt = false;
        settings.setKeybinding(settingKey, input.getLastKeyPressed());
        getButton(settingKey).text = input.keyTextForm(input.getLastKeyPressed());
      }
      else if (input.primaryOnce) {
        enterInputPrompt = false;
        settings.setKeybinding(settingKey, TWEngine.InputModule.LEFT_CLICK);
        getButton(settingKey).text = "Left click";
      }
      else if (input.secondaryOnce) {
        enterInputPrompt = false;
        settings.setKeybinding(settingKey, TWEngine.InputModule.RIGHT_CLICK);
        getButton(settingKey).text = "Right click";
      }
    }
    else if (resetPrompt) {
      ui.useSpriteSystem(readonlyEditorUI);
      //readonlyEditorUI.interactable = true;
      readonlyEditorUI.sprite("keybinding_reset_back", "black");
      float x = readonlyEditorUI.getSprite("keybinding_reset_back").getX();
      float y = readonlyEditorUI.getSprite("keybinding_reset_back").getY();
      app.text("Are you sure you want to reset to defaults?\nThis cannot be undone.", x+315f, y+50f);
      
      if (ui.buttonVary("keybindings_reset_yes", "tick_128", "Yes")) {
        sound.playSound("select_general");
        resetPrompt = false;
        for (int i = 0; i < keybindings.length; i++) {
          settings.setKeybinding(keybindings[i], defaultBindings[i]);
          getButton(keybindings[i]).text = input.keyTextForm(defaultBindings[i]);
        }
        console.log("Reset keybindings.");
      }
      if (ui.buttonVary("keybindings_reset_no", "cross_128", "No")) {
        sound.playSound("select_any");
        resetPrompt = false;
      }
    }
    else {
      for (int i = 0; i < keybindings.length; i++) {
        if (getButton(keybindings[i]).clicked) {
          sound.playSound("select_any");
          settingKey = keybindings[i];
          enterInputPrompt = true;
        }
      }
      
      if (getButton("reset_button").clicked) {
        sound.playSound("select_general");
        resetPrompt = true;
      }
    }
  }
  
  public void endScreenAnimation() {
    
  }
  
  protected boolean customCommands(String command) {
    if (command.equals("/edit")) {
      console.log("Editing settings.");
      requestScreen(new Editor(engine, display.phoneMode ? engine.APPPATH+KEYBIND_SETTING_PATH_PHONE : engine.APPPATH+KEYBIND_SETTING_PATH));
      return true;
    }
    else return false;
  }
}
