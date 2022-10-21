// Dynamic Struct

import std;

class Dyns {
  struct Field {
    Dyns self;
    const size_t i;
    auto ptr() const => self.ptr(i);
    auto ref val(T)() => *cast(T*)ptr;
    auto ref size() => self.sizes[i];
    auto toString() const => self.ptr(i).to!string;
  }

  size_t[string] keys;
  size_t[] sizes;
  void* buf;

  this() {}
  this(const Dyns d) {
    keys = cast(size_t[string])d.keys; //
    sizes = d.sizes.dup;
  }
  this(void* p) { opAssign(p); }

  auto idx(string key) const => keys[key];
  auto offset(size_t i) const => i ? sizes[0..i].sum : 0;
  auto offset(string key) const => offset(idx(key));
  auto ptr(T)(T key) const => buf + offset(key);

  void register(string key, size_t size) {
    keys[key] = keys.length;
    sizes ~= size;
  }
  void register(T)(string key, size_t len=1) => register(key, T.sizeof * len);

  auto size() const => sizes.sum;
  void alloc() { buf = new ubyte[size].ptr; }

  auto opAssign(void* p) => buf = p;
  auto opDispatch(string key)() => Field(this, idx(key));

  static auto from(T)() if(is(T == struct)) {
    auto d = new Dyns;
    static foreach(field; [__traits(derivedMembers, T)])
      d.register(field, mixin(`T.`~field).sizeof);
    return d;
  }
}

unittest {
  struct S {
    ubyte     buf1;
    ubyte[0]  buf2;
    ushort    buf3;
    ubyte[0]  buf4;
    size_t    buf5;
  }
  const Sd = Dyns.from!S;

  auto d = new Dyns(Sd);
  d.buf2.size = 1;
  d.buf4.size = 4;
  d.alloc;
  assert(d.size == 16);

  d.buf5.val!size_t = 123;
  assert(d.buf5.val!size_t == 123);
}
