# Environment variables passed via elixir_make
# ERTS_INCLUDE_DIR
# MIX_APP_PATH
# MIX_ENV

TEMP ?= $(HOME)/.cache
MIX_ENV ?= dev
XGBOOST_CACHE ?= $(TEMP)/exgboost
XGBOOST_GIT_REPO ?= https://github.com/dmlc/xgboost.git

# Use tagged releases in the checks below.
XGBOOST_GIT_REV ?= v3.2.0
OLD_XGBOOST_GIT_REV ?= v3.1.3
NEW_XGBOOST_GIT_REV ?= $(XGBOOST_GIT_REV)

XGBOOST_NS = xgboost-$(XGBOOST_GIT_REV)
XGBOOST_DIR = $(XGBOOST_CACHE)/$(XGBOOST_NS)
XGBOOST_LIB_DIR = $(XGBOOST_DIR)/build/xgboost
XGBOOST_LIB_DIR_FLAG = $(XGBOOST_LIB_DIR)/exgboost.ok

.PHONY: check-xgboost-c-api compare-xgboost-c-api clean

# Set build type based on MIX_ENV
ifeq ($(MIX_ENV), prod)
	CMAKE_BUILD_TYPE = Release
else
	CMAKE_BUILD_TYPE = RelWithDebInfo
endif

# Private configuration
PRIV_DIR = $(MIX_APP_PATH)/priv
EXGBOOST_DIR = $(realpath c/exgboost)
EXGBOOST_CACHE_SO = cache/libexgboost.so
EXGBOOST_CACHE_LIB_DIR = cache/lib
EXGBOOST_SO = $(PRIV_DIR)/libexgboost.so
EXGBOOST_LIB_DIR = $(PRIV_DIR)/lib

# Build flags
CFLAGS = -I$(EXGBOOST_DIR)/include -I$(XGBOOST_LIB_DIR)/include -I$(XGBOOST_DIR) $(if $(ERTS_INCLUDE_DIR),-I$(ERTS_INCLUDE_DIR)) -fPIC -O3 -shared -std=c11

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
	@mkdir -p $(EXGBOOST_LIB_DIR)
	cp -a $(abspath $(EXGBOOST_CACHE_LIB_DIR))/. $(EXGBOOST_LIB_DIR)/ ; \
	cp -a $(abspath $(EXGBOOST_CACHE_SO)) $(EXGBOOST_SO) ;

$(EXGBOOST_CACHE_SO): $(XGBOOST_LIB_DIR_FLAG) $(C_SRCS)
	@mkdir -p $(EXGBOOST_CACHE_LIB_DIR)
	cp -R $(XGBOOST_LIB_DIR)/. $(EXGBOOST_CACHE_LIB_DIR)/
	cp $(XGBOOST_DIR)/lib/$(LIBXGBOOST) $(EXGBOOST_CACHE_LIB_DIR)
	$(CC) $(CFLAGS) $(wildcard $(EXGBOOST_DIR)/src/*.c) $(LDFLAGS) -o $(EXGBOOST_CACHE_SO)
	$(POST_INSTALL)

# This new target handles fetching the source code.
# It only runs if the .git directory inside the source folder is missing.
$(XGBOOST_DIR)/.git:
	@mkdir -p $(XGBOOST_DIR) && \
		cd $(XGBOOST_DIR) && \
		git init && \
		git remote add origin $(XGBOOST_GIT_REPO) && \
		git fetch --depth 1 --recurse-submodules origin $(XGBOOST_GIT_REV) && \
		git checkout FETCH_HEAD && \
		git submodule update --init --recursive

# This modified target now depends on the fetch target.
# It only contains the build commands.
$(XGBOOST_LIB_DIR_FLAG): $(XGBOOST_DIR)/.git
	cd $(XGBOOST_DIR) && \
		cmake -B build -S . -DCMAKE_INSTALL_PREFIX=$(XGBOOST_LIB_DIR) -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) -GNinja $(CMAKE_FLAGS) && \
		ninja -C build install
	touch $(XGBOOST_LIB_DIR_FLAG)

check-xgboost-c-api: $(XGBOOST_LIB_DIR_FLAG)
	./scripts/check_xgboost_c_api.sh \
		"$(XGBOOST_LIB_DIR)/include" \
		"$(XGBOOST_LIB_DIR)/lib/$(LIBXGBOOST)"

compare-xgboost-c-api:
	@set -eu; \
	for rev in "$(OLD_XGBOOST_GIT_REV)" "$(NEW_XGBOOST_GIT_REV)"; do \
		dir="$(XGBOOST_CACHE)/xgboost-$$rev"; \
		mkdir -p "$$dir"; \
		if [ ! -d "$$dir/.git" ]; then \
			git -C "$$dir" init; \
			git -C "$$dir" remote add origin "$(XGBOOST_GIT_REPO)"; \
		fi; \
		git -C "$$dir" fetch --depth 1 --recurse-submodules origin "$$rev"; \
		git -C "$$dir" checkout -f FETCH_HEAD; \
		git -C "$$dir" submodule update --init --recursive; \
	done; \
	./scripts/check_xgboost_c_api.sh --compare \
		"$(XGBOOST_CACHE)/xgboost-$(OLD_XGBOOST_GIT_REV)/include" \
		"$(XGBOOST_CACHE)/xgboost-$(NEW_XGBOOST_GIT_REV)/include"

clean:
	rm -rf $(EXGBOOST_CACHE_SO)
	rm -rf $(EXGBOOST_CACHE_LIB_DIR)
	rm -rf $(EXGBOOST_SO)
	rm -rf $(EXGBOOST_LIB_DIR)
	rm -rf $(XGBOOST_DIR)
	rm -rf $(XGBOOST_LIB_DIR_FLAG)
