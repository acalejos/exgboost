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
END:
    return ret;
}