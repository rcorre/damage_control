/// Represents a smooth transition between two values
module transition;

import dau;
import std.math : pow;

struct Transition(T, alias fn = x => x)
  if (is(typeof(T.init.lerp(T.init, 0f)) : T) && is(typeof(fn(0f)) : float))
{
  T     start;
  T     end;
  float progress;
  float duration;

  @property auto value() { return start.lerp(end, fn(progress)); }
  @property bool done() { return progress == 1f; }

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
}
