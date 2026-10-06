"""検査したFlutter Web成果物を/mobile/用に配置し、同一SHAで照合する。"""

import argparse
import hashlib
import json
import re
import shutil
import subprocess
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit

ROOT_FILES = {
    "index.html", "main.dart.js", "flutter_bootstrap.js", "flutter.js",
    "favicon.png", "manifest.json", "version.json", "_headers",
}
ROOT_DIRS = {"assets", "canvaskit", "icons"}
FORBIDDEN = {"smoke.local.json", ".env", ".git", "node_modules", ".wrangler"}
MAX_FILES = 20_000
MAX_FILE_SIZE = 25 * 1024 * 1024
MANIFEST = "_release.json"


def file_hash(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def files_under(root, skip_build_id=False):
    if root.is_symlink() or not root.is_dir():
        raise ValueError("成果物ディレクトリがありません")
    result = {}
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root)
        if path.is_symlink():
            raise ValueError(f"symlinkは配備できません: {relative}")
        if skip_build_id and relative.as_posix() == ".last_build_id" and path.is_file():
            continue
        if any(part in FORBIDDEN or part.startswith(".") for part in relative.parts):
            raise ValueError(f"ローカル設定は配備できません: {relative}")
        if path.is_file():
            if path.suffix.lower() in {".env", ".pem", ".key", ".dart", ".log", ".zip"}:
                raise ValueError(f"配備対象外のファイルです: {relative}")
            if path.stat().st_size > MAX_FILE_SIZE:
                raise ValueError(f"ファイル容量上限を超えています: {relative}")
            result[relative.as_posix()] = file_hash(path)
    if len(result) > MAX_FILES:
        raise ValueError("成果物のファイル数上限を超えています")
    return result


class HtmlAssets(HTMLParser):
    def __init__(self):
        super().__init__()
        self.base = []
        self.references = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "base":
            self.base.append(attrs.get("href"))
        elif tag in {"script", "link"}:
            self.references.append(attrs.get("src" if tag == "script" else "href", ""))


def validate_app(root):
    files = files_under(root)
    if not {"index.html", "main.dart.js", "flutter_bootstrap.js", "manifest.json"} <= files.keys():
        raise ValueError("Flutterの必須ファイルがありません")
    for name in files:
        parts = Path(name).parts
        if (len(parts) == 1 and name not in ROOT_FILES) or (len(parts) > 1 and parts[0] not in ROOT_DIRS):
            raise ValueError(f"Flutter配備対象外のパスです: {name}")
    html = HtmlAssets()
    html.feed((root / "index.html").read_text())
    if html.base != ["/mobile/"]:
        raise ValueError("base hrefは/mobile/である必要があります")
    for reference in html.references:
        uri = urlsplit(reference)
        if not reference or uri.scheme or uri.netloc or ".." in uri.path.split("/"):
            raise ValueError("HTMLが外部または不正なassetを参照しています")
        relative = uri.path.removeprefix("/mobile/") if uri.path.startswith("/") else uri.path
        if relative not in files:
            raise ValueError("HTMLが存在しないassetを参照しています")
    manifest = json.loads((root / "manifest.json").read_text())
    if any(manifest.get(key) != "/mobile/" for key in ["id", "start_url", "scope"]):
        raise ValueError("manifestの配信パスが一致しません")
    if manifest.get("display") != "standalone":
        raise ValueError("manifestがstandaloneではありません")
    for icon in manifest.get("icons", []):
        if icon.get("src") not in files:
            raise ValueError("manifestのiconがありません")
    bootstrap = (root / "flutter_bootstrap.js").read_text()
    if not bootstrap.rstrip().endswith("_flutter.loader.load();"):
        raise ValueError("Service Worker設定なしのbootstrapではありません")
    return files


def validate_headers(path):
    text = path.read_text()
    rules = [line.strip() for line in text.splitlines()
             if line and not line.startswith((" ", "#"))]
    if rules != ["/mobile/*"]:
        raise ValueError("headerは/mobile/*だけへ適用してください")
    for required in ["X-Content-Type-Options: nosniff", "Referrer-Policy: no-referrer",
                     "Cache-Control: private, max-age=0, must-revalidate", "Content-Security-Policy:"]:
        if required not in text:
            raise ValueError("必要な配信headerがありません")
    if "Strict-Transport-Security:" in text or "Access-Control-Allow-Origin:" in text:
        raise ValueError("ホスト全体のHSTS/CORS設定は変更できません")


def verify_package(root, sha):
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("40桁のGit SHAを指定してください")
    files = files_under(root)
    release = json.loads((root / MANIFEST).read_text())
    expected = {name: digest for name, digest in files.items() if name != MANIFEST}
    if release.get("format") != 1 or release.get("source_sha") != sha or release.get("files") != expected:
        raise ValueError("検査対象SHAまたは成果物のhashが一致しません")
    if set(files) != {MANIFEST, "_headers"} | {"mobile/" + name for name in validate_app(root / "mobile")}:
        raise ValueError("成果物にmobile以外のファイルがあります")
    validate_headers(root / "_headers")
    return release


def package_web(source, destination, sha, headers):
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("40桁のGit SHAを指定してください")
    # 生成された未使用のSWスクリプトは配信しない。登録も追加しない。
    source_files = files_under(source, skip_build_id=True)
    allowed = set(ROOT_FILES) | {"flutter_service_worker.js"}
    for name in source_files:
        parts = Path(name).parts
        if (len(parts) == 1 and name not in allowed) or (len(parts) > 1 and parts[0] not in ROOT_DIRS):
            raise ValueError(f"Flutter配備対象外のパスです: {name}")
    validate_headers(headers)
    source = source.resolve()
    destination = destination.absolute()
    # ローカル成果物の置換だけを許可し、入力やrepoを削除しない。
    if destination.name != "pwa" or destination.parent.name != "build" or destination.is_symlink():
        raise ValueError("出力先はbuild/pwaを指定してください")
    destination = destination.resolve()
    if source == destination or source in destination.parents or destination in source.parents:
        raise ValueError("入力と出力が重なっています")
    if destination.exists():
        shutil.rmtree(destination)
    app = destination / "mobile"
    app.mkdir(parents=True)
    for name in source_files:
        if name in {"_headers", "flutter_service_worker.js"}:
            continue
        target = app / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source / name, target)
    shutil.copyfile(headers, destination / "_headers")
    validate_app(app)
    release = {"format": 1, "source_sha": sha, "files": files_under(destination)}
    (destination / MANIFEST).write_text(json.dumps(release, sort_keys=True, indent=2) + "\n")
    verify_package(destination, sha)
    return release


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path("build/web"))
    parser.add_argument("--output", type=Path, default=Path("build/pwa"))
    parser.add_argument("--headers", type=Path, default=Path("web/_headers"))
    parser.add_argument("--sha")
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    sha = args.sha or subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    result = verify_package(args.output, sha) if args.verify else package_web(args.source, args.output, sha, args.headers)
    print(f"Validated {len(result['files'])} files for source SHA {sha}")


if __name__ == "__main__":
    main()
