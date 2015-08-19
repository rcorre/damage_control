module battle.entities.cursor;

import dau;
import dtiled;
import battle.entities.tilemap;
import battle.battle;

private enum {
  cursorDepth = 6,
  cursorSize  = 16,
  cursorColor = Color(0.0, 0.5 ,0.0, 0.5),
  cursorSpeed = 150
}

class Cursor {
  enum Direction : uint { north, south, east, west }

  private {
    TileMap      _map;
    Vector2f     _velocity = Vector2f.zero;
    Vector2f     _position = Vector2f.zero;
  }

  this(Battle battle) {
    _map = battle.map;
  }

  @property {
    ref auto coord() { return _map.coordAtPoint(_position); }
    auto tile() { return _map.tileAt(coord); }
    auto topLeft() { return _map.tileOffset(coord).as!Vector2f; }
    auto center() { return _map.tileCenter(coord).as!Vector2f; }
  }

  void startMoving(Vector2f direction) {
    _velocity = direction * cursorSpeed;
  }

  void update(float timeElapsed) {
    _position += _velocity * timeElapsed;

    _position.x = _position.x.clamp(0, _map.tileWidth * _map.numCols);
    _position.y = _position.y.clamp(0, _map.tileHeight * _map.numRows);
  }
}
