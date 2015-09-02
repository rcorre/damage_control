module battle.states.timed_phase;

import std.format : format;
import cid;
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

  override {
    void enter(Battle battle) {
      super.enter(battle);
      _font = battle.game.fonts.get(fontName, fontSize);
    }

    void run(Battle battle) {
      super.run(battle);
      auto game = battle.game;

      // tick down the timer; if it hits 0 this phase is over
      _timer -= game.deltaTime;
      if (_timer < 0) battle.states.pop();

      drawTimer(game.renderer);
    }
  }

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
