#include "exgboost.h"

ERL_NIF_TERM EXGBoostVersion(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    int major, minor, patch;
    XGBoostVersion(&major, &minor, &patch);
    return enif_make_tuple3(env, enif_make_int(env, major), enif_make_int(env, minor), enif_make_int(env, patch));
}


static ErlNifFunc nif_funcs[] = {
  {"exgboost_version", 0, EXGBoostVersion}
};
ERL_NIF_INIT(Elixir.Exgboost.NIF, nif_funcs, NULL, NULL, NULL, NULL)