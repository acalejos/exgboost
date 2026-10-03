#!/usr/bin/env python3
"""Assemble docs and provenance alongside the already-built Hex/native packages."""
import argparse
import json
import subprocess
import tarfile
from pathlib import Path
from release_tools import archives, base_url, digest, native_checksums, verify_bundle, version


def prepare(directory, docs, root=Path("."), source_commit=None):
    value = version(root)
    if not (docs / "index.html").is_file():
        raise ValueError("Build documentation with mix docs first")
    doc_archive = directory / f"exgboost-{value}-docs.tar.gz"
    with tarfile.open(doc_archive, "w:gz", format=tarfile.USTAR_FORMAT) as archive:
        for path in sorted(docs.rglob("*")):
            if path.is_file():
                archive.add(path, arcname=path.relative_to(docs).as_posix(), recursive=False)
    info = {"package": "exgboost", "version": value, "tag": "v" + value,
            "source_commit": source_commit or subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
            "archive_base_url": base_url(value), "native_sha256": native_checksums(directory, value)}
    (directory / "release.json").write_text(json.dumps(info, indent=2, sort_keys=True) + "\n")
    names = archives(value) + [name + ".sha256" for name in archives(value)] + [
        f"exgboost-{value}.tar", doc_archive.name, "checksum.exs", "release.json"]
    (directory / "SHA256SUMS").write_text("".join(f"{digest(directory / name)}  {name}\n" for name in sorted(names)))
    verify_bundle(directory, root, source_commit)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--docs", type=Path, default=Path("doc"))
    args = parser.parse_args()
    prepare(args.directory, args.docs)
    print("Verified the complete native, Hex and documentation bundle against this checkout")
