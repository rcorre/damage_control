module battle.states.place_turrets;

import std.range     : walkLength;
import std.format    : format;
import std.algorithm : count, filter;
import dau;
import dtiled;
import battle.battle;
import battle.entities;
import battle.states.timed_phase;
import constants;

private enum {
  phaseTime         = 5,
  newTurretDepth    = 5,

  cannonCountFormat = "Cannons: %d",

  cannonCountPos = Vector2i(screenW * 3/4, 10),
}

/// Player may place cannons within wall bounds
class PlaceTurrets : TimedPhase {
  private {
    int       _turretsLeft;
    Turret    _turret;
    SoundBank _soundOk;
    SoundBank _soundBad;
  }

  this(Battle battle, int numTurrets) {
    super(battle, phaseTime);
    _soundOk  = battle.game.audio.getSoundBank("place_ok");
    _soundBad = battle.game.audio.getSoundBank("place_bad");
    _turretsLeft = numTurrets;
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);
      if (_turretsLeft > 0) _turret = new Turret;

      // try to place the cursor at a reactor the player owns.
      auto allReactors = battle.map.constructs
        .map!(x => cast(Reactor) x)
        .filter!(x => x !is null);

      auto ownedReactors = allReactors.filter!(x => x.enclosed);

      battle.cursor.center = ownedReactors.empty ?
        allReactors.front.center : ownedReactors.front.center;
    }

    void run(Battle battle) {
      super.run(battle);

      // position the turret at the cursor and draw it to the screen
      if (_turret !is null) {
        _turret.topLeft = battle.cursor.topLeft;
        auto batch = SpriteBatch(battle.tileAtlas, newTurretDepth);
        _turret.draw(batch, battle.animationOffset);
        battle.game.renderer.draw(batch);
      }
    }

    override void onConfirm(Battle battle) {
      auto map = battle.map;
      auto coord = battle.cursor.coord;

      if (_turretsLeft > 0             &&
          map.tileAt(coord).isEnclosed &&
          map.canBuildAt(coord)        &&
          map.canBuildAt(coord.south)  &&
          map.canBuildAt(coord.east)   &&
          map.canBuildAt(coord.south.east))
      {
        --_turretsLeft;
        map.place(_turret, coord);
        _soundOk.play();

        _turret = (_turretsLeft > 0) ? new Turret : null;
      }
      else {
        _soundBad.play();
      }
    }
  }
}
