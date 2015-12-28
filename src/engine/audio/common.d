module engine.audio.common;

import engine.allegro;

alias AudioMixer    = ALLEGRO_MIXER*;
alias AudioVoice    = ALLEGRO_VOICE*;
alias AudioSample   = ALLEGRO_SAMPLE*;
alias AudioInstance = ALLEGRO_SAMPLE_INSTANCE*;

enum AudioPlayMode {
  once  = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE,
  loop  = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP,
  bidir = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_BIDIR
}

// mixer helpers
auto frequency(ALLEGRO_MIXER* mixer) {
  return al_get_mixer_frequency(mixer);
}

void frequency(ALLEGRO_MIXER* mixer, uint val) {
  checked!(() => al_set_mixer_frequency(mixer, val), "al_set_mixer_frequency failed");
}

auto quality(ALLEGRO_MIXER* mixer) {
  return al_get_mixer_quality(mixer);
}

void quality(ALLEGRO_MIXER* mixer, ALLEGRO_MIXER_QUALITY val) {
  checked!(() => al_set_mixer_quality(mixer, val), "al_set_mixer_quality failed");
}

auto gain(ALLEGRO_MIXER *mixer) {
  return al_get_mixer_gain(mixer);
}

void gain(ALLEGRO_MIXER *mixer, float val) {
  checked!(() => al_set_mixer_gain(mixer, val), "al_set_mixer_gain failed");
}

auto playing(ALLEGRO_MIXER* mixer) {
  return al_get_mixer_playing(mixer);
}

void playing(ALLEGRO_MIXER* mixer, bool val) {
  checked!(() => al_set_mixer_playing(mixer, val), "al_set_mixer_playing failed");
}

private void checked(alias expr, string msg)() {
  bool ok = expr();
  assert(ok, msg);
}
