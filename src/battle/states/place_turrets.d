module battle.states.place_turrets;

import std.conv      : to;
import std.range     : walkLength;
import std.format    : format;
import std.algorithm : count, filter;

import engine;
import dtiled;

import battle.battle;
import battle.entities;
import battle.states.timed_phase;
import constants;
import common.input_hint;

private enum {
  // for drawing the remaining turret count
  fontName   = "Mecha",
  fontSize   = 16,
  textOffset = Vector2i(16, 24),

  cannonCountFormat = "Cannons: %d",

  cannonCountPos = Vector2i(screenW * 3/4, 10),
}

/// Player may place cannons within wall bounds
class PlaceTurrets : TimedPhase {
  private {
    int       _turretsLeft;
    SoundBank _soundOk;
    SoundBank _soundBad;
    Font      _font;
    InputHint _hint;
  }

  this(Battle battle, int numTurrets) {
    super(battle, PhaseTime.placeTurrets);
    _soundOk  = battle.game.audio.getSoundBank("place_ok");
    _soundBad = battle.game.audio.getSoundBank("place_bad");
    _turretsLeft = numTurrets;
    _font = battle.game.graphics.fonts.get(fontName, fontSize);
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);
      battle.cursor.positionInPlayerTerritory();

      // cannot place any turrets, skip this phase
      if (_turretsLeft <= 0) battle.states.pop();
    }

    void run(Battle battle) {
      super.run(battle);

      if (_turretsLeft > 0) {
        drawCursor(battle);
      }
      else if (!_soundOk.playing && !_soundBad.playing) {
        // no turrets left. pop, but wait so we don't clip the sounds
        battle.states.pop();
      }

      _hint.update(battle.game.deltaTime);
      with (InputHint.Action)
        _hint.draw(battle.game, battle.shakeTransform, up, down, left, right,
                   build, turbo);
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
        map.place(new Turret, coord);
        _soundOk.play();
        battle.shakeScreen(ScreenShakeIntensity.placeTurret);
      }
    }
  }

  private void drawCursor(Battle battle) {
    Sprite sprite;
    sprite.transform = battle.cursor.topLeft;
    sprite.region    = SpriteRegion.turretCursor;

    auto spriteBatch = SpriteBatch(battle.tileAtlas, DrawDepth.newTurret, battle.cameraTransform);
    spriteBatch ~= sprite;
    battle.game.graphics.draw(spriteBatch);

    Text text;
    text.transform = battle.cursor.topLeft + textOffset;
    text.text      = _turretsLeft.to!string;
    text.color     = Color.white;
    text.centered  = true;

    auto textBatch = TextBatch(_font, DrawDepth.newTurret, battle.cameraTransform);
    textBatch ~= text;
    battle.game.graphics.draw(textBatch);
  }
}
