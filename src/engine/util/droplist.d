module engine.util.droplist;

import std.range;
import std.traits : isImplicitlyConvertible;
import std.algorithm;
import std.container;

/// list that automatically and efficiently removes entries for which cond(entry) is true
class DropList(T, alias cond) if (is(typeof(cond(T.init)) == bool)) {
  void insertFront(T val) {
    head = new Node(val, head);
    if (head.next !is null) {
      head.next.prev = head;
    }
  }

  void insertFront(Stuff)(Stuff stuff)
    if (isInputRange!Stuff && isImplicitlyConvertible!(ElementType!Stuff, T))
  {
    foreach(item ; stuff) {
      insert(item);
    }
  }

  alias insert = insertFront;

  bool empty() {
    // creating a slice will discard inactive elements,
    // so empty will return true if the list is populated but contains all inactive elements
    // NOTE: this means empty is not O(1)
    return this[].empty;
  }

  void clear() {
    head = null;
  }

  Range opSlice() {
    return Range(this, head);
  }

  @property static Range emptySlice() {
    return Range(null, null);
  }

  private:
  Node head;

  void removeNode(Node node) {
    assert(node !is null, "attempt to remove null node");
    if (node == head) { // first node
      head = node.next;
    }
    else {
      node.prev.next = node.next;
    }
  }

  class Node {
    T val;
    Node next, prev;

    this(T val, Node next) {
      this.val = val;
      this.next = next;
    }
  }

  static struct Range {
    private Node _node;
    private DropList _list;

    this(DropList list, Node node) {
      _list = list;
      _node = node;

      stripNodes();
    }

    @property {
      bool empty() { return _node is null; }
      ref T front() { return _node.val; }
    }

    void popFront() {
      _node = _node.next;
      stripNodes();
    }

    /// remove nodes for which cond is true starting from node
    void stripNodes() {
      while(_node !is null && cond(_node.val)) {
        auto next = _node.next;
        _list.removeNode(_node);
        _node = next;
      }
    }
  }
}

///
unittest {
  class Foo {
    this(int val, bool active) {
      this.val = val;
      this.active = active;
    }

    bool active;
    int val;
  }

  auto list = new DropList!(Foo, x => !x.active);

  list.insert(new Foo(1, false));
  list.insert(new Foo(2, true));
  list.insert(new Foo(3, true));
  list.insert(new Foo(4, false));
  list.insert(new Foo(5, false));

  int[] vals;

  foreach(el ; list) {
    vals ~= el.val;
    if (el.val == 2) { el.active = false; }
  }
  assert(vals == [3,2]);

  list.insert(new Foo(6, true));

  vals = [];
  foreach(el ; list) {
    vals ~= el.val;
    el.active = false;
  }
  assert(vals == [6, 3]);

  foreach(el ; list) { // should never be entered
    assert(0, "vals should be empty");
  }
}

///
unittest {
  import std.range : walkLength;
  assert(DropList!(int, x => x > 0).emptySlice.walkLength == 0);
}

/// range insertion
unittest {
  import std.range     : iota;
  import std.algorithm : equal;

  auto list = new DropList!(int, x => x > 5);
  list.insert(iota(0, 10));

  assert(list[].equal([5,4,3,2,1,0]));
}

// test range saving
unittest {
  import std.range : walkLength;

  auto list = new DropList!(int, x => x < 0);
  list.insert(1);
  list.insert(2);
  list.insert(3);

  auto slice = list[];
  assert(slice.walkLength == 3);
  assert(slice.walkLength == 3);
}

// ref access
unittest {
  import std.algorithm : equal;

  auto list = new DropList!(int, x => x <= 0);
  list.insert(1);
  list.insert(2);
  list.insert(3);

  foreach (ref i ; list) i -= 1;

  assert(list[].equal([2, 1]));
}

// empty property on container
unittest {
  auto list = new DropList!(int, x => x <= 0);
  assert(list.empty);

  list.insert(-1);
  assert(list.empty); // -1 is immediately discarded

  list.insert(-1);
  list.insert(-2);
  assert(list.empty); // both values are discarded

  list.insert(1);
  list.insert(-2);
  assert(!list.empty);
}
