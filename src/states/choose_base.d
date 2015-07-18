module states.choose_base;

import std.range;
import std.array;
import std.random;
import std.algorithm;
import dau;
import dtiled;
import jsonizer;
import tilemap;
import states.battle;
import states.battle_transition;

/// Player is holding a wall segment they can place with a mouse click
class ChooseBase : State!Battle {
  private RowCol _currentCoord;

  override {
    void start(Battle battle) {
      battle.states.push(new BattleTransition("Choose Base"));
    }

    void run(Battle battle) {
      auto game = battle.game;
      auto map = battle.map;

      auto newCoord = map.coordAtPoint(game.input.mousePos);

      if (newCoord != _currentCoord &&
          map.contains(newCoord)    &&
          map.tileAt(newCoord).hasReactor)
      {
        // clear old walls
        if (map.tileAt(_currentCoord).hasReactor) {
          foreach(coord ; battle.data.getWallCoordsForReactor(_currentCoord)) {
            map.tileAt(coord).construct = Construct.none;
          }
        }

        // place new walls
        foreach(coord ; battle.data.getWallCoordsForReactor(newCoord)) {
          map.tileAt(coord).construct = Construct.wall;
        }

        // register the current coord as the selected node
        _currentCoord = newCoord;
      }

      if (game.input.mouseReleased(MouseButton.lmb) &&
          map.tileAt(_currentCoord).hasReactor)
      {
        // mark all tiles in selected base area as enclosed
        foreach(tile ; map.enclosedTiles!(x => x.hasWall)(_currentCoord, Diagonals.yes)) {
          tile.isEnclosed = true;
        }

        // base is chosen, end this state
        battle.states.pop();
      }
    }
  }
}
