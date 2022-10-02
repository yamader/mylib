bool has(T)(const ref T self, string name) {
  static foreach (s; [__traits(derivedMembers, T)])
    if (s == name)
      return true;
  return false;
}

void set(T, U)(ref T self, string name, const U val) {
  static foreach (s; [__traits(derivedMembers, T)])
    if (s == name) {
      import std.conv: to;

      auto field = &__traits(getMember, self, s);
      *field = val.to!(typeof(*field));
      return;
    }
  throw new Exception("no such member");
}

unittest {
  struct S {
    string s;
    int i;
  }

  S s;

  assert(s.has("i"));
  assert(!s.has("a"));

  s.set("s", "asdf");
  assert(s.s == "asdf");

  s.set("i", 1234);
  assert(s.i == 1234);
}

unittest {
  class C {
    char[] s;
    int i;
  }

  C c = new C;

  assert(c.has("i"));
  assert(!c.has("a"));

  c.set("s", "hjkl");
  assert(c.s == "hjkl");

  c.set("i", "4321");
  assert(c.i == 4321);
}
