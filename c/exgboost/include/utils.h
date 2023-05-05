#ifndef EXGBOOST_UTILS_H
#define EXGBOOST_UTILS_H

#include <erl_nif.h>
#include <stdio.h>
#include <string.h>
#include <xgboost/c_api.h>

ErlNifResourceType *DMatrix_RESOURCE_TYPE;
ErlNifResourceType *Booster_RESOURCE_TYPE;
typedef uint64_t bst_ulong;

void DMatrix_RESOURCE_TYPE_cleanup(ErlNifEnv *env, void *arg);

void Booster_RESOURCE_TYPE_cleanup(ErlNifEnv *env, void *arg);

// Status helpers

ERL_NIF_TERM exg_error(ErlNifEnv *env, const char *msg);

ERL_NIF_TERM ok_atom(ErlNifEnv *env);

ERL_NIF_TERM exg_ok(ErlNifEnv *env, ERL_NIF_TERM term);

ERL_NIF_TERM exg_get_binary_address(ErlNifEnv *env, int argc,
                                    const ERL_NIF_TERM argv[]);

ERL_NIF_TERM exg_get_int_size(ErlNifEnv *env, int argc,
                              const ERL_NIF_TERM argv[]);

// Argument helpers

int exg_get_string(ErlNifEnv *env, ERL_NIF_TERM term, char **var);

int exg_get_list(ErlNifEnv *env, ERL_NIF_TERM term, double **out);

int exg_get_string_list(ErlNifEnv *env, ERL_NIF_TERM term, char ***out,
                        unsigned *len);
int exg_get_dmatrix_list(ErlNifEnv *env, ERL_NIF_TERM term,
                         DMatrixHandle **dmats, unsigned *len);

#endif