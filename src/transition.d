/// Represents a smooth transition between two values
module transition;

import dau;
import std.math : pow;

struct Transition(T) if (is(typeof(T.init.lerp(T.init, 0f)) : T)) {
  T     start;
  T     end;
  float progress;
  float duration;

  void initialize(T initial, float duration) {
    hold(initial);
    this.duration = duration;
  }

  void hold(T val) {
    start = val;
    end = val;
    progress = 0f;
  }

  void go(T to) {
    go(this.value, to);
  }

  void go(T start, T end) {
    this.start    = start;
    this.end      = end;
    this.progress = 0f;
  }

  void update(float timeElapsed) {
    progress = min(1f, progress + timeElapsed / duration);
  }

  auto value() {
    return start.lerp(end, progress.pow(0.35));
  }
}
