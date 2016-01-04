/// Title screen state.
module title.title;

import std.conv    : to;
import std.string  : toUpper;
import std.process : browse;

import engine;

import constants;
import common.savedata;
import battle.battle;
import title.states.main_menu;
import title.states.credits;

/// Show the title screen.
class Title : State!Game {
  private {
    SaveData                 _saveData;
    AudioStream              _music;
    StateStack!(Title, Game) _states;
    immutable string         _mapDir;
  }

  this(Game game, SaveData saveData, string mapDir) {
    _saveData = saveData;
    _mapDir = mapDir;
  }

  void showCredits() { _states.push(new ShowCredits); }
  void popState() { _states.pop(); }

override:
  void enter(Game game) {
    _states.push(new ShowMainMenu(game, this, _saveData, _mapDir));
    _music = game.audio.loadStream(MusicPath.title);
    _music.playmode = AudioPlayMode.loop;
  }

  void exit(Game game) {
    // this ensures handlers are de-registered
    _states.pop();

    // ensure that the music stops and the stream is freed
    _music.destroy();
  }

  void run(Game game) {
    _states.run(this, game);
  }
}
