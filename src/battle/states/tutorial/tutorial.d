/// Temporarily pause the game and overlay some (helpful?) text
module battle.states.tutorial.tutorial;

import std.math;
import std.format : format;
import std.container : Array;
import dau;
import dtiled;
import battle.battle;
import battle.entities.tilemap;
import music;
import constants;
import transition;

private enum {
  fontName  = "Mecha",
  fontSize  = 24,
  textDepth = 6,

  targetSpriteSheet = "tileset", // target used to point out a location
  targetDepth = 5,

  // offset of tutorial text from the center of the cursor
  Vector2f textOffset = Vector2f(32, 32),

  transitionTime = 1f,
}

/// Temporarily pause the game and overlay some (helpful?) text
class Tutorial : BattleState {
  protected StateStack!(Tutorial, Game) _states;

  private {
    Font     _font;
    Bitmap   _cursor;

    Transition!Vector2f _cursorPos;
    Transition!Vector2f _cursorScale;
  }

  this(Battle battle) {
    _font   = battle.game.fonts.get(fontName, fontSize);
    _cursor = battle.game.bitmaps.get(targetSpriteSheet);
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);

      // just exit immediately if we are not in tutorial mode
      if (!battle.showTutorial) battle.states.pop();

      _cursorPos.initialize(Vector2f.zero, transitionTime);
      _cursorScale.initialize(Vector2f.zero, transitionTime);
    }

    void run(Battle battle) {
      if (!_states.empty) _states.run(this, battle.game);

      _cursorPos.update(battle.game.deltaTime);
      _cursorScale.update(battle.game.deltaTime);
    }

    // pressing confirm or cancel progresses the tutorial
    void onConfirm(Battle battle) {
      if (_states.empty) battle.states.pop();
      else _states.pop();
    }
  }

  protected void drawText(Renderer renderer, Vector2f topLeft, string message) {
    Text text;

    text.color     = Color.white;
    text.transform = topLeft;
    text.text      = message;

    auto batch = TextBatch(_font, textDepth);
    batch ~= text;
    renderer.draw(batch);
  }

  protected void drawTarget(Renderer renderer, Vector2f center, Vector2f scale) {
    Sprite sprite;

    sprite.centered        = true;
    sprite.color           = Color.white;
    sprite.transform       = center;
    sprite.transform.scale = scale;
    sprite.region          = SpriteRegion.crossHairs;

    auto batch = SpriteBatch(_cursor, targetDepth);
    batch ~= sprite;
    renderer.draw(batch);
  }

  protected class ShowTip : State!(Tutorial, Game) {
    Vector2f _pos, _scale;
    string _message;

    this(Vector2f pos, Vector2f scale, string message) {
      _pos     = pos;
      _scale   = scale;
      _message = message;
    }

    override void enter(Tutorial tut, Game game) {
      tut._cursorPos.go(_pos);
      tut._cursorScale.go(_scale);
    }

    override void exit(Tutorial tut, Game game) { }

    override void run(Tutorial tut, Game game) {
      drawTarget(game.renderer, _cursorPos.value, _cursorScale.value);

      auto textPos = _cursorPos.value + textOffset;
      drawText(game.renderer, textPos, _message);
    }
  }
}
