/**
  * Main entry point for starting a game.
  *
  * Authors: <a href="https://github.com/rcorre">rcorre</a>
	* License: <a href="http://opensource.org/licenses/MIT">MIT</a>
	* Copyright: Copyright © 2015, rcorre
  */
module engine.game;

import std.file   : exists;
import std.path   : buildNormalizedPath, setExtension;
import std.format : format;
import engine.allegro;
import engine.audio;
import engine.state;
import engine.events;
import engine.util.content;
import engine.graphics;

/// Main game class.
class Game {
  /// Settings used to configure the game.
  struct Settings {
    int fps;             /// Frames-per-second of update/draw loop
    int numAudioSamples; /// Number of audio samples that can play at once

    Display.Settings display; /// Game window and backbuffer configuration
  }

  @property {
    /// Stack of states that manages game flow.
    ref auto states() { return _stateStack; }
    /// Manage graphical resources like the display, bitmaps, and fonts.
    auto graphics() { return _graphics; }
    /// Access the event manager.
    auto events() { return _events; }
    /// Seconds elapsed between the current frame and the previous frame.
    auto deltaTime() { return _deltaTime; }
    /// The audio manager controls sound and music.
    auto audio() { return _audio; }
  }

  /**
   * Main entry point for starting a game. Loops until stop() is called on the game instance.
   *
   * Params:
   *  firstState = initial state that the game will begin in
   *  settings = configures the game
   */
  static int run(State!Game firstState, Settings settings) {
    int mainFn() {
      allegroInitAll();
      auto game = new Game(firstState, settings);

      game.run();

      return 0;
    }

    return al_run_allegro(&mainFn);
  }

  /// End the main game loop, causing Game.run to return.
  void stop() {
    _stopped = true;
  }

  private:
  StateStack!Game _stateStack;
  EventManager    _events;
  AudioManager    _audio;
  GraphicsManager _graphics;
  float           _deltaTime;
  bool            _stopped;
  bool            _update;

  // content
  this(State!Game firstState, Settings settings) {
    _events   = new EventManager;
    _audio    = new AudioManager;
    _graphics = new GraphicsManager(settings.display);

    _events.every(1.0 / settings.fps, { _update = true; });
    _stateStack.push(firstState);
  }

  void run() {
    while(!_stopped) {
      _events.process();
      _graphics.process();

      if (_update) {
        static float last_update_time = 0;

        float current_time = al_get_time();
        _deltaTime         = current_time - last_update_time;
        last_update_time   = current_time;

        _stateStack.run(this);

        graphics.display.clear();
        graphics.render();
        graphics.display.flip();

        _update = false;
      }
    }
  }
}
