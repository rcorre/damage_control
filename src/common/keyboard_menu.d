/// Menu that allows configuration of keyboard controls
module common.keyboard_menu;

import std.conv   : to;
import std.array  : array;
import std.string : toUpper;
import std.algorithm : countUntil;
import cid;
import constants;
import common.menu;
import common.savedata;

/// Show the title screen.
class KeyboardMenu : Menu {
  private {
    SaveData      _saveData;
    EventHandler  _handler;
    string        _currentlyRemapping;
  }


  this(Game game, SaveData saveData) {
    super(
      MenuEntry("up"     , () => startMappingKey(game, "up"     )),
      MenuEntry("down"   , () => startMappingKey(game, "down"   )),
      MenuEntry("left"   , () => startMappingKey(game, "left"   )),
      MenuEntry("right"  , () => startMappingKey(game, "right"  )),
      MenuEntry("confirm", () => startMappingKey(game, "confirm")),
      MenuEntry("cancel" , () => startMappingKey(game, "cancel" )),
      MenuEntry("rotateL", () => startMappingKey(game, "rotateL")),
      MenuEntry("rotateR", () => startMappingKey(game, "rotateR")));

    _saveData = saveData;
  }

  @property bool isRemapping() { return _handler !is null; }

  override void deactivate() {
    super.deactivate();
    _saveData.save();
  }

  void startMappingKey(Game game, string name) {
    // the next time a key is pressed, map it to the selected action
    // consume the event so it is not handled by anything else
    _handler = game.events.onAnyKeyDown(k => remapKey(game, name, k),
        ConsumeEvent.yes);
    _currentlyRemapping = name;
  }

  void remapKey(Game game, string name, KeyCode keycode) {
    // check if we need to overwrite another key mapping to avoid a conflict
    string conflict;
    auto moveAxis = _saveData.controls.axes["move"];
    if (moveAxis.upKey    == keycode && name != "up")    conflict = "up";
    if (moveAxis.downKey  == keycode && name != "down")  conflict = "down";
    if (moveAxis.leftKey  == keycode && name != "left")  conflict = "left";
    if (moveAxis.rightKey == keycode && name != "right") conflict = "right";

    foreach(keyname, keycodes ; _saveData.controls.buttons)
      if (keycodes.keys[0] == keycode && keyname != name) conflict = keyname;

    // a button was pressed while mapping 'name'
    // figure out which contol 'name' corresponds to,
    // and update the corresponding control scheme entry
    switch (name) {
      case "up":
        _saveData.controls.axes["move"].upKey = keycode;
        break;
      case "down":
        _saveData.controls.axes["move"].downKey = keycode;
        break;
      case "left":
        _saveData.controls.axes["move"].leftKey = keycode;
        break;
      case "right":
        _saveData.controls.axes["move"].rightKey = keycode;
        break;
      case "confirm":
      case "cancel":
      case "rotateL":
      case "rotateR":
        _saveData.controls.buttons[name].keys[0] = keycode;
        break;
      default: assert(0, "unknown key " ~ name);
    }

    // register the new control scheme
    game.events.controlScheme = _saveData.controls;

    // stop intercepting key events
    _handler.unregister();
    _handler = null;
    _currentlyRemapping = null;

    // if we conflicted with a different key, immediately start remapping that
    if (conflict !is null && conflict != name) {
      // jump the menu selection to the new key so it's obvious to the user
      setSelection(conflict);
      startMappingKey(game, conflict);
    }
  }

  override void moveSelection(Vector2f direction) {
    // if remapping, a direction button should be captured by the remapping
    // handler rather than the menu motion handler
    if (!isRemapping) super.moveSelection(direction);
  }

  protected override void drawEntry(
      MenuEntry          entry,
      bool               isSelected,
      Vector2i           center,
      ref TextBatch      textBatch,
      ref PrimitiveBatch primBatch)
  {
      super.drawEntry(entry, isSelected, center, textBatch, primBatch);

      Text text;

      text.centered  = true;
      text.color     = Tint.neutral;
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
        return _saveData.controls.axes["move"].upKey.to!string.toUpper;
      case "down":
        return _saveData.controls.axes["move"].downKey.to!string.toUpper;
      case "left":
        return _saveData.controls.axes["move"].leftKey.to!string.toUpper;
      case "right":
        return _saveData.controls.axes["move"].rightKey.to!string.toUpper;
      case "confirm":
      case "cancel":
      case "rotateL":
      case "rotateR":
        return _saveData.controls.buttons[entryText].keys[0].to!string.toUpper;
      default:
        return "";
    }
  }
}
