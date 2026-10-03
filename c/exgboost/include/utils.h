#ifndef EXGBOOST_UTILS_H
#define EXGBOOST_UTILS_H

#include <erl_nif.h>
#include <inttypes.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <xgboost/c_api.h>

ErlNifResourceType *DMatrix_RESOURCE_TYPE;
ErlNifResourceType *Booster_RESOURCE_TYPE;
typedef uint64_t bst_ulong;

// Initialize atoms (must be called during NIF load)
void exg_init_atoms(ErlNifEnv *env);

void DMatrix_RESOURCE_TYPE_cleanup(ErlNifEnv *env, void *arg);

void Booster_RESOURCE_TYPE_cleanup(ErlNifEnv *env, void *arg);

// Status helpers

ERL_NIF_TERM exg_error(ErlNifEnv *env, const char *msg);

ERL_NIF_TERM ok_atom(ErlNifEnv *env);

ERL_NIF_TERM exg_ok(ErlNifEnv *env, ERL_NIF_TERM term);

ERL_NIF_TERM exg_get_int_size(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

// Argument helpers

int exg_get_string(ErlNifEnv *env, ERL_NIF_TERM term, char **var);

int exg_get_list(ErlNifEnv *env, ERL_NIF_TERM term, double **out);

int exg_get_string_list(ErlNifEnv *env, ERL_NIF_TERM term, char ***out, unsigned *len);
int exg_get_dmatrix_list(ErlNifEnv *env, ERL_NIF_TERM term, DMatrixHandle **dmats, unsigned *len);

void exg_free_string_list(char **items, unsigned len);

void exg_free_dmatrix_list(DMatrixHandle *dmats);

// Array Interface helper - extracts components from tuple {binary, typestr, shape, readonly}
int exg_get_array_interface_tuple(ErlNifEnv *env, ERL_NIF_TERM tuple_term, ERL_NIF_TERM *binary_out,
                                  ERL_NIF_TERM *typestr_out, ERL_NIF_TERM *shape_out,
                                  ERL_NIF_TERM *readonly_out, const char **error_msg);

// Array Interface helper - builds JSON from components with fresh address
int exg_build_array_interface_json(ErlNifEnv *env, ERL_NIF_TERM binary_term,
                                   ERL_NIF_TERM typestr_term, ERL_NIF_TERM shape_term,
                                   ERL_NIF_TERM readonly_term, char **json_out,
                                   const char **error_msg);

// Array Interface helper - builds map from components
int exg_make_array_interface_map(ErlNifEnv *env, ERL_NIF_TERM binary_term,
                                 ERL_NIF_TERM typestr_term, ERL_NIF_TERM shape_term,
                                 ERL_NIF_TERM *out_map);

int exg_parse_typestr(const char *typestr, size_t *element_size_out, const char **error_msg);

#endif