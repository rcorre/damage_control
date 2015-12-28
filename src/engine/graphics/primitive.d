/**
 * Provides types and logic for batched drawing of graphics primitives.
 */
module engine.graphics.primitive;

import std.container : Array;
import std.range     : isInputRange, ElementType;

import allegro5.allegro;
import allegro5.allegro_primitives;

import engine.geometry;
import engine.graphics.blend;
import engine.graphics.color;

struct RectPrimitive {
  Rect2f   rect;
  float    angle = 0f;
  bool     centered;
  bool     filled;
  float    thickness = 1f;
  Vector2f roundness = Vector2f.zero;
  Color    color     = Color.white;
}

struct PrimitiveBatch {
  int                 depth;
  Array!RectPrimitive prims;
  Blender             blender;
  Transform!float     transform;

  /**
   * Create a batch for drawing graphics primitives at a given depth.
   *
   * Params:
   *  depth = sprite layer; more positive means 'higher'
   *  transform = camera transformation to apply to all primitives in batch
   */
  this(int depth, Transform!float transform = Transform!float.init) {
    this.depth     = depth;
    this.transform = transform;
  }

  /**
   * Insert a single primitive into the batch to be drawn this frame.
   *
   * Params:
   *  prim = primitive to draw with this batch.
   */
  void opCatAssign(RectPrimitive prim) {
    prims.insert(prim);
  }

  /**
   * Insert a range of primitives into the batch to be drawn this frame.
   *
   * Params:
   *  r = a range of primitives to draw with this batch.
   */
  void opCatAssign(R)(R r)
    if (isInputRange!R && is(ElementType!R == RectPrimitive))
  {
    prims.insert(r);
  }

  package void flip(ALLEGRO_TRANSFORM origTrans) {
    ALLEGRO_TRANSFORM trans;

    foreach(prim ; prims) {
      al_identity_transform(&trans);

      if (prim.centered) {
        // translate by half the width and length to center the rect
        al_translate_transform(&trans,
            -prim.rect.width / 2, -prim.rect.height / 2);
      }

      // apply rotation and translation to the primitive
      al_rotate_transform(&trans, prim.angle);
      al_translate_transform(&trans, prim.rect.x, prim.rect.y);

      // apply the global transform
      al_compose_transform(&trans, &origTrans);

      al_use_transform(&trans);

      if (prim.filled) {
        al_draw_filled_rounded_rectangle(
            0, 0,                               // x1, y1
            prim.rect.width, prim.rect.height,  // x2, y2
            prim.roundness.x, prim.roundness.y, // rx, ry
            prim.color);                        // color
      }
      else {
        al_draw_rounded_rectangle(
            0, 0,                               // x1, y1
            prim.rect.width, prim.rect.height,  // x2, y2
            prim.roundness.x, prim.roundness.y, // rx, ry
            prim.color,                         // color
            prim.thickness);                    // thickness
      }
    }
  }
}
