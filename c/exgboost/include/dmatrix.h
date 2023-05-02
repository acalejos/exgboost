#ifndef EXGBOOST_DMATRIX_H
#define EXGBOOST_DMATRIX_H

#include "utils.h"

ERL_NIF_TERM EXGDMatrixCreateFromFile(ErlNifEnv *env, int argc,
                                      const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixCreateFromMat(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixCreateFromSparse(ErlNifEnv *env, int argc,
                                        const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixCreateFromDense(ErlNifEnv *env, int argc,
                                       const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixGetStrFeatureInfo(ErlNifEnv *env, int argc,
                                         const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixSetStrFeatureInfo(ErlNifEnv *env, int argc,
                                         const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixSetDenseInfo(ErlNifEnv *env, int argc,
                                    const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixNumRow(ErlNifEnv *env, int argc,
                              const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixNumCol(ErlNifEnv *env, int argc,
                              const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixNumNonMissing(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixSetInfoFromInterface(ErlNifEnv *env, int argc,
                                            const ERL_NIF_TERM argv[]);
ERL_NIF_TERM EXGDMatrixSaveBinary(ErlNifEnv *env, int argc,
                                  const ERL_NIF_TERM argv[]);
#endif