#pragma once

#include <utility>

#define _JOIN(a, b) a##b
#define JOIN(a, b) _JOIN(a, b)

#define init(code) [[maybe_unused]]                          \
                   static auto JOIN(_init_, __LINE__) = [] { \
                     [] { code; }();                         \
                     return 0;                               \
                   }();

#define defer(code) [[maybe_unused]] Defer JOIN(_defer_, __LINE__){[&] { code }};

template <class F>
struct Defer {
  F f;
  Defer(F&& f) : f{std::forward<F>(f)} {}
  ~Defer() { f(); }
};
