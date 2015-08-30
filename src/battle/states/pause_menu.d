module battle.states.pause_menu;

import cid;
import battle.battle;
import common.menu;
import common.menu_stack;
import constants;
import transition;

/// Base battle state for fight vs ai or fight vs player.
class PauseMenu : BattleState {
  private {
    MenuStack _menus;
  }

  override void enter(Battle battle) {
    super.enter(battle);
    _menus = new MenuStack(battle.game, mainMenu(battle));
  }

  override void run(Battle battle) {
    super.run(battle);
    _menus.updateAndDraw(battle.game);
  }

  override void onConfirm(Battle battle) {
    _menus.select(battle.game);
  }

  override void onCancel(Battle battle) {
    _menus.popMenu();
  }

  override void onCursorMove(Battle battle, Vector2f direction) {
    _menus.moveSelection(direction, battle.game);
  }

  private:
  auto mainMenu(Battle battle) {
    return new Menu(battle.game,
        MenuEntry("Return"  , g => battle.states.pop()),
        MenuEntry("Options" , g => battle.states.pop()),
        MenuEntry("Controls", g => battle.states.pop()),
        MenuEntry("Quit"    , g => g.stop()));
  }
}
