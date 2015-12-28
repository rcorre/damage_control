/**
 * Provides a simple wrapper around an ALLEGRO_BITMAP
 */
module engine.graphics.bitmap;

import engine.allegro;
import engine.geometry;
import engine.graphics.color;

/**
 * Wrapper around an ALLEGRO_BITMAP*.
 */
struct Bitmap {
  ALLEGRO_BITMAP *_bmp;

  alias _bmp this;

  /// Flags that determine how bitmap is flipped while drawing
  enum Flip {
    none = 0,                             /// Do not flip.
    horizontal = ALLEGRO_FLIP_HORIZONTAL, /// Flip across Y axis
    vertical = ALLEGRO_FLIP_VERTICAL,     /// Flip across X axis
    both = horizontal | vertical          /// Flip across X and Y axis
  }

  @property {
    /// Width of the bitmap in pixels.
    int width() { return al_get_bitmap_width(_bmp); }

    /// Height of the bitmap in pixels.
    int height() { return al_get_bitmap_height(_bmp); }
  }

  /**
   * Render the entire bitmap to the screen.
   * The position, scale, and rotation are controlled by the currently set Transform.
   *
   * Params:
   *  tint = color used to shade drawn bitmap
   *  flip = how to flip bitmap while drawing
   */
  void draw(Color tint = Color.white, Flip flip = Flip.none) {
    al_draw_tinted_bitmap(_bmp, tint, 0, 0, flip);
  }

  /**
   * Render a sub-bitmap to the screen
   *
   * Params:
   *  area = region of bitmap to render
   *  tint = color used to shade drawn bitmap
   *  flip = how to flip bitmap while drawing
   */
  void drawRegion(Rect2i area, Color tint = Color.white, Flip flip = Flip.none) {
    al_draw_tinted_bitmap_region(_bmp, tint, area.x, area.y, area.width, area.height, 0, 0, flip);
  }

  /**
   * Load a bitmap from the image at the given path.
   * The path must exist and point to a file with a format supported by Allegro.
   */
  static Bitmap load(string path) {
    import std.string : toStringz;
    return Bitmap(al_load_bitmap(path.toStringz));
  }
}
