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
  auto mainMenu(Game game) {
    auto play(Game game)    {
      _menus.back.centerToStack();
      _menus ~= playMenu(game);
      _menus.back.exitToCenter();
    }

    auto options(Game game) { game.states.push(new Battle); }
    auto quit(Game game)    { game.stop(); }

    return new TitleMenu(game,
        MenuEntry("Play"   , Vector2i(300, 200), &play),
        MenuEntry("Options", Vector2i(300, 300), &options),
        MenuEntry("Quit"   , Vector2i(300, 400), &quit));
  }

  auto playMenu(Game game) {
    auto play(Game game) { game.states.push(new Battle); }

    return new TitleMenu(game,
        MenuEntry("Level1", Vector2i(300, 200), &play),
        MenuEntry("Level2", Vector2i(300, 300), &play),
        MenuEntry("Level3", Vector2i(300, 400), &play));
  }
}
