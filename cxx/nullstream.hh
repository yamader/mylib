#pragma once

#include <ostream>
#include <streambuf>

namespace yamad {

class NullBuf: public std::streambuf {
 public:
  auto overflow(int c) -> int { return c; }
};

class NullStream: public std::ostream {
  NullBuf buf;
 public:
  NullStream(): std::ostream{&buf} {}
};

static NullStream null_stream;

}
