module states.choose_base;

import std.math : sgn;
import std.range;
import std.random;
import std.algorithm : filter;
import std.container : Array;
import dau;
import dtiled;
import jsonizer;
import tilemap;
import states.battle;

/// Player is holding a wall segment they can place with a mouse click
class ChooseBase : BattleState {
  private RowCol       _currentCoord;
  private Array!RowCol _reactorCoords;

  override {
    void enter(Battle battle) {
      _reactorCoords = Array!RowCol(battle.map
        .allCoords
        .filter!(x => battle.map.tileAt(x).hasReactor));
            
      _currentCoord = _reactorCoords.front;
    }

    void onCursorMove(Battle battle, Vector2i direction) {
      // try to pick a reactor in the direction the cursor was moved
      auto next = _reactorCoords[].find!(x =>
          sgn(x.row - _currentCoord.row) == direction.y ||
          sgn(x.col - _currentCoord.col) == direction.x);

      if (!next.empty) {
        // clear walls from previous selection
        foreach(coord ; battle.data.getWallCoordsForReactor(_currentCoord)) {
          battle.map.tileAt(coord).construct = Construct.none;
        }

        // set walls for new selection
        _currentCoord = next.front;

        // clear walls from previous selection
        foreach(coord ; battle.data.getWallCoordsForReactor(_currentCoord)) {
          battle.map.tileAt(coord).construct = Construct.wall;
        }
      }
    }

    void onConfirm(Battle battle) {
      // mark all tiles in area surrounding the selection as enclosed
      foreach(tile ; battle.map.enclosedTiles!(x => x.hasWall)(_currentCoord, Diagonals.yes)) {
        tile.isEnclosed = true;
      }

      // base is chosen, end this state
      battle.states.pop();
    }
  }
}
