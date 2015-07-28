/// Title screen state.
module title.title;

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
class Title : State!Game {
  private {
    Array!MenuEntry    _entries;
    Array!EventHandler _handlers;
    Font               _font;
    uint               _selectedEntry;
    Bitmap             _underlineBmp;
  }

  override {
    void enter(Game game) {
      if (_underlineBmp is null) {
        // TODO: what a hack ...
        // problem here is that the renderer is holding on to the bitmap through
        // the SpriteBatch
        // eventually need to have the renderer manage bitmaps itself.

        // create underline bitmap
        _underlineBmp = al_create_bitmap(underlineSize.x, underlineSize.y);

        al_set_target_bitmap(_underlineBmp);
        al_clear_to_color(Color.white);
        al_set_target_backbuffer(game.display.display);
      }

      _font = game.fonts.get(fontName, fontSize);

      auto menuPos(int idx) { return menuCenter + entryMargin * idx; }

      auto play(Game game)    { game.states.push(new Battle); }
      auto options(Game game) { game.states.push(new Battle); }
      auto quit(Game game)    { game.stop(); }

      _entries.insert(MenuEntry("Play"    , menuPos(0), &play));
      _entries.insert(MenuEntry("Options" , menuPos(1), &options));
      _entries.insert(MenuEntry("Quit"    , menuPos(2), &quit));

      _entries[0].selected = true;

      void handleKeyDown(in ALLEGRO_EVENT ev) {
        switch (ev.keyboard.keycode) {
          case ALLEGRO_KEY_J:
            assert(_selectedEntry >= 0 && _selectedEntry < _entries.length);
            _entries[_selectedEntry].action(game);
            break;
          case ALLEGRO_KEY_W:
            if (_selectedEntry > 0) {
              _entries[_selectedEntry].selected   = false;
              _entries[--_selectedEntry].selected = true;
            }
            break;
          case ALLEGRO_KEY_S:
            if (_selectedEntry < _entries.length - 1) {
              _entries[_selectedEntry].selected   = false;
              _entries[++_selectedEntry].selected = true;
            }
            break;
          case ALLEGRO_KEY_ESCAPE:
            game.stop();
            break;
          default:
        }
      }

      _handlers.insert(game.events.onKeyDown(&handleKeyDown));
    }

    void exit(Game game) {
      foreach(handler ; _handlers) handler.unregister();
      _handlers.clear();

      if (_underlineBmp !is null) al_destroy_bitmap(_underlineBmp);
    }

    void run(Game game) {
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
}

private struct MenuEntry {
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
