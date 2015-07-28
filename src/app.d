import dau;
import title.title;

int main(char[][] args) {
  Game.Settings settings;

  // general settings
  settings.fps = 60;

  // display settings
  settings.display.windowSize = [800, 600];
  settings.display.canvasSize = [800, 600];
  settings.display.color = Color.black;

  return Game.run(new Title(), settings);
}
