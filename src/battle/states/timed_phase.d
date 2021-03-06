module battle.states.timed_phase;

import std.format : format;
import engine;
import dtiled;
import constants;
import battle.battle;

private enum {
  fontName  = "Mecha",
  fontSize  = 24,
  timerPos = Vector2i(10, 10),
  timerFormat = "Time: %2.1f",
}

/// Base for any timed phase within the battle state
class TimedPhase : BattleState {
  private {
    float _timer;
    Font  _font;
  }

  this(Battle battle, float duration) {
    _timer = duration;
  }

  @property float phaseTimeLeft() { return _timer; }

  override {
    void enter(Battle battle) {
      super.enter(battle);
      _font = battle.game.graphics.fonts.get(fontName, fontSize);
    }

    void run(Battle battle) {
      super.run(battle);
      auto game = battle.game;

      // tick down the timer; if it hits 0 this phase is over
      _timer -= game.deltaTime;
      if (_timer < 0) {
        onTimeout(battle);
        battle.states.pop();
      }

      drawTimer(game.graphics);
    }
  }

  /// Called when the state's time is up, before exit().
  protected void onTimeout(Battle battle) { }

  private void drawTimer(Renderer renderer) {
    auto batch = TextBatch(_font, DrawDepth.overlayText);

    Text text;

    text.color = (_timer > 3.0f) ? Color.gray : Color.red;
    text.transform = timerPos;
    text.text      = timerFormat.format(_timer);
    batch ~= text;

    renderer.draw(batch);
  }
}
