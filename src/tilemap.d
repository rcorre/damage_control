module tilemap;

import std.conv      : to;
import std.array     : array;
import std.range     : chunks;
import std.format    : format;
import std.algorithm : map;
import dau;
import dtiled;
import jsonizer;
import states.battle;

private enum {
  tileDepth = 0,
  featureDepth = 1,
  reactorDepth = 1,
  wallLayoutFile = "./data/walls.json",
  cannonSpriteRow = 6,
  cannonSpriteCol = 0,
  reactorSpriteRow = 6,
  reactorSpriteCol = 2,
  cannonSize = 32, // width and height of cannon sprite in pixels
  reactorSize = 32,   // width and height of reactor sprite in pixels
}

enum Construct {
  none,
  reactor,
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
  /// only true if the tile is the top-left of a reactor (which covers 4 tiles)
  @property bool hasReactor() { return construct == Construct.reactor; }
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

void draw(TileMap map, Bitmap tileAtlas, Battle battle, Vector2i animationOffset,
          Vector2f cannonTarget)
{
  auto render = battle.game.renderer;
  RenderInfo ri;
  ri.bmp   = tileAtlas;

  foreach(coord, tile; map) {
    ri.depth     = tileDepth;
    ri.region    = tile.textureRect;
    ri.transform = map.tileCenter(coord).as!Vector2f;
    ri.color     = tile.isEnclosed ? Color.red : Color.white;
    ri.centered  = true;

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
        ri.region.x += animationOffset.x;
        ri.region.y += animationOffset.y;
        render.draw(ri);
        break;
      case cannon:
        float angle = (cannonTarget - map.tileCenter(coord).as!Vector2f).angle;
        battle.drawCannon(coord, angle, featureDepth);
        break;
      case reactor:
        ri.transform = map.tileOffset(coord.south.east).as!Vector2f;
        ri.region = Rect2i(
            reactorSpriteCol * map.tileWidth,
            reactorSpriteRow * map.tileHeight,
            reactorSize,
            reactorSize);

        // only animate the reactor if it is enclosed
        if (tile.isEnclosed) {
          ri.region.x += animationOffset.x;
          ri.region.y += animationOffset.y;
        }

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

  // create reactors
  foreach(rect ; data.getLayer("reactors").objects) {
    // each reactor is represented by a rect.
    // place the reactors top-left at the top-left rect
    auto coord = RowCol(rect.y / data.tileHeight - 1,
                        rect.x / data.tileWidth  - 1);
    tileMap.tileAt(coord).construct = Construct.reactor;
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
