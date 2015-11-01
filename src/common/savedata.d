module common.savedata;

import std.file;
import std.path;
import std.algorithm;

import jsonizer;

struct SaveData {
  mixin JsonizeMe;

  private {
    string _path;
    @jsonize("scores") int[][] _scores; // scores[worldNum][stageNum] = score
  }

  @jsonize float musicVolume = 1f;
  @jsonize float soundVolume = 1f;

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
    return getScore(worldNum, stageNum);
  }

  /**
   * Record a new score for the given world and stage.
   * Returns: true if it is a new high score, else false.
   */
  bool recordScore(int worldNum, int stageNum, int score) {
    if (score > getScore(worldNum, stageNum)) {
      getScore(worldNum, stageNum) = score;
      save();
      return true;
    }

    return false;
  }

  private:
  auto ref getScore(int worldNum, int stageNum) {
    // TODO: this is just a mess. maybe replace with unique world/stage names
    // especially important for supporting saves on custom maps.
    // stage/world num start at 1, normalize to 0-indexed
    int w = worldNum - 1;
    int s = stageNum - 1;

    // make sure there is a slot allocated for this world-stage score
    if (w >= _scores.length)    _scores.length    = w + 1;
    if (s >= _scores[w].length) _scores[w].length = s + 1;

    return _scores[w][s];
  }
}

unittest {
  import std.uuid;

  auto path = buildPath(tempDir, "damage_control_test", randomUUID().toString, "save.json");

  {
    // create a new save file and populate some scores
    auto data = SaveData(path);

    data.recordScore(1, 1, 1000);
    assert(data.currentHighScore(1, 1) == 1000);

    data.recordScore(2, 3, 2000);
    assert(data.currentHighScore(2, 3) == 2000);

    data.save();
  }

  {
    auto data = SaveData.load(path);

    assert(data.currentHighScore(1,1) == 1000);
    assert(data.currentHighScore(1,2) == 0);
    assert(data.currentHighScore(2,3) == 2000);

    // set a new value and save over the old file
    data.recordScore(1, 2, 1500);
    assert(data.currentHighScore(1, 2) == 1500);
    data.save();
  }

  {
    // check that the new values were saved
    auto data = SaveData.load(path);

    assert(data.currentHighScore(1,1) == 1000);
    assert(data.currentHighScore(1,2) == 1500);
    assert(data.currentHighScore(2,3) == 2000);
  }
}
