module battle.entities.particle;

import dau;
import constants;

struct Particle {
  enum {
    startScale = 0.1f,
    endScale   = 1f,
    startColor = Color(1f,1f,1f,1f),
    endColor   = Color(1f,1f,1f,0f),
    duration   = 0.5f,
    spriteRect = Rect2i(3 * 16, 8 * 16, 16, 16), // col 3, row 8, 16x16
  }

  Vector2f pos;
  float    timeExisted = 0f;

  this(Vector2f pos) { this.pos = pos; }

  @property bool destroyed() { return timeExisted > duration; }

  void update(float timeElapsed) { this.timeExisted += timeElapsed; }

  auto sprite() {
    float lerpFactor = timeExisted / duration;

    Sprite sprite;

    sprite.color    = startColor.lerp(endColor, lerpFactor);
    sprite.centered = true;

    sprite.transform.pos   = pos;
    sprite.transform.angle = 0;
    sprite.transform.scale = Vector2f(1,1) * lerpFactor;

    sprite.region = spriteRect;

    return sprite;
  }
}
