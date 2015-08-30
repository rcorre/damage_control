module battle.states.pause_menu;

import cid;
import battle.battle;
import common.menu;
import common.menu_stack;
import constants;
import transition;
import common.keyboard_menu;
import common.gamepad_menu;

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
        MenuEntry("Options" , g => _menus.pushMenu(optionsMenu(battle.game))),
        MenuEntry("Controls", g => _menus.pushMenu(controlsMenu(battle.game))),
        MenuEntry("Quit"    , g => _menus.pushMenu(quitMenu(battle))));
  }

  auto optionsMenu(Game game) {
    auto dummy(Game game) {}

    return new Menu(game,
        MenuEntry("Sound", &dummy),
        MenuEntry("Music", &dummy));
  }

  auto controlsMenu(Game game) {
    return new Menu(game,
        MenuEntry("Keyboard", g => _menus.pushMenu(keyboardMenu(g))),
        MenuEntry("Gamepad" , g => _menus.pushMenu(gamepadMenu(g))));
  }

  auto keyboardMenu(Game game) {
    return new KeyboardMenu(game, game.events.controlScheme);
  }

  auto gamepadMenu(Game game) {
    return new GamepadMenu(game, game.events.controlScheme);
  }

  auto quitMenu(Battle battle) {
    return new Menu(battle.game,
        MenuEntry("To Title", g => battle.game.states.pop()),
        MenuEntry("To Desktop" , g => battle.game.stop));
  }
}
