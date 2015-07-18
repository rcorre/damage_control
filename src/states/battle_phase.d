module states.battle_phase;

import std.format : format;
import dau;
import dtiled;
import states.battle;
import states.battle_transition;
import tilemap;

private enum {
  fontName  = "Mecha",
  fontSize  = 24,
  textDepth = 1,

  timerPos = Vector2i(10, 10),
  titlePos = Vector2i(300, 10),

  timerFormat = "Time: %2.1f",
}

/// Base for any timed phase within the battle state
class BattlePhase : State!Battle {
  private {
    float _timer;
    string _title;
    Font  _font;
  }

  this(string title, float duration) {
    _title = title;
    _timer = duration;
  }

  override {
    void start(Battle battle) {
      battle.states.push(new BattleTransition(_title));
    }

    void enter(Battle battle) {
      _font = battle.game.fonts.get(fontName, fontSize);
    }

    void run(Battle battle) {
      auto game = battle.game;

      // tick down the timer; if it hits 0 this phase is over
      _timer -= game.deltaTime;
      if (_timer < 0) battle.states.pop();

      drawText(game.renderer);
    }
  }

  private void drawText(Renderer renderer) {
    auto batch = TextBatch(_font, textDepth);

    Text text;

    // title
    text.color     = Color.gray;
    text.transform = titlePos;
    text.text      = _title;
    batch ~= text;

    // timer
    text.color = (_timer > 3.0f) ? Color.gray : Color.red;
    text.transform = timerPos;
    text.text      = timerFormat.format(_timer);
    batch ~= text;

    // cannon counter
    //text.color = (_cannons > 0) ? Color.gray : Color.red;
    //text.transform = cannonCountPos;
    //text.text      = cannonCountFormat.format(_cannons);
    //batch ~= text;

    renderer.draw(batch);
  }
}
