module battle.entities.particle;

import cid;
import constants;

struct Particle {
  enum {
    startScale = 0.1f,
    endScale   = 1f,
    startColor = Color(1f,1f,1f,1f),
    endColor   = Color(1f,1f,1f,0f),
    duration   = 0.5f,
  }

  Vector2f pos;
  float    angle;
  float    timeExisted = 0f;

  this(Vector2f pos, float angle) {
    this.pos = pos;
    this.angle = angle;
  }

  @property bool destroyed() { return timeExisted > duration; }

  void update(float timeElapsed) { this.timeExisted += timeElapsed; }

  auto primitive() {
    float lerpFactor = timeExisted / duration;

    RectPrimitive prim;

    prim.color    = startColor.lerp(endColor, lerpFactor);
    prim.filled   = true;
    prim.centered = true;

    prim.rect = [ pos.x, pos.y, 8, 3 ];
    prim.angle = angle;
    //prim.transform.scale = Vector2f(1,1) * lerpFactor;

    return prim;
  }
}
