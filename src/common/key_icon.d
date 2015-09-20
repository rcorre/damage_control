module common.key_icon;

import cid;

private enum {
  pixelBuffer = 8
}

void drawKeyIcon(string keyname, Vector2i center, Game game) {
  auto font = game.graphics.fonts.get("Mecha", 16);

  Text text;

  text.text      = keyname;
  text.color     = Color.white;
  text.centered  = true;
  text.transform = center;

  RectPrimitive prim;

  prim.rect = Rect2f.centeredAt(
      center,
      font.widthOf(keyname)  + pixelBuffer,
      font.heightOf(keyname) + pixelBuffer);

  prim.color = Color.white;

  auto tb = TextBatch(font, 6);
  auto pb = PrimitiveBatch(5);

  pb ~= prim;
  tb ~= text;

  game.graphics.draw(pb);
  game.graphics.draw(tb);
}
