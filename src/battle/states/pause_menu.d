module battle.states.pause_menu;

import cid;
import battle.battle;
import common.menu;
import common.menu_stack;
import constants;
import transition;
import common.keyboard_menu;
import common.gamepad_menu;

/// Pause the battle and overaly a menu over the battle
abstract class BattleMenu : BattleState {
  private {
    string _title;
    Font   _titleFont;
  }

  protected MenuStack _menus;

  this(string title, Game game) {
    _titleFont = game.graphics.fonts.get(FontSpec.title);
    _title = title;
  }

  protected Menu getMenu(Battle battle);

  override void enter(Battle battle) {
    super.enter(battle);
    _menus = new MenuStack(battle.game, getMenu(battle));
  }

  override void run(Battle battle) {
    super.run(battle);
    dimBackground(battle.game.graphics);
    drawTitle(battle.game.graphics);
    _menus.updateAndDraw(battle.game);
  }

  override void onConfirm(Battle battle) {
    _menus.select();
  }

  override void onCancel(Battle battle) {
    if (_menus.length == 1)
      battle.states.pop();
    else
      _menus.popMenu();
  }

  override void onCursorMove(Battle battle, Vector2f direction) {
    _menus.moveSelection(direction);
  }

  override void onMenu(Battle battle) {
    battle.states.pop(); // exit the pause menu when the pause button is pressed
  }

  private void dimBackground(Renderer renderer) {
    RectPrimitive prim;

    prim.color  = Tint.dimBackground;
    prim.filled = true;
    prim.rect   = [ 0, 0, screenW, screenH ];

    auto batch = PrimitiveBatch(DrawDepth.overlayBackground);
    batch ~= prim;
    renderer.draw(batch);
  }

  private void drawTitle(Renderer renderer) {
    Text text;

    text.text      = _title;
    text.color     = Tint.neutral;
    text.centered  = true;
    text.transform = Vector2f(screenW * 0.1, screenH * 0.1);

    auto batch = TextBatch(_titleFont, DrawDepth.overlayText);
    batch ~= text;
    renderer.draw(batch);
  }
}

class PauseMenu : BattleMenu {
  this(Game game) {
    super("Pause", game);
  }

  protected override Menu getMenu(Battle battle) {
    return new Menu(
        MenuEntry("Return"  , () => battle.states.pop()),
        MenuEntry("Options" , () => _menus.pushMenu(optionsMenu(battle.game))),
        MenuEntry("Controls", () => _menus.pushMenu(controlsMenu(battle.game))),
        MenuEntry("Quit"    , () => _menus.pushMenu(quitMenu(battle.game))));
  }

  private:
  auto optionsMenu(Game game) {
    auto dummy() {}

    return new Menu(
        MenuEntry("Sound", &dummy),
        MenuEntry("Music", &dummy));
  }

  auto controlsMenu(Game game) {
    return new Menu(
        MenuEntry("Keyboard", () => _menus.pushMenu(keyboardMenu(game))),
        MenuEntry("Gamepad" , () => _menus.pushMenu(gamepadMenu(game))));
  }

  auto keyboardMenu(Game game) {
    return new KeyboardMenu(game, game.events.controlScheme);
  }

  auto gamepadMenu(Game game) {
    return new GamepadMenu(game, game.events.controlScheme);
  }

  auto quitMenu(Game game) {
    return new Menu(
        MenuEntry("To Title",    () => game.states.pop()),
        MenuEntry("To Desktop" , () => game.stop));
  }
}

class FailMenu : BattleMenu {
  this(Game game) {
    super("Defeat", game);
  }

  protected override Menu getMenu(Battle battle) {
    auto game = battle.game;

    return new Menu(
        MenuEntry("Retry", () => game.states.replace(new Battle(battle))),
        MenuEntry("Quit" , () => game.states.pop()));
  }
}
