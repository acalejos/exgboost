# Environment variables passed via elixir_make
# ERTS_INCLUDE_DIR
# MIX_APP_PATH

TEMP ?= $(HOME)/.cache
XGBOOST_CACHE ?= $(TEMP)/exgboost
XGBOOST_GIT_REPO ?= https://github.com/dmlc/xgboost.git
# 2.0.2 Release Commit
XGBOOST_GIT_REV ?= 41ce8f28b269dbb7efc70e3a120af3c0bb85efe3
XGBOOST_NS = xgboost-$(XGBOOST_GIT_REV)
XGBOOST_DIR = $(XGBOOST_CACHE)/$(XGBOOST_NS)
XGBOOST_LIB_DIR = $(XGBOOST_DIR)/build/xgboost
XGBOOST_LIB_DIR_FLAG = $(XGBOOST_LIB_DIR)/exgboost.ok

# Private configuration
PRIV_DIR = $(MIX_APP_PATH)/priv
EXGBOOST_DIR = $(realpath c/exgboost)
EXGBOOST_CACHE_SO = cache/libexgboost.so
EXGBOOST_CACHE_LIB_DIR = cache/lib
EXGBOOST_SO = $(PRIV_DIR)/libexgboost.so
EXGBOOST_LIB_DIR = $(PRIV_DIR)/lib

# Build flags
CFLAGS = -I$(EXGBOOST_DIR)/include -I$(XGBOOST_LIB_DIR)/include -I$(XGBOOST_DIR) -I$(ERTS_INCLUDE_DIR)  -fPIC -O3 --verbose -shared -std=c11

C_SRCS = $(wildcard $(EXGBOOST_DIR)/src/*.c) $(wildcard $(EXGBOOST_DIR)/include/*.h)

LDFLAGS = -L$(EXGBOOST_CACHE_LIB_DIR) -lxgboost

ifeq ($(shell uname -s), Darwin)
	POST_INSTALL = install_name_tool $(EXGBOOST_CACHE_SO) -change @rpath/libxgboost.dylib @loader_path/lib/libxgboost.dylib
	LDFLAGS += -flat_namespace -undefined suppress
	LIBXGBOOST = libxgboost.dylib
	ifeq ($(USE_LLVM_BREW), true)
		LLVM_PREFIX=$(shell brew --prefix llvm)
		CMAKE_FLAGS += -DCMAKE_CXX_COMPILER=$(LLVM_PREFIX)/bin/clang++
	endif
else
	LIBXGBOOST = libxgboost.so
	LDFLAGS += -Wl,-rpath,'$$ORIGIN/lib'
	LDFLAGS += -Wl,--allow-multiple-definition
	POST_INSTALL = $(NOOP)
endif

$(EXGBOOST_SO): $(EXGBOOST_CACHE_SO)
	@ mkdir -p $(PRIV_DIR)
	cp -a $(abspath $(EXGBOOST_CACHE_LIB_DIR)) $(EXGBOOST_LIB_DIR) ; \
	cp -a $(abspath $(EXGBOOST_CACHE_SO)) $(EXGBOOST_SO) ;

$(EXGBOOST_CACHE_SO): $(XGBOOST_LIB_DIR_FLAG) $(C_SRCS)
	@mkdir -p cache
	cp -a $(XGBOOST_LIB_DIR) $(EXGBOOST_CACHE_LIB_DIR)
	mv $(XGBOOST_LIB_DIR)/lib/$(LIBXGBOOST) $(EXGBOOST_CACHE_LIB_DIR)
	$(CC) $(CFLAGS) $(wildcard $(EXGBOOST_DIR)/src/*.c) $(LDFLAGS) -o $(EXGBOOST_CACHE_SO)
	$(POST_INSTALL)

$(XGBOOST_LIB_DIR_FLAG):
		rm -rf $(XGBOOST_DIR) && \
		mkdir -p $(XGBOOST_DIR) && \
			cd $(XGBOOST_DIR) && \
			git init && \
			git remote add origin $(XGBOOST_GIT_REPO) && \
			git fetch --depth 1 --recurse-submodules origin $(XGBOOST_GIT_REV) && \
			git checkout FETCH_HEAD && \
			git submodule update --init --recursive && \
			sed 's|learner_parameters\["generic_param"\] = ToJson(ctx_);|&\nlearner_parameters\["default_metric"\] = String(obj_->DefaultEvalMetric());|' src/learner.cc > src/learner.cc.tmp && mv src/learner.cc.tmp src/learner.cc && \
			cmake -DCMAKE_INSTALL_PREFIX=$(XGBOOST_LIB_DIR) -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -B build . $(CMAKE_FLAGS) && \
			make -C build -j1 install
		touch $(XGBOOST_LIB_DIR_FLAG)

clean:
	rm -rf $(EXGBOOST_CACHE_SO)
	rm -rf $(EXGBOOST_CACHE_LIB_DIR)
	rm -rf $(EXGBOOST_SO)
	rm -rf $(EXGBOOST_LIB_DIR)
	rm -rf $(XGBOOST_DIR)
	rm -rf $(XGBOOST_LIB_DIR_FLAG)
