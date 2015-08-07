import dau;
import jsonizer;
import title.title;

int main(char[][] args) {
  Game.Settings settings;

  // general settings
  settings.fps = 60;

  // display settings
  settings.display.windowSize = [800, 600];
  settings.display.canvasSize = [800, 600];
  settings.display.color = Color.black;

  return Game.run(new InitializeGame(), settings);
}

class InitializeGame : State!Game {
  override {
    void enter(Game game) {
      // load control scheme
      game.events.controlScheme = "controls.json".readJSON!ControlScheme;
      game.states.replace(new Title(game));
    }

    void exit(Game game) { }
    void run(Game game) { }
  }
}
