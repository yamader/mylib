import std;

struct Sum(T...) {
  SumType!T v;
  alias v this;

  this(U...)(U args) {
    static if(isSumType!U) v = args.match!(typeof(v));
    else                   v = typeof(v)(args);
  }
}
