module engine.geometry.vector;

import std.math, std.traits, std.range, std.conv, std.string, std.algorithm;
import jsonizer;

public alias Vector2f = Vector2!float;
public alias Vector2i = Vector2!int;

/// A 2-dimensional vector
struct Vector2(T : real) {
  mixin JsonizeMe;

  static if (isFloatingPoint!T) {
    alias AngleType = T;
  }
  else { // use float for angles of integral types
    alias AngleType = float;
  }

  /** Members *****************************************************************/
  @jsonize {
    T x = 0; 
    T y = 0;
  }

  this(T x, T y) {
    this.x = x;
    this.y = y;
  }

  this(T[2] vals) {
    this.x = vals[0];
    this.y = vals[1];
  }

  /** Static *****************************************************************/
  static auto fromAngle(AngleType angle) {
    return Vector2!T(cast(T) cos(angle), cast(T) sin(angle));
  }

  static auto zero()  { return Vector2!T(0, 0); }
  static auto unitX() { return Vector2!T(1, 0); }
  static auto unitY() { return Vector2!T(0, 1); }

  /** Properties **************************************************************/
  @property {
    /// get the length (magnitude) (x^2 + y^2)
    auto len() const {
      return cast(T) hypot(x, y);
    }

    /// set the length (magnitude) (x^2 + y^2)
    T len(T newLen) {
      auto prev_angle = angle; // save angle, it will change
      x = cast(T) (newLen * cos(prev_angle));
      y = cast(T) (newLen * sin(prev_angle));
      return newLen;
    }

    /// get the angle of the vector
    AngleType angle() const {
      return atan2(cast(AngleType) y, cast(AngleType) x);
    }

    /// get the angle of the vector
    AngleType angle(AngleType newAngle) {
      auto prev_len = len; // save len, it will change after assigning to x or y
      x = cast(T) (prev_len * cos(newAngle));
      y = cast(T) (prev_len * sin(newAngle));
      return newAngle;
    }

    /// return the unit vector representation
    auto unit() const {
      return len == 0 ? zero : Vector2!(T)(x / len, y / len);
    }

    /// vector with x coordinate negated
    auto mirroredH() {
      return Vector2!T(-x, y);
    }

    /// vector with y coordinate negated
    auto mirroredV() {
      return Vector2!T(x, -y);
    }

    /// replace unit with normalized eventually
    alias normalized = unit;
  }

  /** Methods *****************************************************************/
  /// normalize the vector in place
  void normalize() {
    if (len == 0) {
      x = y = 0;
    }
    else {
      auto prev_len = len;
      x /= prev_len;
      y /= prev_len;
    }
  }

  /// rotate the vector by angle
  void rotate(AngleType rotation_angle) {
    angle = angle + rotation_angle;
  }

  /// return a vector moved distance from this to dest
  auto movedTo(this T, U : real, V : real)(Vector2!U dest, V distance, out bool destReached) {
    auto disp = dest - this;
    if (disp.len < distance) {
      destReached = true;
      return dest;
    }
    else {
      destReached = false;
      return cast(T) (this + disp.normalized * distance);
    }
  }

  /// move vector distance toward dest, or place on dest if closer than distance
  /// return true if dest reached
  bool moveTo(V)(Vector2!V dest, real distance) {
    bool destReached;
    this = this.movedTo(dest, distance, destReached);
    return destReached;
  }

  auto clamp(U : real, V : real)(Vector2!U min, Vector2!V max) {
    auto rx = cast(T) fmax(min.x, fmin(max.x, x));
    auto ry = cast(T) fmax(min.y, fmin(max.y, y));
    return Vector2!T(rx, ry);
  }

  /** Operators ***************************************************************/
  auto opUnary(string op)() if (op == "-") {
    return Vector2(-x, -y);
  }

  // + or -
  auto opBinary(string op, V)(Vector2!V rhs) if (op == "-" || op == "+" || op == "/" || op == "*") {
    alias U = typeof(mixin("x" ~ op ~ "rhs.x")); // return type
    mixin("return Vector2!U(x" ~op~ "rhs.x, y" ~op~ "rhs.y);");
  }

  // * or /
  auto opBinary(string op, V : real)(V rhs) if (op == "*" || op == "/") {
    alias U = typeof(mixin("x" ~ op ~ "rhs")); // return type
    return Vector2!U(mixin("x" ~op~ "rhs"), mixin("y" ~op~ "rhs"));
  }

  // += or -=
  ref auto opOpAssign(string op, V)(Vector2!(V) rhs) if (op == "-" || op == "+") {
    x = cast(T) mixin("x" ~op~ "rhs.x");
    y = cast(T) mixin("y" ~op~ "rhs.y");
    return this;
  }

  // *= or /=
  ref auto opOpAssign(string op, V)(V rhs) if (op == "*" || op == "/") {
    x = cast(T) mixin("x" ~op~ "rhs");
    y = cast(T) mixin("y" ~op~ "rhs");
    return this;
  }

  // assignment from other vector of a potentially different type
  void opAssign(V)(Vector2!V rhs) {
    x = cast(T) rhs.x;
    y = cast(T) rhs.y;
  }

  void opAssign(T[2] vals) {
    x = vals[0];
    y = vals[1];
  }

  // == other vector, even if types differ
  bool opEquals(V)(auto ref const Vector2!V rhs) const {
    return x == rhs.x && y == rhs.y;
  }

  bool approxEqual(V)(Vector2!V other) {
    return std.math.approxEqual(x, other.x) && std.math.approxEqual(y, other.y);
  }

  /// cast to another vector type
  auto opCast(U : inout(Vector2!V), V)() const {
    return U(cast(V) x, cast(V) y);
  }
}

T distance(T)(Vector2!T v1, Vector2!T v2) {
  return (v2 - v1).len;
}

/// parse a Vector2!T from a string of format "x,y"
auto parseVector(T : real)(string csvSpec) {
  auto entries = csvSpec.splitter(",").map!(x => x.strip.to!T);
  assert(entries.walkLength == 2, "parseVector expects 'x,y', got " ~ csvSpec);
  T x = entries.front;
  entries.popFront;
  T y = entries.front;
  return Vector2!T(x, y);
}

// float vector
unittest {
  // test for rough equality
  enum close_enough = 1e-6;
  void approx(T)(T v1, T v2) {
    // float comparison
    static if (is(T : real)) {
      assert(abs(v1 - v2) < close_enough);
    }
    // vector comparison
    else if (is(typeof(v1.x) : real)) {
      assert(abs(v1.x - v2.x) < close_enough && abs(v1.y - v2.y) < close_enough);
    }
  }

  // construction
  auto v1 = Vector2!float.unitX;
  assert(v1.len == 1);
  assert(v1.angle == 0);
  // static construction
  assert(v1 == Vector2!float.fromAngle(0));
  assert(Vector2!float(sqrt(2f)/2, sqrt(2f)/2) == Vector2!float.fromAngle(PI / 4));
  assert(Vector2!float(sqrt(2f)/2, -sqrt(2f)/2) == Vector2!float.fromAngle(-PI / 4));
  assert(Vector2!float(-sqrt(2f)/2, -sqrt(2f)/2) == Vector2!float.fromAngle(-3 * PI / 4));
  assert(Vector2!float(-sqrt(2f)/2, sqrt(2f)/2) == Vector2!float.fromAngle(3 * PI / 4));
  // copy semantics
  auto v2 = v1;
  assert(v1 == v2);
  // length modification
  v2.len = 2;
  assert(v2.x == 2);
  assert(v2.y == 0);
  assert(v1.x == 1);
  assert(v1 != v2);
  // angle modification
  assert(v2.angle == 0);
  v2.angle = PI_2;
  approx(v2.angle, cast(float) PI_2);
  approx!float(v2.len, 2f); // length shouldn't change
  approx!(Vector2!float)(v2, Vector2!float(0, 2f));
  v2.angle = PI_4;
  approx(v2.x, v2.y);

  // unit vectors and normalization
  Vector2!float v3 = Vector2!float(3,4);
  Vector2!float u3 = v3.unit;
  assert(v3.angle == u3.angle);  // unit vector should have same angle
  approx!float(u3.len, 1); // unit vector should have length 1
  assert(v3.len == 5); // .unit should not modify original
  v3.normalize();
  approx!float(v3.len, 1);    // normalize should modify v3
  // special case
  assert(Vector2!float.zero.unit == Vector2!float.zero);
  v3 = Vector2!float.zero;
  v3.normalize();
  assert(v3 == Vector2!float.zero);

  // rotation
  auto v4 = Vector2!float.fromAngle(PI / 3);
  v4.rotate(PI / 4);
  approx(v4.angle, cast(float) (PI / 3 + PI / 4));
  v4.rotate(-PI / 3);
  approx(v4.angle, cast(float) PI / 4);

  // unary - op
  assert(Vector2!float(2,3) == -Vector2!float(-2,-3));

  // binary ops
  assert(Vector2!float.unitX + Vector2!float.unitY == Vector2!float(1,1));
  assert(Vector2!float(3,4) - Vector2!float(4,6) == Vector2!float(-1,-2));
  assert(Vector2!float.unitY * -2 == Vector2!float(0,-2));
  assert(Vector2!float(-4, 6) * 0.5 == Vector2!float(-2,3));

  // assignment ops
  auto v5 = Vector2!float(3,4);
  v5 += Vector2!float(1,2);
  assert(v5 == Vector2!float(4,6));
  v5 -= Vector2!float(3,4);
  assert(v5 == Vector2!float(1,2));
  v5 *= -2;
  assert(v5 == Vector2!float(-2,-4));
  v5 /= 4;
  assert(v5 == Vector2!float(-0.5,-1));

  // clamp
  auto v6 = Vector2f(12, -2);
  assert(v6.clamp(Vector2f(0, 0), Vector2f(10, 10)) == Vector2f(10, 0));

  // moveTo
  bool reachedDest;
  auto v7 = Vector2f(10, 10);
  reachedDest = v7.moveTo(Vector2f(10, 20), 5);
  approx(v7, Vector2f(10, 15));
  assert(!reachedDest);
  reachedDest = v7.moveTo(Vector2f(10, 20), 6);
  assert(reachedDest);
  approx(v7, Vector2f(10, 20));

  assert(Vector2f(0, 0).approxEqual(Vector2f(0.0000001, -0.0000001)));
}

// int vector
unittest {
  auto v1 = Vector2!int(3, 4);
  assert(v1.len == 5);
  v1 *= 2;
  assert(v1.len == 10 && v1.x == 6 && v1.y == 8);
  auto v2 = Vector2i.unitX;
  assert(v1 + v2 == Vector2!int(7,8));

  // casting test
  Vector2!int v3 = cast(Vector2!int) Vector2!float(5.7, 8.2);
  assert(v3.x == 5 && v3.y == 8);
  Vector2!float v4 = cast(Vector2f) Vector2i(5, 8);
  assert(v4.x == 5.0 && v4.y == 8.0);

  auto test(T)(Vector2!T v) {
    return v.x;
  }

  assert(test(v4) == 5.0);
  assert(test(v3) == 5);

  // assignment ops
  auto v5 = Vector2i(3,4);
  v5 += Vector2i(1,2);
  assert(v5 == Vector2i(4,6));
  v5 -= Vector2i(3,4);
  assert(v5 == Vector2i(1,2));
  v5 *= -2;
  assert(v5 == Vector2i(-2,-4));
  v5 /= 2;
  assert(v5 == Vector2i(-1,-2));
}

// parse vector
unittest {
  assert(parseVector!int("1,2") == Vector2i(1,2));
  assert(parseVector!float("1,2") == Vector2f(1,2));
  assert(parseVector!real("-1.75, 20.4") == Vector2!real(-1.75, 20.4));
}

/// Vector * Vector, Vector / Vector
unittest {
  assert(Vector2i(10, 4) / Vector2i(5, 4) == Vector2i(2, 1));
}
