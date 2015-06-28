module states.fight;

import std.array     : array;
import std.range     : walkLength;
import std.algorithm : sort, count, filter;
import dau;
import dtiled;
import states.battle;
import tilemap;

private enum {
  phaseTime       = 10,
  cannonCooldown  = 4,

  projectileSize  = Vector2i(12, 5),
  projectileTint  = Color(1, 1, 1, 0.5),
  projectileSpeed = 400,
  projectileDepth = 3,

  explosionTime  = 0.10f,
  explosionSize  = 40,
  explosionTint  = Color(1, 1, 1, 1.0),
  explosionDepth = 3,
}

/// Base battle state for fight vs ai or fight vs player.
abstract class Fight : State!Battle {
  private {
    alias ProjectileList = DropList!(Projectile, x => x.duration < 0);
    alias ExplosionList = DropList!(Explosion, x => x.duration < 0);

    private float  _timer;
    private ProjectileList _projectiles;
    private ExplosionList _explosions;
    private Cannon[] _cannons;
    private Bitmap _projectileBmp, _explosionBmp;
  }

  override {
    void start(Battle battle) {
      _timer = phaseTime;
      _projectiles = new ProjectileList;
      _explosions = new ExplosionList;

      // don't forget to re-target the display after creating the bitmaps
      scope(exit) al_set_target_backbuffer(battle.game.display.display);

      // create the projectile bitmap
      _projectileBmp = al_create_bitmap(projectileSize.x, projectileSize.y);
      al_set_target_bitmap(_projectileBmp);
      al_clear_to_color(projectileTint);

      // create the explosion bitmap
      _explosionBmp = al_create_bitmap(explosionSize, explosionSize);
      al_set_target_bitmap(_explosionBmp);
      al_draw_filled_ellipse(
          explosionSize / 2, explosionSize / 2, // center x,y
          explosionSize / 2, explosionSize / 2, // radius x,y
          explosionTint);                       // color

      // create an entry in the cannon list for each cannon in player territory
      _cannons = battle.map.allCoords
        .filter!(x => battle.map.tileAt(x).hasCannon)
        .map!(x => Cannon(battle.map.tileOffset(x + RowCol(1,1)).as!Vector2f))
        .array;
    }

    void run(Battle battle) {
      auto game = battle.game;
      auto mousePos = game.input.mousePos;
      auto map = battle.map;

      _timer -= game.deltaTime;

      if (_timer < 0) {
        //game.states.pop();
      }

      // try to place cannon if LMB clicked
      if (game.input.mouseReleased(MouseButton.lmb)) {
        // place the cannons with the lowest cooldowns first
        _cannons.sort!((a,b) => a.cooldown < b.cooldown);

        if (_cannons.front.cooldown < 0) {
          _cannons.front.cooldown = cannonCooldown;

          auto startPos = _cannons.front.position;
          auto tragectory = ((cast(Vector2f) mousePos) - startPos);

          Projectile proj;
          proj.position = _cannons.front.position;
          proj.velocity = tragectory.normalized * projectileSpeed;
          proj.duration = tragectory.len / projectileSpeed;
          _projectiles.insert(proj);
        }
      }

      processProjectiles(game);
      processExplosions(game);

      foreach(ref cannon ; _cannons) {
        cannon.cooldown -= game.deltaTime;
      }
    }
  }

  ~this() {
    al_destroy_bitmap(_projectileBmp);
    al_destroy_bitmap(_explosionBmp);
  }

  private:
  void processProjectiles(Game game) {
    RenderInfo ri;
    ri.bmp    = _projectileBmp;
    ri.depth  = projectileDepth;
    ri.region = Rect2i(Vector2i.zero, projectileSize);

    foreach(ref proj ; _projectiles) {
      proj.duration -= game.deltaTime;

      if (proj.duration < 0) {
        // turn this projectile into an explosion
        _explosions.insert(Explosion(proj.position));
        continue;
      }

      proj.position += proj.velocity * game.deltaTime;

      ri.transform       = proj.position;
      ri.color           = Color.white;
      ri.transform.angle = proj.velocity.angle;
      while (ri.color.a > 0) {
        game.renderer.draw(ri);
        ri.color.a -= 0.15;
        ri.transform.pos -= proj.velocity * game.deltaTime;
      }
    }
  }

  void processExplosions(Game game) {
    RenderInfo ri;
    ri.bmp    = _explosionBmp;
    ri.depth  = explosionDepth;
    ri.region = Rect2i(0, 0, explosionSize, explosionSize);

    foreach(ref expl ; _explosions) {
      expl.duration -= game.deltaTime;

      // scale about the center
      auto scale = Vector2f(1,1) * (1 - expl.duration / explosionTime);
      ri.transform.pos = expl.position - (scale * explosionSize) / 2;
      ri.transform.scale = scale;

      // fade as time passes
      ri.color = Color.black.lerp(Color.white, expl.duration / explosionTime);

      game.renderer.draw(ri);
    }
  }
}

private:
struct Projectile {
  Vector2f position;
  Vector2f velocity;
  float duration;
}

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
