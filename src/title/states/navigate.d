/// Move through menus in the title screen
module title.states.navigate;

import dau;
import title.menu;
import title.title;

/// Show the title screen.
class NavigateMenus : State!(Title, Game) {
  private Array!EventHandler _handlers;

  override {
    void enter(Title title, Game game) {
      _handlers.insert(game.events.onButtonDown("confirm", () =>
            title.select(game)));

      _handlers.insert(game.events.onButtonDown("cancel", &title.popMenu));

      _handlers.insert(game.events.onAxisMoved("move", (pos) {
            title.moveSelection(pos, game);
      }));
    }

    void exit(Title title, Game game) {
      foreach(h ; _handlers) h.unregister();
    }

    void run(Title title, Game game) { }
  }
}
