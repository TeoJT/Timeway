// How to enable Android mode in your code:
// ctrl+a
// ctrl+/
// Yes. That's really now you do it.
// Make sure to do it to zDesktop too.
import android.content.Context;
import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.os.Bundle;
import android.graphics.Bitmap;
import android.media.MediaPlayer;
import android.net.Uri;
import android.content.res.AssetManager;

public static final int ANDROID_LAUNCH_CAM = 1;
public static final int ANDROID_CAMERA_REQUEST = 2;
static int ANDROID_RESULT_OK;

private void shouldNotBeCalled(String funcitonName) {
  timewayEngine.console.bugWarnOnce(funcitonName+": You should not call this in Android mode!"); 
}


public boolean isLinux() {
  return false;
}

public boolean isWindows() {
  return false;
}

public boolean isMacOS() {
  return false;
}

public boolean isAndroid() {
  return true;
}

@SuppressWarnings("unused")
public void setDesktopIcon(String iconPath) {
  // No desktop or icons on a phone obviously, don't do anything.
}

public String sketchPath() {
  return sketchPath;
}

protected PSurface initSurface() {
  // Don't do anything. Except return the essentials.
  return surface;
}

@SuppressWarnings("unused")
protected void selectOutputSketch(String promptMessage, String outputFileSelected) {
  // TODO: implement file selector.
}

// Android doesn't have ctrl and alt keys.
public static final int CONTROL = -2;
public static final int ALT = -3;


public Object getFromClipboardStringFlavour() {
  return "Clipboard Text";
}

public Object getFromClipboardImageFlavour() {
  return timewayEngine.display.systemImages.get("white").pimage;
}

public PImage getPImageFromClipboard()
{
  return timewayEngine.display.systemImages.get("white").pimage;
}

@SuppressWarnings("unused")
public void copyStringToClipboard(String s) {
  
}

@SuppressWarnings("unused")
public boolean isClipboardImage(Object o) {
  return false;
}

@SuppressWarnings("unused")
public void desktopOpen(String file) {
  
}

public void openErrorLog() {
  
}

@SuppressWarnings("unused")
public void minimalErrorDialog(String mssg) {
  
}

public void requestAndroidPermissions() {
  if (!hasPermission("android.permission.MANAGE_EXTERNAL_STORAGE")) {
    requestPermission("android.permission.MANAGE_EXTERNAL_STORAGE");
  }
  
  if (!hasPermission("android.permission.READ_EXTERNAL_STORAGE")) {
    requestPermission("android.permission.READ_EXTERNAL_STORAGE");
  }
  
  if (!hasPermission("android.permission.WRITE_EXTERNAL_STORAGE")) {
    requestPermission("android.permission.WRITE_EXTERNAL_STORAGE");
  }
}

public void openTouchKeyboard() {
  openKeyboard();
}

public void closeTouchKeyboard() {
  closeKeyboard();
}

public String getAndroidCacheDir() {
  String dir = getContext().getCacheDir().getAbsolutePath();
  if (dir.charAt(dir.length()-1) != '/')  dir += "/";   // Directorify
  return dir;
}

public String getAndroidWriteableDir() {
  String dir = getContext().getFilesDir().getAbsolutePath();
  if (dir.charAt(dir.length()-1) != '/')  dir += "/";   // Directorify
  return dir;
}

@SuppressWarnings("unused")
public PImage getDCaptureImage(DSCapture capture) {
  return timewayEngine.display.systemImages.get("white").pimage;
}

@SuppressWarnings("unused")
public int getDCaptureWidth(DSCapture capture) {
  shouldNotBeCalled("getDCaptureWidth");
  return 0;
}

@SuppressWarnings("unused")
public int getDCaptureHeight(DSCapture capture) {
  shouldNotBeCalled("getDCaptureHeight");
  return 0;
}

public FileInputStream getFileInputStream(String file) {
  try {
    return getContext().openFileInput(sketchPath(file));
  }
  catch (Exception e) {
    timewayEngine.console.warn(e.getMessage());
    return null;
  }
}


public FileOutputStream getFileOutputStream(String file) {
  try {
    return getContext().openFileOutput(file, 3);
  }
  catch (Exception e) {
    timewayEngine.console.warn(e.getMessage());
    return null;
  }
}

boolean cameraPermissionRequested = false;

public void openAndroidCamera() {
  if (!cameraPermissionRequested) {
    requestPermission("android.permission.CAMERA", "onCameraPermissionResponse");
  }
  else {
    startAndroidCamera();
  }
}

void onCameraPermissionResponse(boolean granted) {
  if (granted) {
    cameraPermissionRequested = true;
    startAndroidCamera();
  }
}

void startAndroidCamera() {
  Intent intent= new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
  
  //intent.putExtra(MediaStore.EXTRA_OUTPUT);
  try {
    getActivity().startActivityForResult(intent, ANDROID_LAUNCH_CAM);
  } catch (RuntimeException e) {
      // display error state to the user
      timewayEngine.console.warn("Failed to request camera: "+e.getMessage());
  }
}

boolean once = false;
public void onActivityResult(int requestCode, int resultCode, Intent data)
{
    if (resultCode == Activity.RESULT_CANCELED && !once) {
      timewayEngine.console.log("Cancel photo capture.");
      once = true;
    }
  //if (requestCode == ANDROID_CAMERA_REQUEST){
    timewayEngine.console.log(requestCode);
    try {
      // Get the image from android camera.
      Bitmap imageBitmap = null;
      try {
        imageBitmap = (Bitmap) data.getParcelableExtra("data", Bitmap.class);
      }
      catch (Exception e) {
        timewayEngine.console.warn("getdata Photo error: "+e.getMessage());
        return;
      }
      
      //Bundle extras = data.getExtras();
      //Bitmap imageBitmap = (Bitmap) extras.get("data");
      
      timewayEngine.console.log(imageBitmap.getWidth()+" "+imageBitmap.getHeight());
      //imageBitmap.getPixels(int[] pixels, int offset, int stride, int x, int y, int width, int height)
      timewayEngine.console.log("tout est ok------------------");
      
      // Now to convert the image to pimage
      // swapped width and height cus image is on its side.
      int wi = imageBitmap.getHeight();
      int hi = imageBitmap.getWidth();
      PImage photo = createImage(wi, hi, ARGB);
      photo.loadPixels();
      
      
      try {
        for (int y = 0; y < imageBitmap.getHeight(); y++) {
          for (int x = 0; x < imageBitmap.getWidth(); x++) {
            photo.pixels[x*wi + y] = imageBitmap.getPixel(x, (imageBitmap.getHeight()-y-1));
          }
        }
      }
      catch (Exception e) {
        timewayEngine.console.warn("getpixel Photo error: "+e.getMessage());
        return;
      }
      photo.updatePixels();
      
      if (timewayEngine.currScreen instanceof Editor) {
        ((Editor)timewayEngine.currScreen).endCameraAndroid(photo);
      }
    }
    catch (Exception e) {
      timewayEngine.console.warn("Couldn't get result image, error: "+e.getMessage());
    }
}

void backPressed() {
  timewayEngine.inputPromptShown = false;
  if (timewayEngine.currScreen instanceof PixelRealmWithUI) {
    PixelRealmWithUI screen = (PixelRealmWithUI)timewayEngine.currScreen;
    screen.menu = null;
    screen.menuShown = false;
  }
}



public class AndroidMedia {
  MediaPlayer mediaPlayer = null;
  
  public AndroidMedia(String path) {
    // paths in the user files
    if (path.charAt(0) == '/') {
      File fff = new File(path);
      if (!fff.exists()) {
        timewayEngine.console.warn("(AndroidMedia) "+path+" doesn't exist.");
      }
      else {
        mediaPlayer = MediaPlayer.create(getContext(), Uri.fromFile(fff));
      }
    }
    // Paths in the assets
    else {
      mediaPlayer = new MediaPlayer();
      try {
        mediaPlayer.setDataSource(surface.getAssets().openFd(path));
        mediaPlayer.prepare();
      }
      catch (IOException e) {
        timewayEngine.console.warn("IOException MediaPlayer "+path+": "+e.getMessage());
        mediaPlayer = null;
      }
      catch (RuntimeException e) {
        timewayEngine.console.warn("Couldn't play "+path+": "+e.getMessage());
        mediaPlayer = null;
      }
    }
  }
  
  
  public void play() {
    if (mediaPlayer != null) {
      mediaPlayer.setLooping(false);
      mediaPlayer.start();
    }
  }
  
  public void loop() {
    if (mediaPlayer != null) {
      mediaPlayer.setLooping(true);
      mediaPlayer.start();
    }
  }
  
  public void stop() {
    if (mediaPlayer != null) {
      mediaPlayer.stop();
    }
  }
  
  public void volume(float vol) {
    if (mediaPlayer != null) {
      mediaPlayer.setVolume(vol, vol);
    }
  }
  
  public boolean isPlaying() {
    if (mediaPlayer != null) {
      return mediaPlayer.isPlaying();
    }
    return false;
  }
  
  
}














//SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss");
//String fileName = "IMG_" + simpleDateFormat.format(new Date()) + ".jpg";
//File myDirectory = new File(Environment.getExternalStorageDirectory() + "/DCIM/Camera/");
//cameraImageFile = new File(myDirectory, fileName);
//Uri imageUri = Uri.fromFile(cameraImageFile);
//Intent intent = new Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE);
//intent.putExtra(MediaStore.EXTRA_OUTPUT, imageUri);
//startActivityForResult(intent, CAMERA_PIC_REQUEST);

//**OnActivityResult:**
//switch (requestCode) {
//case CAMERA_PIC_REQUEST:

//ImageView.setImageBitmap(decodeFile(cameraImageFile.getAbsolutePath()));

//}
//break;
