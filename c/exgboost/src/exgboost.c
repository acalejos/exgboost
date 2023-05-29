#include "exgboost.h"

static int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info) {
  DMatrix_RESOURCE_TYPE = enif_open_resource_type(
      env, NULL, "DMatrix_RESOURCE_TYPE", DMatrix_RESOURCE_TYPE_cleanup,
      (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);
  Booster_RESOURCE_TYPE = enif_open_resource_type(
      env, NULL, "Booster_RESOURCE_TYPE", Booster_RESOURCE_TYPE_cleanup,
      (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);
  if (DMatrix_RESOURCE_TYPE == NULL || Booster_RESOURCE_TYPE == NULL) {
    return 1;
  }
  return 0;
}

static int upgrade(ErlNifEnv *env, void **priv_data, void **old_priv_data,
                   ERL_NIF_TERM load_info) {
  DMatrix_RESOURCE_TYPE = enif_open_resource_type(
      env, NULL, "DMatrix_RESOURCE_TYPE", DMatrix_RESOURCE_TYPE_cleanup,
      ERL_NIF_RT_TAKEOVER, NULL);
  Booster_RESOURCE_TYPE = enif_open_resource_type(
      env, NULL, "Booster_RESOURCE_TYPE", Booster_RESOURCE_TYPE_cleanup,
      ERL_NIF_RT_TAKEOVER, NULL);
  if (DMatrix_RESOURCE_TYPE == NULL || Booster_RESOURCE_TYPE == NULL) {
    return 1;
  }
  return 0;
}

static ErlNifFunc nif_funcs[] = {
    {"get_int_size", 0, exg_get_int_size},
    {"xgboost_version", 0, EXGBoostVersion},
    {"xgboost_build_info", 0, EXGBuildInfo},
    {"set_global_config", 1, EXGBSetGlobalConfig},
    {"get_global_config", 0, EXGBGetGlobalConfig},
    {"proxy_dmatrix_create", 0, EXGProxyDMatrixCreate},
    {"dmatrix_create_from_file", 2, EXGDMatrixCreateFromFile},
    {"dmatrix_create_from_mat", 4, EXGDMatrixCreateFromMat},
    {"dmatrix_create_from_sparse", 6, EXGDMatrixCreateFromSparse},
    {"dmatrix_create_from_dense", 2, EXGDMatrixCreateFromDense},
    {"dmatrix_set_str_feature_info", 3, EXGDMatrixSetStrFeatureInfo},
    {"dmatrix_get_str_feature_info", 2, EXGDMatrixGetStrFeatureInfo},
    {"dmatrix_set_dense_info", 5, EXGDMatrixSetDenseInfo},
    {"dmatrix_num_row", 1, EXGDMatrixNumRow},
    {"dmatrix_num_col", 1, EXGDMatrixNumCol},
    {"dmatrix_num_non_missing", 1, EXGDMatrixNumNonMissing},
    {"dmatrix_set_info_from_interface", 3, EXGDMatrixSetInfoFromInterface},
    {"dmatrix_save_binary", 3, EXGDMatrixSaveBinary},
    {"get_binary_address", 1, exg_get_binary_address},
    {"dmatrix_get_float_info", 2, EXGDMatrixGetFloatInfo},
    {"dmatrix_get_uint_info", 2, EXGDMatrixGetUIntInfo},
    {"dmatrix_get_data_as_csr", 2, EXGDMatrixGetDataAsCSR},
    {"dmatrix_slice", 3, EXGDMatrixSliceDMatrix},
    {"booster_create", 1, EXGBoosterCreate},
    {"booster_boosted_rounds", 1, EXGBoosterBoostedRounds},
    {"booster_set_param", 3, EXGBoosterSetParam},
    {"booster_get_num_feature", 1, EXGBoosterGetNumFeature},
    {"booster_update_one_iter", 3, EXGBoosterUpdateOneIter},
    {"booster_boost_one_iter", 4, EXGBoosterBoostOneIter},
    {"booster_eval_one_iter", 4, EXGBoosterEvalOneIter},
    {"booster_get_attr_names", 1, EXGBoosterGetAttrNames},
    {"booster_get_attr", 2, EXGBoosterGetAttr},
    {"booster_set_attr", 3, EXGBoosterSetAttr},
    {"booster_set_str_feature_info", 3, EXGBoosterSetStrFeatureInfo},
    {"booster_get_str_feature_info", 2, EXGBoosterGetStrFeatureInfo},
    {"booster_feature_score", 2, EXGBoosterFeatureScore},
    {"booster_slice", 4, EXGBoosterSlice},
    {"booster_predict_from_dmatrix", 3, EXGBoosterPredictFromDMatrix},
    {"booster_predict_from_dense", 4, EXGBoosterPredictFromDense},
    {"booster_predict_from_csr", 7, EXGBoosterPredictFromCSR},
    {"booster_load_model", 1, EXGBoosterLoadModel, ERL_NIF_DIRTY_JOB_IO_BOUND},
    {"booster_save_model", 2, EXGBoosterSaveModel, ERL_NIF_DIRTY_JOB_IO_BOUND},
    {"booster_serialize_to_buffer", 1, EXGBoosterSerializeToBuffer},
    {"booster_deserialize_from_buffer", 1, EXGBoosterDeserializeFromBuffer},
    {"booster_save_model_to_buffer",2,EXGBoosterSaveModelToBuffer},
    {"booster_load_model_from_buffer",1,EXGBoosterLoadModelFromBuffer},
    {"booster_load_json_config",2,EXGBoosterLoadJsonConfig},
    {"booster_save_json_config",1,EXGBoosterSaveJsonConfig}};
ERL_NIF_INIT(Elixir.EXGBoost.NIF, nif_funcs, load, NULL, upgrade, NULL)
