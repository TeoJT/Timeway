// How to enable Android mode in your code:
// ctrl+a
// ctrl+/
// Yes. That's really now you do it.
// Make sure to do it to zDesktop too.

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
