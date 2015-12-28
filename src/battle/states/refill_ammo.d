module battle.states.refill_ammo;

import std.math;
import std.range;
import std.algorithm;

import engine;
import dtiled;

import battle.battle;
import constants;
import transition;

/// Calculate ammo awarded this round and distribute it to turrets.
class RefillAmmo : BattleState {
  private {
    Bitmap      _ammoBitmap;
    AmmoIcon[]  _ammoIcons;
    SoundEffect _reloadSound;
    bool        _done;
  }

  override void enter(Battle battle) {
    super.enter(battle);

    _ammoBitmap = (battle.game.graphics.bitmaps.get(SpriteSheet.tileset));
    _reloadSound = battle.game.audio.getSound(Sounds.reload);

    auto turrets = battle.map.turrets
      .filter!(x => x.enclosed)          // only refill enclosed turrets
      .map!(x => x.repeat(x.ammoNeeded)) // one entry for each refill request
      .joiner;

    _ammoIcons = battle.map.reactors // for each reactor
      .filter!(x => x.enclosed)      // in player territory
      .map!(x => x.center            // around its center
        .repeat(ammoPerReactor)      // spawn several ammos
        .enumerate!int
        .map!(pair => AmmoIcon(pair.value, pair.index)))
      .joiner // join these into a single list
      .array; // and store

    foreach(ref ammo, turret ; _ammoIcons.lockstep(turrets)) {
      // for each refill request, wait a bit, then send the ammo to the turret
      battle.game.events.sequence(
          1.0, { ammo.position.go(turret.center); },
          0.5, { turret.ammo += 1;                },
          0  , { _reloadSound.play();             },
          0  , { ammo.visible = false;            },
          0  , { _done = true;                    });
    }
  }

  override void run(Battle battle) {
    super.run(battle);

    auto batch = SpriteBatch(_ammoBitmap, DrawDepth.ammoIcon);

    foreach(ref icon ; _ammoIcons) {
      icon.update(battle.game.deltaTime);
      icon.draw(batch);
    }

    battle.game.graphics.renderer.draw(batch);

    if (_done) battle.states.pop();
  }
}

private struct AmmoIcon {
  Transition!Vector2f position;
  bool visible = true;

  this(Vector2f start, int idx) {
    enum angleDelta = 2 * PI / ammoPerReactor;
    position.initialize(start, 0.5f);
    position.go(start + Vector2f.fromAngle(angleDelta * idx) * 60);
  }

  void update(float time) {
    position.update(time);
  }

  void draw(ref SpriteBatch sb) {
    if (!visible) return;

    Sprite sprite;

    sprite.transform = position.value;
    sprite.centered  = true;
    sprite.region    = SpriteRegion.rocket;

    sb ~= sprite;
  }
}
