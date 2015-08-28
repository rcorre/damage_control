module battle.states.start_round;

import dau;
import music;
import constants;
import battle.battle;
import battle.states.place_walls;
import battle.states.place_turrets;
import battle.states.fight_ai;
import battle.states.stats_summary;
import battle.states.introduction;
import battle.states.tutorial;

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

    battle.player.startNewRound();

    // TODO: check if just finished last round
    battle.states.push(
        new TutorialTurrets(battle),
        new BattleIntroduction(cannonsTitle, MusicLevel.moderate, battle.game),
        new PlaceTurrets(battle, numTurrets),

        new BattleIntroduction(fightTitle, MusicLevel.intense, battle.game),
        new FightAI(battle, _currentRound),

        new BattleIntroduction(rebuildTitle, MusicLevel.basic, battle.game),
        new PlaceWalls(battle),

        new StatsSummary(battle, _currentRound));

    ++_currentRound;
  }

  override void exit(Battle battle) { }
  override void run(Battle battle) { }
}

class EmptyBattleState : State!Battle {
  override void enter(Battle b) { b.states.pop(); }
  override void exit(Battle b) { }
  override void run(Battle b) { }
}

