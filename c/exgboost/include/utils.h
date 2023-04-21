#ifndef EXGBOOST_UTILS_H
#define EXGBOOST_UTILS_H

#include <cstring>
#include <erl_nif.h>
#include <xgboost/c_api.h>

extern ErlNifResourceType* DMatrix_RESOURCE_TYPE;
typedef uint64_t bst_ulong;

void DMatrix_RESOURCE_TYPE_cleanup(ErlNifEnv* env, void* arg);

// Status helpers

ERL_NIF_TERM error(ErlNifEnv* env, const char* msg);

ERL_NIF_TERM ok(ErlNifEnv* env);

ERL_NIF_TERM ok(ErlNifEnv* env, ERL_NIF_TERM term);

// Argument helpers

int get_string(ErlNifEnv* env, ERL_NIF_TERM term, char **var);

int get_list(ErlNifEnv* env, ERL_NIF_TERM term, double **out);

#endif