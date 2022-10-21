// Dynamic Struct

import std;

class Dyns {
  struct Field {
    Dyns self;
    size_t i;
    auto ref val(T)() => *cast(T*)self.ptr(i);
    auto ref size() => self.sizes[i];
    auto toString() => self.ptr(i).to!string;
  }

  size_t[string] keys;
  size_t[] sizes;
  void* buf;

  this() {}
  this(void* p) { opAssign(p); }

  auto idx(string key) => keys[key];
  auto offset(size_t i) => i ? sizes[0..i].sum : 0;
  auto offset(string key) => offset(idx(key));
  auto ptr(T)(T key) => buf + offset(key);

  void register(string key, size_t size) {
    keys[key] = keys.length;
    sizes ~= size;
  }
  void register(T)(string key, size_t len=1) => register(key, T.sizeof * len);

  auto size() => sizes.sum;
  void alloc() { buf = new ubyte[size].ptr; }

  auto from(T)() if(is(T == struct)) {
    static foreach(field; [__traits(derivedMembers, T)])
      register(field, mixin(`T.`~field).sizeof);
  }

  auto opAssign(void* p) => buf = p;
  auto opDispatch(string key)() => Field(this, idx(key));
}

unittest {
  struct S {
    ubyte     buf1;
    ubyte[0]  buf2;
    ushort    buf3;
    ubyte[0]  buf4;
    size_t    buf5;
  }

  auto d = new Dyns;
  d.from!S;
  d.buf2.size = 1;
  d.buf4.size = 4;
  d.alloc;
  assert(d.size == 16);
}
