module battle.entities.tilemap;

import std.conv      : to;
import std.array     : array;
import std.range     : chunks;
import std.format    : format;
import std.algorithm : map;
import dau;
import dtiled;
import jsonizer;
import constants;
import battle.battle;
import battle.entities.construct;

private enum {
  tileDepth = 0,
  circuitDepth = 1,
  featureDepth = 2,
  circuitColOffset = 5, // offset of circuit animation
}

class Tile {
  private bool _enclosed;
  private Construct _construct;

  const {
    bool canBuild;
    Rect2i textureRect;
  }

  bool isEnclosed() { return _enclosed; }
  void isEnclosed(bool val) {
    _enclosed = val;
    if (_construct !is null) _construct.enclosed = val;
  }

  bool hasWall()    { return wall !is null; }
  bool hasReactor() { return reactor !is null; }
  bool hasTurret()  { return turret !is null; }

  bool isEmpty()           { return _construct is null; }
  bool hasLargeConstruct() { return _construct !is null && _construct.isLarge; }

  auto wall()    { return cast(Wall)    _construct; }
  auto turret()  { return cast(Turret)  _construct; }
  auto reactor() { return cast(Reactor) _construct; }

  auto construct() { return _construct; }
  void construct(Construct c) {
    assert(c is null || construct is null, "cannot overwrite construct");
    _construct = c;
  }

  this(Rect2i textureRect, bool canBuild) {
    this.textureRect = textureRect;
    this.canBuild = canBuild;
  }
}

struct TileMap {
  OrthoMap!Tile _map;
  alias _map this;

  this(MapData data) {
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

    _map = OrthoMap!Tile(tiles, data.tileWidth, data.tileHeight);

    // create reactors
    foreach(rect ; data.getLayer("reactors").objects) {
      // each reactor is represented by a rect.
      auto coord = RowCol(rect.y / data.tileHeight - 1,
          rect.x / data.tileWidth  - 1);
      auto pos = _map.tileOffset(coord.south.east).as!Vector2f;
      place(new Reactor, coord);
    }
  }

  void draw(Bitmap tileAtlas, Renderer renderer, Vector2i animationOffset) {
    auto tileBatch    = SpriteBatch(tileAtlas, tileDepth);
    auto constructBatch = SpriteBatch(tileAtlas, featureDepth);

    foreach(coord, tile; _map) {
      Sprite sprite;

      sprite.region    = tile.textureRect;
      sprite.transform = _map.tileCenter(coord).as!Vector2f;
      sprite.color     = Color.white;
      sprite.centered  = true;

      tileBatch ~= sprite;

      // draw circuit animation
      if (tile.isEnclosed) {
        // hack because of my messy tilemapping
        if (sprite.region.x <= 2 * _map.tileWidth) { // inside of main set
          sprite.region.x += circuitColOffset * _map.tileWidth + animationOffset.x;
        }
        else {
          sprite.region.x = (1 + circuitColOffset) * _map.tileWidth + animationOffset.x;
          sprite.region.y = _map.tileHeight;
        }

        tileBatch ~= sprite;
      }

      if (tile._construct !is null) {
        tile._construct.draw(constructBatch, animationOffset);
      }
    }

    renderer.draw(tileBatch);
    renderer.draw(constructBatch);
  }

  bool canBuildAt(RowCol coord) {
    return
      tileAt(coord).isEmpty                  &&
      tileAt(coord).canBuild                 &&
      !tileAt(coord.north).hasLargeConstruct &&
      !tileAt(coord.west).hasLargeConstruct  &&
      !tileAt(coord.north.west).hasLargeConstruct;
  }

  void place(Construct construct, RowCol coord) {
    auto tile = tileAt(coord);
    assert(tile.construct is null,
        "Tried to build %s at %s, but tile already contains %s"
        .format(typeid(construct), coord, typeid(tile.construct)));

    tile.construct = construct;
    construct.position = construct.isLarge ?
      tileOffset(coord.south.east).as!Vector2f :
      tileCenter(coord).as!Vector2f;
  }

  void clear(RowCol coord) {
    tileAt(coord).construct = null;
  }
}
