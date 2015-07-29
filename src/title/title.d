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
    TitleMenu _menu;
    EventHandler _handler;
  }

  override {
    void enter(Game game) {
      auto play(Game game)    { game.states.push(new Battle); }
      auto options(Game game) { game.states.push(new Battle); }
      auto quit(Game game)    { game.stop(); }

      _menu = new TitleMenu(
          game,
          MenuEntry("Play"    , Vector2i(400, 200), &play),
          MenuEntry("Options" , Vector2i(400, 300), &options),
          MenuEntry("Quit"    , Vector2i(400, 400), &quit));

      void handleKeyDown(in ALLEGRO_EVENT ev) {
        switch (ev.keyboard.keycode) {
          case ALLEGRO_KEY_J:
            _menu.confirmSelection(game);
            break;
          case ALLEGRO_KEY_K:
            _menu.backOut();
            break;
          case ALLEGRO_KEY_W:
            _menu.moveSelectionUp();
            break;
          case ALLEGRO_KEY_S:
            _menu.moveSelectionDown();
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
      _menu.update(game);
    }
  }
}
