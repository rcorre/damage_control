module battle.states.fight;

import std.math      : PI_2, PI;
import std.array     : array;
import std.random    : uniform;
import std.algorithm : map, filter;
import engine;
import dtiled;
import battle.battle;
import battle.states.timed_phase;
import battle.entities;
import constants;
import transition;
import common.input_hint;

private enum {
  explosionSize  = 40,

  aimingSpeed = 200, // how far the crosshairs slide (per second)

  // time between successive shots
  reloadTime = 0.2f,

  // keep the targeting cursor inside this area
  levelBounds = Rect2f(-50, -50, screenW + 100, screenH + 100),
}

/// Base battle state for fight vs ai or fight vs player.
abstract class Fight : TimedPhase {
  private {
    alias ProjectileList = DropList!(Rocket, x => x.destroyed);
    alias ExplosionList = DropList!(Explosion, x => x.done);
    alias ParticleList = DropList!(Particle, x => x.destroyed);

    ProjectileList _projectiles;
    ExplosionList  _explosions;
    ParticleList   _particles;
    Turret[]       _turrets;
    Bitmap         _spriteSheet;
    SoundBank      _launcherSound;
    SoundBank      _explosionSound;
    SoundEffect    _noAmmoSound;
    Vector2f       _targetPos;
    Vector2f       _targetVelocity;
    float          _reloadCountdown;
    InputHint      _hint;
  }

  this(Battle battle) {
    super(battle, PhaseTime.fight);
    _projectiles = new ProjectileList;
    _explosions  = new ExplosionList;
    _particles   = new ParticleList;

    _spriteSheet    = battle.game.graphics.bitmaps.get(SpriteSheet.tileset);
    _launcherSound  = battle.game.audio.getSoundBank("cannon");
    _explosionSound = battle.game.audio.getSoundBank("explosion");
    _noAmmoSound    = battle.game.audio.getSound("place_bad");

    // apply some variance to the sounds
    _explosionSound.gainFactor  = [0.6, 1];
    _explosionSound.panFactor   = [-0.5, 0.5];
    _explosionSound.speedFactor = [0.8, 1.2];

    _reloadCountdown = 0;
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

    void run(Battle battle) {
      super.run(battle);

      auto game = battle.game;
      auto map = battle.map;

      processProjectiles(battle);
      processExplosions(battle);
      processParticles(battle);

      _reloadCountdown = max(0, _reloadCountdown - game.deltaTime);

      foreach(turret ; _turrets) turret.aimAt(_targetPos);

      _targetPos += _targetVelocity * battle.game.deltaTime *
        (battle.turboMode ? turboSpeedFactor : 1);

      _targetPos.keepInside(levelBounds);

      battle.camera.focus(_targetPos);

      drawTarget(battle.game.graphics, _targetPos, battle.animationOffset, battle.cameraTransform);

      _hint.update(game.deltaTime);
      with (InputHint.Action)
        _hint.draw(game, battle.shakeTransform, up, down, left, right, shoot,
                   turbo);
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
    auto batch = SpriteBatch(battle.tileAtlas, DrawDepth.projectile, battle.cameraTransform);

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

  void processExplosions(Battle battle) {
    auto batch = SpriteBatch(_spriteSheet, DrawDepth.explosion, battle.cameraTransform);

    foreach(ref expl ; _explosions) {
      expl.update(battle.game.deltaTime);
      expl.draw(batch);
    }

    battle.game.graphics.draw(batch);
  }

  void processParticles(Battle battle) {
    auto batch = PrimitiveBatch(DrawDepth.particle, battle.cameraTransform);

    foreach(ref particle ; _particles) {
      particle.update(battle.game.deltaTime);
      batch ~= particle.primitive;
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

  void drawTarget(Renderer renderer, Vector2f pos, Vector2i animationOffset, Transform!float trans) {
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

    auto batch = SpriteBatch(_spriteSheet, DrawDepth.crosshair, trans);
    batch ~= sprite;
    renderer.draw(batch);
  }

  protected:
  bool allProjectilesExpired() { return _explosions.empty && _projectiles.empty; }

  void createExplosion(Vector2f pos) {
    _explosions.insert(Explosion(pos));
    _explosionSound.play();
  }

  void spawnParticle(Vector2f pos, float angle) {
    _particles.insert(Particle(pos, angle));
  }
}

private:
struct Explosion {
  enum {
    animTime   = 0.02,
    numFrames  = 8,
    animOffset = 128, // how much to offset x for each animation step
  }

  Vector2f position;
  float angle;
  float tillNextFrame = animTime;
  int animFrame       = 0;

  this(Vector2f position) {
    // center the rectangle on the given point
    this.position = position;

    // the explosion image is not symmetric; rotate for some variety
    this.angle = uniform(0, 2 * PI);
  }

  void draw(ref SpriteBatch batch) {
    if (done) return;

    Sprite sprite;

    sprite.centered        = true;
    sprite.transform.pos   = position;
    sprite.transform.angle = angle;

    sprite.region = SpriteRegion.explosion;
    sprite.region.x += animOffset * animFrame;

    sprite.color = lerp(Color.white, Color.clear, cast(float)animFrame / numFrames);

    batch ~= sprite;
  }

  @property auto done() { return animFrame == numFrames; }

  void update(float time) {
    if ((tillNextFrame -= time) < 0) {
      tillNextFrame = animTime;
      ++animFrame;
    }
  }
}
