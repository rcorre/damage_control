module constants;

import cid.geometry;
import cid.graphics.color;

enum {
  screenW   = 800,
  screenH   = 600,
  frameRate = 60,

  tileSize = 16,

  // mechanics
  ammoPerReactor = 6,     /// How much ammo each reactor can refill
  tilesPerTurret = 30,    /// A new turret is rewarded for this many tiles
  initialTurretCount = 3, /// You can place this many turrets on the first round

  turboSpeedFactor = 2, /// How much to multiply cursor speed in turbo mode
}

enum SpriteRegion {
  crossHairs   = Rect2i(6 * 16, 9 * 16, 16, 16),
  rocket       = Rect2i(6 * 16, 8 * 16, 16, 16),
  particle     = Rect2i(7 * 16, 8 * 16, 16, 16),
  reactor      = Rect2i(2 * 16, 6 * 16, 32, 32),
  turretBase   = Rect2i(0 * 16, 6 * 16, 32, 32),
  turret2      = Rect2i(0 * 16, 8 * 16, 32, 32), // turret with 2 ammo
  turret1      = Rect2i(2 * 16, 8 * 16, 32, 32), // turret with 1 ammo
  turret0      = Rect2i(4 * 16, 8 * 16, 32, 32), // turret with 0 ammo
  turretCursor = Rect2i(6 * 16, 6 * 16, 32, 32), // turret placement cursor
}

enum SpriteSheet {
  tileset = "tileset"
}

/// The layer at which to draw various entities. Higher is drawn above lower.
enum DrawDepth {
  // construction
  newWall   = 3,  /// a wall that is about to be placed
  newTurret = 4, /// a turret that is about to be placed

  // conflict
  particle   = 2, /// the trail left by a rocket
  projectile = 3, /// a rocket or other projectile in motion
  enemy      = 3, /// a hovering enemy
  explosion  = 3, /// a rocket/enemy explosion
  crosshair  = 4, /// UI element for aiming

  // construction
  tile    = 0, /// a tile in the map
  circuit = 1, /// the effect drawn over enclosed terrain
  feature = 2, /// objects on top of tiles

  // overlay
  overlayBackground = 5, /// drawn behind overlay text but above everything else
  overlayText       = 6, /// text shown over everything else in the game
  overlayHighlight  = 7, /// highlight areas of the map

  // menus
  menuText = 6,
}

enum ScoreFactor {
  territory = 5,  // points per tile enclosed in player territory
  enemy     = 20, // points per enemy destroyed
  reactor   = 80, // points per reactor enclosed
}

enum PhaseTime {
  chooseBase   = 10,
  placeTurrets = 15,
  fight        = 20,
  placeWalls   = 20,
}

/// common colors used throughout the game
enum Tint {
  subdued   = Color(1f,1f,1f,0.25f), // for dimmed elements
  neutral   = Color(1f,1f,1f,0.5f),  // for active but not highlighted elements
  highlight = Color(1f,1f,1f,1f),    // for emphasized elements
}
