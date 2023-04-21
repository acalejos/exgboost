#include "exgboost.h"

static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
    DMatrix_RESOURCE_TYPE = enif_open_resource_type(env, NULL, "DMatrix_RESOURCE_TYPE",
                                                      DMatrix_RESOURCE_TYPE_cleanup,
                                                      (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);
    if (DMatrix_RESOURCE_TYPE == NULL) {
        return 1;
    }
    return 0;
}

static int upgrade(ErlNifEnv* env, void** priv_data, void** old_priv_data, ERL_NIF_TERM load_info) {
    DMatrix_RESOURCE_TYPE = enif_open_resource_type(env, NULL, "DMatrix_RESOURCE_TYPE",
                                                      DMatrix_RESOURCE_TYPE_cleanup,
                                                      ERL_NIF_RT_TAKEOVER, NULL);
    if (DMatrix_RESOURCE_TYPE == NULL) {
        return 1;
    }
    return 0;
}

static ErlNifFunc nif_funcs[] = {
    {"exgboost_version", 0, EXGBoostVersion},
    {"exg_build_info", 0, EXGBuildInfo},
    {"exg_set_global_config", 1, EXGBSetGlobalConfig},
    {"exg_get_global_config", 0, EXGBGetGlobalConfig},
    {"exg_dmatrix_create_from_file",2,EXGDMatrixCreateFromFile},
    {"exg_dmatrix_create_from_mat",4,EXGDMatrixCreateFromMat}
};
ERL_NIF_INIT(Elixir.Exgboost.NIF, nif_funcs, NULL, NULL, NULL, NULL)