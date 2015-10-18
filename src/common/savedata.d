module savedata;

import std.file;
import std.path;

import jsonizer;

struct SaveData {
  mixin JsonizeMe;

  private string _path;

  static auto create(string path) {
    auto data = SaveData();
    data._path = path;
    return data;
  }

  static auto load(string path) {
    auto data = path.readJSON!SaveData;
    data._path = path;
    return data;
  }

  void save() {
    auto dir = _path.dirName;
    if (!dir.exists) dir.mkdirRecurse();
    _path.writeJSON(this);
  }

  @jsonize:
  int[][] scores; // scores[worldNum][stageNum] = score
}

unittest {
  import std.uuid;

  auto path = buildPath(tempDir, "damage_control_test", randomUUID().toString, "save.json");

  // create a new save file and populate some scores
  auto data = SaveData.create(path);
  data.scores = [
    [ 1000, 2000, 0 ],
    [ 1200,    0, 0 ],
    [    0,    0, 0 ],
  ];

  // save and try loading it
  data.save();
  auto data2 = SaveData.load(path);
  assert(data.scores[0][0] == 1000);
  assert(data.scores[0][1] == 2000);
  assert(data.scores[0][2] ==    0);
  assert(data.scores[1][0] == 1200);

  // set a new value and save over the old file
  data.scores[1][1] = 1600;
  data.save();

  // check that the new values were saved
  auto data3 = SaveData.load(path);
  assert(data.scores[0][0] == 1000);
  assert(data.scores[0][1] == 2000);
  assert(data.scores[0][2] ==    0);
  assert(data.scores[1][0] == 1200);
  assert(data.scores[1][1] == 1600);
}
