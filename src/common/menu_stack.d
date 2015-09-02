/// Manages a horizontal stack of menus.
module common.menu_stack;

import std.math      : pow;
import std.process   : browse;
import std.container : Array;
import battle.battle;
import cid;
import constants;
import common.menu;

private enum {
  underlineSize = Vector2i(150, 6),

  fontName  = "Mecha",
  fontSize  = 36,
}

/// Manages a horizontal stack of menus.
class MenuStack {
  private {
    Array!Menu _menus;
    Menu       _poppedMenu;
    Bitmap     _underlineBmp;
    Font       _font;
    SoundBank  _menuMoveSound;
    SoundBank  _menuSelectSound;
    SoundBank  _menuPopSound;
  }

  this(Game game, Menu firstMenu) {
    // generate bitmap used for menu underline
    _underlineBmp = Bitmap(al_create_bitmap(underlineSize.x, underlineSize.y));
    al_set_target_bitmap(_underlineBmp);
    al_clear_to_color(Color.white);
    al_set_target_backbuffer(game.display.display);

    // load font for menu text
    _font = game.fonts.get(fontName, fontSize);

    _menuMoveSound   = game.audio.getSoundBank("menu_move");
    _menuSelectSound = game.audio.getSoundBank("menu_select");
    _menuPopSound    = game.audio.getSoundBank("menu_pop");

    _menus ~= firstMenu;
    _menus.back.moveTo(targetX(0));
    _menus.back.activate();
  }

  ~this() {
    al_destroy_bitmap(_underlineBmp);
  }

  @property length() { return _menus.length; }

  void updateAndDraw(Game game) {
    auto spriteBatch = SpriteBatch(_underlineBmp, DrawDepth.menuText);
    auto textBatch   = TextBatch(_font, DrawDepth.menuText);

    foreach(menu ; _menus) {
      menu.update(game.deltaTime);
      menu.draw(spriteBatch, textBatch);
    }
    if (_poppedMenu) {
      _poppedMenu.update(game.deltaTime);
      _poppedMenu.draw(spriteBatch, textBatch);
    }

    game.renderer.draw(spriteBatch);
    game.renderer.draw(textBatch);
  }

  void select(Game game) {
    _menuSelectSound.play();
    _menus.back.confirmSelection(game);
  }

  void moveSelection(Vector2f direction, Game game) {
    _menus.back.moveSelection(direction);

    // if we are moving up/down, play the movement noise
    if (direction.y != 0) _menuMoveSound.play();
  }

  void pushMenu(Menu newMenu) {
    _menus.back.deactivate();
    _menus ~= newMenu;

    foreach(i, menu ; _menus[].enumerate!int) {
      menu.moveTo(targetX(i));
    }

    newMenu.activate();
  }

  void popMenu() {
    if (_menus.length == 1) return;

    _menuPopSound.play();

    _poppedMenu = _menus.back;
    _menus.removeBack();

    foreach(i, menu ; _menus[].enumerate!int) {
      menu.moveTo(targetX(i));
    }

    _poppedMenu.moveTo(900);
    _poppedMenu.deactivate();
    _menus.back.activate();
  }

  private:
  auto targetX(int menuIdx) {
    int n = cast(int) _menus.length;
    return 500 - 140 * n + 220 * menuIdx;
  }
}
