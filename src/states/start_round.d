module states.start_round;

import dau;
import states.battle;
import states.place_wall;
import states.place_cannons;
import states.fight_ai;
import states.battle_transition;

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
        new BattleTransition(cannonsTitle),
        new PlaceCannons(battle), 

        new BattleTransition(fightTitle),
        new FightAI(battle, _currentRound++), 

        new BattleTransition(rebuildTitle),
        new PlaceWall(battle));
  }

  override void exit(Battle battle) { }
  override void run(Battle battle) { }
}
