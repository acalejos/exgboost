#include "dmatrix.h"

#include <errno.h>
#include <inttypes.h>
#include <string.h>

#include "yyjson.h"

static ERL_NIF_TERM make_DMatrix_resource(ErlNifEnv *env, DMatrixHandle handle) {
  ERL_NIF_TERM ret = -1;
  DMatrixHandle **resource = enif_alloc_resource(DMatrix_RESOURCE_TYPE, sizeof(DMatrixHandle *));
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

// Deprecated since XGBoost 2.0.0
ERL_NIF_TERM EXGDMatrixCreateFromFile(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  char *fname = NULL;
  char *format = NULL;
  int silent = 0;
  int result = -1;
  DMatrixHandle handle;
  ERL_NIF_TERM ret = 0;
  if (argc != 2) {
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
  result = XGDMatrixCreateFromFile(fname, 1, &handle);
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
  return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromURI(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  char *config = NULL;
  DMatrixHandle handle;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  if (argc != 1) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!exg_get_string(env, argv[0], &config)) {
    ret = exg_error(env, "Config must be a string");
    goto END;
  }
  result = XGDMatrixCreateFromURI(config, &handle);
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
  return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromMat(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
  result = XGDMatrixCreateFromMat(mat, (bst_ulong)nrow, (bst_ulong)ncol, missing, &handle);
  if (result == 0) {
    ret = make_DMatrix_resource(env, handle);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromSparse(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  int result = -1;
  char *indptr_interface = NULL;
  char *indices_interface = NULL;
  char *data_interface = NULL;
  const char *error_msg = NULL;
  ERL_NIF_TERM indptr_binary, indptr_typestr, indptr_shape, indptr_readonly;
  ERL_NIF_TERM indices_binary, indices_typestr, indices_shape, indices_readonly;
  ERL_NIF_TERM data_binary, data_typestr, data_shape, data_readonly;
  bst_ulong n = 0;
  char *config = NULL;
  char *format = NULL;
  DMatrixHandle handle;
  ERL_NIF_TERM ret = 0;

  if (argc != 6) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }

  // Extract ArrayInterface tuples: {binary, typestr, shape, readonly}
  if (!exg_get_array_interface_tuple(env, argv[0], &indptr_binary, &indptr_typestr, &indptr_shape,
                                     &indptr_readonly, &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to extract indptr ArrayInterface tuple");
    goto END;
  }

  if (!exg_get_array_interface_tuple(env, argv[1], &indices_binary, &indices_typestr,
                                     &indices_shape, &indices_readonly, &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to extract indices ArrayInterface tuple");
    goto END;
  }

  if (!exg_get_array_interface_tuple(env, argv[2], &data_binary, &data_typestr, &data_shape,
                                     &data_readonly, &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to extract data ArrayInterface tuple");
    goto END;
  }

  // Build JSON from extracted components
  if (!exg_build_array_interface_json(env, indptr_binary, indptr_typestr, indptr_shape,
                                      indptr_readonly, &indptr_interface, &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to build indptr ArrayInterface");
    goto END;
  }

  if (!exg_build_array_interface_json(env, indices_binary, indices_typestr, indices_shape,
                                      indices_readonly, &indices_interface, &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to build indices ArrayInterface");
    goto END;
  }

  if (!exg_build_array_interface_json(env, data_binary, data_typestr, data_shape, data_readonly,
                                      &data_interface, &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to build data ArrayInterface");
    goto END;
  }

  // Matrix dimension parsing, must be a positive integer.
  ErlNifUInt64 n_arg = 0;

  if (!enif_get_uint64(env, argv[3], &n_arg)) {
    ret = exg_error(env, "Matrix dimension must be a non-negative integer");
    goto END;
  }

  if (n_arg == 0) {
    ret = exg_error(env, "Matrix dimension must be greater than zero");
    goto END;
  }

  n = (bst_ulong)n_arg;

  if (!exg_get_string(env, argv[4], &config)) {
    ret = exg_error(env, "Config must be a string");
    goto END;
  }

  if (!exg_get_string(env, argv[5], &format)) {
    ret = exg_error(env, "Format must be a string");
    goto END;
  }
  if (strcmp(format, "csr") == 0) {
    result = XGDMatrixCreateFromCSR(indptr_interface, indices_interface, data_interface, n, config,
                                    &handle);
  } else if (strcmp(format, "csc") == 0) {
    result = XGDMatrixCreateFromCSC(indptr_interface, indices_interface, data_interface, n, config,
                                    &handle);
  } else {
    ret = exg_error(env, "Format must in ['csr','csc']");
    goto END;
  }
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
  if (indptr_interface != NULL) {
    enif_free(indptr_interface);
    indptr_interface = NULL;
  }
  if (indices_interface != NULL) {
    enif_free(indices_interface);
    indices_interface = NULL;
  }
  if (data_interface != NULL) {
    enif_free(data_interface);
    data_interface = NULL;
  }
  if (format != NULL) {
    enif_free(format);
    format = NULL;
  }
  return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromDense(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  int result = -1;
  char *array_interface = NULL;
  const char *error_msg = NULL;
  ERL_NIF_TERM array_binary, array_typestr, array_shape, array_readonly;
  char *config = NULL;
  DMatrixHandle out;
  ERL_NIF_TERM ret = 0;

  if (argc != 2) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }

  // Extract ArrayInterface tuple: {binary, typestr, shape, readonly}
  if (!exg_get_array_interface_tuple(env, argv[0], &array_binary, &array_typestr, &array_shape,
                                     &array_readonly, &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to extract ArrayInterface tuple");
    goto END;
  }

  // Build ArrayInterface JSON from components
  if (!exg_build_array_interface_json(env, array_binary, array_typestr, array_shape, array_readonly,
                                      &array_interface, &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to build ArrayInterface");
    goto END;
  }

  if (!exg_get_string(env, argv[1], &config)) {
    ret = exg_error(env, "Config must be a JSON-Encoded string");
    goto END;
  }
  result = XGDMatrixCreateFromDense(array_interface, config, &out);
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

ERL_NIF_TERM EXGDMatrixSetStrFeatureInfo(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
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
  if (strcmp(field, "feature_type") != 0 && strcmp(field, "feature_name") != 0) {
    ret = exg_error(env, "Field must be in ['feature_type', 'feature_name']");
    goto END;
  }
  handle = *resource;
  // XGBoost reads features during the call; caller keeps ownership.
  result = XGDMatrixSetStrFeatureInfo(handle, field, (const char **)features, num_features);
  if (result == 0) {
    ret = ok_atom(env);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  // Helper-allocated buffers must be reclaimed on all paths.
  if (features != NULL) {
    exg_free_string_list(features, num_features);
  }
  if (field != NULL) {
    enif_free(field);
  }
  return ret;
}

ERL_NIF_TERM EXGDMatrixGetStrFeatureInfo(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  char const **c_out_features = NULL;
  bst_ulong out_size = 0;
  char *field = NULL;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  ERL_NIF_TERM *arr = NULL;

  if (argc != 2) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }

  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
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
  result = XGDMatrixGetStrFeatureInfo(handle, field, &out_size, &c_out_features);

  if (result == 0) {
    if (out_size > UINT_MAX || out_size > SIZE_MAX / sizeof(*arr)) {
      ret = exg_error(env, "Result is too large");
      goto END;
    }

    if (out_size != 0) {
      arr = enif_alloc((size_t)out_size * sizeof(*arr));

      if (arr == NULL) {
        ret = exg_error(env, "Failed to allocate result");
        goto END;
      }

      for (bst_ulong i = 0; i < out_size; ++i) {
        if (c_out_features[i] == NULL) {
          ret = exg_error(env, "XGBoost returned a NULL feature");
          goto END;
        }

        arr[i] = enif_make_string(env, c_out_features[i], ERL_NIF_LATIN1);
      }
    }

    ERL_NIF_TERM list = out_size == 0 ? enif_make_list(env, 0)
                                      : enif_make_list_from_array(env, arr, (unsigned)out_size);

    ret = exg_ok(env, list);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }

END:
  if (arr != NULL) {
    enif_free(arr);
  }

  if (field != NULL) {
    enif_free(field);
  }

  return ret;
}

ERL_NIF_TERM EXGDMatrixNumRow(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  bst_ulong out = 0;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  if (argc != 1) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
    goto END;
  }
  handle = *resource;
  result = XGDMatrixNumRow(handle, &out);
  if (result == 0) {
    ret = exg_ok(env, enif_make_uint64(env, (ErlNifUInt64)out));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGDMatrixNumCol(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  bst_ulong out = 0;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  if (argc != 1) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
    goto END;
  }
  handle = *resource;
  result = XGDMatrixNumCol(handle, &out);
  if (result == 0) {
    ret = exg_ok(env, enif_make_uint64(env, (ErlNifUInt64)out));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGDMatrixNumNonMissing(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  bst_ulong out = 0;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  if (argc != 1) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
    goto END;
  }
  handle = *resource;
  result = XGDMatrixNumNonMissing(handle, &out);
  if (result == 0) {
    ret = exg_ok(env, enif_make_uint64(env, (ErlNifUInt64)out));
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGDMatrixSetInfoFromInterface(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  char *field = NULL;
  char *data_interface = NULL;
  const char *error_msg = NULL;
  ERL_NIF_TERM data_binary, data_typestr, data_shape, data_readonly;
  int result = -1;
  ERL_NIF_TERM ret = 0;

  if (argc != 3) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }

  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
    goto END;
  }

  if (!exg_get_string(env, argv[1], &field)) {
    ret = exg_error(env, "Field must be a string");
    goto END;
  }

  // Extract ArrayInterface tuple: {binary, typestr, shape, readonly}
  if (!exg_get_array_interface_tuple(env, argv[2], &data_binary, &data_typestr, &data_shape,
                                     &data_readonly, &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to extract ArrayInterface tuple");
    goto END;
  }

  // Build ArrayInterface JSON from components
  if (!exg_build_array_interface_json(env, data_binary, data_typestr, data_shape, data_readonly,
                                      &data_interface, &error_msg)) {
    ret = exg_error(env, error_msg ? error_msg : "Failed to build data ArrayInterface");
    goto END;
  }

  if (strcmp(field, "label") != 0 && strcmp(field, "weight") != 0 &&
      strcmp(field, "base_margin") != 0 && strcmp(field, "group") != 0 &&
      strcmp(field, "label_lower_bound") != 0 && strcmp(field, "label_upper_bound") != 0 &&
      strcmp(field, "feature_weights") != 0) {
    ret = exg_error(env,
                    "Field must be in ['label', 'weight', "
                    "'base_margin','group','label_lower_bound','label_"
                    "upper_bound','feature_weights']");
    goto END;
  }
  handle = *resource;
  result = XGDMatrixSetInfoFromInterface(handle, field, data_interface);
  if (result == 0) {
    ret = ok_atom(env);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  if (field != NULL) {
    enif_free(field);
  }
  if (data_interface != NULL) {
    enif_free(data_interface);
  }
  return ret;
}

ERL_NIF_TERM EXGDMatrixSaveBinary(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  char *fname = NULL;
  int silent = 0;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  if (argc != 3) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &fname)) {
    ret = exg_error(env, "File name must be a string");
    goto END;
  }
  if (!enif_get_int(env, argv[2], &silent)) {
    ret = exg_error(env, "Silent must be an integer");
    goto END;
  }
  handle = *resource;
  result = XGDMatrixSaveBinary(handle, fname, silent);
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

ERL_NIF_TERM EXGDMatrixGetFloatInfo(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  char *field = NULL;
  const float *out = NULL;
  bst_ulong len = 0;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  ERL_NIF_TERM *arr = NULL;

  if (argc != 2) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &field)) {
    ret = exg_error(env, "Field must be a string");
    goto END;
  }
  if (strcmp(field, "label") != 0 && strcmp(field, "weight") != 0 &&
      strcmp(field, "base_margin") != 0 && strcmp(field, "label_lower_bound") &&
      strcmp(field, "label_upper_bound") && strcmp(field, "feature_weights") != 0) {
    ret = exg_error(env,
                    "Field must be in ['label', 'weight', "
                    "'base_margin','label_lower_bound','label_"
                    "upper_bound','feature_weights']");
    goto END;
  }
  handle = *resource;
  result = XGDMatrixGetFloatInfo(handle, field, &len, &out);
  if (result == 0) {
    arr = enif_alloc(sizeof(ERL_NIF_TERM) * len);
    for (int i = 0; i < len; i++) {
      // Values are copied into BEAM-managed terms here.
      arr[i] = enif_make_double(env, out[i]);
    }
    ret = exg_ok(env, enif_make_list_from_array(env, arr, len));
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

ERL_NIF_TERM EXGDMatrixGetUIntInfo(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  char *field = NULL;
  const unsigned *out = NULL;
  bst_ulong len = 0;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  ERL_NIF_TERM *arr = NULL;

  if (argc != 2) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &field)) {
    ret = exg_error(env, "Field must be a string");
    goto END;
  }
  if (strcmp(field, "group_ptr") != 0) {
    ret = exg_error(env, "Field must be in ['group_ptr']");
    goto END;
  }
  handle = *resource;
  result = XGDMatrixGetUIntInfo(handle, field, &len, &out);
  if (result == 0) {
    arr = enif_alloc(sizeof(ERL_NIF_TERM) * len);
    for (int i = 0; i < len; i++) {
      // Values are copied into BEAM-managed terms here.
      arr[i] = enif_make_uint(env, out[i]);
    }
    ret = exg_ok(env, enif_make_list_from_array(env, arr, len));
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

ERL_NIF_TERM EXGDMatrixGetDataAsCSR(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  bst_ulong num_non_missing = 0;
  bst_ulong num_rows = 0;
  char *config = NULL;
  bst_ulong *out_indptr = NULL;
  unsigned *out_indices = NULL;
  float *out_data = NULL;
  ERL_NIF_TERM *indptr = NULL;
  ERL_NIF_TERM *indices = NULL;
  ERL_NIF_TERM *data = NULL;
  int result = -1;
  ERL_NIF_TERM ret = 0;
  if (argc != 2) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &config)) {
    ret = exg_error(env, "Config must be a JSON-Encoded string");
    goto END;
  }
  handle = *resource;
  result = XGDMatrixNumRow(handle, &num_rows);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }
  result = XGDMatrixNumNonMissing(handle, &num_non_missing);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }
  // Check allocation sizes fit in size_t
  if (num_rows > SIZE_MAX / sizeof(bst_ulong) - 1 ||
      num_non_missing > SIZE_MAX / sizeof(unsigned) || num_non_missing > SIZE_MAX / sizeof(float)) {
    ret = exg_error(env, "Matrix is too large");
    goto END;
  }
  out_indptr = malloc(sizeof(bst_ulong) * (size_t)(num_rows + 1));
  out_indices = malloc(sizeof(unsigned) * (size_t)num_non_missing);
  out_data = malloc(sizeof(float) * (size_t)num_non_missing);
  if (!out_indptr || !out_indices || !out_data) {
    ret = exg_error(env, "Failed to allocate memory");
    goto END;
  }
  result = XGDMatrixGetDataAsCSR(handle, config, out_indptr, out_indices, out_data);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }
  // Check enif_alloc sizes fit in size_t
  if (num_rows > SIZE_MAX / sizeof(ERL_NIF_TERM) - 1 ||
      num_non_missing > SIZE_MAX / sizeof(ERL_NIF_TERM)) {
    ret = exg_error(env, "Matrix is too large");
    goto END;
  }
  indptr = enif_alloc(sizeof(ERL_NIF_TERM) * (size_t)(num_rows + 1));
  indices = enif_alloc(sizeof(ERL_NIF_TERM) * (size_t)num_non_missing);
  data = enif_alloc(sizeof(ERL_NIF_TERM) * (size_t)num_non_missing);
  if (!indptr || !indices || !data) {
    ret = exg_error(env, "Failed to allocate memory");
    goto END;
  }
  for (bst_ulong i = 0; i < num_rows + 1; ++i) {
    indptr[i] = enif_make_uint64(env, (ErlNifUInt64)out_indptr[i]);
  }
  for (bst_ulong i = 0; i < num_non_missing; ++i) {
    indices[i] = enif_make_uint(env, out_indices[i]);
    data[i] = enif_make_double(env, out_data[i]);
  }
  ret = exg_ok(env,
               enif_make_tuple3(env, enif_make_list_from_array(env, indptr, (size_t)(num_rows + 1)),
                                enif_make_list_from_array(env, indices, (size_t)num_non_missing),
                                enif_make_list_from_array(env, data, (size_t)num_non_missing)));
END:
  // Mixed allocators: enif_free for enif_alloc buffers, free for malloc buffers.
  if (config != NULL) {
    enif_free(config);
    config = NULL;
  }
  if (out_indptr != NULL) {
    free(out_indptr);
    out_indptr = NULL;
  }
  if (out_indices != NULL) {
    free(out_indices);
    out_indices = NULL;
  }
  if (out_data != NULL) {
    free(out_data);
    out_data = NULL;
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
};

ERL_NIF_TERM EXGDMatrixSliceDMatrix(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  ErlNifBinary bin;
  DMatrixHandle out;
  int result = -1;
  int allow_groups = 0;
  ERL_NIF_TERM ret = -1;
  if (argc != 3) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
    goto END;
  }
  if (!enif_inspect_binary(env, argv[1], &bin)) {
    ret = exg_error(env, "Indices must be a binary of ints");
    goto END;
  }
  if (!enif_get_int(env, argv[2], &allow_groups)) {
    ret = exg_error(env, "allow_groups must be an int");
    goto END;
  }
  if (bin.size % sizeof(int) != 0) {
    ret = exg_error(env, "Indices must be a binary of ints");
    goto END;
  }
  if (bin.size == 0) {
    ret = exg_error(env, "Indices must be a binary of ints (non-empty))");
    goto END;
  }
  if (allow_groups != 0 && allow_groups != 1) {
    ret = exg_error(env, "allow_groups must be 0 or 1");
    goto END;
  }
  handle = *resource;
  int index_count = (int)(bin.size / sizeof(int));
  for (bst_ulong i = 0; i < index_count; i++) {
    if (((int *)bin.data)[i] < 0) {
      ret = exg_error(env, "Indices must be non-negative");
      goto END;
    }
  }
  result = XGDMatrixSliceDMatrixEx(handle, (int *)bin.data, index_count, &out, allow_groups);
  if (0 == result) {
    ret = make_DMatrix_resource(env, out);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

ERL_NIF_TERM EXGProxyDMatrixCreate(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  int result = -1;
  ERL_NIF_TERM ret = -1;
  if (argc != 0) {
    ret = exg_error(env, "EXGProxyDMatrixCreate doesn't take arguments");
    goto END;
  }
  result = XGProxyDMatrixCreate(&handle);
  if (0 == result) {
    ret = make_DMatrix_resource(env, handle);
  } else {
    ret = exg_error(env, XGBGetLastError());
  }
END:
  return ret;
}

// Helper to parse ArrayInterface JSON and copy data atomically
static int exg_parse_and_copy_array_interface(ErlNifEnv *env, const char *json_str,
                                              ERL_NIF_TERM *out_map) {
  int ok = 0;
  yyjson_doc *doc = NULL;

  doc = yyjson_read(json_str, strlen(json_str), 0);
  if (doc == NULL) {
    goto CLEANUP;
  }

  yyjson_val *root = yyjson_doc_get_root(doc);
  if (!yyjson_is_obj(root)) {
    goto CLEANUP;
  }

  yyjson_val *version_val = yyjson_obj_get(root, "version");
  yyjson_val *typestr_val = yyjson_obj_get(root, "typestr");
  yyjson_val *data_arr = yyjson_obj_get(root, "data");
  yyjson_val *shape_arr = yyjson_obj_get(root, "shape");

  if (!yyjson_is_uint(version_val) || yyjson_get_uint(version_val) != 3 ||
      !yyjson_is_str(typestr_val) || !yyjson_is_arr(data_arr) || !yyjson_is_arr(shape_arr)) {
    goto CLEANUP;
  }

  if (yyjson_arr_size(data_arr) < 2) {
    goto CLEANUP;
  }

  yyjson_val *address_val = yyjson_arr_get(data_arr, 0);
  yyjson_val *readonly_val = yyjson_arr_get(data_arr, 1);

  if (!yyjson_is_uint(address_val) || !yyjson_is_bool(readonly_val)) {
    goto CLEANUP;
  }

  uint64_t address_arg = yyjson_get_uint(address_val);

  if (address_arg > UINTPTR_MAX) {
    goto CLEANUP;
  }

  uintptr_t address = (uintptr_t)address_arg;
  const char *typestr = yyjson_get_str(typestr_val);

  size_t bytes_per_elem = 0;
  const char *parse_error = NULL;

  if (!exg_parse_typestr(typestr, &bytes_per_elem, &parse_error)) {
    goto CLEANUP;
  }

  size_t ndim = yyjson_arr_size(shape_arr);

  /*
   * Quantile-cut interfaces are expected to be one-dimensional.
   * Relax this only if the helper becomes generic.
   */
  if (ndim != 1) {
    goto CLEANUP;
  }

  yyjson_val *dim_val = yyjson_arr_get(shape_arr, 0);

  if (!yyjson_is_uint(dim_val)) {
    goto CLEANUP;
  }

  uint64_t dim_arg = yyjson_get_uint(dim_val);

  if (dim_arg > SIZE_MAX) {
    goto CLEANUP;
  }

  size_t dim = (size_t)dim_arg;

  if (dim != 0 && bytes_per_elem > SIZE_MAX / dim) {
    goto CLEANUP;
  }

  size_t total_size = dim * bytes_per_elem;

  if (address == 0 && total_size != 0) {
    goto CLEANUP;
  }

  ERL_NIF_TERM binary_term;
  unsigned char *destination = enif_make_new_binary(env, total_size, &binary_term);

  if (destination == NULL && total_size != 0) {
    goto CLEANUP;
  }

  if (total_size != 0) {
    memcpy(destination, (const void *)address, total_size);
  }

  size_t typestr_len = strlen(typestr);
  ERL_NIF_TERM typestr_term;
  unsigned char *typestr_destination = enif_make_new_binary(env, typestr_len, &typestr_term);

  if (typestr_destination == NULL && typestr_len != 0) {
    goto CLEANUP;
  }

  if (typestr_len != 0) {
    memcpy(typestr_destination, typestr, typestr_len);
  }

  ERL_NIF_TERM shape_term = enif_make_list1(env, enif_make_uint64(env, (ErlNifUInt64)dim));

  ok = exg_make_array_interface_map(env, binary_term, typestr_term, shape_term, out_map);

CLEANUP:
  if (doc != NULL) {
    yyjson_doc_free(doc);
  }

  return ok;
}

ERL_NIF_TERM EXGDMatrixGetQuantileCut(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  DMatrixHandle handle;
  DMatrixHandle **resource = NULL;
  char *config = NULL;
  char const *out_indptr_json = NULL;
  char const *out_data_json = NULL;
  ERL_NIF_TERM indptr_map, data_map;
  ERL_NIF_TERM ret = -1;
  int result = -1;

  if (argc != 2) {
    ret = exg_error(env, "Wrong number of arguments");
    goto END;
  }
  if (!enif_get_resource(env, argv[0], DMatrix_RESOURCE_TYPE, (void *)&resource)) {
    ret = exg_error(env, "DMatrix must be a resource");
    goto END;
  }
  if (!exg_get_string(env, argv[1], &config)) {
    ret = exg_error(env, "Config must be a JSON-Encoded string");
    goto END;
  }
  handle = *resource;

  // Get ArrayInterface JSON from XGBoost
  result = XGDMatrixGetQuantileCut(handle, config, &out_indptr_json, &out_data_json);
  if (result != 0) {
    ret = exg_error(env, XGBGetLastError());
    goto END;
  }

  // Parse JSON and copy data atomically, before any other operations
  if (!exg_parse_and_copy_array_interface(env, out_indptr_json, &indptr_map)) {
    ret = exg_error(env, "Failed to parse indptr ArrayInterface");
    goto END;
  }
  if (!exg_parse_and_copy_array_interface(env, out_data_json, &data_map)) {
    ret = exg_error(env, "Failed to parse data ArrayInterface");
    goto END;
  }

  ret = exg_ok(env, enif_make_tuple2(env, indptr_map, data_map));

END:
  if (config != NULL) {
    enif_free(config);
    config = NULL;
  }
  return ret;
}
