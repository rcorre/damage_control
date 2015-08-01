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

  underlineOffsetShown  = Vector2i(   0,  30),
  underlineOffsetHidden = Vector2i(-200,  30),
  underlineSize         = Vector2i( 150,   6),

  subduedTint    = Color(1f,1f,1f,0.25f),
  neutralTint   = Color(1f,1f,1f,0.5f),
  highlightTint = Color(1f,1f,1f,1f),

  textDuration = 0.5,
  underlineDuration = 0.5,
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

    _entries.insert(entries);

    // select the first entry
    _entries[0].select();

    // transition in the remaining entries without selecting
    foreach(ref entry ; _entries) {
      entry.exitToCenter();
    }
  }

  ~this() {
    al_destroy_bitmap(_underlineBmp);
  }

  void setSelection(int idx) {
    assert(idx >= 0 && idx < _entries.length);
    _entries[_selectedEntry].deselect();
    _selectedEntry = idx;
    _entries[idx].select();
  }

  void moveSelectionDown() {
    if (_selectedEntry < _entries.length - 1) {
      _entries[_selectedEntry].deselect();
      _entries[++_selectedEntry].select();
    }
  }

  void moveSelectionUp() {
      if (_selectedEntry > 0) {
        _entries[_selectedEntry].deselect();
        _entries[--_selectedEntry].select();
      }
  }

  void confirmSelection(Game game) {
    assert(_selectedEntry >= 0 && _selectedEntry < _entries.length);
    _entries[_selectedEntry].action(game);
  }

  void stackToCenter() {
    foreach(ref entry ; _entries) { entry.stackToCenter(); }
  }

  void centerToStack() {
    foreach(ref entry ; _entries) { entry.centerToStack(); }
  }

  void exitToCenter() {
    foreach(ref entry ; _entries) { entry.exitToCenter(); }
  }

  void centerToExit() {
    foreach(ref entry ; _entries) { entry.centerToExit(); }
  }

  void update(Game game) {
    auto textBatch   = TextBatch(_font, textDepth);
    auto spriteBatch = SpriteBatch(_underlineBmp, textDepth);

    foreach(ref entry ; _entries) {
      entry.update(game.deltaTime);

      Text text;
      Sprite sprite;

      text.centered  = true;
      text.color     = entry.textColor;
      text.transform = entry.textPos;
      text.text      = entry.text;

      sprite.centered  = true;
      sprite.color     = entry.underlineColor;
      sprite.transform = entry.underlinePos;
      sprite.region    = Rect2i(Vector2i.zero, underlineSize);

      textBatch   ~= text;
      spriteBatch ~= sprite;
    }

    game.renderer.draw(textBatch);
    game.renderer.draw(spriteBatch);
  }
}

package:
struct MenuEntry {
  alias Action = void delegate(Game);

  string text;
  Action action;

  private {
    Vector2i   _activePos;
    Vector2i   _inactivePos;
    Vector2i   _exitPos;
    Transition _textTransition;
    Transition _underlineTransition;
  }

  this(string text, Vector2i center, Action action) {
    this.text    = text;
    this.action  = action;
    _activePos   = center;
    _inactivePos = center - Vector2i(300, 0);
    _exitPos     = Vector2i(900, center.y);

    _textTransition      = Transition(textDuration, x => x.pow(0.35));
    _underlineTransition = Transition(underlineDuration, x => x.pow(0.35));

    // make sure the underline starts hidden
    _underlineTransition.start(
        underlineHidePos, underlineHidePos, subduedTint, subduedTint);
  }

  void select() {
    // keep text where it is but transition color
    auto textPos = _textTransition.pos;
    _textTransition.start(textPos, textPos, neutralTint, highlightTint);

    _underlineTransition.start(
        _inactivePos + underlineOffsetHidden,
        _activePos + underlineOffsetShown,
        neutralTint,
        highlightTint);
  }

  void deselect() {
    // keep text where it is but transition color
    auto textPos = _textTransition.pos;
    _textTransition.start(textPos, textPos, highlightTint, neutralTint);

    _underlineTransition.start(
        _activePos + underlineOffsetShown,
        _inactivePos + underlineOffsetHidden,
        highlightTint,
        neutralTint);
  }

  void stackToCenter() {
    auto endColor = (_textTransition.endColor == highlightTint) ? highlightTint : neutralTint;

    _textTransition.start(_inactivePos, _activePos, subduedTint, endColor);
  }

  void centerToStack() {
    _textTransition.start(_activePos, _inactivePos, neutralTint, subduedTint);
    _underlineTransition.start(_underlineTransition.pos, underlineHidePos,
        _underlineTransition.color, subduedTint);
  }

  void exitToCenter() {
    auto endColor = (_textTransition.endColor == highlightTint) ? highlightTint : neutralTint;

    _textTransition.start(_exitPos, _activePos, subduedTint, endColor);
  }

  void centerToExit() {
    _textTransition.start(_activePos, _exitPos, neutralTint, subduedTint);
    _underlineTransition.start(_underlineTransition.pos, underlineHidePos,
        _underlineTransition.color, subduedTint);
  }

  void update(float time) {
    _textTransition.update(time);
    _underlineTransition.update(time);
  }

  auto textPos() {
    return _textTransition.pos;
  }

  auto underlinePos() {
    return _underlineTransition.pos;
  }

  auto textColor() {
    return _textTransition.color;
  }

  auto underlineColor() {
    return _underlineTransition.color;
  }

  private auto underlineHidePos() {
    return Vector2i(-100, _activePos.y + underlineOffsetHidden.y);
  }

  private auto underlineShowPos() {
    return _activePos + underlineOffsetShown;
  }
}

struct Transition {
  Vector2i startPos;
  Vector2i endPos;
  Color    startColor;
  Color    endColor;
  float    progress;

  float                 duration;
  float function(float) lerpFactor;

  this(float duration, float function(float) lerpFactor) {
    this.duration = duration;
    this.lerpFactor = lerpFactor;
  }

  void start(Vector2i pos1, Vector2i pos2, Color color1, Color color2) {
    startPos   = pos1;
    endPos     = pos2;
    startColor = color1;
    endColor   = color2;
    progress   = 0;
  }

  void update(float timeElapsed) {
    progress = min(1f, progress + timeElapsed / duration);
  }

  auto pos() {
    return startPos.lerp(endPos, lerpFactor(progress));
  }

  auto color() {
    return startColor.lerp(endColor, lerpFactor(progress));
  }
}
