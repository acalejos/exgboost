#ifndef EXGBOOST_NIF_BINDINGS_H
#define EXGBOOST_NIF_BINDINGS_H

#include <cstring>
#include <erl_nif.h>
#include <xgboost/c_api.h>
#include <sys/stat.h>

ErlNifResourceType* DMatrix_RESOURCE_TYPE;

#define safe_xgboost(call) {  \
  int err = (call); \
  if (err != 0) { \
    fprintf(stderr, "%s:%d: error in %s: %s\n", __FILE__, __LINE__, #call, XGBGetLastError());  \
    exit(1); \
  } \
}

/**
 * @brief Return the version of the XGBoost library being currently used.
 *
 * @param env
 * @param argc
 * @param argv
 * @return ERL_NIF_TERM as a 3-tuple of integers: {major, minor, patch}
 *
 */
ERL_NIF_TERM EXGBoostVersion(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

/**
 * @brief Return the build information of the XGBoost library being currently used.
 *
 * @param env
 * @param argc
 * @param argv
 * @return ERL_NIF_TERM String encoded JSON object containing build flags and dependency version.
 */
ERL_NIF_TERM EXGBuildInfo(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

/**
 * @brief Set global configuration (collection of parameters that apply globally). This function accepts the list of key-value pairs representing the global-scope parameters to be configured. The list of key-value pairs are passed in as a JSON string.
 *
 * @param env
 * @param argc
 * @param argv
 * @return ERL_NIF_TERM 0 on success, -1 on failure.
 */
ERL_NIF_TERM EXGBSetGlobalConfig(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

/**
 * @brief Get global configuration (collection of parameters that apply globally). This function returns the list of key-value pairs representing the global-scope parameters that are currently configured. The list of key-value pairs are returned as a JSON string.
 *
 * @param env
 * @param argc
 * @param argv
 * @return ERL_NIF_TERM string encoded JSON object containing the global-scope parameters that are currently configured.
 */
ERL_NIF_TERM EXGBGetGlobalConfig(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

#endif