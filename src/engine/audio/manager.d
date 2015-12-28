module engine.audio.manager;

import std.file   : dirEntries, SpanMode;
import std.path   : stripExtension;
import std.string : toStringz, chompPrefix;
import engine.allegro;
import engine.audio.sound;
import engine.audio.stream;
import engine.audio.common;

class AudioManager {
  // Mixer Organization:
  // soundMixer  -
  //               \
  //                 -> masterMixer -> voice
  //               /
  // streamMixer -

  AudioMixer masterMixer; // mixer connected directly to voice
  AudioMixer streamMixer; // mixer for music
  AudioMixer soundMixer;  // mixer for sound effects

  private {
    AudioSample[string] _samples;
    AudioVoice          _voice;       // the audio output device
  }

  this() {
    bool ok = al_install_audio();
    assert(ok, "failed to install audio module");

    ok = al_init_acodec_addon();
    assert(ok, "failed to init audio codec addon");

    // TODO: use game settings to configure these options
    _voice = al_create_voice(44100,
        ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_INT16,
        ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);

    masterMixer = al_create_mixer(44100,
        ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_FLOAT32,
        ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);

    streamMixer = al_create_mixer(44100,
        ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_FLOAT32,
        ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);

    soundMixer = al_create_mixer(44100,
        ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_FLOAT32,
        ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);

    assert(_voice,       "failed to create audio voice");
    assert(streamMixer, "failed to create audio stream mixer");
    assert(soundMixer,  "failed to create sound effect mixer");
    assert(masterMixer, "failed to create master audio mixer");

    ok = al_attach_mixer_to_mixer(soundMixer, masterMixer);
    assert(ok, "failed to attach sound mixer to voice");

    ok = al_attach_mixer_to_mixer(streamMixer, masterMixer);
    assert(ok, "failed to attach sound mixer to voice");

    ok = al_attach_mixer_to_voice(masterMixer, _voice);
    assert(ok, "failed to attach master audio mixer to voice");
  }

  ~this() {
    al_destroy_mixer(soundMixer);
    al_destroy_mixer(streamMixer);
    al_destroy_mixer(masterMixer);
    al_destroy_voice(_voice);
    unloadSamples();
  }

  void loadSamples(string dir, string glob = "*") {
    bool followSymlink = false;
    foreach(entry ; dir.dirEntries(glob, SpanMode.depth, followSymlink)) {
      auto path = entry.name;
      auto name = path    // the name consists of the path
        .chompPrefix(dir) // minus the directory prefix
        .chompPrefix("/") // minus the leading /
        .stripExtension;  // minus the extension

      auto sample = al_load_sample(path.toStringz);
      assert(sample, "failed to load " ~ path);

      _samples[name] = sample;
    }
  }

  void unloadSamples() {
    foreach(name, sample ; _samples) al_destroy_sample(sample);
    _samples = null;
  }

  auto getSound(string name) {
    assert(name in _samples, "no sample named " ~ name);
    return SoundEffect(_samples[name], soundMixer);
  }

  auto getSoundBank(string name, size_t sizeLimit = 10) {
    assert(name in _samples, "no sample named " ~ name);
    return SoundBank(_samples[name], soundMixer, sizeLimit);
  }

  auto playSound(string name) {
    auto sample = getSound(name);
    sample.play();
  }

  static void stopAllSamples() { al_stop_samples(); }

  auto loadStream(string path, size_t bufferCount = 4, uint samples = 1024) {
    import std.string : toStringz;
    auto stream = al_load_audio_stream(path.toStringz, 4, 1024);
    assert(stream, "failed to stream audio from " ~ path);
    al_attach_audio_stream_to_mixer(stream, streamMixer);
    return AudioStream(stream);
  }
}
