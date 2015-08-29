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

  highlightDepth = 8,

  // tutorial text positions
  messageEnter  = Vector2f(-screenW / 3 , screenH * 3/5),
  messageCenter = Vector2f(screenW / 2  , screenH * 3/5),
  messageExit   = Vector2f(screenW * 4/3, screenH * 3/5),

  helpMessagePos   = Vector2f(screenW / 2, screenH * 1/20),
  helpMessageColor = Color.gray,

  transitionTime = 0.5f,
  enterTransitionFn = (float x) => x.pow(0.5),
  exitTransitionFn = (float x) => x.pow(1.5),
}

/// Temporarily pause the game and overlay some (helpful?) text
class Tutorial : BattleState {
  protected StateStack!(Tutorial, Battle) _states;

  private {
    Font    _font;
    Bitmap  _cursor;
    TileMap _map;

    Transition!(Vector2f, exitTransitionFn)  _previousMessagePos;
    Transition!(Vector2f, enterTransitionFn) _currentMessagePos;

    string _currentMessage;
    string _previousMessage;
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

      _previousMessagePos.initialize(messageEnter, transitionTime);
      _currentMessagePos.initialize(messageEnter, transitionTime);
    }

    void run(Battle battle) {
      if (!_states.empty) _states.run(this, battle);

      _previousMessagePos.update(battle.game.deltaTime);
      _currentMessagePos.update(battle.game.deltaTime);

      drawText(battle.game.renderer, _previousMessagePos.value, _previousMessage);
      drawText(battle.game.renderer, _currentMessagePos.value, _currentMessage);

      drawText(battle.game.renderer, helpMessagePos,
          "Press <confirm> (J) to continue...", helpMessageColor);
    }

    // pressing confirm or cancel progresses the tutorial
    void onConfirm(Battle battle) {
      _states.pop();

      // the last step of this tutorial scene is done; back to the game!
      if (_states.empty) battle.states.pop();
    }
  }

  protected void setMessage(string message) {
    _previousMessage = _currentMessage;
    _currentMessage  = message;

    _previousMessagePos.go(messageCenter, messageExit);
    _currentMessagePos.go(messageEnter, messageCenter);
  }

  protected void drawText(
      Renderer renderer,
      Vector2f center,
      string message,
      Color color = Color.white)
  {
    Text text;

    text.centered  = true;
    text.color     = color;
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

  /// Just show a tutorial message.
  protected class ShowMessage : State!(Tutorial, Battle) {
    private string _message;

    this(string message) {
      _message = message;
    }

    override void enter(Tutorial tut, Battle battle) {
      tut.setMessage(_message);
    }

    override void exit(Tutorial tut, Battle battle) { }

    override void run(Tutorial tut, Battle battle) { }
  }

  /// Show a tutorial message and highlight a section of the map.
  protected class HighlightCoords : ShowMessage {
    private {
      Array!RowCol _coords;
      Color        _color;
    }

    this(R)(R coords, Color color, string message) {
      super(message);
      _coords   = coords;
      _color   = color;
    }

    override void run(Tutorial tut, Battle battle) {
      super.run(tut, battle);
      auto batch = PrimitiveBatch(highlightDepth);

      RectPrimitive prim;
      prim.color       = _color;
      prim.filled      = true;
      prim.rect.width  = tileSize;
      prim.rect.height = tileSize;

      foreach(coord ; _coords) {
        prim.rect.topLeft = battle.map.tileOffset(coord).as!Vector2i;
        batch ~= prim;
      }

      battle.game.renderer.draw(batch);
    }
  }
}
