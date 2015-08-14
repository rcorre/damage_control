module battle.start_round;

import dau;
import music;
import battle.battle;
import battle.place_wall;
import battle.place_cannons;
import battle.fight_ai;
import battle.introduction;

private enum {
  cannonsTitle = "Install Cannons",
  fightTitle   = "Engage!",
  rebuildTitle = "Rebuild",
}

/// This state sits at the bottom of the Battle state stack.
/// Every time it is entered, it pushes all the states involved in a single round and
/// increments the round counter.
class StartRound : State!Battle {
  private int _currentRound; // the round to start the next time this stated is entered

  override void enter(Battle battle) {
    // TODO: check if just finished last round
    battle.states.push(
        new BattleIntroduction(cannonsTitle, MusicLevel.moderate, battle.game),
        new PlaceCannons(battle), 

        new BattleIntroduction(fightTitle, MusicLevel.intense, battle.game),
        new FightAI(battle, _currentRound++), 

        new BattleIntroduction(rebuildTitle, MusicLevel.basic, battle.game),
        new PlaceWall(battle));
  }

  override void exit(Battle battle) { }
  override void run(Battle battle) { }
}
