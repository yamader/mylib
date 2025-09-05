#include <algorithm>
#include <cctype>
#include <functional>
#include <optional>
#include <string_view>
#include <type_traits>
#include <utility>
#include <vector>

// clang-format off
#define FWD(v) std::forward<decltype(v)>(v)
#define CAPT(v) v{FWD(v)}
// clang-format on

namespace parser {

using std::function, std::string_view;

template <class T>
using Parsed = std::optional<std::pair<std::remove_reference_t<T>, string_view>>;

template <class P>
using ParserV = decltype(std::declval<P>()(std::declval<string_view>()))::value_type::first_type;

// Functor -----------------------------------------------------

inline auto map(auto&& f, auto&& p) {
  return [CAPT(f), CAPT(p)](string_view s) {
    return p(s).transform([&](auto&& v) {
      return std::pair{f(std::move(v.first)), v.second};
    });
  };
}

inline auto operator%(auto&& f, auto&& p) { return map(FWD(f), FWD(p)); }

// Applicative -------------------------------------------------

inline auto pure(auto&& v) {
  return [CAPT(v)](string_view s) -> Parsed<decltype(v)> {
    return {{std::move(v), s}};
  };
}

inline auto apply(auto&& p, auto&& q) {
  return [CAPT(p), CAPT(q)](string_view s) {
    return p(s).and_then([&](auto&& f) {
      return (std::move(f.first) % std::move(q))(f.second);
    });
  };
}

inline auto operator<<(auto&& p, auto&& q) {
  return [CAPT(p), CAPT(q)](string_view s) {
    return [](auto&& x) { return [CAPT(x)](auto&&) { return x; }; } % std::move(p) * std::move(q);
  };
}

inline auto operator>>(auto&& p, auto&& q) {
  return [CAPT(p), CAPT(q)](string_view s) {
    return [](auto&&) { return [](auto&& x) { return x; }; } % std::move(p) * std::move(q);
  };
}

inline auto operator*(auto&& p, auto&& q) { return apply(FWD(p), FWD(q)); }

// Alternative -------------------------------------------------

template <class A>
inline auto empty(string_view s) -> Parsed<A> { return {}; }

inline auto either(auto&& p, auto&& q) {
  return [CAPT(p), CAPT(q)](string_view s) {
    return p(s).or_else([&] { return q(s); });
  };
}

inline auto operator|(auto&& p, auto&& q) { return either(FWD(p), FWD(q)); }

// Monad -------------------------------------------------------

inline auto bind(auto&& p, auto&& f) {
  return [CAPT(p), CAPT(f)](string_view s) {
    return p(s).and_then([&](auto&& v) {
      return f(std::move(v.first))(v.second);
    });
  };
}

inline auto operator>>=(auto&& p, auto&& f) { return bind(FWD(p), FWD(f)); }

// List --------------------------------------------------------

template <template <class> class V = std::vector>
inline auto many(auto&& p) {
  using A = V<ParserV<decltype(p)>>;
  return [CAPT(p)](string_view s) -> Parsed<A> {
    // ダックタイピングしてるとFPっぽく書けない :(
    A a;
    while (auto v = p(s)) {
      a.emplace_back(std::move((*v).first));
      s = (*v).second;
    }
    return {{a, s}};
  };
}

template <template <class> class V = std::vector>
inline auto some(auto&& p) {
  return [CAPT(p)](string_view s) {
    return many(p)(s).and_then([&](auto&& v) -> Parsed<V<ParserV<decltype(p)>>> {
      if (v.first.empty()) return {};
      return v;
    });
  };
}

inline auto operator-(auto&& p) { return many(FWD(p)); }
inline auto operator+(auto&& p) { return some(FWD(p)); }

// Basic -------------------------------------------------------

inline auto satisfy(auto&& f) {
  return [CAPT(f)](string_view s) -> Parsed<char> {
    if (s.empty() or not f(s.front())) return {};
    return {{s.front(), s.substr(1)}};
  };
}

inline auto any_chr() {
  return satisfy([](char) { return true; });
}

inline auto chr(char c) {
  return satisfy([c](char v) { return v == c; });
}

inline auto str(string_view x) {
  return [x](string_view s) -> Parsed<string_view> {
    if (not s.starts_with(x)) return {};
    return {{x, s.substr(x.length())}};
  };
}

inline auto lex(auto&& p) {
  return [CAPT(p)](string_view s) {
    return p({std::ranges::find_if_not(s, (int (*)(int))std::isspace), s.end()});
  };
}

inline auto lchr(char c) { return lex(chr(c)); }
inline auto lstr(string_view s) { return lex(str(s)); }

}
