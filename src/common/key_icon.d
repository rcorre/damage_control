module common.key_icon;

import std.range : chunks;
import cid;
import constants;

private enum {
  pixelBuffer = Vector2f(8, 8)
}

void drawInputHints(Game game, string[] pairs...) {
  auto topLeft = Vector2f(screenW * 0.1, screenH * 0.8);
  auto font = game.graphics.fonts.get("Mecha", 16);

  auto textBatch = TextBatch(font, 6);
  auto primBatch = PrimitiveBatch(5);

  foreach(pair ; pairs.chunks(2)) {
    auto key         = pair[0];
    auto description = pair[1];

    auto keySize = font.sizeOf(key) + pixelBuffer;

    Text text;

    text.text      = key;
    text.color     = Color.white;
    text.transform = topLeft;

    textBatch ~= text;

    text.text      = description;
    text.color     = Color.gray;
    text.transform = topLeft + Vector2f(keySize.x, 0);

    textBatch ~= text;

    RectPrimitive box;

    box.rect  = Rect2f(topLeft - pixelBuffer / 2, keySize.x, keySize.y);
    box.color = Color.white;

    primBatch ~= box;
  }

  game.graphics.draw(textBatch);
  game.graphics.draw(primBatch);
}
