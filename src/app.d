import dau;
import states.battle;

int main(char[][] args) {
  Game.Settings settings;

  // general settings
  settings.fps = 60;

  // display settings
  settings.display.windowSize = [800, 600];
  settings.display.canvasSize = [800, 600];
  settings.display.color = Color.black;

  // content settings
  settings.content.dir = "content";
  settings.content.bitmapDir = "image";
  settings.content.bitmapExt = ["png"];

  return Game.run(new Battle(), settings);
}
