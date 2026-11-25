#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
"""Build, verify and checksum the distributable .plasmoid archive.

    scripts/package.py stage            build/package/ (package/ + compiled catalogs)
    scripts/package.py build            stage, then dist/<name>-<version>.plasmoid + .sha256
    scripts/package.py verify FILE      check an existing archive
    scripts/package.py check-tag TAG    fail unless TAG is "v" + metadata Version

The archive is reproducible: sorted entries, fixed permissions and a fixed
timestamp (SOURCE_DATE_EPOCH, else the last commit time, else 2000-01-01).
Only the Python standard library and msgfmt (when po/*.po exist) are used.
"""

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SOURCE = REPO / "package"
STAGE = REPO / "build" / "package"
DIST = REPO / "dist"

# What may ship. Everything else in an archive is an error.
ALLOWED = [
    re.compile(r"^metadata\.json$"),
    re.compile(r"^contents/(ui|config|code)/[A-Za-z0-9_.-]+\.(qml|js|xml)$"),
    re.compile(r"^contents/icons/[A-Za-z0-9_.-]+\.(svg|svgz|png)$"),
    re.compile(r"^contents/LICENSES/[A-Za-z0-9_.+-]+\.txt$"),
    re.compile(r"^contents/locale/[A-Za-z_@]+/LC_MESSAGES/plasma_applet_[A-Za-z0-9_.-]+\.mo$"),
]
REQUIRED = ["metadata.json", "contents/ui/main.qml", "contents/config/main.xml", "contents/config/config.qml"]


def metadata(root=SOURCE):
    return json.loads((root / "metadata.json").read_text(encoding="utf-8"))["KPlugin"]


def artifact_stem(plugin):
    """"Power Supply Meter" -> "power-supply-meter"; falls back to the plugin id."""
    slug = re.sub(r"[^a-z0-9]+", "-", plugin.get("Name", "").lower()).strip("-")
    return slug or plugin["Id"].rsplit(".", 1)[-1]


def epoch():
    if os.environ.get("SOURCE_DATE_EPOCH"):
        return int(os.environ["SOURCE_DATE_EPOCH"])
    try:
        out = subprocess.run(["git", "-C", str(REPO), "log", "-1", "--format=%ct"],
                             capture_output=True, text=True, check=True).stdout.strip()
        if out:
            return int(out)
    except (OSError, subprocess.CalledProcessError):
        pass
    return 946684800  # 2000-01-01, used when building outside git


def stage():
    if STAGE.exists():
        shutil.rmtree(STAGE)
    shutil.copytree(SOURCE, STAGE)
    # GPL-3.0 requires the licence text to accompany distributed copies.
    licence = metadata()["License"]
    licence_file = REPO / "LICENSES" / f"{licence}.txt"
    if not licence_file.exists():
        sys.exit(f"error: metadata License is {licence} but {licence_file.relative_to(REPO)} is missing")
    (STAGE / "contents" / "LICENSES").mkdir()
    shutil.copy2(licence_file, STAGE / "contents" / "LICENSES" / licence_file.name)
    plugin_id = metadata()["Id"]
    catalogs = sorted((REPO / "po").glob("*.po"))
    if catalogs and not shutil.which("msgfmt"):
        sys.exit("error: po/*.po exist but msgfmt is missing; run 'make doctor'")
    for po in catalogs:
        target = STAGE / "contents" / "locale" / po.stem / "LC_MESSAGES" / f"plasma_applet_{plugin_id}.mo"
        target.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["msgfmt", "--check", "-o", str(target), str(po)], check=True)
    print(f"package: staged {STAGE.relative_to(REPO)} ({len(catalogs)} translation(s))")
    return STAGE


def build():
    root = stage()
    plugin = metadata(root)
    DIST.mkdir(exist_ok=True)
    archive = DIST / f"{artifact_stem(plugin)}-{plugin['Version']}.plasmoid"
    stamp = time.gmtime(max(epoch(), 315532800))[:6]  # zip cannot store dates before 1980
    files = sorted(p for p in root.rglob("*") if p.is_file())
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for path in files:
            info = zipfile.ZipInfo(path.relative_to(root).as_posix(), stamp)
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            zf.writestr(info, path.read_bytes())
    verify(archive)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    checksum = archive.with_name(archive.name + ".sha256")
    checksum.write_text(f"{digest}  {archive.name}\n", encoding="utf-8")
    print(f"package: {archive.relative_to(REPO)}\npackage: sha256 {digest}")
    return archive


def verify(archive):
    archive = Path(archive)
    errors = []
    with zipfile.ZipFile(archive) as zf:
        names = zf.namelist()
        bad = zf.testzip()
        if bad:
            errors.append(f"corrupt entry: {bad}")
        for name in names:
            if name.endswith("/"):
                continue
            if not any(rule.match(name) for rule in ALLOWED):
                errors.append(f"unexpected file: {name}")
        for name in REQUIRED:
            if name not in names:
                errors.append(f"missing file: {name}")
        if "metadata.json" in names:
            meta = json.loads(zf.read("metadata.json"))
            plugin = meta.get("KPlugin", {})
            licence = f"contents/LICENSES/{plugin.get('License')}.txt"
            if licence not in names:
                errors.append(f"missing licence text for metadata License: {licence}")
            if meta.get("KPackageStructure") != "Plasma/Applet":
                errors.append("metadata.json: KPackageStructure must be Plasma/Applet")
            expected = f"{artifact_stem(plugin)}-{plugin.get('Version')}.plasmoid"
            if archive.name != expected:
                errors.append(f"archive name {archive.name} does not match metadata version ({expected})")
            for name in names:
                match = re.match(r"^contents/locale/[^/]+/LC_MESSAGES/(.+)\.mo$", name)
                if match and match.group(1) != f"plasma_applet_{plugin.get('Id')}":
                    errors.append(f"catalog has the wrong domain: {name}")
    if errors:
        sys.exit("package: verification failed\n  " + "\n  ".join(errors))
    print(f"package: verified {archive.name} ({len(names)} entries)")


def check_tag(tag):
    expected = "v" + metadata()["Version"]
    if tag != expected:
        sys.exit(f"error: tag {tag} does not match metadata.json version ({expected})")
    print(f"package: tag {tag} matches metadata.json")


def main(argv):
    if argv[:1] == ["stage"]:
        stage()
    elif argv[:1] == ["build"]:
        build()
    elif argv[:1] == ["verify"] and len(argv) == 2:
        verify(argv[1])
    elif argv[:1] == ["check-tag"] and len(argv) == 2:
        check_tag(argv[1])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
