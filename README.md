# Timeway

Timeway is a Onenote-like application where you can create notes stored on your computer and explore your files in an interactive 3D retro world.

It is currently very WIP, so there may be noticable missing features/bugs.

## Quick start
Download from the [releases page](https://github.com/TeoJT/timeway/releases/) and run the executable. If running on Linux or MacOS, you'll need to ensure Java 8 is installed.
When you start the program, it should present you with an introductory page which shows you the basics. To leave this page, click the "entries" arrow at the top-left.

## How to use
Click the "world view" button on the explorer page to view your files as a 3D world. Move using wasd, use q+e to look around, use r to sprint, space to jump, and press backspace to return back to the explorer. Enter portals to enter a directory and collect file icons to open them. Coins mainly exist as a decoration for now.

To create a new Timeway entry, click "New Entry" in the explorer. You can rename the file by editing the title. Click in a blank area to create text, and use ctrl-v to paste images into your file. You can drag text and images, and you can resize images by clicking and dragging the bottom-right corner of the image. Delete any text or images with the delete key. You can also change colour and size of the text in the toolbar.

**IMPORTANT**: Files are not saved automatically yet, so make sure to click the "entries" back button to save entries.

## Extra options
Timeway's config file is located in data/config.json. These are the following configurations:

`repressDevMode : true/false` - Disables dev mode even if being edited by the Processing IDE.

`fullscreen : true/false` - Toggles fullscreen mode upon startup.

`forceDevMode : true/false` - Enables dev mode even if using an exported version.

`scrollSensitivity : float` - The trackpad/mousewheel scroll sensitivity in the explorer.

`dynamicFramerate : true/false` - Timeway reduces the framerate while doing non resource intensive stuff like typing. Set to false to disable this feature.

`lowBatteryPercent : float 0.0-100.0` - (NOT FUNCTIONAL YET) The framerate is reduced when the device's battery percentage is lower than this value. Devices without a battery or that are plugged in are not affected.

`autoScaleDown : true/false` - In the editor, pasted images are shrunk to 512 pixels width/height to save space and performance. Set to false to allow native resolution of pasted images.

`defaultSystemFont : string` - The font used by Timeway without the file extension. Available fonts are in `data/engine/fonts`.

`homeDirectory : string` - The default starting directory in the explorer and world view.

## Updates
As of 0.0.4, Timeway should automatically look for updates and prompt you when one is available.
Follow [my blog](https://teojt.github.io/blog) for updates and roadmaps for the project.
More documentation will (maybe) be released soon.

