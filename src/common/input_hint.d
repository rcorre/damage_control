module common.key_icon;

import std.range     : iota, chunks, lockstep;
import std.algorithm : map;
import cid;
import constants;

private enum {
  startY = screenH * 1.00, // y position where hints enter the screen
  endY   = screenH * 0.95, // y position where hints are shown

  iconBuffer = Vector2f(5, 5), // space between key icon and action
  hintBuffer = 16,             // horizontal space between subsequent hints
}

void drawInputHints(Game game, float progress, string[] pairs...) {
  auto xPos(size_t i) { return (i + 1) * screenW / (pairs.length / 2 + 1); }
  auto yPos = lerp(startY, endY, progress);

  // space the hint positions evenly along the bottom of the screen
  auto positions = iota(0, pairs.length / 2)
    .map!(i => Vector2f(xPos(i), yPos));

  auto font = game.graphics.fonts.get("Mecha", 16);

  auto textBatch = TextBatch(font, 6);
  auto primBatch = PrimitiveBatch(5);

  foreach(pair, topLeft ; pairs.chunks(2).lockstep(positions)) {
    auto key    = pair[0];
    auto action = pair[1];

    auto keySize = font.sizeOf(key) + iconBuffer;

    // draw the key name
    Text text;

    text.text      = key;
    text.color     = lerp(Color.black, Color.white, progress);
    text.transform = topLeft;

    textBatch ~= text;

    // draw the name of the action bound to that key
    text.text      = action;
    text.color     = lerp(Color.black, Color.gray, progress);
    text.transform = topLeft + Vector2f(keySize.x + iconBuffer.x, 0);

    textBatch ~= text;

    // draw a box around the key name
    RectPrimitive box;

    box.rect  = Rect2f(topLeft - iconBuffer / 2, keySize.x, keySize.y);
    box.color = Color.white;

    primBatch ~= box;

    topLeft.x += keySize.x + hintBuffer + font.widthOf(action);
  }

  game.graphics.draw(textBatch);
  game.graphics.draw(primBatch);
}
