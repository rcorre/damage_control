module battle.states.recenter_camera;

import cid;
import battle.battle;
import battle.entities.camera;

private enum {
  recenterSpeed = 200,
}

/// Move the camra gradually back to a centered position.
/// This is used after the fight state to ensure the camera is centered for the
/// construction phase.
class RecenterCamera : BattleState {
  override void run(Battle battle) {
    super.run(battle);
    auto dist = recenterSpeed * battle.game.deltaTime;
    if (battle.camera.topLeft.moveTo(Vector2f.zero, dist)) battle.states.pop();
  }
}
