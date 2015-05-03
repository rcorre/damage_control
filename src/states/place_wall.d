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
    void start(Game game) {
      _map = cast(TileMap) game.entities.findEntities("map").front;
      _wall = new Wall(game.input.mousePos);
      game.entities.registerEntity(_wall);
    }

    void update(Game game) {
      auto mousePos = game.input.mousePos;
      auto tile = _map.tileAt(mousePos);
      _wall.center = tile.center;

      if (game.input.mouseReleased(MouseButton.lmb) && (tile.wall is null)) {
        // place wall
        tile.wall = _wall;

        // see if any surrounding tile is now part of an enclosed area
        foreach(neighbor ; _map.surrounding(tile)) {
          auto enclosed = findEnclosure(_map, neighbor);

          if (enclosed !is null) {
            foreach(idx, mark ; enclosed) {
              if (mark) _map.tileAt(idx).sprite.tint = Color.red;
            }
            break;
          }
        }

        // create a new wall
        _wall = new Wall(tile.center);
        game.entities.registerEntity(_wall);
      }
    }
  }
}

private:
bool[] findEnclosure(TileMap map, Tile source) {
  static bool[] visited;
  static bool hitEdge;

  if (visited.length != map.numTiles) {
    visited = new bool[map.numTiles];
  }

  void flood(int row, int col) {
    auto idx = row * map.numRows + col;
    auto tile = map.tileAt(idx);
    hitEdge = hitEdge || (tile is null);

    if (hitEdge || visited[idx] || tile.wall !is null) {
      return;
    }

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

  visited.fill(false);
  hitEdge = false;

  flood(source.row, source.col);

  return hitEdge ? null : visited;
}
