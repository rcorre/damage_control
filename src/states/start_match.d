module states.start_match;

import dau.all;

/// Start a new match.
class StartMatch : State!Game {
  this() {
    auto mapData = loadTiledMap("./content/maps/map1.json");
  }

  override {
    void enter(Game game) {
    }
  }
}
