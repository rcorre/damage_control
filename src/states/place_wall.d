module states.place_wall;

import std.range;
import std.array;
import std.random;
import std.algorithm;
import dau;
import jsonizer;
import dtiled.map;
import dtiled.coords;
import dtiled.algorithm;
import states.battle;

private enum {
  dataFile   = "data/pieces.json",
  dataSize   = 3,
  spriteSize = 32,
  wallDepth  = 1,
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
      auto map = battle.map;

      auto centerCoord = map.gridCoordAt(mousePos);
      _piece.draw(map.tileCenter(centerCoord).as!Vector2i, _tileAtlas, game.renderer);

      if (game.input.mouseReleased(MouseButton.lmb)) {
        auto wallTiles = map.tilesMasked(centerCoord, _piece.mask);

        // No room to place piece
        if (wallTiles.any!(x => !x.canBuild && x.hasWall)) return;

        foreach(tile ; wallTiles) tile.hasWall = true;

        // check if any surrounding tile is now part of an enclosed area
        foreach(coord ; battle.map.coordsAround(centerCoord)) {
          auto enclosure = findEnclosure!(x => x.canBuild && !x.hasWall)(map.tiles, coord);

          foreach(tile ; enclosure) {
            tile.isEnclosed = true;
          }
        }

        _piece = Piece.random(); // generate a new piece
      }
    }
  }
}

private:
/// A group of walls the player can place during the building stage
struct Piece {
  PieceLayout layout;

  static Piece random() {
    return Piece(_data.randomSample(1).front);
  }

  @property auto mask() {
    return layout[].chunks(3).map!(x => x.array).array;
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
