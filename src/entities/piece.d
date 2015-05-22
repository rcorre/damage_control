module entities.piece;

import std.random : randomSample;
import dau;
import jsonizer;

/*
private enum {
  dataFile = "data/pieces.json",
  dataSize = 3,
}

/// A group of walls the player can place during the building stage
class Piece {
  Wall[] walls;
  private Vector2i _prevPos;

  this(Vector2i center, EntityManager entities) {
    auto data = _data.randomSample(1).front;

    foreach(i, spriteIdx ; data) {
      if (spriteIdx == 0) continue;

      auto sprite = new Sprite(getTexture("tileset"), spriteIdx);
      auto pos = center + getOffset(i, sprite);
      auto wall = new Wall(pos, sprite);
      walls ~= wall;
      entities.registerEntity(wall);
    }

    _prevPos = center;
  }

  @property void center(Vector2i pos) {
    auto offset = pos - _prevPos;
    foreach(wall ; walls) {
      wall.center = wall.center + offset;
    }
    _prevPos = pos;
  }

  private auto getOffset(ulong idx, Sprite sprite) {
    int relRow = ((cast(int) idx) / dataSize) - 1;
    int relCol = ((cast(int) idx) % dataSize) - 1;
    return Vector2i(relCol * sprite.width, relRow * sprite.height);
  }
}

private:
alias PieceData = uint[9];

PieceData[] _data;

static this() {
  _data = dataFile.readJSON!(PieceData[]);
}
*/
