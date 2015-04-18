import dau.engine;
import dau.setup;
import title.title;

int main(char[][] args) {
  GameSettings settings;
  settings.fps = 60;
  settings.screenWidth = 800;
  settings.screenHeight = 600;
  settings.numAudioSamples = 4;

  return runGame!Title(settings);
}
