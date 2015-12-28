/**
 * Provides types and logic for batched text drawing.
 */
module engine.graphics.text;

import std.container : Array;
import std.range     : isInputRange, ElementType;

import allegro5.allegro;
import allegro5.allegro_ttf;

import engine.geometry;
import engine.graphics.font;
import engine.graphics.blend;
import engine.graphics.color;

struct Text {
  bool            centered;
  Color           color = Color.black;
  string          text;
  Transform!float transform;
}

struct TextBatch {
  Font            font;
  int             depth;
  Array!Text      texts;
  Blender         blender;
  Transform!float transform;

  /**
   * Create a batch for drawing text with the same font and depth.
   *
   * Params:
   *  bitmap = bitmap to use as a sprite sheet
   *  depth = sprite layer; more positive means 'higher'
   *  transform = camera transformation to apply to all text in batch
   */
  this(Font font, int depth, Transform!float transform = Transform!float.init) {
    assert(font !is null, "null font given to TextBatch. I see problems ahead...");
    this.font      = font;
    this.depth     = depth;
    this.transform = transform;
  }

  /**
   * Insert a single sprite into the batch to be drawn this frame.
   *
   * Params:
   *  text = text to draw with this batch's font.
   */
  void opCatAssign(Text text) {
    texts.insert(text);
  }

  /**
   * Insert a range of text objects into the batch to be drawn this frame.
   *
   * Params:
   *  text = a range of text objects to draw with this batch's font.
   */
  void opCatAssign(R)(R r) if (isInputRange!R && is(ElementType!R == Text)) {
    texts.insert(r);
  }

  package void flip(ALLEGRO_TRANSFORM origTrans) {
    ALLEGRO_TRANSFORM curTrans;

    // improve performance for drawing the same bitmap multiple times
    al_hold_bitmap_drawing(true);
    scope(exit) al_hold_bitmap_drawing(false);

    foreach(text ; texts) {
      al_identity_transform(&curTrans);

      if (text.centered) {
        auto w = font.widthOf(text.text);
        auto h = font.heightOf(text.text);

        // translate by half the width and length to center the text
        al_translate_transform(&curTrans, -w / 2, -h / 2);
      }

      // compose with the transform for this individual text
      al_compose_transform(&curTrans, text.transform.transform);

      // compose with the global transform
      al_compose_transform(&curTrans, &origTrans);

      al_use_transform(&curTrans);

      font.draw(text.text, text.color);
    }
  }
}

