module battle.entities.camera;

import cid;

import constants;

struct Camera {
  private enum {
    // the cursor must move out of this region to begin scrolling
    scrolloff = Rect2f(32, 32, screenW - 64, screenH - 64),

    screencenter = Vector2f(screenW, screenH) / 2,
  }

  Vector2f topLeft = Vector2f.zero;

  void focus(Vector2f pos) {
    float offset;

    if ((offset = pos.x - scrolloff.left ) < 0 || // scroll left
        (offset = pos.x - scrolloff.right) > 0)   // scroll right
    {
      topLeft.x = offset;
    }

    if ((offset = pos.y - scrolloff.top   ) < 0 || // scroll up
        (offset = pos.y - scrolloff.bottom) > 0)   // scroll down
    {
      topLeft.y = offset;
    }
  }
}
