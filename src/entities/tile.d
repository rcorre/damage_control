module entities.tile;

import std.conv;
import std.math : abs;
import dau;
import entities.wall;

class Tile : Entity {
  Wall wall;

  const {
    int row, col;
    bool canBuild;
  }

  this(Vector2i pos, int row, int col, Sprite sprite, bool canBuild) {
    auto offset = Vector2i(sprite.width, sprite.height) / 2;
    super(pos + offset, sprite, "tile");
    this.row = row;
    this.col = col;
    this.canBuild = canBuild;
  }

  int distance(Tile other) {
    return distance(other.row, other.col);
  }

  int distance(int otherRow, int otherCol) {
    return abs(row - otherRow) + abs(col - otherCol);
  }
}
