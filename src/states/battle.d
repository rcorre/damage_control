module states.battle;

import dau;
import dtiled;
import tilemap;
import states.place_wall;

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
}
