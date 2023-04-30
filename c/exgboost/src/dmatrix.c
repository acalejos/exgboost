#include "dmatrix.h"

static ERL_NIF_TERM make_DMatrix_resource(ErlNifEnv *env,
                                          DMatrixHandle handle) {
  ERL_NIF_TERM ret = -1;
  DMatrixHandle **resource =
      enif_alloc_resource(DMatrix_RESOURCE_TYPE, sizeof(DMatrixHandle *));
  if (resource != NULL) {
    *resource = handle;
    ret = exg_ok(env, enif_make_resource(env, resource));
    enif_release_resource(resource);
  } else {
    ret = exg_error(env, "Failed to allocate memory for XGBoost DMatrix");
  }
  return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromFile(ErlNifEnv *env, int argc,
                                      const ERL_NIF_TERM argv[]) {
  char *fname = NULL;
  char *format = NULL;
  char *uri = NULL;
  const char uri_param[] = "?format=";
  int silent = 0;
  int result = -1;
  DMatrixHandle handle;
  ERL_NIF_TERM ret = 0;
  if (argc != 3) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!exg_get_string(env, argv[0], &fname)) {
    ret = exg_error(env, "File name must be a string");
    goto END;
  }
  if (!enif_get_int(env, argv[1], &silent)) {
    ret = exg_error(env, "Silent must be an integer");
    goto END;
  }
  if (!exg_get_string(env, argv[2], &format)) {
    ret = exg_error(env, "File Format must be a string");
    goto END;
  }
  if ((0 != strcmp(format, "csv")) && (0 != strcmp(format, "libsvm"))) {
    ret = exg_error(env, "File format must be either 'csv' or 'libsvm'");
    goto END;
  }
  // strlen is safe because exg_get_string always null terminates on success
  // +1 for the null terminator
  size_t uri_len = strlen(fname) + strlen(format) + strlen(uri_param) + 1;
  uri = (char *)malloc(uri_len * sizeof(char));
  result = snprintf(uri, uri_len, "%s%s%s", fname, uri_param, format);
  if ((size_t)result != uri_len - 1) {
    ret = exg_error(env, "Error creating filename URI");
    goto END;
  }
  result = XGDMatrixCreateFromFile(uri, 1, &handle);
  if (result == 0) {
    ret = make_DMatrix_resource(env, handle);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (fname != NULL) {
    enif_free(fname);
    fname = NULL;
  }
  if (format != NULL) {
    enif_free(format);
    format = NULL;
  }
  if (uri != NULL) {
    free(uri);
    uri = NULL;
  }
  return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromMat(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]) {
  ErlNifBinary bin;
  int result = -1;
  float *mat = NULL;
  int nrow = 0;
  int ncol = 0;
  int num_floats = 0;
  double missing = 0.0;
  DMatrixHandle handle;
  ERL_NIF_TERM ret = 0;
  if (argc != 4) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[0], &bin)) {
    ret = exg_error(env, "Data must be a binary");
    goto END;
  }
  if (!enif_get_int(env, argv[1], &nrow)) {
    ret = exg_error(env, "Nrow must be an integer");
    goto END;
  }
  if (!enif_get_int(env, argv[2], &ncol)) {
    ret = exg_error(env, "Ncol must be an integer");
    goto END;
  }
  if (!enif_get_double(env, argv[3], &missing)) {
    ret = exg_error(env, "Missing must be a float");
    goto END;
  }
  mat = (float *)bin.data;
  num_floats = bin.size / sizeof(float);
  if (num_floats != nrow * ncol) {
    ret = exg_error(env, "Data size does not match nrow and ncol");
    goto END;
  }
  // The DMatrix wlil keep ahold of this data, so we don't need to free it
  // Will be freed when DMatrix is freed in resource destructor
  result = XGDMatrixCreateFromMat(mat, (bst_ulong)nrow, (bst_ulong)ncol,
                                  missing, &handle);
  if (result == 0) {
    ret = make_DMatrix_resource(env, handle);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromCSR(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]) {
  int result = -1;
  ErlNifBinary indptr_bin;
  ErlNifBinary indices_bin;
  ErlNifBinary data_bin;
  char *indptr = NULL;
  char *indices = NULL;
  char *data = NULL;
  char data_interface[512] = {0};
  char indptr_interface[512] = {0};
  char indices_interface[512] = {0};
  int ncol = 0;
  char *config = NULL;
  DMatrixHandle handle;
  ERL_NIF_TERM ret = 0;
  if (argc != 8) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[0], &indptr_bin)) {
    ret = exg_error(env, "Indptr_bin must be a binary");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &indptr)) {
    ret =
        exg_error(env, "Indptr Array Interface must be a JSON-Encoded string");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[2], &indices_bin)) {
    ret = exg_error(env, "Indices_bin must be a binary");
    goto END;
  }
  if (!exg_get_string(env, argv[3], &indices)) {
    ret =
        exg_error(env, "Indices Array Interface must be a JSON-Encoded string");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[4], &data_bin)) {
    ret = exg_error(env, "Data_bin must be a binary");
    goto END;
  }
  if (!exg_get_string(env, argv[5], &data)) {
    ret = exg_error(env, "Data Array Interface must be a JSON-Encoded string");
    goto END;
  }
  if (!enif_get_int(env, argv[6], &ncol)) {
    ret = exg_error(env, "Ncol must be an integer");
    goto END;
  }
  if (!exg_get_string(env, argv[7], &config)) {
    ret = exg_error(env, "Config must be a string");
    goto END;
  }
  sprintf(indptr_interface, indptr, (size_t)indptr_bin.data);
  sprintf(indices_interface, indices, (size_t)indices_bin.data);
  sprintf(data_interface, data, (size_t)data_bin.data);
  result = XGDMatrixCreateFromCSR(indptr_interface, indices_interface,
                                  data_interface, ncol, config, &handle);
  if (result == 0) {
    ret = make_DMatrix_resource(env, handle);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (config != NULL) {
    enif_free(config);
    config = NULL;
  }
  if (indptr != NULL) {
    enif_free(indptr);
    indptr = NULL;
  }
  if (indices != NULL) {
    enif_free(indices);
    indices = NULL;
  }
  if (data != NULL) {
    enif_free(data);
    data = NULL;
  }
  return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromCSREx(ErlNifEnv *env, int argc,
                                       const ERL_NIF_TERM argv[]) {
  ErlNifBinary indptr_bin;
  ErlNifBinary indices_bin;
  ErlNifBinary data_bin;
  int result = -1;
  ErlNifUInt64 *indptr = NULL;
  uint32_t *indices = NULL;
  float *data = NULL;
  uint32_t nindptr = 0;
  ErlNifUInt64 nelem = 0;
  ErlNifUInt64 ncol = 0;
  DMatrixHandle handle;
  ERL_NIF_TERM ret = 0;
  if (argc != 6) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[0], &indptr_bin)) {
    ret = exg_error(env, "Indptr must be a binary of uint64_t");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[1], &indices_bin)) {
    ret = exg_error(env, "Indices must be a binary of uint64_t");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[2], &data_bin)) {
    ret = exg_error(env, "Data must be a binary of uint64_t");
    goto END;
  }
  if (!enif_get_uint(env, argv[3], &nindptr)) {
    ret = exg_error(env, "Nindptr must be a uint64_t");
    goto END;
  }
  if (!enif_get_uint64(env, argv[4], &nelem)) {
    ret = exg_error(env, "Nelem must be a uint64_t");
    goto END;
  }
  if (!enif_get_uint64(env, argv[5], &ncol)) {
    ret = exg_error(env, "Ncol must be a uint64_t");
    goto END;
  }
  indptr = (ErlNifUInt64 *)indptr_bin.data;
  indices = (uint32_t *)indices_bin.data;
  data = (float *)data_bin.data;
  if (indptr_bin.size != nindptr * sizeof(ErlNifUInt64)) {
    ret = exg_error(env, "Indptr size does not match nindptr");
    goto END;
  }
  if (data_bin.size != nelem * sizeof(float)) {
    ret = exg_error(env, "Data size does not match nelem");
    goto END;
  }
  result = XGDMatrixCreateFromCSREx(indptr, indices, data, nindptr, nelem, ncol,
                                    &handle);
  if (result == 0) {
    ret = exg_ok(env, enif_make_resource(env, handle));
    enif_release_resource(handle);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromDense(ErlNifEnv *env, int argc,
                                       const ERL_NIF_TERM argv[]) {
  ErlNifBinary data_bin;
  char data[512] = {0};
  int result = -1;
  char *array_interface = NULL;
  char *config = NULL;
  DMatrixHandle out;
  ERL_NIF_TERM ret = 0;
  if (argc != 3) {
    ret = exg_error(env, "Wrong number of arguments");
  }
  if (!enif_inspect_binary(env, argv[0], &data_bin)) {
    ret = exg_error(env, "Data must be a binary");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &array_interface)) {
    ret = exg_error(env, "Array Interface must be a JSON-Encoded string");
    goto END;
  }
  if (!exg_get_string(env, argv[2], &config)) {
    ret = exg_error(env, "Config must be a JSON-Encoded string");
    goto END;
  }
  sprintf(data, array_interface, (size_t)data_bin.data);
  result = XGDMatrixCreateFromDense(data, config, &out);
  if (0 == result) {
    ret = make_DMatrix_resource(env, out);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (array_interface != NULL) {
    enif_free(array_interface);
  }
  if (config != NULL) {
    enif_free(config);
  }
  return ret;
}

ERL_NIF_TERM EXGDMatrixSetStrFeatureInfo(ErlNifEnv *env, int argc,
                                         const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  char **features = NULL;
  unsigned num_features = 0;
  char *field = NULL;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  if (argc != 3) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE,
                         (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
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
  result = XGDMatrixSetStrFeatureInfo(handle, field, features, num_features);
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

ERL_NIF_TERM EXGDMatrixGetStrFeatureInfo(ErlNifEnv *env, int argc,
                                         const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  char const **c_out_features = NULL;
  bst_ulong out_size = 0;
  char *field = NULL;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  if (argc != 2) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE,
                         (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
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
      XGDMatrixGetStrFeatureInfo(handle, field, &out_size, &c_out_features);
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