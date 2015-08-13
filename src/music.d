module music;

import std.string    : format;
import std.algorithm : canFind;
import dau;

class MusicMixer {
  enum numStreams = 3;

  private {
    AudioStream[3] _streams;

  }

  this(AudioManager manager, int trackNum) {
    auto basePath = "./content/music/track%d".format(trackNum);

    foreach(i ; 0..numStreams) {
      _streams[i] = manager.loadStream("%s/stream%d.ogg".format(basePath, i));
      _streams[i].gain = 0; // don't enable any streams to start
      _streams[i].playMode = AudioPlayMode.loop;
    }
  }

  ~this() {
    foreach(stream ; _streams) stream.unload();
  }

  void setTracks(int[] nums ...) {
    foreach(i, stream ; _streams) {
      stream.gain = (nums.canFind(i)) ? 1 : 0;
    }
  }
}
