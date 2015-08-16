module constants;

import dau.geometry;

enum {
  screenW   = 800,
  screenH   = 600,
  frameRate = 60,
}

enum SpriteRegion {
  crossHairs = Rect2i(6 * 16, 9 * 16, 16, 16),
  rocket     = Rect2i(6 * 16, 8 * 16, 16, 16),
  particle   = Rect2i(7 * 16, 8 * 16, 16, 16),
}
