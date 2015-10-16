module battle.entities.tilemap;

import std.conv      : to;
import std.array     : array;
import std.range     : chunks;
import std.format    : format;
import std.algorithm : map, find, remove;
import cid;
import dtiled;
import jsonizer;
import constants;
import battle.battle;
import battle.entities.construct;

private enum {
  circuitColOffset = 5, // offset of circuit animation
}

class Tile {
  Color tint = Color.white;

  private {
    bool      _enclosed;
    Construct _construct;
  }

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

  auto wall()    { return cast(Wall)    _construct; }
  auto turret()  { return cast(Turret)  _construct; }
  auto reactor() { return cast(Reactor) _construct; }

  auto construct() { return _construct; }

  private void construct(Construct c) {
    assert(c is null || construct is null, "cannot overwrite construct");
    _construct = c;
  }

  this(Rect2i textureRect, bool canBuild) {
    this.textureRect = textureRect;
    this.canBuild = canBuild;
  }
}

class TileMap {
  OrthoMap!Tile _map;
  alias _map this;

  Construct[] _constructs;

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

  @property auto constructs() { return _constructs[]; }

  @property auto turrets() {
    return _constructs.map!(x => cast(Turret) x).filter!(x => x !is null);
  }

  @property auto reactors() {
    return _constructs.map!(x => cast(Reactor) x).filter!(x => x !is null);
  }

  void draw(Bitmap tileAtlas, Renderer renderer, Vector2i animationOffset, Transform!float trans) {
    auto tileBatch    = SpriteBatch(tileAtlas, DrawDepth.tile, trans);
    auto constructBatch = SpriteBatch(tileAtlas, DrawDepth.feature, trans);

    foreach(coord, tile; _map) {
      Sprite sprite;

      sprite.region    = tile.textureRect;
      sprite.transform = _map.tileCenter(coord).as!Vector2f;
      sprite.color     = tile.tint;
      sprite.centered  = true;

      tileBatch ~= sprite;

      // draw circuit animation to visually indicate enclosed tiles
      if (tile.isEnclosed) {
        sprite.region = SpriteRegion.circuits;
        sprite.region.x += animationOffset.x;
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
    return tileAt(coord).isEmpty && tileAt(coord).canBuild;
  }

  void place(Construct construct, RowCol topLeft) {
    construct.center = tileOffset(topLeft).as!Vector2f + construct.size / 2;

    // depending on the size of the construct, it may cover more than 1 tile
    auto bottomRight = topLeft + RowCol(1, 1) * construct.gridSize;

    bool enclosed = true;

    // give each covered tile a reference to the construct
    foreach(coord ; topLeft.span(bottomRight)) {
      auto tile = tileAt(coord);

      assert(tile.construct is null,
          "Tried to place %s at %s, but tile already contains %s"
          .format(typeid(construct), coord, typeid(tile.construct)));

      tile.construct = construct;
      enclosed = enclosed && tile.isEnclosed;
    }

    construct.enclosed = enclosed;

    _constructs ~= construct;
  }

  void clear(RowCol coord) {
    auto removeMe = tileAt(coord).construct;
    if (removeMe !is null) {
      _constructs = _constructs.remove!(x => x == removeMe);
    }

    tileAt(coord).construct = null;
  }

  /**
   * Set the sprite of the wall at the given coord based on surrounding walls.
   *
   * A wall's sprite is determined by the pattern of surrounding walls.
   * When a wall is destroyed or a new wall is placed, this needs to be
   * re-evaluated for all nearby walls.
   */
  void regenerateWallSprite(RowCol coord) {
    // just ignore if there is no wall here
    // easier to check here than have all callers verify this
    if (!tileAt(coord).hasWall) return;

    uint[3][3] mask;

    createMaskAround!(x => x.hasWall ? 1 : 0)(this, coord, mask);
    tileAt(coord).wall.adjustSprite(mask);
  }
}
