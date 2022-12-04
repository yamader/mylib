import std;
import bitmap;

auto chr(Color hi, Color lo, bool tc = false) {
  string res;

  if(lo.a) {
    res ~= "\33[48;";
    if(tc)  res ~= format("2;%d;%d;%d", lo.r, lo.g, lo.b);
    else    res ~= format("5;%d", lo.x256);
    res ~= "m";
  }

  if(hi.a) {
    res ~= "\33[38;";
    if(tc)  res ~= format("2;%d;%d;%d", hi.r, hi.g, hi.b);
    else    res ~= format("5;%d", hi.x256);
    res ~= "m\u2580";
  } else {
    res ~= " ";
  }

  return res ~ "\33[m";
}

auto render(const Color[][] bmp, bool tc) =>
  bmp.chunks(2).map!(a => zip(a[0], a[1])
    .map!(c => chr(c[0], c[1], tc)).array).array;
