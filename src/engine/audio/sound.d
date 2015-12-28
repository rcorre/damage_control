module engine.audio.sound;

import std.random    : uniform;
import std.container : Array;
import std.typecons  : RefCounted, RefCountedAutoInitialize;
import std.algorithm : any, find;
import engine.allegro;
import engine.audio.common;
import engine.util.randomized;

alias SoundEffect = RefCounted!(SoundEffectPayload, RefCountedAutoInitialize.no);
alias SoundBank   = RefCounted!(SoundBankPayload  , RefCountedAutoInitialize.no);

private:
struct SoundEffectPayload {
  private AudioInstance _instance;

  this(AudioSample sample, AudioMixer mixer) {
    _instance = al_create_sample_instance(sample);
    al_attach_sample_instance_to_mixer(_instance, mixer);
  }

  ~this() { al_destroy_sample_instance(_instance); }

  void play() {
    bool ok = al_play_sample_instance(_instance);
    assert(ok, "Failed to play sample instance");
  }

  void stop() {
    bool ok = al_stop_sample_instance(_instance);
    assert(ok, "Failed to stop sample instance");
  }

  @property {
    bool playing () { return al_get_sample_instance_playing (_instance); }
    auto gain    () { return al_get_sample_instance_gain    (_instance); }
    auto pan     () { return al_get_sample_instance_pan     (_instance); }
    auto speed   () { return al_get_sample_instance_speed   (_instance); }

    void gain  (float val) { al_set_sample_instance_gain  (_instance, val); }
    void pan   (float val) { al_set_sample_instance_pan   (_instance, val); }
    void speed (float val) { al_set_sample_instance_speed (_instance, val); }
  }
}

struct SoundBankPayload {
  /// When playing a sound, the gain is randomly selected from this interval.
  Randomized!(float, "[]") gainFactor  = [1,1];

  /// When playing a sound, the pan is randomly selected from this interval.
  Randomized!(float, "[]") panFactor   = [0,0];

  /// When playing a sound, the speed is randomly selected from this interval.
  Randomized!(float, "[]") speedFactor = [1,1];

  private {
    Array!AudioInstance _instances;
    AudioSample         _sample;
    AudioMixer          _mixer;
    size_t              _limit;
  }

  this(AudioSample sample, AudioMixer mixer, size_t limit) {
    _sample = sample;
    _mixer  = mixer;
    _limit  = limit;
  }

  ~this() {
    foreach(instance ; _instances) al_destroy_sample_instance(instance);
  }

  /// True if any of the sample instances in this bank are playing.
  @property bool playing() { 
    return _instances[].any!(x => al_get_sample_instance_playing(x));
  }

  void play() {
    auto ready = _instances[].find!(x => !al_get_sample_instance_playing(x));

    if (!ready.empty) {
      // we found an instance to reuse
      auto instance = ready.front;

      // apply some variance
      al_set_sample_instance_gain  (instance, gainFactor.next);
      al_set_sample_instance_pan   (instance, panFactor.next);
      al_set_sample_instance_speed (instance, speedFactor.next);

      bool ok = al_play_sample_instance(ready.front);
      assert(ok, "Failed to play a sample instance from a sound bank");
    }
    else if (_instances.length < _limit) {
      // all instances are playing, but we have room for a new one
      auto newInstance = al_create_sample_instance(_sample);

      // stick it in the list and attach it to our sound mixer
      _instances.insert(newInstance);
      al_attach_sample_instance_to_mixer(newInstance, _mixer);

      // now play the new instance
      bool ok = al_play_sample_instance(newInstance);
      assert(ok, "Failed to play a sample instance from a sound bank");
    }
  }
}

/++ TODO: pre-create a sample that has 0-length audio?
auto nullAudio() {
  return new BlackHole!AudioSample();
}
++/
