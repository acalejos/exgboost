#include "exgboost.h"

static int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info) {
  DMatrix_RESOURCE_TYPE = enif_open_resource_type(
      env, NULL, "DMatrix_RESOURCE_TYPE", DMatrix_RESOURCE_TYPE_cleanup,
      (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);
  if (DMatrix_RESOURCE_TYPE == NULL) {
    return 1;
  }
  return 0;
}

static int upgrade(ErlNifEnv *env, void **priv_data, void **old_priv_data,
                   ERL_NIF_TERM load_info) {
  DMatrix_RESOURCE_TYPE = enif_open_resource_type(
      env, NULL, "DMatrix_RESOURCE_TYPE", DMatrix_RESOURCE_TYPE_cleanup,
      ERL_NIF_RT_TAKEOVER, NULL);
  if (DMatrix_RESOURCE_TYPE == NULL) {
    return 1;
  }
  return 0;
}

static ErlNifFunc nif_funcs[] = {
    {"xgboost_version", 0, EXGBoostVersion},
    {"xgboost_build_info", 0, EXGBuildInfo},
    {"set_global_config", 1, EXGBSetGlobalConfig},
    {"get_global_config", 0, EXGBGetGlobalConfig},
    {"dmatrix_create_from_file", 3, EXGDMatrixCreateFromFile},
    {"dmatrix_create_from_mat", 4, EXGDMatrixCreateFromMat},
    {"dmatrix_create_from_csr", 5, EXGDMatrixCreateFromCSR},
    {"dmatrix_create_from_csrex", 6, EXGDMatrixCreateFromCSREx},
    {"dmatrix_create_from_dense", 3, EXGDMatrixCreateFromDense}};
ERL_NIF_INIT(Elixir.Exgboost.NIF, nif_funcs, load, NULL, upgrade, NULL)