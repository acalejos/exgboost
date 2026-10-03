#include "booster.h"

#include <limits.h>

static ERL_NIF_TERM make_Booster_resource(ErlNifEnv *env, BoosterHandle handle) {
  ERL_NIF_TERM ret = -1;
  BoosterHandle **resource = enif_alloc_resource(Booster_RESOURCE_TYPE, sizeof(BoosterHandle *));
  if (resource != NULL) {
    *resource = handle;
    // BEAM resource now owns the handle and releases it in resource cleanup.
    ret = exg_ok(env, enif_make_resource(env, resource));
    enif_release_resource(resource);
  } else {
    ret = exg_error(env, "Failed to allocate memory for XGBoost DMatrix");
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterCreate(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
  // exg_get_dmatrix_list allocates this temporary array.
  exg_free_dmatrix_list(dmats);
  return ret;
}

ERL_NIF_TERM EXGBoosterSlice(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(resource))) {
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
  result = XGBoosterSlice(in_booster, begin_layer, end_layer, step, &out_booster);
  if (result == 0) {
    ret = make_Booster_resource(env, out_booster);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterBoostedRounds(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **resource = NULL;
  int rounds;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(resource))) {
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

ERL_NIF_TERM EXGBoosterSetParam(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(resource))) {
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
  // XGBoost consumes name/value during this call; no ownership transfer.
  result = XGBoosterSetParam(booster, name, value);
  if (result == 0) {
    ret = enif_make_atom(env, "ok");
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (name != NULL) {
    enif_free(name);
  }
  if (value != NULL) {
    enif_free(value);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterGetNumFeature(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **resource = NULL;
  bst_ulong num_feature;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *resource;
  result = XGBoosterGetNumFeature(booster, &num_feature);
  if (result == 0) {
    ret = exg_ok(env, enif_make_uint64(env, (ErlNifUInt64)num_feature));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterUpdateOneIter(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  if (!enif_get_resource(env, argv[1], DMatrix_RESOURCE_TYPE, (void *)&(dtrain_resource))) {
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

ERL_NIF_TERM EXGBoosterTrainOneIter(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  DMatrixHandle dtrain;
  DMatrixHandle **dtrain_resource = NULL;
  ERL_NIF_TERM grad_binary, grad_typestr, grad_shape, grad_readonly;
  ERL_NIF_TERM hess_binary, hess_typestr, hess_shape, hess_readonly;
  char *grad = NULL;
  char *hess = NULL;
  const char *error_msg = NULL;
  int iteration = 0;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (4 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  if (!enif_get_resource(env, argv[1], DMatrix_RESOURCE_TYPE, (void *)&(dtrain_resource))) {
    ret = exg_error(env, "Invalid DMatrix");
    goto END;
  }
  dtrain = *dtrain_resource;

  if (!exg_get_array_interface_tuple(env, argv[2], &grad_binary, &grad_typestr, &grad_shape,
                                     &grad_readonly, &error_msg)) {
    ret = exg_error(env, error_msg);
    goto END;
  }
  if (!exg_build_array_interface_json(env, grad_binary, grad_typestr, grad_shape, grad_readonly,
                                      &grad, &error_msg)) {
    ret = exg_error(env, error_msg);
    goto END;
  }

  if (!exg_get_array_interface_tuple(env, argv[3], &hess_binary, &hess_typestr, &hess_shape,
                                     &hess_readonly, &error_msg)) {
    ret = exg_error(env, error_msg);
    goto END;
  }
  if (!exg_build_array_interface_json(env, hess_binary, hess_typestr, hess_shape, hess_readonly,
                                      &hess, &error_msg)) {
    ret = exg_error(env, error_msg);
    goto END;
  }

  result = XGBoosterBoostedRounds(booster, &iteration);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }

  result = XGBoosterTrainOneIter(booster, dtrain, iteration, grad, hess);
  if (result == 0) {
    ret = ok_atom(env);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (grad != NULL) {
    enif_free(grad);
  }
  if (hess != NULL) {
    enif_free(hess);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterEvalOneIter(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  DMatrixHandle *dmats = NULL;
  char **evnames = NULL;
  int iter = -1;
  unsigned num_dmats = 0;
  unsigned num_evnames = 0;
  const char *out = NULL;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (4 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
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
  result = XGBoosterEvalOneIter(booster, iter, dmats, (const char **)evnames, (bst_ulong)num_dmats,
                                &out);
  if (result == 0) {
    ret = exg_ok(env, enif_make_string(env, out, ERL_NIF_LATIN1));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  // Helper-allocated arrays must be reclaimed on all paths.
  exg_free_dmatrix_list(dmats);
  exg_free_string_list(evnames, num_evnames);
  return ret;
}

ERL_NIF_TERM EXGBoosterGetAttr(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  char *key = NULL;
  const char *out = NULL;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  int success = -1;
  if (2 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
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
  if (key != NULL) {
    enif_free(key);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterSetAttr(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
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
  if (key != NULL) {
    enif_free(key);
  }
  if (value != NULL) {
    enif_free(value);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterGetAttrNames(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  const char **out = NULL;
  bst_ulong out_len = 0;
  ERL_NIF_TERM *arr = NULL;
  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }

  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }

  booster = *booster_resource;
  result = XGBoosterGetAttrNames(booster, &out_len, &out);
  if (result == 0) {
    if (out_len > UINT_MAX || out_len > SIZE_MAX / sizeof(*arr)) {
      ret = exg_error(env, "Result is too large");
      goto END;
    }

    if (out_len != 0) {
      arr = enif_alloc((size_t)out_len * sizeof(*arr));

      if (arr == NULL) {
        ret = exg_error(env, "Failed to allocate result");
        goto END;
      }

      for (bst_ulong i = 0; i < out_len; ++i) {
        arr[i] = enif_make_string(env, out[i], ERL_NIF_LATIN1);
      }
    }

    ERL_NIF_TERM list = out_len == 0 ? enif_make_list(env, 0)
                                     : enif_make_list_from_array(env, arr, (unsigned)out_len);

    ret = exg_ok(env, list);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }

END:
  if (arr != NULL) {
    enif_free(arr);
  }

  return ret;
}

ERL_NIF_TERM EXGBoosterSetStrFeatureInfo(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&resource)) {
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
  if (strcmp(field, "feature_type") != 0 && strcmp(field, "feature_name") != 0) {
    ret = exg_error(env, "Field must be in ['feature_type', 'feature_name']");
    goto END;
  }
  handle = *resource;
  result = XGBoosterSetStrFeatureInfo(handle, field, (const char **)features, num_features);
  if (result == 0) {
    ret = ok_atom(env);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (features != NULL) {
    exg_free_string_list(features, num_features);
  }
  if (field != NULL) {
    enif_free(field);
  }
  return ret;
}
ERL_NIF_TERM EXGBoosterGetStrFeatureInfo(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle handle;
  BoosterHandle **resource = NULL;
  char const **c_out_features = NULL;
  bst_ulong out_len = 0;
  char *field = NULL;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  ERL_NIF_TERM *arr = NULL;

  if (argc != 2) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }

  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "Booster must be a resource");
    goto END;
  }

  if (!exg_get_string(env, argv[1], &field)) {
    ret = exg_error(env, "Field must be a string");
    goto END;
  }

  if (strcmp(field, "feature_type") != 0 && strcmp(field, "feature_name") != 0) {
    ret = exg_error(env, "Field must be in ['feature_type', 'feature_name']");
    goto END;
  }

  handle = *resource;
  result = XGBoosterGetStrFeatureInfo(handle, field, &out_len, &c_out_features);

  if (result == 0) {
    if (out_len > UINT_MAX || out_len > SIZE_MAX / sizeof(*arr)) {
      ret = exg_error(env, "Result is too large");
      goto END;
    }

    if (out_len != 0) {
      arr = enif_alloc((size_t)out_len * sizeof(*arr));

      if (arr == NULL) {
        ret = exg_error(env, "Failed to allocate result");
        goto END;
      }

      for (bst_ulong i = 0; i < out_len; ++i) {
        arr[i] = enif_make_string(env, c_out_features[i], ERL_NIF_LATIN1);
      }
    }

    ERL_NIF_TERM list = out_len == 0 ? enif_make_list(env, 0)
                                     : enif_make_list_from_array(env, arr, (unsigned)out_len);

    ret = exg_ok(env, list);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (field != NULL) {
    enif_free(field);
  }
  if (arr != NULL) {
    enif_free(arr);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterFeatureScore(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  char *config = NULL;

  bst_ulong out_n_features = 0;
  const char **out_features = NULL;
  bst_ulong out_dim = 0;
  const bst_ulong *out_shape = NULL;
  const float *out_scores = NULL;

  ERL_NIF_TERM *feature_terms = NULL;
  ERL_NIF_TERM *shape_terms = NULL;
  ERL_NIF_TERM *score_terms = NULL;

  ERL_NIF_TERM ret = 0;
  int result = -1;

  if (argc != 2) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }

  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void **)&booster_resource)) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }

  if (!exg_get_string(env, argv[1], &config)) {
    ret = exg_error(env, "Config must be a JSON-encoded string");
    goto END;
  }

  booster = *booster_resource;

  result = XGBoosterFeatureScore(booster, config, &out_n_features, &out_features, &out_dim,
                                 &out_shape, &out_scores);

  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }

  /*
   * XGBoost returns:
   *
   *   out_features: out_n_features strings
   *   out_shape:    out_dim dimensions
   *   out_scores:   product(out_shape) floats
   */

  if (out_dim == 0) {
    ret = exg_error(env, "XGBoost returned an empty feature-score shape");
    goto END;
  }

  if (out_shape == NULL) {
    ret = exg_error(env, "XGBoost returned a NULL feature-score shape");
    goto END;
  }

  if (out_n_features != 0 && out_features == NULL) {
    ret = exg_error(env, "XGBoost returned NULL feature names");
    goto END;
  }

  /*
   * These Erlang NIF APIs take unsigned lengths.
   */
  if (out_n_features > UINT_MAX) {
    ret = exg_error(env, "Too many feature names");
    goto END;
  }

  if (out_dim > UINT_MAX) {
    ret = exg_error(env, "Feature-score rank is too large");
    goto END;
  }

  /*
   * For XGBoosterFeatureScore, the first score dimension represents
   * the features listed in out_features.
   */
  if (out_shape[0] != out_n_features) {
    ret = exg_error(env, "Feature-score shape does not match feature-name count");
    goto END;
  }

  /*
   * Calculate the flattened score count with overflow protection.
   */
  size_t score_count = 1;

  for (bst_ulong i = 0; i < out_dim; ++i) {
    bst_ulong dim_arg = out_shape[i];

    if (dim_arg > SIZE_MAX) {
      ret = exg_error(env, "Feature-score dimension is too large");
      goto END;
    }

    size_t dim = (size_t)dim_arg;

    if (dim != 0 && score_count > SIZE_MAX / dim) {
      ret = exg_error(env, "Feature-score shape overflows");
      goto END;
    }

    score_count *= dim;
  }

  if (score_count > UINT_MAX) {
    ret = exg_error(env, "Too many feature scores");
    goto END;
  }

  if (score_count != 0 && out_scores == NULL) {
    ret = exg_error(env, "XGBoost returned NULL feature scores");
    goto END;
  }

  /*
   * Allocate feature-name terms on the heap instead of using a VLA.
   */
  if (out_n_features != 0) {
    if (out_n_features > SIZE_MAX / sizeof(*feature_terms)) {
      ret = exg_error(env, "Feature-name allocation overflows");
      goto END;
    }

    feature_terms = enif_alloc((size_t)out_n_features * sizeof(*feature_terms));

    if (feature_terms == NULL) {
      ret = exg_error(env, "Failed to allocate feature names");
      goto END;
    }

    for (bst_ulong i = 0; i < out_n_features; ++i) {
      if (out_features[i] == NULL) {
        ret = exg_error(env, "XGBoost returned a NULL feature name");
        goto END;
      }

      feature_terms[i] = enif_make_string(env, out_features[i], ERL_NIF_LATIN1);
    }
  }

  /*
   * Copy the shape into BEAM terms.
   */
  if (out_dim > SIZE_MAX / sizeof(*shape_terms)) {
    ret = exg_error(env, "Feature-score shape allocation overflows");
    goto END;
  }

  shape_terms = enif_alloc((size_t)out_dim * sizeof(*shape_terms));

  if (shape_terms == NULL) {
    ret = exg_error(env, "Failed to allocate feature-score shape");
    goto END;
  }

  for (bst_ulong i = 0; i < out_dim; ++i) {
    shape_terms[i] = enif_make_uint64(env, (ErlNifUInt64)out_shape[i]);
  }

  /*
   * Copy all scores into BEAM terms.
   */
  if (score_count != 0) {
    if (score_count > SIZE_MAX / sizeof(*score_terms)) {
      ret = exg_error(env, "Feature-score allocation overflows");
      goto END;
    }

    score_terms = enif_alloc(score_count * sizeof(*score_terms));

    if (score_terms == NULL) {
      ret = exg_error(env, "Failed to allocate feature scores");
      goto END;
    }

    for (size_t i = 0; i < score_count; ++i) {
      score_terms[i] = enif_make_double(env, out_scores[i]);
    }
  }

  ERL_NIF_TERM features =
      out_n_features == 0 ? enif_make_list(env, 0)
                          : enif_make_list_from_array(env, feature_terms, (unsigned)out_n_features);

  ERL_NIF_TERM shape = enif_make_tuple_from_array(env, shape_terms, (unsigned)out_dim);

  ERL_NIF_TERM scores = score_count == 0
                            ? enif_make_list(env, 0)
                            : enif_make_list_from_array(env, score_terms, (unsigned)score_count);

  ret = exg_ok(env, enif_make_tuple3(env, features, shape, scores));

END:
  if (feature_terms != NULL) {
    enif_free(feature_terms);
  }

  if (shape_terms != NULL) {
    enif_free(shape_terms);
  }

  if (score_terms != NULL) {
    enif_free(score_terms);
  }

  if (config != NULL) {
    enif_free(config);
  }

  return ret;
}

static ERL_NIF_TERM collect_prediction_results(ErlNifEnv *env, const bst_ulong *out_shape,
                                               bst_ulong out_dim, const float *out_result) {
  ERL_NIF_TERM ret = 0;
  ERL_NIF_TERM *shape_terms = NULL;
  ERL_NIF_TERM *result_terms = NULL;
  size_t result_len = 1;

  if (out_shape == NULL) {
    return exg_error(env, "Prediction shape is NULL");
  }

  if (out_dim == 0) {
    return exg_error(env, "Prediction shape is empty");
  }

  /*
   * enif_make_tuple_from_array() takes an unsigned count.
   */
  if (out_dim > UINT_MAX || out_dim > SIZE_MAX / sizeof(*shape_terms)) {
    return exg_error(env, "Prediction dimension is too large");
  }

  shape_terms = enif_alloc((size_t)out_dim * sizeof(*shape_terms));

  if (shape_terms == NULL) {
    return exg_error(env, "Failed to allocate prediction shape");
  }

  for (bst_ulong i = 0; i < out_dim; ++i) {
    bst_ulong dim_arg = out_shape[i];

    if (dim_arg > SIZE_MAX) {
      ret = exg_error(env, "Prediction dimension is too large");
      goto END;
    }

    size_t dim = (size_t)dim_arg;

    if (dim != 0 && result_len > SIZE_MAX / dim) {
      ret = exg_error(env, "Prediction shape overflows");
      goto END;
    }

    result_len *= dim;

    shape_terms[i] = enif_make_uint64(env, (ErlNifUInt64)dim_arg);
  }

  /*
   * enif_make_list_from_array() also takes an unsigned count.
   */
  if (result_len > UINT_MAX || result_len > SIZE_MAX / sizeof(*result_terms)) {
    ret = exg_error(env, "Prediction result is too large");
    goto END;
  }

  if (result_len != 0 && out_result == NULL) {
    ret = exg_error(env, "Prediction result is NULL");
    goto END;
  }

  if (result_len != 0) {
    result_terms = enif_alloc(result_len * sizeof(*result_terms));

    if (result_terms == NULL) {
      ret = exg_error(env, "Failed to allocate prediction result");
      goto END;
    }

    for (size_t i = 0; i < result_len; ++i) {
      result_terms[i] = enif_make_double(env, out_result[i]);
    }
  }

  ERL_NIF_TERM shape = enif_make_tuple_from_array(env, shape_terms, (unsigned)out_dim);

  ERL_NIF_TERM results = result_len == 0
                             ? enif_make_list(env, 0)
                             : enif_make_list_from_array(env, result_terms, (unsigned)result_len);

  ret = exg_ok(env, enif_make_tuple2(env, shape, results));

END:
  if (shape_terms != NULL) {
    enif_free(shape_terms);
  }

  if (result_terms != NULL) {
    enif_free(result_terms);
  }

  return ret;
}

ERL_NIF_TERM EXGBoosterPredictFromDMatrix(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  DMatrixHandle dmatrix;
  DMatrixHandle **dmatrix_resource = NULL;
  char *config = NULL;
  const bst_ulong *out_shape = NULL;
  bst_ulong out_dim = 0;
  const float *out_result = NULL;

  ERL_NIF_TERM ret = -1;
  int result = -1;
  if (3 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  if (!enif_get_resource(env, argv[1], DMatrix_RESOURCE_TYPE, (void *)&(dmatrix_resource))) {
    ret = exg_error(env, "Invalid DMatrix");
    goto END;
  }
  if (!exg_get_string(env, argv[2], &config)) {
    ret = exg_error(env, "Config must be a JSON-encoded string");
    goto END;
  }
  booster = *booster_resource;
  dmatrix = *dmatrix_resource;
  result = XGBoosterPredictFromDMatrix(booster, dmatrix, config, &out_shape, &out_dim, &out_result);
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

ERL_NIF_TERM EXGBoosterPredictFromDense(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  DMatrixHandle proxy;
  DMatrixHandle **proxy_resource = NULL;
  char *values = NULL;
  const char *error_msg = NULL;
  char *config = NULL;
  const bst_ulong *out_shape = NULL;
  bst_ulong out_dim = 0;
  const float *out_result = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;

  if (argc != 7) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }

  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }

  // Build ArrayInterface JSON from components: (binary, typestr, shape, readonly)
  if (!exg_build_array_interface_json(env, argv[1], argv[2], argv[3], argv[4], &values,
                                      &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to extract ArrayInterface");
    goto END;
  }

  if (!exg_get_string(env, argv[5], &config)) {
    ret = exg_error(env, "Config must be a JSON-encoded string");
    goto END;
  }

  if (!enif_get_resource(env, argv[6], DMatrix_RESOURCE_TYPE, (void *)&(proxy_resource))) {
    proxy = NULL;
  } else {
    proxy = *proxy_resource;
  }
  booster = *booster_resource;
  result =
      XGBoosterPredictFromDense(booster, values, config, proxy, &out_shape, &out_dim, &out_result);
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

ERL_NIF_TERM EXGBoosterPredictFromCSR(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  DMatrixHandle proxy;
  DMatrixHandle **proxy_resource = NULL;
  char *indptr = NULL;
  char *indices = NULL;
  char *data = NULL;
  const char *error_msg = NULL;
  char *config = NULL;
  bst_ulong ncols = 0;
  ErlNifUInt64 ncols_arg = 0;
  const bst_ulong *out_shape = NULL;
  bst_ulong out_dim = 0;
  const float *out_result = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;

  if (argc != 16) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }

  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }

  // Build ArrayInterface JSON for each sparse array from components
  if (!exg_build_array_interface_json(env, argv[1], argv[2], argv[3], argv[4], &indptr,
                                      &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to extract indptr ArrayInterface");
    goto END;
  }

  if (!exg_build_array_interface_json(env, argv[5], argv[6], argv[7], argv[8], &indices,
                                      &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to extract indices ArrayInterface");
    goto END;
  }

  if (!exg_build_array_interface_json(env, argv[9], argv[10], argv[11], argv[12], &data,
                                      &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to extract data ArrayInterface");
    goto END;
  }

  if (!enif_get_uint64(env, argv[13], &ncols_arg)) {
    ret = exg_error(env, "Ncols must be a non-negative integer");
    goto END;
  }

  if (ncols_arg == 0) {
    ret = exg_error(env, "Ncols must be greater than zero");
    goto END;
  }

  ncols = (bst_ulong)ncols_arg;

  if (!exg_get_string(env, argv[14], &config)) {
    ret = exg_error(env, "Config must be a JSON-encoded string");
    goto END;
  }

  if (!enif_get_resource(env, argv[15], DMatrix_RESOURCE_TYPE, (void *)&(proxy_resource))) {
    proxy = NULL;
  } else {
    proxy = *proxy_resource;
  }
  booster = *booster_resource;
  result = XGBoosterPredictFromCSR(booster, indptr, indices, data, ncols, config, proxy, &out_shape,
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

ERL_NIF_TERM EXGBoosterLoadModel(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
    XGBoosterFree(booster);
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (fname != NULL) {
    enif_free(fname);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterSaveModel(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  char *fname = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  if (2 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
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

ERL_NIF_TERM EXGBoosterSerializeToBuffer(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  bst_ulong out_len = 0;
  const char *out_buf = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  result = XGBoosterSerializeToBuffer(booster, &out_len, &out_buf);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }

  // Use enif_make_new_binary for cleaner memory management
  ERL_NIF_TERM binary_term;
  unsigned char *dest = enif_make_new_binary(env, out_len, &binary_term);
  if (dest == NULL && out_len != 0) {
    ret = exg_error(env, "Failed to allocate binary");
    goto END;
  }
  if (out_len > 0) {
    memcpy(dest, out_buf, out_len);
  }
  ret = exg_ok(env, binary_term);
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterDeserializeFromBuffer(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
    XGBoosterFree(booster);
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (buf != NULL) {
    enif_free(buf);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterLoadModelFromBuffer(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
    XGBoosterFree(booster);
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (buf != NULL) {
    enif_free(buf);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterSaveModelToBuffer(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  bst_ulong out_len = 0;
  const char *out_buf = NULL;
  char *config = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  if (2 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
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

  // Use enif_make_new_binary for cleaner memory management
  ERL_NIF_TERM binary_term;
  unsigned char *dest = enif_make_new_binary(env, out_len, &binary_term);
  if (dest == NULL && out_len != 0) {
    ret = exg_error(env, "Failed to allocate binary");
    goto END;
  }
  if (out_len > 0) {
    memcpy(dest, out_buf, out_len);
  }
  ret = exg_ok(env, binary_term);
END:
  if (config != NULL) {
    enif_free(config);
  }
  return ret;
}

ERL_NIF_TERM EXGBoosterSaveJsonConfig(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  bst_ulong out_len = 0;
  const char *out_buf = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  if (1 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  booster = *booster_resource;
  result = XGBoosterSaveJsonConfig(booster, &out_len, &out_buf);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }

  // Use enif_make_new_binary for cleaner memory management
  ERL_NIF_TERM binary_term;
  unsigned char *dest = enif_make_new_binary(env, out_len, &binary_term);
  if (dest == NULL && out_len != 0) {
    ret = exg_error(env, "Failed to allocate binary");
    goto END;
  }
  if (out_len > 0) {
    memcpy(dest, out_buf, out_len);
  }
  ret = exg_ok(env, binary_term);
END:
  return ret;
}

ERL_NIF_TERM EXGBoosterLoadJsonConfig(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
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

ERL_NIF_TERM EXGBoosterDumpModelEx(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  BoosterHandle booster;
  BoosterHandle **booster_resource = NULL;
  bst_ulong out_len = 0;
  const char **out_dump_array = NULL;
  char *fmap = NULL;
  int with_stats = 0;
  char *format = NULL;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  if (4 != argc) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], Booster_RESOURCE_TYPE, (void *)&(booster_resource))) {
    ret = exg_error(env, "Invalid Booster");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &fmap)) {
    ret = exg_error(env, "Invalid fmap -- should be a string");
    goto END;
  }
  if (!enif_get_int(env, argv[2], &with_stats)) {
    ret = exg_error(env, "Invalid with_stats -- should be an int");
    goto END;
  }
  if (!exg_get_string(env, argv[3], &format)) {
    ret = exg_error(env, "Invalid format -- should be a string");
    goto END;
  }
  booster = *booster_resource;
  result = XGBoosterDumpModelEx(booster, fmap, with_stats, format, &out_len, &out_dump_array);
  if (result == 0) {
    ERL_NIF_TERM arr[out_len];
    for (bst_ulong i = 0; i < out_len; ++i) {
      arr[i] = enif_make_string(env, out_dump_array[i], ERL_NIF_LATIN1);
    }
    ret = exg_ok(env, enif_make_list_from_array(env, arr, out_len));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (fmap != NULL) {
    enif_free(fmap);
  }
  if (format != NULL) {
    enif_free(format);
  }
  return ret;
}
