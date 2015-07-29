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

  transitionDuration = 0.5,
}

/// Show the title screen.
class TitleMenu {
  private {
    Array!MenuEntry    _entries;
    Array!EventHandler _handlers;
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

    _entries = entries;

    _entries[0].selected = true;
  }

  ~this() {
    al_destroy_bitmap(_underlineBmp);
  }

  void moveSelectionDown() {
    if (_selectedEntry < _entries.length - 1) {
      _entries[_selectedEntry].selected   = false;
      _entries[++_selectedEntry].selected = true;
    }
  }

  void moveSelectionUp() {
      if (_selectedEntry > 0) {
        _entries[_selectedEntry].selected   = false;
        _entries[--_selectedEntry].selected = true;
      }
  }

  void confirmSelection(Game game) {
    assert(_selectedEntry >= 0 && _selectedEntry < _entries.length);
    _entries[_selectedEntry].action(game);
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
      text.transform = entry.center;
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

  Vector2i center;
  string   text;
  bool     selected;
  float    progress;
  Action   action;

  this(string text, Vector2i center, Action action) {
    this.text     = text;
    this.center   = center;
    this.action   = action;
    this.progress = 0;
  }

  void update(float time) {
    if (selected && progress < transitionDuration) {
      progress += time;
    }
    else if (!selected && progress > 0) {
      progress -= time;
    }
  }

  auto underlinePos() {
    auto start = Vector2i(-100, center.y) + underlineOffset;
    auto end   = center + underlineOffset;

    // increases from 0 to 1, starting quickly then slowing down
    auto factor = (progress / transitionDuration).pow(0.35);

    return start.lerp(end, factor);
  }

  auto tint() {
    return unselectedTint.lerp(selectedTint, progress / transitionDuration);
  }
}
