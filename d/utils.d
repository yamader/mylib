auto avg(T)(T[] a) => a.fold!`a+b` / real(a.length);
auto toa(T, U)(U[] a) => a[].map!(to!T).array;
auto pop(T)(auto ref T[] a) { auto v=a.front; a.popFront; return v; }

auto timestamp(SysTime st) => (st.toUTC - SysTime.fromUnixTime(0)).total!"msecs";
auto timestamp(DateTime dt) => dt.SysTime.timestamp;
auto timestamp() => Clock.currTime.timestamp;
