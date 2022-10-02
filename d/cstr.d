auto len(T)(T* a) {
  size_t i;
  while(a[i]) i++;
  return i;
}

auto str(char* s) {
  return cast(string)s[0..s.len];
}

unittest {
  auto p = cast(char*)"asdf".ptr;
  assert(p.str == "asdf");
}
