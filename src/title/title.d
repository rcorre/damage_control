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
      _menus.back.moveTo(targetPos(0));

      _handlers.insert(game.events.onButtonDown("confirm",
          () => _menus.back.confirmSelection(game)));

      _handlers.insert(game.events.onButtonDown("cancel", () => popMenu()));

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
      foreach(menu ; _menus) {
        menu.update(game.deltaTime);
        menu.draw(game.renderer);
      }
      if (_poppedMenu) {
        _poppedMenu.update(game.deltaTime);
        _poppedMenu.draw(game.renderer);
      }
    }
  }

  private:
  auto targetPos(int menuIdx) {
    int n = cast(int) _menus.length;
    int x = 500 - 140 * n + 220 * menuIdx;

    return Vector2i(x, 100);
  }

  void pushMenu(TitleMenu newMenu) {
    _menus.back.deselect();
    _menus ~= newMenu;

    foreach(i, menu ; _menus[].enumerate!int) {
      menu.moveTo(targetPos(i));
    }

    newMenu.setSelection(0);
  }

  void popMenu() {
    if (_menus.length == 1) return;

    _poppedMenu = _menus.back;
    _menus.removeBack();

    foreach(i, menu ; _menus[].enumerate!int) {
      menu.moveTo(targetPos(i));
    }

    _poppedMenu.moveTo(Vector2i(900, 100));
    _poppedMenu.deselect();
    _menus.back.setSelection(0);
  }

  auto mainMenu(Game game) {
    return new TitleMenu(game,
      MenuEntry("Play"    , g => pushMenu(playMenu(g))),
      MenuEntry("Options" , g => pushMenu(optionsMenu(g))),
      MenuEntry("Controls", g => pushMenu(controlsMenu(g))),
      MenuEntry("Credits" , g => pushMenu(creditsMenu(g))),
      MenuEntry("Quit"    , g => g.stop()));
  }

  auto playMenu(Game game) {
    auto play(Game game) { game.states.push(new Battle); }

    return new TitleMenu(game,
      MenuEntry("Tutorial", &play),
      MenuEntry("1 Player", &play),
      MenuEntry("2 Player", &play));
  }

  auto optionsMenu(Game game) {
    auto dummy(Game game) {}

    return new TitleMenu(game,
      MenuEntry("Sound", &dummy),
      MenuEntry("Music", &dummy));
  }

  auto controlsMenu(Game game) {
    return new TitleMenu(game,
      MenuEntry("Keyboard", g => pushMenu(keyboardMenu(g))),
      MenuEntry("Gamepad" , g => pushMenu(gamepadMenu(g))));
  }

  auto keyboardMenu(Game game) {
    auto dummy(Game game) {}

    return new TitleMenu(game,
      MenuEntry("Keyboard", &dummy),
      MenuEntry("Gamepad" , &dummy));
  }

  auto gamepadMenu(Game game) {
    auto dummy(Game game) {}

    return new TitleMenu(game,
      MenuEntry("Keyboard", &dummy),
      MenuEntry("Gamepad" , &dummy));
  }

  auto creditsMenu(Game game) {
    return new TitleMenu(game,
      MenuEntry("D"       , g => browse("http://dlang.org")),
      MenuEntry("Allegro" , g => browse("https://allegro.cc/")),
      MenuEntry("Aseprite", g => browse("http://aseprite.org")),
      MenuEntry("LMMS"    , g => browse("https://lmms.io")),
      MenuEntry("Tiled"   , g => browse("http://mapeditor.org")));
  }
}
