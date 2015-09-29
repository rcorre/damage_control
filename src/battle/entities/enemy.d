module battle.entities.enemy;

import std.math;
import std.range;
import std.random;
import std.algorithm;
import cid;
import dtiled;
import battle.entities.tilemap;
import constants;

struct EnemyContext {
  float    timeElapsed; // time elapsed this frame
  float    timeTillEnd; // time until battle ends
  RowCol[] targets;     // tiles that have walls
  TileMap  tileMap;

  void delegate(Vector2f origin, Vector2f target) spawnProjectile;
  void delegate(Vector2f origin)                  spawnExplosion;
}

class Enemy {
  private enum {
    accuracy      = 0.5,
    speed         = 90,
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

    spriteOffset = Vector2i(4 * 16, 6 * 16),
    spriteSize   = Vector2i(32, 32),
  }

  Transform!float transform;
  float           fireCooldown;
  RowCol          target;
  bool            destroyed;
  bool            crashing;
  Rect2i          spriteRect;

  protected StateStack!(Enemy, EnemyContext) states;

  this(Vector2f position) {
    this.transform = position;
    states.push(new SelectTarget);
    spriteRect = Rect2i(spriteOffset, spriteSize);
  }

  ref auto pos() { return transform.pos; }

  void update(EnemyContext context) {
    states.run(this, context);

    // otherwise try to find the nearest exit
    auto exitPath =
      only(
        Vector2f(0      ,   pos.y),    // consider exiting left
        Vector2f(screenW,   pos.y),    // consider exiting right
        Vector2f(pos.x  ,       0),    // consider exiting top
        Vector2f(pos.x  , screenH))    // consider exiting bottom
      .map!(x => x - pos)              // compute path to each exit
      .minPos!((a,b) => a.len < b.len) // find the shortest
      .front;                          // take it!

    if (!crashing && exitPath.len / speed > context.timeTillEnd) {
      auto velocity = exitPath.normalized * speed;
      states.push(new LeaveBattle(velocity));
    }
  }

  void draw(ref SpriteBatch batch, in Vector2i animationOffset) {
    Sprite sprite;

    sprite.color     = Color.white;
    sprite.centered  = true;
    sprite.transform = transform;

    sprite.region = spriteRect;
    sprite.region.x += animationOffset.x;
    sprite.region.y += animationOffset.y;

    batch ~= sprite;
  }

  void die(Vector2f projectilePos, void delegate(Enemy) spawnFragment) {
    auto trajectory = (transform.pos - projectilePos).normalized;

    if (uniform01 < fragmentProbability) {
      foreach (i ; 0..4) {
        auto fragment = new Enemy(this.transform.pos);

        fragment.spriteRect.x += (i % 2) * spriteRect.width / 2;
        fragment.spriteRect.y += (i / 2) * spriteRect.height / 2;
        fragment.spriteRect.width = spriteRect.width / 2;
        fragment.spriteRect.height = spriteRect.height / 2;

        fragment.states.push(new Mayday(this, trajectory));
        spawnFragment(fragment);
      }

      this.destroyed = true;
    }
    else {
      states.push(new Mayday(this, trajectory));
    }
  }
}

private:
// base class for an enemy state providing default implementations
abstract class EnemyState : State!(Enemy, EnemyContext) {
  override void enter(Enemy self, EnemyContext context) { }

  override void exit(Enemy self, EnemyContext context) { }

  override void run(Enemy self, EnemyContext context) {
    self.fireCooldown -= context.timeElapsed;
  }

  static bool hasTarget(Enemy self, EnemyContext context) {
    return context.tileMap.tileAt(self.target).hasWall;
  }
}

class SelectTarget : EnemyState {
  override void enter(Enemy self, EnemyContext context) {
    self.target = context.targets.randomSample(1).front;
    self.states.push(new ApproachTarget);
  }
}

class ApproachTarget : EnemyState {
  override void run(Enemy self, EnemyContext context) {
    // stop trying to approach target if it is gone
    if (!hasTarget(self, context)) {
      self.states.pop();
      return;
    }

    auto targetPos = context.tileMap.tileCenter(self.target).as!Vector2f;

    // rotate towards the target
    auto angleDiff = self.transform.angle - (targetPos - self.pos).angle;

    if (!angleDiff.approxEqual(0, 0.1)) {
      self.transform.angle -=
        angleDiff.sgn * self.rotationSpeed * context.timeElapsed;
    }

    if (self.pos.distance(targetPos) > self.range) {
      // not in range, so move towards the target
      self.pos.moveTo(targetPos, context.timeElapsed * self.speed);
    }
    else {
      self.states.replace(new FireAtTarget); // in range, prepare to fire
      self.states.push(new Hover);           // but wait a bit first
    }
  }
}

class Hover : EnemyState {
  private float _timer;

  override void enter(Enemy self, EnemyContext context) {
    _timer = uniform(self.minHoverTime, self.maxHoverTime);
  }

  override void run(Enemy self, EnemyContext context) {
    _timer -= context.timeElapsed;
    if (_timer < 0) self.states.pop();
  }
}

class FireAtTarget : EnemyState {
  override void enter(Enemy self, EnemyContext context) {
    auto targetPos = context.tileMap.tileCenter(self.target).as!Vector2f;

    if (uniform(0f, 1f) > self.accuracy) {
      // simulate a 'miss' by targeting an area within 2 tiles of the target
      targetPos += Vector2f(uniform(-2, 2), uniform(-2, 2)) * tileSize;
    }

    context.spawnProjectile(self.pos, targetPos);

    if (hasTarget(self, context)) {
      // target was not destroyed
      self.states.push(new CircleTarget, new Hover);
    }
    else {
      // target was destroyed
      self.states.pop();
    }
  }
}

class CircleTarget : EnemyState {
  private float _timer;
  private float _factor;

  override void enter(Enemy self, EnemyContext context) {
    _timer = uniform(self.minHoverTime, self.maxHoverTime);
    _factor = uniform(-1f, 1f);
  }

  override void run(Enemy self, EnemyContext context) {
    _timer -= context.timeElapsed;
    if (_timer < 0) {
      self.states.pop();
      return;
    }

    auto targetPos = context.tileMap.tileCenter(self.target).as!Vector2f;

    auto offset = self.pos - targetPos;
    auto rotation = self.circlingSpeed * context.timeElapsed * _factor;
    offset.rotate(rotation);

    auto newTarget = targetPos + offset;

    // try not to rotate out of the map bounds
    if (newTarget.x < 0 || newTarget.x > screenW ||
        newTarget.y < 0 || newTarget.y > screenH)
    {
      // rotate in the opposite direction instead
      offset = self.pos - targetPos;
      offset.rotate(-rotation);
    }

    self.pos = newTarget;

    // keep facing towards the target
    self.transform.angle = (targetPos - self.pos).angle;
  }
}

/// Spin out of control, then explode.
class Mayday : EnemyState {
  private float    _timer;
  private Vector2f _velocity;
  private float    _angularVelocity;
  private float    _deltaScale;

  this(Enemy self, Vector2f trajectory) {
    _timer = uniform(self.minCrashTime, self.maxCrashTime);
    _velocity = trajectory * uniform(self.minCrashSpeed, self.maxCrashSpeed);
    _angularVelocity = uniform(-3f, 3f) * self.rotationSpeed;
    _deltaScale = uniform(0.3f, 0.7f) / _timer;
  }

  override void enter(Enemy self, EnemyContext context) {
    self.crashing = true;
  }

  override void run(Enemy self, EnemyContext context) {
    _timer -= context.timeElapsed;
    if (_timer < 0) {
      self.destroyed = true;
      context.spawnExplosion(self.pos);
    }

    self.pos += _velocity * context.timeElapsed;
    self.transform.angle += _angularVelocity * context.timeElapsed;
    self.transform.scale -= Vector2f(1,1) * _deltaScale * context.timeElapsed;
  }
}

/// Try to leave the battlefield
class LeaveBattle : EnemyState {
  Vector2f _velocity;

  this(Vector2f velocity) {
    _velocity = velocity; // set velocity towards exit
  }

  override void enter(Enemy self, EnemyContext context) {
    // if already out of bounds, stay
    if (self.pos.x < 0 || self.pos.x > screenW ||
        self.pos.y < 0 || self.pos.y > screenH)
    {
      self.states.push(new Hover);
    }
  }

  override void run(Enemy self, EnemyContext context) {
    // rotate towards the direction of movement
    auto angleDiff = self.transform.angle - _velocity.angle;
    if (!angleDiff.approxEqual(0, 0.1)) {
      self.transform.angle -=
        angleDiff.sgn * self.rotationSpeed * context.timeElapsed;
    }

    // move towards an exit
    self.pos += _velocity * context.timeElapsed;
  }
}
