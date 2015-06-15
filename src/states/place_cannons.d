module states.place_cannons;

import std.range     : walkLength;
import std.algorithm : count, filter;
import dau;
import dtiled;
import states.battle;
import tilemap;

private enum {
  phaseTime       = 10,
  cannonDepth     = 2,
  cannonsPerRound = 1,
  cannonsPerNode  = 1,
  tilesPerCannon  = 30
}

/// Player may place cannons within wall bounds
class PlaceCannons : State!Battle {
  private float _timer;
  private ulong _cannons;

  override {
    void start(Battle battle) {
      _timer = phaseTime;

      auto territory = battle.map.tiles.filter!(x => x.isEnclosed);
      auto numNodes = territory.count!(x => x.hasNode);

      _cannons =
        cannonsPerRound +                      // base cannon count
        numNodes * cannonsPerNode +            // node bonus
        territory.walkLength / tilesPerCannon; // territory bonus
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
      //game.renderer.draw(map.tileOffset(centerCoord).as!Vector2i, _tileAtlas, game.renderer);

      if (game.input.mouseReleased(MouseButton.lmb)   &&
          _cannons > 0                                &&
          map.tileAt(mouseCoord).canPlaceCannon       &&
          map.tileAt(mouseCoord.south).canPlaceCannon &&
          map.tileAt(mouseCoord.east).canPlaceCannon  &&
          map.tileAt(mouseCoord.south.east).canPlaceCannon)
      {
        --_cannons;
        map.tileAt(mouseCoord).construct = Construct.cannon;
      }
    }
  }
}
