#!/usr/bin/env python3
"""Publish the verified CI tarballs directly through Hex's documented HTTP API."""
import argparse
import json
import os
import urllib.error
import urllib.request
from pathlib import Path
from release_tools import digest, verify_bundle


class HexClient:
    def __init__(self, key, api="https://hex.pm/api", repository="https://repo.hex.pm"):
        self.key, self.api, self.repository = key, api, repository

    def request(self, path, payload=None):
        headers = {"Accept": "application/json", "User-Agent": "EXGBoost-release/1.0"}
        if payload is not None:
            headers.update({"Authorization": self.key, "Content-Type": "application/octet-stream"})
        request = urllib.request.Request(self.api + path, data=payload, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                body = response.read()
                return json.loads(body) if body else {}
        except urllib.error.HTTPError as error:
            if error.code == 404 and payload is None:
                return None
            detail = error.read().decode(errors="replace").replace(self.key, "[REDACTED]")
            raise ValueError(f"Hex request failed ({error.code}): {detail}") from None

    def publish(self, directory, value):
        package = directory / f"exgboost-{value}.tar"
        release_path = f"/packages/exgboost/releases/{value}"
        if self.request(release_path) is not None:
            # Hex's legacy API checksum is an inner checksum, not SHA256 of the .tar.
            # Compare the actual CDN tarball so a retry never overwrites a different release.
            request = urllib.request.Request(f"{self.repository}/tarballs/{package.name}",
                                             headers={"User-Agent": "EXGBoost-release/1.0"})
            with urllib.request.urlopen(request, timeout=120) as response:
                existing = response.read()
            if existing != package.read_bytes():
                raise ValueError("This Hex version already contains a different package; bump the version")
            print("Identical Hex package already published; continuing with documentation")
        else:
            self.request("/packages/exgboost/releases?replace=false", package.read_bytes())
            print(f"Published the CI-built package (sha256:{digest(package)})")
        self.request(release_path + "/docs", (directory / f"exgboost-{value}-docs.tar.gz").read_bytes())
        print(f"Published package and documentation: https://hex.pm/packages/exgboost/{value}")


def run(directory, publish=False):
    value = verify_bundle(directory)
    if not publish:
        print(f"Dry run passed for exgboost {value}; no package or docs uploaded")
        return
    key = os.environ.get("HEX_API_KEY")
    if not key:
        raise ValueError("Set the HEX_API_KEY GitHub Actions secret to a Hex publishing API key")
    HexClient(key).publish(directory, value)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--publish", action="store_true", help="Upload package and docs; default is a dry run")
    args = parser.parse_args()
    run(args.directory, args.publish)
