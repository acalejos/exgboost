#include "utils.h"

// Atoms
ERL_NIF_TERM exg_error(ErlNifEnv *env, const char *msg) {
  ERL_NIF_TERM atom = enif_make_atom(env, "error");
  ERL_NIF_TERM msg_term = enif_make_string(env, msg, ERL_NIF_LATIN1);
  return enif_make_tuple2(env, atom, msg_term);
}

ERL_NIF_TERM ok_atom(ErlNifEnv *env) { return enif_make_atom(env, "ok"); }

ERL_NIF_TERM exg_ok(ErlNifEnv *env, ERL_NIF_TERM term) {
  return enif_make_tuple2(env, ok_atom(env), term);
}

// Resource type helpers
void DMatrix_RESOURCE_TYPE_cleanup(ErlNifEnv *env, void *arg) {
  DMatrixHandle handle = *((DMatrixHandle *)arg);
  XGDMatrixFree(handle);
}

void Booster_RESOURCE_TYPE_cleanup(ErlNifEnv *env, void *arg) {
  BoosterHandle handle = *((BoosterHandle *)arg);
  XGBoosterFree(handle);
}

// Argument helpers
int exg_get_string(ErlNifEnv *env, ERL_NIF_TERM term, char **var) {
  unsigned len;
  int ret = enif_get_list_length(env, term, &len);

  if (!ret) {
    ErlNifBinary bin;
    ret = enif_inspect_binary(env, term, &bin);
    if (!ret) {
      return 0;
    }
    *var = (char *)enif_alloc(bin.size + 1);
    strncpy(*var, (const char *)bin.data, bin.size);
    (*var)[bin.size] = '\0';
    return ret;
  }

  *var = (char *)enif_alloc(len + 1);
  ret = enif_get_string(env, term, *var, len + 1, ERL_NIF_LATIN1);

  if (ret > 0) {
    (*var)[ret - 1] = '\0';
  } else if (ret == 0) {
    (*var)[0] = '\0';
  }

  return ret;
}

int exg_get_list(ErlNifEnv *env, ERL_NIF_TERM term, double **out) {
  ERL_NIF_TERM head, tail;
  unsigned len = 0;
  int i = 0;
  if (!enif_get_list_length(env, term, &len)) {
    return 0;
  }
  *out = (double *)enif_alloc(len * sizeof(double));
  if (out == NULL) {
    return 0;
  }
  while (enif_get_list_cell(env, term, &head, &tail)) {
    int ret = enif_get_double(env, head, &((*out)[i]));
    if (!ret) {
      return 0;
    }
    term = tail;
    i++;
  }
  return 1;
}

int exg_get_string_list(ErlNifEnv *env, ERL_NIF_TERM term, char ***out,
                        unsigned *len) {
  ERL_NIF_TERM head, tail;
  int i = 0;
  if (!enif_get_list_length(env, term, len)) {
    return 0;
  }
  *out = (char **)enif_alloc(*len * sizeof(char *));
  if (*out == NULL) {
    return 0;
  }
  while (enif_get_list_cell(env, term, &head, &tail)) {
    int ret = exg_get_string(env, head, &((*out)[i]));
    if (!ret) {
      return 0;
    }
    term = tail;
    i++;
  }
  return 1;
}

int exg_get_dmatrix_list(ErlNifEnv *env, ERL_NIF_TERM term,
                         DMatrixHandle **dmats, unsigned *len) {
  ERL_NIF_TERM head, tail;
  int i = 0;
  if (!enif_get_list_length(env, term, len)) {
    return 0;
  }
  *dmats = (DMatrixHandle *)enif_alloc(*len * sizeof(DMatrixHandle));
  if (NULL == dmats) {
    return 0;
  }
  while (enif_get_list_cell(env, term, &head, &tail)) {
    DMatrixHandle **resource = NULL;
    if (!enif_get_resource(env, head, DMatrix_RESOURCE_TYPE,
                           (void *)&(resource))) {
      return 0;
    }
    memcpy(&((*dmats)[i]), resource, sizeof(DMatrixHandle));
    term = tail;
    i++;
  }
  return 1;
}

ERL_NIF_TERM exg_get_binary_address(ErlNifEnv *env, int argc,
                                    const ERL_NIF_TERM argv[]) {
  ErlNifBinary bin;
  ERL_NIF_TERM ret = 0;
  if (argc != 1) {
    ret = exg_error(env, "exg_get_binary_address: wrong number of arguments");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[0], &bin)) {
    ret = exg_error(env, "exg_get_binary_address: invalid binary");
    goto END;
  }
  ret = exg_ok(env, enif_make_uint64(env, (uint64_t)bin.data));
END:
  return ret;
}

ERL_NIF_TERM exg_get_binary_from_address(ErlNifEnv *env, int argc,
                                         const ERL_NIF_TERM argv[]) {
  ErlNifBinary out_bin;
  ErlNifUInt64 address = 0;
  ErlNifUInt64 size = 0;
  ERL_NIF_TERM ret = -1;
  if (argc != 2) {
    ret = exg_error(env, "exg_get_binary_address: wrong number of arguments");
    goto END;
  }
  if (!enif_get_uint64(env, argv[0], &address)) {
    ret = exg_error(env, "exg_get_binary_address: invalid address");
    goto END;
  }
  if (!enif_get_uint64(env, argv[1], &size)) {
    ret = exg_error(env, "exg_get_binary_address: invalid size");
    goto END;
  }
  if (!enif_alloc_binary(size, &out_bin)) {
    ret = exg_error(env, "Failed to allocate binary");
    goto END;
  }
  memcpy(out_bin.data, (const void *)(uintptr_t)address, size);
  ret = exg_ok(env, enif_make_binary(env, &out_bin));
END:
  return ret;
}

ERL_NIF_TERM exg_get_int_size(ErlNifEnv *env, int argc,
                              const ERL_NIF_TERM argv[]) {
  ERL_NIF_TERM ret = 0;
  if (argc != 0) {
    ret = exg_error(env, "exg_get_int_size doesn't take any arguments");
    goto END;
  }
  int size = sizeof(int);
  ret = exg_ok(env, enif_make_int(env, size));
END:
  return ret;
}
