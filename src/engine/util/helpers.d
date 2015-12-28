/**
  * A smattering of possibly useful helper functions
  *
  * Authors: <a href="https://github.com/rcorre">rcorre</a>
	* License: <a href="http://opensource.org/licenses/MIT">MIT</a>
	* Copyright: Copyright © 2015, rcorre
  */
module engine.util.helpers;

import std.traits;
import std.range;

/// return range.front, using val as a default if range is empty.
auto frontOr(R, T)(R range, T val) if (isInputRange!R && is(T : typeof(R.init.front))) {
  return range.empty ? val : range.front;
}

///
unittest {
  import std.algorithm;
  auto a = [1, 2, 3, 4, 5];
  assert(a.find!(x => x > 3).frontOr(0) == 4);
  assert(a.find!(x => x > 5).frontOr(0) == 0);
}

/// Returns a do-nothing "dummy" delegate with the same signature as T.
auto doNothing(T)() if (isDelegate!T) {
  static if (is(ReturnType!T == void)) {
    return delegate(ParameterTypeTuple!T) { };
  }
  else static if (is(ReturnType!T : typeof(null))) {
    return delegate(ParameterTypeTuple!T) { return null; };
  }
  else {
    return delegate(ParameterTypeTuple!T) { return ReturnType!T.init; };
  }
}

unittest {
  alias Action = void delegate();
  Action act = doNothing!Action;
  act();
}

unittest {
  alias Action = int delegate();
  Action act = doNothing!Action;
  assert(act() == 0);
}

unittest {
  alias Action = int delegate(float, string);
  Action act = doNothing!Action;
  assert(act(1.0f, "hi") == 0);
}

unittest {
  alias Action = string delegate();
  Action act = doNothing!Action;
  assert(act() is null);
}

string prettyString(E)(E val) if (is(E == enum)) {
  import std.conv   : to;
  import std.regex  : ctRegex, replaceAll;
  import std.string : toUpper;

  enum rx = ctRegex!("[A-Z]");
  auto str = val.to!(string).replaceAll(rx, " $&");
  return str[0].toUpper.to!string ~ str[1 .. $];
}

unittest {
  enum Foo {
    oneSingleFoo
  }

  assert(Foo.oneSingleFoo.prettyString == "One Single Foo");
}
