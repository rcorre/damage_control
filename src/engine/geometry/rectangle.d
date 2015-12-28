module engine.geometry.rectangle;

import std.string, std.algorithm, std.conv, std.array;
import engine.geometry.vector;
import engine.util.math : clamp;

alias Rect2i = Rect2!int;
alias Rect2f = Rect2!float;

struct Rect2(T : real) {
  T x, y, width, height;

  this(T x, T y, T width, T height) {
    this.x      = x;
    this.y      = y;
    this.width  = width;
    this.height = height;
  }

  this(U : T)(U[4] vals) {
    this(vals[0], vals[1], vals[2], vals[3]);
  }

  this(U : T)(Vector2!U topLeft, U width, U height) {
    this(topLeft.x, topLeft.y, width, height);
  }

  this(U : T)(Vector2!U topLeft, Vector2!U size) {
    this(topLeft.x, topLeft.y, size.x, size.y);
  }

  static auto centeredAt(U : T)(Vector2!U center, U width, U height) {
    return Rect2!T(center.x - width / 2, center.y - height / 2, width, height);
  }

  @property {
    T top()             { return y; }
    T top(U : T)(U val) { return y = val; }

    T left()             { return x; }
    T left(U : T)(U val) { return x = val; }

    T bottom()             { return y + height; }
    T bottom(U : T)(U val) { return y = val - height; }

    T right()             { return x + width; }
    T right(U : T)(U val) { return x = val - width; }

    auto center() { return Vector2!T(x + width / 2, y + height / 2); }
    auto center(U : T)(Vector2!U val) {
      x = val.x - width / 2;
      y = val.y - height / 2;
      return center;
    }

    auto topLeft() { return Vector2!T(x, y); }
    auto topLeft(U)(Vector2!U val) if (is(typeof(U.init) : T)) {
      x = val.x;
      y = val.y;
      return topLeft;
    }

    auto topRight() { return Vector2!T(right, y); }
    auto topRight(U)(Vector2!U val) if (is(typeof(U.init) : T)) {
      right = val.x;
      top = val.y;
      return topRight;
    }

    auto bottomLeft() { return Vector2!T(left, bottom); }
    auto bottomLeft(U)(Vector2!U val) if (is(typeof(U.init) : T)) {
      left = val.x;
      bottom = val.y;
      return bottomLeft;
    }

    auto bottomRight() { return Vector2!T(right, bottom); }
    auto bottomRight(U)(Vector2!U val) if (is(typeof(U.init) : T)) {
      right  = val.x;
      bottom = val.y;
      return bottomRight;
    }
  }

  void opAssign(U : T)(U[4] vals) {
    this.x      = vals[0];
    this.y      = vals[1];
    this.width  = vals[2];
    this.height = vals[3];
  }

  /// cast to another rect type
  auto opCast(U : inout(Rect2!V), V)() const {
    return U(cast(V) x, cast(V) y, cast(V) width, cast(V) height);
  }

  bool contains(U : T)(U px, U py) {
    return px >= x && px <= right && py >= y && py <= bottom;
  }

  bool contains(U : T)(Vector2!U point) {
    return point.x >= x && point.x <= right && point.y >= y && point.y <= bottom;
  }

  bool contains(U : T)(Rect2!U rect) {
    return rect.x >= x && rect.right <= right && rect.y >= y && rect.bottom <= bottom;
  }

  bool intersects(U : T)(Rect2!U rect) {
    return !(rect.right < x || rect.x > right || rect.bottom < y || rect.y > bottom);
  }

  void keepInside(U : T)(Rect2!U bounds, int buffer = 0) {
    bounds.x += buffer / 2;
    bounds.y += buffer / 2;
    bounds.width  -= buffer / 2;
    bounds.height -= buffer / 2;
    if (x < bounds.x) { x = bounds.x; }
    if (y < bounds.y) { y = bounds.y; }
    if (right  > bounds.right)  { right = bounds.right; }
    if (bottom > bounds.bottom) { bottom = bounds.bottom; }
  }

  static Rect2!T aggregate(Rect2!T[] rects ...) {
    T top, bottom, left, right;
    foreach(rect ; rects) {
      left   = min(left   , rect.x);
      right  = max(right  , rect.right);
      top    = min(top    , rect.y);
      bottom = max(bottom , rect.bottom);
    }
    return Rect2!T(left, top, right - left, bottom - top);
  }
}

void keepInside(T)(ref Vector2!T point, Rect2!T area) {
  point.x = clamp(point.x, area.left, area.right);
  point.y = clamp(point.y, area.top, area.bottom);
}

auto parseRect(T : real)(string csvSpec) {
  auto entries = csvSpec.splitter(",").map!(x => x.strip.to!T);
  auto vals = entries.array;
  assert(vals.length == 4, "failed to parse rectangle from %s (need 4 values)".format(csvSpec));
  return Rect2!T(vals[0], vals[1], vals[2], vals[3]);
}

// int rects
unittest {
  auto r1 = Rect2i(1, 2, 3, 4);
  // value access
  assert(r1.x == 1 && r1.y == 2 && r1.width == 3 && r1.height == 4);
  assert(r1.bottom == 6 && r1.right == 4);
  assert(r1.center == Vector2i(2, 4)); // center is an approximate -- rounds down
  // assignments
  r1.bottom = 10;
  assert(r1.y == 6 && r1.center == Vector2i(2, 8));

  auto r2 = Rect2i(0, 0, 20, 20);

  assert(!r1.contains(r2) && r2.contains(r1));

  auto cont = Rect2i.aggregate(Rect2i(0, 0, 10, 20), Rect2i(-10, 12, 16, 12));
  assert(cont == Rect2i(-10, 0, 20, 24));
}

// float rects
unittest {
  auto r1 = Rect2f(1, 2, 3, 4);
  assert(r1.x == 1 && r1.y == 2 && r1.width == 3 && r1.height == 4);
  assert(r1.bottom == 6 && r1.right == 4);
  assert(r1.center == Vector2f(2.5, 4)); // center is an approximate -- rounds down

  r1.bottom = 5.5;
  assert(r1.y == 1.5 && r1.center == Vector2f(2.5, 3.5));
}

// parsing
unittest {
  assert("1,2,3,4".parseRect!int == Rect2i(1, 2, 3, 4));
  assert("-1.4,2.6, 1.8, 42.7".parseRect!float == Rect2f(-1.4, 2.6, 1.8, 42.7));
}

// assigning from different types
unittest {
  import std.math : approxEqual;

  Rect2f r = Rect2f(1, 2, 3, 4);
  assert(r.topLeft == Vector2f(1,2));

  r.topLeft = Vector2i(3,4);
  assert(r.topLeft == Vector2f(3,4));

  r = [1,2,3,4];
  assert(r.topLeft == Vector2f(1,2));
  assert(r.bottomRight == Vector2f(4,6));

  r.top = 5;
  assert(r.top == 5f);

  auto r2 = Rect2f.centeredAt(Vector2i(2,2), 4, 4);
  assert(r2.topLeft == Vector2f.zero);
}
