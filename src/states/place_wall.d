module states.place_wall;

import std.range;
import std.array;
import std.random;
import std.algorithm;
import dau;
import jsonizer;
import states.battle;

private enum {
  dataFile   = "data/pieces.json",
  dataSize   = 3,
  spriteSize = 32,
  wallDepth  = -1,
}

/// Player is holding a wall segment they can place with a mouse click
class PlaceWall : State!Battle {
  private {
    Piece _piece;
    Bitmap _tileAtlas;
  }

  override {
    void start(Battle battle) {
      _piece = Piece.random;
      _tileAtlas = battle.game.content.bitmaps.get("tileset");
    }

    void run(Battle battle) {
      auto game = battle.game;
      auto mousePos = game.input.mousePos;

      _piece.draw(game.input.mousePos, _tileAtlas, game.renderer);

      auto coord = battle.map.gridCoordAt(mousePos);
      if (!battle.map.contains(coord)) return;

      auto tile = battle.map.tileAt(coord);

      if (game.input.mouseReleased(MouseButton.lmb) && !tile.hasWall) {
        // place wall
        tile.hasWall = true;

        // see if any surrounding tile is now part of an enclosed area
        foreach(neighbor ; battle.map.around(coord)) {
          /*
          auto enclosure = findEnclosure(battle.map, neighbor);

          if (enclosure !is null) {
            foreach(idx, isEnclosed ; enclosure) {
              if (isEnclosed) battle.map.tileAt(idx).sprite.tint = Color.red;
            }
            break;
          }
          */
        }

        // create a new wall
        _piece = Piece.random();
      }
    }
  }
}

private:
/*
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
*/

/// A group of walls the player can place during the building stage
struct Piece {
  PieceLayout layout;

  static Piece random() {
    return Piece(_data.randomSample(1).front);
  }

  void draw(Vector2i center, Bitmap bmp, Renderer renderer) {
    RenderInfo ri;
    ri.bmp = bmp;
    ri.depth = wallDepth;

    foreach(i, spriteIdx ; layout) {
      if (spriteIdx == 0) continue;

      ri.transform = center + wallOffset(i);
      ri.region = spriteRect(spriteIdx, bmp);

      renderer.draw(ri);
    }
  }

  private auto wallOffset(ulong idx) {
    int relRow = ((cast(int) idx) / dataSize) - 1;
    int relCol = ((cast(int) idx) % dataSize) - 1;

    return Vector2i(relCol, relRow) * spriteSize;
  }

  private auto spriteRect(uint idx, Bitmap bmp) {
    int nCols = bmp.width / spriteSize;
    int row = idx / nCols;
    int col = idx % nCols;
    return Rect2i(col * spriteSize, row * spriteSize, spriteSize, spriteSize);
  }
}

alias PieceLayout = uint[dataSize * dataSize];

PieceLayout[] _data;

static this() {
  _data = dataFile.readJSON!(PieceLayout[]);
}
