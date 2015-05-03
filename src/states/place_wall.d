module states.place_wall;

import std.range : front;
import dau;
import entities.tilemap;
import entities.wall;

/// Player is holding a wall segment they can place with a mouse click
class PlaceWall : State!Game {
  private {
    Wall _wall;
    TileMap _map;
  }

  override {
    void enter(Game game) {
      _map = cast(TileMap) game.entities.findEntities("map").front;
      _wall = new Wall(game.input.mousePos);
      game.entities.registerEntity(_wall);
    }

    void update(Game game) {
      auto mousePos = game.input.mousePos;
      _wall.center = _map.tileAt(mousePos).center;
    }
  }
}
