/// Title menu
module title.menu;

import std.math      : pow;
import std.container : Array;
import battle.battle;
import dau;

private enum {
  fontName  = "Mecha",
  fontSize  = 36,
  textDepth = 1,

  menuCenter      = Vector2i(400, 200),
  entryMargin     = Vector2i(  0, 100),
  underlineOffset = Vector2i(  0,  30),
  underlineSize   = Vector2i(150,   6),

  selectedTint   = Color(1f,1f,1f,1f),
  unselectedTint = Color(1f,1f,1f,0.3f),

  selectionDuration = 0.5,
  activationDuration = 0.5,
}

/// Show the title screen.
class TitleMenu {
  private {
    Array!MenuEntry    _entries;
    Font               _font;
    uint               _selectedEntry;
    Bitmap             _underlineBmp;
  }

  this(Game game, MenuEntry[] entries ...) {
    _underlineBmp = Bitmap(al_create_bitmap(underlineSize.x, underlineSize.y));

    al_set_target_bitmap(_underlineBmp);
    al_clear_to_color(Color.white);
    al_set_target_backbuffer(game.display.display);

    _font = game.fonts.get(fontName, fontSize);

    //auto entryPos(int idx) { return menuCenter + entryMargin * idx; }

    _entries.insert(entries);

    _entries[0].mode = MenuEntry.Mode.selected;
  }

  ~this() {
    al_destroy_bitmap(_underlineBmp);
  }

  void moveSelectionDown() {
    if (_selectedEntry < _entries.length - 1) {
      _entries[_selectedEntry].mode   = MenuEntry.Mode.active;
      _entries[++_selectedEntry].mode = MenuEntry.Mode.selected;
    }
  }

  void moveSelectionUp() {
      if (_selectedEntry > 0) {
        _entries[_selectedEntry].mode   = MenuEntry.Mode.active;
        _entries[--_selectedEntry].mode = MenuEntry.Mode.selected;
      }
  }

  void confirmSelection(Game game) {
    assert(_selectedEntry >= 0 && _selectedEntry < _entries.length);
    _entries[_selectedEntry].action(game);
  }

  void backOut() {
    foreach(ref entry ; _entries) entry.mode = MenuEntry.Mode.inactive;
  }

  void update(Game game) {
    auto textBatch   = TextBatch(_font, textDepth);
    auto spriteBatch = SpriteBatch(_underlineBmp, textDepth);

    foreach(ref entry ; _entries) {
      entry.update(game.deltaTime);

      Text text;
      Sprite sprite;

      text.centered  = true;
      text.color     = entry.tint;
      text.transform = entry.textPos;
      text.text      = entry.text;

      sprite.centered  = true;
      sprite.color     = entry.tint;
      sprite.transform = entry.underlinePos;
      sprite.region    = Rect2i(Vector2i.zero, underlineSize);

      textBatch   ~= text;
      spriteBatch ~= sprite;
    }

    game.renderer.draw(textBatch);
    game.renderer.draw(spriteBatch);
  }
}

package struct MenuEntry {
  alias Action = void delegate(Game);

  enum Mode { hidden, inactive, active, selected }

  Vector2i activePos;
  Vector2i inactivePos;
  Vector2i hiddenPos;
  string   text;
  Mode     mode;
  float    selectionProgress;
  float    activationProgress;
  float    hidingProgress;
  Action   action;

  this(string text, Vector2i center, Action action) {
    this.mode               = Mode.active;
    this.text               = text;
    this.activePos          = center;
    this.inactivePos        = center - Vector2i(300, 0);
    this.hiddenPos          = center + Vector2i(500, 0);
    this.action             = action;
    this.activationProgress = 0;
    this.selectionProgress  = 0;
  }

  void update(float time) {
    final switch (mode) with (Mode) {
      case hidden:
        if (hidingProgress < activationDuration) hidingProgress += time;
        if (selectionProgress > 0) selectionProgress -= time;
        if (activationProgress > 0) activationProgress -= time;
        break;
      case inactive:
        if (selectionProgress > 0) selectionProgress -= time;
        if (activationProgress > 0) activationProgress -= time;
        break;
      case active:
        if (activationProgress < activationDuration) activationProgress += time;
        if (selectionProgress > 0) selectionProgress -= time;
        break;
      case selected:
        if (activationProgress < activationDuration) activationProgress += time;
        if (selectionProgress < selectionDuration) selectionProgress += time;
        break;
    }
  }

  auto textPos() {
    final switch (mode) with (Mode) {
      case hidden:
        auto factor = (hidingProgress / activationDuration).pow(0.5);
        return activePos.lerp(hiddenPos, factor);
      case inactive:
        auto factor = (1 - activationProgress / activationDuration).pow(0.5);
        return activePos.lerp(inactivePos, factor);
      case active:
      case selected:
        auto factor = (activationProgress / activationDuration).pow(0.5);
        return inactivePos.lerp(activePos, factor);
    }
  }

  auto underlinePos() {
    auto start = Vector2i(-100, textPos.y) + underlineOffset;
    auto end   = textPos + underlineOffset;

    // increases from 0 to 1, starting quickly then slowing down
    auto factor = (selectionProgress / selectionDuration).pow(0.35);

    return start.lerp(end, factor);
  }

  auto tint() {
    return (mode == Mode.active || mode == Mode.selected) ?
      unselectedTint.lerp(selectedTint, selectionProgress / selectionDuration) :
      unselectedTint;
  }
}
