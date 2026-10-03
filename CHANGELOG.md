# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.11.0

### Added

- Nothing

### Updated

- Updated the bundled XGBoost release from 3.1.3 to 3.2.0.
- Model persistence now uses XGBoost's stable JSON/UBJ model format while retaining support for loading legacy serialized snapshots.
- Custom-gradient training now uses `XGBoosterTrainOneIter`, replacing the deprecated `XGBoosterBoostOneIter` API.
- XGBoost C API revision checks now ignore formatting-only declaration changes and validate symbols exported by the built shared library.
- Incremental builds now refresh the packaged XGBoost library instead of nesting the new library under an existing `priv/lib` directory.
- Fix precompiled nif download; tags now X.Y.Z not vX.Y.Z.
- Remove older nif versions from precompiled list.
- Ensure checksum SHA's are part of the precompiled packages.

### Removed

- Nothing.

## 0.10.3

### Added

- `clang-format` command added to dev container Dockerfile.
- `.clang-format` file from `xgboost` Github repo itself added as the default formatting of C files in this repo.
- `xaver.clang-format"` vscode extension added to repo.

### Updated

- Formatting pass across all source and header files in `c/exgboost` directory - formatting change only no code changes.
- Formatting information added to `CHANGELOG.md`.

### Removed

- Nothing.

## 0.10.2

### Added

- Comprehensive safety validation tests added in `test/nif_test.exs` covering:
  - Invalid typestr format rejection
  - Binary size validation preventing buffer overflows
  - Boolean type strictness (only `true`/`false` atoms accepted)
  - Shape overflow protection for extremely large dimensions
  - Endianness marker validation
- `CONTRIBUTING.md` - developer guide with DO's and DON'Ts for NIF development, safety requirements, and testing procedures.
- **yyjson JSON parser**: Vendored yyjson 0.10.0 (MIT license) for robust Array Interface JSON parsing in quantile-cut operations:
  - Handles arbitrary field ordering and whitespace
  - Supports multi-dimensional shapes (up to 8 dimensions)
  - Comprehensive overflow protection in size calculations
  - Better error handling than manual string parsing
  - Single-file integration (~400KB source, compiles to ~70KB in shared library)

### Changed

- **NIF Layer Safety Improvements**:
  - Buffer overflow protection: Dynamic allocation with overflow-checked arithmetic replaces fixed-size buffers in Array Interface JSON builder
  - Strict type safety: All pointer arithmetic now uses `uintptr_t` with `PRIuPTR` formatting
  - Platform-independent integer conversions: `enif_get_ulong`/`enif_make_ulong` replaced with `enif_get_uint64`/`enif_make_uint64`
  - Comprehensive input validation: Added validation for typestr format, shape dimensions, boolean values, and binary sizes
  - Memory safety: Binary size validation ensures data buffers match expected sizes before any memory operations
  - Single cleanup path: Refactored to use consistent resource management with single cleanup labels to prevent memory leaks
  - Atomic data copying: All data returned from XGBoost is now copied atomically within NIF calls, eliminating pointer lifetime issues
  - Added static assertions and overflow checks for VLA (Variable Length Array) declarations
  - **Memory management improvements**: Refactored all binary copying to use `enif_make_new_binary()` instead of `enif_alloc_binary()` + `enif_make_binary()` for cleaner ownership semantics and automatic memory leak prevention (no manual cleanup required)

- **ArrayInterface Optimization**:
  - Removed `address` field - pointer addresses are never exposed to Elixir for safety
  - Removed `tensor` field - eliminates duplicate memory storage; tensors now reconstructed on-demand from binary data
  - Removed `Jason.Encoder` protocol implementation - no longer needed as ArrayInterface is not serialized to JSON
  - Updated `Inspect` protocol to show `readonly` directly instead of `data: [address, readonly]`
  - `get_tensor/1` now reconstructs tensors from binary data instead of caching, trading minimal performance for significant memory savings
  - Updated `from_map/1` to ignore address values from incoming data, only extracting readonly flag

- **DMatrix Improvements**:
  - **Reduced NIF argument counts**: Refactored Array Interface NIFs to use tuple arguments for cleaner API:
    - `dmatrix_create_from_sparse`: 15 → 6 arguments (3 tuples + 3 params)
    - `dmatrix_create_from_dense`: 5 → 2 arguments (1 tuple + 1 param)
    - `dmatrix_set_info_from_interface`: 6 → 3 arguments (1 tuple + 2 params)
    - Each tuple packs `{binary, typestr, shape, readonly}` for one array
    - Added `exg_get_array_interface_tuple()` helper to extract tuple components
    - Prevents argument index mistakes and makes code more maintainable
  - `get_quantile_cut/1` refactored to return maps with `:binary`, `:typestr`, `:shape` instead of JSON with memory addresses
  - All data copying happens atomically within C before returning to Elixir
  - **Hardened JSON parser**: Replaced fragile `strstr()`/`sscanf()` parsing with robust yyjson-based parser:
    - Now supports multi-dimensional shapes instead of only 1D arrays
    - Handles arbitrary JSON field ordering and whitespace
    - Added divide-by-zero protection: `if (bytes_per_elem == 0) return 0;`
    - Improved typestr parsing using `strtoul()` with errno checking
    - Comprehensive overflow protection for all size calculations
  - Consolidated typestr parsing logic - `build_tensor_from_map/1` now uses shared `ArrayInterface.parse_typestr/1` helper

- **Typestr Handling Improvements**:
  - **Explicit error handling**: Added `ArrayInterface.parse_typestr/1` (returns `{:ok, type}` or `{:error, reason}`) and `parse_typestr!/1` (raises `ArgumentError`) following Elixir conventions
  - **Better diagnostics**: Invalid typestr now raises clear error messages instead of cryptic `MatchError` or `CaseClauseError`
  - **Flattened control flow**: Refactored `parse_typestr` from 3 levels of nested `case` statements to clean `with` expression with helper function
  - **Code consolidation**: Eliminated duplicate typestr parsing logic between `ArrayInterface.get_tensor/1` and `DMatrix.build_tensor_from_map/1`
  - **Comprehensive validation**: `parse_typestr/1` validates format, type codes (i/u/f/c), and byte counts with helpful error messages
  - **Flexible error handling**: Callers can choose between tuple-based error handling (`parse_typestr/1`) or exception-based (`parse_typestr!/1`)
  - **Robust C parsing**: Replaced `atoi()` with `strtoumax()` for proper overflow detection and error handling
  - **Consistent validation across layers**: Both C (NIF) and Elixir layers now enforce the same validation rules:
    - Only little-endian (`<`) and byte-order-independent (`|`) markers accepted
    - Big-endian (`>`) rejected until byte-swapping is implemented
    - Byte-order-independent marker (`|`) only valid for single-byte types (e.g., `|i1`, `|u1`)
    - Supported type codes: `i` (signed int), `u` (unsigned int), `f` (float), `c` (complex)
    - Element size: Any syntactically valid positive integer; XGBoost validates actual type support

- **Unsafe APIs removed in this releases**:
  - `EXGBoost.NIF.get_binary_from_address/2` - arbitrary memory read primitive that could crash the BEAM VM
  - `EXGBoost.NIF.get_binary_address/1` - arbitrary memory read primitive that could crash the BEAM VM
  - `exg_get_binary_from_address` C NIF function and all declarations
  - `exg_get_binary_address` C NIF function and all declarations
  - Address-based tensor reconstruction in `ArrayInterface.get_tensor/1`
  - Tensor caching in `ArrayInterface` struct

### Fixed

- Cross-platform compatibility: Fixed `unsigned long` → `ErlNifUInt64` conversions to prevent data truncation on Windows (LP64 vs LLP64 calling conventions)
- Memory safety: Eliminated all pointer lifetime gaps where Elixir code held addresses to freed memory
- Buffer safety: All shape-to-JSON conversions now use dynamic allocation with proper bounds checking

### Security

- Eliminated arbitrary memory read primitive that allowed reading from any address
- All binary data is now validated for size before access, preventing buffer overflows
- Pointer addresses are never exposed to Elixir, preventing use-after-free vulnerabilities
- Strict type validation prevents type confusion attacks

## [0.9.1]

### Removed

- Kino and Livebook Integration; `kino` doesn't seem like it's under active development, make this a pure library.
- Mark `EXGBoost.DMatrix.from_file` as deprecated.
