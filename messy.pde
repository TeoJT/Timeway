import java.util.Iterator;   // Used by the stack class at the bottom
import java.util.Arrays;

//*********************Sprite Class****************************
// Now yes, I am aware that the code is a mess and there are many
// features inside of this class that go unused. This was ripped
// straight from SketchiePad. This is mainly placeholder code as
// to be able to have click+draggable objects.
// Its functionalities:
// 1. Create sprites simply by calling the sprite() method
// 2. Click and drag objects
// 3. Resize objects
// 4. Save the position of objects between closing and starting again
// 5. Move objects with code, but still allow the position to be updated when clicked+dragged.
public final class SpriteSystemPlaceholder {
        public HashMap<String, Integer> spriteNames;
        public ArrayList<Sprite> sprites;
        public Sprite selectedSprite;
        public Stack<Sprite> spritesStack;
        private int newSpriteX = 0, newSpriteY = 0, newSpriteZ = 0;
        public Sprite unusedSprite;
        public Engine engine;
        public PApplet app;
        public Engine.Console console;
        public boolean keyPressAllowed = true;
        public Click generalClick;
        public Stack<Sprite> selectedSprites;
        public String myPath;
        public boolean interactable = true;
        public boolean saveSpriteData = true;
        public boolean showAllWireframes = false;
        public boolean suppressSpriteWarning = false;
        public boolean repositionSpritesToScale = true;

        public String PATH_SPRITES_ATTRIB;
        public String APPPATH; 

        public final int SINGLE = 1;
        public final int DOUBLE = 2;
        public final int VERTEX = 3;
        public final int ROTATE = 4;   
        
        public float selectBorderTime = 0.;

        // Use this constructor for no saving sprite data.
        public SpriteSystemPlaceholder(Engine engine) {
            this(engine, "");
            saveSpriteData = false;
        } 

        // Default constructor.
        public SpriteSystemPlaceholder(Engine engine, String path) {
            this.engine = engine;
            spriteNames = new HashMap<String, Integer>();
            selectedSprites = new Stack<Sprite>(8192);
            sprites = new ArrayList<Sprite>();
            spritesStack = new Stack<Sprite>(128);
            unusedSprite = new Sprite("UNUSED");
            generalClick = new Click();
            selectedSprite = null;
            app = engine.app;
            console = engine.console;
            PATH_SPRITES_ATTRIB = engine.PATH_SPRITES_ATTRIB;
            APPPATH = engine.APPPATH;
            this.myPath = path;
        }

        
        class Click {
            private boolean dragging = false;
            private int clickDelay = 0;
            private boolean click = false;
            private boolean draggingEnd = false;
            
            public boolean isDragging() {
                return dragging;
            }
            
            public void update() {
                draggingEnd = false;
                if (!mousePressed && dragging) {
                dragging = false;
                draggingEnd = true;
                }
                if (clickDelay > 0) {
                clickDelay--;
                }
                if (!click && mousePressed) {
                click = true;
                clickDelay = 1;
                }
                if (click && !mousePressed) {
                click = false;
                }
            }
            
            public boolean draggingEnded() {
                return draggingEnd;
            }
            
            public void beginDrag() {
                if (mousePressed && clickDelay > 0) {
                dragging = true;
                }
            }
            
            public boolean clicked() {
                return (clickDelay > 0);
            }
            
            
        }
        class QuadVertices {
            public PVector v[] = new PVector[4];
            
            {
            v[0] = new PVector(0,0);
            v[1] = new PVector(0,0);
            v[2] = new PVector(0,0);
            v[3] = new PVector(0,0);
            }
            
            public QuadVertices() {
            
            }
            public QuadVertices(float xStart1,float yStart1,float xStart2,float yStart2,float xEnd1,float yEnd1,float xEnd2,float yEnd2) {
            v[0].set(xStart1, yStart1);
            v[1].set(xStart2, yStart2);
            v[2].set(xEnd1,   yEnd1);
            v[3].set(xEnd2,   yEnd2);
            }
        }
        
        // Added implements RedrawElement so that we can use sprite with ERS
        class Sprite {

            public String imgName = "";
            public String name;
            
            public float xpos, ypos, zpos;
            public int wi = 0, hi = 0;
            
            public QuadVertices vertex;
 
            
            public float defxpos, defypos, defzpos;
            public int defwi = 0, defhi = 0;
            public QuadVertices defvertex;
            public float defrot = HALF_PI;
            public float defradius = 100.; //radiusY = 50.;
            
            public float offxpos, offypos;
            public int offwi = 0, offhi = 0;
            public QuadVertices offvertex;
            public float offrot = HALF_PI;
            public float offradius = 100.; //radiusY = 50.;
            
            public int spriteOrder;
            public boolean allowResizing = true;
            
            public float repositionDragStartX;
            public float repositionDragStartY;
            public QuadVertices repositionV;
            public float aspect;
            public Click resizeDrag;
            public Click repositionDrag;
            public Click select;
            public int currentVertex = 0;
            public boolean hoveringOverResizeSquare = false;
            public boolean lock = false;
            public int lastFrameShown = 0;
            public float bop = 0.0;
            public int mode = SINGLE;
            public float rot = HALF_PI;
            public float radius = 100.; //radiusY = 50.;
            
            public float BOX_SIZE = 50;
            
            
            
            //Scale modes:
            //1 - pixel width height (int)
            //2 - scale multiplier (float)

            public Sprite(String name) {
                xpos = 0;
                ypos = 0;
                this.name = name;
                vertex = new QuadVertices();
                offvertex = new QuadVertices();
                defvertex = new QuadVertices();
                repositionV = new QuadVertices();
                resizeDrag     = new Click();
                repositionDrag = new Click();
                select         = new Click();
            }
            
            public void setOrder(int order) {
                this.spriteOrder = order;
            }
            
            public int getOrder() {
                return spriteOrder;
            }

            public float getBop() {
                return bop;
            }

            public void bop() {
                bop = 0.2;
            }

            public void bop(float b) {
                bop = b;
            }

            public void resetBop() {
                bop = 0.0;
            }
            
            public String getModeString() {
                switch (mode) {
                case SINGLE: //SINGLE
                return "SINGLE";
                case DOUBLE: //DOUBLE
                return "DOUBLE";
                case VERTEX: //VERTEX
                return "VERTEX";
                case ROTATE: //ROTATE
                return "ROTATE";
                default:
                return "SINGLE";
                }
            }
            
            public void setMode(int m) {
                this.mode = m;
            }
            
            public void setModeString(String m) {
                if (m.equals("SINGLE")) {
                mode = SINGLE;
                }
                else if (m.equals("DOUBLE")) {
                mode = DOUBLE;
                }
                else if (m.equals("VERTEX")) {
                mode = VERTEX;
                }
                else if (m.equals("ROTATE")) {
                mode = ROTATE;
                }
                else {
                mode = SINGLE;
                }
            }

            public String getName() {
                return this.name;
            }

            public void lock() {
                lock = true;
            }
            public void unlock() {
                lock = false;
            }
            public void poke(int f) {
                //rot += 0.05;
                bop *= 0.85;
                lastFrameShown = f;
            }
            public boolean beingUsed(int f) {
                return (f == lastFrameShown-1 || f == lastFrameShown || f == lastFrameShown+1);
            }
            public boolean isLocked() {
                return lock;
            }
            public void setImg(String name) {
                PImage im = engine.display.getImg(name);
                imgName = name;
                if (wi == 0) { 
                wi = (int)im.width;
                defwi = wi;
                }
                if (hi == 0) {
                hi = (int)im.height;
                defhi = hi;
                }
                aspect = float(im.height)/float(im.width);
            }

            public void move(float x, float y) {
                float oldX = xpos;
                float oldY = ypos;
                xpos = x;
                ypos = y;
                defxpos = x;
                defypos = y;
                
                //Vertex position
                for (int i = 0; i < 4; i++) {
                vertex.v[i].add(x-oldX, y-oldY);
                }
            }
            
            public void offmove(float x, float y) {
                float oldX = xpos;
                float oldY = ypos;
                offxpos = x;
                offypos = y;
                xpos = defxpos+x;
                ypos = defypos+y;
                
                for (int i = 0; i < 4; i++) {
                vertex.v[i].add(xpos-oldX, ypos-oldY);
                }
            }
            
            public void vertex(int v, float x, float y) {
                vertex.v[v].set(x, y);
                defvertex.v[v].set(x, y);
            }
            
            public void offvertex(int v, float x, float y) {
                offvertex.v[v].set(x, y);
                vertex.v[v].set(defvertex.v[v].x+x, defvertex.v[v].y+y);
            }

            public void setX(float x) {
                xpos = x;
                defxpos = x;
            }

            public void setY(float y) {
                ypos = y;
                defypos = y;
            }
            
            public void offsetX(float x) {
                offxpos = x;
                xpos = defxpos+x;
            }

            public void offsetY(float y) {
                offypos = y;
                ypos = defxpos+y;
            }

            public void setZ(float z) {
                zpos = z;
                defzpos = z;
            }

            public void setWidth(int w) {
                this.wi = w;
                defwi =   w;
            }

            public void setHeight(int h) {
                this.hi = h;
                defhi =   h;
            }
            
            public void offsetWidth(int w) {
                this.offwi = w;
                this.wi = defwi+w;
            }

            public void offsetHeight(int h) {
                this.offhi = h;
                this.hi = defhi+h;
            }

            public float getX() {
                return this.xpos;
            }

            public float getY() {
                return this.ypos;
            }

            public float getZ() {
                return this.zpos;
            }

            public int getWidth() {
                return this.wi;
            }

            public int getHeight() {
                return this.hi;
            }
            
            
            private boolean polyPoint(PVector[] vertices, float px, float py) {
                boolean collision = false;
            
                // go through each of the vertices, plus
                // the next vertex in the list
                int next = 0;
                for (int current=0; current<vertices.length; current++) {
            
                // get next vertex in list
                // if we've hit the end, wrap around to 0
                next = current+1;
                if (next == vertices.length) next = 0;
            
                // get the PVectors at our current position
                // this makes our if statement a little cleaner
                PVector vc = vertices[current];    // c for "current"
                PVector vn = vertices[next];       // n for "next"
            
                // compare position, flip 'collision' variable
                // back and forth
                if (((vc.y >= py && vn.y < py) || (vc.y < py && vn.y >= py)) &&
                    (px < (vn.x-vc.x)*(py-vc.y) / (vn.y-vc.y)+vc.x)) {
                        collision = !collision;
                }
                }
                return collision;
            }



            public boolean mouseWithinSquare() {
                switch (mode) {
                case SINGLE: {
                    float d = BOX_SIZE, x = (float)wi-d+xpos, y = (float)hi-d+ypos;
                    if (engine.mouseX() > x && engine.mouseY() > y && engine.mouseX() < x+d && engine.mouseY() < y+d) {
                      return true;
                    }
                }
                break;
                case DOUBLE: {
                  // width square
                    float d = BOX_SIZE, x1 = (float)wi-(d/2)+xpos, y1 = (float)(hi/2)-(d/2)+ypos;
                  // height square
                    float               x2 = (float)(wi/2)-(d/2)+xpos, y2 = (float)(hi)-(d/2)+ypos;
                    if ((engine.mouseX() > x1 && engine.mouseY() > y1 && engine.mouseX() < x1+d && engine.mouseY() < y1+d)
                    || (engine.mouseX() > x2 && engine.mouseY() > y2 && engine.mouseX() < x2+d && engine.mouseY() < y2+d)) {
                      return true;
                    }
                }
                break;
                case VERTEX: {
                    for (int i = 0; i < 4; i++) {
                    float d = BOX_SIZE;
                    float x = vertex.v[i].x;
                    float y = vertex.v[i].y;
                    if (engine.mouseX() > x-d/2 && engine.mouseY() > y-d/2 && engine.mouseX() < x+d/2 && engine.mouseY() < y+d/2) {
                        return true;
                    }
                    }
                }
                break;
                case ROTATE:
                //float decx = float(mouseX)-cx;
                //float decy = cy-float(mouseY);
                //if (decy < 0) {
                //  rot = atan(-decx/decy);
                //}
                //else {
                //  rot = atan(-decx/decy)+PI;
                //}
                float cx = xpos+wi/2, cy = ypos+hi/2;
                float d = BOX_SIZE;
                float x = cx+sin(rot)*radius,  y = cy+cos(rot)*radius;
                
                if (engine.mouseX() > x-d/2 && engine.mouseY() > y-d/2 && engine.mouseX() < x+d/2 && engine.mouseY() < y+d/2) {
                    return true;
                }
                break;
                default: {
                    d = BOX_SIZE;
                    x = (float)wi-d+xpos;
                    y = (float)hi-d+ypos;
                    if (engine.mouseX() > x && engine.mouseY() > y && engine.mouseX() < x+d && engine.mouseY() < y+d) {
                    return true;
                    }
                }
                break;
                }
                return false;
            }
            
            public float getRot() {
                return this.rot;
            }
            
            public void setRot(float r) {
                this.rot = r;
            }
            
            // hooo now that is some very incomplete code.
            // Don't use it, it doesn't work.
            public boolean rotateCollision() {
                float r = HALF_PI/2 + rot;
                float xr = radius;
                float yr = radius;
                float xd = xpos+float(wi)/2;
                float yd = ypos+float(hi)/2;
                float f = 0;
                if (wi > hi) {
                f = 1-(float(hi)/float(wi));
                }
                else if (hi > wi) {
                f = 1-(float(wi)/float(hi));
                }
                else {
                f = 0;
                }
                
                float x = sin(r+f)*xr + xd;
                float y = cos(r+f)*yr + yd;
                vertex.v[0].x = x;
                vertex.v[0].y = y;
                x = sin(r-f+HALF_PI)*xr + xd;
                y = cos(r-f+HALF_PI)*yr + yd;
                vertex.v[1].x = x;
                vertex.v[1].y = y;
                x = sin(r+f+PI)*xr + xd;
                y = cos(r+f+PI)*yr + yd;
                vertex.v[2].x = x;
                vertex.v[2].y = y;
                x = sin(r-f+HALF_PI+PI)*xr + xd;
                y = cos(r-f+HALF_PI+PI)*yr + yd;
                vertex.v[3].x = x;
                vertex.v[3].y = y;
                x = sin(r+f)*xr + xd;
                y = cos(r+f)*yr + yd;
                vertex.v[0].x = x;
                vertex.v[0].y = y;
                
                return polyPoint(vertex.v, engine.mouseX(), engine.mouseY());
            }
            
            
            public boolean mouseWithinSprite() {
                switch (mode) {
                case SINGLE: {
                    float x = xpos, y = ypos;
                    return (engine.mouseX() > x && engine.mouseY() > y && engine.mouseX() < x+wi && engine.mouseY() < y+hi);
                    //return (mouseX > x && mouseY > y && mouseX < x+wi && mouseY < y+hi && !repositionDrag.isDragging());
                }
                case DOUBLE: {
                    float x = xpos, y = ypos;
                    return (engine.mouseX() > x && engine.mouseY() > y && engine.mouseX() < x+wi && engine.mouseY() < y+hi);
                }
                case VERTEX:
                    return polyPoint(vertex.v, engine.mouseX(), engine.mouseY());
                case ROTATE: {
                    return rotateCollision();
                }
                    
                }
                return false;
            }
            
            public boolean mouseWithinHitbox() {
                return mouseWithinSprite() || mouseWithinSquare();
            }

            public boolean clickedOn() {
                return (mouseWithinHitbox() && repositionDrag.clicked());
            }
            
            // The sprite class ripped from Sketchiepad likes to sh*t out
            // json files whenever it's moved or anything. We don't want any
            // text placeable elements to do that. If a path wasn't provided
            // in the constructor we do NOT update the sprite data.
            public void updateJSON() {
                if (saveSpriteData) {
                    JSONObject attributes = new JSONObject();
                    
                    attributes.setString("name", name);
                    attributes.setString("mode", getModeString());
                    attributes.setBoolean("locked", this.isLocked());
                    attributes.setInt("x", (int)this.defxpos);
                    attributes.setInt("y", (int)this.defypos);
                    attributes.setInt("w", (int)this.defwi);
                    attributes.setInt("h", (int)this.defhi);
                    
                    for (int i = 0; i < 4; i++) {
                        attributes.setInt("vx"+str(i), (int)defvertex.v[i].x);
                        attributes.setInt("vy"+str(i), (int)defvertex.v[i].y);
                    }
                    
                    //resetDefaults();
                    
                    app.saveJSONObject(attributes, myPath+name+".json");
                }
            }
            
            public boolean isDragging() {
                return resizeDrag.isDragging() || repositionDrag.isDragging();
            }

            public void dragReposition() {
                boolean dragging = mouseWithinSprite() && !mouseWithinSquare();
                if (mode == VERTEX) {
                //dragging = mouseWithinSprite();
                }
                if (dragging && !repositionDrag.isDragging()) {
                repositionDrag.beginDrag();
                
                //X and Y position
                repositionDragStartX = this.xpos-engine.mouseX();
                repositionDragStartY = this.ypos-engine.mouseY();
                
                //Vertex position
                for (int i = 0; i < 4; i++) {
                    repositionV.v[i].set(vertex.v[i].x-engine.mouseX(), vertex.v[i].y-engine.mouseY());
                }
                }
                if (repositionDrag.isDragging()) {
                //X and y position
                this.xpos = repositionDragStartX+engine.mouseX();
                this.ypos = repositionDragStartY+engine.mouseY();
                
                defxpos = xpos-offxpos;
                defypos = ypos-offypos;
                
                //Vertex position
                for (int i = 0; i < 4; i++) {
                    vertex.v[i].set(repositionV.v[i].x+engine.mouseX(), repositionV.v[i].y+engine.mouseY());
                    defvertex.v[i].set(vertex.v[i].x-offvertex.v[i].x, vertex.v[i].y-offvertex.v[i].y);
                }
                }
                if (repositionDrag.draggingEnded()) {
                    updateJSON();
                }

                repositionDrag.update();
            }

            public boolean hoveringOverResizeSquare() {
                return this.hoveringOverResizeSquare;
            }

            public boolean hoveringVertex(float px, float py) {
                boolean collision = false;
                int next = 0;
                for (int current=0; current<vertex.v.length; current++) {

                // get next vertex in list
                // if we've hit the end, wrap around to 0
                next = current+1;
                if (next == vertex.v.length) next = 0;

                PVector vc = vertex.v[current];    // c for "current"
                PVector vn = vertex.v[next];       // n for "next"

                if ( ((vc.y > py) != (vn.y > py)) && (px < (vn.x-vc.x) * (py-vc.y) / (vn.y-vc.y) + vc.x) ) {
                    collision = !collision;
                }
                }

                return false;
            }

            public void resizeSquare() {
                switch (mode) {
                case SINGLE: {
                    float d = BOX_SIZE, x = (float)wi-d+xpos, y = (float)hi-d+ypos;
                    resizeDrag.update();
                    this.square(x,y, d);
                    if (engine.mouseX() > x && engine.mouseY() > y && engine.mouseX() < x+d && engine.mouseY() < y+d) {
                    resizeDrag.beginDrag();
                    this.hoveringOverResizeSquare = true;
                    } else {
                    this.hoveringOverResizeSquare = false;
                    }
                    if (resizeDrag.isDragging()) {
                    wi = int((engine.mouseX()+d/2-xpos));
                    hi = int((engine.mouseX()+d/2-xpos)*aspect);
                    
                    defwi = wi-offwi;
                    defhi = hi-offhi;
                    }
                    if (resizeDrag.draggingEnded()) {
                    updateJSON();
                    }
                }
                break;
                    
                    
                case DOUBLE: {
                  // width square
                    float d = BOX_SIZE, x1 = (float)wi-(d/2)+xpos, y1 = (float)(hi/2)-(d/2)+ypos;
                  // height square
                    float               x2 = (float)(wi/2)-(d/2)+xpos, y2 = (float)(hi)-(d/2)+ypos;
                    resizeDrag.update();
                    this.square(x1, y1, d);
                    this.square(x2, y2, d);
                    if (engine.mouseX() > x1 && engine.mouseY() > y1 && engine.mouseX() < x1+d && engine.mouseY() < y1+d) {
                      resizeDrag.beginDrag();
                      // whatever we're using currentVertex
                      currentVertex = 1;
                      this.hoveringOverResizeSquare = true;
                    } else if (engine.mouseX() > x2 && engine.mouseY() > y2 && engine.mouseX() < x2+d && engine.mouseY() < y2+d) {
                      resizeDrag.beginDrag();
                      // whatever we're using currentVertex
                      currentVertex = 2;
                      this.hoveringOverResizeSquare = true;
                    }
                    else {
                      this.hoveringOverResizeSquare = false;
                    }
                    
                    
                    if (resizeDrag.isDragging()) {
                      if (currentVertex == 1) {
                        wi = int((engine.mouseX()+d/2-xpos));
                      }
                      else if (currentVertex == 2) {
                        hi = int((engine.mouseY()+d/2-ypos));
                      }
                      
                      defwi = wi-offwi;
                      defhi = hi-offhi;
                    }
                    
                    if (resizeDrag.draggingEnded()) {
                      updateJSON();
                    }
                }
                break;
                
                case VERTEX: {
                    resizeDrag.update();
                    for (int i = 0; i < 4; i++) {
                      float d = BOX_SIZE;
                      float x = vertex.v[i].x;
                      float y = vertex.v[i].y;
                      this.square(x-d/2, y-d/2, d);
                      
                      if (engine.mouseX() > x-d/2 && engine.mouseY() > y-d/2 && engine.mouseX() < x+d/2 && engine.mouseY() < y+d/2) {
                          resizeDrag.beginDrag();
                          currentVertex = i;
                          this.hoveringOverResizeSquare = true;
                      } else {
                          this.hoveringOverResizeSquare = false;
                      }
                      if (resizeDrag.isDragging() && currentVertex == i) {
                          vertex.v[i].x = engine.mouseX();
                          vertex.v[i].y = engine.mouseY();
                          defvertex.v[i].set(vertex.v[i].x-offvertex.v[i].x, vertex.v[i].y-offvertex.v[i].y);
                      }
                    }
                    if (resizeDrag.draggingEnded()) {
                    updateJSON();
                    }
                }
                break;
                
                
                case ROTATE: {
                    resizeDrag.update();
                    float cx = xpos+wi/2, cy = ypos+hi/2;
                    float d = BOX_SIZE;
                    float x = cx+sin(rot)*radius,  y = cy+cos(rot)*radius;
                    
                    this.square(x-d/2, y-d/2, d);
                    
                    if (engine.mouseX() > x-d/2 && engine.mouseY() > y-d/2 && engine.mouseX() < x+d/2 && engine.mouseY() < y+d/2) {
                    resizeDrag.beginDrag();
                    this.hoveringOverResizeSquare = true;
                    } else {
                    this.hoveringOverResizeSquare = false;
                    }
                    
                    if (resizeDrag.isDragging()) {
                    float decx = (engine.mouseX())-cx;
                    float decy = cy-(engine.mouseY());
                    if (decy < 0) {
                        rot = atan(-decx/decy);
                    }
                    else {
                        rot = atan(-decx/decy)+PI;
                    }
                    
                    //float a = float(wi)/float(hi);
                    float s = sin(rot);//, c = a*-cos(rot);
                    if (s != 0.0) {
                        radius = decx/s;
                    }
                    
                    
                    }
                }
                break;
                    
                }
            }
            
            public void setRadius(float x) {
                radius = x;
            }
            
            public float getRadius() {
                return radius;
            }
            
            public void createVertices() {
                vertex.v[0].set(xpos, ypos);
                vertex.v[1].set(xpos+wi, ypos);
                vertex.v[2].set(xpos+wi, ypos+hi);
                vertex.v[3].set(xpos, ypos+hi);
                
                defvertex.v[0].set(xpos, ypos);
                defvertex.v[1].set(xpos+wi, ypos);
                defvertex.v[2].set(xpos+wi, ypos+hi);
                defvertex.v[3].set(xpos, ypos+hi);
            }

            private void square(float x, float y, float d) {
                noStroke();
                app.fill(sin(selectBorderTime += 0.1*engine.display.getDelta())*50+200, 100);
                app.rect(x, y, d, d);
            }
        }
        
        // New method added.
        // This is called at the start of screens so that things like GUI's can
        // be repositioned if there's different scaling.
        // Only does it on the x axis for now.
        public void repositionSpritesToScale() {
          repositionSpritesToScale = true;
        }

        private int totalSprites = 0;
        
        public Sprite getSprite(String name) {
            try {
            return sprites.get(spriteNames.get(name));
            }
            catch (NullPointerException e) {
                //if (!suppressSpriteWarning)
                //    console.bugWarn("Sprite "+name+" does not exist.");
                return unusedSprite;
            }
        }
  
        // What a confusing method name lol
        // We don't want to load or save from json for sprites like
        // placeables.
        public void updateSpriteFromJSON(Sprite s) throws NullPointerException {
            if (saveSpriteData) {
                JSONObject att = loadJSONObject(myPath+s.getName()+".json");
                s.move(att.getInt("x"), att.getInt("y"));
                s.setWidth(att.getInt("w"));
                s.setHeight(att.getInt("h"));
                
                s.setModeString(att.getString("mode"));
                if (att.getBoolean("locked")) {
                    s.lock();
                }
                
                for (int i = 0; i < 4; i++) {
                    s.vertex.v[i].set(att.getInt("vx"+str(i)), att.getInt("vy"+str(i)));
                    s.defvertex.v[i].set(att.getInt("vx"+str(i)), att.getInt("vy"+str(i)));
                }
            }
        }
        public void addSprite(String identifier, String img) {
            Sprite newSprite = new Sprite(identifier);
            newSprite.setImg(img);
            newSprite.setOrder(++totalSprites);
            addSprite(identifier, newSprite);
            try {
            updateSpriteFromJSON(newSprite);
            }
            catch (NullPointerException e) {
            newSprite.move(newSpriteX, newSpriteY);
            newSprite.setZ(newSpriteZ);
            newSpriteX += 20;
            newSpriteY += 20;
            newSpriteZ += 20;
            newSprite.createVertices();
            }
            
            // Added part: automatically offset if we need to reposition by scale.
            // TODO: This code has been disabled because it is buggy. It needs to be fixed.
            //if (repositionSpritesToScale) {
            //  if (engine.displayScale*0.5 >= 1.) newSprite.offsetX((newSprite.getX()/(engine.displayScale*0.5))-newSprite.getX());
            //  else newSprite.offsetX(newSprite.getX()-(newSprite.getX()/sqrt(engine.displayScale*2)));
            //}
        }
        private void addSprite(String name, Sprite sprite) {
            sprites.add(sprite);
            spriteNames.put(name, sprites.size()-1);
        }
        
        public Sprite spriteWithName(String name) {
            return sprites.get(spriteNames.get(name));
        }
        public void newSprite(String name) {
            Sprite sprite = new Sprite(name);
            this.addSprite(name, sprite);
        }
        public void newSprite(String name, String img) {
            Sprite sprite = new Sprite(name);
            sprite.setImg(img);
            this.addSprite(name, sprite);
        }
        public void newSprite(String name, String img, float x, float y) {
            Sprite sprite = new Sprite(name);
            sprite.setImg(img);
            sprite.move(x,y);
            this.addSprite(name, sprite);
        }
        public void newSprite(String name, String img, float x, float y, int w, int h) {
            Sprite sprite = new Sprite(name);
            sprite.setImg(img);
            sprite.move(x,y);
            sprite.setWidth(w);
            sprite.setHeight(h);
            this.addSprite(name, sprite);
        }

        public boolean spriteExists(String identifier) {
            return (spriteNames.get(identifier) != null);
        }

        public void emptySpriteStack() {
            spritesStack.empty();
        }

        private void renderSprite(Sprite s) {
            if (s.equals(selectedSprite) || (showAllWireframes && keyPressAllowed)) {
                engine.wireframe = true;
            }
            //draw.autoImg(s.getImg(), s.getX(), s.getY()+s.getHeight()*s.getBop(), s.getWidth(), s.getHeight()-int((float)s.getHeight()*s.getBop()));
            
            switch (s.mode) {
              case SINGLE:
              engine.display.img(s.imgName, s.getX(), s.getY()+s.getHeight()*s.getBop(), s.getWidth(), s.getHeight()-int((float)s.getHeight()*s.getBop()));
              break;
              case DOUBLE:
              engine.display.img(s.imgName, s.getX(), s.getY()+s.getHeight()*s.getBop(), s.getWidth(), s.getHeight()-int((float)s.getHeight()*s.getBop()));
              break;
              case VERTEX:  // We don't need vertices in our program so let's just sweep this under the rug.
              //draw.autoImgVertex(s);
              break;
              case ROTATE:
              //draw.autoImgRotate(s);
              break;
            }
            engine.wireframe = false;
            s.poke(app.frameCount);
        }

        public void renderSprites() {
            for (Sprite s : sprites) {
                renderSprite(s);
            }
        }
        
        public void renderSprite(String name, String img) {
            Sprite s = getSprite(name);
            s.setImg(img);
            renderSprite(s);
        }
        
        public void renderSprite(String name) {
            Sprite s = sprites.get(spriteNames.get(name));
            renderSprite(s);
        }

        public void guiElement(String identifier, String image) {
            //float ratioX = app.width/float(app.displayWidth);
            //println("ratioX: " + ratioX);
            //getSprite(identifier).offmove((float(app.displayWidth)*ratioX), 0.);
            this.sprite(identifier, image);
        }

        public void guiElement(String nameAndID) {
            this.guiElement(nameAndID, nameAndID);
        }

        public void button(String identifier, String image, String text) {
            this.guiElement(identifier, image);
            if (text.length() > 0) {
                app.textFont(engine.DEFAULT_FONT, 18);
                // app.fill(255);
                app.textAlign(CENTER, TOP);
                float x = getSprite(identifier).getX() + getSprite(identifier).getWidth()/2;
                float y = getSprite(identifier).getY() + getSprite(identifier).getHeight() + 5;
                engine.display.recordRendererTime();
                app.text(text, x, y);
                engine.display.recordLogicTime();
            }
        }

        public void button(String nameAndID, String text) {
            this.button(nameAndID, nameAndID, text);
        }

        public void button(String nameAndID) {
            this.button(nameAndID, nameAndID);
        }


        // TODO: move the button code to the engine later.
        // Anything that needs to be consistant between screens
        // should be in the engine class anyways.
        public boolean buttonClicked(String identifier) {
            Sprite s = getSprite(identifier);
            return (s.mouseWithinHitbox() && engine.input.primaryClick);
        }

        public boolean buttonHover(String identifier) {
            Sprite s = getSprite(identifier);
            return s.mouseWithinHitbox();
        }

        public void sprite(String nameAndID) {
            this.sprite(nameAndID, nameAndID);
        }

        public void sprite(String identifier, String image) {
            if (!spriteExists(identifier)) {
                addSprite(identifier, image);
            }
            Sprite s = getSprite(identifier);
            s.setImg(image);
            try { spritesStack.push(s); }
            catch (StackException e) { 
              this.engine.console.bugWarnOnce("Sprite stack is full, did you forget to call updateSpriteSystem()?"); 
            }
            renderSprite(s);
        }

        // Same as sprite, except since the code is so botched,
        // here's some more botch'd code with hackDimensions
        // where we DON'T render the sprite.
        public void placeable(String identifier) {
            if (!spriteExists(identifier)) addSprite(identifier, "nothing");
            Sprite s = getSprite(identifier);
            placeable(s);
        }

        public void placeable(Sprite s) {
            s.imgName = "nothing";
            spritesStack.push(s);
            renderSprite(s);
        }

        public void hackSpriteDimensions(Sprite s, int w, int h) {
            s.wi = w;
            s.hi = h;
            s.aspect = float(h)/float(w);
        }

        public void hackSpriteDimensions(String identifier, int w, int h) {
            Sprite s = getSprite(identifier);
            hackSpriteDimensions(s, w, h);
        }

        private void runSpriteInteraction() {
            
            // Replace true with false to disable sprite interaction.
            if (interactable) {
            if (selectedSprite != null) {
                if (!selectedSprite.beingUsed(app.frameCount)) {
                selectedSprite = null;
                }
            }
            
            boolean hoveringOverAtLeast1Sprite = false;
            boolean clickedSprite = false;
            
            for (int i = 0; i < spritesStack.size(); i++) {
                Sprite s = spritesStack.peek(i);
                if (s.equals(selectedSprite)) {
                if (s.mouseWithinHitbox()) {
                    hoveringOverAtLeast1Sprite = true;
                }
                if (!s.isLocked()) {
                    if (s.allowResizing) {
                        s.resizeSquare();
                    }
                    s.dragReposition();
                }
                }
                else if (s.mouseWithinHitbox()) {
                hoveringOverAtLeast1Sprite = true;
                if (generalClick.clicked()) {
                    selectedSprites.push(s);
                    clickedSprite = true;
                }
                }
            }
            //Sort through the sprites and select the front-most sprite (sprite with the biggest zpos)
            if (clickedSprite && selectedSprites.size() > 0) {
                boolean performSearch = true;
                if (selectedSprite != null) {
                if (selectedSprite.mouseWithinHitbox()) {
                    performSearch = false;
                }
                
                if (selectedSprite.isDragging()) {
                    performSearch = false;
                }
                }
                
                if (performSearch) {
                int highest = selectedSprites.top().getOrder();
                Sprite highestSelected = selectedSprites.top();
                for (int i = 0; i < selectedSprites.size(); i++) {
                    Sprite s = selectedSprites.peek(i);
                    if (s.getOrder() > highest) {
                        highest = s.getOrder();
                        highestSelected = s;
                    }
                }
                selectedSprite = highestSelected;
                selectedSprites.empty();
                }
            }
            
            if (!hoveringOverAtLeast1Sprite && generalClick.clicked()) {
                selectedSprite = null;
            }
            
            }
        }
        
        //idk man. I'm not in the mood to name things today lol.
        public void keyboardInteractionEnabler() {
          if (engine.input.ctrlDown && engine.input.keyDownOnce('~')) {
            if (!this.interactable) {
              this.interactable = true;
              engine.console.log("Sprite system interactability enabled.");
            }
            else {
              this.interactable = false;
              engine.console.log("Sprite system interactability disabled.");
            }
          };
        }

        public void updateSpriteSystem() {
            this.keyboardInteractionEnabler();
            this.generalClick.update();
            this.runSpriteInteraction();
            this.emptySpriteStack();
        }

    }
    


    

    //*******************************************
    //****************Stack class****************
    class StackException extends RuntimeException{    
        public StackException(String err) {
            super(err);
        }
    }

    public class Stack<T> implements Iterable<T> {
    private Object[] S;
    private int top;
    private int capacity;
    
    public Stack(int size){
        capacity = size;
        S = new Object[size];
        top = -1;
    }

    public Stack(){
        this(100);
    }
    
    public T peek() {
        if(isEmpty())
        throw new StackException("stack is empty");
        return (T)S[top];
    }
    
    public T peek(int indexFromTop) {
        //Accessing negative indexes should be impossible.
        if(top-indexFromTop < 0)
        throw new StackException("stack is empty");
        return (T)S[top-indexFromTop];
    }
    
    public boolean isEmpty(){
        return top < 0;
    }
    
    public int size(){
        return top+1; 
    }
    
    public void empty() {
        top = -1;
    }

    public void push(T e){
        if(size() == capacity)
        throw new StackException("stack is full");
        S[++top] = e;
    }
    
    public T pop() throws StackException{
        if(isEmpty())
        throw new StackException("stack is empty");
        // this type cast is safe because we type checked the push method
        return (T) S[top--];
    }
    
    public T top() throws StackException{
        if(isEmpty())
        throw new StackException("stack is empty");
        // this type cast is safe because we type checked the push method
        return (T) S[top];
    }
    
    public Iterator<T> iterator() {
      return (Iterator<T>)Arrays.asList(S).iterator();
    }
    
    }
