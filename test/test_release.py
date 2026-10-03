"""Release integrity and failure/retry tests; no live publishing or credentials."""
import hashlib
import io
import json
import sys
import tarfile
import tempfile
import unittest
import urllib.error
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from prepare_release import prepare
from publish_hex import HexClient, run
from release_tools import PACKAGE_FILES, archives, expected_sources, verify_bundle


def tar_bytes(files, compressed=False):
    output = io.BytesIO()
    with tarfile.open(fileobj=output, mode="w:gz" if compressed else "w") as archive:
        for name, data in files.items():
            entry = tarfile.TarInfo(name)
            entry.size = len(data)
            archive.addfile(entry, io.BytesIO(data))
    return output.getvalue()


class ReleaseTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        stage = Path(self.temporary.name)
        self.root, self.release, self.docs = stage / "source", stage / "release", stage / "doc"
        for path in (self.root, self.release, self.docs):
            path.mkdir()
        for name in PACKAGE_FILES:
            (self.root / name).write_text(name)
        (self.root / "mix.exs").write_text('''@version "0.6.0"
"https://github.com/acalejos/exgboost/releases/download/v#{@version}/@{artefact_filename}"
''')
        for directory in ("c", "lib", "scripts"):
            (self.root / directory).mkdir()
            (self.root / directory / "fixture").write_text(directory)
        (self.docs / "index.html").write_text("<html>EXGBoost</html>")
        pairs = []
        for name in archives("0.6.0"):
            data = name.encode()
            (self.release / name).write_bytes(data)
            digest = hashlib.sha256(data).hexdigest()
            (self.release / (name + ".sha256")).write_text(f"{digest}  {name}\n")
            pairs.append(f'  "{name}" => "sha256:{digest}",\n')
        (self.release / "checksum.exs").write_text("%{\n" + "".join(pairs) + "}\n")
        self.write_package()
        self.sha = "a" * 40
        prepare(self.release, self.docs, self.root, self.sha)

    def write_package(self, modify=None):
        files = expected_sources(self.root)
        files["checksum.exs"] = (self.release / "checksum.exs").read_bytes()
        if modify:
            modify(files)
        metadata = b'{<<"name">>,<<"exgboost">>}.\n{<<"version">>,<<"0.6.0">>}.\n'
        package = tar_bytes({"VERSION": b"3", "CHECKSUM": b"fixture", "metadata.config": metadata,
                             "contents.tar.gz": tar_bytes(files, compressed=True)})
        (self.release / "exgboost-0.6.0.tar").write_bytes(package)

    def verify(self, sha=None):
        return verify_bundle(self.release, self.root, sha or self.sha)

    def test_complete_bundle_matches_source_and_native_checksums(self):
        self.assertEqual(self.verify(), "0.6.0")

    def test_tampered_native_archive_is_rejected(self):
        (self.release / archives("0.6.0")[0]).write_bytes(b"changed")
        with self.assertRaisesRegex(ValueError, "Native archive checksum mismatch"):
            self.verify()

    def test_missing_architecture_is_rejected(self):
        (self.release / archives("0.6.0")[0]).unlink()
        with self.assertRaisesRegex(ValueError, "Native archive targets"):
            self.verify()

    def test_duplicate_manifest_entry_is_rejected(self):
        manifest = self.release / "checksum.exs"
        text = manifest.read_text()
        manifest.write_text(text[:-2] + text.splitlines(keepends=True)[1] + "}\n")
        with self.assertRaisesRegex(ValueError, "exactly the four"):
            self.verify()

    def test_incomplete_manifest_is_rejected(self):
        (self.release / "checksum.exs").write_text("%{}\n")
        with self.assertRaisesRegex(ValueError, "exactly the four"):
            self.verify()

    def test_wrong_tagged_commit_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "source_commit"):
            self.verify("b" * 40)

    def test_wrong_release_url_is_rejected(self):
        info = self.release / "release.json"
        data = json.loads(info.read_text())
        data["archive_base_url"] = "https://github.com/another/fork/releases/download/v0.6.0/"
        info.write_text(json.dumps(data))
        with self.assertRaisesRegex(ValueError, "archive_base_url"):
            self.verify()

    def test_hex_package_cannot_drop_the_checksum_manifest(self):
        self.write_package(lambda files: files.pop("checksum.exs"))
        with self.assertRaisesRegex(ValueError, "differs from the tagged source/manifest"):
            self.verify()

    def test_hex_package_cannot_ship_other_source_files(self):
        self.write_package(lambda files: files.update({"README.md": b"stale release"}))
        with self.assertRaisesRegex(ValueError, "differs from the tagged source/manifest"):
            self.verify()

    def test_docs_must_include_an_index(self):
        (self.release / "exgboost-0.6.0-docs.tar.gz").write_bytes(tar_bytes({"empty.html": b"no index"}, True))
        with self.assertRaisesRegex(ValueError, "no index.html"):
            self.verify()

    def test_all_payloads_must_be_in_sha256sums(self):
        path = self.release / "SHA256SUMS"
        path.write_text("".join(line for line in path.read_text().splitlines(keepends=True) if "-docs.tar.gz" not in line))
        with self.assertRaisesRegex(ValueError, "every release payload"):
            self.verify()

    def test_dry_run_does_not_create_a_publishing_client(self):
        with patch("publish_hex.verify_bundle", return_value=self.verify()), patch("publish_hex.HexClient") as client:
            run(self.release)
            client.assert_not_called()

    def test_publish_uploads_exact_ci_tarballs_with_no_replace(self):
        seen = []

        def response(request, timeout):
            seen.append(request)
            if request.data is None:
                raise urllib.error.HTTPError(request.full_url, 404, "not found", {}, io.BytesIO(b""))
            return io.BytesIO(b"{}")

        with patch("urllib.request.urlopen", side_effect=response):
            HexClient("test-key").publish(self.release, "0.6.0")
        self.assertEqual(seen[1].full_url, "https://hex.pm/api/packages/exgboost/releases?replace=false")
        self.assertEqual(seen[1].data, (self.release / "exgboost-0.6.0.tar").read_bytes())
        self.assertEqual(seen[2].data, (self.release / "exgboost-0.6.0-docs.tar.gz").read_bytes())
        self.assertEqual(seen[1].get_header("Authorization"), "test-key")

    def test_retry_after_docs_failure_skips_identical_package(self):
        package = (self.release / "exgboost-0.6.0.tar").read_bytes()
        seen = []

        def response(request, timeout):
            seen.append(request)
            if request.full_url.startswith("https://repo.hex.pm/"):
                return io.BytesIO(package)
            return io.BytesIO(b"{}")

        with patch("urllib.request.urlopen", side_effect=response):
            HexClient("test-key").publish(self.release, "0.6.0")
        posts = [request for request in seen if request.data is not None]
        self.assertEqual(len(posts), 1)
        self.assertTrue(posts[0].full_url.endswith("/0.6.0/docs"))

    def test_retry_refuses_to_overwrite_a_different_hex_release(self):
        with patch("urllib.request.urlopen", side_effect=[io.BytesIO(b"{}"), io.BytesIO(b"another package")]) as request:
            with self.assertRaisesRegex(ValueError, "already contains a different"):
                HexClient("test-key").publish(self.release, "0.6.0")
            self.assertEqual(request.call_count, 2)

    def test_api_errors_redact_the_key(self):
        error = urllib.error.HTTPError("https://hex.pm/api", 403, "forbidden", {}, io.BytesIO(b"rejected test-key"))
        with patch("urllib.request.urlopen", side_effect=error):
            with self.assertRaisesRegex(ValueError, r"\[REDACTED\]") as raised:
                HexClient("test-key").request("/publish", b"package")
        self.assertNotIn("test-key", str(raised.exception))


if __name__ == "__main__":
    unittest.main()
