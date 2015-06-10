module states.place_wall;

import std.range;
import std.array;
import std.random;
import std.algorithm;
import dau;
import jsonizer;
import dtiled.coords;
import dtiled.algorithm;
import tilemap;
import states.battle;
import states.place_cannons;

private enum {
  dataFile   = "data/pieces.json",
  dataSize   = 3,
  spriteSize = 32,
  wallDepth  = 1,
  phaseTime  = 10,
}

/// Player is holding a wall segment they can place with a mouse click
class PlaceWall : State!Battle {
  private {
    Piece _piece;
    Bitmap _tileAtlas;
    float _timer;
  }

  override {
    void start(Battle battle) {
      _piece = Piece.random;
      _tileAtlas = battle.game.content.bitmaps.get("tileset");
      _timer = phaseTime;
    }

    void run(Battle battle) {
      auto game = battle.game;
      auto mousePos = game.input.mousePos;
      auto map = battle.map;

      _timer -= game.deltaTime;

      if (_timer < 0) {
        battle.states.replace(new PlaceCannons);
      }

      auto centerCoord = map.coordAtPoint(mousePos);
      _piece.draw(map.tileOffset(centerCoord).as!Vector2i, _tileAtlas, game.renderer);

      if (game.input.mouseReleased(MouseButton.lmb)) {
        auto wallCoords = map.maskCoordsAround(centerCoord, _piece.mask);
        auto wallTiles = wallCoords.map!(x => map.tileAt(x));

        // No room to place piece
        if (wallTiles.any!(x => !x.canBuild || x.isObstructed)) return;

        foreach(coord ; wallCoords) {
          map.tileAt(coord).construct = Construct.wall;

          // check if any surrounding tile is now part of an enclosed area
          foreach(neighbor ; coord.adjacent(Diagonals.yes)) {
            foreach(tile ; map.enclosedTiles!(x => x.hasWall)(neighbor, Diagonals.yes)) {
              tile.isEnclosed = true;
            }
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
  PieceLayout mask;

  static Piece random() {
    return Piece(_data.randomSample(1).front);
  }

  void draw(Vector2i center, Bitmap bmp, Renderer renderer) {
    RenderInfo ri;
    ri.bmp = bmp;
    ri.depth = wallDepth;

    foreach(coord ; RowCol(0,0).span(dataSize, dataSize)) {
      auto spriteIdx = mask[coord.row][coord.col];
      if (spriteIdx == 0) continue;

      auto offset = Vector2i(cast(int) coord.col - 1, cast(int) coord.row - 1) * spriteSize;
      ri.transform = center + offset;
      ri.region = spriteRect(spriteIdx, bmp);

      renderer.draw(ri);
    }
  }

  void rotate() {
  }

  auto spriteRect(uint idx, Bitmap bmp) {
    int nCols = bmp.width / spriteSize;
    int row = idx / nCols;
    int col = idx % nCols;
    return Rect2i(col * spriteSize, row * spriteSize, spriteSize, spriteSize);
  }
}

alias PieceLayout = uint[dataSize][dataSize];

PieceLayout[] _data;

static this() {
  _data = dataFile.readJSON!(PieceLayout[]);
}
