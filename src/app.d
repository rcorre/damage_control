import std.path;
import std.stdio;
import std.getopt;

import jsonizer;
import standardpaths;

import engine;
import constants;
import common.savedata;
import title.title;

int main(string[] args) {
  // e.g. ~/.config/damage_control or %APPDATA%/damage_control
  string saveDir = StandardPath.config.writablePath.buildPath("damage_control");

  bool printVersion;

  auto helpInfo = getopt(
    args,
    "savedir|s", "path to save file directory", &saveDir,
    "version|v", "print version info and exit", &printVersion);

  if (helpInfo.helpWanted)
    defaultGetoptPrinter(gameTitle, helpInfo.options);
  else if (printVersion)
    writeln(gameTitle, " ", gameVersion);
  else {
    Game.Settings settings;

    // general settings
    settings.fps = frameRate;

    // display settings
    settings.display.windowSize = [screenW, screenH];
    settings.display.canvasSize = [screenW, screenH];
    settings.display.color = Color.black;

    saveDir = saveDir.expandTilde;

    return Game.run(new InitializeGame(saveDir), settings);
  }

  return 0;
}

private:
class InitializeGame : State!Game {
  private string _saveDir;

  this(string saveDir) {
    _saveDir = saveDir;
  }

  override {
    void enter(Game game) {
      game.audio.loadSamples("./content/sound", "*.wav");

      auto saveData = SaveData.load(_saveDir);

      game.events.controlScheme = saveData.controls;

      game.audio.streamMixer.gain = saveData.musicVolume.clamp(0, 1);
      game.audio.soundMixer.gain  = saveData.soundVolume.clamp(0, 1);

      // start on title state
      game.states.replace(new Title(game, saveData));

      // make sure user can close the window
      game.graphics.onClose = { game.stop(); };
    }

    void exit(Game game) { }
    void run(Game game) { }
  }
}
