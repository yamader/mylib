import std;

const struct Color {
  ubyte[] bgra;

  auto ref b() => bgra[0];
  auto ref g() => bgra[1];
  auto ref r() => bgra[2];
  auto ref a() => bgra[3];

  auto x256() {
    // なんか知らんけどよく使われてるアルゴリズム
    // https://github.com/tmux/tmux/pull/432 とか

    auto distSq(T)(T ax, T ay, T az, T bx, T by, T bz) =>
      (ax - bx)^^2 + (ay - by)^^2 + (az - bz)^^2;

    enum i2c = [0x0, 0x5f, 0x87, 0xaf, 0xd7, 0xff];
    auto c2i(ubyte v) => v < 48 ? 0 : v < 115 ? 1 : (v - 35) / 40;

    const ir = c2i(r), cr = i2c[ir],
          ig = c2i(g), cg = i2c[ig],
          ib = c2i(b), cb = i2c[ib];

    const avg = (r + g + b) / 3;
    const igy = avg > 238 ? 23 : (avg - 3) / 10,
          cgy = 8 + 10 * igy;

    return distSq(cr, cg, cb, r, g, b) <= distSq(cgy, cgy, cgy, r, g, b)
      ? 16 + 36 * ir + 6 * ig + ib
      : 232 + igy;
  }
}

struct Bitmap {
  size_t width, height;
  Color[][] data;
}

auto unpack(T, U: ubyte)(U[] buf) {
  const fixed = cast(U[T.sizeof])buf[0..T.sizeof];
  return fixed.littleEndianToNative!T;
}

auto parse(T: ubyte)(T[] buf) {
  const offs   = buf[0x0a..0x0e].unpack!uint;
  const width  = buf[0x12..0x16].unpack!int;
  const height = buf[0x16..0x1a].unpack!int;

  // v5 header only
  if(buf[0x1c..0x1e].unpack!ushort != 32)
    fatal("format is not supported");

  return const Bitmap(width, height,
    buf[offs..$]
      .chunks(4).map!Color.array
      .chunks(width).array.reverse);
}
