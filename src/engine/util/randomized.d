/**
 * Represent a value that should be randomized at each access.
 *
 * Examples:
 * Suppose you have a particle generator that spans a random number of particles
 * ---
 * Randomized!int numParticles = [200, 800];
 *
 * ---
 */
module engine.util.randomized;

import std.random : uniform;

/**
 * Represent a value that should be randomized at each access.
 * Params:
 * T = type of value to generate
 * bounds = whether to use an inclusive or exclusive bound on each end.
 */
struct Randomized(T : real, string bounds = "[)") {
  private T _min, _max;

  /// Get the next random value in the given range
  @property auto next() { return uniform!bounds(_min, _max); }

  /// Construct a Randomized!T that generates values between min and max.
  this(T min, T max) {
    _min = min;
    _max = max;
  }

  /**
   * Construct a Randomized!T from a min/max pair.
   *
   * Examles:
   * Randomized!float projectileSpeed = [200, 400];
   */
  this(T[2] span) {
    _min = span[0];
    _max = span[1];
  }

  /**
   * Construct a Randomized!T from a min/max pair.
   *
   * Examles:
   * Randomized!float projectileSpeed;
   * projectileSpeed = [200, 400];
   */
  void opAssign(T[2] span) {
    _min = span[0];
    _max = span[1];
  }
}
