//// How to enable Android mode in your code:
//// ctrl+a
//// ctrl+/
//// Yes. That's really now you do it.
//// Make sure to do it to zDesktop too.
//import android.content.Context;

//@SuppressWarnings("unused")
//private void shouldNotBeCalled(String funcitonName) {
//  timewayEngine.console.bugWarnOnce(funcitonName+": You should not call this in Android mode!"); 
//}


//public boolean isLinux() {
//  return false;
//}

//public boolean isWindows() {
//  return false;
//}

//public boolean isMacOS() {
//  return false;
//}

//public boolean isAndroid() {
//  return true;
//}

//@SuppressWarnings("unused")
//public void setDesktopIcon(String iconPath) {
//  // No desktop or icons on a phone obviously, don't do anything.
//}

//public String sketchPath() {
//  return sketchPath;
//}

//protected PSurface initSurface() {
//  // Don't do anything. Except return the essentials.
//  return surface;
//}

//@SuppressWarnings("unused")
//protected void selectOutputSketch(String promptMessage, String outputFileSelected) {
//  // TODO: implement file selector.
//}

//// Android doesn't have ctrl and alt keys.
//public static final int CONTROL = -2;
//public static final int ALT = -3;


//public Object getFromClipboardStringFlavour() {
//  return "Clipboard Text";
//}

//public Object getFromClipboardImageFlavour() {
//  return timewayEngine.display.systemImages.get("white").pimage;
//}

//public PImage getPImageFromClipboard()
//{
//  return timewayEngine.display.systemImages.get("white").pimage;
//}

//@SuppressWarnings("unused")
//public void copyStringToClipboard(String s) {
  
//}

//@SuppressWarnings("unused")
//public boolean isClipboardImage(Object o) {
//  return false;
//}

//@SuppressWarnings("unused")
//public void desktopOpen(String file) {
  
//}

//public void openErrorLog() {
  
//}

//@SuppressWarnings("unused")
//public void minimalErrorDialog(String mssg) {
  
//}

//public void requestAndroidPermissions() {
//  if (!hasPermission("android.permission.MANAGE_EXTERNAL_STORAGE")) {
//    requestPermission("android.permission.MANAGE_EXTERNAL_STORAGE");
//    timewayEngine.console.log("Requesting MANAGE_EXTERNAL_STORAGE permission");
//  }
//  else timewayEngine.console.log("Already have permission for MANAGE_EXTERNAL_STORAGE");
  
//  if (!hasPermission("android.permission.READ_EXTERNAL_STORAGE")) {
//    requestPermission("android.permission.READ_EXTERNAL_STORAGE");
//    timewayEngine.console.log("Requesting READ_EXTERNAL_STORAGE permission");
//  }
//  else timewayEngine.console.log("Already have permission for READ_EXTERNAL_STORAGE");
  
//  if (!hasPermission("android.permission.WRITE_EXTERNAL_STORAGE")) {
//    requestPermission("android.permission.WRITE_EXTERNAL_STORAGE");
//    timewayEngine.console.log("Requesting WRITE_EXTERNAL_STORAGE permission");
//  }
//  else timewayEngine.console.log("Already have permission for WRITE_EXTERNAL_STORAGE");
//}

//public void openTouchKeyboard() {
//  openKeyboard();
//}

//public void closeTouchKeyboard() {
//  closeKeyboard();
//}

//public String getAndroidCacheDir() {
//  String dir = getContext().getCacheDir().getAbsolutePath();
//  if (dir.charAt(dir.length()-1) != '/')  dir += "/";   // Directorify
//  return dir;
//}

//public String getAndroidWriteableDir() {
//  String dir = getContext().getFilesDir().getAbsolutePath();
//  if (dir.charAt(dir.length()-1) != '/')  dir += "/";   // Directorify
//  return dir;
//}

//@SuppressWarnings("unused")
//public PImage getDCaptureImage(DSCapture capture) {
//  return timewayEngine.display.systemImages.get("white").pimage;
//}

//@SuppressWarnings("unused")
//public int getDCaptureWidth(DSCapture capture) {
//  shouldNotBeCalled("getDCaptureWidth");
//  return 0;
//}

//@SuppressWarnings("unused")
//public int getDCaptureHeight(DSCapture capture) {
//  shouldNotBeCalled("getDCaptureHeight");
//  return 0;
//}
