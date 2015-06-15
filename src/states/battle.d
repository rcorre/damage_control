module states.battle;

import dau;
import dtiled;
import tilemap;
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
  Game game;
  StateStack!Battle states;

  private {
    Bitmap _tileAtlas;
  }

  override {
    void start(Game game) {
      this.game = game;
      this.map = buildMap(MapData.load("./content/map/map1.json"));
      this.states = new StateStack!Battle(this);
      _tileAtlas = game.content.bitmaps.get("tileset");
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
