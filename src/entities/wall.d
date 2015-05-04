module entities.wall;

import std.conv;
import std.math : abs;
import dau;

private enum {
  spriteRow = 3,
  spriteCol = 2,
}

class Wall : Entity {
  int row, col;

  this(Vector2i pos) {
    auto sprite = new Sprite("tileset", spriteRow, spriteCol);
    super(pos, sprite, "wall");
  }
}
