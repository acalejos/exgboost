#!/usr/bin/env python3
"""Exercise the real precompiler from an unpacked Hex package, with source builds forbidden."""
import argparse
import functools
import http.server
import os
import subprocess
import tempfile
import threading
from pathlib import Path
from release_tools import hex_files, version


def smoke(directory, public=False):
    value = version()
    files = hex_files(directory / f"exgboost-{value}.tar", value)
    server = None
    try:
        with tempfile.TemporaryDirectory(prefix="exgboost-hex-") as temporary:
            stage = Path(temporary)
            package = stage / "package"
            package.mkdir()
            for name, content in files.items():
                destination = package / name
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(content)
            if not public:
                handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(directory.resolve()))
                server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
                threading.Thread(target=server.serve_forever, daemon=True).start()
                path = package / "mix.exs"
                source = path.read_text()
                old = 'https://github.com/acalejos/exgboost/releases/download/v#{@version}/'
                if old not in source:
                    raise ValueError("Missing release URL template")
                # The distributed package remains unchanged; only this isolated test fixture uses localhost.
                path.write_text(source.replace(old, f"http://127.0.0.1:{server.server_port}/"))
            (package / "Makefile").write_text(".PHONY: all\nall:\n\t@echo 'Source fallback is forbidden in the Hex consumer smoke test' >&2\n\t@exit 1\n")
            (stage / "mix.exs").write_text('''defmodule Consumer.MixProject do
  use Mix.Project
  def project, do: [app: :consumer, version: "0.1.0", deps: [{:exgboost, path: "package"}]]
end
''')
            env = dict(os.environ, MIX_ENV="prod", EXGBOOST_BUILD="false", ELIXIR_MAKE_CACHE_DIR=str(stage / "native-cache"))
            # Do not let a caller's build/cache/toolchain overrides reuse previously compiled files.
            for name in ("MIX_BUILD_PATH", "MIX_DEPS_PATH", "XGBOOST_DIR", "XGBOOST_CACHE"):
                env.pop(name, None)
            for command in (["mix", "deps.get"], ["mix", "compile", "--warnings-as-errors"],
                            ["mix", "run", "--no-compile", str((Path.cwd() / "scripts/smoke.exs").resolve())]):
                subprocess.run(command, cwd=stage, env=env, check=True)
            archives = list((stage / "native-cache").glob("*.tar.gz"))
            if len(archives) != 1 or archives[0].name not in files["checksum.exs"].decode():
                raise ValueError("Consumer did not download exactly one checked release archive")
            print(f"Fresh Hex consumer downloaded {archives[0].name}; no XGBoost compilation")
    finally:
        if server:
            server.shutdown()
            server.server_close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--public", action="store_true", help="Use the published GitHub URL instead of a local fixture server")
    args = parser.parse_args()
    smoke(args.directory, args.public)
