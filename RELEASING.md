# Releasing EXGBoost

The native distribution uses XGBoost 3.4.2 at the immutable commit pinned in
`Makefile`. Source builds do not patch upstream code. A NIF built on OTP 26
(ABI 2.17) is reused on newer OTP releases. Each architecture builds on its own
native runner; cross compilation is deliberately rejected.

## Validate a change

```sh
mix deps.get
EXGBOOST_BUILD=true mix quality
EXGBOOST_BUILD=true MIX_ENV=test mix coveralls.html
```

Coverage measures Elixir code; it does not measure C or upstream C++ coverage.
The NIF stubs are excluded. CI retains JSON coverage reports as artifacts; no
external coverage service or token is required. The initial coverage report is
an honest baseline, with no artificial percentage gate.

Pull requests also run the four-platform native packaging workflow. It tests
source builds, creates and inspects archives, loads each archive in a fresh BEAM,
and builds a Hex package containing all four checksums. Download the
`hex-package` artifact to inspect the exact deliverable.

## Prepare a release

1. Update `@version` in `mix.exs`, `CHANGELOG.md`, and the README installation example.
2. Merge the maintenance change after both workflows pass.
3. Tag that commit as `v<VERSION>` and push the tag. The native workflow creates
   a **draft** GitHub release after all platforms and the Hex packaging job pass.
4. Inspect the draft's four native archives, SHA256 sidecars, `SHA256SUMS`,
   `checksum.exs`, and `exgboost-<VERSION>.tar`.
5. Publish the GitHub release before publishing Hex, so downloads are reachable.
6. Download `checksum.exs` from that release into the matching clean tagged
   checkout. Run `MIX_ENV=docs mix deps.get`, `mix hex.build`, and compare the
   package contents with the CI package. Run `mix hex.publish` to publish the
   package and documentation using your Hex credentials.

Hex publishing remains an explicit maintainer command. Never publish a package
without its complete checksum manifest, or regenerate checksums from unchecked
remote assets. `scripts/release_checksums.exs` computes SHA256 from the actual
archives and fails if any platform is missing or unexpected.

## Reproduce a native package locally

```sh
MIX_ENV=prod mix deps.get
EXGBOOST_BUILD=true MIX_ENV=prod ELIXIR_MAKE_CACHE_DIR="$PWD/cache/precompiled" \
  mix elixir_make.precompile
# Select the archive and the target printed by the precompiler:
bash scripts/verify_archive.sh cache/precompiled/<archive>.tar.gz <target>
MIX_ENV=prod bash scripts/smoke_archive.sh cache/precompiled/<archive>.tar.gz
```

Use OTP 26 to reproduce release ABI 2.17. A newer OTP emits a different archive
ABI and is useful for testing, but the release manifest deliberately rejects it.
Source builds support `BUILD_JOBS`, `USE_OPENMP`, `CMAKE_FLAGS`, `XGBOOST_CACHE`,
and `XGBOOST_GIT_REV`. `EXGBOOST_BUILD=true` bypasses downloads. `make clean`
removes installed native files while retaining the upstream build cache;
`make distclean` also removes that cache. Use a separate cache when building
with substantially different toolchains or experimental upstream revisions.

## Update XGBoost

Pin the release's full commit SHA in `Makefile` and update the version assertion
in `scripts/smoke.exs`. Run the complete tests and native workflow, review
`include/xgboost/c_api.h` and upstream release notes, and run
`scripts/check_xgboost_c_api.sh <installed-include> <installed-library>`.
Early stopping discovers the actual default metric through upstream evaluation;
it does not depend on a patched `default_metric` JSON field.
