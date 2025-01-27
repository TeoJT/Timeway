// *****************************
// Timeway's Interfacing Toolkit
// *****************************


Object runTWIT(int opcode, Object[] args)  {
  try {
      switch (opcode) {
        case 1:
        int val = (int)args[0];
        String mssg = "Hello World "+val;
        timewayEngine.console.log(mssg);
        return mssg;
        
        // print(Object[] args...)
        case 2:
        // print function can have unlimited args
        // First arg is the size of the args list.
        int len = min((int)args[0], 127);
        String message = "";
        for (int i = 1; i < len; i++) {
          String element = "";
          if (args[i] instanceof String) {
            element = (String)args[i];
          }
          else if (args[i] instanceof Integer) {
            element = str((int)args[i]);
          }
          else if (args[i] instanceof Float) {
            element = str((float)args[i]);
          }
          else if (args[i] instanceof Long) {
            element = str((long)args[i]);
          }
          else if (args[i] instanceof Boolean) {
            element = str((boolean)args[i]);
          }
          else {
            if (args[i] != null) element = args[i].getClass().getSimpleName();
          }
          message += (element + " ");
        }
        timewayEngine.console.log(message);
        break;
        
        case 3:
        timewayEngine.console.warn((String)args[0]);
        break;
        
        // fileMkdir(String path) {
        case 1000:
        timewayEngine.file.mkdir((String)args[0]);
        break;
        
        // fileCopy(String src, String dest)
        case 1001:
        return timewayEngine.file.copy((String)args[0], (String)args[1]);
        
        // fileGetLastModified
        case 1002:
        return timewayEngine.file.getLastModified((String)args[0]);
        
        // fileGetExt
        case 1003:
        return timewayEngine.file.getExt((String)args[0]);
        
        // FileGetDir
        case 1004:
        return timewayEngine.file.getDir((String)args[0]);
        
        // fileIsDirectory
        case 1005:
        return timewayEngine.file.isDirectory((String)args[0]);
        
        // fileGetPrevDir
        case 1006:
        return timewayEngine.file.getPrevDir((String)args[0]);
        
        // fileGetRelativeDir
        case 1007:
        return timewayEngine.file.getRelativeDir((String)args[0], (String)args[1]);
        
        // fileRelativeToAbsolute
        case 1008:
        return timewayEngine.file.relativeToAbsolute((String)args[0], (String)args[1]);
        
        // fileDirectorify
        case 1010:
        return timewayEngine.file.directorify((String)args[0]);
        
        // fileGetMyDir
        case 1011:
        return timewayEngine.file.getMyDir();
        
        // fileExists
        case 1012:
        return timewayEngine.file.exists((String)args[0]);
        
        // fileGetSize
        case 1013:
        return timewayEngine.file.fileSize((String)args[0]);
        
        // fileIsImage
        case 1014:
        return timewayEngine.file.isImage((String)args[0]);
        
        // fileGetFilename
        case 1015:
        return timewayEngine.file.getFilename((String)args[0]);
        
        // fileGetIsolatedFilename
        case 1016:
        return timewayEngine.file.getIsolatedFilename((String)args[0]);
        
        // fileAtRootDir
        case 1017:
        return timewayEngine.file.atRootDir((String)args[0]);
        
        // fileExtToIco
        case 1009:
        return timewayEngine.file.typeToIco(timewayEngine.file.extToType((String)args[0]));
        
        // fileHidden
        case 1018:
        return timewayEngine.file.fileHidden((String)args[0]);
        
        // fileUnhide
        case 1019:
        return timewayEngine.file.unhide((String)args[0]);
        
        // fileCountFiles
        case 1020:
        return timewayEngine.file.countFiles((String)args[0]);
        
        // fileOpen
        case 1021:
        timewayEngine.file.open((String)args[0]);
        break;
        
        // fileOpenEntryReadonly
        case 1022:
        timewayEngine.file.openEntryReadonly((String)args[0]);
        break;
        
        // uiAddSpriteSystem
        case 2000:
        timewayEngine.ui.addSpriteSystem(timewayEngine, (String)args[0], (String)args[1]);
        timewayEngine.ui.getSpriteSystem((String)args[0]).interactable = (boolean)args[2];
        break;
        
        // uiUseSpriteSystem
        case 2001:
        timewayEngine.ui.useSpriteSystem(timewayEngine.ui.getSpriteSystem((String)args[0]));
        timewayEngine.ui.usingTWITSpriteSystem = true;
        break;
        
        // uiSetSpriteSystemInteractable
        case 2002:        
        timewayEngine.ui.getSpriteSystem((String)args[0]).interactable = (boolean)args[1];
        break;
        
        // uiSprite
        case 2003:        
        timewayEngine.ui.getInUseSpriteSystem().sprite((String)args[0], (String)args[1]);
        break;
        
        // uiButton
        case 2004:        
        return timewayEngine.ui.buttonVary((String)args[0], (String)args[1], (String)args[2]);

        
        // uiButtonHover
        case 2005:        
        return timewayEngine.ui.buttonHoverVary((String)args[0]);
        
        // uiBasicButton
        case 2006:        
        return timewayEngine.ui.basicButton((String)args[0], (float)args[1], (float)args[2], (float)args[3], (float)args[4]);
        
        // uiLoadingIcon
        case 2007:        
        timewayEngine.ui.loadingIcon((float)args[0], (float)args[1], (float)args[2]);
        break;
        
        // uiLoadingIcon
        case 2008:        
        timewayEngine.ui.updateSpriteSystems();
        break;
                
        // getPluginPath
        case 3000:        
        if (timewayEngine.currScreen instanceof PixelRealmWithUI) {
          return ((PixelRealmWithUI)timewayEngine.currScreen).currRealm.realmPluginPath;
        }
        return "";
        
        // getRunPoint
        case 3001:        
        if (timewayEngine.currScreen instanceof PixelRealmWithUI) {
          return ((PixelRealmWithUI)timewayEngine.currScreen).apiMode;
        }
        return "";
        
        // prPauseRefresher
        case 3002:        
        if (timewayEngine.currScreen instanceof PixelRealmWithUI) {
          ((PixelRealmWithUI)timewayEngine.currScreen).issueRefresherCommand(PixelRealm.REFRESHER_LONGPAUSE);
        }
        break;
        
        // prResumeRefresher
        case 3003:        
        if (timewayEngine.currScreen instanceof PixelRealmWithUI) {
          ((PixelRealmWithUI)timewayEngine.currScreen).issueRefresherCommand(PixelRealm.REFRESHER_EXITLONGPAUSE);
        }
        break;
        
        // prPrompt
        case 3004:        
        if (timewayEngine.currScreen instanceof PixelRealmWithUI) {
          ((PixelRealmWithUI)timewayEngine.currScreen).prompt((String)args[0], (String)args[1], (int)args[2]);
        }
        break;
        
        // prMenuShown()
        case 3005:        
        if (timewayEngine.currScreen instanceof PixelRealmWithUI) {
          return ((PixelRealmWithUI)timewayEngine.currScreen).menuShown;
        }
        return false;
        
        // prCreateCustomMenu
        case 3006:        
        if (timewayEngine.currScreen instanceof PixelRealmWithUI) {
          ((PixelRealmWithUI)timewayEngine.currScreen).createCustomMenu((String)args[0], (String)args[1], (Runnable)args[2]);
        }
        break;
        
        // prCloseMenu
        case 3007:        
        if (timewayEngine.currScreen instanceof PixelRealmWithUI) {
          ((PixelRealmWithUI)timewayEngine.currScreen).closeMenu();
        }
        break;
        
        // soundPlay()
        case 4000:
        timewayEngine.sound.playSound((String)args[0], (float)args[1]);
        break;
        
        // soundPlayOnce()
        case 4001:
        timewayEngine.sound.playSoundOnce((String)args[0]);
        break;
        
        // soundPause()
        case 4002:
        timewayEngine.sound.pauseSound((String)args[0]);
        break;
        
        // soundLoop()
        case 4003:
        timewayEngine.sound.loopSound((String)args[0]);
        break;
        
        // soundStop()
        case 4004:
        timewayEngine.sound.loopSound((String)args[0]);
        break;
        
        // soundSetVolume()
        case 4005:
        timewayEngine.sound.setSoundVolume((String)args[0], (float)args[1]);
        break;
        
        // soundSetMasterVolume()
        case 4006:
        timewayEngine.sound.setMasterVolume((float)args[0]);
        break;
        
        // soundSetMusicVolume()
        case 4007:
        timewayEngine.sound.setMusicVolume((float)args[0]);
        break;
        
        // soundStreamMusic
        case 4008:
        timewayEngine.sound.streamMusic((String)args[0]);
        break;
        
        // soundStreamMusicWithFade
        case 4009:
        timewayEngine.sound.streamMusicWithFade((String)args[0]);
        break;
        
        // soundStopMusic
        case 4010:
        timewayEngine.sound.stopMusic();
        break;
        
        // soundPauseMusic()
        case 4011:
        timewayEngine.sound.pauseMusic();
        break;
        
        // soundContinueMusic()
        case 4012:
        timewayEngine.sound.continueMusic();
        break;
        
        // soundFadeAndStopMusic
        case 4013:
        timewayEngine.sound.fadeAndStopMusic();
        break;
        
        // soundSyncMusic
        case 4014:
        timewayEngine.sound.syncMusic((float)args[0]);
        break;
        
        // soundGetMusicDuration()
        case 4015:
        return timewayEngine.sound.getCurrentMusicDuration();
        
        
        
        default:
        timewayEngine.console.warn("Unknown opcode "+opcode);
        break;
      }
      
      
      
      
      
  }
  // Typically a bug in the boilerplate or here.
  catch (IndexOutOfBoundsException e) {
    
  }
  return null;
        
}
