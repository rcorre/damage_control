/// Temporarily pause the game and overlay some (helpful?) text
module battle.states.tutorial.tutorial;

import std.math;
import std.range;
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

  // where to center the tutorial text
  Vector2f textCenter = Vector2f(screenW / 2, screenH * 4/5),

  transitionTime = 1f,
}

/// Temporarily pause the game and overlay some (helpful?) text
class Tutorial : BattleState {
  protected StateStack!(Tutorial) _states;

  private {
    Font    _font;
    Bitmap  _cursor;
    TileMap _map;

    Transition!Vector2f _cursorPos;
    Transition!Vector2f _cursorScale;

    string _message;
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
      if (!_states.empty) _states.run(this);

      _cursorPos.update(battle.game.deltaTime);
      _cursorScale.update(battle.game.deltaTime);

      drawText(battle.game.renderer, textCenter, _message);
    }

    // pressing confirm or cancel progresses the tutorial
    void onConfirm(Battle battle) {
      _states.pop();

      // the last step of this tutorial scene is done; back to the game!
      if (_states.empty) battle.states.pop();
    }
  }

  protected void drawText(Renderer renderer, Vector2f center, string message) {
    Text text;

    text.centered  = true;
    text.color     = Color.white;
    text.transform = center;
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

  protected auto highlightCoords(R)(R tiles, Color tint, string message)
  {
    class HighlightCoords : State!Tutorial {
      override void enter(Tutorial tut) {
        tut._message = message;
        foreach(tile ; tiles.save) tile.tint = tint;
      }

      override void exit(Tutorial tut) {
        foreach(tile ; tiles.save) tile.tint = Color.white;
      }

      override void run(Tutorial tut) { }
    }

    return new HighlightCoords;
  }
}
