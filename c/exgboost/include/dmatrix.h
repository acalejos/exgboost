#ifndef EXGBOOST_DMATRIX_H
#define EXGBOOST_DMATRIX_H

#include "utils.h"

ERL_NIF_TERM EXGDMatrixCreateFromFile(ErlNifEnv *env, int argc,
                                      const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixCreateFromMat(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]);

/**
 * @brief Create a DMatrix from a CSR matrix
 * @details config – JSON encoded configuration. Required values are:
 *              missing: Which value to represent missing value.
 *              nthread (optional): Number of threads used for initializing
 * DMatrix.
 *
 * @param env
 * @param argc
 * @param argv
 * @return ERL_NIF_TERM
 */
ERL_NIF_TERM EXGDMatrixCreateFromCSR(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]);

/**
 * @brief Create a DMatrix from a CSR matrix in the format of CSREx
 * @note WARNING: c_api.cc:64: `XGDMatrixCreateFromCSREx` is deprecated
 * since 2.0.0, use `XGDMatrixCreateFromCSR` instead
 *
 * @param env
 * @param argc
 * @param argv
 * @return ERL_NIF_TERM Resource handle to DMatrix
 */
ERL_NIF_TERM EXGDMatrixCreateFromCSREx(ErlNifEnv *env, int argc,
                                       const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixCreateFromCSC(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixCreateFromDense(ErlNifEnv *env, int argc,
                                       const ERL_NIF_TERM argv[]);

ERL_NIF_TERM EXGDMatrixGetStrFeatureInfo(ErlNifEnv *env, int argc,
                                         const ERL_NIF_TERM argv[]);
/**
 * @brief Set feature information (feature names)
 * for integer, q for quantitive, c for categorical.  Similarly "int" and
 * "float" are also reconized.
 *
 *
 * @param env
 * @param argc
 * @param argv
 * @return ERL_NIF_TERM
 */
ERL_NIF_TERM EXGDMatrixSetStrFeatureInfo(ErlNifEnv *env, int argc,
                                         const ERL_NIF_TERM argv[]);
#endif