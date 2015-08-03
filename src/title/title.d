/// Title screen state.
module title.title;

import std.math      : pow;
import std.process   : browse;
import std.container : Array;
import battle.battle;
import dau;
import title.menu;
import jsonizer;

/// Show the title screen.
class Title : State!Game {
  private {
    Array!TitleMenu    _menus;
    TitleMenu          _poppedMenu;
    Array!EventHandler _handlers;
  }

  override {
    void enter(Game game) {
      game.events.setControlScheme("controls.json".readJSON!ControlScheme);
      _menus ~= mainMenu(game);

      _handlers.insert(game.events.onButtonDown("confirm",
          () => _menus.back.confirmSelection(game)));

      _handlers.insert(game.events.onButtonDown("cancel", () => popMenu()));

      auto moveMenuSelection(Vector2f pos) {
      }

      _handlers.insert(game.events.onAxisMoved("move", (pos) {
        if      (pos.y > 0) _menus.back.moveSelectionDown();
        else if (pos.y < 0) _menus.back.moveSelectionUp();
        else if (pos.x < 0) popMenu();
        else if (pos.x > 0) _menus.back.confirmSelection(game);
      }));
    }

    void exit(Game game) {
      foreach(h ; _handlers) h.unregister();
    }

    void run(Game game) {
      foreach(menu ; _menus) menu.update(game);
      if (_poppedMenu) _poppedMenu.update(game);
    }
  }

  private:
  void pushMenu(TitleMenu menu) {
    _menus.back.centerToStack();
    _menus ~= menu;
    _menus.back.exitToCenter();
  }

  void popMenu() {
    if (_menus.length > 1) {
      _poppedMenu = _menus.back;
      _menus.removeBack();
      _poppedMenu.centerToExit();
      _menus.back.setSelection(0);
      _menus.back.stackToCenter();
    }
  }

  auto mainMenu(Game game) {
    return new TitleMenu(game,
      MenuEntry("Play"    , Vector2i(300, 100), g => pushMenu(playMenu(g))),
      MenuEntry("Options" , Vector2i(300, 200), g => pushMenu(optionsMenu(g))),
      MenuEntry("Controls", Vector2i(300, 300), g => pushMenu(controlsMenu(g))),
      MenuEntry("Credits" , Vector2i(300, 400), g => pushMenu(creditsMenu(g))),
      MenuEntry("Quit"    , Vector2i(300, 500), g => g.stop()));
  }

  auto playMenu(Game game) {
    auto play(Game game) { game.states.push(new Battle); }

    return new TitleMenu(game,
      MenuEntry("Tutorial", Vector2i(400, 200), &play),
      MenuEntry("1 Player", Vector2i(400, 300), &play),
      MenuEntry("2 Player", Vector2i(400, 400), &play));
  }

  auto optionsMenu(Game game) {
    auto dummy(Game game) {}

    return new TitleMenu(game,
      MenuEntry("Sound", Vector2i(400, 200), &dummy),
      MenuEntry("Music", Vector2i(400, 400), &dummy));
  }

  auto controlsMenu(Game game) {
    return new TitleMenu(game,
      MenuEntry("Keyboard", Vector2i(400, 200), g => pushMenu(keyboardMenu(g))),
      MenuEntry("Gamepad" , Vector2i(400, 400), g => pushMenu(gamepadMenu(g))));
  }

  auto keyboardMenu(Game game) {
    auto dummy(Game game) {}

    return new TitleMenu(game,
      MenuEntry("Keyboard", Vector2i(400, 200), &dummy),
      MenuEntry("Gamepad" , Vector2i(400, 400), &dummy));
  }

  auto gamepadMenu(Game game) {
    auto dummy(Game game) {}

    return new TitleMenu(game,
      MenuEntry("Keyboard", Vector2i(400, 200), &dummy),
      MenuEntry("Gamepad" , Vector2i(400, 400), &dummy));
  }

  auto creditsMenu(Game game) {
    return new TitleMenu(game,
      MenuEntry("D"       , Vector2i(400, 100), g => browse("http://dlang.org")),
      MenuEntry("Allegro" , Vector2i(400, 200), g => browse("https://allegro.cc/")),
      MenuEntry("Aseprite", Vector2i(400, 300), g => browse("http://aseprite.org")),
      MenuEntry("LMMS"    , Vector2i(400, 400), g => browse("https://lmms.io")),
      MenuEntry("Tiled"   , Vector2i(400, 500), g => browse("http://mapeditor.org")));
  }
}
