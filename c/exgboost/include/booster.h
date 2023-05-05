#ifndef EXGBOOST_BOOSTER_H
#define EXGBOOST_BOOSTER_H

#include "utils.h"

ERL_NIF_TERM EXGBoosterCreate(ErlNifEnv *env, int argc,
                              const ERL_NIF_TERM argv[]);
ERL_NIF_TERM EXGBoosterBoostedRounds(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]);
ERL_NIF_TERM EXGBoosterSlice(ErlNifEnv *env, int argc,
                             const ERL_NIF_TERM argv[]);
ERL_NIF_TERM EXGBoosterSetParam(ErlNifEnv *env, int argc,
                                const ERL_NIF_TERM argv[]);
ERL_NIF_TERM EXGBoosterGetNumFeature(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]);
ERL_NIF_TERM EXGBoosterUpdateOneIter(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]);
ERL_NIF_TERM EXGBoosterBoostOneIter(ErlNifEnv *env, int argc,
                                    const ERL_NIF_TERM argv[]);

#endif