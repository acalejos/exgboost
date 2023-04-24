#ifndef EXGBOOST_DMATRIX_H
#define EXGBOOST_DMATRIX_H

#include "utils.h"

ERL_NIF_TERM EXGDMatrixCreateFromFile(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixCreateFromMat(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixCreateFromCSR(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

/**
 * @brief Create a DMatrix from a CSR matrix in the format of CSREx
 * @note WARNING: c_api.cc:64: `XGDMatrixCreateFromCSREx` is deprecated since 2.0.0, use `XGDMatrixCreateFromCSR` instead
 *
 * @param env
 * @param argc
 * @param argv
 * @return ERL_NIF_TERM Resource handle to DMatrix
 */
ERL_NIF_TERM EXGDMatrixCreateFromCSREx(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixCreateFromCSC(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixCreateFromDense(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixCreateFromDT(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixSaveBinary(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixSetFloatInfo(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixSetUIntInfo(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixSetGroup(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixGetFloatInfo(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixGetUIntInfo(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixNumRow(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixNumCol(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixSliceDMatrix(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixFree(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

#endif