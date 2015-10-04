import cid;
import jsonizer;
import constants;
import title.title;

int main(char[][] args) {
  Game.Settings settings;

  // general settings
  settings.fps = frameRate;

  // display settings
  settings.display.windowSize = [screenW, screenH];
  settings.display.canvasSize = [screenW, screenH];
  settings.display.color = Color.black;

  return Game.run(new InitializeGame(), settings);
}

class InitializeGame : State!Game {
  override {
    void enter(Game game) {
      // load control scheme
      game.events.controlScheme = "controls.json".readJSON!ControlScheme;

      // load content
      game.audio.loadSamples("./content/sound", "*.wav");

      // start on title state
      game.states.replace(new Title(game));

      // make sure user can close the window
      game.graphics.onClose = { game.stop(); };
    }

    void exit(Game game) { }
    void run(Game game) { }
  }
}
