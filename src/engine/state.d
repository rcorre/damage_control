/**
 * Generic state stack implementation.
 *
 *
 * Examples:
 * A `StateStack` is useful for managing top-level game logic:
 * ---
 * class SettingsScreen : State!MyGame {
 *   private MyGameSettings _settings;
 *
 *   override void enter(MyGame game) {
 *     _settings = game.loadSettings();
 *   }
 *
 *   override void exit(MyGame game) {
 *     game.saveSettings(_settings);
 *   }
 *
 *   override void run(MyGame game) {
 *     // process player input to move through menu and adjust settings
 *     // ...
 *
 *     // when the player exits the menu, just pop this state
 *     if (clickedExitButton) {
 *       game.states.pop();
 *       // exit() will be called to save the settings
 *     }
 *   }
 * }
 *
 * // inside your game class:
 * class MyGame {
 *   StateStack!MyGame states;
 *
 *   void update() {
 *     states.run(this);
 *     // ...
 *   }
 * }
 *
 * ---
 *
 * States can also be used to manage the logic of in-game entities.
 * In this case, it may be useful to pass some context along.
 * For this reason, states can take multiple arguments:
 *
 * ---
 * class FollowPlayer : State!(Bird, GameWorld) {
 *   override void enter(Bird bird, GameWorld world) { }
 *   override void exit (Bird bird, GameWorld world) { }
 *
 *   override void run(Bird bird, GameWorld world) {
 *     bird.moveTowards(world.player.pos, world.timeElapsed);
 *   }
 * }
 *
 * // inside your entity class:
 * class Bird {
 *   private StateStack!(Bird, GameWorld) _states;
 *
 *   void update(GameWorld world) {
 *     _states.run(this, world);
 *   }
 * }
 *
 * ---
 *
 */
module engine.state;

import std.container : SList;

/**
 * Generic behavioral state.
 */
interface State(T...) {
  /// Called before `run` if this was not the previously run state.
  void enter(T params);

  /// Called once whenever the state becomes 'inactive'.
  /// A state becomes inactive if the state is popped or a new state is pushed.
  /// `exit` is only called if `enter` was previously called.
  void exit(T params);

  /// Called continuously while this state is active.
  void run(T params);
}

/// Manages a LIFO stack of states which determine how an instance of `T` behaves.
struct StateStack(T...) {
  @property {
    /// The state at the top of the stack.
    auto top() { return _stack.front; }

    /// True if no states exist on the stack.
    bool empty() { return _stack.empty; }
  }

  /**
   * Place one or more new states on the state stack.
   *
   * When pushing multiple states, the states given last are placed on the bottom.
   * The following:
   * -----
   * states.push(new StateA, new StateB, new StateC);
   * -----
   * is equivalent to:
   * -----
   * states.push(new StateC);
   * states.push(new StateB);
   * states.push(new StateA);
   * -----
   */
  void push(State!T[] states ...) {
    if (_currentStateEntered) {
      top.exit(_params);
      _currentStateEntered = false;
    }

    foreach_reverse(state ; states) {
      _stack.insertFront(state);
    }
  }

  /// Remove the current state.
  void pop() {
    // get ref to current state, top may change during exit
    auto state = top;
    _stack.removeFront;
    if (_currentStateEntered) {
      _currentStateEntered = false;
      state.exit(_params);
    }
  }

  /// Pop the top state (if there is a top state) and push a new state.
  void replace(State!T state) {
    if (!_stack.empty) {
      pop();
    }
    push(state);
  }

  /**
   * Step the state stack forward.
   *
   * If the `top` state has not been activated, this will call `enter` on it.
   * If the `top` state's `enter` modifies the stack, `enter` will continue to be
   * called on each new `top` state until a state remains on the stack after
   * its `enter` call.
   * Once the stack has 'stabilized', `run` will be called on the new `top`.
   *
   * Such multi-enter scenarios occur with 'transient' states -- states that
   * perform something during `enter` and immediately pop themselves from the
   * stack.
   *
   *
   */
  void run(T params) {
    // cache obj for calls to exit() that are triggered by pop().
    _params = params;

    // top.enter() could push/pop, so keep going until the top state is entered
    while (!_currentStateEntered) {
      _currentStateEntered = true;
      top.enter(params);
    }

    top.run(params);
  }

  private:
  SList!(State!T) _stack;    // stack of states
  bool _currentStateEntered; // true if top state has been enter()ed
  T _params;                 // cache params passed to run() for use by pop()
}

version (unittest) {
  private {
    class Foo {
      string[] log;
      StateStack!Foo states;

      void check(string[] entries ...) {
        import std.format : format;
        assert(log == entries, "expected %s, got %s".format(entries, log));
        log = null;
      }
    }

    class LoggingState : State!Foo {
      override {
        void enter (Foo foo) { foo.log ~= name ~ ".enter"; }
        void exit  (Foo foo) { foo.log ~= name ~ ".exit";  }
        void run   (Foo foo) { foo.log ~= name ~ ".run";   }
      }

      @property string name() {
        import std.string : split;
        return this.classinfo.name.split(".")[$ - 1];
      }
    }

    class A : LoggingState { }

    class B : LoggingState { }

    // pushes states during enter/exit
    class D : LoggingState {
      override {
        void enter(Foo foo) { foo.states.push(new A); }
        void exit(Foo foo) { foo.states.push(new B); }
      }
    }

    // pops self during enter
    class E : LoggingState {
      override {
        void enter(Foo foo) { foo.states.push(new B); }
        void exit(Foo foo) { foo.states.push(new B); }
      }
    }
  }
}

// push, run, and pop single state
unittest {
  auto foo = new Foo;

  foo.states.push(new A);
  foo.check();

  foo.states.run(foo);
  foo.check("A.enter", "A.run");
  foo.states.run(foo);
  foo.check("A.run");

  foo.states.pop();
  foo.check("A.exit");
}

// push multiple states
unittest {
  auto foo = new Foo;

  foo.states.push(new A);
  foo.states.run(foo); // A
  foo.check("A.enter", "A.run");

  foo.states.push(new B);
  foo.check("A.exit");
  foo.states.run(foo); // A B
  foo.check("B.enter", "B.run");
}

// push state during enter
unittest {
  class C : LoggingState {
    override void enter(Foo foo) { super.enter(foo); foo.states.push(new A); }
  }

  auto foo = new Foo;

  foo.states.push(new C);
  foo.states.run(foo);
  foo.check("C.enter", "C.exit","A.enter", "A.run");
  foo.states.pop();
  foo.check("A.exit");
  foo.states.run(foo);
  foo.check("C.enter", "C.exit","A.enter", "A.run");
}

// push state during exit
unittest {
  class C : LoggingState {
    override void exit(Foo foo) { super.exit(foo); foo.states.push(new A); }
  }

  auto foo = new Foo;

  foo.states.push(new C);
  foo.states.run(foo);
  foo.check("C.enter", "C.run");
  foo.states.pop();
  foo.check("C.exit");
  foo.states.run(foo);
  foo.check("A.enter", "A.run");
}

// push state during run
unittest {
  class C : LoggingState {
    override void run(Foo foo) { super.run(foo); foo.states.push(new A); }
  }

  auto foo = new Foo;

  foo.states.push(new C);
  foo.states.run(foo);
  foo.check("C.enter", "C.run", "C.exit");
  foo.states.run(foo);
  foo.check("A.enter", "A.run");
}

// pop state during enter -- should skip run
unittest {
  class C : LoggingState {
    override void enter(Foo foo) { super.enter(foo); foo.states.pop(); }
  }

  auto foo = new Foo;

  foo.states.push(new A);
  foo.states.push(new C);
  foo.check();
  foo.states.run(foo);
  foo.check("C.enter", "C.exit","A.enter", "A.run");
}

// pop state during exit
unittest {
  class C : LoggingState {
    override void exit(Foo foo) { super.exit(foo); foo.states.pop(); }
  }

  auto foo = new Foo;

  foo.states.push(new A);
  foo.states.push(new B); // this will get popped when C exits
  foo.states.push(new C);
  foo.check();
  foo.states.run(foo);
  foo.check("C.enter", "C.run");
  foo.states.pop();
  foo.check("C.exit"); // C pops B while it is exiting
  foo.states.run(foo);
  foo.check("A.enter", "A.run"); // only A is left
}

// pop state during run
unittest {
  class C : LoggingState {
    override void run(Foo foo) { super.run(foo); foo.states.pop(); }
  }

  auto foo = new Foo;

  foo.states.push(new A);
  foo.states.push(new C);
  foo.check();
  foo.states.run(foo);
  foo.check("C.enter", "C.run", "C.exit");
  foo.states.run(foo);
  foo.check("A.enter", "A.run");
}

// varargs push
unittest {
  auto foo = new Foo;

  foo.states.push(new A, new B);
  foo.states.run(foo); // B A
  foo.check("A.enter", "A.run");
  foo.states.pop(); // B xAx
  foo.check("A.exit");
  foo.states.run(foo); // B
  foo.check("B.enter", "B.run");
}

// multi-param states
unittest {
  class Thing { int y = 5; }

  class World { int gravity = -1; }

  class Fall : State!(Thing, World) {
    override void enter(Thing thing, World world) { }
    override void exit (Thing thing, World world) { }
    override void run  (Thing thing, World world) {
      thing.y += world.gravity;
    }
  }

  World world = new World;
  Thing thing = new Thing;
  StateStack!(Thing, World) states;

  states.push(new Fall);

  states.run(thing, world);
  assert(thing.y == 4);

  states.run(thing, world);
  assert(thing.y == 3);
}
