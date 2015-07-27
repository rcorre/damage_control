module battle.cursor;

import dau;
import dtiled;
import tilemap;
import battle.battle;

private enum {
  cursorDepth = 6
  cursorSize  = 16,
  cursorColor = Color(0.0, 0.5 ,0.0, 0.5)
}

class Cursor {
  enum Direction : uint { north, south, east, west }

  bool visible;

  private {
    TileMap      _map;
    RowCol       _coord;
    Bitmap       _bitmap;
    EventManager _events;

    TimerHandler[4] _moveTimers;
  }

  this(Battle battle) {
    _map = battle.map;
    _events = battle.game.events;

    // create the cursor bitmap
    _bitmap = Bitmap(al_create_bitmap(cursorSize, cursorSize));
    al_set_target_bitmap(_bitmap);
    al_clear_to_color(cursorColor);

    al_set_target_backbuffer(battle.game.display.display);
  }

  ~this() {
    al_destroy_bitmap(_bitmap);
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

  void draw(Renderer renderer) {
    if (!visible) return;

    auto batch = SpriteBatch(_bitmap, cursorDepth);
    Sprite sprite;

    sprite.color     = Color.white;
    sprite.centered  = true;
    sprite.transform = this.center;
    sprite.region    = Rect2i(0, 0, cursorSize, cursorSize);

    batch ~= sprite;

    renderer.draw(batch);
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
