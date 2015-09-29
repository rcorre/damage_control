module common.input_hint;

import std.conv      : to;
import std.range     : only, iota, chunks, lockstep;
import std.string    : toUpper;
import std.typecons  : staticIota;
import std.algorithm : map;
import cid;
import constants;

private enum {
  startY = screenH * 1.00, // y position where hints enter the screen
  endY   = screenH * 0.95, // y position where hints are shown

  iconMargin = Vector2f(5, 5), // space between key icon and action

  hintTime = 0.5f, // duration of hint fade-in (secs)

  iconColor   = Color(1,1,1,0.7),
  textColor = Color(1,1,1,0.5),
}

enum Button {
  up      = "up",
  down    = "down",
  left    = "left",
  right   = "right",

  build   = "confirm",
  shoot   = "confirm",
  confirm = "confirm",

  back    = "cancel",
  cancel  = "cancel",

  rotateL = "rotateL",
  rotateR = "rotateR",
}

struct InputHint {
  private {
    string[] _prevHints;
    string[] _currentHints;

    float _progress = 0f;
  }

  void update(float time) {
    _progress = clamp(_progress + time / hintTime, 0, 1);
  }

  void draw(Game game, Button[] actions ...) {
    auto font = game.graphics.fonts.get("Mecha", 16);

    auto textBatch = TextBatch(font, 6);
    auto primBatch = PrimitiveBatch(5);

    foreach(i, action ; actions) {
      // get the name of the key currently mapped to this action
      immutable key = game.events.controlScheme.keyName(action);

      // entries are spaced evenly across the bottom
      // the y position rises over time (or falls when transitioning out)
      auto topLeft = Vector2f(
          (i + 1) * screenW / (actions.length + 1), // even horizontal spacing
          lerp(startY, endY, _progress));           // y pos rises up over time

      // this is the size of the box around the keyboard key icon
      auto keySize = font.sizeOf(key) + iconMargin;

      // draw the key name
      Text text;

      text.text      = key;
      text.color     = lerp(Color.black, iconColor, _progress);
      text.transform = topLeft;

      textBatch ~= text;

      // draw the name of the action bound to that key
      text.text      = action.to!string;
      text.color     = lerp(Color.black, textColor, _progress);
      text.transform = topLeft + Vector2f(keySize.x + iconMargin.x, 0);

      textBatch ~= text;

      // draw a box around the key name
      RectPrimitive box;

      box.rect  = Rect2f(topLeft - iconMargin / 2, keySize.x, keySize.y);
      box.color = lerp(Color.black, iconColor, _progress);

      primBatch ~= box;
    }

    game.graphics.draw(textBatch);
    game.graphics.draw(primBatch);
  }
}

private:
// get the name of the keyboard currently mapped to this button
auto keyName(ControlScheme controls, Button b) {
  KeyCode key;

  final switch (b) with (Button) {
    case up:
      key = controls.axes["move"].upKey;
      break;
    case down:
      key = controls.axes["move"].downKey;
      break;
    case left:
      key = controls.axes["move"].leftKey;
      break;
    case right:
      key = controls.axes["move"].rightKey;
      break;
    case confirm:
    case cancel:
    case rotateL:
    case rotateR:
      key = controls.buttons[b].keys[0];
      break;
  }

  return key.to!string.toUpper;
}
