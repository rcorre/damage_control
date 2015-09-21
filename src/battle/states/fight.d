module battle.states.fight;

import std.math      : PI_2;
import std.array     : array;
import std.algorithm : map, filter;
import cid;
import dtiled;
import battle.battle;
import battle.states.timed_phase;
import battle.entities;
import battle.entities.tilemap;
import constants;
import transition;

private enum {
  explosionTime  = 0.30f,
  explosionSize  = 40,
  explosionTint  = Color(1, 1, 1, 1.0),

  targetSpriteSheet = "tileset",

  aimingSpeed = 200, // how far the crosshairs slide (per second)

  // time between successive shots
  reloadTime = 0.2f
}

/// Base battle state for fight vs ai or fight vs player.
abstract class Fight : TimedPhase {
  private {
    alias ProjectileList = DropList!(Rocket, x => x.destroyed);
    alias ExplosionList = DropList!(Explosion, x => x.duration < 0);
    alias ParticleList = DropList!(Particle, x => x.destroyed);

    ProjectileList _projectiles;
    ExplosionList  _explosions;
    ParticleList   _particles;
    Turret[]       _turrets;
    Bitmap         _explosionBmp;
    Bitmap         _targetBmp;
    SoundBank      _launcherSound;
    SoundBank      _explosionSound;
    SoundEffect    _noAmmoSound;
    Vector2f       _targetPos;
    Vector2f       _targetVelocity;
    float          _reloadCountdown;
  }

  this(Battle battle) {
    super(battle, PhaseTime.fight);
    _projectiles = new ProjectileList;
    _explosions = new ExplosionList;
    _particles = new ParticleList;

    _targetBmp = battle.game.graphics.bitmaps.get(targetSpriteSheet);
    _launcherSound = battle.game.audio.getSoundBank("cannon");
    _explosionSound = battle.game.audio.getSoundBank("explosion");
    _noAmmoSound = battle.game.audio.getSound("place_bad");

    // apply some variance to the sounds
    _explosionSound.gainFactor  = [0.6, 1];
    _explosionSound.panFactor   = [-0.5, 0.5];
    _explosionSound.speedFactor = [0.8, 1.2];

    // create the explosion bitmap
    _explosionBmp = Bitmap(al_create_bitmap(explosionSize, explosionSize));
    al_set_target_bitmap(_explosionBmp);
    al_clear_to_color(Color(0,0,0,0));
    al_draw_filled_ellipse(
        explosionSize / 2, explosionSize / 2, // center x,y
        explosionSize / 2, explosionSize / 2, // radius x,y
        explosionTint);                       // color

    // re-target the display after creating the bitmap
    al_set_target_backbuffer(battle.game.graphics.display);

    _reloadCountdown = 0;
  }

  ~this() {
    al_destroy_bitmap(_explosionBmp);
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);

      // only turrets enclosed in the player territory are useable
      _turrets = battle.map.turrets.filter!(x => x.enclosed).array;

      // the crosshairs should start at one of the turrets
      _targetPos = _turrets.empty ? Vector2f.zero : _turrets.front.center;
      _targetVelocity = Vector2f.zero;
    }

    void exit(Battle battle) { super.exit(battle); }

    void run(Battle battle) {
      super.run(battle);

      auto game = battle.game;
      auto map = battle.map;

      processProjectiles(battle);
      processExplosions(game);
      processParticles(battle);

      _reloadCountdown = max(0, _reloadCountdown - game.deltaTime);

      foreach(turret ; _turrets) turret.aimAt(_targetPos);

      _targetPos += _targetVelocity * battle.game.deltaTime *
        (battle.turboMode ? turboSpeedFactor : 1);

      drawTarget(battle.game.graphics, _targetPos, battle.animationOffset);
    }

    void onConfirm(Battle battle) {
      auto res = _turrets.find!(x => x.ammo > 0);

      if (res.empty) {
        // no ammo left
        _noAmmoSound.play();
      }
      else if (_reloadCountdown <= 0) {
        auto launcher = res.front;
        launcher.ammo -= 1;

        spawnProjectile(launcher.center, _targetPos);
        _launcherSound.play();
        _reloadCountdown = reloadTime;
      }
    }

    // action to take when cursor is moved in the given direction
    void onCursorMove(Battle battle, Vector2f direction) {
      _targetVelocity = direction * aimingSpeed;
    }
  }

  void onProjectileExplode(Battle battle, Vector2f position, float radius) {
    auto coord = battle.map.coordAtPoint(position);
    if (battle.map.contains(coord) && battle.map.tileAt(coord).hasWall) {
      destroyWall(battle, coord);
    }
  }

  void spawnProjectile(Vector2f origin, Vector2f target) {
    _projectiles.insert(Rocket(origin, target));
  }

  private:
  void processProjectiles(Battle battle) {
    auto batch = SpriteBatch(battle.tileAtlas, DrawDepth.projectile);

    foreach(ref proj ; _projectiles) {
      proj.update(battle.game.deltaTime, &spawnParticle);

      if (proj.destroyed) {
        // turn this projectile into an explosion
        createExplosion(proj.position);
        battle.shakeScreen(ScreenShakeIntensity.explosion);
        onProjectileExplode(battle, proj.position, explosionSize);
      }
      else {
        proj.draw(batch);
      }
    }


    battle.game.graphics.draw(batch);
  }

  void processExplosions(Game game) {
    auto batch = SpriteBatch(_explosionBmp, DrawDepth.explosion);

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

    game.graphics.draw(batch);
  }

  void processParticles(Battle battle) {
    auto batch = SpriteBatch(battle.tileAtlas, DrawDepth.particle);

    foreach(ref particle ; _particles) {
      particle.update(battle.game.deltaTime);
      batch ~= particle.sprite;
    }

    battle.game.graphics.draw(batch);
  }

  void destroyWall(Battle battle, RowCol wallCoord) {
    auto map = battle.map;
    map.clear(wallCoord);

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

  void drawTarget(Renderer renderer, Vector2f pos, Vector2i animationOffset) {
    Sprite sprite;

    sprite.transform.pos = pos;
    sprite.centered      = true;
    sprite.region        = SpriteRegion.crossHairs;
    // the crosshairs scale up and rotate after firing

    float reloadFactor = _reloadCountdown / reloadTime;
    sprite.transform.angle = lerp(0, -PI_2, reloadFactor);
    sprite.transform.scale = Vector2i(1,1) * lerp(1f, 2f, reloadFactor);

    if (_turrets.canFind!(x => x.ammo > 0)) {
      // if player can fire, animate the crossHairs
      sprite.region.topLeft = sprite.region.topLeft + animationOffset;
    }
    else {
      // otherwise, dim the crosshairs by reducing alpha
      sprite.color.a = 0.5;
    }

    auto batch = SpriteBatch(_targetBmp, DrawDepth.crosshair);
    batch ~= sprite;
    renderer.draw(batch);
  }

  protected:
  bool allProjectilesExpired() { return _explosions.empty && _projectiles.empty; }

  void createExplosion(Vector2f pos) {
    _explosions.insert(Explosion(pos));
    _explosionSound.play();
  }

  void spawnParticle(Vector2f pos) {
    _particles.insert(Particle(pos));
  }
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
