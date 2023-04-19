#ifndef EXGBOOST_NIF_BINDINGS_H
#define EXGBOOST_NIF_BINDINGS_H

#include <erl_nif.h>
#include <xgboost/c_api.h>

#define safe_xgboost(call) {  \
  int err = (call); \
  if (err != 0) { \
    fprintf(stderr, "%s:%d: error in %s: %s\n", __FILE__, __LINE__, #call, XGBGetLastError());  \
    exit(1); \
  } \
}

#define atom_ok enif_make_atom(env, "ok")
#define atom_error enif_make_atom(env, "error")

ERL_NIF_TERM XGBoostVersion(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

#endif