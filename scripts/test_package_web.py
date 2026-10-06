import json
import tempfile
import unittest
from pathlib import Path

from package_web import package_web, verify_package


class PackageWebTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "build" / "web"
        self.output = self.root / "build" / "pwa"
        self.source.mkdir(parents=True)
        self.sha = "a" * 40
        files = {
            "index.html": '<base href="/mobile/"><link href="manifest.json"><script src="flutter_bootstrap.js"></script>',
            "manifest.json": json.dumps({"id": "/mobile/", "start_url": "/mobile/", "scope": "/mobile/", "display": "standalone", "icons": [{"src": "icons/icon.png"}]}),
            "main.dart.js": "// synthetic build only",
            "flutter_bootstrap.js": "_flutter.loader.load();\n",
            "flutter_service_worker.js": "// unused generated file",
            "icons/icon.png": "dummy image",
            "assets/fonts/sample.ttf": "dummy font",
        }
        for name, text in files.items():
            path = self.source / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
        self.headers = self.root / "_headers"
        self.headers.write_text("/mobile/*\n  X-Content-Type-Options: nosniff\n  Referrer-Policy: no-referrer\n  Cache-Control: private, max-age=0, must-revalidate\n  Content-Security-Policy: default-src 'none'\n")

    def package(self):
        return package_web(self.source, self.output, self.sha, self.headers)

    def test_mobile_layout_headers_and_source_sha(self):
        self.package()
        release = verify_package(self.output, self.sha)
        self.assertEqual(release["source_sha"], self.sha)
        self.assertTrue((self.output / "mobile/icons/icon.png").is_file())
        self.assertTrue((self.output / "_headers").is_file())
        self.assertFalse((self.output / "mobile/_headers").exists())
        self.assertFalse((self.output / "mobile/flutter_service_worker.js").exists())

    def test_repackage_removes_stale_asset(self):
        self.package()
        (self.output / "mobile/old.js").write_text("old")
        self.package()
        self.assertFalse((self.output / "mobile/old.js").exists())

    def test_flutter_build_id_is_excluded_and_other_hidden_files_rejected(self):
        (self.source / ".last_build_id").write_text("generated-build-id")
        self.package()
        self.assertFalse((self.output / "mobile/.last_build_id").exists())
        (self.source / ".other").write_text("unexpected")
        with self.assertRaisesRegex(ValueError, "ローカル設定"):
            self.package()

    def test_wrong_base_href_rejected(self):
        (self.source / "index.html").write_text('<base href="/">')
        with self.assertRaisesRegex(ValueError, "base href"):
            self.package()

    def test_missing_referenced_script_rejected(self):
        (self.source / "index.html").write_text('<base href="/mobile/"><script src="missing.js"></script>')
        with self.assertRaisesRegex(ValueError, "存在しない"):
            self.package()

    def test_cdn_reference_rejected(self):
        (self.source / "index.html").write_text('<base href="/mobile/"><script src="https://cdn.invalid/app.js"></script>')
        with self.assertRaisesRegex(ValueError, "外部"):
            self.package()

    def test_wrong_manifest_scope_rejected(self):
        manifest = json.loads((self.source / "manifest.json").read_text())
        manifest["scope"] = "/"
        (self.source / "manifest.json").write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "manifest"):
            self.package()

    def test_service_worker_registration_rejected(self):
        (self.source / "flutter_bootstrap.js").write_text('_flutter.loader.load({serviceWorkerSettings: {}});')
        with self.assertRaisesRegex(ValueError, "bootstrap"):
            self.package()

    def test_multiple_loader_calls_rejected(self):
        (self.source / "flutter_bootstrap.js").write_text('_flutter.loader.load({serviceWorkerSettings: {}});\n_flutter.loader.load();')
        with self.assertRaisesRegex(ValueError, "bootstrap"):
            self.package()

    def test_comment_cannot_supply_required_headers(self):
        text = self.headers.read_text()
        self.headers.write_text("\n".join("# " + line if line.startswith(" ") else line for line in text.splitlines()))
        with self.assertRaisesRegex(ValueError, "必要な"):
            self.package()

    def test_headers_before_path_rejected(self):
        lines = self.headers.read_text().splitlines()
        self.headers.write_text("\n".join(lines[1:] + lines[:1]))
        with self.assertRaisesRegex(ValueError, "パス指定前"):
            self.package()

    def test_root_header_rule_rejected(self):
        self.headers.write_text(self.headers.read_text().replace("/mobile/*", "/*"))
        with self.assertRaisesRegex(ValueError, "header"):
            self.package()

    def test_smoke_config_and_hidden_files_rejected(self):
        for name in ["smoke.local.json", "assets/.env", "assets/test.pem"]:
            path = self.source / name
            path.write_text("DUMMY-NOT-A-SECRET")
            with self.assertRaises(ValueError):
                self.package()
            path.unlink()

    def test_symlink_rejected(self):
        (self.source / "assets/link.js").symlink_to(self.source / "main.dart.js")
        with self.assertRaisesRegex(ValueError, "symlink"):
            self.package()

    def test_output_cannot_delete_source(self):
        with self.assertRaises(ValueError):
            package_web(self.source, self.source, self.sha, self.headers)
        self.assertTrue((self.source / "main.dart.js").is_file())

    def test_parent_symlink_cannot_alias_and_delete_source(self):
        self.source.rename(self.output)
        alias = self.root / "alias"
        alias.mkdir()
        (alias / "build").symlink_to(self.output.parent, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "重なっています"):
            package_web(self.output, alias / "build/pwa", self.sha, self.headers)
        self.assertTrue((self.output / "main.dart.js").is_file())

    def test_parent_symlink_cannot_delete_arbitrary_directory(self):
        data = self.root / "data"
        victim = data / "pwa"
        victim.mkdir(parents=True)
        (victim / "keep.txt").write_text("keep")
        alias = self.root / "alias"
        alias.mkdir()
        (alias / "build").symlink_to(data, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "実際の出力先"):
            package_web(self.source, alias / "build/pwa", self.sha, self.headers)
        self.assertTrue((victim / "keep.txt").is_file())

    def test_wrong_artifact_sha_rejected(self):
        self.package()
        with self.assertRaisesRegex(ValueError, "SHA"):
            verify_package(self.output, "b" * 40)

    def test_modified_missing_and_extra_files_rejected(self):
        for operation in ["modified", "missing", "extra"]:
            self.package()
            path = self.output / "mobile/main.dart.js"
            if operation == "modified":
                path.write_text("changed")
            elif operation == "missing":
                path.unlink()
            else:
                (self.output / "mobile/extra.js").write_text("extra")
            with self.assertRaisesRegex(ValueError, "hash"):
                verify_package(self.output, self.sha)


if __name__ == "__main__":
    unittest.main()
