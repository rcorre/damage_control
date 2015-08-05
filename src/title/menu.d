/// Title menu
module title.menu;

import std.math      : pow;
import std.range     : enumerate;
import std.container : Array;
import battle.battle;
import dau;

private enum {
  fontName  = "Mecha",
  fontSize  = 36,
  textDepth = 1,

  menuCenter  = Vector2i(400, 200),
  entryMargin = Vector2i(  0, 100),

  underlineOffsetShown  = Vector2i(   0,  30),
  underlineOffsetHidden = Vector2i(-200,  30),
  underlineSize         = Vector2i( 150,   6),

  subduedTint   = Color(1f,1f,1f,0.25f),
  neutralTint   = Color(1f,1f,1f,0.5f),
  highlightTint = Color(1f,1f,1f,1f),

  transitionDuration = 0.5,
}

/// Show the title screen.
class TitleMenu {
  private {
    Array!MenuEntry     _entries;
    Font                _font;
    size_t              _selection;
    Bitmap              _underlineBmp;
    Transition!Vector2i _position;
  }

  this(Game game, MenuEntry[] entries ...) {
    _underlineBmp = Bitmap(al_create_bitmap(underlineSize.x, underlineSize.y));

    al_set_target_bitmap(_underlineBmp);
    al_clear_to_color(Color.white);
    al_set_target_backbuffer(game.display.display);

    _font = game.fonts.get(fontName, fontSize);

    _entries.insert(entries);

    _position.hold(Vector2i(900, 100));
  }

  ~this() {
    al_destroy_bitmap(_underlineBmp);
  }

  void setSelection(size_t idx) {
    assert(idx >= 0 && idx < _entries.length);
    _entries[_selection].deselect();
    _entries[idx].select(_position.end.x);
    _selection = idx;
  }

  void moveSelectionDown() {
    setSelection((_selection + 1) % _entries.length);
  }

  void moveSelectionUp() {
    setSelection((_selection - 1) % _entries.length);
  }

  void confirmSelection(Game game) {
    assert(_selection >= 0 && _selection < _entries.length);
    _entries[_selection].action(game);
  }

  void moveTo(Vector2i pos) {
    _position.go(_position.value, pos);
  }

  void deselect() {
    _entries[_selection].deselect();
  }

  void update(float time) {
    foreach(ref entry ; _entries) entry.update(time);
    _position.update(time);
  }

  void draw(Renderer renderer) {
    auto textBatch   = TextBatch(_font, textDepth);
    auto spriteBatch = SpriteBatch(_underlineBmp, textDepth);

    foreach(i , entry ; _entries[].enumerate!int) {
      Text text;
      Sprite sprite;

      auto textPos = _position.value + Vector2i(0, 100 * i);

      text.centered  = true;
      text.color     = entry.textColor;
      text.transform = textPos;
      text.text      = entry.text;

      sprite.centered  = true;
      sprite.color     = entry.underlineColor;
      sprite.transform = Vector2i(entry.underlineX, textPos.y + 30);
      sprite.region    = Rect2i(Vector2i.zero, underlineSize);

      textBatch   ~= text;
      spriteBatch ~= sprite;
    }

    renderer.draw(textBatch);
    renderer.draw(spriteBatch);
  }
}

package:
struct MenuEntry {
  alias Action = void delegate(Game);

  string text;
  Action action;

  private {
    Transition!Color _textColor;
    Transition!Color _underlineColor;
    Transition!int   _underlineX;
  }

  this(string text, Action action) {
    this.text    = text;
    this.action  = action;

    _textColor.hold(neutralTint);
    _underlineX.hold(-100);
  }

  void select(int xPos) {
    _textColor.go(neutralTint, highlightTint);
    _underlineColor.go(subduedTint, highlightTint);
    _underlineX.go(-100, xPos);
  }

  void deselect() {
    _textColor.go(neutralTint);
    _underlineColor.go(subduedTint);
    _underlineX.go(-100);
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

private struct Transition(T) if (is(typeof(T.init.lerp(T.init, 0f)) : T)) {
  T     start;
  T     end;
  float progress;

  void hold(T val) {
    start = val;
    end = val;
    progress = 0f;
  }

  void go(T to) {
    go(this.value, to);
  }

  void go(T start, T end) {
    this.start    = start;
    this.end      = end;
    this.progress = 0f;
  }

  void update(float timeElapsed) {
    progress = min(1f, progress + timeElapsed / transitionDuration);
  }

  auto value() {
    return start.lerp(end, progress.pow(0.35));
  }
}
