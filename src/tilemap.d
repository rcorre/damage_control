module tilemap;

import std.conv      : to;
import std.array     : array;
import std.range     : chunks;
import std.algorithm : map;
import dau;
import dtiled;

private enum tileDepth = 0;

struct Tile {
  bool hasWall;
  const {
    bool canBuild;
    Rect2i textureRect;
  }

  this(Rect2i textureRect, bool canBuild) {
    this.textureRect = textureRect;
    this.canBuild = canBuild;
  }
}

alias TileMap = OrthoMap!Tile;

void draw(TileMap map, Bitmap tileAtlas, Renderer render) {
  RenderInfo ri;
  ri.bmp = tileAtlas;

  foreach(coord, tile; map) {
    auto pos = Vector2f(coord.col * map.tileWidth, coord.row * map.tileHeight);

    ri.region    = tile.textureRect;
    ri.transform = Transform!float(pos);
    ri.depth     = tileDepth;

    render.draw(ri);
  }
}

auto buildMap(MapData data) {
  auto layer = data.getLayer("ground");

  auto buildTile(TiledGid gid) {
    auto tileset = data.getTileset(gid);

    auto region = Rect2i(
        tileset.tileOffsetX(gid),
        tileset.tileOffsetY(gid),
        tileset.tileWidth,
        tileset.tileHeight);

    bool canBuild = tileset.tileProperties(gid).get("canBuild", "false").to!bool;

    return Tile(region, canBuild);
  }

  auto tiles = layer.data.map!buildTile.chunks(layer.numCols).map!(x => x.array).array;

  return TileMap(data.tileWidth, data.tileHeight, tiles);
}
