module battle.states.pause_menu;

import engine;
import battle.battle;
import common.menu;
import common.menu_stack;
import constants;
import transition;
import common.savedata;
import common.options_menu;
import common.gamepad_menu;
import common.keyboard_menu;

/// Pause the battle and overaly a menu over the battle
abstract class BattleMenu : BattleState {
  private string       _title;
  private Font         _titleFont;
  private EventHandler _handler;
  protected MenuStack  _menus;

  this(string title, Game game) {
    _titleFont = game.graphics.fonts.get(FontSpec.title);
    _title = title;
  }

  protected Menu getMenu(Battle battle);

  override void enter(Battle battle) {
    super.enter(battle);
    _menus = new MenuStack(battle.game, getMenu(battle));
    _handler = battle.game.events.onAxisTapped("move",
                                               (dir) => _menus.moveSelection(dir));
  }

  override void run(Battle battle) {
    super.run(battle);
    dimBackground(battle.game.graphics);
    drawTitle(battle.game.graphics);
    _menus.updateAndDraw(battle.game);
  }

  override void exit(Battle battle) {
    super.exit(battle);
    _menus.deactivate();
    _handler.unregister();
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
    // ignore cursor move event -- instead hook in to axis tap events
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
  private SaveData _saveData;

  this(Game game, SaveData saveData) {
    super("Pause", game);
    _saveData = saveData;
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
    return new OptionsMenu(game, _saveData);
  }

  auto controlsMenu(Game game) {
    return new Menu(
        MenuEntry("Keyboard", () => _menus.pushMenu(new KeyboardMenu(game, _saveData))),
        MenuEntry("Gamepad" , () => _menus.pushMenu(new GamepadMenu(game, _saveData))));
  }

  auto quitMenu(Game game) {
    return new Menu(
        MenuEntry("To Title",    () => game.states.pop()),
        MenuEntry("To Desktop" , () => game.stop));
  }
}

class VictoryMenu : BattleMenu {
  this(Game game) {
    super("Victory!", game);
  }

  protected override Menu getMenu(Battle battle) {
    auto game = battle.game;

    return new Menu(
        MenuEntry("Return", () => game.states.replace(new Battle(battle))));
  }
}
