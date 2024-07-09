//// How to enable Desktop mode in your code:
//// ctrl+a
//// ctrl+/
//// Yes. That's really now you do it.
//// Make sure to do it to zAndroid too.
//import com.jogamp.newt.opengl.GLWindow;

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
//    boolean maximise = true;
    
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
