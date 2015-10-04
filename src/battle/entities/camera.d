module battle.entities.camera;

import cid;

import constants;

struct Camera {
  private enum {
    scrolloff    = Rect2f(100, 100, screenW - 200, screenH - 200),
    screencenter = Vector2f(screenW, screenH) / 2,
  }

  Vector2f topLeft = Vector2f.zero;

  void focus(Vector2f pos) {
    if (pos.x < scrolloff.x) {
      topLeft.x = pos.x - scrolloff.x;
    }
    else if (pos.x > scrolloff.right) {
      topLeft.x = pos.x - scrolloff.right;
    }

    if (pos.y < scrolloff.y) {
      topLeft.y = pos.y - scrolloff.y;
    }
    else if (pos.y > scrolloff.bottom) {
      topLeft.y = pos.y - scrolloff.bottom;
    }
  }

  void recenter() { topLeft = Vector2f.zero; }
}
