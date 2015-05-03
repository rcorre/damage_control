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
      auto tile = _map.tileAt(mousePos);
      _wall.center = tile.center;

      if (game.input.mouseReleased(MouseButton.lmb) && (tile.wall is null)) {
        // place wall and create a new wall
        tile.wall = _wall;
        _wall = new Wall(tile.center);
        game.entities.registerEntity(_wall);
      }
    }
  }
}
