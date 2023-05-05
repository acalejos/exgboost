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