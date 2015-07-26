module states.battle;

import std.array     : array;
import std.string    : startsWith;
import std.container : Array;
import dau;
import dtiled;
import tilemap;
import player;
import cursor;
import states.choose_base;
import states.start_round;
import states.battle_transition;

private enum {
  cannonBaseRow   = 6,
  cannonBaseCol   = 0,
  cannonBarrelRow = 8,
  cannonBarrelCol = 0,
  cannonSize      = 32, // width and height of cannon sprite in pixels

  enemySpriteRow = 6,
  enemySpriteCol = 4,
  enemySize      = 32,
  enemyDepth = 3,

  animationTime = 0.06,            // seconds per frame of tilesheet animation
  tilesetSize   = Vector2i(128, 0), // size of the tileset image for one frame of animation
}

/// Start a new match.
class Battle : State!Game {
  TileMap map;
  BattleData data;
  Game game;
  StateStack!Battle states;
  Player player;
  Vector2f cannonTarget = Vector2f.zero;

  private {
    Bitmap       _tileAtlas;
    float        _animationTimer;
    int          _numAnimationFrames;
    int          _animationCounter;
    Cursor       _cursor;
  }

  @property auto animationOffset() {
    return tilesetSize * _animationCounter;
  }

  @property auto cursor() { return _cursor; }

  override {
    void enter(Game game) {
      this.game = game;
      auto mapData = MapData.load("./content/map/map1.json");
      this.map = buildMap(mapData);
      this.data = BattleData(mapData);
      _tileAtlas = game.bitmaps.get("tileset");
      player = new Player(Color(0, 0, 0.8));

      states.push(new BattleTransition("Choose Base"),
                  new ChooseBase,
                  new StartRound);

      _numAnimationFrames = _tileAtlas.width / tilesetSize.x;
      _animationTimer = animationTime;
      _cursor = new Cursor(this);
    }

    void exit(Game game) {
    }

    void run(Game game) {
      states.run(this);
      map.draw(_tileAtlas, this, animationOffset, cannonTarget);

      // animation
      _animationTimer -= game.deltaTime;
      if (_animationTimer < 0) {
        _animationTimer = animationTime;
        _animationCounter = (_animationCounter + 1) % _numAnimationFrames;
      }

      cursor.draw(game.renderer);
    }
  }

  void drawCannon(RowCol coord, float angle, int depth) {
    auto batch = SpriteBatch(_tileAtlas, depth);
    Sprite sprite;

    sprite.color     = Color.white;
    sprite.centered  = true;

    // draw the base
    sprite.transform = map.tileOffset(coord.south.east).as!Vector2f;

    sprite.region = Rect2i(
        cannonBaseCol * map.tileWidth + animationOffset.x,
        cannonBaseRow * map.tileHeight + animationOffset.y,
        cannonSize,
        cannonSize);

    batch ~= sprite;

    // draw the barrel
    sprite.transform.angle = angle;

    sprite.region.x = cannonBarrelCol * map.tileWidth + animationOffset.x;
    sprite.region.y = cannonBarrelRow * map.tileHeight + animationOffset.y;

    batch ~= sprite;

    game.renderer.draw(batch);
  }

  void drawEnemies(R)(R r)
    if (isInputRange!R && is(ElementType!R == Transform!float))
  {
    auto batch = SpriteBatch(_tileAtlas, enemyDepth);

    foreach(transform ; r) {
      Sprite sprite;

      sprite.color     = Color.white;
      sprite.centered  = true;
      sprite.transform = transform;

      sprite.region = Rect2i(
          enemySpriteCol * map.tileWidth  + animationOffset.x,
          enemySpriteRow * map.tileHeight + animationOffset.y,
          enemySize,
          enemySize);

      batch ~= sprite;
    }

    game.renderer.draw(batch);
  }
}

protected:
abstract class BattleState : State!Battle {
  Array!EventHandler _handlers;

  override {
    void enter(Battle battle) {
      void handleKeyDown(in ALLEGRO_EVENT ev) {
        switch (ev.keyboard.keycode) {
          case ALLEGRO_KEY_J:
            onConfirm(battle);
            break;
          case ALLEGRO_KEY_K:
            onCancel(battle);
            break;
          case ALLEGRO_KEY_A:
            battle.cursor.startMoving(Cursor.Direction.west);
            onCursorMove(battle, Vector2i(-1,0));
            break;
          case ALLEGRO_KEY_D:
            battle.cursor.startMoving(Cursor.Direction.east);
            onCursorMove(battle, Vector2i(1,0));
            break;
          case ALLEGRO_KEY_W:
            battle.cursor.startMoving(Cursor.Direction.north);
            onCursorMove(battle, Vector2i(0,-1));
            break;
          case ALLEGRO_KEY_S:
            battle.cursor.startMoving(Cursor.Direction.south);
            onCursorMove(battle, Vector2i(0,1));
            break;
          case ALLEGRO_KEY_ESCAPE:
            battle.game.stop();
            break;
          default:
        }
      }

      void handleKeyUp(in ALLEGRO_EVENT ev) {
        switch (ev.keyboard.keycode) {
          case ALLEGRO_KEY_A:
            battle.cursor.stopMoving(Cursor.Direction.west);
            break;
          case ALLEGRO_KEY_D:
            battle.cursor.stopMoving(Cursor.Direction.east);
            break;
          case ALLEGRO_KEY_W:
            battle.cursor.stopMoving(Cursor.Direction.north);
            break;
          case ALLEGRO_KEY_S:
            battle.cursor.stopMoving(Cursor.Direction.south);
            break;
          default:
        }
      }

      void handleButtonDown(in ALLEGRO_EVENT ev) {
        onConfirm(battle);
      }

      void handleJoypadAxis(in ALLEGRO_EVENT ev) {
        // TODO: hardcoded to Buffalo SNES controller
        auto joy = ev.joystick;

        if (joy.pos == 0) {
          if (joy.axis == 0) {
            battle.cursor.stopMoving(Cursor.Direction.west);
            battle.cursor.stopMoving(Cursor.Direction.east);
          }
          else {
            battle.cursor.stopMoving(Cursor.Direction.north);
            battle.cursor.stopMoving(Cursor.Direction.south);
          }
        }
        else {
          with (Cursor.Direction) {
            auto direction =
              (joy.axis == 0) ?
              ((joy.pos > 0) ? east : west) :
              ((joy.pos > 0) ? south : north);

            battle.cursor.startMoving(direction);
          }
        }
      }

      _handlers.insert(battle.game.events.onKeyDown(&handleKeyDown));
      _handlers.insert(battle.game.events.onKeyUp(&handleKeyUp));
      _handlers.insert(battle.game.events.onButtonDown(&handleButtonDown));
      _handlers.insert(battle.game.events.onJoypadAxis(&handleJoypadAxis));
    }

    void exit(Battle battle) {
      foreach(handler ; _handlers) handler.unregister();
    }

    void run(Battle battle) { }
  }

  // action to take when cursor is moved in the given direction
  void onCursorMove(Battle battle, Vector2i direction) { }

  // action to take when the "confirm" button is pressed
  void onConfirm(Battle battle) { }

  // action to take when the "cancel" button is pressed
  void onCancel(Battle battle) { }

  // action to take when a "rotate" button is pressed
  void onRotate(Battle battle, bool clockwise) { }
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
        topLeft.span(topRight  + RowCol(1,0)),  // top row
        botLeft.span(botRight  + RowCol(1,0)),  // bottom row
        topLeft.span(botLeft   + RowCol(0,1)),  // left column
        topRight.span(botRight + RowCol(1,1))); // right column
  }
}
