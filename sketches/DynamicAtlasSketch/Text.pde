

class TextRendererClone {
  public PFont textFont;
  protected char[] textBuffer = new char[8 * 1024];
  protected char[] textWidthBuffer = new char[8 * 1024];
  
  protected int textBreakCount;
  protected int[] textBreakStart;
  protected int[] textBreakStop;
  
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
  
  
  UVImage[] glyphs = new UVImage[65536];
  
  public TextRendererClone(PFont font) {
    textFont = font;
    setupGlyphs();
    
    textSize = 12;
    textLeading = 14;
    textAlign = LEFT;
    textMode = MODEL;
  }
  
  void setupGlyphs() {
    for (int i = 0; i < 1024; i++) {
      PFont.Glyph g = typewriter.getGlyph(char(i));
      if (g != null && g.image != null) {
        UVImage im = createUVImage(g.image, true);
        if (im != null) glyphs[i] = im;
      }
    }
    
    update();
    
    
  }
  
  public void textLeading(float leading) {
    textLeading = leading;
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
  
  
  public void text(String str, float x, float y, float z) {
      if (z != 0) translate(0, 0, z);  // slow!
  
      text(str, x, y);
  //    textZ = z;
  
      if (z != 0) translate(0, 0, -z);  // inaccurate!
    }
  
  
    public void text(char[] chars, int start, int stop,
                     float x, float y, float z) {
      if (z != 0) translate(0, 0, z);  // slow!
  
      text(chars, start, stop, x, y);
  //    textZ = z;
  
      if (z != 0) translate(0, 0, -z);  // inaccurate!
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
      UVImage glyphImage = glyphs[(int)ch];
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
  
          textCharModelImpl(glyphImage,
                            x1, y1, x2, y2);
        }
      } else if (ch != ' ' && ch != 127) {
        println("No glyph found for the " + ch + " (\\u" + PApplet.hex(ch, 4) + ") character");
      }
    }
  
  
    protected void textCharModelImpl(UVImage glyph,
                                     float x1, float y1,
                                     float x2, float y2) {
      image(glyph, x1, y1, x2-x1, y2-y1);     
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
  
  
    public void text(int num, float x, float y) {
      text(String.valueOf(num), x, y);
    }
  
  
    public void text(int num, float x, float y, float z) {
      text(String.valueOf(num), x, y, z);
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
    
    public void textAlign(int alignX, int alignY) {
      textAlign = alignX;
      textAlignY = alignY;
    }
    
    public float textWidth(char c) {
      textWidthBuffer[0] = c;
      return textWidthImpl(textWidthBuffer, 0, 1);
    }
                                 }
