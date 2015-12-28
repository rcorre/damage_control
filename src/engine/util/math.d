module engine.util.math;

import std.math : ceil, floor;
import std.algorithm : min, max, sum, map;
import std.range : zip;

/// represent a value that is always clamped between two other values
struct Clamped(T, alias lower, alias upper) if (is(typeof(clamp(T.init, lower, upper)) : T)) {
  alias val this;

  private @property ref T val() {
    _val = _val.clamp(lower, upper);
    return _val;
  }
  private T _val;
}

/// add amount to start, but don't let it go past end
T approach(T, U, V)(T start, U end, V amount) {
  if (start < end) {
    return cast(T) min(start + amount, end);
  }
  else {
    return cast(T) max(start + amount, end);
  }
}

/// keep val between lower and upper
T clamp(T, U, V)(T val, U lower, V upper) if (is(typeof(min(V.init, max(U.init, T.init))) : T)) {
  return min(upper, max(lower, val));
}

T average(T)(T[] vals ...) if (is(typeof(((T.init + T.init) / T.init)) : T)) {
  return vals.sum / vals.length;
}

auto weightedAverage(T, U)(T[] vals, U[] weights) if (is(typeof(((T.init * U.init) / U.init)) : real)) {
  assert(vals.length == weights.length, "vals and weights must be equal size");
  return vals.zip(weights).map!(x => x[0] * x[1]).sum / weights.sum;
}

int roundUp(real val) {
  return cast(int) ceil(val);
}

int roundDown(real val) {
  return cast(int) floor(val);
}

/// linearly interpolate between start and end. factor is clamped between 0 (start) and 1 (end)
T lerp(T, U : real)(T start, T end, U factor)
  if (is(typeof(cast(T) (start + (end - start) * factor))))
{
  factor = clamp(factor, 0, 1);
  return cast(T) (start + (end - start) * factor);
}

unittest {
  Clamped!(float, 0, 1) f;

  f = 0;
  assert(f == 0);

  f = -2;
  assert(f == 0);

  f = 1;
  assert(f == 1);

  f = 3;
  assert(f == 1);

  f = 0.5f;
  assert(f == 0.5f);

  f += 1.5f;
  assert(f == 1.0f);
}

unittest {
  assert(5.approach(9, 3) == 8);
  assert(5.approach(9, 12) == 9);
  assert(9.approach(5, -2) == 7);
  assert(9.approach(5, -8) == 5);

  assert(5.clamp(0, 3) == 3);
  assert((-2).clamp(0, 3) == 0);
  assert(0.clamp(-5, 5) == 0);

  assert(clamp(0.5, 0, 1) == 0.5);
  assert(clamp(1.5, 0, 1) == 1);
  assert(clamp(-1.5, 0, 1) == 0);

  assert(lerp(0, 20, 0.5) == 10);
  assert(lerp(10, -10, 0.8) == -6);
}

/// vector lerp
unittest {
  import engine.geometry.vector;

  auto v1 = Vector2i.zero;
  auto v2 = Vector2i.unitX * 10;
  assert(lerp(v1, v2, 0) == v1);
  assert(lerp(v1, v2, 0.5) == Vector2i(5, 0));
  assert(lerp(v1, v2, 1) == Vector2i(10, 0));

  auto v3 = Vector2f(3, 4);
  auto v4 = Vector2f(6, -3);
  assert(lerp(v3, v4, 0.5).approxEqual(Vector2f(4.5, 0.5)));
}
