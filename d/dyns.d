// Dynamic Struct

import std;

class Dyns(T...) {
  static if(T.length == 1) {
    // T is a struct
    alias Types = Fields!T;
  } else {
    // T are fields
    template Keys(T, string _, U...) {
      static if(U.length) alias Keys = AliasSeq!(T, Keys!U);
      else                alias Keys = T;
    }
    alias Types = Keys!T;
  }

  alias Size = SumType!(size_t, size_t delegate());

  enum isDyns(T) = __traits(isSame, TemplateOf!Dyns, TemplateOf!T);

  static init() {
    size_t[string] idx;
    typeof(_dyns_sizes) sizes;
    static if(T.length == 1) {
      // T is a struct
      static foreach(key; [__traits(derivedMembers, T)]) {{
        alias I = typeof(mixin(`T[0].` ~ key));
        idx[key] = idx.length;
        static if(isDyns!I) Size s = 0;
        else                Size s = I.sizeof;
        sizes ~= s;
      }}
    } else {
      // T are fields
      auto unpack(U, string key, V...)() {
        idx[key] = idx.length;
        static if(isDyns!U) Size s = 0;
        else                Size s = U.sizeof;
        sizes ~= s;
        static if(V.length) unpack!V;
      }
      unpack!T;
    }
    return tuple!("idx", "sizes")(idx, sizes);
  }

 private:
  enum size_t[string] _dyns_idx = init.idx;
  Size[] _dyns_sizes = init.sizes;
  SumType!Types[size_t] _dyns_dynses;
  void* _dyns_buf;

 public:
  this() {
    static foreach(i, Type; Types) static if(isDyns!Type) {
      _dyns_dynses[i] = new Type(ptr(i));
      _dyns_sizes[i] = () => _dyns_dynses[i].tryMatch!((Type d) => d.size);
    }
  }
  this(const void* p) {
    this();
    opAssign(p);
  }

  auto offset(size_t i) const {
    if(!i) return 0;
    return _dyns_sizes[0..i].map!(s => s.match!(
        (size_t v) => v,
        (size_t delegate() f) => f()
      )).sum;
  }
  auto offset(string key) const => offset(_dyns_idx[key]);
  auto ptr(U)(U field) const => _dyns_buf + offset(field);

  // field
  auto ref getSize(size_t i) => _dyns_sizes[i].match!(
      (ref size_t v) => v,
      (ref size_t delegate() f) => f()
    );
  auto ref setSize(size_t i, size_t n) => _dyns_sizes[i].match!(
      (ref size_t v) => v = n,
      (ref size_t delegate() f) => f()
    );

  // total
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
      auto ptr() const => self.ptr(i);
      auto ref size() => self.getSize(i);
      auto ref size(size_t n) => self.setSize(i, n);
      auto ref val() {
        static if(isArray!Type) return cast(ElementType!Type*)ptr;
        else                    return *cast(Type*)ptr;
      }
      auto ref arr()() if(isArray!Type) {
        auto len = size / ElementType!Type.sizeof;
        return val[0..len];
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
    s.buf.arr[2] = 5;
    assert(s.buf.arr == [1, 2, 5, 4]);
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
