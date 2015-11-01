/// Title screen state.
module title.title;

import std.conv    : to;
import std.string  : toUpper;
import std.process : browse;

import cid;

import constants;
import common.menu;
import common.menu_stack;
import common.keyboard_menu;
import common.gamepad_menu;
import common.options_menu;
import common.input_hint;
import common.savedata;
import battle.battle;
import title.states.navigate;

private enum {
  titlePos   = Vector2f(screenW / 7, 30),
  versionPos = Vector2f(screenW / 7, 60),
}

/// Show the title screen.
class Title : State!Game {
  private {
    StateStack!(Title, Game) _states;
    MenuStack                _menus;
    InputHint                _hint;
    AudioStream              _music;
    Font                     _titleFont;
    Font                     _versionFont;
    SaveData                 _saveData;
  }

  this(Game game, SaveData saveData) {
    _titleFont   = game.graphics.fonts.get(FontSpec.title);
    _versionFont = game.graphics.fonts.get(FontSpec.versionTag);
    _saveData    = saveData;
  }

  override {
    void enter(Game game) {
      _menus = new MenuStack(game, mainMenu(game));
      _states.push(new NavigateMenus);
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
      _menus.updateAndDraw(game);
      _states.run(this, game);

      _hint.update(game.deltaTime);

      auto controls = game.events.controlScheme;

      // draw hints for menu navigation keys
      _hint.draw(game, Button.up, Button.down, Button.confirm, Button.back);

      auto titleBatch   = TextBatch(_titleFont, DrawDepth.menuText);
      auto versionBatch = TextBatch(_versionFont, DrawDepth.menuText);
      drawTitle(titleBatch);
      drawVersion(versionBatch);
      game.graphics.draw(titleBatch);
      game.graphics.draw(versionBatch);
    }
  }

  void select() {
    _menus.select();
  }

  void popMenu() {
    _menus.popMenu();
  }

  void moveSelection(Vector2f pos) {
    _menus.moveSelection(pos);
  }

  private:
  void drawTitle(ref TextBatch batch) {
    Text text;

    text.centered  = true;
    text.color     = Tint.emphasize;
    text.transform = titlePos,
    text.text      = gameTitle;

    batch ~= text;
  }

  void drawVersion(ref TextBatch batch) {
    Text text;

    text.centered  = true;
    text.color     = Tint.subdued;
    text.transform = versionPos,
    text.text      = gameVersion;

    batch ~= text;
  }

  auto mainMenu(Game game) {
    return new Menu(
        MenuEntry("Play"    , () => _menus.pushMenu(playMenu(game))),
        MenuEntry("Options" , () => _menus.pushMenu(optionsMenu(game))),
        MenuEntry("Controls", () => _menus.pushMenu(controlsMenu(game))),
        MenuEntry("Credits" , () => _menus.pushMenu(creditsMenu(game))),
        MenuEntry("Quit"    , () => game.stop()));
  }

  auto playMenu(Game game) {
    return new Menu(
        MenuEntry("World 1", () => _menus.pushMenu(worldMenu(game, 1))),
        MenuEntry("World 2", {}),
        MenuEntry("World 3", {}));
  }

  auto worldMenu(Game game, int worldNum) {
    auto stageEntry(int num) {
      auto score = _saveData.currentHighScore(worldNum, num);
      return MenuEntry("Stage %d (%d)".format(num, score),
                       () => game.states.push(new Battle(worldNum, num, _saveData)));
    }

    return new Menu(stageEntry(1), stageEntry(2), stageEntry(3));
  }

  auto optionsMenu(Game game) {
    return new OptionsMenu(game, _saveData);
  }

  auto controlsMenu(Game game) {
    return new Menu(
        MenuEntry("Keyboard", () => _menus.pushMenu(keyboardMenu(game))),
        MenuEntry("Gamepad" , () => _menus.pushMenu(gamepadMenu(game))));
  }

  auto keyboardMenu(Game game) {
    return new KeyboardMenu(game, game.events.controlScheme);
  }

  auto gamepadMenu(Game game) {
    return new GamepadMenu(game, game.events.controlScheme);
  }

  auto creditsMenu(Game game) {
    return new Menu(
        MenuEntry("D"       , () => browse("http://dlang.org")),
        MenuEntry("Allegro" , () => browse("https://allegro.cc/")),
        MenuEntry("Aseprite", () => browse("http://aseprite.org")),
        MenuEntry("LMMS"    , () => browse("https://lmms.io")),
        MenuEntry("Tiled"   , () => browse("http://mapeditor.org")));
  }
}
