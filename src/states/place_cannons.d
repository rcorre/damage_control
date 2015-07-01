module states.place_cannons;

import std.range     : walkLength;
import std.algorithm : count, filter;
import dau;
import dtiled;
import states.battle;
import states.fight_ai;
import tilemap;

private enum {
  phaseTime       = 5,
  cannonDepth     = 3,
  cannonsPerRound = 1,
  cannonsPerNode  = 1,
  tilesPerCannon  = 30
}

/// Player may place cannons within wall bounds
class PlaceCannons : State!Battle {
  private float  _timer;
  private ulong  _cannons;

  override {
    void start(Battle battle) {
      _timer = phaseTime;

      auto territory = battle.map.allTiles.filter!(x => x.isEnclosed);
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

      if (_timer < 0 || _cannons == 0) {
        battle.states.replace(new FightAI(0));
      }

      auto mouseCoord = map.coordAtPoint(mousePos);

      // draw cannon at current tile under mouse if the player has another cannon to place
      if (_cannons > 0) battle.drawCannon(mouseCoord, cannonDepth);

      // try to place cannon if LMB clicked
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
