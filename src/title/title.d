/// Title screen state.
module title.title;

import std.container : Array;
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
  unselectedTint = Color(1f,1f,1f,0.5f),

  transitionDuration = 1,
}

/// Show the title screen.
class Title : State!Game {
  private {
    Array!MenuEntry    _entries;
    Array!EventHandler _handlers;
    Font               _font;
    uint               _selectedEntry;
  }

  override {
    void enter(Game game) {
      _font = game.fonts.get(fontName, fontSize);
      _entries.insert(MenuEntry("Play"    , menuCenter + entryMargin * 0));
      _entries.insert(MenuEntry("Options" , menuCenter + entryMargin * 1));
      _entries.insert(MenuEntry("Quit"    , menuCenter + entryMargin * 2));

      _entries[0].selected = true;

      void handleKeyDown(in ALLEGRO_EVENT ev) {
        switch (ev.keyboard.keycode) {
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
    }

    void run(Game game) {
      foreach(ref entry ; _entries) entry.draw(game.renderer, _font);
      //states.run(this);
    }
  }
}

private struct MenuEntry {
  Vector2i center;
  string   textString;
  bool     selected;
  float    time;

  this(string text, Vector2i center) {
    this.textString = text;
    this.center = center;
    this.time = 0;
  }

  void update(float time) {
  }

  void draw(Renderer renderer, Font font) {
    auto batch = TextBatch(font, textDepth);
    Text text;

    text.centered  = true;
    text.color     = selected ? selectedTint : unselectedTint;
    text.transform = center;
    text.text      = textString;
    batch ~= text;

    renderer.draw(batch);
  }
}
