module states.start_match;

import dau;
import dtiled;
import entities.tilemap;

/// Start a new match.
class StartMatch : State!Game {
  this() {
  }

  override {
    void enter(Game game) {
      auto mapData = TiledMap.load("./content/maps/map1.json");
      auto map = new TileMap(mapData, game.entities);
      game.entities.registerEntity(map);
    }
  }
}
