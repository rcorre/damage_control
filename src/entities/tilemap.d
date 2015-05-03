module entities.tilemap;

import std.algorithm, std.range, std.string, std.math, std.file, std.path, std.conv;
import dau;
import dtiled;
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
      if (gid & TiledFlag.flipHorizontal) {
        sprite.flip = Texture.Flip.horizontal;
      }
      bool canBuild = tileset.tileProperties(gid).get("canBuild", "false").to!bool;
      auto tile = new Tile(pos, row, col, sprite, canBuild);
      entities.registerEntity(tile);
      _tiles[tile.row] ~= tile;
    }

    auto area = Rect2i(0, 0, numCols * map.tilewidth, numRows * map.tileheight);
    super(area, "map");
  }

  @property int numTiles() const { return numRows * numCols; }

  Tile tileAt(ulong idx) {
    return tileAt(idx / numCols, idx % numCols);
  }

  Tile tileAt(ulong row, ulong col) {
    return (row < 0 || col < 0 || row >= numRows || col >= numCols) ? null : _tiles[row][col];
  }

  Tile tileAt(Vector2i pos) {
    int row = pos.y / tileHeight;
    int col = pos.x / tileWidth;
    return tileAt(row, col);
  }

  /// return tiles adjacent to tile
  auto adjacent(Tile tile) {
    int row = tile.row;
    int col = tile.col;

    return [
      tileAt(row - 1, col),
      tileAt(row, col - 1),
      tileAt(row + 1, col),
      tileAt(row, col + 1),
    ]
    .filter!(x => x !is null);
  }

  /// return tiles adjacent to or diagonal to tile
  auto surrounding(Tile tile) {
    int row = tile.row;
    int col = tile.col;

    return [
      tileAt(row - 1, col - 1),
      tileAt(row - 1, col + 1),
      tileAt(row + 1, col - 1),
      tileAt(row + 1, col + 1),
    ]
    .filter!(x => x !is null)
    .chain(adjacent(tile));
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
