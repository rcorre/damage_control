module engine.util.content;

import std.format   : format;
import std.traits   : ReturnType, ParameterTypeTuple;
import std.typecons : Tuple;

/**
 * Loads, caches, and provides access to resources.
 *
 * Params:
 *  load = function to call when loading un-cached resources.
 */
struct ContentCache(alias load) {
  /**
   * The types that compose a key which uniquely identifies a resource.
   *
   * This could often just be a string that corresponds to some part of the
   * filename that a resource was loaded from.
   *
   * In some cases, a more complex key is useful;
   * For example, a Font might have a `string name` and an `int size`.
   */
  alias K = ParameterTypeTuple!load;

  /// The type of resource returned by the `load` function.
  alias V = ReturnType!load;

  // store of already loaded resources.
  private V[Tuple!K] _cache;

  /**
   * Try to retrieve a resource.
   * If this resource was already loaded, returns it from the cache.
   * Otherwise, it returns `loader(keys)` and caches the result.
   *
   * Params:
   *  keys = arguments to `loader`
   */
  V get(K keys) {
    auto key = Tuple!K(keys);

    auto obj = key in _cache;

    // already in cache
    if (obj !is null) return *obj;

    // not yet cached; load, cache, and return
    auto res = load(keys);
    _cache[key] = res;
    return res;
  }
}

/// Example with a single key:
unittest {
  struct FakeBitmap { string name; }

  // track how many times our loading function is called
  int calls = 0;
  auto loadFakeBitmap(string key) {
    ++calls;
    // if actually loading a bitmap, we would build a path here
    return FakeBitmap("bitmap_" ~ key);
  }

  // create a cache for our fake bitmaps
  ContentCache!loadFakeBitmap bitmaps;

  // load two new bitmaps
  auto foo = bitmaps.get("foo");
  auto bar = bitmaps.get("bar");

  assert(foo.name == "bitmap_foo");
  assert(bar.name == "bitmap_bar");
  assert(calls == 2);

  // try to load something that we already loaded
  auto foo2 = bitmaps.get("foo");

  assert(foo2 == foo);

  // the loader should not have been invoked, foo was cached
  assert(calls == 2);
}
