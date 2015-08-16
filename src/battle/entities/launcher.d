module battle.entities.launcher;

import dau;

struct Launcher {
  Vector2f position;
  int ammo;

  this(Vector2f position) {
    this.position = position;
    this.ammo = 2;
  }
}
