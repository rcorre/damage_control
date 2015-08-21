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
  turretsPerRound   = 1,
  turretsPerReactor = 1,
  tilesPerTurret    = 30,

  cannonCountFormat = "Cannons: %d",

  cannonCountPos = Vector2i(screenW * 3/4, 10),
}

/// Player may place cannons within wall bounds
class PlaceTurrets : TimedPhase {
  private {
    ulong     _turretsLeft;
    Turret    _turret;
    SoundBank _soundOk;
    SoundBank _soundBad;
  }

  this(Battle battle) {
    super(battle, phaseTime);
    _soundOk  = battle.game.audio.getSoundBank("place_ok");
    _soundBad = battle.game.audio.getSoundBank("place_bad");
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);

      auto territory = battle.map.allTiles.filter!(x => x.isEnclosed);
      auto numNodes = territory.count!(x => x.hasReactor);

      _turretsLeft =
        turretsPerRound +                      // base cannon count
        numNodes * turretsPerReactor +            // node bonus
        territory.walkLength / tilesPerTurret; // territory bonus

      if (_turretsLeft > 0) _turret = new Turret;
    }

    void run(Battle battle) {
      super.run(battle);

      // position the turret at the cursor and draw it to the screen
      if (_turret !is null) {
        _turret.position = battle.cursor.center;
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
