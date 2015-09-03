/// A vertical list of menu entries.
module common.menu;

import std.math      : pow;
import std.range     : only, enumerate, isInputRange, ElementType;
import std.container : Array;
import battle.battle;
import cid;
import constants;
import transition;

private enum {
  // x position of underline when not shown (entry not selected)
  underlineHideX = -100,

  // seconds it takes for menus or underlines to move between locations
  transitionDuration = 0.5f,

  // smooth motion transition for text and colors
  transitionFn = (float x) => x.pow(0.35),
}

/// A vertical list of menu entries.
class Menu {
  private {
    Array!MenuEntry  _entries;
    size_t           _selection;

    Transition!(int, transitionFn)   _positionX;
    Transition!(Color, transitionFn) _color;
  }

  this(T...)(T entries) {
    this(only(entries));
  }

  this(R)(R entries)
    if (isInputRange!R && is(ElementType!R : MenuEntry))
  {
    _entries.insert(entries);

    // start off-screen to the right and subdued in color
    _positionX.initialize(900, transitionDuration);
    _color.initialize(Tint.subdued, transitionDuration);
  }

  @property auto selectedEntry() { return _entries[_selection]; }

  // y offsets are determined to space out the entries within the screen height
  auto entryY(int idx) {
    auto n = cast(int) _entries.length;
    return (idx + 1) * 600 / (n + 1);
  }

  void activate() {
    setSelection(0);
    _color.go(Tint.subdued, Tint.neutral);
  }

  void deactivate() {
    _entries[_selection].deselect();
    _color.go(Tint.neutral, Tint.subdued);
  }

  void setSelection(size_t idx) {
    assert(idx >= 0 && idx < _entries.length);
    _entries[_selection].deselect();
    _entries[idx].select(_positionX.end);
    _selection = idx;
  }

  void moveSelection(Vector2f direction) {
    if (direction.y > 0) {
      setSelection((_selection + 1) % _entries.length);
    }
    else if (direction.y < 0) {
      setSelection((_selection + _entries.length - 1) % _entries.length);
    }
  }

  void confirmSelection() {
    assert(_selection >= 0 && _selection < _entries.length);
    _entries[_selection].action();
  }

  void moveTo(int xPos) {
    _positionX.go(_positionX.value, xPos);
  }

  void update(float time) {
    foreach(ref entry ; _entries) entry.update(time);
    _positionX.update(time);
    _color.update(time);
  }

  void draw(ref SpriteBatch spriteBatch, ref TextBatch textBatch) {
    foreach(i , entry ; _entries[].enumerate!int) {
      auto textPos = Vector2i(_positionX.value, entryY(i));
      bool isSelected = (i == _selection);
      drawEntry(entry, isSelected, textPos, textBatch, spriteBatch);
    }
  }

  protected void drawEntry(
      MenuEntry       entry,
      bool            isSelected,
      Vector2i        center,
      ref TextBatch   textBatch,
      ref SpriteBatch spriteBatch)
  {
      Text text;
      Sprite sprite;

      text.centered  = true;
      text.color     = isSelected ? entry.textColor : _color.value;
      text.transform = center;
      text.text      = entry.text;

      sprite.centered  = true;
      sprite.color     = entry.underlineColor;
      sprite.transform = Vector2i(entry.underlineX, center.y + 30);

      auto sw = spriteBatch.bitmap.width;
      auto sh = spriteBatch.bitmap.height;
      sprite.region    = Rect2i(0, 0, sw, sh);

      textBatch   ~= text;
      spriteBatch ~= sprite;
  }
}

struct MenuEntry {
  alias Action = void delegate();

  string text;
  Action action;

  private {
    Transition!(Color, transitionFn) _textColor;
    Transition!(Color, transitionFn) _underlineColor;
    Transition!(int  , transitionFn) _underlineX;
  }

  this(string text, Action action) {
    this.text    = text;
    this.action  = action;

    _textColor.initialize(Tint.neutral, transitionDuration);
    _underlineColor.initialize(Tint.subdued, transitionDuration);
    _underlineX.initialize(underlineHideX, transitionDuration);
  }

  void select(int xPos) {
    _textColor.go(Tint.neutral, Tint.highlight);
    _underlineColor.go(Tint.subdued, Tint.highlight);
    _underlineX.go(underlineHideX, xPos);
  }

  void deselect() {
    _textColor.go(Tint.neutral);
    _underlineColor.go(Tint.subdued);
    _underlineX.go(underlineHideX);
  }

  void update(float time) {
    _textColor.update(time);
    _underlineColor.update(time);
    _underlineX.update(time);
  }

  auto underlineX() {
    return _underlineX.value;
  }

  auto textColor() {
    return _textColor.value;
  }

  auto underlineColor() {
    return _underlineColor.value;
  }
}
