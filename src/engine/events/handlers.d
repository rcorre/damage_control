module engine.events.handlers;

import std.conv      : to;
import std.traits    : EnumMembers;
import std.typecons  : Flag;
import std.algorithm : any;
import engine.allegro;
import engine.geometry;
import engine.events.input;
import engine.events.keycodes;

alias EventAction   = void delegate();
alias AxisAction    = void delegate(Vector2f axisPos);
alias AnyAxisAction = void delegate(int stick, int axis, float pos);
alias KeyAction     = void delegate(KeyCode key);
alias ButtonAction  = void delegate(int button);
alias CustomAction  = void delegate(in ALLEGRO_EVENT ev);

alias ConsumeEvent = Flag!"ConsumeEvent";

abstract class EventHandler {
  private bool _active = true;
  const ConsumeEvent consume;

  this(ConsumeEvent consume) { this.consume = consume; }

  @property bool active() { return _active; }

  void unregister() { _active = false; }

  bool handle(in ALLEGRO_EVENT ev);

  // called after changing the control scheme
  void updateControls(ControlScheme controls) { }
}

// generic event handler
class CustomHandler : EventHandler {
  private {
    CustomAction       _action;
    ALLEGRO_EVENT_TYPE _type;
  }

  this(CustomAction action, ALLEGRO_EVENT_TYPE type, ConsumeEvent consume) {
    super(consume);
    _action = action;
    _type  = type;
  }

  override bool handle(in ALLEGRO_EVENT ev) {
    if (ev.type == _type) {
      _action(ev);
      return true;
    }

    return false;
  }
}
class TimerHandler : EventHandler {
  private {
    EventAction          _action;
    bool                 _repeat;
    ALLEGRO_EVENT_QUEUE* _queue;
    ALLEGRO_TIMER*       _timer;
  }

  this(EventAction action, double secs, bool repeat, ALLEGRO_EVENT_QUEUE* queue) {
    // the event is specific to this handler, never pass it along
    super(ConsumeEvent.yes);
    _action = action;
    _repeat = repeat;
    _queue  = queue;
    _timer  = al_create_timer(secs);

    // register and start timer
    al_register_event_source(_queue, al_get_timer_event_source(_timer));
    al_start_timer(_timer);
  }

  ~this() {
    al_destroy_timer(_timer);
  }

  override void unregister() {
    super.unregister();

    al_unregister_event_source(_queue, al_get_timer_event_source(_timer));
  }

  override bool handle(in ALLEGRO_EVENT ev) {
    if (ev.type == ALLEGRO_EVENT_TIMER && ev.timer.source == _timer) {
      _action();
      if (!_repeat) unregister();
      return true;
    }

    return false;
  }

  /// Pause a running timer. Does nothing if already paused.
  void stop() { al_stop_timer(_timer); }

  /// Resume a paused timer. Does nothing if already running.
  void start() { al_start_timer(_timer); }
}

class ButtonHandler : EventHandler {
  enum Type { press, release }

  private {
    EventAction _action;
    Type        _type;
    string      _name;
    KeyCode[]   _keys;
    int[]       _buttons;
  }

  this(EventAction action,
       Type type,
       ControlScheme controls,
       string name,
       ConsumeEvent consume)
  {
    super(consume);
    _action = action;
    _type   = type;
    _name   = name;

    updateControls(controls);
  }

  override bool handle(in ALLEGRO_EVENT ev) {
    final switch (_type) with (Type) {
      case press:
        if (_keys[].any!(x => ev.isKeyPress(x)) ||
            _buttons[].any!(x => ev.isButtonPress(x)))
        {
          _action();
          return true;
        }
        break;
      case release:
        if (_keys[].any!(x => ev.isKeyRelease(x)) ||
            _buttons[].any!(x => ev.isButtonRelease(x)))
        {
          _action();
          return true;
        }
        break;
    }

    return false;
  }

  override void updateControls(ControlScheme controls) {
    assert(_name in controls.buttons, "unknown button name " ~ _name);
    _keys = controls.buttons[_name].keys;
    _buttons = controls.buttons[_name].buttons;
  }
}

class AxisHandler : EventHandler {
  private enum Direction : ubyte { up, down, left, right };

  private {
    AxisMap    _map;
    AxisAction _action;
    string     _name;

    bool[4]  _dpad;
    Vector2f _joystick;
  }

  this(AxisAction action,
      ControlScheme controls,
      string name,
      ConsumeEvent consume)
  {
    super(consume);

    _action   = action;
    _name     = name;
    _joystick = Vector2f.zero;

    updateControls(controls);
  }

  override bool handle(in ALLEGRO_EVENT ev) {
    bool handled = true;

    with (Direction) {
      if      (ev.isKeyPress  (_map.downKey)) dpad(down, true);
      else if (ev.isKeyRelease(_map.downKey)) dpad(down, false);

      else if (ev.isKeyPress  (_map.upKey)) dpad(up, true);
      else if (ev.isKeyRelease(_map.upKey)) dpad(up, false);

      else if (ev.isKeyPress  (_map.leftKey)) dpad(left, true);
      else if (ev.isKeyRelease(_map.leftKey)) dpad(left, false);

      else if (ev.isKeyPress  (_map.rightKey)) dpad(right, true);
      else if (ev.isKeyRelease(_map.rightKey)) dpad(right, false);

      else if (ev.isAxisMotion(_map.xAxis)) joystickX(ev.joystick.pos);
      else if (ev.isAxisMotion(_map.yAxis)) joystickY(ev.joystick.pos);

      else handled = false;
    }

    return handled;
  }

  override void updateControls(ControlScheme controls) {
    assert(_name in controls.axes, "unknown axis name " ~ _name);
    _map = controls.axes[_name];
  }

  private:
  void joystickY(float val) {
    _joystick.y = val;
    _action(_joystick);
  }

  void joystickX(float val) {
    _joystick.x = val;
    _action(_joystick);
  }

  void dpad(Direction direction, bool pressed) {
    // record the button state
    _dpad[direction] = pressed;

    // generate a joystick position from the current button states
    Vector2f pos;

    if (_dpad[Direction.up])    pos.y -= 1;
    if (_dpad[Direction.down])  pos.y += 1;
    if (_dpad[Direction.left])  pos.x -= 1;
    if (_dpad[Direction.right]) pos.x += 1;

    // trigger the registered action
    _action(pos);
  }
}

class AxisTapHandler : EventHandler {
  private enum Direction : ubyte { up, down, left, right };

  private {
    AxisMap    _map;
    AxisAction _action;
    string     _name;

    Vector2f _joystick = Vector2f.zero;

    bool  _tap;       // whether the axis is in a 'tapped' position
    float _innerBand = 0.3f; // point to cross to release a tap
    float _outerBand = 0.6f; // point to cross to trigger a tap
  }

  this(AxisAction action,
      ControlScheme controls,
      string name,
      ConsumeEvent consume)
  {
    super(consume);

    _action = action;
    _name   = name;

    updateControls(controls);
  }

  override bool handle(in ALLEGRO_EVENT ev) {
    bool handled = true;

    with (Direction) {
      if      (ev.isKeyPress  (_map.downKey)) dpad(down, true);
      else if (ev.isKeyRelease(_map.downKey)) dpad(down, false);

      else if (ev.isKeyPress  (_map.upKey)) dpad(up, true);
      else if (ev.isKeyRelease(_map.upKey)) dpad(up, false);

      else if (ev.isKeyPress  (_map.leftKey)) dpad(left, true);
      else if (ev.isKeyRelease(_map.leftKey)) dpad(left, false);

      else if (ev.isKeyPress  (_map.rightKey)) dpad(right, true);
      else if (ev.isKeyRelease(_map.rightKey)) dpad(right, false);

      else if (ev.isAxisMotion(_map.xAxis))
        joystick(ev.joystick.pos, _joystick.y);
      else if (ev.isAxisMotion(_map.yAxis))
        joystick(_joystick.x, ev.joystick.pos);

      else handled = false;
    }

    return handled;
  }

  override void updateControls(ControlScheme controls) {
    assert(_name in controls.axes, "unknown axis name " ~ _name);
    _map = controls.axes[_name];
  }

  private:
  void joystick(float x, float y) {
    _joystick = Vector2f(x, y);

    if (_tap && _joystick.len < _innerBand) {
      // moved from a 'tapped' position to a 'neutral' position
      _tap = false;
    }
    else if (!_tap && _joystick.len > _outerBand) {
      // moved from a 'neutral' position to a 'tapped' position
      _tap = true;
      _action(_joystick);
    }
  }

  void dpad(Direction direction, bool pressed) {
    if (pressed) {
      final switch (direction) with (Direction) {
        case up:    _action(Vector2f( 0, -1)); break;
        case down:  _action(Vector2f( 0,  1)); break;
        case left:  _action(Vector2f(-1,  0)); break;
        case right: _action(Vector2f( 1,  0)); break;
      }
      _tap = true;
    }
    else
      _tap = false;
  }
}

class AnyKeyHandler : EventHandler {
  enum Type { press, release }

  private {
    KeyAction _action;
    Type      _type;
  }

  this(KeyAction action, Type type, ConsumeEvent consume) {
    super(consume);

    _action  = action;
    _type    = type;
  }

  override bool handle(in ALLEGRO_EVENT ev) {
    if (_type == Type.press && ev.type == ALLEGRO_EVENT_KEY_DOWN) {
      _action(ev.keyboard.keycode.to!KeyCode);
      return true;
    }
    else if (_type == Type.release && ev.type == ALLEGRO_EVENT_KEY_UP) {
      _action(ev.keyboard.keycode.to!KeyCode);
      return true;
    }

    return false;
  }
}

class AnyButtonHandler : EventHandler {
  enum Type { press, release }

  private {
    ButtonAction _action;
    Type         _type;
  }

  this(ButtonAction action, Type type, ConsumeEvent consume) {
    super(consume);

    _action  = action;
    _type    = type;
  }

  override bool handle(in ALLEGRO_EVENT ev) {
    if (_type == Type.release && ev.type == ALLEGRO_EVENT_JOYSTICK_BUTTON_UP ||
        _type == Type.press   && ev.type == ALLEGRO_EVENT_JOYSTICK_BUTTON_DOWN)
    {
      _action(ev.joystick.button);
      return true;
    }

    return false;
  }
}

class AnyAxisHandler : EventHandler {
  private {
    AnyAxisAction _action;
    string        _name;
  }

  this(AnyAxisAction action, ConsumeEvent consume) {
    super(consume);
    _action = action;
  }

  override bool handle(in ALLEGRO_EVENT ev) {
    if (ev.type == ALLEGRO_EVENT_JOYSTICK_AXIS) {
      _action(ev.joystick.stick, ev.joystick.axis, ev.joystick.pos);
    }

    return false;
  }
}

private:
bool isKeyPress(in ALLEGRO_EVENT ev, int keycode) {
  return ev.type == ALLEGRO_EVENT_KEY_DOWN &&
    ev.keyboard.keycode == keycode;
}

bool isKeyRelease(in ALLEGRO_EVENT ev, int keycode) {
  return ev.type == ALLEGRO_EVENT_KEY_UP &&
    ev.keyboard.keycode == keycode;
}

bool isButtonPress(in ALLEGRO_EVENT ev, int button) {
  return ev.type == ALLEGRO_EVENT_JOYSTICK_BUTTON_DOWN &&
    ev.joystick.button == button;
}

bool isButtonRelease(in ALLEGRO_EVENT ev, int button) {
  return ev.type == ALLEGRO_EVENT_JOYSTICK_BUTTON_UP &&
    ev.joystick.button == button;
}

bool isAxisMotion(in ALLEGRO_EVENT ev, AxisMap.SubAxis map) {
  return (ev.type == ALLEGRO_EVENT_JOYSTICK_AXIS &&
      ev.joystick.stick == map.stick &&
      ev.joystick.axis == map.axis);
}

unittest {
  int runTest() {
    al_init();

    ALLEGRO_EVENT event_in, event_out;
    ALLEGRO_EVENT_SOURCE source;

    auto queue = al_create_event_queue();

    al_init_user_event_source(&source);
    al_register_event_source(queue, &source);

    event_in.any.type         = ALLEGRO_EVENT_KEY_DOWN;
    event_in.keyboard.keycode = ALLEGRO_KEY_ENTER;

    al_emit_user_event(&source, &event_in, null);

    al_wait_for_event(queue, &event_out);

    assert(event_out.type == ALLEGRO_EVENT_KEY_DOWN);
    assert(event_out.keyboard.keycode == ALLEGRO_KEY_ENTER);

    al_destroy_event_queue(queue);
    return 0;
  }

  int res = al_run_allegro(&runTest);
  assert(res == 0);
}

// test button handling
unittest {
  import engine.events.keycodes;

  class FakeHandler : ButtonHandler {
    bool handled;

    // handle the event, then return and reset the handled flag
    bool check(in ALLEGRO_EVENT ev) {
      auto res = super.handle(ev);
      assert(res == handled);
      handled = false;
      return res;
    }

    this(Type type, ControlScheme controls, string name) {
      super({ handled = true; }, type, controls, name, ConsumeEvent.no);
    }
  }

  ButtonMap confirmMap, cancelMap;

  confirmMap.keys    = [ KeyCode.enter, KeyCode.j ];
  confirmMap.buttons = [ 0, 2 ];

  cancelMap.keys    = [ KeyCode.escape, KeyCode.k ];
  cancelMap.buttons = [ 1 ];

  ControlScheme controls;
  controls.buttons["confirm"] = confirmMap;
  controls.buttons["cancel"]  = cancelMap;

  auto confirmHandler = new FakeHandler(ButtonHandler.Type.press  , controls, "confirm");
  auto cancelHandler  = new FakeHandler(ButtonHandler.Type.release, controls, "cancel");

  auto buttonDown(int button) {
    ALLEGRO_EVENT ev;
    ev.any.type = ALLEGRO_EVENT_JOYSTICK_BUTTON_DOWN;
    ev.joystick.button = button;

    return ev;
  }

  auto buttonUp(int button) {
    ALLEGRO_EVENT ev;
    ev.any.type = ALLEGRO_EVENT_JOYSTICK_BUTTON_UP;
    ev.joystick.button = button;

    return ev;
  }

  auto keyDown(int key) {
    ALLEGRO_EVENT ev;
    ev.any.type = ALLEGRO_EVENT_KEY_DOWN;
    ev.keyboard.keycode = key;
    return ev;
  }

  auto keyUp(int key) {
    ALLEGRO_EVENT ev;
    ev.any.type = ALLEGRO_EVENT_KEY_UP;
    ev.keyboard.keycode = key;
    return ev;
  }

  // confirm handler should respond to:
  // - button presses, not releases
  //   - joystick buttons 0 and 2
  //   - keys enter and j
  assert( confirmHandler.check(buttonDown(0)));
  assert( confirmHandler.check(buttonDown(2)));
  assert(!confirmHandler.check(buttonDown(1)));
  assert(!confirmHandler.check(buttonUp  (0)));
  assert(!confirmHandler.check(buttonUp  (2)));

  assert( confirmHandler.check(keyDown(ALLEGRO_KEY_ENTER)));
  assert( confirmHandler.check(keyDown(ALLEGRO_KEY_J)));
  assert(!confirmHandler.check(keyDown(ALLEGRO_KEY_ESCAPE)));
  assert(!confirmHandler.check(keyUp  (ALLEGRO_KEY_ENTER)));
  assert(!confirmHandler.check(keyUp  (ALLEGRO_KEY_ESCAPE)));

  // confirm handler should respond to:
  // - button releases, not presses
  //   - joystick button 1
  //   - keys escape and k
  assert(!cancelHandler.check(buttonDown(1)));
  assert(!cancelHandler.check(buttonDown(0)));
  assert( cancelHandler.check(buttonUp  (1)));
  assert(!cancelHandler.check(buttonUp  (0)));

  assert(!cancelHandler.check(keyDown(ALLEGRO_KEY_ESCAPE)));
  assert(!cancelHandler.check(keyDown(ALLEGRO_KEY_K)));
  assert(!cancelHandler.check(keyDown(ALLEGRO_KEY_ENTER)));
  assert(!cancelHandler.check(keyUp  (ALLEGRO_KEY_ENTER)));
  assert( cancelHandler.check(keyUp  (ALLEGRO_KEY_ESCAPE)));
}

// test axis handling
unittest {
  import engine.events.keycodes;

  enum {
    xAxis     = 0,
    yAxis     = 1,
    goodStick = 1,
    badStick  = 0,
    badAxis   = 2,
  }

  AxisMap axis;

  axis.upKey    = KeyCode.w;
  axis.downKey  = KeyCode.s;
  axis.leftKey  = KeyCode.a;
  axis.rightKey = KeyCode.d;

  axis.xAxis.stick = 1;
  axis.xAxis.axis  = 0;

  axis.yAxis.stick = 1;
  axis.yAxis.axis  = 1;

  ControlScheme controls;

  controls.axes["move"] = axis;

  Vector2f axisPos = Vector2f.zero;

  bool check(Vector2f expected) {
    bool ok = axisPos.approxEqual(expected);
    axisPos = Vector2f.zero;
    return ok;
  }

  auto moveHandler = new AxisHandler((pos) { axisPos = pos; },
      controls,
      "move",
      ConsumeEvent.no);

  auto keyDown(int key) {
    ALLEGRO_EVENT ev;
    ev.any.type = ALLEGRO_EVENT_KEY_DOWN;
    ev.keyboard.keycode = key;
    return ev;
  }

  auto keyUp(int key) {
    ALLEGRO_EVENT ev;
    ev.any.type = ALLEGRO_EVENT_KEY_UP;
    ev.keyboard.keycode = key;
    return ev;
  }

  auto moveAxis(int stick, int axis, float pos) {
    ALLEGRO_EVENT ev;
    ev.any.type       = ALLEGRO_EVENT_JOYSTICK_AXIS;
    ev.joystick.stick = stick;
    ev.joystick.axis  = axis;
    ev.joystick.pos   = pos;
    return ev;
  }

  // up
  assert(moveHandler.handle(keyDown(ALLEGRO_KEY_W)));
  assert(check(Vector2f(0, -1)));

  // up+right
  assert(moveHandler.handle(keyDown(ALLEGRO_KEY_D)));
  assert(check(Vector2f(1, -1)));

  // up+right+down (down+up should cancel)
  assert(moveHandler.handle(keyDown(ALLEGRO_KEY_S)));
  assert(check(Vector2f(1, 0)));

  // down+right (released up)
  assert(moveHandler.handle(keyUp(ALLEGRO_KEY_W)));
  assert(check(Vector2f(1, 1)));

  // down (released right)
  assert(moveHandler.handle(keyUp(ALLEGRO_KEY_D)));
  assert(check(Vector2f(0, 1)));

  // everything released
  assert(moveHandler.handle(keyUp(ALLEGRO_KEY_S)));
  assert(check(Vector2f.zero));

  // move the joystick x axis
  assert(moveHandler.handle(moveAxis(goodStick, xAxis, 0.5f)));
  assert(check(Vector2f(0.5f, 0)));

  // move the joystick y axis
  assert(moveHandler.handle(moveAxis(goodStick, yAxis, 0.7f)));
  assert(check(Vector2f(0.5f, 0.7f)));

  // move the joystick x axis in the other direction
  assert(moveHandler.handle(moveAxis(goodStick, xAxis, -0.2f)));
  assert(check(Vector2f(-0.2f, 0.7f)));

  // move a different axis on the same stick (should have no effect)
  assert(!moveHandler.handle(moveAxis(goodStick, badAxis, -0.9f)));
  assert(check(Vector2f.zero));

  // move a different stick (should have no effect)
  assert(!moveHandler.handle(moveAxis(badStick, xAxis, -0.9f)));
  assert(check(Vector2f.zero));

  // move the joystick y axis to zero
  assert(moveHandler.handle(moveAxis(goodStick, yAxis, 0.0f)));
  assert(check(Vector2f(-0.2f, 0.0f)));

  // move the joystick x axis to zero
  assert(moveHandler.handle(moveAxis(goodStick, xAxis, 0.0f)));
  assert(check(Vector2f(-0.0f, 0.0f)));
}
