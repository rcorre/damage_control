module states.battle;

import std.array     : array;
import std.string    : startsWith;
import std.algorithm : sort;
import dau;
import dtiled;
import tilemap;
import player;
import states.choose_base;
import states.place_wall;
import states.place_cannons;
import states.fight_ai;

private enum {
  cannonSpriteRow = 6,
  cannonSpriteCol = 0,
  cannonSize      = 32, // width and height of cannon sprite in pixels

  nodeSpriteRow = 6,
  nodeSpriteCol = 2,
  nodeSize      = 32,   // width and height of node sprite in pixels

  enemySpriteRow = 6,
  enemySpriteCol = 4,
  enemySize      = 32,

  animationTime = 0.06,            // seconds per frame of tilesheet animation
  tilesetSize   = Vector2i(96, 0), // size of the tileset image for one frame of animation

}

/// Start a new match.
class Battle : State!Game {
  TileMap map;
  BattleData data;
  Game game;
  StateStack!Battle states;
  Player player;

  private {
    Bitmap _tileAtlas;
    float _animationTimer;
    int _numAnimationFrames;
    int _animationCounter;
    int _currentRound; // the round to start on the next startNewRound()
  }

  @property auto animationOffset() {
    return tilesetSize * _animationCounter;
  }

  override {
    void start(Game game) {
      this.game = game;
      auto mapData = MapData.load("./content/map/map1.json");
      this.map = buildMap(mapData);
      this.data = BattleData(mapData);
      this.states = new StateStack!Battle(this);
      _tileAtlas = game.content.bitmaps.get("tileset");
      player = new Player(Color(0, 0, 0.8));
      states.push(new ChooseBase);
      _numAnimationFrames = _tileAtlas.width / tilesetSize.x;
      _animationTimer = animationTime;
    }

    void run(Game game) {
      if (game.input.keyPressed(ALLEGRO_KEY_ESCAPE)) {
        game.stop();
      }

      states.run();
      map.draw(_tileAtlas, game.renderer, animationOffset);

      // animation
      _animationTimer -= game.deltaTime;
      if (_animationTimer < 0) {
        _animationTimer = animationTime;
        _animationCounter = (_animationCounter + 1) % _numAnimationFrames;
      }
    }
  }

  void drawCannon(RowCol coord, int depth) {
    RenderInfo ri;

    ri.bmp       = _tileAtlas;
    ri.color     = Color.white;
    ri.depth     = depth;
    ri.transform = map.tileOffset(coord).as!Vector2f;

    ri.region = Rect2i(
        cannonSpriteCol * map.tileWidth + animationOffset.x,
        cannonSpriteRow * map.tileHeight + animationOffset.y,
        cannonSize,
        cannonSize);

    game.renderer.draw(ri);
  }

  void drawEnemy(Vector2f pos, int depth) {
    RenderInfo ri;

    ri.bmp       = _tileAtlas;
    ri.color     = Color.white;
    ri.depth     = depth;
    ri.transform = pos;

    ri.region = Rect2i(
        enemySpriteCol * map.tileWidth  + animationOffset.x,
        enemySpriteRow * map.tileHeight + animationOffset.y,
        enemySize,
        enemySize);

    game.renderer.draw(ri);
  }

  void startNewRound() {
    states.push(new PlaceCannons, new FightAI(_currentRound++), new PlaceWall);
  }
}

private:
struct BattleData {
  struct WallRegion {
    RowCol start, end;

    this(ObjectData obj, int tileWidth, int tileHeight) {
      this.start = RowCol(obj.y / tileHeight, obj.x / tileWidth);
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

  auto getWallCoordsForNode(RowCol coord) {
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
        topLeft.span(topRight  + RowCol(1,0)),  // top row
        botLeft.span(botRight  + RowCol(1,0)),  // bottom row
        topLeft.span(botLeft   + RowCol(0,1)),  // left column
        topRight.span(botRight + RowCol(1,1))); // right column
  }
}
