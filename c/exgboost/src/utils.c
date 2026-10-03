#include "utils.h"

#include <ctype.h>
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
// Ensure bst_ulong and ErlNifUInt64 are both 64-bit for safe conversions
_Static_assert(sizeof(bst_ulong) == sizeof(ErlNifUInt64),
               "bst_ulong and ErlNifUInt64 must both be 64-bit");

// Cached atoms
static ERL_NIF_TERM ATOM_TRUE;
static ERL_NIF_TERM ATOM_FALSE;
static ERL_NIF_TERM ATOM_OK;
static ERL_NIF_TERM ATOM_ERROR;
static ERL_NIF_TERM ATOM_BINARY;
static ERL_NIF_TERM ATOM_TYPESTR;
static ERL_NIF_TERM ATOM_SHAPE;

// Initialize atoms (call this from NIF load)
void exg_init_atoms(ErlNifEnv *env) {
  ATOM_TRUE = enif_make_atom(env, "true");
  ATOM_FALSE = enif_make_atom(env, "false");
  ATOM_OK = enif_make_atom(env, "ok");
  ATOM_ERROR = enif_make_atom(env, "error");
  ATOM_BINARY = enif_make_atom(env, "binary");
  ATOM_TYPESTR = enif_make_atom(env, "typestr");
  ATOM_SHAPE = enif_make_atom(env, "shape");
}

ERL_NIF_TERM exg_error(ErlNifEnv *env, const char *msg) {
  ERL_NIF_TERM msg_term = enif_make_string(env, msg, ERL_NIF_LATIN1);
  return enif_make_tuple2(env, ATOM_ERROR, msg_term);
}

ERL_NIF_TERM ok_atom(ErlNifEnv *env) { return ATOM_OK; }

ERL_NIF_TERM exg_ok(ErlNifEnv *env, ERL_NIF_TERM term) {
  return enif_make_tuple2(env, ATOM_OK, term);
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
  if (*out == NULL) {
    return 0;
  }
  while (enif_get_list_cell(env, term, &head, &tail)) {
    int ret = enif_get_double(env, head, &((*out)[i]));
    if (!ret) {
      enif_free(*out);
      *out = NULL;
      return 0;
    }
    term = tail;
    i++;
  }
  return 1;
}

int exg_get_string_list(ErlNifEnv *env, ERL_NIF_TERM term, char ***out, unsigned *len) {
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
      exg_free_string_list(*out, i);
      *out = NULL;
      return 0;
    }
    term = tail;
    i++;
  }
  return 1;
}

int exg_get_dmatrix_list(ErlNifEnv *env, ERL_NIF_TERM term, DMatrixHandle **dmats, unsigned *len) {
  ERL_NIF_TERM head, tail;
  int i = 0;
  if (!enif_get_list_length(env, term, len)) {
    return 0;
  }
  *dmats = (DMatrixHandle *)enif_alloc(*len * sizeof(DMatrixHandle));
  if (NULL == *dmats) {
    return 0;
  }
  while (enif_get_list_cell(env, term, &head, &tail)) {
    DMatrixHandle **resource = NULL;
    if (!enif_get_resource(env, head, DMatrix_RESOURCE_TYPE, (void *)&(resource))) {
      exg_free_dmatrix_list(*dmats);
      *dmats = NULL;
      return 0;
    }
    memcpy(&((*dmats)[i]), resource, sizeof(DMatrixHandle));
    term = tail;
    i++;
  }
  return 1;
}

void exg_free_string_list(char **items, unsigned len) {
  if (items == NULL) {
    return;
  }
  for (unsigned i = 0; i < len; ++i) {
    if (items[i] != NULL) {
      enif_free(items[i]);
    }
  }
  enif_free(items);
}

void exg_free_dmatrix_list(DMatrixHandle *dmats) {
  if (dmats != NULL) {
    enif_free(dmats);
  }
}

// Helper: Extract boolean from term (true/false atom only)
static int exg_get_boolean(ErlNifEnv *env, ERL_NIF_TERM term, int *value) {
  if (enif_is_identical(term, ATOM_TRUE)) {
    *value = 1;
    return 1;
  } else if (enif_is_identical(term, ATOM_FALSE)) {
    *value = 0;
    return 1;
  }
  return 0;
}

// Helper: Parse and validate typestr format, returning element size
// Accepts patterns like: <f4, <f8, <i4, <i8, <u4, <u8, |i1, |u1, etc.
//
// Validation policy:
// - Endianness: Only '<' (little-endian) and '|' (byte-order-independent) are accepted.
//   Big-endian '>' is rejected until byte-swapping is implemented.
// - Type codes: 'i' (signed int), 'u' (unsigned int), 'f' (float), 'c' (complex)
// - Element size: Any positive integer that fits in size_t is accepted syntactically.
//   XGBoost will validate whether it supports the specific type/width combination.
// - The '|' marker is only valid for single-byte types (width 1).
int exg_parse_typestr(const char *typestr, size_t *element_size_out, const char **error_msg) {
  if (typestr == NULL || typestr[0] == '\0' || typestr[1] == '\0' || typestr[2] == '\0') {
    *error_msg = "Typestr must have the form '<f4', '<i8', or '|u1'";
    return 0;
  }

  char endianness = typestr[0];
  char type_code = typestr[1];
  const char *size_text = typestr + 2;

  // Only little-endian and byte-order-independent are supported
  // Big-endian requires byte-swapping which is not yet implemented
  if (endianness != '<' && endianness != '|') {
    *error_msg =
        "Typestr endianness must be '<' (little-endian) or '|' (byte-order-independent); "
        "big-endian '>' is not supported";
    return 0;
  }

  if (type_code != 'i' && type_code != 'u' && type_code != 'f' && type_code != 'c') {
    *error_msg = "Typestr type must be 'i', 'u', 'f', or 'c'";
    return 0;
  }

  /*
   * strtoumax() accepts whitespace and a leading '+', but these are not
   * valid in a typestr. Require every remaining character to be a digit.
   */
  for (const char *cursor = size_text; *cursor != '\0'; ++cursor) {
    if (!isdigit((unsigned char)*cursor)) {
      *error_msg = "Typestr element size must contain decimal digits only";
      return 0;
    }
  }

  errno = 0;
  char *end = NULL;
  uintmax_t parsed = strtoumax(size_text, &end, 10);

  if (errno == ERANGE || end == size_text || *end != '\0' || parsed == 0 || parsed > SIZE_MAX) {
    *error_msg = "Invalid typestr element size";
    return 0;
  }

  size_t element_size = (size_t)parsed;

  // The byte-order-independent marker '|' is only valid for single-byte types
  if (endianness == '|' && element_size != 1) {
    *error_msg = "Byte-order-independent marker '|' is only valid for single-byte types";
    return 0;
  }

  *element_size_out = element_size;
  return 1;
}

// Helper: Build shape JSON string dynamically
static int exg_shape_to_json(ErlNifEnv *env, ERL_NIF_TERM shape_term, char **json_out,
                             const char **error_msg) {
  unsigned shape_len;
  char *json = NULL;
  size_t capacity = 64;
  size_t pos = 0;

  if (!enif_get_list_length(env, shape_term, &shape_len)) {
    *error_msg = "Shape must be a proper list";
    return 0;
  }

  // Allocate initial buffer
  json = enif_alloc(capacity);
  if (json == NULL) {
    *error_msg = "Failed to allocate memory for shape JSON";
    return 0;
  }

  json[pos++] = '[';

  ERL_NIF_TERM head, tail = shape_term;
  for (unsigned i = 0; i < shape_len; i++) {
    if (!enif_get_list_cell(env, tail, &head, &tail)) {
      enif_free(json);
      *error_msg = "Failed to iterate shape list";
      return 0;
    }

    ErlNifUInt64 dim;
    if (!enif_get_uint64(env, head, &dim)) {
      enif_free(json);
      *error_msg = "Shape values must be non-negative integers";
      return 0;
    }

    // Estimate space needed for this dimension
    char dim_str[32];
    int written = snprintf(dim_str, sizeof(dim_str), "%llu", (unsigned long long)dim);
    if (written < 0) {
      enif_free(json);
      *error_msg = "Failed to format shape dimension";
      return 0;
    }

    size_t needed = written + (i < shape_len - 1 ? 1 : 0);  // +1 for comma

    // Ensure capacity
    while (pos + needed + 2 >= capacity) {  // +2 for ']' and '\0'
      capacity *= 2;
      char *new_json = enif_realloc(json, capacity);
      if (new_json == NULL) {
        enif_free(json);
        *error_msg = "Failed to reallocate memory for shape JSON";
        return 0;
      }
      json = new_json;
    }

    // Append dimension
    strcpy(json + pos, dim_str);
    pos += written;

    // Add comma if not last
    if (i < shape_len - 1) {
      json[pos++] = ',';
    }
  }

  json[pos++] = ']';
  json[pos] = '\0';

  *json_out = json;
  return 1;
}

// Helper: Validate shape and check binary size
static int exg_validate_shape_and_size(ErlNifEnv *env, ERL_NIF_TERM shape_term, size_t element_size,
                                       size_t binary_size, size_t *required_bytes_out,
                                       const char **error_msg) {
  unsigned shape_len;

  if (!enif_get_list_length(env, shape_term, &shape_len)) {
    *error_msg = "Shape must be a proper list";
    return 0;
  }

  // Calculate total elements with overflow checking
  size_t total_elements = 1;
  ERL_NIF_TERM head, tail = shape_term;

  for (unsigned i = 0; i < shape_len; i++) {
    if (!enif_get_list_cell(env, tail, &head, &tail)) {
      *error_msg = "Failed to iterate shape list";
      return 0;
    }

    ErlNifUInt64 dim;
    if (!enif_get_uint64(env, head, &dim)) {
      *error_msg = "Shape values must be non-negative integers";
      return 0;
    }

    // Check for overflow in multiplication
    if (dim > 0 && total_elements > SIZE_MAX / dim) {
      *error_msg = "Shape dimensions overflow";
      return 0;
    }

    total_elements *= (size_t)dim;
  }

  // Check for overflow in byte calculation
  if (total_elements > SIZE_MAX / element_size) {
    *error_msg = "Required byte size overflows";
    return 0;
  }

  size_t required_bytes = total_elements * element_size;

  if (binary_size < required_bytes) {
    *error_msg = "Binary is too small for the specified shape and type";
    return 0;
  }

  *required_bytes_out = required_bytes;
  return 1;
}

// Helper: Extract Array Interface components from tuple {binary, typestr, shape, readonly}
int exg_get_array_interface_tuple(ErlNifEnv *env, ERL_NIF_TERM tuple_term, ERL_NIF_TERM *binary_out,
                                  ERL_NIF_TERM *typestr_out, ERL_NIF_TERM *shape_out,
                                  ERL_NIF_TERM *readonly_out, const char **error_msg) {
  int arity = 0;
  const ERL_NIF_TERM *tuple_elements = NULL;

  *error_msg = NULL;

  // Check that it's a tuple
  if (!enif_get_tuple(env, tuple_term, &arity, &tuple_elements)) {
    *error_msg = "ArrayInterface must be a tuple";
    return 0;
  }

  // Verify arity is exactly 4
  if (arity != 4) {
    *error_msg = "ArrayInterface tuple must have 4 elements: {binary, typestr, shape, readonly}";
    return 0;
  }

  // Extract components
  *binary_out = tuple_elements[0];
  *typestr_out = tuple_elements[1];
  *shape_out = tuple_elements[2];
  *readonly_out = tuple_elements[3];

  return 1;
}

// Helper to build Array Interface JSON from components with fresh address
// Returns 1 on success, 0 on failure
int exg_build_array_interface_json(ErlNifEnv *env, ERL_NIF_TERM binary_term,
                                   ERL_NIF_TERM typestr_term, ERL_NIF_TERM shape_term,
                                   ERL_NIF_TERM readonly_term, char **json_out,
                                   const char **error_msg) {
  ErlNifBinary data_bin;
  char *typestr = NULL;
  char *shape_json = NULL;
  char *json = NULL;
  int readonly;
  int ok = 0;

  *json_out = NULL;
  *error_msg = NULL;

  // Extract and validate binary
  if (!enif_inspect_binary(env, binary_term, &data_bin)) {
    *error_msg = "Binary argument required";
    goto CLEANUP;
  }

  // Extract typestr
  if (!exg_get_string(env, typestr_term, &typestr)) {
    *error_msg = "Typestr must be a string";
    goto CLEANUP;
  }

  // Parse and validate typestr format
  size_t element_size = 0;
  if (!exg_parse_typestr(typestr, &element_size, error_msg)) {
    goto CLEANUP;
  }

  // Extract and validate readonly
  if (!exg_get_boolean(env, readonly_term, &readonly)) {
    *error_msg = "Readonly must be a boolean (true or false atom)";
    goto CLEANUP;
  }

  // Validate shape dimensions and binary size
  size_t required_bytes = 0;
  if (!exg_validate_shape_and_size(env, shape_term, element_size, data_bin.size, &required_bytes,
                                   error_msg)) {
    goto CLEANUP;
  }

  // Build shape JSON
  if (!exg_shape_to_json(env, shape_term, &shape_json, error_msg)) {
    goto CLEANUP;
  }

  // Get binary address
  uintptr_t address = (uintptr_t)data_bin.data;

  // Calculate required JSON buffer size
  int needed = snprintf(NULL, 0,
                        "{\"typestr\":\"%s\",\"shape\":%s,"
                        "\"data\":[%" PRIuPTR ",%s],\"version\":3}",
                        typestr, shape_json, address, readonly ? "true" : "false");

  if (needed < 0) {
    *error_msg = "Failed to calculate JSON size";
    goto CLEANUP;
  }

  // Allocate JSON buffer
  json = enif_alloc((size_t)needed + 1);
  if (json == NULL) {
    *error_msg = "Failed to allocate array interface JSON";
    goto CLEANUP;
  }

  // Build final JSON
  int written = snprintf(json, (size_t)needed + 1,
                         "{\"typestr\":\"%s\",\"shape\":%s,"
                         "\"data\":[%" PRIuPTR ",%s],\"version\":3}",
                         typestr, shape_json, address, readonly ? "true" : "false");

  if (written != needed) {
    *error_msg = "Failed to construct array interface JSON";
    goto CLEANUP;
  }

  // Success
  *json_out = json;
  json = NULL;
  ok = 1;

CLEANUP:
  if (typestr != NULL) {
    enif_free(typestr);
  }

  if (shape_json != NULL) {
    enif_free(shape_json);
  }

  if (json != NULL) {
    enif_free(json);
  }

  return ok;
}

ERL_NIF_TERM exg_get_int_size(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
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

// So we don't expose ATOM_* directly to other files, provide a wrapper function.
int exg_make_array_interface_map(ErlNifEnv *env, ERL_NIF_TERM binary_term,
                                 ERL_NIF_TERM typestr_term, ERL_NIF_TERM shape_term,
                                 ERL_NIF_TERM *out_map) {
  ERL_NIF_TERM keys[] = {ATOM_BINARY, ATOM_TYPESTR, ATOM_SHAPE};

  ERL_NIF_TERM values[] = {binary_term, typestr_term, shape_term};

  return enif_make_map_from_arrays(env, keys, values, 3, out_map);
}