module cursor;

import dau;
import dtiled;
import tilemap;
import states.battle;

private enum {
  cursorSize = 16,
  cursorColor = Color(0.0, 0.5 ,0.0, 0.5)
}

class Cursor {
  private {
    TileMap _map;
    RowCol  _coord;
    Bitmap  _bitmap;
  }

  this(Battle battle) {
    _map = battle.map;

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
    auto coord() { return _coord; }
    auto tile() { return _map.tileAt(_coord); }
    auto center() { return _map.tileCenter(_coord).as!Vector2f; }
  }

  void update(Game game, InputManager input) {
    if (input.keyPressed(ALLEGRO_KEY_A)) {
      _coord = _coord.west;
    }
    else if (input.keyPressed(ALLEGRO_KEY_D)) {
      _coord = _coord.east;
    }
    else if (input.keyPressed(ALLEGRO_KEY_W)) {
      _coord = _coord.north;
    }
    else if (input.keyPressed(ALLEGRO_KEY_S)) {
      _coord = _coord.south;
    }
  }

  void draw(Renderer renderer) {
    auto batch = SpriteBatch(_bitmap, 6);
    Sprite sprite;

    sprite.color     = Color.white;
    sprite.centered  = true;
    sprite.transform = _map.tileCenter(_coord).as!Vector2f;
    sprite.region    = Rect2i(0, 0, cursorSize, cursorSize);

    batch ~= sprite;

    renderer.draw(batch);
  }
}
