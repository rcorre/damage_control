module battle.entities.cursor;

import std.algorithm : map, filter;
import engine;
import dtiled;
import constants;
import battle.entities.tilemap;
import battle.entities.construct;
import battle.battle;

class Cursor {
  private {
    enum moveDelay = 0.15;

    TileMap  _map;
    RowCol   _coord;
    Vector2i _velocity;
    float    _tillNextMove;
  }

  this(Battle battle) {
    _map = battle.map;
  }

  @property {
    auto coord() { return _coord; }
    auto tile() { return _map.tileAt(coord); }
    auto topLeft() { return _map.tileOffset(coord).as!Vector2f; }
    auto center() { return _map.tileCenter(coord).as!Vector2f; }
  }

  void startMoving(Vector2i direction) {
    if (_velocity == Vector2i.zero) {
      // just started moving, jump in the given direction
      _coord += RowCol(direction.y, direction.x);
      _tillNextMove = moveDelay;
    }

    _velocity = direction;
  }

  void update(float timeElapsed, bool turboMode) {
    _tillNextMove -= timeElapsed * (turboMode ? turboSpeedFactor : 1);

    if (_tillNextMove < 0) {
      _tillNextMove = moveDelay;
      _coord += RowCol(_velocity.y, _velocity.x);
    }
  }

  /// Try to place the cursor in a place the player owns.
  /// Used for positioning the cursor at the start of a building phase.
  void positionInPlayerTerritory() {
    auto allReactors = _map.constructs
      .map!(x => cast(Reactor) x)
      .filter!(x => x !is null);

    auto ownedReactors = allReactors.filter!(x => x.enclosed);

    _coord = _map.coordAtPoint(ownedReactors.empty ?
        allReactors.front.center : ownedReactors.front.center);
  }
}
