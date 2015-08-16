module battle.entities.rocket;

import dau;
import constants;

struct Rocket {
  private enum {
    accuracy      = 0.5,
    speed         = 500,
    rotationSpeed = 4,
    circlingSpeed = 1.0,
    range         = 240,

    minHoverTime = 0.5,
    maxHoverTime = 2.0,

    minCrashTime = 0.5,
    maxCrashTime = 1.5,

    minCrashSpeed = 30.0f,
    maxCrashSpeed = 90.0f,

    fragmentProbability = 0.1f, // chance to split into fragments on die()

    spriteRect = Rect2i(2 * 16, 8 * 16, 16, 16), // col 2, row 8
  }

  private {
    Transform!float _transform;
    Vector2f        _velocity;
    float           _duration;
  }

  this(Vector2f start, Vector2f target) {
    _transform = start;

    auto path = target - start;
    _velocity = path.normalized * speed;
    _duration = path.len / speed;
  }

  @property bool destroyed() { return _duration < 0; }
  @property auto position() { return _transform.pos; }

  void update(float timeElapsed) {
    _duration -= timeElapsed;
    _transform.pos += _velocity * timeElapsed;
  }

  void draw(ref SpriteBatch batch) {
    Sprite sprite;

    sprite.color     = Color.white;
    sprite.centered  = true;
    sprite.transform = _transform;

    sprite.transform.angle = _velocity.angle;

    sprite.region = spriteRect;

    batch ~= sprite;
  }
}
