module states.place_cannons;

import std.range     : walkLength;
import std.format    : format;
import std.algorithm : count, filter;
import dau;
import dtiled;
import states.battle;
import tilemap;

private enum {
  phaseTime       = 5,
  cannonDepth     = 3,
  cannonsPerRound = 1,
  cannonsPerNode  = 1,
  tilesPerCannon  = 30,

  fontName  = "Mecha",
  fontSize  = 24,
  textDepth = 1,

  titleText         = "Install Cannons",
  cannonCountFormat = "Cannons: %d",
  timerCountFormat  = "Time: %2.1f",

  timerPos       = Vector2i(10, 10),
  titlePos       = Vector2i(300, 10),
  cannonCountPos = Vector2i(600, 10),
}

/// Player may place cannons within wall bounds
class PlaceCannons : State!Battle {
  private float _timer;
  private ulong _cannons;
  private Font  _font;

  override {
    void enter(Battle battle) {
      _font = battle.game.fonts.get(fontName, fontSize);
      _timer = phaseTime;

      auto territory = battle.map.allTiles.filter!(x => x.isEnclosed);
      auto numNodes = territory.count!(x => x.hasReactor);

      _cannons =
        cannonsPerRound +                      // base cannon count
        numNodes * cannonsPerNode +            // node bonus
        territory.walkLength / tilesPerCannon; // territory bonus
    }

    void run(Battle battle) {
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

      // tick down the timer; if it hits 0 or we are done placing cannons, pop the state
      _timer -= game.deltaTime;
      if (_timer < 0 || _cannons == 0) battle.states.pop();

      drawText(game.renderer);
    }
  }

  private void drawText(Renderer renderer) {
    auto batch = TextBatch(_font, textDepth);

    Text text;

    // title
    text.color     = Color.gray;
    text.transform = titlePos;
    text.text      = titleText;
    batch ~= text;

    // timer
    text.color = (_timer > 3.0f) ? Color.gray : Color.red;
    text.transform = timerPos;
    text.text      = timerCountFormat.format(_timer);
    batch ~= text;

    // cannon counter
    text.color = (_cannons > 0) ? Color.gray : Color.red;
    text.transform = cannonCountPos;
    text.text      = cannonCountFormat.format(_cannons);
    batch ~= text;

    renderer.draw(batch);
  }
}
