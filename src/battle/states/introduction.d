module battle.states.introduction;

import std.math;
import std.format : format;
import std.container : Array;
import engine;
import dtiled;
import battle.battle;
import battle.entities.tilemap;
import constants;
import transition;

private enum {
  fontName  = "Mecha",
  fontSize  = 24,

  titleEnterPos = Vector2i(-210, 300),
  titleExitPos  = Vector2i( 900, 300),

  underlineEnterPos = Vector2i(1010, 320),
  underlineExitPos  = Vector2i(-100, 320),

  underlineSize = Vector2i(150, 6),

  transitionDuration = 2,

  // this represents position relative to the transition progress (0 to 1)
  // this function is chosen to have the title speed towards the center, slow
  // down briefly, and then speed back out the other side
  positionFn = (float x) => (((2 * x) - 1).pow(5) + 1) / 2 + x / 8,

  // this function represents the color value at a given point in time
  // it causes the color to dim, then fade back in
  colorFn = (float x) => (2 * x - 1).pow(2),
}

/// Play a short animation before entering the next phase
class BattleIntroduction : BattleState {
  private {
    static Bitmap _underline;

    Transition!(Color   , colorFn   ) _backgroundTint;
    Transition!(Vector2i, positionFn) _textTransition;
    Transition!(Vector2i, positionFn) _underlineTransition;

    string      _title;
    Font        _font;
    SoundEffect _sound;
  }

  this(string title, Game game) {
    _title = title;
    _sound = game.audio.getSound("battle_intro");
    _font  = game.graphics.fonts.get(fontName, fontSize);

    // create underline bitmap
    _underline = al_create_bitmap(underlineSize.x, underlineSize.y);

    al_set_target_bitmap(_underline);
    al_clear_to_color(Color.white);
    al_set_target_backbuffer(game.graphics.display);
  }

  static ~this() {
    al_destroy_bitmap(_underline);
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);

      _backgroundTint.initialize(Tint.dimBackground, transitionDuration);
      _backgroundTint.go(Color.clear);

      _textTransition.initialize(titleEnterPos, transitionDuration);
      _textTransition.go(titleExitPos);

      _underlineTransition.initialize(underlineEnterPos, transitionDuration);
      _underlineTransition.go(underlineExitPos);

      _sound.play();
    }

    void run(Battle battle) {
      super.run(battle);
      auto game = battle.game;

      _backgroundTint.update(game.deltaTime);
      _textTransition.update(game.deltaTime);
      _underlineTransition.update(game.deltaTime);

      dimBackground(game.graphics);
      drawText(game.graphics);
      drawUnderline(game.graphics);

      if (_textTransition.done && _underlineTransition.done) {
        battle.states.pop();
      }
    }
  }

  private void drawText(Renderer renderer) {
    auto batch = TextBatch(_font, DrawDepth.overlayText);
    Text text;

    // title
    text.centered  = true;
    text.color     = Color.white;
    text.transform = _textTransition.value;
    text.text      = _title;
    batch ~= text;

    renderer.draw(batch);
  }

  private void drawUnderline(Renderer renderer) {
    auto batch = SpriteBatch(_underline, DrawDepth.overlayText);
    Sprite sprite;

    sprite.centered  = true;
    sprite.color     = Color.white;
    sprite.transform = _underlineTransition.value;
    sprite.region    = Rect2i(Vector2i.zero, underlineSize);
    batch ~= sprite;

    renderer.draw(batch);
  }

  private void dimBackground(Renderer renderer) {
    RectPrimitive prim;

    prim.color  = _backgroundTint.value;
    prim.filled = true;
    prim.rect   = [ 0, 0, screenW, screenH ];

    auto batch = PrimitiveBatch(DrawDepth.overlayBackground);
    batch ~= prim;
    renderer.draw(batch);
  }
}
