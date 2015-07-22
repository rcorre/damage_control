module enemy;

import std.math;
import std.random;
import dau;
import dtiled;
import tilemap;

struct EnemyContext {
  float    timeElapsed;
  RowCol[] targets;
  TileMap  tileMap;
  void delegate(Vector2f origin, Vector2f target) spawnProjectile;
}

class Enemy {
  private enum {
    accuracy      = 0.5,
    speed         = 90,
    rotationSpeed = 4,
    range         = 240,

    minHoverTime = 0.5,
    maxHoverTime = 2.0,
  }

  Transform!float transform;
  float           fireCooldown;
  RowCol          target;
  bool            destroyed;

  protected StateStack!Enemy states;

  this(Vector2f position) {
    this.transform = position;
    this.fireCooldown = uniform(minEnemyFireCooldown, maxEnemyFireCooldown);
  }

  ref auto pos() { return transform.pos; }
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
    return context.map.tileAt(self.target).hasWall;
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
    if (!hasTarget(self, context)) self.states.pop();

    auto targetPos = context.map.tileCenter(self.target).as!Vector2f;

    // rotate towards the target
    auto angleDiff = self.transform.angle - (targetPos - self.pos).angle;

    if (!angleDiff.approxEqual(0, 0.1)) {
      self.transform.angle -=
        angleDiff.sgn * self.rotationSpeed * context.timeElapsed;
    }

    if (self.pos.distance(targetPos) > self.range) {
      // not in range, so move towards the target
      self.pos.moveTo(targetPos, game.deltaTime * self.speed);
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
    auto target = self.target;

    if (uniform(0f, 1f) > enemyAccuracy) {
      // simulate a 'miss' by targeting an adjacent tile
      target = target.adjacent(Diagonals.yes).randomSample(1).front;
    }

    auto targetPos = context.map.tileCenter(self.target).as!Vector2f;

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

  override void enter(Enemy self, EnemyContext context) {
    _timer = uniform(minHoverTime, maxHoverTime);
  }

  override void run(Enemy self, EnemyContext context) {
    _timer -= context.timeElapsed;
    if (_timer < 0) self.states.pop();

    auto targetPos = context.map.tileCenter(self.target).as!Vector2f;

    self.pos = targetPos + (self.pos - targetPos).rotated(self.rotationSpeed);

    // keep facing towards the target
    self.transform.angle = (targetPos - self.pos).angle;
  }
}
