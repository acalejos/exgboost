#include "exgboost.h"

static ERL_NIF_TERM
fast_compare(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  int a, b;
  // Fill a and b with the values of the first two args
  if (!enif_get_int(env, argv[0], &a) ||
      !enif_get_int(env, argv[1], &b)) {
      return enif_make_badarg(env);
  }

  // Usual C unreadable code because this way is more true
  int result = a == b ? 0 : (a > b ? 1 : -1);

  return enif_make_int(env, result);
}


static ErlNifFunc nif_funcs[] = {
  // {erl_function_name, erl_function_arity, c_function}
  {"fast_compare", 2, fast_compare}
};
ERL_NIF_INIT(Elixir.Exgboost.NIF, nif_funcs, NULL, NULL, NULL, NULL)