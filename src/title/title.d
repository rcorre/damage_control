/// Title screen state.
module title.title;

import std.process   : browse;
import battle.battle;
import cid;
import common.menu;
import common.menu_stack;
import common.keyboard_menu;
import common.gamepad_menu;
import common.options_menu;
import title.states.navigate;

private enum {
  underlineSize = Vector2i(150, 6),

  fontName  = "Mecha",
  fontSize  = 36,
  textDepth = 1,
}

/// Show the title screen.
class Title : State!Game {
  private {
    StateStack!(Title, Game) _states;
    MenuStack                _menus;
  }

  override {
    void enter(Game game) {
      _menus = new MenuStack(game, mainMenu(game));
      _states.push(new NavigateMenus);
    }

    void exit(Game game) {
      // this ensures handlers are de-registered
      _states.pop();
    }

    void run(Game game) {
      _menus.updateAndDraw(game);
      _states.run(this, game);
    }
  }

  void select(Game game) {
    _menus.select(game);
  }

  void popMenu() {
    _menus.popMenu();
  }

  void moveSelection(Vector2f pos, Game game) {
    _menus.moveSelection(pos, game);
  }

  private:
  auto mainMenu(Game game) {
    return new Menu(game,
        MenuEntry("Play"    , g => _menus.pushMenu(playMenu(g))),
        MenuEntry("Options" , g => _menus.pushMenu(optionsMenu(g))),
        MenuEntry("Controls", g => _menus.pushMenu(controlsMenu(g))),
        MenuEntry("Credits" , g => _menus.pushMenu(creditsMenu(g))),
        MenuEntry("Quit"    , g => g.stop()));
  }

  auto playMenu(Game game) {
    auto play(Game game) { game.states.push(new Battle(ShowTutorial.yes)); }

    return new Menu(game,
        MenuEntry("Tutorial", &play),
        MenuEntry("1 Player", &play),
        MenuEntry("2 Player", &play));
  }

  auto optionsMenu(Game game) {
    auto dummy(Game game) {}

    return new OptionsMenu(game);
  }

  auto controlsMenu(Game game) {
    return new Menu(game,
        MenuEntry("Keyboard", g => _menus.pushMenu(keyboardMenu(g))),
        MenuEntry("Gamepad" , g => _menus.pushMenu(gamepadMenu(g))));
  }

  auto keyboardMenu(Game game) {
    return new KeyboardMenu(game, game.events.controlScheme);
  }

  auto gamepadMenu(Game game) {
    return new GamepadMenu(game, game.events.controlScheme);
  }

  auto creditsMenu(Game game) {
    return new Menu(game,
        MenuEntry("D"       , g => browse("http://dlang.org")),
        MenuEntry("Allegro" , g => browse("https://allegro.cc/")),
        MenuEntry("Aseprite", g => browse("http://aseprite.org")),
        MenuEntry("LMMS"    , g => browse("https://lmms.io")),
        MenuEntry("Tiled"   , g => browse("http://mapeditor.org")));
  }
}
