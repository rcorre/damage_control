module states.timed_phase;

import std.format : format;
import dau;
import dtiled;
import states.battle;

private enum {
  fontName  = "Mecha",
  fontSize  = 24,
  textDepth = 1,
  timerPos = Vector2i(10, 10),
  timerFormat = "Time: %2.1f",
}

/// Base for any timed phase within the battle state
class TimedPhase : State!Battle {
  private {
    float _timer;
    Font  _font;
  }

  this(Battle battle, float duration) {
    _timer = duration;
  }

  override {
    void enter(Battle battle) {
      _font = battle.game.fonts.get(fontName, fontSize);
    }

    void exit(Battle battle) { }

    void run(Battle battle) {
      auto game = battle.game;

      // tick down the timer; if it hits 0 this phase is over
      _timer -= game.deltaTime;
      if (_timer < 0) battle.states.pop();

      drawTimer(game.renderer);
    }
  }

  private void drawTimer(Renderer renderer) {
    auto batch = TextBatch(_font, textDepth);

    Text text;

    text.color = (_timer > 3.0f) ? Color.gray : Color.red;
    text.transform = timerPos;
    text.text      = timerFormat.format(_timer);
    batch ~= text;

    renderer.draw(batch);
  }
}
