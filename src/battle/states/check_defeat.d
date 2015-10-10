module battle.states.check_defeat;

import std.algorithm : any;
import cid;
import common.menu;
import common.menu_stack;
import battle.battle;
import battle.states.pause_menu;

/// Check if defeated, and if so, show a failure menu.
class CheckDefeat : State!Battle {
  override void enter(Battle battle) {
    if (!battle.map.allTiles.any!(x => x.isEnclosed)) 
      battle.states.replace(new FailMenu(battle.game));
    else
      battle.states.pop();
  }

  override void exit(Battle battle) { }
  override void run(Battle battle) { }
}
