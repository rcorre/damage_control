module engine.events.manager;

import std.range : chain, only;
import core.time;
import engine.allegro;
import engine.util.droplist;
import engine.events.input;
import engine.events.handlers;

class EventManager {
  private {
    alias HandlerList = DropList!(EventHandler, x => !x.active);

    ALLEGRO_EVENT_QUEUE* _queue;
    HandlerList          _handlers;
    ControlScheme        _controls;
  }

  this() {
    _handlers = new HandlerList();
    _queue = al_create_event_queue();

    al_register_event_source(_queue, al_get_keyboard_event_source());
    al_register_event_source(_queue, al_get_mouse_event_source());
    al_register_event_source(_queue, al_get_joystick_event_source());
  }

  ~this() {
    al_destroy_event_queue(_queue);
  }

  /**
   * Process events until the event queue is empty.
   */
  void process() {
    ALLEGRO_EVENT event;

    while (!al_is_event_queue_empty(_queue)) {
      al_wait_for_event(_queue, &event);

      foreach(handler ; _handlers) {
        bool handled = handler.handle(event);

        if (handled && handler.consume) break;
      }
    }
  }

  @property {
    auto controlScheme() { return _controls; }

    void controlScheme(ControlScheme controls) {
      _controls = controls;
      refreshHandlers(controls);
    }
  }

  auto after(double seconds, EventAction action) {
    enum repeat = false;
    auto handler = new TimerHandler(action, seconds, repeat, _queue);
    _handlers.insert(handler);
    return handler;
  }

  auto after(Duration dur, EventAction action) {
    return after(dur.total!"nsecs" / 1e9, action);
  }

  /**
   * Perform a series of timed actions.
   *
   * Entries are provided as (delay, action) pairs.
   * Delays are additive, meaning that if the first action's delay is given
   * as t1 and the second action's delay is given as t2, the second action
   * occurs at time (t1 + t2) from now.
   *
   * Params:
   * entries = a series of (delay, action) pairs
   *
   * Returns: a range of one TimerHandler for each (delay, action) pair
   *
   * Example:
   * -----
   * // the actions will be called at 2, 5, and 8 seconds from now, respectively
   * game.events.sequence(2, &openTheDoor,
   *                      3, &getOnTheFloor,
   *                      3, &walkTheDinosaur);
   *
   * // the above is equivalent to
   * game.events.after(2    , &openTheDoor);
   * game.events.after(2+3  , &getOnTheFloor);
   * game.events.after(2+3+3, &walkTheDinosaur);
   * -----
   */
  auto sequence(T ...)(T entries) if (is(T[0] : double ) &&
                                      is(T[1] : EventAction))
  {
    // pop off a (delay, action) pair and create a timer for it
    double seconds     = entries[0];
    EventAction action = entries[1];

    auto timer = after(seconds, action);

    static if (T.length > 2) {
      // there are more pairs left -- Add the current delay to the next.
      return chain(only(timer), sequence(entries[2] + seconds, entries[3..$]));
    }
    else {
      return only(timer);
    }
  }

  auto every(double seconds, EventAction action) {
    enum repeat = true;
    auto handler = new TimerHandler(action, seconds, repeat, _queue);
    _handlers.insert(handler);
    return handler;
  }

  auto every(Duration dur, EventAction action) {
    return every(dur.total!"nsecs" / 1e9, action);
  }

  auto onButtonDown(string name,
                    EventAction action,
                    ConsumeEvent consume = ConsumeEvent.no)
  {
    auto handler = new ButtonHandler(action, ButtonHandler.Type.press,
        _controls, name, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onButtonUp(string name,
                  EventAction action,
                  ConsumeEvent consume = ConsumeEvent.no)
  {
    auto handler = new ButtonHandler(action, ButtonHandler.Type.release,
        _controls, name, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onAnyKeyDown(KeyAction action, ConsumeEvent consume = ConsumeEvent.no) {
    auto handler = new AnyKeyHandler(action, AnyKeyHandler.Type.press, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onAnyKeyUp(KeyAction action, ConsumeEvent consume = ConsumeEvent.no) {
    auto handler = new AnyKeyHandler(action, AnyKeyHandler.Type.release, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onAnyButtonDown(ButtonAction action,
                       ConsumeEvent consume = ConsumeEvent.no)
  {
    auto handler =
      new AnyButtonHandler(action, AnyButtonHandler.Type.press, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onAnyButtonUp(ButtonAction action,
                     ConsumeEvent consume = ConsumeEvent.no)
  {
    auto handler =
      new AnyButtonHandler(action, AnyButtonHandler.Type.release, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onAxisMoved(string name,
                   AxisAction action,
                   ConsumeEvent consume = ConsumeEvent.no)
  {
    auto handler = new AxisHandler(action, _controls, name, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onAxisTapped(string name,
                   AxisAction action,
                   ConsumeEvent consume = ConsumeEvent.no)
  {
    auto handler = new AxisTapHandler(action, _controls, name, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onAnyAxis(AnyAxisAction action, ConsumeEvent consume = ConsumeEvent.yes) {
    auto handler = new AnyAxisHandler(action, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onEvent(ALLEGRO_EVENT_TYPE type,
               CustomAction action,
               ConsumeEvent consume = ConsumeEvent.no)
  {
    auto handler = new CustomHandler(action, type, consume);
    _handlers.insert(handler);
    return handler;
  }

  // update handlers to listen to new controls after a control scheme change
  private auto refreshHandlers(ControlScheme controls) {
    foreach(h ; _handlers) h.updateControls(controls);
  }
}
