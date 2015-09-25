module common.key_icon;

import std.range     : iota, chunks, lockstep;
import std.algorithm : map;
import cid;
import constants;

private enum {
  startY = screenH * 1.00, // y position where hints enter the screen
  endY   = screenH * 0.95, // y position where hints are shown

  iconMargin = Vector2f(5, 5), // space between key icon and action

  hintTime = 0.5f, // duration of hint fade-in (secs)

  iconColor   = Color(1,1,1,0.7),
  textColor = Color(1,1,1,0.5),
}

struct InputHint {
  private {
    string[] _prevHints;
    string[] _currentHints;

    float _progress = 0f;
  }

  void update(float time) {
    _progress = clamp(_progress + time / hintTime, 0, 1);
  }

  void draw(Game game, string[] pairs...) {
    auto xPos(size_t i) { return (i + 1) * screenW / (pairs.length / 2 + 1); }
    auto yPos = lerp(startY, endY, _progress);

    // space the hint positions evenly along the bottom of the screen
    auto positions = iota(0, pairs.length / 2)
      .map!(i => Vector2f(xPos(i), yPos));

    auto font = game.graphics.fonts.get("Mecha", 16);

    auto textBatch = TextBatch(font, 6);
    auto primBatch = PrimitiveBatch(5);

    // draw each (key, action, position) tuple
    foreach(pair, topLeft ; pairs.chunks(2).lockstep(positions)) {
      immutable key    = pair[0];
      immutable action = pair[1];

      auto keySize = font.sizeOf(key) + iconMargin;

      // draw the key name
      Text text;

      text.text      = key;
      text.color     = lerp(Color.black, iconColor, _progress);
      text.transform = topLeft;

      textBatch ~= text;

      // draw the name of the action bound to that key
      text.text      = action;
      text.color     = lerp(Color.black, textColor, _progress);
      text.transform = topLeft + Vector2f(keySize.x + iconMargin.x, 0);

      textBatch ~= text;

      // draw a box around the key name
      RectPrimitive box;

      box.rect  = Rect2f(topLeft - iconMargin / 2, keySize.x, keySize.y);
      box.color = lerp(Color.black, iconColor, _progress);

      primBatch ~= box;
    }

    game.graphics.draw(textBatch);
    game.graphics.draw(primBatch);
  }
}
