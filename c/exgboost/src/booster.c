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
  if (!enif_get_list_length(env, argv[0], &dmats_len)) {
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
  ERL_NIF_TERM head, tail, term;
  term = argv[0];
  int i = 0;
  dmats = (DMatrixHandle *)enif_alloc(dmats_len * sizeof(DMatrixHandle));
  if (NULL == dmats) {
    ret = exg_error(env, "Failed to allocate memory for DMatrixHandle");
    goto END;
  }
  while (enif_get_list_cell(env, term, &head, &tail)) {
    DMatrixHandle **resource = NULL;
    if (!enif_get_resource(env, head, DMatrix_RESOURCE_TYPE,
                           (void *)&(resource))) {
      ret = exg_error(env, "Invalid DMatrix");
      goto ERROR;
    }
    dmats[i] = *resource;
    term = tail;
    i++;
  }
  result = XGBoosterCreate(dmats, dmats_len, &booster);
  if (result == 0) {
    ret = make_Booster_resource(env, booster);
    goto END;
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
ERROR:
  enif_free(dmats);
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
  if (!enif_get_atom(env, argv[1], name, sizeof(name), ERL_NIF_LATIN1)) {
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