#ifndef EXGBOOST_BOOSTER_H
#define EXGBOOST_BOOSTER_H

#include "utils.h"

ERL_NIF_TERM EXGBoosterCreate(ErlNifEnv *env, int argc,
                              const ERL_NIF_TERM argv[]);

#endif