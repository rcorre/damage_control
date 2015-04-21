import dau;
import states.start_match;

int main(char[][] args) {
  GameSettings settings;
  settings.fps = 60;
  settings.screenWidth = 800;
  settings.screenHeight = 600;
  settings.numAudioSamples = 4;
  settings.numAudioSamples = 4;
  settings.bgColor = Color.black;

  System[] systems;

  return runGame(new StartMatch(), settings, systems);
}
