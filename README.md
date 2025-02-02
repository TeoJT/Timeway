
![image](https://github.com/user-attachments/assets/e238ebde-fe51-4a36-b1c8-97885947356c)


## Your computer is your universe.

Timeway is a whimsical, dream-like file explorer that represents your computer's files in a 3D world.

## Quick start

1. Visit the [Timeway download page](https://teojt.github.io/timeway.html#download) or the [releases page](https://teojt.github.io/timeway.html#download).
2. Extract the files
3. Run Timeway.exe (or the Timeway executable on Linux)
4. Go though the tutorial which explains the basic controls.

## Full guide
TODO.

## Timeway Interfacing Toolkit guide (TWIT)
TODO.
Timeway includes an API to allow custom plugins to run in each realm. This is a work in progress and an API reference will be released soon.

## Development guide
### Quick start
Ensure you have Python installed. If you're on windows, this can either be in WSL or native.

Download and run the [TWEngine Development Environment Installer](https://github.com/TeoJT/twengine-dev-environment-setup) to install everything you need to start coding with Timeway. This includes the Processing IDE and all needed libraries.

Open Processing and the open Timeway from the File>Open menu. You can test run the application by clicking the big play button.

*NOTE:* This repo doesn't include the realm templates. If you really want to have realm templates installed, please extract it from a [release](https://teojt.github.io/timeway.html#download) of Timeway. This will be located under `data/engine/realmtemplates`.

### Building an official release.
In Processing, go to File>Export application and select the OS's to export to. Ensure "Include Java with build" is checked.

Once the export has been complete, open the terminal, go to the Timeway directory, and run `python3 timeway_packer.py`. Wait for the script to finish the packing process. If you don't intend to ship your build publicly, you may cancel (CTRL+C) the script when it reaches the zipping process. The final build will be timeway\_\[OS\]\_\[VERSION\].zip, or located in \timeway_\[OS\] if you cancel the zipping process.
