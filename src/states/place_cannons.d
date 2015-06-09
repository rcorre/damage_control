module states.place_cannons;

import dau;
import dtiled.coords;
import states.battle;
import tilemap;

private enum {
  phaseTime  = 10,
}

/// Player may place cannons within wall bounds
class PlaceCannons : State!Battle {
  private float _timer;

  override {
    void start(Battle battle) {
      _timer = phaseTime;
    }

    void run(Battle battle) {
      auto game = battle.game;
      auto mousePos = game.input.mousePos;
      auto map = battle.map;

      _timer -= game.deltaTime;

      if (_timer < 0) {
        //game.states.pop();
      }

      auto mouseCoord = map.coordAtPoint(mousePos);
      //_piece.draw(map.tileOffset(centerCoord).as!Vector2i, _tileAtlas, game.renderer);

      if (game.input.mouseReleased(MouseButton.lmb) && !map.tileAt(mouseCoord).isObstructed) {
        map.tileAt(mouseCoord).construct = Construct.cannon;
      }
    }
  }
}
