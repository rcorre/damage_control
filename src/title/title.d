/// Title screen state.
module title.title;

import std.conv    : to;
import std.string  : toUpper;
import std.process : browse;

import cid;

import constants;
import common.savedata;
import battle.battle;
import title.states.main_menu;

/// Show the title screen.
class Title : State!Game {
  private {
    SaveData                 _saveData;
    AudioStream              _music;
    StateStack!(Title, Game) _states;
  }

  this(Game game, SaveData saveData) {
    _saveData = saveData;
  }

override:
  void enter(Game game) {
    _states.push(new ShowMainMenu(game, _saveData));
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
