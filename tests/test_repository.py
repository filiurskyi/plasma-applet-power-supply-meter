# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
"""Static checks of metadata, configuration schema, config pages and packaging.

Run with: python3 -m unittest discover -s tests -v
"""

import importlib.util
import json
import re
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PACKAGE = REPO / "package"
KCFG = "{http://www.kde.org/standards/kcfg/1.0}"


def load_script(name):
    spec = importlib.util.spec_from_file_location(name, REPO / "scripts" / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def config_entries():
    root = ET.parse(PACKAGE / "contents" / "config" / "main.xml").getroot()
    return {entry.get("name"): entry for entry in root.iter(f"{KCFG}entry")}


class MetadataTest(unittest.TestCase):
    def setUp(self):
        self.meta = json.loads((PACKAGE / "metadata.json").read_text(encoding="utf-8"))
        self.plugin = self.meta["KPlugin"]

    def test_package_structure(self):
        self.assertEqual(self.meta["KPackageStructure"], "Plasma/Applet")
        self.assertRegex(self.meta["X-Plasma-API-Minimum-Version"], r"^6\.\d+$")

    def test_required_fields(self):
        for key in ("Id", "Name", "Description", "Icon", "Version", "License", "Category",
                    "Authors", "Website", "BugReportUrl"):
            self.assertTrue(self.plugin.get(key), f"KPlugin.{key} is missing or empty")

    def test_plugin_id_is_reverse_domain_and_not_kde(self):
        self.assertRegex(self.plugin["Id"], r"^[a-z][a-z0-9]*(\.[a-z][a-z0-9_]*){2,}$")
        self.assertFalse(self.plugin["Id"].startswith("org.kde."), "org.kde.* is reserved for KDE")

    def test_version_is_semver(self):
        self.assertRegex(self.plugin["Version"], r"^\d+\.\d+\.\d+$")

    def test_licence_text_and_spdx_headers_match(self):
        licence = self.plugin["License"]
        self.assertTrue((REPO / "LICENSES" / f"{licence}.txt").exists())
        for path in list(PACKAGE.rglob("*.qml")) + list(PACKAGE.rglob("*.js")) + list(PACKAGE.rglob("*.xml")):
            # REUSE-IgnoreStart
            self.assertIn(f"SPDX-License-Identifier: {licence}", path.read_text(encoding="utf-8"),
                          f"{path.relative_to(REPO)} lacks the SPDX header")
            # REUSE-IgnoreEnd

    def test_category_is_known(self):
        self.assertIn(self.plugin["Category"], load_script("init").CATEGORIES)


class ConfigurationTest(unittest.TestCase):
    def setUp(self):
        self.entries = config_entries()
        self.ui = {p.name: p.read_text(encoding="utf-8") for p in (PACKAGE / "contents" / "ui").glob("*.qml")}

    def test_defaults_match_types(self):
        for name, entry in self.entries.items():
            kind = entry.get("type").lower()
            default = entry.findtext(f"{KCFG}default") or ""
            if kind == "int":
                value = int(default)
                lo, hi = entry.findtext(f"{KCFG}min"), entry.findtext(f"{KCFG}max")
                if lo is not None:
                    self.assertGreaterEqual(value, int(lo), name)
                if hi is not None:
                    self.assertLessEqual(value, int(hi), name)
            elif kind == "bool":
                self.assertIn(default, ("true", "false"), name)
            elif kind == "color":
                self.assertRegex(default, r"^#[0-9a-fA-F]{6}$", name)

    def test_config_pages_exist(self):
        model = (PACKAGE / "contents" / "config" / "config.qml").read_text(encoding="utf-8")
        for source in re.findall(r'source:\s*"([^"]+)"', model):
            self.assertIn(source, self.ui, f"config.qml references missing page {source}")

    def test_every_cfg_property_has_a_schema_entry(self):
        for page, text in self.ui.items():
            for name in re.findall(r"property\s+(?:alias|[\w.]+)\s+cfg_(\w+)", text):
                self.assertIn(name, self.entries, f"{page}: cfg_{name} has no entry in main.xml")

    def test_every_schema_entry_is_used(self):
        code = "\n".join(self.ui.values())
        for name in self.entries:
            used = f"cfg_{name}" in code and f"configuration.{name}" in code
            self.assertTrue(used, f"main.xml entry {name} needs both a cfg_ property and a reader")

    def test_spinbox_bounds_match_schema(self):
        general = self.ui["configGeneral.qml"]
        for name in ("maxWatts", "intervalSeconds"):
            entry = self.entries[name]
            block = re.search(r"id:\s*%s\b(.*?)\n\s*}" % name, general, re.S).group(1)
            self.assertIn(f"from: {entry.findtext(f'{KCFG}min')}", block, name)
            self.assertIn(f"to: {entry.findtext(f'{KCFG}max')}", block, name)


class PackageTest(unittest.TestCase):
    def setUp(self):
        self.package = load_script("package")

    def test_build_is_valid_and_reproducible(self):
        first = self.package.build()
        digest = first.read_bytes()
        second = self.package.build()
        self.assertEqual(digest, second.read_bytes(), "two builds differ")
        with zipfile.ZipFile(second) as zf:
            names = zf.namelist()
        self.assertIn("metadata.json", names)
        self.assertFalse(any(n.startswith(("package/", "tests/", "scripts/", ".")) for n in names))

    def test_verify_rejects_unexpected_files(self):
        archive = self.package.build()
        with tempfile.TemporaryDirectory() as tmp:
            bad = Path(tmp) / archive.name
            shutil.copy(archive, bad)
            with zipfile.ZipFile(bad, "a") as zf:
                zf.writestr("contents/ui/.secret", "token")
            with self.assertRaises(SystemExit):
                self.package.verify(bad)

    def test_check_tag(self):
        version = json.loads((PACKAGE / "metadata.json").read_text())["KPlugin"]["Version"]
        self.package.check_tag(f"v{version}")
        with self.assertRaises(SystemExit):
            self.package.check_tag("v0.0.0-wrong")


class InitTest(unittest.TestCase):
    """Runs scripts/init.py on a throwaway copy of the repository."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.copy = Path(self.tmp.name) / "repo"
        shutil.copytree(REPO, self.copy, ignore=shutil.ignore_patterns(".git", "build", "dist", "__pycache__"))
        for args in (["init", "-q"], ["add", "-A"],
                     ["-c", "user.name=t", "-c", "user.email=t@example.org", "commit", "-qm", "base"]):
            subprocess.run(["git", "-C", str(self.copy), *args], check=True)

    def tearDown(self):
        self.tmp.cleanup()

    def run_init(self, *extra):
        return subprocess.run(
            ["python3", str(self.copy / "scripts" / "init.py"),
             "--plugin-id", "org.example.demo.clock", "--name", "Demo Clock",
             "--repo-name", "plasma-applet-demo-clock", "--repo-url", "https://example.org/me/plasma-applet-demo-clock",
             "--author", "Jane Doe", "--email", "jane@example.org", "--description", "A small demonstration clock",
             "--license", "GPL-3.0-or-later", "--category", "Date and Time", "--min-plasma", "6.1",
             "--version", "0.1.0", *extra],
            capture_output=True, text=True, stdin=subprocess.DEVNULL)

    def test_rewrites_identifiers_everywhere(self):
        result = self.run_init()
        self.assertEqual(result.returncode, 0, result.stderr)
        meta = json.loads((self.copy / "package" / "metadata.json").read_text())
        self.assertEqual(meta["KPlugin"]["Id"], "org.example.demo.clock")
        self.assertEqual(meta["KPlugin"]["Authors"], [{"Name": "Jane Doe", "Email": "jane@example.org"}])
        self.assertEqual(meta["X-Plasma-API-Minimum-Version"], "6.1")
        old_id = json.loads((REPO / "package" / "metadata.json").read_text())["KPlugin"]["Id"]
        leftovers = subprocess.run(["git", "-C", str(self.copy), "grep", "-l", old_id],
                                   capture_output=True, text=True).stdout.split()
        self.assertEqual(leftovers, [], f"old plugin id left in {leftovers}")
        self.assertTrue((self.copy / "po" / "plasma_applet_org.example.demo.clock.pot").exists())

    def test_rejects_invalid_input_without_writing(self):
        result = subprocess.run(["python3", str(self.copy / "scripts" / "init.py"), "--plugin-id", "Not An Id",
                                 "--category", "Nope"], capture_output=True, text=True, stdin=subprocess.DEVNULL)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("plugin-id", result.stderr)
        status = subprocess.run(["git", "-C", str(self.copy), "status", "--porcelain"],
                                capture_output=True, text=True).stdout
        self.assertEqual(status, "")

    def test_refuses_dirty_tree(self):
        (self.copy / "package" / "contents" / "ui" / "main.qml").write_text("// local edit\n")
        result = self.run_init()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("uncommitted", result.stderr)
        self.assertEqual((self.copy / "package" / "contents" / "ui" / "main.qml").read_text(), "// local edit\n")

    def test_dry_run_writes_nothing(self):
        result = self.run_init("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would update package/metadata.json", result.stdout)
        status = subprocess.run(["git", "-C", str(self.copy), "status", "--porcelain"],
                                capture_output=True, text=True).stdout
        self.assertEqual(status, "")


if __name__ == "__main__":
    unittest.main()
