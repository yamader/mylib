auto avg(T)(T[] a) => a.fold!`a+b` / real(a.length);
auto toa(T, U)(U[] a) => a[].map!(to!T).array;
auto pop(T)(auto ref T[] a) { auto v=a.front; a.popFront; return v; }
