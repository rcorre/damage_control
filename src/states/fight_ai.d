module states.fight_ai;

import std.array     : array;
import std.random    : uniform;
import dau;
import states.battle;
import states.fight;

private enum {
  minEnemyFireCooldown = 2,
  maxEnemyFireCooldown = 5,
  enemyDepth = 3,
  enemySize = Vector2i(32,32),
}

class FightAI : Fight {
  private {
    alias EnemyList = DropList!(Enemy, x => x.destroyed);

    EnemyList _enemies;
    Bitmap _enemyBmp;
    int _round;
  }

  this(int round) {
    _round = round;
  }

  override {
    void start(Battle battle) {
      super.start(battle);
      _enemyBmp = battle.game.content.bitmaps.get("enemy");

      _enemies = new EnemyList;

      _enemies.insert(
          battle.data
          .getEnemyWave(_round)  // get the wave data for this round
          .map!(x => Enemy(x))); // create an enemy at each location
    }

    void run(Battle battle) {
      super.run(battle);

      processEnemies(battle.game);
    }
  }

  ~this() {
    al_destroy_bitmap(_enemyBmp);
  }

  private:
  void processEnemies(Game game) {
    RenderInfo ri;
    ri.bmp    = _enemyBmp;
    ri.depth  = enemyDepth;
    ri.color  = Color.white;
    ri.region = Rect2i(Vector2i.zero, enemySize);

    foreach(ref enemy ; _enemies) {
      ri.transform = enemy.position;
      game.renderer.draw(ri);
    }
  }
}

private:
struct Enemy {
  Vector2f position;
  float fireCooldown;
  bool destroyed;

  this(Vector2f position) {
    this.position = position;
    this.fireCooldown = uniform(minEnemyFireCooldown, maxEnemyFireCooldown);
  }
}
