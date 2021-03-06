/// Menu that allows configuration of controller controls
module common.gamepad_menu;

import std.conv   : to;
import std.array  : array;
import std.string : format, toUpper;
import engine;
import constants;
import common.menu;
import common.savedata;

/// Show the title screen.
class GamepadMenu : Menu {
  private {
    SaveData     _saveData;
    EventHandler _handler;
    string       _currentlyRemapping;
  }

  private ref auto controls() { return _saveData.controls; }

  this(Game game, SaveData saveData) {
    super(
      MenuEntry("up"     , () => startMappingAxis  (game, "up"     )),
      MenuEntry("down"   , () => startMappingAxis  (game, "down"   )),
      MenuEntry("left"   , () => startMappingAxis  (game, "left"   )),
      MenuEntry("right"  , () => startMappingAxis  (game, "right"  )),
      MenuEntry("confirm", () => startMappingButton(game, "confirm")),
      MenuEntry("cancel" , () => startMappingButton(game, "cancel" )),
      MenuEntry("turbo"  , () => startMappingButton(game, "turbo"  )),
      MenuEntry("rotateL", () => startMappingButton(game, "rotateL")),
      MenuEntry("rotateR", () => startMappingButton(game, "rotateR")),
      MenuEntry("menu",    () => startMappingButton(game, "menu")));

    _saveData = saveData;
  }

  @property bool isRemapping() { return _handler !is null; }

  override void deactivate() {
    super.deactivate();
    _saveData.save();
  }

  void startMappingButton(Game game, string name) {
    // the next time a button is pressed, map it to the selected action
    // consume the event so it is not handled by anything else
    _handler = game.events.onAnyButtonDown(b => remapButton(game, name, b),
        ConsumeEvent.yes);
    _currentlyRemapping = name;
  }

  void remapButton(Game game, string name, int button) {
    // check if we need to overwrite another key mapping to avoid a conflict
    string conflict;

    foreach(action, buttons ; controls.buttons)
      if (buttons.buttons[0] == button && action != name) conflict = action;

    // a button was pressed while mapping 'name'
    // figure out which control 'name' corresponds to,
    // and update the corresponding control scheme entry
    switch (name) {
      case "up":
        break;
      case "down":
        break;
      case "left":
        break;
      case "right":
        break;
      case "confirm":
      case "cancel":
      case "turbo":
      case "rotateL":
      case "rotateR":
      case "menu":
        controls.buttons[name].buttons[0] = button;
        break;
      default: assert(0, "unknown key " ~ name);
    }

    // register the new control scheme
    game.events.controlScheme = controls;

    // stop intercepting key events
    _handler.unregister();
    _handler = null;
    _currentlyRemapping = null;

    // if we conflicted with a different button, immediately start remapping that
    if (conflict !is null && conflict != name) {
      // jump the menu selection to the new key so it's obvious to the user
      setSelection(conflict);
      startMappingButton(game, conflict);
    }
  }

  void startMappingAxis(Game game, string name) {
    // the next time an axis is moved, map it to the selected direction
    // consume the event so it is not handled by anything else
    _handler = game.events.onAnyAxis(
        (stick, axis, pos) => remapAxis(game, name, stick, axis, pos),
        ConsumeEvent.yes);
    _currentlyRemapping = name;
  }

  void remapAxis(Game game, string name, int stick, int axis, float pos) {
    string conflict;

    auto moveAxis = controls.axes["move"];
    if (moveAxis.yAxis.stick == stick && moveAxis.yAxis.axis == axis) conflict = "up";
    if (moveAxis.xAxis.stick == stick && moveAxis.xAxis.axis == axis) conflict = "left";

    // an axis was moved.
    // figure out which control 'name' corresponds to,
    // and update the corresponding control scheme entry
    switch (name) {
      case "up":
      case "down":
        controls.axes["move"].yAxis.stick = stick;
        controls.axes["move"].yAxis.axis = axis;
        break;
      case "left":
      case "right":
        controls.axes["move"].xAxis.stick = stick;
        controls.axes["move"].xAxis.axis = axis;
        break;
      case "confirm":
      case "turbo":
      case "cancel":
      case "rotateL":
      case "rotateR":
      case "menu":
        break;
      default: assert(0, "unknown key " ~ name);
    }

    // register the new control scheme
    game.events.controlScheme = controls;

    // stop intercepting key events
    _handler.unregister();
    _handler = null;
    _currentlyRemapping = null;

    // if we conflicted with a different button, immediately start remapping that
    if (conflict !is null && conflict != name) {
      // jump the menu selection to the new key so it's obvious to the user
      setSelection(conflict);
      startMappingAxis(game, conflict);
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
      case "down":
        auto yAxis = controls.axes["move"].yAxis;
        return "<%d,%d>".format(yAxis.stick, yAxis.axis);
      case "left":
      case "right":
        auto xAxis = controls.axes["move"].xAxis;
        return "<%d,%d>".format(xAxis.stick, xAxis.axis);
      case "confirm":
      case "cancel":
      case "turbo":
      case "rotateL":
      case "rotateR":
      case "menu":
        return controls.buttons[entryText].buttons[0].to!string;
      default:
        return "";
    }
  }
}
