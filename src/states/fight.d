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
  projectileDepth = 3,
  projectileSpeed = 350,
  cannonCooldown = 5,
}

/// Player may place cannons within wall bounds
class Fight : State!Battle {
  private float  _timer;
  private Projectile[] _projectiles;
  private Cannon[] _cannons;
  private Bitmap _projectileBmp;

  override {
    void start(Battle battle) {
      _timer = phaseTime;

      _projectileBmp = al_create_bitmap(8,8);

      al_set_target_bitmap(_projectileBmp);
      al_clear_to_color(Color.white);
      al_set_target_backbuffer(battle.game.display.display);

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
        _cannons.sort!((a,b) => a.cooldown < b.cooldown);
        if (_cannons.front.cooldown < 0) {
          _cannons.front.cooldown = cannonCooldown;

          auto startPos = _cannons.front.position;
          auto tragectory = ((cast(Vector2f) mousePos) - startPos).normalized;

          Projectile proj;
          proj.position = _cannons.front.position;
          proj.velocity = tragectory * projectileSpeed;
          _projectiles ~= proj;
        }
      }

      RenderInfo ri;
      ri.bmp    = _projectileBmp;
      ri.depth  = projectileDepth;
      ri.region = Rect2i(0,0,8,8);

      foreach(ref proj ; _projectiles) {
        proj.position += proj.velocity * game.deltaTime;

        ri.transform = proj.position;
        ri.color  = Color.white;
        while (ri.color.a > 0) {
          game.renderer.draw(ri);
          ri.color.a -= 0.2;
          ri.transform.pos -= proj.velocity * game.deltaTime;
        }
      }

      foreach(ref cannon ; _cannons) {
        cannon.cooldown -= game.deltaTime;
      }
    }
  }

  ~this() {
    al_destroy_bitmap(_projectileBmp.bitmap);
  }
}

private:
struct Projectile {
  Vector2f position;
  Vector2f velocity;
}

struct Cannon {
  Vector2f position;
  float cooldown;

  this(Vector2f position) {
    this.position = position;
    this.cooldown = 0;
  }
}
