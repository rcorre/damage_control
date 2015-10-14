module battle.states.start_round;

import cid;
import constants;
import battle.battle;
import battle.states.place_walls;
import battle.states.place_turrets;
import battle.states.fight_ai;
import battle.states.stats_summary;
import battle.states.introduction;
import battle.states.check_defeat;
import battle.states.refill_ammo;
import battle.states.recenter_camera;
import battle.states.victory;

private enum {
  cannonsTitle = "Install Turrets",
  fightTitle   = "Engage!",
  rebuildTitle = "Rebuild",
}

/// This state sits at the bottom of the Battle state stack.
/// Every time it is entered, it pushes all the states involved in a single round and
/// increments the round counter.
class StartRound : State!Battle {
  private int _currentRound; // the round to start the next time this stated is entered

  override void enter(Battle battle) {
    int numTurrets = _currentRound == 0 ?
      initialTurretCount :
      battle.player.statsThisRound.tilesEnclosed / tilesPerTurret;

    if (_currentRound == battle.data.numRounds) {
      battle.states.push(new BattleVictory(battle));
    }
    else {
      battle.player.startNewRound();

      battle.states.push(
          new BattleIntroduction(cannonsTitle, battle.game),
          new PlaceTurrets(battle, numTurrets),
          new RefillAmmo,

          new BattleIntroduction(fightTitle, battle.game),
          new FightAI(battle, _currentRound),
          new RecenterCamera,

          new BattleIntroduction(rebuildTitle, battle.game),
          new PlaceWalls(battle),

          new CheckDefeat,

          new StatsSummary(battle, _currentRound));

      ++_currentRound;
    }
  }

  override void exit(Battle battle) { }
  override void run(Battle battle) { }
}
