module battle.states.choose_base;

import std.range;
import std.random;
import std.algorithm : filter, minPos;
import std.container : Array;

import engine;
import dtiled;

import battle.battle;
import battle.states.timed_phase;
import battle.entities;
import constants;
import common.input_hint;

/// Player is holding a wall segment they can place with a mouse click
class ChooseBase : TimedPhase {
  private {
    RowCol       _currentCoord;
    Array!RowCol _reactorCoords;
    bool         _choiceConfirmed;
    InputHint    _hint;
    SoundEffect  _confirmSound; // sound to play on confirming selection
    EventHandler _handler;
  }

  this(Battle battle) {
    super(battle, PhaseTime.chooseBase);
    _reactorCoords = Array!RowCol(battle.map
        .allCoords
        .filter!(x => battle.map.tileAt(x).hasReactor));

    selectReactor(battle, _reactorCoords.front);

    _confirmSound = battle.game.audio.getSound(Sounds.chooseBase);
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);
      selectReactor(battle, _currentCoord);
      _handler = battle.game.events.onAxisTapped("move", (dir) => onAxisTap(battle, dir));
    }

    void exit(Battle battle) {
      super.exit(battle);
      _handler.unregister();
    }

    void run(Battle battle) {
      super.run(battle);

      _hint.update(battle.game.deltaTime);
      with (InputHint.Action)
      _hint.draw(battle.game, battle.shakeTransform, up, down, left, right, confirm);
    }

    void onTimeout(Battle battle) {
      // if player hasn't picked something by now, pick for them
      if (!_choiceConfirmed) confirmChoice(battle);
    }

    void onConfirm(Battle battle) {
      confirmChoice(battle);
      battle.states.pop();
    }

    override void onCursorMove(Battle battle, Vector2f direction) {
      // ignore cursor move event -- instead hook in to axis tap events
    }
  }

  private:
  void selectReactor(Battle battle, RowCol reactorCoord) {
    // if we re-enter the state from pause, don't re-select the same reactor
    if (reactorCoord == _currentCoord) return;

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

  void confirmChoice(Battle battle) {
    _choiceConfirmed = true;

    // mark all tiles in area surrounding the selection as enclosed
    foreach(tile ; battle.map.enclosedTiles!(x => x.hasWall)(_currentCoord, Diagonals.yes)) {
      tile.isEnclosed = true;
    }

    _confirmSound.play();
    battle.shakeScreen(ScreenShakeIntensity.chooseBase);
  }

  void onAxisTap(Battle battle, Vector2f direction) {
    auto dist(RowCol coord) { return _currentCoord.manhattan(coord); }

    // try to pick the closest reactor in the direction the cursor was moved
    auto res = _reactorCoords[]
      .filter!(x => battle.map.tileAt(x).reactor !is
               battle.map.tileAt(_currentCoord).reactor)
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
}
