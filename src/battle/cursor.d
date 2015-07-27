module battle.cursor;

import dau;
import dtiled;
import tilemap;
import battle.battle;

private enum {
  cursorDepth = 6,
  cursorSize  = 16,
  cursorColor = Color(0.0, 0.5 ,0.0, 0.5)
}

class Cursor {
  enum Direction : uint { north, south, east, west }

  private {
    TileMap      _map;
    RowCol       _coord;
    EventManager _events;

    TimerHandler[4] _moveTimers;
  }

  this(Battle battle) {
    _map = battle.map;
    _events = battle.game.events;
  }

  ~this() {
    foreach(timer ; _moveTimers) {
      if (timer !is null) timer.unregister();
    }
  }

  @property {
    ref auto coord() { return _coord; }
    auto tile() { return _map.tileAt(_coord); }
    auto topLeft() { return _map.tileOffset(_coord).as!Vector2f; }
    auto center() { return _map.tileCenter(_coord).as!Vector2f; }
  }

  void startMoving(Direction direction) {
    auto idx = cast(long) direction;
    if (_moveTimers[idx] is null) {
      shift(direction);
      _moveTimers[idx] = _events.every(100.msecs, ev => shift(direction));
    }
  }

  void stopMoving(Direction direction) {
    auto idx = cast(long) direction;
    if (_moveTimers[idx] !is null) {
      _moveTimers[idx].unregister();
      _moveTimers[idx] = null;
    }
  }

  private void shift(Direction direction) {
    RowCol newCoord;

    final switch (direction) with (Direction) {
      case north:
        newCoord = coord.north;
        break;
      case south:
        newCoord = coord.south;
        break;
      case east:
        newCoord = coord.east;
        break;
      case west:
        newCoord = coord.west;
        break;
    }

    // disallow moving the cursor out of bounds
    if (_map.contains(newCoord)) _coord = newCoord;
  }
}
