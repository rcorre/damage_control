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

      auto validCoord = map.allCoords
        .find!(coord =>
          map.tileAt(coord).isEnclosed &&
          map.canBuildAt(coord)        &&
          map.canBuildAt(coord.south)  &&
          map.canBuildAt(coord.east)   &&
          map.canBuildAt(coord.south.east))
        .front
        .ifThrown(RowCol(0,0)); // just in case

      auto validPos = map.tileOffset(validCoord.south.east).as!Vector2f;

      auto wallCoord = map.allCoords
        .find!(coord => map.tileAt(coord).hasWall)
        .front
        .ifThrown(RowCol(0,0)); // just in case

      auto wallPos = map.tileOffset(wallCoord.south.east).as!Vector2f;

      auto outsideCoord = map.allCoords
        .filter!(coord => map.contains(coord.south) &&
                          map.contains(coord.east) &&
                          map.contains(coord.south.east))
        .find!(coord => !map.tileAt(coord).isEnclosed            &&
                        !map.tileAt(coord.south).isEnclosed      &&
                        !map.tileAt(coord.east).isEnclosed       &&
                        !map.tileAt(coord.south.east).isEnclosed &&
                        map.tileAt(coord).canBuild               &&
                        map.tileAt(coord.south).canBuild         &&
                        map.tileAt(coord.east).canBuild          &&
                        map.tileAt(coord.south.east).canBuild)
        .front
        .ifThrown(RowCol(0,0)); // just in case

      auto outsidePos = map.tileOffset(outsideCoord.south.east).as!Vector2f;

      auto abyssCoord = map.allCoords
        .filter!(coord => map.contains(coord.south) &&
                          map.contains(coord.east) &&
                          map.contains(coord.south.east))
        .find!(coord => !map.tileAt(coord).canBuild       &&
                        !map.tileAt(coord.south).canBuild &&
                        !map.tileAt(coord.east).canBuild  &&
                        !map.tileAt(coord.south.east).canBuild)
        .front
        .ifThrown(RowCol(0,0)); // just in case

      auto abyssPos = map.tileOffset(abyssCoord.south.east).as!Vector2f;

      _states.push(
          new ShowTip(validPos, Vector2f(2,2),
            "You can place turrets inside your territory"),
          new ShowTip(wallPos, Vector2f(2,2),
            "But not on top of another construct ..."),
          new ShowTip(outsidePos, Vector2f(2,2),
            "or outside your territory ..."),
          new ShowTip(abyssPos, Vector2f(2,2),
            "or in the bottomless abyss over here."));
    }

    void run(Battle battle) {
      super.run(battle);
    }
  }
}
