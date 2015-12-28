module engine.events.input;

import std.conv      : to;
import std.array     : array;
import std.traits    : EnumMembers;
import std.string    : toLower;
import std.algorithm : map;
import engine.allegro;
import engine.events.keycodes;
import jsonizer;

struct ControlScheme {
  mixin JsonizeMe;

  @jsonize {
    ButtonMap[string] buttons;
    AxisMap[string]   axes;
  }
}

struct ButtonMap {
  mixin JsonizeMe;

  @jsonize KeyCode[] keys;
  @jsonize int[] buttons;

  @jsonize
  this(string[] keys, int[] buttons) {
    this.buttons = buttons;
    this.keys = keys.map!(x => x.toLower.to!KeyCode).array;
  }
}

struct AxisMap {
  mixin JsonizeMe;

  struct SubAxis {
    mixin JsonizeMe;

    @jsonize {
      int stick;
      int axis;
    }
  }

  @jsonize {
    SubAxis xAxis;
    SubAxis yAxis;

    KeyCode upKey;
    KeyCode downKey;
    KeyCode leftKey;
    KeyCode rightKey;
  }
}

// test loading controls
unittest {
  import std.algorithm : equal;

  auto json = `
  {
    "buttons": {
      "confirm": {
        "keys": [ "j", "enter", "space" ],
          "buttons": [ 1, 2 ]
      },
        "cancel": {
          "keys": [ "k", "escape" ],
          "buttons": [ 3, 4 ]
        }
    },
      "axes": {
        "move": {
          "upKey"   : "w",
          "downKey" : "s",
          "leftKey" : "a",
          "rightKey": "d",
          "xAxis": { "stick": 1, "axis": 0 },
          "yAxis": { "stick": 2, "axis": 3 }
        }
      }
  }`;

  auto controls = json.fromJSONString!ControlScheme;

  assert(controls.buttons["confirm"].keys[].equal(
      [ ALLEGRO_KEY_J, ALLEGRO_KEY_ENTER, ALLEGRO_KEY_SPACE ]));

  assert(controls.buttons["confirm"].buttons[].equal([ 1, 2]));

  assert(controls.buttons["cancel"].keys[].equal(
      [ ALLEGRO_KEY_K, ALLEGRO_KEY_ESCAPE ]));

  assert(controls.buttons["cancel"].buttons[].equal([ 3, 4]));

  assert(controls.axes["move"].upKey    == ALLEGRO_KEY_W);
  assert(controls.axes["move"].downKey  == ALLEGRO_KEY_S);
  assert(controls.axes["move"].leftKey  == ALLEGRO_KEY_A);
  assert(controls.axes["move"].rightKey == ALLEGRO_KEY_D);

  assert(controls.axes["move"].xAxis.stick == 1);
  assert(controls.axes["move"].yAxis.stick == 2);
  assert(controls.axes["move"].xAxis.axis  == 0);
  assert(controls.axes["move"].yAxis.axis  == 3);
}

// test loading controls
unittest {
  import std.algorithm : equal;

  // setup and save
  ControlScheme saveMe;

  saveMe.buttons["confirm"] = ButtonMap();
  saveMe.buttons["cancel"]  = ButtonMap();

  saveMe.buttons["confirm"].keys    = [ KeyCode.j, KeyCode.enter ];
  saveMe.buttons["cancel"].keys     = [ KeyCode.k, KeyCode.escape ];
  saveMe.buttons["confirm"].buttons = [ 1, 2 ];

  saveMe.axes["move"] = AxisMap();

  saveMe.axes["move"].upKey    = KeyCode.w;
  saveMe.axes["move"].downKey  = KeyCode.s;
  saveMe.axes["move"].leftKey  = KeyCode.a;
  saveMe.axes["move"].rightKey = KeyCode.d;

  saveMe.axes["move"].xAxis.stick = 1;
  saveMe.axes["move"].yAxis.stick = 2;
  saveMe.axes["move"].xAxis.axis  = 0;
  saveMe.axes["move"].yAxis.axis  = 3;

  auto json = saveMe.toJSON;

  // load and verify
  auto loadMe = json.fromJSON!ControlScheme;

  assert(loadMe.buttons["confirm"].keys    == [ KeyCode.j, KeyCode.enter  ]);
  assert(loadMe.buttons["cancel"].keys     == [ KeyCode.k, KeyCode.escape ]);
  assert(loadMe.buttons["confirm"].buttons == [ 1, 2 ]);

  assert(loadMe.axes["move"].upKey    == KeyCode.w);
  assert(loadMe.axes["move"].downKey  == KeyCode.s);
  assert(loadMe.axes["move"].leftKey  == KeyCode.a);
  assert(loadMe.axes["move"].rightKey == KeyCode.d);

  assert(loadMe.axes["move"].xAxis.stick == 1);
  assert(loadMe.axes["move"].yAxis.stick == 2);
  assert(loadMe.axes["move"].xAxis.axis  == 0);
  assert(loadMe.axes["move"].yAxis.axis  == 3);
}
