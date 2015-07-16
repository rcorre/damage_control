module states.place_cannons;

import std.range     : walkLength;
import std.format    : format;
import std.algorithm : count, filter;
import dau;
import dtiled;
import states.battle;
import states.battle_phase;
import tilemap;

private enum {
  phaseTime       = 5,
  cannonDepth     = 3,
  cannonsPerRound = 1,
  cannonsPerNode  = 1,
  tilesPerCannon  = 30,

  titleText         = "Install Cannons",
  cannonCountFormat = "Cannons: %d",

  cannonCountPos = Vector2i(600, 10),
}

/// Player may place cannons within wall bounds
class PlaceCannons : BattlePhase {
  private ulong _cannons;

  this() {
    super(titleText, phaseTime);
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

      auto game = battle.game;
      auto mousePos = game.input.mousePos;
      auto map = battle.map;

      auto mouseCoord = map.coordAtPoint(mousePos);

      // draw cannon at current tile under mouse if the player has another cannon to place
      if (_cannons > 0) battle.drawCannon(mouseCoord, 0, cannonDepth);

      // try to place cannon if LMB clicked
      if (game.input.mouseReleased(MouseButton.lmb) &&
          _cannons > 0                              &&
          map.canBuildAt(mouseCoord)                &&
          map.canBuildAt(mouseCoord.south)          &&
          map.canBuildAt(mouseCoord.east)           &&
          map.canBuildAt(mouseCoord.south.east))
      {
        --_cannons;
        map.tileAt(mouseCoord).construct = Construct.cannon;
      }

    }
  }
}
