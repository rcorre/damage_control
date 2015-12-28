/**
 * Package containing all graphics-related modules
 */
module engine.graphics;

public import engine.graphics.font;
public import engine.graphics.text;
public import engine.graphics.blend;
public import engine.graphics.color;
public import engine.graphics.bitmap;
public import engine.graphics.render;
public import engine.graphics.sprite;
public import engine.graphics.display;
public import engine.graphics.primitive;

import std.path : exists, setExtension, buildNormalizedPath;
import allegro5.allegro;
import engine.geometry;
import engine.util.content;

class GraphicsManager {
  alias renderer this;

  /// Called when the display is resized. Set to `null` to ignore.
  void delegate(Vector2i newSize) onResize;

  /// Called when the user tries to close the display. Set to `null` to ignore.
  void delegate() onClose;

  /// Called when the display gains focus. Set to `null` to ignore.
  void delegate() onSwitchIn;

  /// Called when the display loses focus. Set to `null` to ignore.
  void delegate() onSwitchOut;

  private {
    Display  _display;
    Renderer _renderer;

    ContentCache!bitmapLoader _bitmaps;
    ContentCache!fontLoader   _fonts;

    ALLEGRO_EVENT_QUEUE* _events;
  }

  @property {
    auto display()  { return _display; }
    auto renderer() { return _renderer; }

    auto ref bitmaps() { return _bitmaps; }
    auto ref fonts()   { return _fonts; }
  }

  this(Display.Settings settings) {
    _display = Display(settings);
    _renderer = new Renderer;

    // listen to display events
    _events = al_create_event_queue();
    al_register_event_source(_events, al_get_display_event_source(_display));
  }

  ~this() {
    al_destroy_display(_display);
    al_destroy_event_queue(_events);
  }

  /// Process display events until the queue is empty.
  void process() {
    ALLEGRO_EVENT ev;
    while (!al_is_event_queue_empty(_events)) {
      al_get_next_event(_events, &ev);

      switch (ev.type) {
        case ALLEGRO_EVENT_DISPLAY_RESIZE:
          if (onResize) onResize(Vector2i(ev.display.width, ev.display.height));
          break;
          case ALLEGRO_EVENT_DISPLAY_CLOSE:
            if (onClose) onClose();
            break;
          case ALLEGRO_EVENT_DISPLAY_SWITCH_IN:
            if (onSwitchIn) onSwitchIn();
            break;
          case ALLEGRO_EVENT_DISPLAY_SWITCH_OUT:
            if (onSwitchOut) onSwitchOut();
            break;
          default: break;
      }
    }
  }

  static auto bitmapLoader(string key) {
    auto path = contentDir
      .buildNormalizedPath(bitmapDir, key)
      .setExtension(bitmapExt);

    assert(path.exists, "could not find %s".format(path));
    return Bitmap.load(path);
  }

  static auto fontLoader(string key, int size) {
    auto path = contentDir
      .buildNormalizedPath(fontDir, key)
      .setExtension(fontExt);

    assert(path.exists, "could not find %s".format(path));
    return loadFont(path, size);
  }
}

private:
enum {
  contentDir = "content",

  bitmapDir = "image",
  fontDir   = "font",

  bitmapExt = ".png",
  fontExt   = ".ttf",
}
