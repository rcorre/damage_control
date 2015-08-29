module battle.states.choose_base;

import std.range;
import std.random;
import std.algorithm : filter, minPos;
import std.container : Array;
import dau;
import dtiled;
import jsonizer;
import battle.battle;
import battle.states.timed_phase;
import battle.entities;
import constants;

/// Player is holding a wall segment they can place with a mouse click
class ChooseBase : TimedPhase {
  private {
    RowCol       _currentCoord;
    Array!RowCol _reactorCoords;
    bool _choiceConfirmed;
  }

  this(Battle battle) {
    super(battle, PhaseTime.chooseBase);
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);
      _reactorCoords = Array!RowCol(battle.map
        .allCoords
        .filter!(x => battle.map.tileAt(x).hasReactor));

      _currentCoord = _reactorCoords.front;
      selectReactor(battle, _currentCoord);
    }

    void exit(Battle battle) {
      super.exit(battle);

      // if player hasn't picked something by now, pick for them
      if (!_choiceConfirmed) confirmChoice(battle);
    }

    void onCursorMove(Battle battle, Vector2f direction) {
      auto dist(RowCol coord) { return _currentCoord.manhattan(coord); }

      // try to pick the closest reactor in the direction the cursor was moved
      auto res = _reactorCoords[]
        .filter!(x => x != _currentCoord)
        .filter!(coord =>
          (direction.y < 0 && (coord.row - _currentCoord.row) < 0) ||
          (direction.y > 0 && (coord.row - _currentCoord.row) > 0) ||
          (direction.x < 0 && (coord.col - _currentCoord.col) < 0) ||
          (direction.x > 0 && (coord.col - _currentCoord.col) > 0))
        .minPos!((a,b) => dist(a) < dist(b));

      if (!res.empty) {
        // clear walls from previous selection
        foreach(coord ; battle.data.getWallCoordsForReactor(_currentCoord)) {
          battle.map.clear(coord);
        }

        selectReactor(battle, res.front);
      }
    }

    void onConfirm(Battle battle) {
      confirmChoice(battle);
      battle.states.pop();
    }
  }

  private void selectReactor(Battle battle, RowCol reactorCoord) {
    // set walls for new selection
    _currentCoord = reactorCoord;

    // place walls around new base
    foreach(coord ; battle.data.getWallCoordsForReactor(_currentCoord)) {
      battle.map.place(new Wall, coord);
    }

    // The walls need to evaluate their sprites _after_ they are all placed
    foreach(coord ; battle.data.getWallCoordsForReactor(_currentCoord)) {
      battle.map.regenerateWallSprite(coord);
    }
  }

  private void confirmChoice(Battle battle) {
    _choiceConfirmed = true;

    // mark all tiles in area surrounding the selection as enclosed
    foreach(tile ; battle.map.enclosedTiles!(x => x.hasWall)(_currentCoord, Diagonals.yes)) {
      tile.isEnclosed = true;
    }
  }
}
