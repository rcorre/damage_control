module states.place_cannons;

import std.range     : walkLength;
import std.format    : format;
import std.algorithm : count, filter;
import dau;
import dtiled;
import states.battle;
import states.timed_phase;
import tilemap;

private enum {
  phaseTime       = 5,
  cannonDepth     = 3,
  cannonsPerRound = 1,
  cannonsPerNode  = 1,
  tilesPerCannon  = 30,

  cannonCountFormat = "Cannons: %d",

  cannonCountPos = Vector2i(600, 10),
}

/// Player may place cannons within wall bounds
class PlaceCannons : TimedPhase {
  private ulong _cannons;

  this(Battle battle) {
    super(battle, phaseTime);
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);

      auto territory = battle.map.allTiles.filter!(x => x.isEnclosed);
      auto numNodes = territory.count!(x => x.hasReactor);

      _cannons =
        cannonsPerRound +                      // base cannon count
        numNodes * cannonsPerNode +            // node bonus
        territory.walkLength / tilesPerCannon; // territory bonus
    }

    void run(Battle battle) {
      super.run(battle);

      auto coord = battle.cursor.coord;

      // draw cannon at current tile under mouse if the player has another cannon to place
      if (_cannons > 0) battle.drawCannon(coord, 0, cannonDepth);

    }

    override void onConfirm(Battle battle) {
      auto map = battle.map;
      auto coord = battle.cursor.coord;

      if (_cannons > 0                 &&
          map.tileAt(coord).isEnclosed &&
          map.canBuildAt(coord)        &&
          map.canBuildAt(coord.south)  &&
          map.canBuildAt(coord.east)   &&
          map.canBuildAt(coord.south.east))
      {
        --_cannons;
        map.tileAt(coord).construct = Construct.cannon;
      }
    }
  }
}
