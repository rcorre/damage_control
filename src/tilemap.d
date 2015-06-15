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
  featureDepth = 1,
  nodeDepth = 1,
  wallLayoutFile = "./data/walls.json",
  cannonSpriteRow = 6,
  cannonSpriteCol = 0,
  nodeSpriteRow = 6,
  nodeSpriteCol = 2,
  cannonSize = 32, // width and height of cannon sprite in pixels
  nodeSize = 32,   // width and height of node sprite in pixels
}

enum Construct {
  none,
  node,
  wall,
  cannon,
}

class Tile {
  Construct construct;
  bool isEnclosed;

  const {
    bool canBuild;
    Rect2i textureRect;
  }

  @property bool hasWall() { return construct == Construct.wall; }
  /// only true if the tile is the top-left of a node (which covers 4 tiles)
  @property bool hasNode() { return construct == Construct.node; }
  /// only true if the tile is the top-left of a cannon (which covers 4 tiles)
  @property bool hasCannon() { return construct == Construct.cannon; }
  @property bool isEmpty() { return construct == Construct.none; }
  @property bool canPlaceWall() { return isEmpty && canBuild; }
  @property bool canPlaceCannon() { return isEmpty && canBuild && isEnclosed; }

  this(Rect2i textureRect, bool canBuild) {
    this.textureRect = textureRect;
    this.canBuild = canBuild;
  }
}

alias TileMap = OrthoMap!Tile;

void draw(TileMap map, Bitmap tileAtlas, Renderer render) {
  RenderInfo ri;
  ri.bmp   = tileAtlas;

  foreach(coord, tile; map.tiles) {
    auto pos = Vector2f(coord.col * map.tileWidth, coord.row * map.tileHeight);

    ri.depth     = tileDepth;
    ri.region    = tile.textureRect;
    ri.transform = Transform!float(pos);
    ri.color     = tile.isEnclosed ? Color.red : Color.white;

    render.draw(ri);

    // don't shade in the construct on top of the tile
    ri.color = Color.white;
    // draw constructs above tiles
    ri.depth = featureDepth;

    final switch (tile.construct) with (Construct) {
      case wall:
        uint[3][3] layout;
        map.createMaskAround!(x => x.hasWall ? 1 : 0)(coord, layout);

        ri.region = getWallSpriteRegion(layout, map.tileWidth, map.tileHeight);
        render.draw(ri);
        break;
      case cannon:
        ri.region = Rect2i(
            cannonSpriteCol * map.tileWidth,
            cannonSpriteRow * map.tileHeight,
            cannonSize,
            cannonSize);

        render.draw(ri);
        break;
      case node:
        ri.region = Rect2i(
            nodeSpriteCol * map.tileWidth,
            nodeSpriteRow * map.tileHeight,
            nodeSize,
            nodeSize);

        render.draw(ri);
        break;
      case none:
        break;
    }
  }
}

auto buildMap(MapData data) {
  auto buildTile(TiledGid groundGid) {
    auto tileset = data.getTileset(groundGid);

    auto region = Rect2i(
        tileset.tileOffsetX(groundGid),
        tileset.tileOffsetY(groundGid),
        tileset.tileWidth,
        tileset.tileHeight);

    bool canBuild = tileset.tileProperties(groundGid).get("canBuild", "false").to!bool;

    return new Tile(region, canBuild);
  }

  // build ground
  auto tiles = data.getLayer("ground") // grab the layer named ground
    .data                              // iterate over the GIDs in that layer
    .map!(x => buildTile(x))           // use the gid to build a tile at that coord
    .chunks(data.numCols)              // chunk into rows
    .map!(x => x.array)                // create an array from each row
    .array;                            // create an array of all the row arrays

  auto tileMap = TileMap(tiles, data.tileWidth, data.tileHeight);

  // create nodes
  foreach(rect ; data.getLayer("nodes").objects) {
    // each node is represented by a rect whose top-left corner is in the top-left tile of that node
    auto coord = RowCol(rect.y / data.tileHeight - 1, rect.x / data.tileWidth - 1);
    tileMap.tileAt(coord).construct = Construct.node;
  }

  return tileMap;
}

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

private:
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
