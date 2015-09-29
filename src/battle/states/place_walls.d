module battle.states.place_walls;

import std.range;
import std.array;
import std.random;
import std.algorithm;
import cid;
import dtiled;
import jsonizer;
import constants;
import common.input_hint;
import battle.battle;
import battle.entities;
import battle.states.timed_phase;

private enum {
  dataFile   = "data/pieces.json",
  dataSize   = 5,
}

/// Player is holding a wall segment they can place with a mouse click
class PlaceWalls : TimedPhase {
  private {
    Piece     _piece;
    Bitmap    _tileAtlas;
    SoundBank _soundOk;
    SoundBank _soundBad;
    InputHint _hint;
  }

  this(Battle battle) {
    super(battle, PhaseTime.placeWalls);
    _soundOk  = battle.game.audio.getSoundBank("place_ok");
    _soundBad = battle.game.audio.getSoundBank("place_bad");
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);
      _piece = Piece.random;
      _tileAtlas = battle.game.graphics.bitmaps.get("tileset");

      battle.cursor.positionInPlayerTerritory();
    }

    void run(Battle battle) {
      super.run(battle);

      _piece.draw(battle.cursor.topLeft, _tileAtlas, battle.game.graphics);

      _hint.update(battle.game.deltaTime);
      _hint.draw(battle.game, Button.up, Button.down, Button.left, Button.right,
          Button.build, Button.rotateL, Button.rotateR);
    }

    void exit(Battle battle) {
      super.exit(battle);

      // record the count of tiles and reactors the player managed to enclose
      battle.player.statsThisRound.tilesEnclosed =
        cast(int) battle.map.allTiles.count!(x => x.isEnclosed);

      battle.player.statsThisRound.reactorsEnclosed =
        cast(int) battle.map.constructs
        .count!(x => x.enclosed && (cast(Reactor) x) !is null);
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
      battle.shakeScreen(ScreenShakeIntensity.placeWall);

      foreach(coord ; wallCoords) {
        map.place(new Wall, coord);

        // placing a wall may adjust the area around it
        foreach(neighbor ; coord.adjacent(Diagonals.yes)) {
          // it may have formed a new enclosed area...
          auto encloseMe = map
            .enclosedTiles!(x => x.hasWall)(neighbor, Diagonals.yes)
            .filter!(x => x.canBuild);

          foreach(tile ; encloseMe) tile.isEnclosed = true;

          // and it may change the sprites of nearby walls for tiling effects
          map.regenerateWallSprite(neighbor);
        }
      }

      // we need to determine the sprite for the placed walls too
      foreach(coord ; wallCoords) map.regenerateWallSprite(coord);

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
    auto batch = SpriteBatch(bmp, DrawDepth.newWall);

    foreach(coord ; RowCol(0,0).span(dataSize, dataSize)) {
      // no wall at this slot
      if (!layout[coord.row][coord.col]) continue;

      auto offset = Vector2i(cast(int) coord.col - 2, cast(int) coord.row - 2) *
        tileSize;

      uint[3][3] mask;

      rectGrid(layout).createMaskAround!(x => x)(coord, mask);

      Sprite sprite;
      sprite.transform = center + offset;
      sprite.region = Wall.spriteRegionFor(mask);

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
