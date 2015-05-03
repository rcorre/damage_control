module entities.wall;

import std.conv;
import std.math : abs;
import dau;

private enum {
  spriteRow = 1,
  spriteCol = 0,
}

class Wall : Entity {
  int row, col;

  this(Vector2i pos) {
    auto sprite = new Sprite("terrain", spriteRow, spriteCol);
    super(pos, sprite, "wall");
  }
}
