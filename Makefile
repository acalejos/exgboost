# elixir_make supplies MIX_APP_PATH and ERTS_INCLUDE_DIR.
.DEFAULT_GOAL := all
XGBOOST_GIT_REPO ?= https://github.com/dmlc/xgboost.git
# XGBoost v3.4.2; pin the immutable commit, not a movable tag.
XGBOOST_GIT_REV ?= fdf0888bedddbd444d72994d845c59b3ca182c5b
XGBOOST_CACHE ?= $(CURDIR)/cache/xgboost
BUILD_TARGET := $(shell uname -s)-$(shell uname -m)
XGBOOST_DIR ?= $(XGBOOST_CACHE)/$(XGBOOST_GIT_REV)/source
XGBOOST_BUILD := $(XGBOOST_CACHE)/$(XGBOOST_GIT_REV)/$(BUILD_TARGET)/build
XGBOOST_INSTALL := $(XGBOOST_CACHE)/$(XGBOOST_GIT_REV)/$(BUILD_TARGET)/install
PRIV_DIR := $(MIX_APP_PATH)/priv
NIF := $(PRIV_DIR)/libexgboost.so
SRC := $(wildcard c/exgboost/src/*.c)
HEADERS := $(wildcard c/exgboost/include/*.h)
BUILD_JOBS ?= 2
USE_OPENMP ?= ON
CFLAGS ?= -O3
CPPFLAGS += -Ic/exgboost/include -I$(XGBOOST_INSTALL)/include -I$(ERTS_INCLUDE_DIR)
CFLAGS += -fPIC -std=c11 -Wall -Werror=implicit-function-declaration
LDFLAGS += -L$(PRIV_DIR)/lib -lxgboost

ifeq ($(shell uname -s),Darwin)
LIBXGBOOST := libxgboost.dylib
LDFLAGS += -undefined dynamic_lookup -Wl,-rpath,@loader_path/lib
else
LIBXGBOOST := libxgboost.so
LDFLAGS += -Wl,-rpath,'$$ORIGIN/lib'
endif

.PHONY: all xgboost nif clean distclean
all: xgboost
	$(MAKE) nif

# CMake tracks compiler/options and rebuilds incrementally; no stale success marker.
xgboost: $(XGBOOST_DIR)/.exgboost-source
	cmake -S "$(XGBOOST_DIR)" -B "$(XGBOOST_BUILD)" \
	  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(XGBOOST_INSTALL)" \
	  -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_MESSAGE=NEVER -DCMAKE_C_COMPILER="$(CC)" -DCMAKE_CXX_COMPILER="$(CXX)" \
	  -DKEEP_BUILD_ARTIFACTS_IN_BINARY_DIR=ON -DUSE_CUDA=OFF -DUSE_OPENMP=$(USE_OPENMP) $(CMAKE_FLAGS)
	cmake --build "$(XGBOOST_BUILD)" --parallel $(BUILD_JOBS)
	cmake --install "$(XGBOOST_BUILD)"
	mkdir -p "$(PRIV_DIR)/lib" "$(PRIV_DIR)/licenses"
	cmp -s "$(XGBOOST_INSTALL)/lib/$(LIBXGBOOST)" "$(PRIV_DIR)/lib/$(LIBXGBOOST)" || cp "$(XGBOOST_INSTALL)/lib/$(LIBXGBOOST)" "$(PRIV_DIR)/lib/$(LIBXGBOOST)"
ifeq ($(shell uname -s),Darwin)
	ln -sf libxgboost.dylib "$(PRIV_DIR)/lib/libxgboost.3.dylib"
else
	ln -sf libxgboost.so "$(PRIV_DIR)/lib/libxgboost.so.3"
endif
	cp "$(XGBOOST_DIR)/LICENSE" "$(PRIV_DIR)/licenses/XGBoost-LICENSE"
	cp "$(XGBOOST_DIR)/dmlc-core/LICENSE" "$(PRIV_DIR)/licenses/dmlc-core-LICENSE"
	head -n 22 c/exgboost/include/yyjson.h > "$(PRIV_DIR)/licenses/yyjson-LICENSE"
ifeq ($(shell uname -s),Darwin)
	bash scripts/bundle_macos.sh "$(PRIV_DIR)"
endif

$(XGBOOST_DIR)/.exgboost-source:
	mkdir -p "$(XGBOOST_DIR)"
	git -C "$(XGBOOST_DIR)" init
	git -C "$(XGBOOST_DIR)" remote add origin "$(XGBOOST_GIT_REPO)" || git -C "$(XGBOOST_DIR)" remote set-url origin "$(XGBOOST_GIT_REPO)"
	git -C "$(XGBOOST_DIR)" fetch --depth 1 origin "$(XGBOOST_GIT_REV)"
	git -C "$(XGBOOST_DIR)" checkout --detach FETCH_HEAD
	git -C "$(XGBOOST_DIR)" submodule update --init --recursive --depth 1
	touch "$@"

nif: $(NIF)
$(NIF): $(SRC) $(HEADERS) $(PRIV_DIR)/lib/$(LIBXGBOOST) Makefile
	$(CC) $(CPPFLAGS) $(CFLAGS) -shared $(SRC) $(LDFLAGS) -o "$@"
ifeq ($(shell uname -s),Darwin)
	install_name_tool -change @rpath/libxgboost.3.dylib @loader_path/lib/libxgboost.dylib "$@"
endif

# Keep the expensive upstream cache for routine cleans.
clean:
	rm -f "$(NIF)"
	rm -rf "$(PRIV_DIR)/lib" "$(PRIV_DIR)/licenses"
distclean: clean
	rm -rf "$(XGBOOST_CACHE)"

check-xgboost-c-api: xgboost
	bash scripts/check_xgboost_c_api.sh "$(XGBOOST_INSTALL)/include" "$(XGBOOST_INSTALL)/lib/$(LIBXGBOOST)"
