/// Title screen state.
module title.title;

import std.math      : pow;
import std.process   : browse;
import std.container : Array;
import battle.battle;
import dau;
import title.menu;
import title.keyboard_menu;
import title.gamepad_menu;
import title.states.navigate;
import jsonizer;

private enum {
  underlineSize = Vector2i( 150,   6),

  fontName  = "Mecha",
  fontSize  = 36,
  textDepth = 1,
}

/// Show the title screen.
class Title : State!Game {
  private {
    Array!TitleMenu          _menus;
    TitleMenu                _poppedMenu;
    StateStack!(Title, Game) _states;
    Bitmap                   _underlineBmp;
    Font                     _font;
  }

  this(Game game) {
    // generate bitmap used for menu underline
    _underlineBmp = Bitmap(al_create_bitmap(underlineSize.x, underlineSize.y));
    al_set_target_bitmap(_underlineBmp);
    al_clear_to_color(Color.white);
    al_set_target_backbuffer(game.display.display);

    // load font for menu text
    _font = game.fonts.get(fontName, fontSize);
  }

  ~this() {
    al_destroy_bitmap(_underlineBmp);
  }

  override {
    void enter(Game game) {
      _menus ~= mainMenu(game);
      _menus.back.moveTo(targetX(0));
      _menus.back.activate();
      _states.push(new NavigateMenus);
    }

    void exit(Game game) {
      _states.pop();
      _menus.clear();
      _poppedMenu = null;
    }

    void run(Game game) {
      auto spriteBatch = SpriteBatch(_underlineBmp, textDepth);
      auto textBatch   = TextBatch(_font, textDepth);

      foreach(menu ; _menus) {
        menu.update(game.deltaTime);
        menu.draw(spriteBatch, textBatch);
      }
      if (_poppedMenu) {
        _poppedMenu.update(game.deltaTime);
        _poppedMenu.draw(spriteBatch, textBatch);
      }

      game.renderer.draw(spriteBatch);
      game.renderer.draw(textBatch);

      _states.run(this, game);
    }
  }

package:
  void select(Game game) {
    _menus.back.confirmSelection(game);
  }

  void moveSelection(Vector2f direction, Game game) {
    if      (direction.y > 0) _menus.back.moveSelectionDown();
    else if (direction.y < 0) _menus.back.moveSelectionUp();
    else if (direction.x < 0) popMenu();
    else if (direction.x > 0) _menus.back.confirmSelection(game);
  }

  void pushMenu(TitleMenu newMenu) {
    _menus.back.deactivate();
    _menus ~= newMenu;

    foreach(i, menu ; _menus[].enumerate!int) {
      menu.moveTo(targetX(i));
    }

    newMenu.activate();
  }

  void popMenu() {
    if (_menus.length == 1) return;

    _poppedMenu = _menus.back;
    _menus.removeBack();

    foreach(i, menu ; _menus[].enumerate!int) {
      menu.moveTo(targetX(i));
    }

    _poppedMenu.moveTo(900);
    _poppedMenu.deactivate();
    _menus.back.activate();
  }

  private:
  auto targetX(int menuIdx) {
    int n = cast(int) _menus.length;
    return 500 - 140 * n + 220 * menuIdx;
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
    return new KeyboardMenu(game, game.events.controlScheme);
  }

  auto gamepadMenu(Game game) {
    return new GamepadMenu(game, game.events.controlScheme);
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
