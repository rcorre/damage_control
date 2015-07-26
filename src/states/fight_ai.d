module states.fight_ai;

import std.array  : array;
import dau;
import dtiled;
import enemy;
import states.battle;
import states.fight;

private enum {
  enemySize = Vector2i(32,32),
}

class FightAI : Fight {
  private {
    alias EnemyList = DropList!(Enemy, x => x.destroyed);

    EnemyList _enemies;
    int _round;
    RowCol[] _targets;  // coordinates enemies should target
  }

  this(Battle battle, int round) {
    super(battle);
    _round = round;
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);
      // consider all tiles with walls as targets
      _targets = battle.map.allCoords.filter!(x => battle.map.tileAt(x).hasWall).array;

      _enemies = new EnemyList;

      _enemies.insert(
          battle.data
          .getEnemyWave(_round)      // get the wave data for this round
          .map!(x => new Enemy(x))); // create an enemy at each location
    }

    void run(Battle battle) {
      super.run(battle);

      updateEnemies(battle);
      battle.drawEnemies(_enemies[].map!(x => x.transform));
    }

    void onProjectileExplode(Battle battle, Vector2f pos, float radius) {
      super.onProjectileExplode(battle, pos, radius);
      foreach(ref enemy ; _enemies) {
        if (enemy.pos.distance(pos) < radius) {
          enemy.destroyed = true;
        }
      }
    }
  }

  private:
  void updateEnemies(Battle battle) {
    auto game = battle.game;

    // when no enemies are left, and all projectiles are gone, end the battle
    if (_enemies.empty && super.allProjectilesExpired)
      battle.states.pop();

    EnemyContext context;
    context.timeElapsed     = game.deltaTime;
    context.targets         = _targets;
    context.tileMap         = battle.map;
    context.spawnProjectile = &super.spawnProjectile;

    foreach(ref enemy ; _enemies) {
      enemy.update(context);
    }
  }
}
