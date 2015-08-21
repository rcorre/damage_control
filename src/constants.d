module constants;

import dau.geometry;

enum {
  screenW   = 800,
  screenH   = 600,
  frameRate = 60,

  wallSize = 16,
}

enum SpriteRegion {
  crossHairs = Rect2i(6 * 16, 9 * 16, 16, 16),
  rocket     = Rect2i(6 * 16, 8 * 16, 16, 16),
  particle   = Rect2i(7 * 16, 8 * 16, 16, 16),
  reactor    = Rect2i(2 * 16, 6 * 16, 32, 32),
  turretBase = Rect2i(0 * 16, 6 * 16, 32, 32),
  turret2    = Rect2i(0 * 16, 8 * 16, 32, 32), // turret with 2 ammo
  turret1    = Rect2i(2 * 16, 8 * 16, 32, 32), // turret with 1 ammo
  turret0    = Rect2i(4 * 16, 8 * 16, 32, 32), // turret with 0 ammo
}
