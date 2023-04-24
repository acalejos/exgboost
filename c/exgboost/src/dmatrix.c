#include "dmatrix.h"

ERL_NIF_TERM EXGDMatrixCreateFromFile(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    char *fname = NULL;
    int silent = 0;
    int result = -1;
    DMatrixHandle handle;
    ERL_NIF_TERM ret = 0;
    if (argc != 2) {
        ret = error(env, "Wrong number of arguments");
        goto END;
    }
    if (!get_string(env, argv[0], &fname)) {
        ret = error(env, "File name must be a string");
        goto END;
    }
    if (!enif_get_int(env, argv[1], &silent)) {
        ret = error(env, "Silent must be an integer");
        goto END;
    }
    result = XGDMatrixCreateFromFile("test/data/testfile.txt", 1, &handle);
    printf("After creating from file\n");
    if (result == 0) {
        ret = ok(env, enif_make_resource(env, handle));
    } else {
        ret = error(env, XGBGetLastError());
    }
END:
    if (fname != NULL) {
        enif_free(fname);
        fname = NULL;
    }
    return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromMat(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
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
        ret = error(env, "Wrong number of arguments");
        goto END;
    }
    if (!enif_inspect_binary(env, argv[0], &bin)) {
        ret = error(env, "Data must be a binary");
        goto END;
    }
    if (!enif_get_int(env, argv[1], &nrow)) {
        ret = error(env, "Nrow must be an integer");
        goto END;
    }
    if (!enif_get_int(env, argv[2], &ncol)) {
        ret = error(env, "Ncol must be an integer");
        goto END;
    }
    if (!enif_get_double(env, argv[3], &missing)) {
        ret = error(env, "Missing must be a float");
        goto END;
    }
    mat = (float *)bin.data;
    num_floats = bin.size / sizeof(float);
    if (num_floats != nrow * ncol) {
        ret = error(env, "Data size does not match nrow and ncol");
        goto END;
    }
    // The DMatrix wlil keep ahold of this data, so we don't need to free it
    // Will be freed when DMatrix is freed in resource destructor
    result = XGDMatrixCreateFromMat(mat, (bst_ulong)nrow, (bst_ulong)ncol, missing, &handle);
    if (result == 0) {
        ret = ok(env, enif_make_resource(env, handle));
        enif_release_resource(handle);
    } else {
        ret = error(env, XGBGetLastError());
    }
END:
    return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromCSR(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    int result = -1;
    char *indptr = NULL;
    char *indices = NULL;
    char *data = NULL;
    int ncol = 0;
    char *config = NULL;
    DMatrixHandle handle;
    ERL_NIF_TERM ret = 0;
    if (argc != 5) {
        ret = error(env, "Wrong number of arguments");
        goto END;
    }
    if (!get_string(env, argv[0], &indptr)) {
        ret = error(env, "Indptr must be a string");
        goto END;
    }
    if (!get_string(env, argv[1], &indices)) {
        ret = error(env, "Indices must be a string");
        goto END;
    }
    if (!get_string(env, argv[2], &data)) {
        ret = error(env, "Data must be a string");
        goto END;
    }
    if (!enif_get_int(env, argv[3], &ncol)) {
        ret = error(env, "Ncol must be an integer");
        goto END;
    }
    if (!get_string(env, argv[4], &config)) {
        ret = error(env, "Config must be a string");
        goto END;
    }
    printf("indptr: %s\n", indptr);
    printf("indices: %s\n", indices);
    printf("data: %s\n", data);
    printf("ncol: %d\n", ncol);
    printf("config: %s\n", config);
    result = XGDMatrixCreateFromCSR(indptr, indices, data, ncol, config, &handle);
    if (result == 0) {
        ret = ok(env, enif_make_resource(env, handle));
        enif_release_resource(handle);
    } else {
        ret = error(env, XGBGetLastError());
    }
END:
    return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromCSREx(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary indptr_bin;
    ErlNifBinary indices_bin;
    ErlNifBinary data_bin;
    int result = -1;
    uint64_t *indptr = NULL;
    uint32_t *indices = NULL;
    float *data = NULL;
    uint32_t nindptr = 0;
    uint64_t nelem = 0;
    uint64_t ncol = 0;
    DMatrixHandle handle;
    ERL_NIF_TERM ret = 0;
    if (argc != 6) {
        ret = error(env, "Wrong number of arguments");
        goto END;
    }
    if (!enif_inspect_binary(env, argv[0], &indptr_bin)) {
        ret = error(env, "Indptr must be a binary of uint64_t");
        goto END;
    }
    if (!enif_inspect_binary(env, argv[1], &indices_bin)) {
        ret = error(env, "Indices must be a binary of uint64_t");
        goto END;
    }
    if (!enif_inspect_binary(env, argv[2], &data_bin)) {
        ret = error(env, "Data must be a binary of uint64_t");
        goto END;
    }
    if (!enif_get_uint(env, argv[3], &nindptr)) {
        ret = error(env, "Nindptr must be a uint64_t");
        goto END;
    }
    if (!enif_get_uint64(env, argv[4], &nelem)) {
        ret = error(env, "Nelem must be a uint64_t");
        goto END;
    }
    if (!enif_get_uint64(env, argv[5], &ncol)) {
        ret = error(env, "Ncol must be a uint64_t");
        goto END;
    }
    indptr = (uint64_t *)indptr_bin.data;
    indices = (uint32_t *)indices_bin.data;
    data = (float *)data_bin.data;
    if (indptr_bin.size != nindptr * sizeof(uint64_t)) {
        ret = error(env, "Indptr size does not match nindptr");
        goto END;
    }
    if (data_bin.size != nelem * sizeof(float)) {
        ret = error(env, "Data size does not match nelem");
        goto END;
    }
    result = XGDMatrixCreateFromCSREx(indptr, indices, data, nindptr, nelem, ncol, &handle);
    if (result == 0) {
        ret = ok(env, enif_make_resource(env, handle));
        enif_release_resource(handle);
    } else {
        ret = error(env, XGBGetLastError());
    }
END:
    return ret b;
}