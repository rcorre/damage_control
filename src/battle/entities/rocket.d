module battle.entities.rocket;

import engine;
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

    particleInterval = 0.01f,
  }

  private {
    Transform!float _transform;
    Vector2f        _velocity;
    float           _duration;
    float           _particleTimer;
  }

  this(Vector2f start, Vector2f target) {
    _transform.pos = start;

    auto path = target - start;
    _velocity = path.normalized * speed;
    _duration = path.len / speed;

    _transform.angle = _velocity.angle;

    _particleTimer = particleInterval;
  }

  @property bool destroyed() { return _duration < 0; }
  @property auto position() { return _transform.pos; }

  void update(float timeElapsed, void delegate(Vector2f, float) spawnParticle) {
    _duration -= timeElapsed;
    _transform.pos += _velocity * timeElapsed;

    _particleTimer -= timeElapsed;
    if (_particleTimer < 0) {
      _particleTimer = particleInterval;
      spawnParticle(_transform.pos, _transform.angle);
    }
  }

  void draw(ref SpriteBatch batch) {
    Sprite sprite;

    sprite.color     = Color.white;
    sprite.centered  = true;
    sprite.transform = _transform;

    sprite.region = SpriteRegion.rocket;

    batch ~= sprite;
  }
}
