#include "booster.h"

ERL_NIF_TERM EXGBoostVersion(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    int major, minor, patch;
    XGBoostVersion(&major, &minor, &patch);
    return ok(env, enif_make_tuple3(env, enif_make_int(env, major), enif_make_int(env, minor), enif_make_int(env, patch)));
}

ERL_NIF_TERM EXGBuildInfo(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    char const *out = NULL;
    int result = -1;
    ERL_NIF_TERM ret = 0;
    // Don't need to free this since it's a pointer to a static string defined in the xgboost config struct
    // https://github.com/dmlc/xgboost/blob/21d95f3d8f23873a76f8afaad0fee5fa3e00eafe/src/c_api/c_api.cc#L107
    if (argc != 0) {
        ret = error(env, "Wrong number of arguments");
        goto END;
    }
    result = XGBuildInfo(&out);
    if (result == 0) {
        ret = ok(env, enif_make_string(env, out, ERL_NIF_LATIN1));
    } else {
        ret = error(env, XGBGetLastError());
    }
END:
    return ret;
}

ERL_NIF_TERM EXGBSetGlobalConfig(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    char *config = NULL;
    int result = -1;
    ERL_NIF_TERM ret = 0;
    if (argc != 1) {
        ret = error(env, "Wrong number of arguments");
        goto END;
    }
    if (!get_string(env, argv[0], &config)) {
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
    int result = -1;
    ERL_NIF_TERM ret = 0;
    if (argc != 0) {
        ret = error(env, "Wrong number of arguments");
        goto END;
    }
    // No need to free out, it's a pointer to a static string defined in the xgboost config struct
    result = XGBGetGlobalConfig((char const **)&out);
    if (result == 0) {
        ret = ok(env, enif_make_string(env, out, ERL_NIF_LATIN1));
    } else {
        ret = error(env, XGBGetLastError());
    }
END:
    return ret;
}