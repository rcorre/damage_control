/// Menu that allows configuration of keyboard controls
module title.keyboard_menu;

import std.conv   : to;
import std.array  : array;
import std.string : toUpper;
import title.menu;
import cid;

private enum neutralTint = Color(1f,1f,1f,0.5f);

/// Show the title screen.
class KeyboardMenu : TitleMenu {
  private {
    ControlScheme _controls;
    EventHandler  _handler;
    string        _currentlyRemapping;
  }

  this(Game game, ControlScheme controls) {
    super(game,
      MenuEntry("up"     , g => startMappingKey(g, "up"     )),
      MenuEntry("down"   , g => startMappingKey(g, "down"   )),
      MenuEntry("left"   , g => startMappingKey(g, "left"   )),
      MenuEntry("right"  , g => startMappingKey(g, "right"  )),
      MenuEntry("confirm", g => startMappingKey(g, "confirm")),
      MenuEntry("cancel" , g => startMappingKey(g, "cancel" )),
      MenuEntry("rotateL", g => startMappingKey(g, "rotateL")),
      MenuEntry("rotateR", g => startMappingKey(g, "rotateR")));

    _controls = controls;
  }

  @property bool isRemapping() { return _handler !is null; }

  void startMappingKey(Game game, string name) {
    // the next time a key is pressed, map it to the selected action
    // consume the event so it is not handled by anything else
    _handler = game.events.onAnyKeyDown(k => remapKey(game, name, k),
        ConsumeEvent.yes);
    _currentlyRemapping = name;
  }

  void remapKey(Game game, string name, KeyCode keycode) {
    // a button was pressed while mapping 'name'
    // figure out which contol 'name' corresponds to,
    // and update the corresponding control scheme entry
    switch (name) {
      case "up":
        _controls.axes["move"].upKey = keycode;
        break;
      case "down":
        _controls.axes["move"].downKey = keycode;
        break;
      case "left":
        _controls.axes["move"].leftKey = keycode;
        break;
      case "right":
        _controls.axes["move"].rightKey = keycode;
        break;
      case "confirm":
      case "cancel":
      case "rotateL":
      case "rotateR":
        _controls.buttons[name].keys[0] = keycode;
        break;
      default: assert(0, "unknown key " ~ name);
    }

    // register the new control scheme
    game.events.controlScheme = _controls;

    // stop intercepting key events
    _handler.unregister();
    _handler = null;
    _currentlyRemapping = null;
  }

  override void moveSelectionDown() {
    // if remapping, a direction button should be captured by the remapping
    // handler rather than the menu motion handler
    if (!isRemapping) super.moveSelectionDown();
  }

  override void moveSelectionUp() {
    // if remapping, a direction button should be captured by the remapping
    // handler rather than the menu motion handler
    if (!isRemapping) super.moveSelectionUp();
  }

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
    if (entryText == _currentlyRemapping) {
      return "-";
    }

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
