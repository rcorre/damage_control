module states.start_round;

import dau;
import states.battle;
import states.place_wall;
import states.place_cannons;
import states.fight_ai;

/// This state sits at the bottom of the Battle state stack.
/// Every time it is entered, it pushes all the states involved in a single round and
/// increments the round counter.
class StartRound : State!Battle {
  private int _currentRound; // the round to start the next time this stated is entered

  override void enter(Battle battle) {
    // TODO: check if just finished last round
    battle.states.push(new PlaceCannons, new FightAI(_currentRound++), new PlaceWall);
  }
}
