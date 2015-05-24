module tilemap;

import std.conv      : to;
import std.array     : array;
import std.range     : chunks;
import std.format    : format;
import std.algorithm : map;
import dau;
import dtiled;
import jsonizer;

private enum {
  tileDepth = 0,
  wallLayoutFile = "./data/walls.json"
}

class Tile {
  bool hasWall;
  bool isEnclosed;

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
  ri.bmp   = tileAtlas;
  ri.depth = tileDepth;

  foreach(coord, tile; map) {
    auto pos = Vector2f(coord.col * map.tileWidth, coord.row * map.tileHeight);

    ri.region    = tile.textureRect;
    ri.transform = Transform!float(pos);
    ri.color     = tile.isEnclosed ? Color.red : Color.white;

    render.draw(ri);

    if (tile.hasWall) {
      uint[3][3] layout;
      map.createMask!(x => x.hasWall ? 1 : 0)(coord, layout);

      ri.region = getWallSpriteRegion(layout, map.tileWidth, map.tileHeight);
      ri.color = Color.white;
      render.draw(ri);
    }
  }
}

auto buildMap(MapData data) {
  auto buildTile(TiledGid gid) {
    auto tileset = data.getTileset(gid);

    auto region = Rect2i(
        tileset.tileOffsetX(gid),
        tileset.tileOffsetY(gid),
        tileset.tileWidth,
        tileset.tileHeight);

    bool canBuild = tileset.tileProperties(gid).get("canBuild", "false").to!bool;

    return new Tile(region, canBuild);
  }

  auto layer = data.getLayer("ground");

  auto tiles = layer.data.map!buildTile.chunks(layer.numCols).map!(x => x.array).array;

  return TileMap(data.tileWidth, data.tileHeight, tiles);
}

private:
auto getWallSpriteRegion(uint[3][3] mask, int width, int height) {
  // don't care about corners
  mask[0][0] = 0;
  mask[0][2] = 0;
  mask[2][0] = 0;
  mask[2][2] = 0;

  auto r = _layouts.find!(x => x.mask == mask);
  assert(!r.empty, "no data for wall layout %s".format(mask));

  auto layout = r.front;
  return Rect2i(width * layout.col, height * layout.row, width, height);
}

struct WallLayout {
  mixin JsonizeMe;
  @jsonize {
    uint[3][3] mask;
    uint row, col;
  }
}

WallLayout[] _layouts;

static this() {
  _layouts = wallLayoutFile.readJSON!(WallLayout[]);
}
