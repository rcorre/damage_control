/// Title screen state.
module title.title;

import std.process   : browse;
import battle.battle;
import cid;
import constants;
import common.menu;
import common.menu_stack;
import common.keyboard_menu;
import common.gamepad_menu;
import common.options_menu;
import common.key_icon;
import title.states.navigate;

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

      drawInputHints(game,
          "W", "Up" ,
          "S", "Down",
          "J", "Confirm",
          "K", "Cancel");
    }
  }

  void select(Game game) {
    _menus.select();
  }

  void popMenu() {
    _menus.popMenu();
  }

  void moveSelection(Vector2f pos, Game game) {
    _menus.moveSelection(pos);
  }

  private:
  auto mainMenu(Game game) {
    return new Menu(
        MenuEntry("Play"    , () => _menus.pushMenu(playMenu(game))),
        MenuEntry("Options" , () => _menus.pushMenu(optionsMenu(game))),
        MenuEntry("Controls", () => _menus.pushMenu(controlsMenu(game))),
        MenuEntry("Credits" , () => _menus.pushMenu(creditsMenu(game))),
        MenuEntry("Quit"    , () => game.stop()));
  }

  auto playMenu(Game game) {
    auto play() { game.states.push(new Battle(ShowTutorial.yes)); }

    return new Menu(
        MenuEntry("Tutorial", &play),
        MenuEntry("1 Player", &play),
        MenuEntry("2 Player", &play));
  }

  auto optionsMenu(Game game) {
    auto dummy(Game game) {}

    return new OptionsMenu(game);
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
