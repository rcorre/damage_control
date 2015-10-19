import std.file;
import std.path;
import std.stdio;
import std.getopt;

import cid;
import jsonizer;
import constants;

import common.savedata;
import title.title;

int main(string[] args) {
  version(Posix)
    string savePath = "~/.config/damage_control/save.json";
  else
    static assert(0, "figure out where to save on windows");

  bool printVersion;

  auto helpInfo = getopt(
    args,
    "savepath|s", "path to JSON save data file", &savePath,
    "version|v" , "print version info and exit", &printVersion);

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

    return Game.run(new InitializeGame(savePath), settings);
  }

  return 0;
}

private:
class InitializeGame : State!Game {
  private string _savePath;

  this(string savePath) {
    _savePath = savePath;
  }

  override {
    void enter(Game game) {
      // load control scheme
      game.events.controlScheme = "controls.json".readJSON!ControlScheme;

      // load content
      game.audio.loadSamples("./content/sound", "*.wav");

      // start on title state
      game.states.replace(new Title(game));

      // make sure user can close the window
      game.graphics.onClose = { game.stop(); };
    }

    void exit(Game game) { }
    void run(Game game) { }
  }
}
