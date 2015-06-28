module states.battle;

import std.array     : array;
import std.string    : startsWith;
import std.algorithm : sort;
import dau;
import dtiled;
import tilemap;
import player;
import states.place_wall;

private enum {
  cannonSpriteRow = 6,
  cannonSpriteCol = 0,
  cannonSize      = 32, // width and height of cannon sprite in pixels

  nodeSpriteRow = 6,
  nodeSpriteCol = 2,
  nodeSize      = 32,   // width and height of node sprite in pixels
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
      states.push(new PlaceWall);
    }

    void run(Game game) {
      if (game.input.keyPressed(ALLEGRO_KEY_ESCAPE)) {
        game.stop();
      }

      states.run();
      map.draw(_tileAtlas, game.renderer);
    }
  }

  void drawCannon(RowCol coord, int depth) {
    RenderInfo ri;

    ri.bmp       = _tileAtlas;
    ri.color     = Color.white;
    ri.depth     = depth;
    ri.transform = map.tileOffset(coord).as!Vector2f;

    ri.region = Rect2i(
        cannonSpriteCol * map.tileWidth,
        cannonSpriteRow * map.tileHeight,
        cannonSize,
        cannonSize);

    game.renderer.draw(ri);
  }
}

private:
struct BattleData {
  private Vector2f[][] _enemyWaves;

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
  }

  auto getEnemyWave(int round) {
    return _enemyWaves[round];
  }
}
