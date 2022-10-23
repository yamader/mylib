#pragma once

#include "nullstream.hh"

#include <iostream>
#include <sstream>
#include <string>
#include <utility>

//
struct Context {
  bool debugging = false;
  bool has_color = true;
};

namespace yamad {

using namespace std::literals;

constexpr inline std::string_view prefix{"hoge: "};

auto c_dim(Context& ctx, auto&& msg) -> decltype(msg + "") {
  if(ctx.has_color) return "\e[1;30m" + msg + "\e[0m";
  else              return msg;
}

auto c_err(Context& ctx, auto&& msg) -> decltype(msg + "") {
  if(ctx.has_color) return "\e[1;31m" + msg + "\e[0m";
  else              return msg;
}

class Logger {
  std::ostream& out;
  std::stringstream ss;

 public:
  Logger(std::ostream& out): out{out} {
    *this << prefix;
  }
  ~Logger() { out << ss.str() << '\n'; }

  template<typename T>
  auto operator<<(T&& val) -> Logger& {
    ss << std::forward<T>(val);
    return *this;
  }
};

class Log {
  Context& ctx;
  Logger logger;

 public:
  Log(Context& ctx): ctx{ctx}, logger{std::cout} {}

  template<typename T>
  auto operator<<(T&& val) -> Log& {
    logger << std::forward<T>(val);
    return *this;
  }
};

class Err {
  Context& ctx;
  Logger logger;

 public:
  Err(Context& ctx): ctx{ctx}, logger{std::cerr} {
    *this << c_err(ctx, "error: "s);
  }

  template<typename T>
  auto operator<<(T&& val) -> Err& {
    logger << std::forward<T>(val);
    return *this;
  }
};

class Fatal {
  Context& ctx;
  Logger logger;

 public:
  Fatal(Context& ctx): ctx{ctx}, logger{std::cerr} {
    *this << c_err(ctx, "fatal: "s);
  }
  [[noreturn]] ~Fatal() {
    logger.~Logger();
    exit(1);
  }

  template<typename T>
  auto operator<<(T&& val) -> Fatal& {
    logger << std::forward<T>(val);
    return *this;
  }
};

class Debug {
  Context& ctx;
  Logger logger;

 public:
  Debug(Context& ctx): ctx{ctx}, logger{init_logger(ctx)} {
    *this << c_dim(ctx, "debug: "s);
  }

  auto init_logger(Context& ctx) -> Logger {
    if(ctx.debugging) return {std::cout};
    else              return {yamad::null_stream};
  }

  template<typename T>
  auto operator<<(T&& val) -> Debug& {
    logger << std::forward<T>(val);
    return *this;
  }
};

}
