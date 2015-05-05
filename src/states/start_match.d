module states.start_match;

import dau;
import dtiled;
import entities.tilemap;
import states.place_wall;

/// Start a new match.
class StartMatch : State!Game {
  override {
    void enter(Game game) {
      auto mapData = TiledMap.load("./content/map/map1.json");
      auto map = new TileMap(mapData, game.entities);
      game.entities.registerEntity(map);
      game.states.push(new PlaceWall);
    }
  }
}
