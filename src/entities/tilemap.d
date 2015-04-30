module entities.tilemap;

import std.algorithm, std.string, std.math, std.file, std.path, std.conv;
import dau;
import tiled;
import entities.tile;

class TileMap : Entity {
  const {
    int numRows, numCols;
    int tileWidth, tileHeight;
  }

  this(TiledMap map, EntityManager entities) {
    numCols = map.width;
    numRows = map.height;
    tileWidth = map.tilewidth;
    tileHeight = map.tileheight;
    _tiles = new Tile[][numRows];

    auto layer = map.getLayer("terrain");
    foreach(idx, gid ; map.getLayer("terrain").data) {
      // first figure out where the tile is positioned based on its index
      int row = cast(int) layer.idxToRow(idx);
      int col = cast(int) layer.idxToCol(idx);
      auto pos = Vector2i(col * map.tilewidth, row * map.tileheight);

      // now examine tile data from tileset
      auto tileset = map.getTileset(gid);
      auto sprite = new Sprite("terrain", tileset.tileRow(gid), tileset.tileCol(gid));
      bool canBuild = tileset.tileProperties(gid).get("canBuild", "false").to!bool;
      auto tile = new Tile(pos, row, col, sprite, canBuild);
      entities.registerEntity(tile);
      _tiles[tile.row] ~= tile;
    }

    auto area = Rect2i(0, 0, numCols * map.tilewidth, numRows * map.tileheight);
    super(area, "map");
  }

  auto tileAt(int row, int col) {
    return (row < 0 || col < 0 || row >= numRows || col >= numCols) ? null : _tiles[row][col];
  }

  auto tileAt(Vector2i pos) {
    int row = pos.y / tileHeight;
    int col = pos.x / tileWidth;
    return tileAt(row, col);
  }

  /// return tiles adjacent to tile
  auto neighbors(Tile tile) {
    Tile[] neighbors;
    int row = tile.row;
    int col = tile.col;
    if (row > 0)           { neighbors ~= tileAt(row - 1, col); }
    if (col > 0)           { neighbors ~= tileAt(row, col - 1); }
    if (row < numRows - 1) { neighbors ~= tileAt(row + 1, col); }
    if (col < numCols - 1) { neighbors ~= tileAt(row, col + 1); }
    return neighbors;
  }

  auto tilesInRange(Tile center, int minRange, int maxRange) {
    Tile[] tiles;
    for (int row = center.row - maxRange ; row <= center.row + maxRange ; ++row) {
      for (int col = center.col - maxRange ; col <= center.col + maxRange ; ++col) {
        auto tile = tileAt(row, col);
        auto dist = abs(row - center.row) + abs(col - center.col);
        if (tile !is null && dist >= minRange && dist <= maxRange) {
          tiles ~= tile;
        }
      }
    }
    return tiles;
  }

  private:
  Tile[][] _tiles;
}
