module states.place_wall;

import std.range;
import std.array;
import std.algorithm;
import dau;
import entities.tile;
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

        auto fill = enclosedRegion(_map, tile);
        if (fill !is null) {
          foreach(fillme ; fill) {
            fillme.sprite.tint = Color.red;
          }
        }
      }
    }
  }
}

private:
Tile[] enclosedRegion(TileMap map, Tile tile) {
  // shared between calls on the same map
  static bool[] visited;

  // if length is incorrect, this is the first call on this map, so initialize visited
  if (visited.length != map.numTiles) {
    visited = new bool[map.numTiles];
  }

  foreach(neighbor ; map.surrounding(tile)) {
    if (floodFill(map, neighbor, visited)) {
      return visited.enumerate.filter!(x => x.value).map!(x => map.tileAt(x.index)).array;
    }
  }

  return null;
}

bool floodFill(TileMap map, Tile source, ref bool[] visited) {
  bool hitEdge = false;
  visited.fill(false);

  void flood(int row, int col) {
    int idx = row * col;
    auto tile = map.tileAt(idx);
    hitEdge = hitEdge || (tile is null);

    if (hitEdge || visited[idx] || tile.wall !is null) return;

    visited[idx] = true;

    // cardinal directions
    flood(row - 1 , col);
    flood(row + 1 , col);
    flood(row     , col - 1);
    flood(row     , col + 1);

    // diagonals
    flood(row - 1 , col - 1);
    flood(row - 1 , col + 1);
    flood(row + 1 , col - 1);
    flood(row + 1 , col + 1);
  }

  flood(source.row, source.col);

  return !hitEdge;
}
