/**
 * Provides a convenience wrapper around ALLEGRO_AUDIO_STREAM.
 */
module engine.audio.stream;

import engine.allegro;
import engine.audio.common;
import std.typecons : RefCounted, RefCountedAutoInitialize;

/**
 * A stream plays music from a file, and is well suited to playing music.
 *
 * This is essentially an ALLEGRO_AUDIO_STREAM* with two added benefits:
 *  - it is RefCounted, so manual disposal is not required
 *  - it provides properties to easily get/set stream values (e.g. gain)
 *
 *  You should generally not instantiate a stream directly.
 *  Instead, use `AudioManager.loadStream`, which will attach the loaded stream
 *  to the music mixer.
 */
alias AudioStream = RefCounted!(AudioStreamWrapper, RefCountedAutoInitialize.no);

private struct AudioStreamWrapper {
  private alias Mode = AudioPlayMode;

  ALLEGRO_AUDIO_STREAM* _stream;
  alias _stream this;

  ~this() { al_destroy_audio_stream(_stream); }

  @property {
    auto pan       () { return al_get_audio_stream_pan       (_stream); }
    auto gain      () { return al_get_audio_stream_gain      (_stream); }
    auto speed     () { return al_get_audio_stream_speed     (_stream); }
    auto length    () { return al_get_audio_stream_length    (_stream); }
    auto playing   () { return al_get_audio_stream_playing   (_stream); }
    auto playmode  () { return al_get_audio_stream_playmode  (_stream); }
    auto frequency () { return al_get_audio_stream_frequency (_stream); }

    void pan      (float val) { al_set_audio_stream_pan      (_stream, val); }
    void gain     (float val) { al_set_audio_stream_gain     (_stream, val); }
    void speed    (float val) { al_set_audio_stream_speed    (_stream, val); }
    void playing  (bool  val) { al_set_audio_stream_playing  (_stream, val); }
    void playmode (Mode  val) { al_set_audio_stream_playmode (_stream, val); }
  }
}
