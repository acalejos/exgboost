#include "utils.h"

ERL_NIF_TERM error(ErlNifEnv* env, const char* msg) {
    ERL_NIF_TERM atom = enif_make_atom(env, "error");
    ERL_NIF_TERM msg_term = enif_make_string(env, msg, ERL_NIF_LATIN1);
    return enif_make_tuple2(env, atom, msg_term);
}

ERL_NIF_TERM ok(ErlNifEnv* env) {
    return enif_make_atom(env, "ok");
}

ERL_NIF_TERM ok(ErlNifEnv* env, ERL_NIF_TERM term) {
    return enif_make_tuple2(env, ok(env), term);
}

void DMatrix_RESOURCE_TYPE_cleanup(ErlNifEnv* env, void* arg) {
    DMatrixHandle handle = *((DMatrixHandle*)arg);
    XGDMatrixFree(handle);
}

// Argument helpers

int get_string(ErlNifEnv* env, ERL_NIF_TERM term, char **var) {
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
}

int get_list(ErlNifEnv* env, ERL_NIF_TERM term, double **out) {
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
        ret = enif_get_double(env, head, &((*out)[i]));
        if (!ret) {
            return 0;
        }
        i++;
    }
    return 1;
}