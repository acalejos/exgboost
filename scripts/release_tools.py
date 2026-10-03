"""Shared validation for the CI bundle and Hex publisher (no third-party dependencies)."""
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path, PurePosixPath

REPOSITORY = "acalejos/exgboost"
TARGETS = ("aarch64-apple-darwin", "aarch64-linux-gnu", "x86_64-apple-darwin", "x86_64-linux-gnu")
PACKAGE_FILES = ("mix.exs", "Makefile", "README.md", "CHANGELOG.md", "RELEASING.md", "LICENSE", ".formatter.exs")
SEMVER = r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z.-]+)?"


def version(root=Path(".")):
    value = re.search(r'@version "([^"]+)"', (root / "mix.exs").read_text()).group(1)
    if not re.fullmatch(SEMVER, value):
        raise ValueError(f"Invalid package version: {value}")
    return value


def check_tag(tag, root=Path(".")):
    if tag != "v" + version(root):
        raise ValueError(f"Tag {tag} must match package version v{version(root)}")


def archives(value):
    return [f"exgboost-nif-2.17-{target}-{value}.tar.gz" for target in TARGETS]


def base_url(value):
    return f"https://github.com/{REPOSITORY}/releases/download/v{value}/"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def tar_files(archive):
    files = {}
    for entry in archive.getmembers():
        path = PurePosixPath(entry.name)
        if path.is_absolute() or ".." in path.parts or entry.issym() or entry.islnk():
            raise ValueError(f"Invalid package path: {entry.name}")
        if entry.isfile():
            if entry.name in files:
                raise ValueError(f"Duplicate package path: {entry.name}")
            files[entry.name] = archive.extractfile(entry).read()
    return files


def hex_files(path, value):
    with tarfile.open(path) as outer:
        if outer.extractfile("VERSION").read() != b"3":
            raise ValueError("Unsupported Hex tarball format")
        metadata = outer.extractfile("metadata.config").read().decode()
        for key, expected in (("name", "exgboost"), ("version", value)):
            if not re.search(r'\{<<"' + key + r'">>,\s*<<"' + re.escape(expected) + r'">>\}', metadata):
                raise ValueError(f"Hex metadata {key} does not match {expected}")
        contents = outer.extractfile("contents.tar.gz").read()
    with tarfile.open(fileobj=io.BytesIO(contents), mode="r:gz") as inner:
        return tar_files(inner)


def expected_sources(root):
    paths = [root / name for name in PACKAGE_FILES]
    for directory in ("lib", "c", "scripts"):
        paths.extend(p for p in (root / directory).rglob("*")
                     if p.is_file() and "__pycache__" not in p.parts and p.suffix != ".pyc")
    return {p.relative_to(root).as_posix(): p.read_bytes() for p in paths}


def native_checksums(directory, value):
    expected = archives(value)
    actual = sorted(p.name for p in directory.glob("exgboost-nif-*.tar.gz"))
    if actual != expected:
        raise ValueError(f"Native archive targets do not match: expected {expected}, got {actual}")
    manifest = (directory / "checksum.exs").read_text()
    pair = r'"([^"\n]+)"\s*=>\s*"sha256:([a-f0-9]{64})"\s*,\s*'
    if not re.fullmatch(r"\s*%\{\s*(?:" + pair + r")*\}\s*", manifest):
        raise ValueError("Invalid checksum manifest")
    pairs = re.findall(pair, manifest)
    hashes = dict(pairs)
    if len(pairs) != len(hashes) or sorted(hashes) != expected:
        raise ValueError("Checksum manifest must contain exactly the four native targets")
    for name, expected_hash in hashes.items():
        if digest(directory / name) != expected_hash:
            raise ValueError(f"Native archive checksum mismatch: {name}")
        if (directory / (name + ".sha256")).read_text().strip() != f"{expected_hash}  {name}":
            raise ValueError(f"Native archive sidecar mismatch: {name}")
    return hashes


def verify_bundle(directory, root=Path("."), source_commit=None):
    directory, root = directory.resolve(), root.resolve()
    value = version(root)
    hashes = native_checksums(directory, value)
    info = json.loads((directory / "release.json").read_text())
    source_commit = source_commit or subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
    expected_info = {"package": "exgboost", "version": value, "tag": "v" + value,
                     "source_commit": source_commit, "archive_base_url": base_url(value), "native_sha256": hashes}
    for key, expected in expected_info.items():
        if info.get(key) != expected:
            raise ValueError(f"Release provenance mismatch: {key}")
    package = directory / f"exgboost-{value}.tar"
    files = hex_files(package, value)
    expected = expected_sources(root)
    expected["checksum.exs"] = (directory / "checksum.exs").read_bytes()
    if files != expected:
        changed = sorted(name for name in set(files) | set(expected) if files.get(name) != expected.get(name))
        raise ValueError(f"Hex package differs from the tagged source/manifest: {changed}")
    template = f'https://github.com/{REPOSITORY}/releases/download/v#{{@version}}/@{{artefact_filename}}'
    if template.encode() not in files["mix.exs"]:
        raise ValueError("Hex package does not reference the matching GitHub release")
    docs = directory / f"exgboost-{value}-docs.tar.gz"
    with tarfile.open(docs, "r:gz") as archive:
        if "index.html" not in tar_files(archive):
            raise ValueError("Documentation archive has no index.html")
    sums = {}
    for line in (directory / "SHA256SUMS").read_text().splitlines():
        match = re.fullmatch(r"([a-f0-9]{64})  ([A-Za-z0-9_.-]+)", line)
        if not match or match[2] in sums:
            raise ValueError("Invalid SHA256SUMS")
        sums[match[2]] = match[1]
    payloads = set(hashes) | {name + ".sha256" for name in hashes} | {
        package.name, docs.name, "checksum.exs", "release.json"}
    if set(sums) != payloads:
        raise ValueError("SHA256SUMS does not contain every release payload")
    for name, expected_hash in sums.items():
        if digest(directory / name) != expected_hash:
            raise ValueError(f"Release payload checksum mismatch: {name}")
    return value
