// Dynamic Struct

import std;

class Dyns(T...) {
 private:
  static if(T.length <= 1) {
    // T is a struct
    alias Types = Fields!T;
    enum _dyns_members = [__traits(derivedMembers, T)];
  } else {
    // T are fields
    alias Types = Stride!(2, T);
    enum _dyns_members = [Stride!(2, T[1..$])];
  }

  alias Size = SumType!(size_t, size_t delegate());
  enum isDyns(T) = __traits(isSame, TemplateOf!Dyns, TemplateOf!T);

  enum _dyns_idx = zip(_dyns_members, _dyns_members.length.iota).assocArray;
  Size[] _dyns_sizes;
  SumType!(NoDuplicates!Types)[size_t] _dyns_dynses;
  void* _dyns_buf;

  auto fieldPtr(size_t i) const {
    auto offset = _dyns_sizes[0..i].map!(s => s.match!(
        (size_t v) => v,
        (size_t delegate() f) => f()
      )).sum;
    return _dyns_buf + offset;
  }

  auto ref getSize(size_t i) => _dyns_sizes[i].match!(
      (ref size_t v) => v,
      (ref size_t delegate() f) => f()
    );
  auto ref setSize(size_t i, size_t n) => _dyns_sizes[i].match!(
      (ref size_t v) => v = n,
      (ref size_t delegate() f) => f()
    );

 public:
  this() {
    enum initSize(T) = isDyns!T ? 0 : T.sizeof;
    enum sizes = [staticMap!(initSize, Types)].map!Size.array;
    _dyns_sizes = sizes;
    static foreach(i, Type; Types) static if(isDyns!Type) {
      _dyns_dynses[i] = new Type(fieldPtr(i));
      _dyns_sizes[i] = () => _dyns_dynses[i].tryMatch!((Type d) => d.size);
    }
  }
  this(const void* p) {
    this();
    opAssign(p);
  }

  auto ref ptr() => _dyns_buf;
  auto size() const => _dyns_sizes.map!(s => s.match!(
      (size_t v) => v,
      (size_t delegate() f) => f()
    )).sum;
  void alloc() { opAssign(new ubyte[size].ptr); }

  auto opAssign(const void* p) {
    _dyns_buf = cast(void*)p;
    return this;
  }

  auto opDispatch(string key)() if(_dyns_idx.keys.canFind(key)) {
    enum i = _dyns_idx[key];
    alias Type = Types[i];

    struct Field {
      Dyns self;
      auto ptr() const => self.fieldPtr(i);
      auto ref size() => self.getSize(i);
      auto ref size(size_t n) => self.setSize(i, n);
      auto ref val() {
        static if(isArray!Type) {
          auto len = size / ElementType!Type.sizeof;
          auto buf = cast(ElementType!Type*)ptr;
          return buf[0..len];
        } else {
          return *cast(Type*)ptr;
        }
      }
      auto toString() const => ptr.to!string;
    }

    static if(isDyns!Type)  return _dyns_dynses[i].tryMatch!((Type d) => d);
    else                    return Field(this);
  }
}

unittest {
  alias Sdyn = Dyns!(
    size_t,   "n",
    ubyte[0], "buf");

  struct Sbuf {
    size_t    n;
    ubyte[4]  buf;
  }

  {
    auto buf = Sbuf(4, [1, 2, 3, 4]);
    auto s = new Sdyn(&buf);
    s.buf.size = s.n.val;
    assert(s.size == 12);
    s.n.val = 123;
    assert(s.n.val == 123);
    s.buf.val[2] = 5;
    assert(s.buf.val == [1, 2, 5, 4]);
  }

  struct S2 {
    ubyte     buf1;
    ubyte[0]  buf2;
    ushort[2] buf3;
    Sdyn      buf4;
    size_t    buf5;
  }

  {
    auto s = new Dyns!S2;
    s.buf2.size = 3;
    s.buf4.buf.size = 4;
    assert(s.size == 28);
    s.alloc;
    s.buf5.val = size_t.max;
    assert(s.buf5.val == size_t.max);
  }
}
