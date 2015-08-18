module battle.states.introduction;

import std.math;
import std.format : format;
import std.container : Array;
import dau;
import dtiled;
import battle.battle;
import tilemap;
import music;

private enum {
  fontName  = "Mecha",
  fontSize  = 24,
  textDepth = 5,

  titleEnterPos = Vector2i(-210, 300),
  titleExitPos  = Vector2i( 900, 300),

  underlineEnterPos = Vector2i(1010, 320),
  underlineExitPos  = Vector2i(-100, 320),

  underlineSize = Vector2i(150, 6),

  transitionDuration = 2,
}

/// Play a short animation before entering the next phase
class BattleIntroduction : BattleState {
  private {
    static Bitmap _underline;

    Transition  _textTransition;
    Transition  _underlineTransition;
    string      _title;
    Font        _font;
    SoundEffect _sound;

    // How many music streams to enable.
    // More intense parts of the battle enable more streams.
    MusicLevel _musicLevel;
  }

  this(string title, MusicLevel musicLevel, Game game) {
    _title      = title;
    _musicLevel = musicLevel;
    _sound      = game.audio.getSound("battle_intro");
    _font       = game.fonts.get(fontName, fontSize);

    // create underline bitmap
    _underline = al_create_bitmap(underlineSize.x, underlineSize.y);

    al_set_target_bitmap(_underline);
    al_clear_to_color(Color.white);
    al_set_target_backbuffer(game.display.display);
  }

  static ~this() {
    al_destroy_bitmap(_underline);
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);

      _textTransition.startPos    = titleEnterPos;
      _textTransition.endPos      = titleExitPos;
      _textTransition.timeElapsed = 0;
      _textTransition.totalTime   = transitionDuration;

      _underlineTransition.startPos    = underlineEnterPos;
      _underlineTransition.endPos      = underlineExitPos;
      _underlineTransition.timeElapsed = 0;
      _underlineTransition.totalTime   = transitionDuration;

      battle.music.enableTracksUpTo(_musicLevel);
      _sound.play();
    }

    void run(Battle battle) {
      super.run(battle);
      auto game = battle.game;

      _textTransition.timeElapsed += game.deltaTime;
      _underlineTransition.timeElapsed += game.deltaTime;

      drawText(game.renderer);
      drawUnderline(game.renderer);

      if (_textTransition.done && _underlineTransition.done) {
        battle.states.pop();
      }
    }
  }

  private void drawText(Renderer renderer) {
    auto batch = TextBatch(_font, textDepth);
    Text text;

    // title
    text.centered  = true;
    text.color     = Color.white;
    text.transform = _textTransition.getPos();
    text.text      = _title;
    batch ~= text;

    renderer.draw(batch);
  }

  private void drawUnderline(Renderer renderer) {
    auto batch = SpriteBatch(_underline, textDepth);
    Sprite sprite;

    sprite.centered  = true;
    sprite.color     = Color.white;
    sprite.transform = _underlineTransition.getPos();
    sprite.region    = Rect2i(Vector2i.zero, underlineSize);
    batch ~= sprite;

    renderer.draw(batch);
  }
}

// TODO: eventually merge with the Transition struct used in menus
private struct Transition {
  Vector2f startPos, endPos;
  float timeElapsed, totalTime;

  auto getPos() {
    // x increases linearly from 0 to 1
    auto x = timeElapsed / totalTime;

    // y = ((2x - 1)^5 + 1) / 2
    auto y = (((2 * x) - 1).pow(5) + 1) / 2 + x / 8;

    return startPos.lerp(endPos, y);
  }

  bool done() {
    return timeElapsed > totalTime;
  }
}
