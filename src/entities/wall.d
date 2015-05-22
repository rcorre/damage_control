/*
module entities.wall;

import std.math      : abs;
import std.range     : chunks, empty, front;
import std.array     : array;
import std.format    : format;
import std.algorithm : find;
import dau;
import jsonizer;
import entities.tile;

private enum {
  dataFile = "data/walls.json"
}

class Wall : Entity {
  this(Vector2i pos, Sprite sprite = null) {
    sprite = (sprite is null) ?  new Sprite("tileset", 3, 2) : sprite;
    super(pos, sprite, "wall");
  }

  void regenSprite(int row, int col, Tile[] neighbors) {
    _sprite = pickSprite(row, col, neighbors);
  }

  Sprite pickSprite(int row, int col, Tile[] neighbors) {
    int[9] layout;
    layout[4] = 1;  // center tile is always filled

    foreach(tile ; neighbors) {
      if (tile.wall is null) continue;

      int relRow = tile.row - row + 1;
      int relCol = tile.col - col + 1;

      int idx = relRow * 3 + relCol;

      assert(idx > 0 && idx < 9,
          "tile idx %d out of range (row: %d, col: %d)".format(idx, relRow, relCol));

      layout[idx] = 1;
    }

    auto data = _wallData.find!(x => x.layout == layout);
    assert(!data.empty, "no data has layout %s".format(layout));
    return new Sprite("tileset", data.front.row, data.front.col);
  }
}

private:
/// determines how a wall should be drawn based on its surroundings
struct WallData {
  mixin JsonizeMe;

  @jsonize {
    int[9] layout;
    int row;
    int col;
  }
}

WallData[] _wallData;

static this() {
  _wallData = dataFile.readJSON!(WallData[]);
}
*/
