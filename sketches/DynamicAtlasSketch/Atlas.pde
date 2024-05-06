
import java.nio.IntBuffer;

private PGL pgl;
private PShader atlasShader;
private int currentBoundAtlas = 0;
private PGraphics currentPG;

// idk 8 seems enough for now.
DynamicTextureAtlas[] atlases = new DynamicTextureAtlas[8];

// Things we gotta add:
// 1. Using multiple atlases when we run out of space    DONE

// 2. Allow rendering to multiple PGraphics canvases   DONE

// 3. Repeat texture wrap mode    DONE

// 4. Large images    DONE

final static int UNLOCK_THRESHOLD = 9000000;
    
public class DynamicTextureAtlas {
      private int glTexID = 0;
      private IntBuffer texData;
      public int[][] stencilAlloc;
      
      // Keeps track of how many pixels have filled the atlas.
      private int pixelsFill = 0;
      
      // Once a random allocation fails in this atlas,
      // a new atlas will be used and this one will be marked as "locked"
      // to prevent new textures being written to it until textures have been removed
      // such that the pixelsFill < UNLOCK_THRESHOLD.
      private boolean locked = false;
      
      private boolean needsUpdating = false;
      
      static final int TEX_WIDTH = 4096;
      static final int TEX_HEIGHT = 4096;
      
      public DynamicTextureAtlas() {
        init();
        if (atlasShader == null) {
          atlasShader = loadShader("frag.glsl", "vert.glsl");
          atlasShader.init();
        }
      }
      
      // Returns whether or not its locked, and checks the pixel fill just
      // to make sure if it can be unlocked.
      public boolean unlocked() {
        // If locked, check if enough textures have been removed since being locked.
        if (locked) {
          if (pixelsFill < UNLOCK_THRESHOLD) {
            locked = false;
            return true;
          }
          else {
            return false;
          }
        }
        
        // Not locked so return true;
        return true;
      }
      
    
      void init() {
        pgl = currentPG.beginPGL();
        IntBuffer intBuffer = IntBuffer.allocate(1);
        pgl.genTextures(1, intBuffer);
        glTexID = intBuffer.get(0);
      
        texData = IntBuffer.allocate(TEX_WIDTH*TEX_HEIGHT);
        stencilAlloc = new int[TEX_HEIGHT][(TEX_WIDTH/32)];  // ints are 32 bits wide.
        
        // Clear it out with black pixels
        for (int i = 0; i < TEX_WIDTH*TEX_HEIGHT; i++) {
          texData.put(i, 0xFF000000);
        }
        
        // Clear allocation stencil buffer to no allocation anywhere.
        for (int y = 0; y < stencilAlloc.length; y++) {
          for (int x = 0; x < stencilAlloc[0].length; x++) {
            stencilAlloc[y][x] = 0;
          }
        }
        
        // Put it into GPU memory
        texData.rewind();
        //long before = System.nanoTime();
        pgl.activeTexture(PGL.TEXTURE0);
        pgl.bindTexture(PGL.TEXTURE_2D, glTexID);
        pgl.texImage2D(PGL.TEXTURE_2D, 0, PGL.RGBA, TEX_WIDTH, TEX_HEIGHT, 0, PGL.RGBA, PGL.UNSIGNED_BYTE, texData);
        
        //pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MAG_FILTER, PGL.NEAREST);
        //pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MIN_FILTER, PGL.NEAREST);
        pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MAG_FILTER, PGL.LINEAR);
        pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MIN_FILTER, PGL.LINEAR_MIPMAP_LINEAR);
        //println("texImage2D time: "+str((System.nanoTime()-before)/1000)+"us");
        currentPG.endPGL();
      }
      
      // The atlas is dynamic so this means new textures can be added to it on the fly.
      // To do this, we need to neatly find a spot for each texture in the atlas.
      
      // There are 3 operations based on operations:
      // 1.  Clear space tracker (CST); when used area < n, we save the next available space using cursors.
      // 2.  Random pos: When used area >= n, pick random coordinates and check area is clear.
      //     We can later do a bit of optimisation to tightly pack the image to the next image instead of having small bubbles.
      // 2.5 (maybe) move to a different atlas/texture unit if we have enough slots and/or spare processing time.
      // 3.  Linearly search; If the number of random positions we do > threshold, linearly search the entire atlas, top to bottom.
      //     The least efficient method, but basically guarenteed way of finding a spot, if there's any spot large enough in the atlas.
      
      private int cursorTrackerX = 0;
      private int cursorTrackerY = 0;
      private int trackerMaxHeight = 0;
      
      // Expensive check space operation.
      private boolean checkSpace(int startx, int starty, int w, int h) {
        int endx = (startx+w)/32;
        int endy = starty+h;
        
        // Create a line
        int line[] = new int[TEX_WIDTH/32];
        int l = startx+w;
        for (int i = startx; i < l; i++) {
          line[i/32] |= 1 << (i%32);
        }
        
        // Definite nope.
        if (endx > TEX_WIDTH/32 || endy > TEX_HEIGHT) {
          return false;
        }
        
        startx /= 32;
        for (int y = starty; y < endy; y++) {
          for (int x = startx; x < endx; x++) {
            
            if (stencilAlloc[y][x] == 0) {
            }
            else if ((stencilAlloc[y][x] & line[x]) == 0) {
            }
            else return false;
          }
        }
        return true;
      }
      
      // Fastest, not guarenteed to find a space
      private int[] findSpaceUsingTracker(int w, int h) {
        println("Using tracker");
        //int ctx = cursorTrackerX-cursorTrackerX%32+32;
        int ctx = cursorTrackerX;
        int cty = cursorTrackerY;
        
        if (ctx+w > TEX_WIDTH) {
          cty += trackerMaxHeight;
          trackerMaxHeight = 0;
          ctx = 0;
        }
        if (cty+h > TEX_HEIGHT) {
          // There is no longer any space at that point.
          return null;
        }
        
        boolean found = checkSpace(ctx, cty, w, h);
        int[] ret = {ctx, cty};
        
        if (found) {
          ctx += w;
          cursorTrackerX = ctx;
          cursorTrackerY = cty;
          // Max height so that we can squeeze texture more efficiently
          // and increase chances of tracker search being successful.
          if (h > trackerMaxHeight) {
            trackerMaxHeight = h;
          }
        }
        // Space that we expected to be empty is taken.
        else {
          println("Tracker failed to find at ", ctx, cty, w, h);
          return null;
        }
        
        
        println("Tracker found ", ctx, cty, w, h);
        return ret;
      }
      
      // Not the fastest but good for finding a space when densely populated.
      private int[] findSpaceUsingRandom(int w, int h, int numAttempts) {
        
        // Select random spaces and see if there's a free space in that spot.
        for (int i = 0; i < numAttempts; i++) {
          int x = int(random(0, TEX_WIDTH-w));
          int y = int(random(0, TEX_HEIGHT-h));
          
          if (checkSpace(x, y, w, h)) {
            // TODO: find the closest next texture so we can tightly place the image next to it
            // minimizing space bubbles.
            int[] ret = {x, y};
            println("Random found ", x, y, w, h, "after", i, "attempts");
            return ret;
          }
        }
        
        // Give up after a certain number of attempts.
        System.err.println("Random failed to find");
        return null;
      }
      
      private int[] findSpaceUsingRandom(int w, int h) {
        // Idk let's try 128 for a start.
        return findSpaceUsingRandom(w, h, 128);
      }
      
      // Slowest, almost guarenteed to find a space.
      // TODO: Implement (eventually), it's so slow that I don't
      // see much point in doing it.
      //private int[] findSpaceLinear() {
      //  return new int[2];
      //}
      
      // Returns 4 floats of the top-left and bottom-right uv coords  
      public UVImage addNow(PImage img, float repeatX, float repeatY, boolean grayScale) {
        int w = int((float)img.width*repeatX);
        int h = int((float)img.height*repeatY);
        
        // We need to find a space.
        // Use seperate algorithms in an attempt to find a space.
        // 1. tracker
        int[] pos = findSpaceUsingTracker(w, h);
        // Attempt failed, try different algorithm.
        if (pos == null) {
          pos = findSpaceUsingRandom(w, h);
          
          // Too many attempts made.
          if (pos == null) {
            // If searching for a random spot fails, we consider the atlas to be full
            // and lock it so no further textures are added until the pixel fill is reduced.
            locked = true;
            return null;
          }
          else {
            // Maybe there's a free space after the random space we found.
            // Let's update the tracker variables!
            cursorTrackerX = pos[0]+w;
            cursorTrackerY = pos[1];
            
            if (cursorTrackerX > TEX_WIDTH) {
              // idk place it under it doesnt matter.
              cursorTrackerY += trackerMaxHeight;
              trackerMaxHeight = 0;
              cursorTrackerX = pos[0];
            }
          }
        }
        
        // At this point we should have a free space pos.
        
        
        // Write the texture data in the space we just found.
        int endx = pos[0]+w;
        int endy = pos[1]+h;
        img.loadPixels();
        int imx = 0;
        int imy = 0;
        texData.rewind();
        for (int y = pos[1]; y < endy; y++) {
          for (int x = pos[0]; x < endx; x++) {
            // This weird pixel access sum basically gets the pixel at the x and y position, wrapping back round
            // every time the coords cross the width and height.
            int c = img.pixels[(imy%(img.height-1))*img.width+(imx%(img.width-1))];
            int a = c >> 24 & 0xFF;
            int r = c >> 16 & 0xFF;
            int g = c >> 8 & 0xFF;
            int b = c & 0xFF;
            //a << 24 | b << 16 | g << 8 | r
            // Ordering is: ABGR
            // TODO: alpha seems to mess things up?
            if (grayScale) {
              
              texData.put(TEX_WIDTH*y + x,  b << 24 | b << 16 | b << 8 | b);
            }
            else {
              texData.put(TEX_WIDTH*y + x, ( a << 24 |  b << 16 | g << 8 | r));
            }
            // Update stencil allocation buffer too by the bit.
            stencilAlloc[y][x/32] |= 1 << (x%32);
            imx++;
          }
          imy++;
          imx = 0;
        }
        texData.rewind();
        needsUpdating = true;
        
        // Update pixels fill.
        pixelsFill += w*h;
        println("(increase) pixels used now: "+pixelsFill);
        
        UVImage newImg = new UVImage(
          (float)pos[0]/float(TEX_WIDTH),
          (float)pos[1]/float(TEX_HEIGHT),
          (float)(pos[0]+img.width)/float(TEX_WIDTH),
          (float)(pos[1]+img.height)/float(TEX_HEIGHT)
        );
        newImg.width = (float)img.width;
        newImg.height = (float)img.height;
        newImg.atlasUVx1 = pos[0];
        newImg.atlasUVy1 = pos[1];
        // Remember, w and h take into account the repeat.
        newImg.atlasUVx2 = pos[0]+w;
        newImg.atlasUVy2 = pos[1]+h;
        
        return newImg;
      }
      
      void update() {
        // Only update if necessary to save performance.
        if (needsUpdating) {
          pgl = currentPG.beginPGL();
          pgl.activeTexture(PGL.TEXTURE0);
          pgl.bindTexture(PGL.TEXTURE_2D, glTexID);
          pgl.texImage2D(PGL.TEXTURE_2D, 0, PGL.RGBA, TEX_WIDTH, TEX_HEIGHT, 0, PGL.RGBA, PGL.UNSIGNED_BYTE, texData);
          
          pgl.generateMipmap(PGL.TEXTURE_2D);
          currentPG.endPGL();
          needsUpdating = false;
        }
      }
      
      public void clear(UVImage img) {
        int startx = img.atlasUVx1;
        int starty = img.atlasUVy1;
        int endx = img.atlasUVx2;
        int endy = img.atlasUVy2;
        
        for (int y = starty; y < endy; y++) {
          for (int x = startx; x < endx; x++) {
            stencilAlloc[y][x/32] &= 0xFFFFFFFE << (x%32);
          }
        }
        // Clear pixels fill.
        pixelsFill -= (endx-startx)*(endy-starty);
        println("(decrease) pixels used now: "+pixelsFill);
        
        // No need to set needsUpdating because we haven't modified the actual GPU texture memory,
        // just the stencil which resides on the CPU side.
      }
      
      // This is a little tricky because we can't track openGL calls and we want to
      // prioritise performance, we need to call bind() each time we begin to use the
      // atlas.
      public void bind() {
        pgl = currentPG.beginPGL();
        pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MAG_FILTER, PGL.NEAREST);
        pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MIN_FILTER, PGL.NEAREST);
        pgl.activeTexture(PGL.TEXTURE0);
        pgl.bindTexture(PGL.TEXTURE_2D, glTexID);
        currentPG.endPGL();
      }
      
      public void image(UVImage img, float x, float y, float w, float h) {
        currentPG.pushMatrix();
        currentPG.translate(x, y);
        currentPG.scale(w, h);
        //img.display();
        
        // Convert to 0.0-1.0 values.
        // Prolly could be optimised.
        // TODO: optimise UV updating
        float uvx1 = (img.width*img.uvx1)/float(TEX_WIDTH);
        float uvy1 = (img.height*img.uvy1)/float(TEX_HEIGHT);
        float uvx2 = (img.width*(img.uvx2-1.))/float(TEX_WIDTH);
        float uvy2 = (img.height*(img.uvy2-1.))/float(TEX_HEIGHT);
        
        
        currentPG.beginShape(QUADS);
        currentPG.noStroke();
        currentPG.vertex(0, 0, img.startx+uvx1, img.starty+uvy1);
        currentPG.vertex(1, 0, img.endx+uvx2, img.starty+uvy1);
        currentPG.vertex(1, 1, img.endx+uvx2, img.endy+uvy2);
        currentPG.vertex(0, 1, img.startx+uvx1, img.endy+uvy2);
        currentPG.endShape();
        
        currentPG.popMatrix();
      }
}
    
public abstract class FastImage {
  public float width = 0, height = 0;
  public float uvx1 = 0.;
  public float uvy1 = 0.;
  public float uvx2 = 1.;
  public float uvy2 = 1.;
  
  public void setUV(float uvx1, float uvy1, float uvx2, float uvy2) {
    this.uvx1 = uvx1;
    this.uvy1 = uvy1;
    this.uvx2 = uvx2;
    this.uvy2 = uvy2;
  }
}


public void usePGraphics(PGraphics pg) {
  if (!(pg instanceof PGraphicsOpenGL)) {
    println("usePGraphics: PGraphics must be of type OpenGL (P2D/P3D)");
    return;
  }
  currentPG = pg;
}

// Image that stores texture data in a single texture atlas.
// This class stores the location of the image in the UV atlas as UV coordinates.
// Renders smaller images really quickly.
public class UVImage extends FastImage {
  public float startx, starty, endx, endy;
  public int atlasID = 0;
  private PShape shape;
  
  public int atlasUVx1 = 0;
  public int atlasUVy1 = 0;
  public int atlasUVx2 = 0;
  public int atlasUVy2 = 0;
  
  //private boolean allocated = false;
  
  public UVImage(float[] uvs, int atlasID) {
    this.atlasID = atlasID;
    
    startx = uvs[0];
    starty = uvs[1];
    endx   = uvs[2];
    endy   = uvs[3];
  }
  
  public UVImage(float uv1, float uv2, float uv3, float uv4) {
    startx = uv1;
    starty = uv2;
    endx   = uv3;
    endy   = uv4;
  }
  
  //public void setUV(float uvx1, float uvy1, float uvx2, float uvy2) {
  //  this.uvx1 = uvx1;
  //  this.uvy1 = uvy1;
  //  this.uvx2 = uvx2;
  //  this.uvy2 = uvy2;
  //}
  
  public void display() {
    currentPG.shape(shape);
  }
  
  // We need to unallocate texture when the object 
  // is garbage collected.
  public void finalize() {
    destroyImage(this);
    println("Destroyed", startx, starty, endx, endy);
  }
}

    
private void bindAtlas(int id) {
  if (currentBoundAtlas != id) {
    atlases[id].bind();
    currentBoundAtlas = id;
  }
}

public void image(FastImage img, float x, float y, float w, float h) {
  if (img instanceof UVImage) {
    UVImage uvimg = (UVImage)img;
    bindAtlas(uvimg.atlasID);
    atlases[uvimg.atlasID].image(uvimg, x, y, w, h);
  }
  else if (img instanceof LargeImage) {
    LargeImage largeimg = (LargeImage)img;
    
    // Set to -1 so that any uvImages know to re-bind the atlas upon beginning rendering.
    currentBoundAtlas = -1;
    
    // Bind the texture
    pgl = currentPG.beginPGL();
    pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MAG_FILTER, PGL.NEAREST);
    pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MIN_FILTER, PGL.NEAREST);
    pgl.activeTexture(PGL.TEXTURE0);
    pgl.bindTexture(PGL.TEXTURE_2D, largeimg.glTexID);
    currentPG.endPGL();
    
    currentPG.pushMatrix();
    currentPG.translate(x, y);
    currentPG.scale(w, h);
    largeimg.display();
    currentPG.popMatrix();
  }
}

public void image(FastImage img, float x, float y) {
  image(img, x, y, img.width, img.height);
}

public void destroyImage(UVImage img) {
  atlases[img.atlasID].clear(img);
}


public UVImage createUVImage(PImage img) {
  return createUVImage(img, 1., 1., false);
}

public UVImage createUVImage(PImage img, float repeatX, float repeatY) {
  return createUVImage(img, repeatX, repeatY, false);
}

public UVImage createUVImage(PImage img, boolean monoChrome) {
  return createUVImage(img, 1., 1., monoChrome);
}

public UVImage createUVImage(PImage img, float repeatX, float repeatY, boolean monoChrome) {
  // Check each atlas for space.
  for (int i = 0; i < atlases.length; i++) {
    if (atlases[i] == null) {
      atlases[i] = new DynamicTextureAtlas();
    }
    
    
    if (atlases[i].unlocked()) {
      UVImage newImg = atlases[i].addNow(img, repeatX, repeatY, monoChrome);
      // Successful allocation; we have created a new texture
      if (newImg != null) {
        newImg.atlasID = i;
        active = i;
        println("Created new texture on atlas "+i);
        return newImg;
      }
      // Unsuccessful; the atlas is full, and has automatically been locked.
      // Move on to the next atlas.
      else {
        continue;
      }
  
    }
  }
  
  // If we're at this point, it means we've run out of texture memory.
  // We could perhaps try to optimise previous atlases at the cost of performance,
  // but that's a TODO. For now let's just give up all hope.
  throw new RuntimeException("Out of texture space.");
}

public void bind() {
  currentBoundAtlas = -1;
  currentPG.shader(atlasShader);
}

public void update() {
  for (int i = 0; i < atlases.length; i++) {
    if (atlases[i] != null) {
      // Each atlas will only update if necessary.
      atlases[i].update();
    }
  }
}
















// For images that are so large that they prolly don't fit in a texture atlas.
// Slower, but doesn't take up more memory than necessary.
// Needs to be in the same class that contains pgl.
public class LargeImage extends FastImage {
  public float width = 0, height = 0;
  public int glTexID = -1;
  private PShape shape;
  
  public LargeImage(int glTexID) {
    this.glTexID = glTexID;
    
    shape = currentPG.createShape();
    
    shape.beginShape(QUADS);
    //texture(grass);
    shape.noStroke();
    shape.vertex(0, 0, uvx1, uvy1);
    shape.vertex(1, 0, uvx2, uvx1);
    shape.vertex(1, 1, uvx2, uvy2);
    shape.vertex(0, 1, uvx1, uvy2);
    shape.endShape();
  }
  
  public void display() {
    // TODO: optimise UV updating
    //println(shape.getVertexCount());
    shape.beginTessellation();
    shape.setTextureUV(0, uvx1, uvy1);
    shape.setTextureUV(1, uvx2, uvy1);
    shape.setTextureUV(2, uvx2, uvy2);
    shape.setTextureUV(3, uvx1, uvy2);
    shape.endTessellation();
    currentPG.shape(shape);
  }
  
  public void finalize() {
    // TODO: OpenGL function call to clear texture from gpu mem
  }
}

LargeImage createLargeImage(PImage img) {
    IntBuffer data = IntBuffer.allocate(img.width*img.height);
    int glTexID = -1;
    
    // Copy pimage data to the intbuffer.
    
    img.loadPixels();
    data.rewind();
    int l = img.width*img.height;
    for (int i = 0; i < l; i++) {
      int c = img.pixels[i];
      int a = c >> 24 & 0xFF;
      int r = c >> 16 & 0xFF;
      int g = c >> 8 & 0xFF;
      int b = c & 0xFF;
      data.put(i, ( a << 24 |  b << 16 | g << 8 | r));
    }
    data.rewind();
    
    // Create the texture buffer and put data into gpu mem.
    pgl = currentPG.beginPGL();
    IntBuffer intBuffer = IntBuffer.allocate(1);
    pgl.genTextures(1, intBuffer);
    glTexID = intBuffer.get(0);
    pgl.activeTexture(PGL.TEXTURE0);
    pgl.bindTexture(PGL.TEXTURE_2D, glTexID);
    pgl.texImage2D(PGL.TEXTURE_2D, 0, PGL.RGBA, img.width, img.height, 0, PGL.RGBA, PGL.UNSIGNED_BYTE, data);
    pgl.generateMipmap(PGL.TEXTURE_2D);
    currentPG.endPGL();
    
    LargeImage largeimg = new LargeImage(glTexID);
    largeimg.width = img.width;
    largeimg.height = img.height;
    return largeimg;
}


Canvas stencilMapDisplay;
int active = 0;
void showStencilMap(float xx, float yy, float ww, float hh) {
  stencilMapDisplay.graphics.beginDraw();
  stencilMapDisplay.graphics.loadPixels();
  int w = stencilMapDisplay.graphics.width;
  int h = stencilMapDisplay.graphics.height;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      int atx = int((float(x)/float(w))*float(atlases[active].stencilAlloc[0].length));
      int aty = int((float(y)/float(h))*float(atlases[active].stencilAlloc.length));
      stencilMapDisplay.graphics.pixels[y*w+x] = (atlases[active].stencilAlloc[aty][atx]) == 0 ? color(0) : color(255);
    }
  }
  stencilMapDisplay.graphics.updatePixels();
  stencilMapDisplay.graphics.fill(127);
  stencilMapDisplay.graphics.textSize(32);
  stencilMapDisplay.graphics.textAlign(LEFT, TOP);
  stencilMapDisplay.graphics.text(active, 0, 0);
  stencilMapDisplay.graphics.endDraw();
  stencilMapDisplay.display(xx, yy, ww, hh);
}
