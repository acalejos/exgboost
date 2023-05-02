# Environment variables passed via elixir_make
# ERTS_INCLUDE_DIR
# MIX_APP_PATH

TEMP ?= $(HOME)/.cache
XGBOOST_CACHE ?= $(TEMP)/exgboost
XGBOOST_GIT_REPO ?= https://github.com/dmlc/xgboost.git
XGBOOST_GIT_REV ?= 08ce495b5de973033160e7c7b650abf59346a984# v1.7.5 Patch Release (https://github.com/dmlc/xgboost/releases/tag/v1.7.5)
XGBOOST_NS = xgboost-$(XGBOOST_GIT_REV)
XGBOOST_DIR = $(XGBOOST_CACHE)/$(XGBOOST_NS)
XGBOOST_LIB_DIR = $(XGBOOST_DIR)/build/xgboost
XGBOOST_LIB_DIR_FLAG = $(XGBOOST_LIB_DIR)/exgboost.ok

# Private configuration
PRIV_DIR = $(MIX_APP_PATH)/priv
EXGBOOST_DIR = c/exgboost
EXGBOOST_CACHE_SO = cache/libexgboost.so
EXGBOOST_CACHE_LIB_DIR = cache/lib
EXGBOOST_SO = $(PRIV_DIR)/libexgboost.so
EXGBOOST_LIB_DIR = $(PRIV_DIR)/lib

# Build flags
CFLAGS = -I$(ERTS_INCLUDE_DIR) -I$(EXGBOOST_DIR)/include -I$(XGBOOST_LIB_DIR)/include -I$(XGBOOST_DIR) -fPIC -O3 --verbose -shared -std=c11
# TODO: Check CUDA_TOOLKIT_VERSION before setting BUILD_WITH_CUDA_CUB to ON
ifeq ($(USE_CUDA), true)
	CMAKE_FLAGS += -DUSE_CUDA=ON -DBUILD_WITH_CUDA_CUB=ON
else
	CMAKE_FLAGS += -DUSE_CUDA=OFF -DBUILD_WITH_CUDA_CUB=OFF
endif

#C_SRCS = $(EXGBOOST_DIR)/src/exgboost.c $(EXGBOOST_DIR)/include/exgboost.h
C_SRCS = $(wildcard $(EXGBOOST_DIR)/src/*.c) $(wildcard $(EXGBOOST_DIR)/include/*.h)

LDFLAGS = -L$(EXGBOOST_CACHE_LIB_DIR)/lib -lxgboost

ifeq ($(shell uname -s), Darwin)
	POST_INSTALL = install_name_tool $(EXGBOOST_CACHE_SO) -change @rpath/libxgboost.dylib @loader_path/lib/lib/libxgboost.dylib
	LDFLAGS += -flat_namespace -undefined suppress
	ifeq ($(USE_LLVM_BREW), true)
		LLVM_PREFIX=$(shell brew --prefix llvm)
		CMAKE_FLAGS += -DCMAKE_CXX_COMPILER=$(LLVM_PREFIX)/bin/clang++
	endif
else
	# Use a relative RPATH, so at runtime libexgboost.so looks for libxgboost.so
	# in ./lib regardless of the absolute location. This way priv can be safely
	# packed into an Elixir release. Also, we use $$ to escape Makefile variable
	# and single quotes to escape shell variable
	LDFLAGS += -Wl,-rpath,'$$ORIGIN/lib'
	POST_INSTALL = $(NOOP)
endif

$(EXGBOOST_SO): $(EXGBOOST_CACHE_SO)
	@ mkdir -p $(PRIV_DIR)
	@ if [ "${MIX_BUILD_EMBEDDED}" = "true" ]; then \
		cp -a $(abspath $(EXGBOOST_CACHE_LIB_DIR)) $(EXGBOOST_LIB_DIR) ; \
		cp -a $(abspath $(EXGBOOST_CACHE_SO)) $(EXGBOOST_SO) ; \
	else \
		ln -sf $(abspath $(EXGBOOST_CACHE_LIB_DIR)) $(EXGBOOST_LIB_DIR) ; \
		ln -sf $(abspath $(EXGBOOST_CACHE_SO)) $(EXGBOOST_SO) ; \
	fi

$(EXGBOOST_CACHE_SO): $(XGBOOST_LIB_DIR_FLAG) $(C_SRCS)
	@mkdir -p cache
	cp -a $(XGBOOST_LIB_DIR) $(EXGBOOST_CACHE_LIB_DIR)
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
			cmake -DCMAKE_INSTALL_PREFIX=$(XGBOOST_LIB_DIR) -B build . $(CMAKE_FLAGS) && \
			make -C build -j install
		touch $(XGBOOST_LIB_DIR_FLAG)

clean:
	rm -rf $(EXGBOOST_CACHE_SO)
	rm -rf $(EXGBOOST_CACHE_LIB_DIR)
	rm -rf $(EXGBOOST_SO)
	rm -rf $(EXGBOOST_LIB_DIR)
	rm -rf $(XGBOOST_DIR)