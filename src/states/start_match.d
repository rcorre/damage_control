module states.start_match;

import dau;
import entities.tilemap;

/// Start a new match.
class StartMatch : State!Game {
  this() {
  }

  override {
    void enter(Game game) {
      auto mapData = loadTiledMap("./content/maps/map1.json");
      auto map = new TileMap(mapData, game.entities);
      game.entities.registerEntity(map);
    }
  }
}
