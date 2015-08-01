/// Title screen state.
module title.title;

import std.math      : pow;
import std.container : Array;
import battle.battle;
import dau;
import title.menu;

/// Show the title screen.
class Title : State!Game {
  private {
    Array!TitleMenu _menus;
    TitleMenu       _poppedMenu;
    EventHandler    _handler;
  }

  override {
    void enter(Game game) {
      _menus ~= mainMenu(game);

      void handleKeyDown(in ALLEGRO_EVENT ev) {
        switch (ev.keyboard.keycode) {
          case ALLEGRO_KEY_J:
            _menus.back.confirmSelection(game);
            break;
          case ALLEGRO_KEY_K:
            if (_menus.length > 1) {
              _poppedMenu = _menus.back;
              _menus.removeBack();
              _poppedMenu.centerToExit();
              _menus.back.setSelection(0);
              _menus.back.stackToCenter();
            }
            break;
          case ALLEGRO_KEY_W:
            _menus.back.moveSelectionUp();
            break;
          case ALLEGRO_KEY_S:
            _menus.back.moveSelectionDown();
            break;
          case ALLEGRO_KEY_ESCAPE:
            game.stop();
            break;
          default:
        }
      }

      _handler = game.events.onKeyDown(&handleKeyDown);
    }

    void exit(Game game) {
      _handler.unregister();
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

  auto mainMenu(Game game) {
    auto play(Game game)     { pushMenu(playMenu(game)); }
    auto options(Game game)  { pushMenu(optionsMenu(game)); }
    auto controls(Game game) { pushMenu(controlsMenu(game)); }
    auto credits(Game game)  { pushMenu(creditsMenu(game)); }
    auto quit(Game game)     { game.stop(); }

    return new TitleMenu(game,
        MenuEntry("Play"    , Vector2i(300, 100), &play),
        MenuEntry("Options" , Vector2i(300, 200), &options),
        MenuEntry("Controls", Vector2i(300, 300), &controls),
        MenuEntry("Credits" , Vector2i(300, 400), &credits),
        MenuEntry("Quit"    , Vector2i(300, 500), &quit));
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
    auto dummy(Game game) {}

    return new TitleMenu(game,
        MenuEntry("Sound", Vector2i(400, 200), &dummy),
        MenuEntry("Music", Vector2i(400, 400), &dummy));
  }

  auto creditsMenu(Game game) {
    auto dummy(Game game) {}

    return new TitleMenu(game,
        MenuEntry("D"       , Vector2i(400, 100), &dummy),
        MenuEntry("Allegro" , Vector2i(400, 200), &dummy),
        MenuEntry("Aseprite", Vector2i(400, 300), &dummy),
        MenuEntry("LMMS"    , Vector2i(400, 400), &dummy),
        MenuEntry("Tiled"   , Vector2i(400, 500), &dummy));
  }
}
