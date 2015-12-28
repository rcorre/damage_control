module engine.geometry.transform;

import std.math;
import engine.allegro;
import engine.geometry.vector;

/// Encompasses positional, rotational, and scale data.
struct Transform(T) {
  alias AngleType = Vector2!T.AngleType;

  /** Members *****************************************************************/
  Vector2!T pos   = Vector2!T.zero;  /// position in space
  Vector2!T scale = Vector2!T(1, 1); /// x and y scaling
  AngleType angle = 0;               /// rotation in radians

  private ALLEGRO_TRANSFORM _trans;

  /** Construction **************************************************************/
  this(U)(Vector2!U pos) {
    this.pos = pos;
  }

  void opAssign(U)(Vector2!U pos) {
    this.pos = pos;
    this.scale = [1, 1];
    this.angle = 0;
  }

  /** Properties **************************************************************/
  @property {
    /// Get the matrix transformation based on the position, scale, angle
    const(ALLEGRO_TRANSFORM*) transform() {
      al_identity_transform(&_trans);
      al_scale_transform(&_trans, scale.x, scale.y);
      al_rotate_transform(&_trans, angle);
      al_translate_transform(&_trans, pos.x, pos.y);
      return &_trans;
    }
  }

  /** Methods *****************************************************************/
  auto compose(Transform!T other) {
    Transform t;
    t.pos   = this.pos   + other.pos;
    t.angle = this.angle + other.angle;
    t.scale = this.scale * other.scale;
    return t;
  }

  /// Use the transformation matrix to transform a point.
  auto transform(T)(Vector2!T point) {
    Vector2f pt = cast(Vector2f) point;
    al_transform_coordinates(transform, &pt.x, &pt.y);
    return cast(Vector2!T) pt;
  }
}

/// translation
unittest {
  Transform!int s;
  Vector2i v;
  assert(s.transform(v) == Vector2i.zero);

  s.pos = Vector2i(3, -2);
  assert(s.transform(v) == Vector2i(3, -2));
}

/// rotation
unittest {
  import std.math;
  Transform!int s;
  s.angle = PI_2;
  Vector2i v = [5, 0];
  assert(s.transform(v) == Vector2i(0, 5));
  s.angle += PI;
  assert(s.transform(v) == Vector2i(0, -5));
  s.pos.x += 3;
  assert(s.transform(v) == Vector2i(3, -5));
}

/// scaling
unittest {
  import std.math;
  Transform!int s;
  s.scale *= 2;
  Vector2i v = [5, -3];
  assert(s.transform(v) == Vector2i(10, -6));
}
