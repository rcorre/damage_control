module battle.entities.construct;

import std.range;
import engine;
import jsonizer;
import constants;

private enum {
  wallLayoutFile = "./data/walls.json",
}

/// Represents an entity that is placed on a tile
abstract class Construct {
  Vector2f center;
  bool enclosed;

  @property auto size() { return Vector2i(1,1) * tileSize * gridSize; }
  @property auto topLeft() { return center - size / 2; }
  @property void topLeft(Vector2f val) { center = val + size / 2; }

abstract:
  /// Region covered, in number of tiles (the region is always square).
  @property int gridSize();
  void draw(ref SpriteBatch batch, Vector2i animationOffset);
}

class Wall : Construct {
  private Rect2i _spriteRegion;

  override @property int gridSize() { return 1; }

  override void draw(ref SpriteBatch batch, Vector2i animationOffset) {
    Sprite sprite;

    sprite.transform = center;
    sprite.centered  = true;
    sprite.region    = _spriteRegion;
    sprite.region.x += animationOffset.x;
    sprite.region.y += animationOffset.y;

    batch ~= sprite;
  }

  void adjustSprite(uint[3][3] mask) {
    _spriteRegion = spriteRegionFor(mask);
  }

  static auto spriteRegionFor(uint[3][3] mask) {
    // don't care about corners
    mask[0][0] = 0;
    mask[0][2] = 0;
    mask[2][0] = 0;
    mask[2][2] = 0;

    auto r = _layouts.find!(x => x.mask == mask);
    assert(!r.empty, "no data for wall layout %s".format(mask));

    auto layout = r.front;
    return Rect2i(tileSize * layout.col, tileSize * layout.row, tileSize,
        tileSize);
  }
}

class Turret : Construct {
  enum maxAmmo = 2;

  private float _angle = 0f;
  int ammo;

  override @property int gridSize() { return 2; }
  @property int ammoNeeded() { return max(maxAmmo - ammo, 0) ; }

  override void draw(ref SpriteBatch batch, Vector2i animationOffset) {
    Sprite sprite;
    sprite.color     = Color.white;
    sprite.centered  = true;

    // draw the base
    sprite.transform = center;
    sprite.region = SpriteRegion.turretBase;

    batch ~= sprite;

    // unlike the base, the top rotates and changes sprite based on ammo count
    sprite.transform.angle = _angle;
    switch (ammo) {
      case 2  : sprite.region = SpriteRegion.turret2; break;
      case 1  : sprite.region = SpriteRegion.turret1; break;
      case 0  : sprite.region = SpriteRegion.turret0; break;
      default : assert(0, "unknown ammo count for turret");
    }

    batch ~= sprite;
  }

  void aimAt(Vector2f target) {
    _angle = (target - center).angle;
  }

  /// Refill ammo by amount up to the given amount, and return the leftover.
  int refillAmmo(int amount) {
    assert(ammo >= 0);

    int refill = min(amount, maxAmmo - ammo);
    ammo += refill;
    return amount - refill;
  }
}

class Reactor : Construct {
  override @property int gridSize() { return 2; }

  override void draw(ref SpriteBatch batch, Vector2i animationOffset) {
    Sprite sprite;

    sprite.centered = true;
    sprite.transform = center;

    sprite.region = SpriteRegion.reactor;

    // only animate the reactor if it is enclosed
    if (enclosed) {
      sprite.region.x += animationOffset.x;
      sprite.region.y += animationOffset.y;
    }

    batch ~= sprite;
  }
}

private:
struct WallLayout {
  mixin JsonizeMe;
  @jsonize {
    uint[3][3] mask;
    uint row, col;
  }
}

WallLayout[] _layouts;

static this() {
  _layouts = wallLayoutFile.readJSON!(WallLayout[]);
}
