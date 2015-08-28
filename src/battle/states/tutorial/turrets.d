/// Show the player how turret placement works
module battle.states.tutorial.turrets;

import std.exception;
import dau;
import dtiled;
import battle.battle;
import battle.states.tutorial.tutorial;

private enum {
  fontName  = "Mecha",
  fontSize  = 24,
  textDepth = 6,

  crossHairSpriteSheet = "tileset",
  crossHairDepth = 5,

  goodColor = Color(0, 1, 0, 0.5), // semi-transparent green
  badColor  = Color(1, 0, 0, 0.5), // semi-transparent red
}

/// Show the player how turret placement works
class TutorialTurrets : Tutorial {
  this(Battle battle) {
    super(battle);
  }

  override {
    void enter(Battle battle) {
      super.enter(battle);

      auto map = battle.map;

      auto enclosed = map.allTiles.filter!(x => x.isEnclosed);
      auto occupied = map.allTiles.filter!(x => x.construct !is null);
      auto outside  = map.allTiles.filter!(x => x.canBuild && !x.isEnclosed);
      auto abyss    = map.allTiles.filter!(x => !x.canBuild);

      _states.push(
          highlightCoords(enclosed, goodColor,
            "You can place turrets inside your territory"),

          highlightCoords(occupied, badColor,
            "But not on top of another construct ..."),

          highlightCoords(outside, badColor,
            "or outside your territory ..."),

          highlightCoords(abyss, badColor,
            "or in the bottomless abyss over here."));
    }

    void run(Battle battle) {
      super.run(battle);
    }
  }
}
