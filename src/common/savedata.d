module common.savedata;

import std.file;
import std.path;

import jsonizer;

struct SaveData {
  mixin JsonizeMe;

  private string _path;

  static auto load(string path) {
    // default save data
    SaveData data;

    // try to populate it if a save file is found
    if (path.exists)
      data = path.readJSON!SaveData;

    // set the path so it remembers where to save
    data._path = path;
    return data;
  }

  void save() {
    if (_path is null) return; // playing without saving

    auto dir = _path.dirName;
    if (!dir.exists) dir.mkdirRecurse();
    _path.writeJSON(this);
  }

  auto currentHighScore(int worldNum, int stageNum) {
    // stage/world num start at 1, normalize to 0-indexed
    return _scores[worldNum - 1][stageNum - 1];
  }

  /**
   * Record a new score for the given world and stage.
   * Returns: true if it is a new high score, else false.
   */
  bool recordScore(int worldNum, int stageNum, int score) {
    // make sure there is a slot allocated for this world-stage score
    if (worldNum > _scores.length)           _scores.length = worldNum;
    if (stageNum > _scores[worldNum].length) _scores[worldNum].length = stageNum;

    if (score > _scores[worldNum][stageNum]) {
      // stage/world num start at 1, normalize to 0-indexed
      _scores[worldNum - 1][stageNum - 1] = score;
      save();
      return true;
    }

    return false;
  }

  private:
  @jsonize("scores") int[][] _scores; // scores[worldNum][stageNum] = score
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
