/// Move through menus in the title screen
module title.states.main_menu;

import cid;

import constants;
import common.menu;
import common.savedata;
import common.menu_stack;
import common.input_hint;
import common.gamepad_menu;
import common.options_menu;
import common.keyboard_menu;
import title.title;
import battle.battle;

private enum {
  titlePos   = Vector2f(screenW / 7, 30),
  versionPos = Vector2f(screenW / 7, 60),
}

/// Show the main menu at the title screen.
class ShowMainMenu : State!(Title, Game) {
  private {
    Font               _titleFont;
    Font               _versionFont;
    SaveData           _saveData;
    InputHint          _hint;
    MenuStack          _menus;
    Array!EventHandler _handlers;
  }

  this(Game game, Title title, SaveData saveData) {
    _menus       = new MenuStack(game, mainMenu(game, title));
    _saveData    = saveData;
    _titleFont   = game.graphics.fonts.get(FontSpec.title);
    _versionFont = game.graphics.fonts.get(FontSpec.versionTag);
  }

  override {
    void enter(Title title, Game game) {
      _handlers.insert(game.events.onButtonDown("confirm", () => _menus.select()));
      _handlers.insert(game.events.onButtonDown("cancel" , () => _menus.popMenu));
      _handlers.insert(game.events.onAxisMoved("move"    , (pos) => _menus.moveSelection(pos) ));
    }

    void exit(Title title, Game game) {
      foreach(h ; _handlers) h.unregister();
    }

    void run(Title title, Game game) {
      _menus.updateAndDraw(game);

      _hint.update(game.deltaTime);

      auto controls = game.events.controlScheme;

      // draw hints for menu navigation keys
      with (InputHint.Action)
        _hint.draw(game, up, down, confirm, back);

      auto titleBatch   = TextBatch(_titleFont, DrawDepth.menuText);
      auto versionBatch = TextBatch(_versionFont, DrawDepth.menuText);
      drawTitle(titleBatch);
      drawVersion(versionBatch);
      game.graphics.draw(titleBatch);
      game.graphics.draw(versionBatch);
    }
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

  auto mainMenu(Game game, Title title) {
    return new Menu(
      MenuEntry("Play"    , () => _menus.pushMenu(playMenu(game))),
      MenuEntry("Options" , () => _menus.pushMenu(optionsMenu(game))),
      MenuEntry("Controls", () => _menus.pushMenu(controlsMenu(game))),
      MenuEntry("Credits" , () => title.showCredits),
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
    return new KeyboardMenu(game, _saveData);
  }

  auto gamepadMenu(Game game) {
    return new GamepadMenu(game, _saveData);
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
