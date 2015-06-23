module states.fight;

import std.range     : walkLength;
import std.algorithm : count, filter;
import dau;
import dtiled;
import states.battle;
import tilemap;

private enum {
  phaseTime       = 10,
  projectileDepth = 3,
  projectileSpeed = 200,
}

/// Player may place cannons within wall bounds
class Fight : State!Battle {
  private float  _timer;
  private Projectile[] _projectiles;
  private Bitmap _projectileBmp;

  override {
    void start(Battle battle) {
      _timer = phaseTime;

      _projectileBmp = al_create_bitmap(8,8);

      al_set_target_bitmap(_projectileBmp);
      al_clear_to_color(Color.white);
      al_set_target_backbuffer(battle.game.display.display);
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
        Projectile proj;
        proj.position = Vector2f.zero;
        proj.velocity = (cast(Vector2f) mousePos).normalized * projectileSpeed;
        _projectiles ~= proj;
      }

      RenderInfo ri;
      ri.bmp    = _projectileBmp;
      ri.color  = Color.white;
      ri.depth  = projectileDepth;
      ri.region = Rect2i(0,0,8,8);

      foreach(ref proj ; _projectiles) {
        proj.position += proj.velocity * game.deltaTime;

        ri.transform = proj.position;
        game.renderer.draw(ri);
      }
    }
  }

  ~this() {
    al_destroy_bitmap(_projectileBmp.bitmap);
  }
}

struct Projectile {
  Vector2f position;
  Vector2f velocity;
}
