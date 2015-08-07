/// Menu that allows configuration of controls
module title.controls_menu;

import std.conv      : to;
import std.array     : array;
import std.string    : toUpper;
import std.algorithm : map;
import title.menu;
import dau;

private enum {
  subduedTint   = Color(1f,1f,1f,0.25f),
  neutralTint   = Color(1f,1f,1f,0.5f),
  highlightTint = Color(1f,1f,1f,1f),
}

/// Show the title screen.
class ControlsMenu : TitleMenu {
  private {
    ControlScheme _controls;
  }

  this(Game game, ControlScheme controls) {
    super(game,
      MenuEntry("up"     , (g) { }),
      MenuEntry("down"   , (g) { }),
      MenuEntry("left"   , (g) { }),
      MenuEntry("right"  , (g) { }),
      MenuEntry("confirm", (g) { }),
      MenuEntry("cancel" , (g) { }),
      MenuEntry("rotateL", (g) { }),
      MenuEntry("rotateR", (g) { }));
    _controls = controls;
  }

  void mapButton(string name) { }

  protected override void drawEntry(
      MenuEntry       entry,
      bool            isSelected,
      Vector2i        center,
      ref TextBatch   textBatch,
      ref SpriteBatch spriteBatch)
  {
      super.drawEntry(entry, isSelected, center, textBatch, spriteBatch);
      Text text;

      text.centered  = true;
      text.color     = neutralTint;
      text.transform = center + Vector2i(120, 0);

      text.text = controlName(entry.text);

      textBatch ~= text;
  }

  string controlName(string entryText) {
    switch (entryText) {
      case "up":
        return _controls.axes["move"].upKey.to!string.toUpper;
      case "down":
        return _controls.axes["move"].downKey.to!string.toUpper;
      case "left":
        return _controls.axes["move"].leftKey.to!string.toUpper;
      case "right":
        return _controls.axes["move"].rightKey.to!string.toUpper;
      case "confirm":
      case "cancel":
      case "rotateL":
      case "rotateR":
        return _controls.buttons[entryText].keys[0].to!string.toUpper;
      default:
        return "";
    }
  }
}
