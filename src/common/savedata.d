module common.savedata;

import std.file;
import std.path;
import std.algorithm;

import engine;
import jsonizer;

import constants;

struct GameOptions {
  mixin JsonizeMe;

  @jsonize(JsonizeOptional.yes) {
    float musicVolume = 1f;
    float soundVolume = 1f;
    int   screenShake = 1;
  }
}

struct ProgressData {
  mixin JsonizeMe;

  @jsonize("scores") private int[][] _scores; // scores[worldNum][stageNum] = score

  private auto ref getScore(int worldNum, int stageNum) {
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

class SaveData {
  private {
    enum   _defaultPath = "./data";
    string _saveDir;

    ControlScheme _controls;
    ProgressData  _progress;
    GameOptions   _options;
  }

  static auto load(string path) {
    // 'real' user save paths
    auto controlsPath = path.buildPath(SaveFile.controls);
    auto progressPath = path.buildPath(SaveFile.progress);
    auto optionsPath  = path.buildPath(SaveFile.options);

    // replace with default data if not available
    if (!controlsPath.exists) controlsPath = _defaultPath.buildPath(SaveFile.controls);
    if (!progressPath.exists) progressPath = _defaultPath.buildPath(SaveFile.progress);
    if (!optionsPath.exists ) optionsPath  = _defaultPath.buildPath(SaveFile.options);

    auto data = new SaveData;

    data._controls = controlsPath.readJSON!ControlScheme;
    data._progress = progressPath.readJSON!ProgressData;
    data._options  = optionsPath.readJSON!GameOptions;

    // set the path so it remembers where to save
    data._saveDir = path;
    return data;
  }

  void save() {
    if (_saveDir is null) return; // playing without saving

    if (!_saveDir.exists) _saveDir.mkdirRecurse();

    _saveDir.buildPath(SaveFile.controls).writeJSON(_controls);
    _saveDir.buildPath(SaveFile.progress).writeJSON(_progress);
    _saveDir.buildPath(SaveFile.options).writeJSON(_options);
  }

  @property ref auto musicVolume() { return _options.musicVolume; }
  @property ref auto soundVolume() { return _options.soundVolume; }
  @property ref auto screenShake() { return _options.screenShake; }
  @property ref auto controls() { return _controls; }

  auto currentHighScore(int worldNum, int stageNum) {
    return _progress.getScore(worldNum, stageNum);
  }

  /**
   * Record a new score for the given world and stage.
   * Returns: true if it is a new high score, else false.
   */
  bool recordScore(int worldNum, int stageNum, int score) {
    if (score > _progress.getScore(worldNum, stageNum)) {
      _progress.getScore(worldNum, stageNum) = score;
      return true;
    }

    return false;
  }
}

unittest {
  import std.uuid;

  auto path = buildPath(tempDir, "damage_control_test", randomUUID().toString);

  {
    // new user experience: creates a default save file
    auto data = SaveData.load(path);

    // check that default values were created
    assert(data.controls.buttons["confirm"].keys[0] == KeyCode.j);
    assert(data.controls.buttons["cancel"].keys[0]  == KeyCode.k);

    assert(data.controls.axes["move"].upKey       == KeyCode.w);
    assert(data.controls.axes["move"].downKey     == KeyCode.s);
    assert(data.controls.axes["move"].leftKey     == KeyCode.a);
    assert(data.controls.axes["move"].rightKey    == KeyCode.d);
    assert(data.controls.axes["move"].xAxis.stick == 0);
    assert(data.controls.axes["move"].xAxis.axis  == 0);
    assert(data.controls.axes["move"].yAxis.stick == 0);
    assert(data.controls.axes["move"].yAxis.axis  == 1);

    assert(data.currentHighScore(1,1) == 0);

    assert(data.musicVolume == 1f);
    assert(data.soundVolume == 1f);

    // record some new scores and save
    data.recordScore(1, 1, 1000);
    assert(data.currentHighScore(1, 1) == 1000);

    data.recordScore(2, 3, 2000);
    assert(data.currentHighScore(2, 3) == 2000);

    data.save();
  }

  {
    auto data = SaveData.load(path);

    // validate that controls were preserved
    assert(data.controls.buttons["confirm"].keys[0] == KeyCode.j);
    assert(data.controls.buttons["cancel"].keys[0]  == KeyCode.k);

    assert(data.controls.axes["move"].upKey       == KeyCode.w);
    assert(data.controls.axes["move"].downKey     == KeyCode.s);
    assert(data.controls.axes["move"].leftKey     == KeyCode.a);
    assert(data.controls.axes["move"].rightKey    == KeyCode.d);
    assert(data.controls.axes["move"].xAxis.stick == 0);
    assert(data.controls.axes["move"].xAxis.axis  == 0);
    assert(data.controls.axes["move"].yAxis.stick == 0);
    assert(data.controls.axes["move"].yAxis.axis  == 1);

    // validate the scores saved previously
    assert(data.currentHighScore(1,1) == 1000);
    assert(data.currentHighScore(1,2) == 0);
    assert(data.currentHighScore(2,3) == 2000);

    // set some new values and save over the old file
    data.recordScore(1, 2, 1500);
    assert(data.currentHighScore(1, 2) == 1500);

    data.musicVolume = 0.5f;
    data.controls.buttons["confirm"].keys[0] = KeyCode.q;
    data.controls.axes["move"].leftKey = KeyCode.left;
    data.save();
  }

  {
    // check that the new values were saved
    auto data = SaveData.load(path);

    // validate that controls were preserved
    assert(data.controls.buttons["confirm"].keys[0] == KeyCode.q);
    assert(data.controls.buttons["cancel"].keys[0]  == KeyCode.k);

    assert(data.controls.axes["move"].upKey       == KeyCode.w);
    assert(data.controls.axes["move"].downKey     == KeyCode.s);
    assert(data.controls.axes["move"].leftKey     == KeyCode.left);
    assert(data.controls.axes["move"].rightKey    == KeyCode.d);
    assert(data.controls.axes["move"].xAxis.stick == 0);
    assert(data.controls.axes["move"].xAxis.axis  == 0);
    assert(data.controls.axes["move"].yAxis.stick == 0);
    assert(data.controls.axes["move"].yAxis.axis  == 1);

    assert(data.currentHighScore(1,1) == 1000);
    assert(data.currentHighScore(1,2) == 1500);
    assert(data.currentHighScore(2,3) == 2000);

    assert(data.musicVolume == 0.5f);
  }
}
