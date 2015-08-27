module battle.entities.cursor;

import std.algorithm : map, filter;
import dau;
import dtiled;
import constants;
import battle.entities.tilemap;
import battle.entities.construct;
import battle.battle;

class Cursor {
  enum Direction : uint { north, south, east, west }

  private {
    enum speed = 80;

    TileMap  _map;
    Vector2f _velocity = Vector2f.zero;
    Vector2f _position = Vector2f.zero;
  }

  this(Battle battle) {
    _map = battle.map;
  }

  @property {
    auto coord() { return _map.coordAtPoint(_position); }
    auto tile() { return _map.tileAt(coord); }
    auto topLeft() { return _map.tileOffset(coord).as!Vector2f; }
    auto center() { return _map.tileCenter(coord).as!Vector2f; }
  }

  void startMoving(Vector2f direction) {
    // check if we are changing directions
    if (direction.y > 0 && _velocity.y <= 0) {
      _position = _map.tileCenter(coord.south).as!Vector2f;
    }
    else if (direction.y < 0 && _velocity.y >= 0) {
      _position = _map.tileCenter(coord.north).as!Vector2f;
    }
    else if (direction.x > 0 && _velocity.x <= 0) {
      _position = _map.tileCenter(coord.east).as!Vector2f;
    }
    else if (direction.x < 0 && _velocity.x >= 0) {
      _position = _map.tileCenter(coord.west).as!Vector2f;
    }

    _velocity = direction * speed;
  }

  void update(float timeElapsed, bool turboMode) {
    _position += _velocity * timeElapsed * (turboMode ? turboSpeedFactor : 1);

    _position.x = _position.x.clamp(0, _map.tileWidth * _map.numCols);
    _position.y = _position.y.clamp(0, _map.tileHeight * _map.numRows);
  }

  /// Try to place the cursor in a place the player owns.
  /// Used for positioning the cursor at the start of a building phase.
  void positionInPlayerTerritory() {
    auto allReactors = _map.constructs
      .map!(x => cast(Reactor) x)
      .filter!(x => x !is null);

    auto ownedReactors = allReactors.filter!(x => x.enclosed);

    _position = ownedReactors.empty ?
      allReactors.front.center : ownedReactors.front.center;
  }
}
