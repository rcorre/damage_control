module engine.util.bicycle;

import std.range;

// TODO: support for bidirectional range?
/// cycle that can be shifted forward or backwards
struct Bicycle(R) if (isRandomAccessRange!R && hasLength!R) {
  this(R range) {
    _range = range;
    _len = _range.length;
  }

  @property auto front() {
    return _range[_idx];
  }

  auto advance(size_t steps = 1) {
    _idx = (_idx + steps + _len) % (_len); // add _len to keep idx positive
    return _range[_idx];
  }

  auto reverse(size_t steps = 1) {
    return advance(-steps);
  }

  private:
    R _range;
    size_t _idx;
    size_t _len;
}

auto bicycle(R)(R range) if (isRandomAccessRange!R && hasLength!R) {
  return Bicycle!R(range);
}

unittest {
  auto b = bicycle([1,2,3,4][]);
  assert(b.front == 1);

  assert(b.advance == 2);
  assert(b.advance == 3);
  assert(b.advance == 4);
  assert(b.advance == 1);
  assert(b.advance == 2);
  assert(b.advance == 3);
  assert(b.advance == 4);

  assert(b.reverse == 3);
  assert(b.reverse == 2);
  assert(b.reverse == 1);
  assert(b.reverse == 4);
  assert(b.reverse == 3);

  assert(b.reverse(2) == 1);
  assert(b.reverse(3) == 2);

  assert(b.advance(2) == 4);
  assert(b.advance(3) == 3);

  assert(b.advance(16) == 3);
}
