module battle.states.fight;

import std.array     : array;
import std.range     : walkLength;
import std.algorithm : sort, count, filter;
import dau;
import dtiled;
import battle.battle;
import battle.states.timed_phase;
import battle.entities;
import battle.entities.tilemap;
import constants;

private enum {
  phaseTime      = 15,
  cannonCooldown = 4,

  projectileDepth = 3,
  particleDepth   = 2,

  explosionTime  = 0.30f,
  explosionSize  = 40,
  explosionTint  = Color(1, 1, 1, 1.0),
  explosionDepth = 3,

  targetDepth       = 6,
  targetSpriteSheet = "tileset",
}

/// Base battle state for fight vs ai or fight vs player.
abstract class Fight : TimedPhase {
  private {
    alias ProjectileList = DropList!(Rocket, x => x.destroyed);
    alias ExplosionList = DropList!(Explosion, x => x.duration < 0);
    alias ParticleList = DropList!(Particle, x => x.destroyed);

    private ProjectileList _projectiles;
    private ExplosionList  _explosions;
    private ParticleList   _particles;
    private Turret[]       _turrets;
    private Bitmap         _explosionBmp, _targetBmp;
    private SoundBank      _launcherSound;
  }

  this(Battle battle) {
    super(battle, phaseTime);
    _projectiles = new ProjectileList;
    _explosions = new ExplosionList;
    _particles = new ParticleList;

    _targetBmp = battle.game.bitmaps.get(targetSpriteSheet);
    _launcherSound = battle.game.audio.getSoundBank("cannon");

    // create the explosion bitmap
    _explosionBmp = Bitmap(al_create_bitmap(explosionSize, explosionSize));
    al_set_target_bitmap(_explosionBmp);
    al_clear_to_color(Color(0,0,0,0));
    al_draw_filled_ellipse(
        explosionSize / 2, explosionSize / 2, // center x,y
        explosionSize / 2, explosionSize / 2, // radius x,y
        explosionTint);                       // color

    // re-target the display after creating the bitmap
    al_set_target_backbuffer(battle.game.display.display);
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);

      // create an entry in the cannon list for each cannon in player territory
      _turrets = battle.map.allTiles
        .map!(x => x.turret)
        .filter!(x => x !is null)
        .array;

      foreach(turret ; _turrets) turret.refillAmmo();
    }

    void exit(Battle battle) { super.exit(battle); }

    void run(Battle battle) {
      super.run(battle);

      auto game = battle.game;
      auto map = battle.map;

      processProjectiles(battle);
      processExplosions(game);
      processParticles(battle);

      foreach(turret ; _turrets) turret.aimAt(battle.cursor.center);

      drawTarget(battle.game.renderer, battle.cursor.center);
    }

    override void onConfirm(Battle battle) {
      auto res = _turrets.find!(x => x.ammo > 0);

      if (!res.empty) {
        auto launcher = res.front;
        launcher.ammo -= 1;

        spawnProjectile(launcher.center, battle.cursor.center);
        _launcherSound.play();
      }
    }
  }

  ~this() {
    al_destroy_bitmap(_explosionBmp);
  }

  void onProjectileExplode(Battle battle, Vector2f position, float radius) {
    auto coord = battle.map.coordAtPoint(position);
    if (battle.map.tileAt(coord).hasWall) {
      destroyWall(battle, coord);
    }
  }

  void spawnProjectile(Vector2f origin, Vector2f target) {
    _projectiles.insert(Rocket(origin, target));
  }

  private:
  void processProjectiles(Battle battle) {
    auto batch = SpriteBatch(battle.tileAtlas, projectileDepth);

    foreach(ref proj ; _projectiles) {
      proj.update(battle.game.deltaTime, &spawnParticle);

      if (proj.destroyed) {
        // turn this projectile into an explosion
        createExplosion(proj.position);
        onProjectileExplode(battle, proj.position, explosionSize);
      }
      else {
        proj.draw(batch);
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

  void processParticles(Battle battle) {
    auto batch = SpriteBatch(battle.tileAtlas, particleDepth);

    foreach(ref particle ; _particles) {
      particle.update(battle.game.deltaTime);
      batch ~= particle.sprite;
    }

    battle.game.renderer.draw(batch);
  }

  void destroyWall(Battle battle, RowCol wallCoord) {
    auto map = battle.map;
    map.tileAt(wallCoord).construct = null;

    foreach(neighbor ; wallCoord.adjacent(Diagonals.yes)) {
      map.regenerateWallSprite(neighbor);
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
    sprite.region = SpriteRegion.crossHairs;

    auto batch = SpriteBatch(_targetBmp, targetDepth);
    batch ~= sprite;
    renderer.draw(batch);
  }

  protected:
  bool allProjectilesExpired() { return _explosions.empty && _projectiles.empty; }

  void createExplosion(Vector2f pos) {
    _explosions.insert(Explosion(pos));
  }

  void spawnParticle(Vector2f pos) {
    _particles.insert(Particle(pos));
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
