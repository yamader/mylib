#pragma once

[[noreturn]] inline auto unreachable() {
  __builtin_unreachable();
}
