/// Menu that allows configuration of controller controls
module title.gamepad_menu;

import std.conv   : to;
import std.array  : array;
import std.string : format, toUpper;
import title.menu;
import dau;

private enum neutralTint = Color(1f,1f,1f,0.5f);

/// Show the title screen.
class GamepadMenu : TitleMenu {
  private {
    ControlScheme _controls;
    EventHandler  _handler;
    string        _currentlyRemapping;
  }

  this(Game game, ControlScheme controls) {
    super(game,
      MenuEntry("up"     , g => startMappingAxis  (g, "up"     )),
      MenuEntry("down"   , g => startMappingAxis  (g, "down"   )),
      MenuEntry("left"   , g => startMappingAxis  (g, "left"   )),
      MenuEntry("right"  , g => startMappingAxis  (g, "right"  )),
      MenuEntry("confirm", g => startMappingButton(g, "confirm")),
      MenuEntry("cancel" , g => startMappingButton(g, "cancel" )),
      MenuEntry("turbo"  , g => startMappingButton(g, "turbo"  )),
      MenuEntry("rotateL", g => startMappingButton(g, "rotateL")),
      MenuEntry("rotateR", g => startMappingButton(g, "rotateR")));

    _controls = controls;
  }

  @property bool isRemapping() { return _handler !is null; }

  void startMappingButton(Game game, string name) {
    // the next time a button is pressed, map it to the selected action
    // consume the event so it is not handled by anything else
    _handler = game.events.onAnyButtonDown(b => remapButton(game, name, b),
        ConsumeEvent.yes);
    _currentlyRemapping = name;
  }

  void remapButton(Game game, string name, int button) {
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
        _controls.buttons[name].buttons[0] = button;
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

  void startMappingAxis(Game game, string name) {
    // the next time an axis is moved, map it to the selected direction
    // consume the event so it is not handled by anything else
    _handler = game.events.onAnyAxis(
        (stick, axis, pos) => remapAxis(game, name, stick, axis, pos),
        ConsumeEvent.yes);
    _currentlyRemapping = name;
  }

  void remapAxis(Game game, string name, int stick, int axis, float pos) {
    // an axis was moved.
    // figure out which control 'name' corresponds to,
    // and update the corresponding control scheme entry
    switch (name) {
      case "up":
      case "down":
        _controls.axes["move"].yAxis.stick = stick;
        _controls.axes["move"].yAxis.axis = axis;
        break;
      case "left":
      case "right":
        _controls.axes["move"].xAxis.stick = stick;
        _controls.axes["move"].xAxis.axis = axis;
        break;
      case "confirm":
      case "cancel":
      case "rotateL":
      case "rotateR":
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
      case "down":
        auto yAxis = _controls.axes["move"].yAxis;
        return "<%d,%d>".format(yAxis.stick, yAxis.axis);
      case "left":
      case "right":
        auto xAxis = _controls.axes["move"].xAxis;
        return "<%d,%d>".format(xAxis.stick, xAxis.axis);
      case "confirm":
      case "cancel":
      case "rotateL":
      case "rotateR":
        return _controls.buttons[entryText].buttons[0].to!string;
      default:
        return "";
    }
  }
}
