module battle.battle;

import std.array     : array;
import std.string    : startsWith;
import std.container : Array;
import std.algorithm : sort, uniq;
import cid;
import dtiled;
import player;
import constants;
import battle.states.pause_menu;
import battle.states.choose_base;
import battle.states.start_round;
import battle.states.introduction;
import battle.entities.cursor;
import battle.entities.tilemap;

private enum {
  animationTime = 0.06,             // seconds per frame of tilesheet animation
  tilesetSize   = Vector2i(128, 0), // size of the tileset image for one frame of animation

  screenShakeDuration = 0.2f,
}

alias ShowTutorial = Flag!"ShowTutorial";

/// Start a new match.
class Battle : State!Game {
  TileMap            map;
  BattleData         data;
  Game               game;
  StateStack!Battle  states;
  Player             player;
  AudioStream        music;
  const ShowTutorial showTutorial;

  private {
    Bitmap _tileAtlas;
    float  _animationTimer;
    int    _numAnimationFrames;
    int    _animationCounter;
    Cursor _cursor;
    bool   _turboMode;
    float  _screenShakeIntensity = 0f;
  }

  this(ShowTutorial showTutorial) {
    this.showTutorial = showTutorial;
  }

  /// Construct from another battle -- used to restart a battle
  this(Battle other) {
    this.showTutorial = other.showTutorial;
  }

  @property auto animationOffset() {
    return tilesetSize * _animationCounter;
  }

  @property auto cursor() { return _cursor; }
  @property auto tileAtlas() { return _tileAtlas; }
  @property auto turboMode() { return _turboMode; }

  override {
    void enter(Game game) {
      this.game = game;
      auto mapData = MapData.load("./content/map/map1.json");
      this.map = new TileMap(mapData);
      this.data = BattleData(mapData);
      _tileAtlas = game.graphics.bitmaps.get("tileset");
      player = new Player(Color(0, 0, 0.8));

      states.push(new BattleIntroduction("Choose Base", game),
                  new ChooseBase(this),
                  new StartRound);

      _numAnimationFrames = _tileAtlas.width / tilesetSize.x;
      _animationTimer = animationTime;
      _cursor = new Cursor(this);
      music = game.audio.loadStream(MusicPath.battle);
      music.playmode = AudioPlayMode.loop;
    }

    void exit(Game game) {
      // exit all current states to clean up
      while(!states.empty) states.pop();

      // ensure that the battle music stops and the stream is freed
      music.destroy();
    }

    void run(Game game) {
      states.run(this);
      map.draw(_tileAtlas, game.graphics, animationOffset);

      // animation
      _animationTimer -= game.deltaTime;
      if (_animationTimer < 0) {
        _animationTimer = animationTime;
        _animationCounter = (_animationCounter + 1) % _numAnimationFrames;
      }

      _cursor.update(game.deltaTime, _turboMode);

      Transform!float trans = Vector2f(uniform(-1f, 1f), uniform(-1f, 1f))
        * _screenShakeIntensity;

      al_use_transform(trans.transform);
    }
  }

  void shakeScreen(float intensity) {
    _screenShakeIntensity = intensity;
    game.events.after(screenShakeDuration, { _screenShakeIntensity = 0; });
  }
}

protected:
abstract class BattleState : State!Battle {
  Array!EventHandler _handlers;

  override {
    void enter(Battle battle) {
      auto events = battle.game.events;

      _handlers.insert(events.onButtonDown("confirm", () => onConfirm(battle)));
      _handlers.insert(events.onButtonDown("cancel" , () => onCancel(battle)));
      _handlers.insert(events.onButtonDown("menu"   , () => onMenu(battle)));
      _handlers.insert(events.onButtonDown("turbo",
            { battle._turboMode = true; }));
      _handlers.insert(events.onButtonUp("turbo",
            { battle._turboMode = false; }));
      _handlers.insert(events.onButtonDown("rotateR",
            () => onRotate(battle, true)));
      _handlers.insert(events.onButtonDown("rotateL",
            () => onRotate(battle, false)));
      _handlers.insert(events.onAxisMoved("move",
            (pos) => onCursorMove(battle, pos)));
    }

    void exit(Battle battle) {
      foreach(handler ; _handlers) handler.unregister();
      _handlers.clear();
    }

    void run(Battle battle) { }
  }

  // action to take when cursor is moved in the given direction
  void onCursorMove(Battle battle, Vector2f direction) {
    battle.cursor.startMoving(cast(Vector2i) direction);
  }

  // action to take when the "confirm" button is pressed
  void onConfirm(Battle battle) { }

  // action to take when the "cancel" button is pressed
  void onCancel(Battle battle) {
    // TODO: easy exit for debugging. remove this later
    battle.game.stop();
  }

  // action to take when a "rotate" button is pressed
  void onRotate(Battle battle, bool clockwise) { }

  // action to take when the "menu" button is pressed
  void onMenu(Battle battle) {
    battle.states.push(new PauseMenu);
  }
}

private:
struct BattleData {
  struct WallRegion {
    RowCol start, end;

    this(ObjectData obj, int tileWidth, int tileHeight) {
      // the -1 is required because the rect drawn in tiled ends up just on the
      // inner edge of tiles it should encompass on the top-left side
      this.start = RowCol(obj.y / tileHeight - 1, obj.x / tileWidth - 1);
      this.end = RowCol((obj.y + obj.height) / tileHeight, (obj.x + obj.width) / tileWidth);
    }
  }

  private Vector2f[][] _enemyWaves;  // _enemyWaves[i] lists the enemy positions in wave #i
  private WallRegion[] _wallRegions; // walls that surround starting positions

  this(MapData data) {
    auto parseWave(LayerData layer) {
      return layer.objects
        .map!(obj => Vector2f(obj.x, obj.y))
        .array;
    }

    _enemyWaves ~= data
      .layers
      .filter!(x => x.name.startsWith("enemies"))
      .map!(wave => parseWave(wave))
      .array;

    _wallRegions = data.getLayer("walls")
      .objects
      .map!(obj => WallRegion(obj, data.tileWidth, data.tileHeight))
      .array;
  }

  auto getEnemyWave(int round) {
    return _enemyWaves[round];
  }

  /**
   * Each reactor is associated with a set of walls that will be granted if the
   * player chooses it as their starting location.
   * This method returns the coordinates of those walls.
   */
  auto getWallCoordsForReactor(RowCol coord) {
    auto region = _wallRegions
      .find!(region =>
          region.start.col <= coord.col &&
          region.start.row <= coord.row &&
          region.end.col   >= coord.col &&
          region.end.row   >= coord.row)
      .front;

    auto topLeft  = region.start;
    auto topRight = RowCol(region.start.row, region.end.col);
    auto botLeft  = RowCol(region.end.row  , region.start.col);
    auto botRight = region.end;

    return chain(
        span!"[]"(topLeft       , topRight),        // top row
        span!"[]"(botLeft       , botRight),        // bottom row
        span!"[]"(topLeft.south , botLeft.north),   // left column
        span!"[]"(topRight.south, botRight.north)); // right column
  }
}
