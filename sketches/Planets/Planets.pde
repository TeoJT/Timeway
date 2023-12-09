// Planets, by Andres Colubri
//
// Sun and mercury textures from http://planetpixelemporium.com
// Star field picture from http://www.galacticimages.com/

PImage starfield;

PShape sun;
PImage suntex;

PShape planet1;
PImage surftex1;
PImage cloudtex;

PShape planet2;
PImage surftex2;


PGraphics twodee;
PGraphics threedee;

float cameraX = 0.;
float cameraY = 0.;
float cameraZ = 500.;

boolean lineLine(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {

  // calculate the direction of the lines
  float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
  float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));

  // if uA and uB are between 0-1, lines are colliding
  return (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1);
}

float closestVal = 0.;
Object3D closestObject = null;

class Object3D {
  float x = 0.;
  float y = 0.;
  float z = 0.;
  
  // Just make em constants for now
  float wi = 50.;
  float hi = 50.;
  float closeness = 0.;
  
  public Object3D(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
  
  public void display() {
    threedee.pushMatrix();
    threedee.translate(x, y, z);
    threedee.sphere(wi/2);
    threedee.popMatrix();
  }
  
  public void calculateCloseness() {
    float xx = cameraX-x;
    float zz = cameraZ-z;
    this.closeness = xx*xx + zz*zz + wi*0.5;
  }
  
  public void checkHovering() {
    boolean yawAlign = false;
    boolean pitchAlign = false;
    // YAW
    {
      float d_sin = sin(cameraYaw-PI+HALF_PI)*(wi/2);
      float d_cos = cos(cameraYaw-PI+HALF_PI)*(wi/2);
      float x1 = x + d_sin;
      float z1 = z + d_cos;
      float x2 = x - d_sin;
      float z2 = z - d_cos;
      println("----------");
      println(x1);
      println(z1);
      println(x2);
      println(z2);

      final float SELECT_FAR = 500.;

      float beamX1 = cameraX;
      float beamZ1 = cameraZ;

      float beamX2 = cameraX+sin(cameraYaw)*SELECT_FAR;
      float beamZ2 = cameraZ+cos(cameraYaw)*SELECT_FAR;
      
      println(beamX1);
      println(beamZ1);
      println(beamX2);
      println(beamZ2);
      
      
      yawAlign = lineLine(x1, z1, x2, z2, beamX1, beamZ1, beamX2, beamZ2);
    }
    
    // Pitch
    {
      float d_sin = sin(PI-cameraPitch)*(hi/2);
      float d_cos = cos(PI-cameraPitch)*(hi/2);
      
      float ourx = sqrt(pow(x-cameraX, 2) + pow(z-cameraZ, 2));
      float oury = y-cameraY;
      
      
      // x lies on the same coordinate as closeness to the player
      float x1 = ourx - d_sin;
      // y lies on the same coordinate as how up the player is looking
      float y1 = oury - d_cos;
      float x2 = ourx + d_sin;
      float y2 = oury + d_cos;
      

      final float SELECT_FAR = 500.;

      float beamX1 = 0;
      float beamY1 = 0;

      float beamX2 = sin(PI-(cameraPitch-HALF_PI+PI))*SELECT_FAR;
      float beamY2 = cos(PI-(cameraPitch-HALF_PI+PI))*SELECT_FAR;
      
      
      twodee.beginDraw();
      twodee.stroke(0);
      twodee.pushMatrix();
      twodee.translate(200, 200);
      twodee.line(x1, y1, x2, y2);
      twodee.line(beamX1, beamY1, beamX2, beamY2);
      twodee.popMatrix();
      twodee.noStroke();
      twodee.endDraw();
      
      
      pitchAlign = lineLine(x1, y1, x2, y2, beamX1, beamY1, beamX2, beamY2);
    }

    if (yawAlign && pitchAlign) {
      println(this.closeness);
      if (this.closeness < closestVal) {
        closestVal = this.closeness;
        closestObject = this;
      }
    }
  }
}

ArrayList<Object3D> lizt;

void setup() {
  size(1024, 768, P3D);
  
  twodee = createGraphics(1024, 768, P2D);
  threedee = createGraphics(1024, 768, P3D);
  
  lizt = new ArrayList<Object3D>();
  
  starfield = loadImage("starfield.jpg");
  suntex = loadImage("sun.jpg");  
  surftex1 = loadImage("planet.jpg");  
   
  // We need trilinear sampling for this texture so it looks good
  // even when rendered very small.
  //PTexture.Parameters params1 = PTexture.newParameters(ARGB, TRILINEAR);  
  surftex2 = loadImage("mercury.jpg");  
  
  lizt.add(new Object3D(0, 0, 200));
  lizt.add(new Object3D(0, 50, 150));

  noStroke();
  fill(255);
  sphereDetail(40);

  sun = createShape(SPHERE, 150);
  sun.setTexture(suntex);  

  planet1 = createShape(SPHERE, 20);
  planet1.setTexture(surftex1);
  
  planet2 = createShape(SPHERE, 50);
  planet2.setTexture(surftex2);
}


float cameraYaw = 0.;
float cameraPitch = 0.;

float spinnnn = 0.;
int tabPress = 0;
boolean thirdperson = false;

void draw() {
  // Even we draw a full screen image after this, it is recommended to use
  // background to clear the screen anyways, otherwise A3D will think
  // you want to keep each drawn frame in the framebuffer, which results in 
  // slower rendering.
  background(200);
  
  twodee.beginDraw();
  twodee.clear();
  twodee.endDraw();
  
  
  threedee.beginDraw();
  threedee.clear();
  threedee.endDraw();
  
  float DIST = 1000.;
  
  
  
  if (keyPressed) {
    if (key == 'd') {
      cameraYaw -= 0.05;
    }
    else if (key == 'a') {
      cameraYaw += 0.05;
    }
    
    if (key == 's') {
      cameraPitch -= 0.05;
    }
    else if (key == 'w') {
      cameraPitch += 0.05;
    }
    
    if (key == '\t') tabPress++;
    
    if (tabPress == 1) thirdperson = !thirdperson;
  }
  
  if (!(keyPressed && key == '\t')) tabPress = 0;
  
  //spinnnn += 0.05;
  
  
  
  
  
  
  //shape(sun);
  
  closestVal = Float.MAX_VALUE;
  closestObject = null;
  
  for (Object3D o : lizt) {
    o.calculateCloseness();
  }
  for (Object3D o : lizt) {
    o.checkHovering();
  }
  
  threedee.beginDraw();
  threedee.noStroke();
  
  
  threedee.perspective(PI/3.0, (float)width/height, 1, 10000);
  if (!thirdperson) {
    threedee.camera(cameraX,cameraY,cameraZ, cameraX+sin(cameraYaw)*DIST*cos(cameraPitch), cameraY+sin(cameraPitch)*DIST, cameraZ+cos(cameraYaw)*DIST*cos(cameraPitch), 0., 1., 0.);
  }
  else {
    threedee.camera(sin(spinnnn)*DIST, 150-height/2, cos(spinnnn)*DIST, cameraX,cameraY,cameraZ, 0., 1., 0.);
    threedee.stroke(0);
    threedee.line(cameraX,cameraY,cameraZ, cameraX+sin(cameraYaw)*DIST*cos(cameraPitch), cameraY+sin(cameraPitch)*DIST, cameraZ+cos(cameraYaw)*DIST*cos(cameraPitch));
    threedee.noStroke();
  }
    
    
  
  for (Object3D o : lizt) {
    if (closestObject == o) threedee.fill(255,0,0);
    else threedee.fill(255);
    o.display();
  }
  threedee.endDraw();
  
  
  image(twodee,0,0,width,height);
  image(threedee,0,0,width,height);
  
  
  

}







//void carryingItem() {
//if (inventorySelectedItem != null) {
//      // TODO: OPTIMISATION REQUIRED
//      float SELECT_FAR = 300.;

//      // Stick to in front of the player.
//      if (currentTool == TOOL_GRABBER_NORMAL) {
//        float x = xpos+sin(direction)*SELECT_FAR;
//        float z = zpos+cos(direction)*SELECT_FAR;
//        Object3D o = inventorySelectedItem.carrying;
//        o.x = x;
//        o.z = z;
//        if (onGround())
//          o.y = onSurface(x, z);
//        else
//          o.y = ypos;
//        o.visible = true;
//        if (inventorySelectedItem.carrying instanceof ImageFileObject) {
//          ImageFileObject imgobject = (ImageFileObject)inventorySelectedItem.carrying;
//          imgobject.rot = direction+HALF_PI;
//        }
//      }
//    }
//}
    


    
//void hoverItem() {
//    closestVal = Float.MAX_VALUE;
//    closestObject = null;

//Object inventorySelectedItem = null;

//    final float FLOAT_AMOUNT = 10.;
//    boolean cancelOut = true;
//    // Files.
//    l = files.length;
//    for (int i = 0; i < l; i++) {
//      FileObject f = files[i];
//      if (f != null) {

//        // Quick inventory check; if it's empty, we don't want it to act.
//        boolean holding = false;
//        if (inventorySelectedItem != null)
//          holding = (f == inventorySelectedItem.carrying);

//        if (!holding) {
//          f.checkHovering();
//          if (f instanceof DirectoryPortal) {
//            // Take the player to a new directory in the world if we enter the portal.
//            if (f.touchingPlayer()) {
//              if (portalCoolDown <= 0.) {

//                // Go into the new world
//                // If it's a shortcut, go to where the shortcut points to.
                
//                try {
//                  if (f instanceof ShortcutPortal) {
//                    // SECRET EASTER EGG TOP SECRET
//                    if (((ShortcutPortal)f).shortcutName.equals("Neo_2222?")) {
//                      requestScreen(new WorldLegacy(engine));
//                      f.destroy();
//                    }
//                    // Normal non-easter egg action
//                    else
//                      enterNewRealm(((ShortcutPortal)f).shortcutDir);
//                  }
//                  // Otherwise go to where the directory points to.
//                  else enterNewRealm(f.dir);
//                }
//                catch (RuntimeException e) {
//                  console.warn("The shortcut portal you've just entered is corrupted!");
//                  f.destroy();
//                }
//              } else if (cancelOut) {
//                // Pause the portalcooldown by essentially cancelling out the values.
//                portalCoolDown += display.getDelta();
//                cancelOut = true;
//              }
//            }
//          }
//        }
//      }
//    }

//    // Pick up the object.
//    if (closestObject != null && !menuShown) {
//      FileObject p = (FileObject)closestObject;

//      // Open the file/directory if clicked
//      if (currentTool == TOOL_NORMAL) {
//        if (p.selectedLeft()) {
//          file.open(p.dir);
//        }
//      }

//      // GRABBER TOOL
//      else if (currentTool == TOOL_GRABBER_NORMAL) {

//        // When clicked pick up the object.
//        if (p.selectedLeft()) {

//          pickupItem(p);

//          sound.playSound("pickup");
//        }
//      }
//    }
    
//}
