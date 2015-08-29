/// Show the player how turret placement works
module battle.states.tutorial.turrets;

import std.exception;
import cid;
import dtiled;
import battle.battle;
import battle.states.tutorial.tutorial;

private enum {
  fontName  = "Mecha",
  fontSize  = 24,
  textDepth = 6,

  crossHairSpriteSheet = "tileset",
  crossHairDepth = 5,

  goodColor = Color(0, 1, 0, 0.2), // semi-transparent green
  badColor  = Color(1, 0, 0, 0.2), // semi-transparent red
}

/// Show the player how turret placement works
class TutorialTurrets : Tutorial {
  this(Battle battle) {
    super(battle);
  }

  override void enter(Battle battle) {
    super.enter(battle);

    auto map = battle.map;

    auto enclosed = map.allCoords.filter!(x => map.tileAt(x).isEnclosed);
    auto occupied = map.allCoords.filter!(x => map.tileAt(x).construct !is null);
    auto abyss    = map.allCoords.filter!(x => !map.tileAt(x).canBuild);
    auto outside  = map.allCoords.filter!(x => map.tileAt(x).canBuild &&
                                               !map.tileAt(x).isEnclosed &&
                                               !map.tileAt(x).hasWall);

    _states.push(
        new ShowMessage("You will now get to place 3 turrets."),

        new HighlightCoords(enclosed, goodColor,
          "You can place turrets inside your territory"),

        new HighlightCoords(occupied, badColor,
          "But not on top of another construct..."),

        new HighlightCoords(outside, badColor,
          "or outside your territory..."),

        new HighlightCoords(abyss, badColor,
          "or in this bottomless abyss."),

        new ShowMessage(
          "Use the directional keys (WASD) to select a location..."),

        new ShowMessage(
          "and press the confirm button (J) to confirm placement")
    );
  }
}
