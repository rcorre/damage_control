module battle.states.place_turrets;

import std.conv      : to;
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
  cursorDepth = 5,

  // for drawing the remaining turret count
  fontName   = "Mecha",
  fontSize   = 16,
  textDepth  = 6,
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
  }

  this(Battle battle, int numTurrets) {
    super(battle, PhaseTime.placeTurrets);
    _soundOk  = battle.game.audio.getSoundBank("place_ok");
    _soundBad = battle.game.audio.getSoundBank("place_bad");
    _turretsLeft = numTurrets;
    _font = battle.game.fonts.get(fontName, fontSize);
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);
      battle.cursor.positionInPlayerTerritory();
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
      }
    }
  }

  private void drawCursor(Battle battle) {
    Sprite sprite;
    sprite.transform = battle.cursor.topLeft;
    sprite.region    = SpriteRegion.turretCursor;

    auto spriteBatch = SpriteBatch(battle.tileAtlas, cursorDepth);
    spriteBatch ~= sprite;
    battle.game.renderer.draw(spriteBatch);

    Text text;
    text.transform = battle.cursor.topLeft + textOffset;
    text.text      = _turretsLeft.to!string;
    text.color     = Color.white;
    text.centered  = true;

    auto textBatch = TextBatch(_font, cursorDepth);
    textBatch ~= text;
    battle.game.renderer.draw(textBatch);
  }
}
