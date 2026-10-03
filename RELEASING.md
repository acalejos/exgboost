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

## One-time Hex setup

Create a publishing API key in your [Hex dashboard](https://hex.pm/dashboard/keys)
with API write permission, then save it as the **`HEX_API_KEY`** repository secret
in [GitHub Actions settings](https://github.com/acalejos/exgboost/settings/secrets/actions).
This uses the API-key authentication described in [Hex's publishing guide](https://hex.pm/docs/publish#publishing-from-ci).
The key is only supplied to the final upload step; PR builds and dry runs do not use it.

## Ship a release

1. Set `@version` in `mix.exs`, update the README/notebook installation examples,
   and date the corresponding changelog entry. Merge the change with green CI.
2. From the matching clean `main` checkout, push the version tag. For 0.6.0:

   ```sh
   python3 scripts/check_release_tag.py v0.6.0
   git tag v0.6.0
   git push origin v0.6.0
   ```

   Actions builds and tests all four native archives, calculates `checksum.exs`,
   embeds it in the Hex package, and builds the documentation using that same
   native archive. Fresh consumers on all four platforms use the real downloader
   and are forbidden from compiling XGBoost. Only after every check passes does
   Actions create a **draft** GitHub release with the complete payloads.
3. Inspect and publish that draft in GitHub, or run:

   ```sh
   gh release edit v0.6.0 --draft=false
   ```

   The **Publish Hex** workflow then verifies the published release against the
   tagged checkout, tests an unauthenticated consumer download from the public
   GitHub URL, and uploads the exact CI-built package and documentation to Hex.

**No local native builds, checksum copying, or package rebuilding are required.**
Publishing the GitHub release comes first, so the URLs embedded in Hex already
exist. The naming contract is package `0.6.0`, Git tag `v0.6.0`, and native archive
`exgboost-nif-2.17-<target>-0.6.0.tar.gz`. The version in `mix.exs` generates the
GitHub download URL; CI rejects mismatched tags.

## Inspect or retry publication

Run the publication workflow manually against an already-published GitHub release.
The default performs all validation and the public consumer test without uploading:

```sh
gh workflow run publish.yml --ref main -f tag=v0.6.0
# Explicitly publish, or resume after a missing secret/docs upload failure:
gh workflow run publish.yml --ref main -f tag=v0.6.0 -f publish=true
```

If the same package is already on Hex, the publisher compares its CDN tarball
byte for byte, skips the package upload, and publishes the documentation. A
different package at that version fails; it is never overwritten automatically.
Missing or altered assets, incomplete manifests, wrong commits, and stale package
contents also fail before upload. No failure path regenerates archives or changes
checksums. Resolve the failure and rerun the workflow.

The draft and CI artifacts contain the four native archives and SHA256 sidecars,
`checksum.exs`, `exgboost-<version>.tar`, `exgboost-<version>-docs.tar.gz`,
`release.json` (source commit and native hashes), and `SHA256SUMS` for every payload.
Package publication uses [Hex's documented HTTP API](https://github.com/hexpm/specifications/blob/main/apiary.apib)
to upload those existing tarballs, rather than rebuilding with `mix hex.publish`.
For a local dry run, download the complete bundle into `release/` in its matching
checkout and run `python3 scripts/publish_hex.py release`.

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
