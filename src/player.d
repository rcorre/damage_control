/// Data for a player that persists throughout a match
module player;

import std.container : Array;
import cid;
import constants;

class Player {
  const Color color;
  private Array!PlayerStats _stats;

  @property ref auto statsThisRound() { return _stats.back; }

  this(Color color) {
    this.color = color;
  }

  void startNewRound() { _stats.insertBack(PlayerStats()); }
}

/** Stats for a player's performance on a single round.
 *
 * This will be passed along throughout states in a round (equip/fight/repair)
 * and accumulate data about the player performance.
 * The player will be presented with a summary of their score at the end of each
 * round as well as a total at the end of the match.
 */
struct PlayerStats {
  int enemiesDestroyed;
  int tilesEnclosed;
  int reactorsEnclosed;

  @property {
    auto destructionScore() { return enemiesDestroyed * ScoreFactor.enemy; }
    auto territoryScore() { return tilesEnclosed * ScoreFactor.territory; }
    auto reactorScore() { return reactorsEnclosed * ScoreFactor.reactor; }

    auto totalScore() {
      return destructionScore +
             territoryScore   +
             reactorScore;
    }
  }
}
