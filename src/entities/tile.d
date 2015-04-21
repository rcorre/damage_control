module entities.tile;

import std.conv;
import std.math : abs;
import dau;

class Tile : Entity {
  enum {
    size = 32,
  }

  const {
    int row, col;
    bool canBuild;
  }

  this(TileData data) {
    auto pos = Vector2i(data.col, data.row) * size + Vector2i(size, size) / 2;
    auto sprite = new Sprite(getTexture(data.tilesetName), data.tilesetIdx);
    super(pos, sprite, "tile");
    row = data.row;
    col = data.col;
    canBuild = data.properties.get("canBuild", "false").to!bool;
  }

  int distance(Tile other) {
    return distance(other.row, other.col);
  }

  int distance(int otherRow, int otherCol) {
    return abs(row - otherRow) + abs(col - otherCol);
  }
}
