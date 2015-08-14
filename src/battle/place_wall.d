module battle.place_wall;

import std.range;
import std.array;
import std.random;
import std.algorithm;
import dau;
import dtiled;
import jsonizer;
import tilemap;
import battle.battle;
import battle.timed_phase;

private enum {
  dataFile   = "data/pieces.json",
  dataSize   = 5,
  spriteSize = 16,
  wallDepth  = 3,
  phaseTime  = 15,
}

/// Player is holding a wall segment they can place with a mouse click
class PlaceWall : TimedPhase {
  private {
    Piece       _piece;
    Bitmap      _tileAtlas;
    SoundSample _soundOk;
    SoundSample _soundBad;
  }

  this(Battle battle) {
    super(battle, phaseTime);
    _soundOk  = battle.game.audio.getSample("place_ok");
    _soundBad = battle.game.audio.getSample("place_bad");
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);
      _piece = Piece.random;
      _tileAtlas = battle.game.bitmaps.get("tileset");
    }

    void run(Battle battle) {
      super.run(battle);

      _piece.draw(battle.cursor.topLeft, _tileAtlas, battle.game.renderer);
    }

    void onConfirm(Battle battle) {
      auto map = battle.map;

      auto wallCoords = map.maskCoordsAround(battle.cursor.coord, _piece.layout);

      // No room to place piece
      if (!wallCoords.all!(x => map.canBuildAt(x))) {
        _soundBad.play();
        return;
      }

      _soundOk.play();

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

    void onRotate(Battle battle, bool clockwise) {
      _piece.rotate(clockwise);
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

  void draw(Vector2f center, Bitmap bmp, Renderer renderer) {
    auto batch = SpriteBatch(bmp, wallDepth);

    foreach(coord ; RowCol(0,0).span(dataSize, dataSize)) {
      // no wall at this slot
      if (!layout[coord.row][coord.col]) continue;

      auto offset = Vector2i(cast(int) coord.col - 2, cast(int) coord.row - 2) * spriteSize;

      uint[3][3] mask;

      rectGrid(layout).createMaskAround!(x => x)(coord, mask);

      Sprite sprite;
      sprite.transform = center + offset;
      sprite.region = getWallSpriteRegion(mask, spriteSize, spriteSize);

      batch ~= sprite;
    }

    renderer.draw(batch);
  }

  void rotate(bool clockwise) {
    PieceLayout newLayout;
    foreach(row ; 0..dataSize) {
      foreach(col ; 0..dataSize) {
        if (clockwise)
          newLayout[row][col] = layout[col][dataSize - 1 - row];
        else
          newLayout[col][dataSize - 1 - row] = layout[row][col];
      }
    }
    layout = newLayout;
  }
}

alias PieceLayout = uint[dataSize][dataSize];

PieceLayout[] _data;

static this() {
  _data = dataFile.readJSON!(PieceLayout[]);
}
