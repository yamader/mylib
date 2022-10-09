#pragma once

#include <algorithm>
#include <map>
#include <stdexcept>
#include <string>
#include <string_view>
#include <variant>
#include <vector>

using namespace std::literals;

class Args {
  using Key = std::string_view;

  struct Arg {
    std::string_view desc;
    std::vector<std::string_view> aliases;
    std::variant<std::string, bool> data;
    bool is_flag = false; // どうにかならんものか

    auto str() -> std::string { return std::get<std::string>(data); }
    auto flag() -> bool { return std::get<bool>(data); }

    auto operator=(auto&& v) { return data = v; }
  };

  std::map<Key, Arg> arg;
  std::map<std::string_view, Arg*> name;
  std::vector<std::string> _args;

 public:
  template<class... StringView>
  constexpr auto def(Key key, std::string_view desc, StringView... aliases) -> void {
    if(arg.contains(key)) throw std::invalid_argument("key already registered");
    arg.insert({ key, { desc, { aliases... } } });
    for(auto alias: { aliases... }) name[alias] = &arg[key];
  }

  template<class... StringView>
  constexpr auto def_flag(Key key, std::string_view desc, StringView... aliases) -> void {
    if(arg.contains(key)) throw std::invalid_argument("key already registered");
    arg.insert({ key, { desc, { aliases... }, false } });
    arg[key].is_flag = true;
    for(auto alias: { aliases... }) name[alias] = &arg[key];
  }

  auto parse(int argc, char* argv[]) -> void {
    std::vector<std::string> args(argv, argv + argc);
    for(decltype(argc) i = 0; i < argc; i++) {
      auto& s = args[i];
      if(s.starts_with('-')) {
        if(s == "--") {
          i++;
          for(; i < argc; i++) _args.push_back(args[i]);
          break;
        }
        auto eq_pos = s.find('=');
        if(eq_pos != std::string::npos) {
          name[s.substr(0, eq_pos)]->data = s.substr(eq_pos + 1);
          continue;
        }
        if(!name.contains(s)) throw std::invalid_argument("invalid options");
        auto arg = name[s];
        if(arg->is_flag) {
          arg->data = true;
        } else {
          if(argc < ++i) throw std::invalid_argument("required argument missing");
          arg->data = args[i];
        }
        continue;
      }
      _args.push_back(args[i]);
    }
  }

  auto operator[](Key key) -> Arg& { return arg[key]; }
};
