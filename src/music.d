module music;

import std.string    : format;
import std.algorithm : canFind;
import dau;
import transition;

private enum {
  numStreams   = 3,
  fadeDuration = 3f
}

enum MusicLevel { none, basic, moderate, intense }

class MusicMixer {
  private {
    AudioStream[numStreams]      _streams;
    Transition!float[numStreams] _gains;
  }

  this(AudioManager manager, int trackNum) {
    auto basePath = "./content/music/track%d".format(trackNum);

    foreach(i ; 0..numStreams) {
      _streams[i] = manager.loadStream("%s/stream%d.ogg".format(basePath, i));
      _streams[i].gain = 0; // don't enable any streams to start
      _streams[i].playmode = AudioPlayMode.loop;
      _gains[i].initialize(0, fadeDuration);
    }
  }

  void update(float timeElapsed) {
    foreach(i ; 0..numStreams) {
      _gains[i].update(timeElapsed);
      _streams[i].gain = _gains[i].value;
    }
  }

  void enableTracksUpTo(MusicLevel maxLevel) {
    foreach(i ; MusicLevel.none .. maxLevel)   _gains[i].go(1);
    foreach(i ; maxLevel        .. numStreams) _gains[i].go(0);
  }
}
