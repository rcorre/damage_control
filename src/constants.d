module constants;

import std.typecons : tuple;

import engine.geometry;
import engine.events.input;
import engine.graphics.color;

enum {
  gameTitle   = "Damage Control",
  gameVersion = "v0.0.0 (alpha)",

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
  reactor      = Rect2i(2 * 16, 6 * 16, 32, 32),
  turretBase   = Rect2i(0 * 16, 6 * 16, 32, 32),
  turret2      = Rect2i(0 * 16, 8 * 16, 32, 32), // turret with 2 ammo
  turret1      = Rect2i(2 * 16, 8 * 16, 32, 32), // turret with 1 ammo
  turret0      = Rect2i(4 * 16, 8 * 16, 32, 32), // turret with 0 ammo
  turretCursor = Rect2i(6 * 16, 6 * 16, 32, 32), // turret placement cursor
  explosion    = Rect2i(5 * 16, 0 * 16, 32, 32),
  circuits     = Rect2i(4 * 16, 2 * 16, 16, 16),
}

enum SpriteSheet {
  tileset = "tileset"
}

enum Sounds {
  reload     = "menu_move",
  chooseBase = "place_ok",
  scoreEntry = "place_ok", /// showing a score entry in the victory screen
  scoreTotal = "big_boom", /// showing the total score in the victory screen

  menuPop    = "menu_pop",    /// a menu column has been 'exited' and popped off the stack
  menuMove   = "menu_move",   /// sliding the cursor through menus
  menuSelect = "menu_select", /// selecting a menu entry
}

abstract class FontSpec {
  enum title      = tuple("Mecha", 36).expand;
  enum versionTag = tuple("Mecha", 24).expand;
  enum roundScore = tuple("Mecha", 24).expand; // per-round score in victory
  enum totalScore = tuple("Mecha", 36).expand; // overall score in victory
  enum creditsTitle = tuple("Mecha", 48).expand;
  enum creditsBody  = tuple("Mecha", 36).expand;
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

  // icons
  ammoIcon = 5,

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
  fight        = 15,
  placeWalls   = 20,
}

/// common colors used throughout the game
enum Tint {
  subdued   = Color(0.25, 0.25, 0.25, 1f), // for dimmed elements
  neutral   = Color(0.5 , 0.5 , 0.5 , 1f), // for selectable elements
  emphasize = Color(0.75, 0.75, 0.75, 1f), // for important elements
  highlight = Color(1f  , 1f  , 1f  , 1f), // for active/focused elements

  dimBackground = Color(0.0f,0.0f,0.0f,0.8f), // obscure the background
}

/// paths from which to stream music tracks
enum MusicPath {
  title   = "./content/music/title.ogg",
  defeat  = "./content/music/defeat.ogg",
  victory = "./content/music/victory.ogg",
  battle  = "./content/music/stage%d-%d.ogg", // e.g. stage2-3.ogg
}

enum ScreenShakeIntensity {
  placeWall   = 1f,
  chooseBase  = 1f,
  placeTurret = 2f,
  explosion   = 2f
}

enum SaveFile {
  controls = "controls.json",
  progress = "progress.json",
  options  = "options.json",
}
