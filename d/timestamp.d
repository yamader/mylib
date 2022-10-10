import std.datetime;

auto timestamp() => (Clock.currTime.toUTC - SysTime.fromUnixTime(0)).total!"msecs";
