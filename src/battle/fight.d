module battle.fight;

import std.array     : array;
import std.range     : walkLength;
import std.algorithm : sort, count, filter;
import dau;
import dtiled;
import battle.battle;
import battle.timed_phase;
import tilemap;

private enum {
  phaseTime      = 15,
  cannonCooldown = 4,

  projectileSize  = Vector2i(12, 8),
  projectileTint  = Color(1, 1, 1, 0.5),
  projectileSpeed = 500,
  projectileDepth = 3,

  explosionTime  = 0.30f,
  explosionSize  = 40,
  explosionTint  = Color(1, 1, 1, 1.0),
  explosionDepth = 3,

  targetDepth       = 6,
  targetSpriteRow   = 8,
  targetSpriteCol   = 2,
  targetSpriteSheet = "tileset",
}

/// Base battle state for fight vs ai or fight vs player.
abstract class Fight : TimedPhase {
  private {
    alias ProjectileList = DropList!(Projectile, x => x.duration < 0);
    alias ExplosionList = DropList!(Explosion, x => x.duration < 0);

    private ProjectileList _projectiles;
    private ExplosionList _explosions;
    private Cannon[] _cannons;
    private Bitmap _projectileBmp, _explosionBmp, _targetBmp;
  }

  this(Battle battle) {
    super(battle, phaseTime);
    _projectiles = new ProjectileList;
    _explosions = new ExplosionList;

    _targetBmp = battle.game.bitmaps.get(targetSpriteSheet);

    // don't forget to re-target the display after creating the bitmaps
    scope(exit) al_set_target_backbuffer(battle.game.display.display);

    // create the projectile bitmap
    _projectileBmp = Bitmap(al_create_bitmap(projectileSize.x,
          projectileSize.y));
    al_set_target_bitmap(_projectileBmp);
    al_clear_to_color(projectileTint);

    // create the explosion bitmap
    _explosionBmp = Bitmap(al_create_bitmap(explosionSize, explosionSize));
    al_set_target_bitmap(_explosionBmp);
    al_clear_to_color(Color(0,0,0,0));
    al_draw_filled_ellipse(
        explosionSize / 2, explosionSize / 2, // center x,y
        explosionSize / 2, explosionSize / 2, // radius x,y
        explosionTint);                       // color
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);

      // create an entry in the cannon list for each cannon in player territory
      _cannons = battle.map.allCoords
        .filter!(x => battle.map.tileAt(x).hasCannon)
        .map!(x => Cannon(battle.map.tileOffset(x + RowCol(1,1)).as!Vector2f))
        .array;
    }

    void exit(Battle battle) { super.exit(battle); }

    void run(Battle battle) {
      super.run(battle);

      auto game = battle.game;
      auto map = battle.map;

      processProjectiles(battle);
      processExplosions(game);

      foreach(ref cannon ; _cannons) {
        cannon.cooldown -= game.deltaTime;
      }

      battle.cannonTarget = battle.cursor.center;

      drawTarget(battle.game.renderer, battle.cursor.center);
    }

    override void onConfirm(Battle battle) {
      // fire the cannons with the lowest cooldowns first
      _cannons.sort!((a,b) => a.cooldown < b.cooldown);

      if (_cannons.front.cooldown < 0) {
        _cannons.front.cooldown = cannonCooldown;

        spawnProjectile(_cannons.front.position, battle.cursor.center);
      }
    }
  }

  ~this() {
    al_destroy_bitmap(_projectileBmp);
    al_destroy_bitmap(_explosionBmp);
  }

  void onProjectileExplode(Battle battle, Vector2f position, float radius) {
    auto coord = battle.map.coordAtPoint(position);
    if (battle.map.tileAt(coord).hasWall) {
      destroyWall(battle, coord);
    }
  }

  void spawnProjectile(Vector2f origin, Vector2f target) {
    auto path = target - origin; // path along which projectile will travel

    Projectile proj;
    proj.position = origin;
    proj.velocity = path.normalized * projectileSpeed;
    proj.duration = path.len / projectileSpeed;
    _projectiles.insert(proj);
  }

  private:
  void processProjectiles(Battle battle) {
    auto batch = SpriteBatch(_projectileBmp, projectileDepth);

    foreach(ref proj ; _projectiles) {
      proj.duration -= battle.game.deltaTime;

      if (proj.duration < 0) {
        // turn this projectile into an explosion
        createExplosion(proj.position);
        onProjectileExplode(battle, proj.position, explosionSize);
        continue;
      }

      proj.position += proj.velocity * battle.game.deltaTime;

      Sprite sprite;
      sprite.region          = Rect2i(Vector2i.zero, projectileSize);
      sprite.transform       = proj.position;
      sprite.color           = Color.white;
      sprite.transform.angle = proj.velocity.angle;

      // draw the projectile as a 'trail' of fading rects
      while (sprite.color.a > 0) {
        batch ~= sprite;
        sprite.color.a -= 0.15;
        sprite.transform.pos -= proj.velocity * battle.game.deltaTime;

        batch ~= sprite;
      }
    }

    battle.game.renderer.draw(batch);
  }

  void processExplosions(Game game) {
    auto batch = SpriteBatch(_explosionBmp, explosionDepth);

    foreach(ref expl ; _explosions) {
      expl.duration -= game.deltaTime;

      // scale about the center
      Sprite sprite;

      sprite.centered = true;
      sprite.region = Rect2i(0, 0, explosionSize, explosionSize);
      sprite.transform.pos = expl.position;
      sprite.transform.scale = (expl.duration > explosionTime / 2) ?
        Vector2f(2,2) * (1 - expl.duration / explosionTime) :
        Vector2f(1,1);

      // fade as time passes
      sprite.color = Color.clear.lerp(Color.white, expl.duration / explosionTime);

      batch ~= sprite;
    }

    game.renderer.draw(batch);
  }

  void destroyWall(Battle battle, RowCol wallCoord) {
    auto map = battle.map;
    map.tileAt(wallCoord).construct = Construct.none;

    foreach(neighbor ; wallCoord.adjacent(Diagonals.yes)) {
      if (map.tileAt(neighbor).isEnclosed &&
          map.enclosedCoords!(x => x.hasWall)(neighbor, Diagonals.yes).empty)
      {
        // the tile was previously enclosed but no longer is.
        // clear the enclosed state of all connected tiles with a flood fill
        foreach(ref tile ; map.floodTiles!(x => x.isEnclosed)(neighbor, Diagonals.yes)) {
          tile.isEnclosed = false;
        }
      }
    }
  }

  void drawTarget(Renderer renderer, Vector2f pos) {
    Sprite sprite;

    sprite.transform = pos;
    sprite.centered = true;
    sprite.region = Rect2i(16 * targetSpriteCol, 16 * targetSpriteRow, 16, 16);

    auto batch = SpriteBatch(_targetBmp, targetDepth);
    batch ~= sprite;
    renderer.draw(batch);
  }

  protected:
  bool allProjectilesExpired() { return _explosions.empty && _projectiles.empty; }

  void createExplosion(Vector2f pos) {
    _explosions.insert(Explosion(pos));
  }
}

struct Projectile {
  Vector2f position;
  Vector2f velocity;
  float duration;
}

private:
struct Explosion {
  Vector2f position;
  float duration;

  this(Vector2f position) {
    // center the rectangle on the given point
    this.position = position;
    this.duration = explosionTime;
  }
}

struct Cannon {
  Vector2f position;
  float cooldown;

  this(Vector2f position) {
    this.position = position;
    this.cooldown = 0;
  }
}
