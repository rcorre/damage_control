module battle.states.refill_ammo;

import std.algorithm : map, sum, filter;
import cid;
import dtiled;
import battle.battle;
import constants;
import transition;

/// Calculate ammo awarded this round and distribute it to turrets.
class RefillAmmo : BattleState {
  override void enter(Battle battle) {
    super.enter(battle);

    // only turrets enclosed in the player's territory can be refilled
    auto turrets = battle.map.turrets.filter!(x => x.enclosed);

    // sum the ammo bonuses from all enclosed constructs
    int ammoLeft = battle.map.constructs
      .filter!(x => x.enclosed)
      .map!(x => x.ammoBonus)
      .sum;

    foreach(turret ; turrets) {
      ammoLeft = turret.refillAmmo(ammoLeft);
    }

    battle.states.pop();
  }

  override void run(Battle battle) {
    super.run(battle);
  }
}
