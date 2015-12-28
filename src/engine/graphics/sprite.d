/**
 * Provides types and logic for bitmap-based batched drawing.
 */
module engine.graphics.sprite;

import std.container : Array;
import std.range     : isInputRange;

import allegro5.allegro;

import engine.geometry;
import engine.graphics.blend;
import engine.graphics.color;
import engine.graphics.bitmap;

/**
 * Stores information used to draw some section of a bitmap to the display.
 */
struct Sprite {
  Rect2i          region;
  bool            centered;
  Color           color = Color.white;
  Bitmap.Flip     flip;
  Transform!float transform;
}

/**
 * Groups draw calls for `Sprites` that share the same bitmap and depth.
 */
struct SpriteBatch {
  Bitmap          bitmap;
  int             depth;
  Array!Sprite    sprites;
  Blender         blender;
  Transform!float transform;

  /**
   * Create a batch for drawing sprites with the same bitmap and depth.
   *
   * Params:
   *  bitmap = bitmap to use as a sprite sheet
   *  depth = sprite layer; more positive means 'higher'
   *  transform = camera transformation to apply to all sprites in batch
   */
  this(Bitmap bitmap, int depth, Transform!float transform = Transform!float.init) {
    this.bitmap    = bitmap;
    this.depth     = depth;
    this.transform = transform;
  }


  /**
   * Insert a single sprite into the batch to be drawn this frame.
   *
   * Params:
   *  sprite = sprite to draw with this batch's bitmap.
   */
  void opCatAssign(Sprite sprite) {
    sprites.insert(sprite);
  }

  /**
   * Insert a range of sprites into the batch to be drawn this frame.
   *
   * Params:
   *  sprites = a range of sprites to draw with this batch's bitmap.
   */
  void opCatAssign(R)(R r) if (isInputRange!R && is(ElementType!R == Sprite)) {
    sprites.insert(r);
  }

  package void flip(ALLEGRO_TRANSFORM origTrans) {
    ALLEGRO_TRANSFORM curTrans;

    // improve performance for drawing the same bitmap multiple times
    al_hold_bitmap_drawing(true);
    scope(exit) al_hold_bitmap_drawing(false);

    foreach(sprite ; sprites) {
      al_identity_transform(&curTrans);

      if (sprite.centered) {
        // translate by half the width and length to center the sprite
        al_translate_transform(&curTrans,
            -sprite.region.width / 2, -sprite.region.height / 2);
      }

      // compose with the transform for this individual sprite
      al_compose_transform(&curTrans, sprite.transform.transform);

      // compose with the current global transform
      al_compose_transform(&curTrans, &origTrans);

      al_use_transform(&curTrans);

      bitmap.drawRegion(sprite.region, sprite.color, sprite.flip);
    }
  }
}

