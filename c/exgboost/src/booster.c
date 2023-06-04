#include "booster.h"

static ERL_NIF_TERM make_Booster_resource(ErlNifEnv *env,
                                          BoosterHandle handle) {
  ERL_NIF_TERM ret = -1;
  BoosterHandle **resource =
      enif_alloc_resource(Booster_RESOURCE_TYPE, sizeof(BoosterHandle *));
  if (resource != NULL) {
    *resource = handle;
    ret = exg_ok(env, enif_make_resource(env, resource));
    enif_release_resource(resource);
  } else {
    ret = exg_error(env, "Failed to allocate memory for XGBoost DMatrix");
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterCreate(ErlNifEnv *env, int argc,
                              const ERL_NIF_TERM argv[]) {
  DMatrixHandle *dmats = NULL;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  unsigned dmats_len = 0;
  BoosterHandle booster = NULL;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!exg_get_dmatrix_list(env, argv[0], &dmats, &dmats_len)) {
    ret = exg_error(env, "Invalid list of DMatrix");
    goto END;
  }
  if (0 == dmats_len) {
    result = XGBoosterCreate(NULL, 0, &booster);
    if (result == 0) {
      ret = make_Booster_resource(env, booster);
      goto END;
    } else {
      ret = exg_error(env, "Error making booster");
      goto END;
    }
  }

  result = XGBoosterCreate(dmats, dmats_len, &booster);
  if (result == 0) {
    ret = make_Booster_resource(env, booster);
    goto END;
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterSlice(ErlNifEnv *env, int argc,
                             const ERL_NIF_TERM argv[]) {
  BoosterHandle in_booster;
  BoosterHandle out_booster;
  BoosterHandle **resource = NULL;
  int begin_layer = -1;
  int end_layer = -1;
  int step = -1;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (4 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  in_booster = *resource;
  if (!enif_get_int(env, argv[1], &begin_layer)) {
    ret = exg_error(env, "Invalid begin_layer");
    goto END;
  }
  if (!enif_get_int(env, argv[2], &end_layer)) {
    ret = exg_error(env, "Invalid end_layer");
    goto END;
  }
  if (!enif_get_int(env, argv[3], &step)) {
    ret = exg_error(env, "Invalid step");
    goto END;
  }
  result =
      XGBoosterSlice(in_booster, begin_layer, end_layer, step, &out_booster);
  if (result == 0) {
    ret = make_Booster_resource(env, out_booster);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterBoostedRounds(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **resource = NULL;
  int rounds;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *resource;
  result = XGBoosterBoostedRounds(booster, &rounds);
  if (result == 0) {
    ret = exg_ok(env, enif_make_int(env, rounds));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterSetParam(ErlNifEnv *env, int argc,
                                const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **resource = NULL;
  char *name = NULL;
  char *value = NULL;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (3 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *resource;
  if (!exg_get_string(env, argv[1], &name)) {
    ret = exg_error(env, "Invalid booster parameter name");
    goto END;
  }
  if (!exg_get_string(env, argv[2], &value)) {
    ret = exg_error(env, "Booster parameter value must be a string");
    goto END;
  }
  result = XGBoosterSetParam(booster, name, value);
  if (result == 0) {
    ret = enif_make_atom(env, "ok");
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterGetNumFeature(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **resource = NULL;
  bst_ulong num_feature;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *resource;
  result = XGBoosterGetNumFeature(booster, &num_feature);
  if (result == 0) {
    ret = exg_ok(env, enif_make_ulong(env, num_feature));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterUpdateOneIter(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  DMatrixHandle dtrain;
  DMatrixHandle **dtrain_resource = NULL;
  int iter;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (3 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  if (!enif_get_resource(env, argv[1], DMatrix_RESOURCE_TYPE,
                         (void *)&(dtrain_resource))) {
    ret = exg_error(env, "Invalid DMatrix");
    goto END;
  }
  dtrain = *dtrain_resource;
  if (!enif_get_int(env, argv[2], &iter)) {
    ret = exg_error(env, "Invalid iter");
    goto END;
  }
  result = XGBoosterUpdateOneIter(booster, iter, dtrain);
  if (result == 0) {
    ret = ok_atom(env);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}
ERL_NIF_TERM EXGBoosterBoostOneIter(ErlNifEnv *env, int argc,
                                    const ERL_NIF_TERM argv[]) {
  ErlNifBinary grad_bin;
  ErlNifBinary hess_bin;
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  DMatrixHandle dtrain;
  DMatrixHandle **dtrain_resource = NULL;
  float *grad = NULL;
  float *hess = NULL;
  unsigned grad_len = 0;
  unsigned hess_len = 0;
  bst_ulong len;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (4 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  if (!enif_get_resource(env, argv[1], DMatrix_RESOURCE_TYPE,
                         (void *)&(dtrain_resource))) {
    ret = exg_error(env, "Invalid DMatrix");
    goto END;
  }
  dtrain = *dtrain_resource;
  if (!enif_inspect_binary(env, argv[2], &grad_bin)) {
    ret = exg_error(env, "Grad must be a binary");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[3], &hess_bin)) {
    ret = exg_error(env, "Hess must be a binary");
    goto END;
  }
  grad = (float *)grad_bin.data;
  hess = (float *)hess_bin.data;
  grad_len = grad_bin.size / sizeof(float);
  hess_len = hess_bin.size / sizeof(float);
  if (grad_len != hess_len) {
    ret = exg_error(env, "Grad and Hess must have the same length");
    goto END;
  }
  result =
      XGBoosterBoostOneIter(booster, dtrain, grad, hess, (bst_ulong)grad_len);
  if (result == 0) {
    ret = ok_atom(env);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterEvalOneIter(ErlNifEnv *env, int argc,
                                   const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  DMatrixHandle *dmats = NULL;
  char **evnames = NULL;
  int iter = -1;
  unsigned num_dmats = 0;
  unsigned num_evnames = 0;
  char *out = NULL;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (4 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  if (!enif_get_int(env, argv[1], &iter)) {
    ret = exg_error(env, "Invalid iter");
    goto END;
  }
  if (!exg_get_dmatrix_list(env, argv[2], &dmats, &num_dmats)) {
    ret = exg_error(env, "Invalid DMatrix list");
    goto END;
  }
  if (!exg_get_string_list(env, argv[3], &evnames, &num_evnames)) {
    ret = exg_error(env, "Invalid evnames list");
    goto END;
  }
  if (num_dmats != num_evnames) {
    ret = exg_error(env, "dmats and evnames must have the same length");
    goto END;
  }
  result = XGBoosterEvalOneIter(booster, iter, dmats, evnames,
                                (bst_ulong)num_dmats, &out);
  if (result == 0) {
    ret = exg_ok(env, enif_make_string(env, out, ERL_NIF_LATIN1));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterGetAttr(ErlNifEnv *env, int argc,
                               const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  char *key = NULL;
  char *out = NULL;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  int success = -1;
  if (2 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  if (!exg_get_string(env, argv[1], &key)) {
    ret = exg_error(env, "Key must be a string");
    goto END;
  }
  result = XGBoosterGetAttr(booster, key, &out, &success);
  if (result == 0) {
    if (success == 0) {
      ret = enif_make_string(env, out, ERL_NIF_LATIN1);
    } else {
      ret = exg_ok(env, enif_make_atom(env, "undefined"));
    }
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterSetAttr(ErlNifEnv *env, int argc,
                               const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  char *key = NULL;
  char *value = NULL;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  unsigned atom_len = 0;
  if (3 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  if (!exg_get_string(env, argv[1], &key)) {
    ret = exg_error(env, "Key must be a string");
    goto END;
  }
  if (enif_get_atom_length(env, argv[2], &atom_len, ERL_NIF_LATIN1)) {
    if (atom_len == 0) {
      ret = exg_error(env, "Value must be a string or :nil");
      goto END;
    }
    char buf[atom_len + 1];
    if (!enif_get_atom(env, argv[2], buf, atom_len + 1, ERL_NIF_LATIN1)) {
      ret = exg_error(env, "Value must be a string or :nil");
      goto END;
    }
    if (strcmp(buf, "nil") != 0) {
      ret = exg_error(env, "Value must be a string or :nil");
      goto END;
    }
  } else if (!exg_get_string(env, argv[2], &value)) {
    ret = exg_error(env, "Value must be a string");
    goto END;
  }
  result = XGBoosterSetAttr(booster, key, value);
  if (result == 0) {
    ret = ok_atom(env);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterGetAttrNames(ErlNifEnv *env, int argc,
                                    const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  char **out = NULL;
  bst_ulong out_len = 0;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  result = XGBoosterGetAttrNames(booster, &out_len, &out);
  if (result == 0) {
    ERL_NIF_TERM arr[out_len];
    for (bst_ulong i = 0; i < out_len; ++i) {
      char *local = enif_alloc(strlen(out[i]) + 1);
      strcpy(local, out[i]);
      arr[i] = enif_make_string(env, local, ERL_NIF_LATIN1);
      // TODO: Do we free here or is it handled by the XGBoost library / BEAM?
    }
    ret = exg_ok(env, enif_make_list_from_array(env, arr, out_len));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterSetStrFeatureInfo(ErlNifEnv *env, int argc,
                                         const ERL_NIF_TERM argv[]) {
  BoosterHandle handle;
  BoosterHandle **resource = NULL;
  char **features = NULL;
  unsigned num_features = 0;
  char *field = NULL;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  if (argc != 3) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&resource)) {
    ret = exg_error(env, "Booster must be a resource");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &field)) {
    ret = exg_error(env, "Field must be a string");
    goto END;
  }
  if (!exg_get_string_list(env, argv[2], &features, &num_features)) {
    ret = exg_error(env, "Features must be a list");
    goto END;
  }
  if (strcmp(field, "feature_type") != 0 &&
      strcmp(field, "feature_name") != 0) {
    ret = exg_error(env, "Field must be in ['feature_type', 'feature_name']");
    goto END;
  }
  handle = *resource;
  result = XGBoosterSetStrFeatureInfo(handle, field, features, num_features);
  if (result == 0) {
    ret = ok_atom(env);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (features != NULL) {
    enif_free(features);
    features = NULL;
  }
  return ret;
}
ERL_NIF_TERM EXGBoosterGetStrFeatureInfo(ErlNifEnv *env, int argc,
                                         const ERL_NIF_TERM argv[]) {
  BoosterHandle handle;
  BoosterHandle **resource = NULL;
  char const **c_out_features = NULL;
  bst_ulong out_size = 0;
  char *field = NULL;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  if (argc != 2) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&resource)) {
    ret = exg_error(env, "Booster must be a resource");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &field)) {
    ret = exg_error(env, "Field must be a string");
    goto END;
  }
  if (strcmp(field, "feature_type") != 0 &&
      strcmp(field, "feature_name") != 0) {
    ret = exg_error(env, "Field must be in ['feature_type', 'feature_name']");
    goto END;
  }
  handle = *resource;
  result =
      XGBoosterGetStrFeatureInfo(handle, field, &out_size, &c_out_features);
  if (result == 0) {
    ERL_NIF_TERM arr[out_size];
    for (bst_ulong i = 0; i < out_size; ++i) {
      char *local = enif_alloc(strlen(c_out_features[i]) + 1);
      strcpy(local, c_out_features[i]);
      arr[i] = enif_make_string(env, local, ERL_NIF_LATIN1);
      // TODO: Do we free here or is it handled by the XGBoost library / BEAM?
    }
    ret = exg_ok(env, enif_make_list_from_array(env, arr, out_size));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (field != NULL) {
    enif_free(field);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterFeatureScore(ErlNifEnv *env, int argc,
                                    const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  char **config = NULL;
  bst_ulong out_n_features = 0;
  char **out_features = NULL;
  bst_ulong out_dim = 0;
  bst_ulong *out_shape = NULL;
  float *out_scores = NULL;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (2 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &config)) {
    ret = exg_error(env, "Config must be a list");
    goto END;
  }
  booster = *booster_resource;
  result =
      XGBoosterFeatureScore(booster, config, &out_n_features, &out_features,
                            &out_dim, &out_shape, &out_scores);
  if (result == 0) {
    ERL_NIF_TERM feature_arr[out_n_features];
    for (bst_ulong i = 0; i < out_n_features; ++i) {
      ERL_NIF_TERM shape_arr[out_dim];
      for (bst_ulong j = 0; j < out_dim; ++j) {
        shape_arr[j] = enif_make_int(env, out_shape[i * out_dim + j]);
      }
      ERL_NIF_TERM shape = enif_make_list_from_array(env, shape_arr, out_dim);
      ERL_NIF_TERM scores = enif_make_double(env, out_scores[i]);
      ERL_NIF_TERM feature =
          enif_make_string(env, out_features[i], ERL_NIF_LATIN1);
      ERL_NIF_TERM tuple[3] = {feature, shape, scores};
      feature_arr[i] = enif_make_tuple_from_array(env, tuple, 3);
    }
    ret = exg_ok(env,
                 enif_make_list_from_array(env, feature_arr, out_n_features));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

static ERL_NIF_TERM collect_prediction_results(ErlNifEnv *env,
                                               bst_ulong *out_shape,
                                               bst_ulong out_dim,
                                               float *out_result) {
  bst_ulong out_len = 1;
  ERL_NIF_TERM shape_arr[out_dim];
  for (bst_ulong j = 0; j < out_dim; ++j) {
    shape_arr[j] = enif_make_int(env, out_shape[j]);
    out_len *= out_shape[j];
  }
  ERL_NIF_TERM shape = enif_make_tuple_from_array(env, shape_arr, out_dim);
  ERL_NIF_TERM result_arr[out_len];
  for (bst_ulong i = 0; i < out_len; ++i) {
    result_arr[i] = enif_make_double(env, out_result[i]);
  }
  return exg_ok(env, enif_make_tuple2(
                         env, shape,
                         enif_make_list_from_array(env, result_arr, out_len)));
}

ERL_NIF_TERM EXGBoosterPredictFromDMatrix(ErlNifEnv *env, int argc,
                                          const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  DMatrixHandle dmatrix;
  DMatrixHandle **dmatrix_resource = NULL;
  char *config = NULL;
  bst_ulong *out_shape = NULL;
  bst_ulong out_dim = 0;
  float *out_result = NULL;

  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (3 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  if (!enif_get_resource(env, argv[1], DMatrix_RESOURCE_TYPE,
                         (void *)&(dmatrix_resource))) {
    ret = exg_error(env, "Invalid DMatrix");
    goto END;
  }
  if (!exg_get_string(env, argv[2], &config)) {
    ret = exg_error(env, "Config must be a JSON-encoded string");
    goto END;
  }
  booster = *booster_resource;
  dmatrix = *dmatrix_resource;
  result = XGBoosterPredictFromDMatrix(booster, dmatrix, config, &out_shape,
                                       &out_dim, &out_result);
  if (result == 0) {
    ret = collect_prediction_results(env, out_shape, out_dim, out_result);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (config != NULL) {
    enif_free(config);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterPredictFromDense(ErlNifEnv *env, int argc,
                                        const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  DMatrixHandle proxy;
  DMatrixHandle **proxy_resource = NULL;
  char *values = NULL;
  char *config = NULL;
  bst_ulong *out_shape = NULL;
  bst_ulong out_dim = 0;
  float *out_result = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  if (4 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &values)) {
    ret = exg_error(env, "Value must be a JSON-encoded string");
    goto END;
  }
  if (!exg_get_string(env, argv[2], &config)) {
    ret = exg_error(env, "Config must be a JSON-encoded string");
    goto END;
  }
  if (!enif_get_resource(env, argv[3], DMatrix_RESOURCE_TYPE,
                         (void *)&(proxy_resource))) {
    proxy = NULL;
  } else {
    proxy = *proxy_resource;
  }
  booster = *booster_resource;
  result = XGBoosterPredictFromDense(booster, values, config, proxy, &out_shape,
                                     &out_dim, &out_result);
  if (result == 0) {
    ret = collect_prediction_results(env, out_shape, out_dim, out_result);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (config != NULL) {
    enif_free(config);
  }
  if (values != NULL) {
    enif_free(values);
  }
  return ret;
}
ERL_NIF_TERM EXGBoosterPredictFromCSR(ErlNifEnv *env, int argc,
                                      const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  DMatrixHandle proxy;
  DMatrixHandle **proxy_resource = NULL;
  char *indptr = NULL;
  char *indices = NULL;
  char *data = NULL;
  char *config = NULL;
  bst_ulong ncols = 0;
  bst_ulong *out_shape = NULL;
  bst_ulong out_dim = 0;
  float *out_result = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  if (7 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &indptr)) {
    ret = exg_error(env, "Indptr must be a JSON-encoded string");
    goto END;
  }
  if (!exg_get_string(env, argv[2], &indices)) {
    ret = exg_error(env, "Indices must be a JSON-encoded string");
    goto END;
  }
  if (!exg_get_string(env, argv[3], &data)) {
    ret = exg_error(env, "Data must be a JSON-encoded string");
    goto END;
  }
  if (!enif_get_int(env, argv[4], &ncols)) {
    ret = exg_error(env, "Ncols must be an integer");
    goto END;
  }
  if (!exg_get_string(env, argv[5], &config)) {
    ret = exg_error(env, "Config must be a JSON-encoded string");
    goto END;
  }
  if (!enif_get_resource(env, argv[6], DMatrix_RESOURCE_TYPE,
                         (void *)&(proxy_resource))) {
    proxy = NULL;
  } else {
    proxy = *proxy_resource;
  }
  booster = *booster_resource;
  result =
      XGBoosterPredictFromCSR(booster, indptr, indices, data, ncols, config,
                              proxy, &out_shape, &out_dim, &out_result);
  if (result == 0) {
    ret = collect_prediction_results(env, out_shape, out_dim, out_result);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (config != NULL) {
    enif_free(config);
  }
  if (indptr != NULL) {
    enif_free(indptr);
  }
  if (indices != NULL) {
    enif_free(indices);
  }
  if (data != NULL) {
    enif_free(data);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterLoadModel(ErlNifEnv *env, int argc,
                                 const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  char *fname = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!exg_get_string(env, argv[0], &fname)) {
    ret = exg_error(env, "Fname must be a string representing a file path");
    goto END;
  }
  result = XGBoosterCreate(NULL, 0, &booster);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }
  result = XGBoosterLoadModel(booster, fname);
  if (result == 0) {
    ret = make_Booster_resource(env, booster);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (fname != NULL) {
    enif_free(fname);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterSaveModel(ErlNifEnv *env, int argc,
                                 const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  char *fname = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  if (2 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &fname)) {
    ret = exg_error(env, "Fname must be a string representing a file path");
    goto END;
  }
  booster = *booster_resource;
  result = XGBoosterSaveModel(booster, fname);
  if (result == 0) {
    ret = ok_atom(env);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (fname != NULL) {
    enif_free(fname);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterSerializeToBuffer(ErlNifEnv *env, int argc,
                                         const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  bst_ulong out_len = 0;
  char *out_buf = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  ErlNifBinary out_bin;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  result = XGBoosterSerializeToBuffer(booster, &out_len, &out_buf);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }
  if (!enif_alloc_binary(out_len, &out_bin)) {
    ret = exg_error(env, "Failed to allocate binary");
    goto END;
  }
  memcpy(out_bin.data, out_buf, out_len);
  ret = exg_ok(env, enif_make_binary(env, &out_bin));
END:
  return ret;
}
ERL_NIF_TERM EXGBoosterDeserializeFromBuffer(ErlNifEnv *env, int argc,
                                             const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  char *buf = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  ErlNifBinary bin;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[0], &bin)) {
    ret = exg_error(env, "Buf must be a binary");
    goto END;
  }
  buf = (char *)enif_alloc(bin.size + 1);
  memcpy(buf, bin.data, bin.size);
  result = XGBoosterCreate(NULL, 0, &booster);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }
  result = XGBoosterUnserializeFromBuffer(booster, buf, bin.size);
  if (result == 0) {
    ret = make_Booster_resource(env, booster);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (buf != NULL) {
    enif_free(buf);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterLoadModelFromBuffer(ErlNifEnv *env, int argc,
                                           const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  char *buf = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  ErlNifBinary bin;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[0], &bin)) {
    ret = exg_error(env, "Buf must be a binary");
    goto END;
  }
  buf = (char *)enif_alloc(bin.size + 1);
  memcpy(buf, bin.data, bin.size);
  result = XGBoosterCreate(NULL, 0, &booster);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }
  result = XGBoosterLoadModelFromBuffer(booster, buf, bin.size);
  if (result == 0) {
    ret = make_Booster_resource(env, booster);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (buf != NULL) {
    enif_free(buf);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterSaveModelToBuffer(ErlNifEnv *env, int argc,
                                        const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  bst_ulong out_len = 0;
  char *out_buf = NULL;
  char *config = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  ErlNifBinary out_bin;
  if (2 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &config)) {
    ret = exg_error(env, "Invalid config -- config should be a JSON-encoded string");
    goto END;
  }
  booster = *booster_resource;
  result = XGBoosterSaveModelToBuffer(booster, config, &out_len, &out_buf);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }
  if (!enif_alloc_binary(out_len, &out_bin)) {
    ret = exg_error(env, "Failed to allocate binary");
    goto END;
  }
  memcpy(out_bin.data, out_buf, out_len);
  ret = exg_ok(env, enif_make_binary(env, &out_bin));
END:
  if (config != NULL) {
    enif_free(config);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterSaveJsonConfig(ErlNifEnv *env, int argc,
                                      const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  bst_ulong out_len = 0;
  char *out_buf = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  ErlNifBinary out_bin;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  result = XGBoosterSaveJsonConfig(booster, &out_len, &out_buf);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }
  if (!enif_alloc_binary(out_len, &out_bin)) {
    ret = exg_error(env, "Failed to allocate binary");
    goto END;
  }
  memcpy(out_bin.data, out_buf, out_len);
  ret = exg_ok(env, enif_make_binary(env, &out_bin));
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterLoadJsonConfig(ErlNifEnv *env, int argc,
                                      const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  char *buf = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  ErlNifBinary bin;
  if (2 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE,
                         (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[1], &bin)) {
    ret = exg_error(env, "Buf must be a binary");
    goto END;
  }
  buf = (char *)enif_alloc(bin.size + 1);
  memcpy(buf, bin.data, bin.size);
  booster = *booster_resource;
  result = XGBoosterLoadJsonConfig(booster, buf);
  if (result == 0) {
    ret = ok_atom(env);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (buf != NULL) {
    enif_free(buf);
  }
  return ret;
}