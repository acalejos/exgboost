#include "exgboost.h"

// Status helpers

static ERL_NIF_TERM error(ErlNifEnv* env, const char* msg) {
    ERL_NIF_TERM atom = enif_make_atom(env, "error");
    ERL_NIF_TERM msg_term = enif_make_string(env, msg, ERL_NIF_LATIN1);
    return enif_make_tuple2(env, atom, msg_term);
}

static ERL_NIF_TERM ok(ErlNifEnv* env) {
    return enif_make_atom(env, "ok");
}

static ERL_NIF_TERM ok(ErlNifEnv* env, ERL_NIF_TERM term) {
    return enif_make_tuple2(env, ok(env), term);
}

// Argument helpers

int get(ErlNifEnv* env, ERL_NIF_TERM term, char **var) {
        unsigned len;
    int ret = enif_get_list_length(env, term, &len);

    if (!ret) {
        ErlNifBinary bin;
        ret = enif_inspect_binary(env, term, &bin);
        if (!ret) {
            return 0;
        }
        *var = (char *)enif_alloc(bin.size+1);
        strncpy(*var, (const char*)bin.data, bin.size);
        (*var)[bin.size] = '\0';
        return ret;
    }

    *var = (char *)enif_alloc(len+1);
    ret = enif_get_string(env, term, *var, len+1, ERL_NIF_LATIN1);

    if (ret > 0) {
        (*var)[ret-1] = '\0';
    } else if (ret == 0) {
        (*var)[0] = '\0';
    }

    return ret;
//     unsigned len;
//     int ret = enif_get_list_length(env, term, &len);
//     printf("Length: %d\n", len);
//     printf("Ret: %d\n", ret);
//     if (enif_is_binary(env, term)){
//         printf("Is binary\n");
//     }
//     if (!ret) {
//       ErlNifBinary bin;
//       ret = enif_inspect_binary(env, term, &bin);
//       *var = (char *)enif_alloc(bin.size+1);
//       if (!ret) {
//         goto END;
//       }
//       memcpy(*var, bin.data, bin.size);
//       (*var)[bin.size] = '\0';
//       goto END;
//     }
//     else{
//         *var = (char *)enif_alloc(len+1);
//     }
//     ret = enif_get_string(env, term, *var, len+1, ERL_NIF_LATIN1);

//     if (ret > 0) {
//       (*var)[ret-1] = '\0';
//     } else if (ret == 0) {
//       (*var)[0] = '\0';
//     } else {}
// END:
//     return ret;
}

// Bindings

ERL_NIF_TERM EXGBoostVersion(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    int major, minor, patch;
    XGBoostVersion(&major, &minor, &patch);
    return ok(env, enif_make_tuple3(env, enif_make_int(env, major), enif_make_int(env, minor), enif_make_int(env, patch)));
}

ERL_NIF_TERM EXGBuildInfo(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    char const *out = NULL;
    ERL_NIF_TERM ret = 0;
    // Don't need to free this since it's a pointer to a static string defined in the xgboost config struct
    // https://github.com/dmlc/xgboost/blob/21d95f3d8f23873a76f8afaad0fee5fa3e00eafe/src/c_api/c_api.cc#L107
    int result = XGBuildInfo(&out);
    if (result == 0) {
        ret = ok(env, enif_make_string(env, out, ERL_NIF_LATIN1));
    } else {
        ret = error(env, XGBGetLastError());
    }
    return ret;
}

ERL_NIF_TERM EXGBSetGlobalConfig(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    char *config = NULL;
    int result = -1;
    ERL_NIF_TERM ret = 0;
    if (!get(env, argv[0], &config)) {
        ret = error(env, "Config must be a string");
        goto END;
    }
    result = XGBSetGlobalConfig((char const *)config);
    if (result == 0) {
        ret = ok(env);
    } else {
        ret = error(env, XGBGetLastError());
    }
END:
    if (config != NULL) {
        enif_free(config);
        config = NULL;
    }
    return ret;
}

ERL_NIF_TERM EXGBGetGlobalConfig(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    char *out = NULL;
    ERL_NIF_TERM ret = 0;
    // No need to free out, it's a pointer to a static string defined in the xgboost config struct
    int result = XGBGetGlobalConfig((char const **)&out);
    if (result == 0) {
        ret = ok(env, enif_make_string(env, out, ERL_NIF_LATIN1));
    } else {
        ret = error(env, XGBGetLastError());
    }
    return ret;
}

ERL_NIF_TERM EXGDMatrixCreateFromFile(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    char *fname = NULL;
    int silent = 0;
    int result = -1;
    DMatrixHandle handle;
    ERL_NIF_TERM ret = 0;
    if (!get(env, argv[0], &fname)) {
        ret = error(env, "File name must be a string");
        goto END;
    }
    if (!enif_get_int(env, argv[1], &silent)) {
        ret = error(env, "Silent must be an integer");
        goto END;
    }
    struct stat st;
    if (stat(fname, &st) != 0) {
        ret = error(env, "Failed to stat file");
        goto END;
    }
    if (!S_ISREG(st.st_mode)) {
        ret = error(env, "Not a regular file");
        goto END;
    }
    // printf("Before creating from file");
    // printf("File name: %s\n", fname);
    // printf("Filename length: %ld", strlen(fname));
    result = XGDMatrixCreateFromFile("test/data/testfile.txt", 1, &handle);
    printf("After creating from file\n");
    if (result == 0) {
        ret = ok(env, enif_make_resource(env, handle));
    } else {
        ret = error(env, XGBGetLastError());
    }
END:
    printf("in END\n");
    if (fname != NULL) {
        enif_free(fname);
        fname = NULL;
    }
    return ret;
}

// Setup and Teardown

static void DMatrix_RESOURCE_TYPE_cleanup(ErlNifEnv* env, void* arg) {
    DMatrixHandle handle = *((DMatrixHandle*)arg);
    XGDMatrixFree(handle);
}

static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
    DMatrix_RESOURCE_TYPE = enif_open_resource_type(env, NULL, "DMatrix_RESOURCE_TYPE",
                                                      DMatrix_RESOURCE_TYPE_cleanup,
                                                      (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);
    if (DMatrix_RESOURCE_TYPE == NULL) {
        return 1;
    }
    return 0;
}

static int upgrade(ErlNifEnv* env, void** priv_data, void** old_priv_data, ERL_NIF_TERM load_info) {
    DMatrix_RESOURCE_TYPE = enif_open_resource_type(env, NULL, "DMatrix_RESOURCE_TYPE",
                                                      DMatrix_RESOURCE_TYPE_cleanup,
                                                      ERL_NIF_RT_TAKEOVER, NULL);
    if (DMatrix_RESOURCE_TYPE == NULL) {
        return 1;
    }
    return 0;
}

static ErlNifFunc nif_funcs[] = {
    {"exgboost_version", 0, EXGBoostVersion},
    {"exg_build_info", 0, EXGBuildInfo},
    {"exg_set_global_config", 1, EXGBSetGlobalConfig},
    {"exg_get_global_config", 0, EXGBGetGlobalConfig},
    {"exg_dmatrix_create_from_file",2,EXGDMatrixCreateFromFile}
};
ERL_NIF_INIT(Elixir.Exgboost.NIF, nif_funcs, NULL, NULL, NULL, NULL)