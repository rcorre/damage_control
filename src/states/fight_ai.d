module states.fight_ai;

import std.array     : array;
import std.random    : uniform, randomSample;
import dau;
import dtiled;
import states.battle;
import states.fight;

private enum {
  minEnemyFireCooldown = 2,
  maxEnemyFireCooldown = 5,
  enemyDepth = 3,
  enemySize = Vector2i(32,32),

  enemyAccuracy = 0.5
}

class FightAI : Fight {
  private {
    alias EnemyList = DropList!(Enemy, x => x.destroyed);

    EnemyList _enemies;
    Bitmap _enemyBmp;
    int _round;
    RowCol[] _targets;  // coordinates enemies should target
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

      // consider all tiles with walls as targets
      _targets = battle.map.allCoords.filter!(x => battle.map.tileAt(x).hasWall).array;
    }

    void run(Battle battle) {
      super.run(battle);

      processEnemies(battle);
    }

    void onProjectileExplode(Battle battle, Vector2f pos, float radius) {
      super.onProjectileExplode(battle, pos, radius);
      foreach(ref enemy ; _enemies) {
        auto center = enemy.position + enemySize / 2;
        if (center.distance(pos) < radius) {
          enemy.destroyed = true;
        }
      }
    }
  }

  ~this() {
    al_destroy_bitmap(_enemyBmp);
  }

  private:
  void processEnemies(Battle battle) {
    auto game = battle.game;

    RenderInfo ri;
    ri.bmp    = _enemyBmp;
    ri.depth  = enemyDepth;
    ri.color  = Color.white;
    ri.region = Rect2i(Vector2i.zero, enemySize);

    foreach(ref enemy ; _enemies) {
      enemy.fireCooldown -= game.deltaTime;

      if (enemy.fireCooldown < 0) {
        auto target = _targets.randomSample(1).front;

        if (uniform(0f, 1f) > enemyAccuracy) {
          // simulate a 'miss' by targeting an adjacent tile
          target = target.adjacent(Diagonals.yes).randomSample(1).front;
        }

        enemy.fireCooldown = uniform(minEnemyFireCooldown, maxEnemyFireCooldown);

        spawnProjectile(enemy.position, battle.map.tileCenter(target).as!Vector2f);
      }

      // draw
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
