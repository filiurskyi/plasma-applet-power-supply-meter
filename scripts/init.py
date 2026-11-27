#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
"""Turn a copy of this repository into a new widget.

Run it once in a fresh clone (e.g. made with GitHub's "Use this template").
It rewrites the plugin id, name, author, URLs, licence and other identifiers
everywhere they occur, and renames the translation template. Missing
options are asked for interactively.

Safety: it refuses to run on a dirty git tree (so every change can be
reviewed with `git diff` and undone with `git checkout .`), never deletes
files other than the renamed translation template, and --dry-run shows what
would change without writing anything.
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
METADATA = REPO / "package" / "metadata.json"

# https://develop.kde.org/docs/plasma/widget/properties/#category
CATEGORIES = [
    "Accessibility", "Application Launchers", "Astronomy", "Date and Time",
    "Development Tools", "Education", "Environment and Weather", "Examples",
    "File System", "Fun and Games", "Graphics", "Language", "Mapping",
    "Multimedia", "Online Services", "System Information", "Utilities",
    "Windows and Tasks",
]

# Files rewritten in place. Licence texts, images and generated output are
# never touched.
SKIP_DIRS = {".git", "LICENSES", "build", "dist", "screenshots", "__pycache__"}
SKIP_FILES = {"LICENSE"}
TEXT_SUFFIXES = {".qml", ".js", ".json", ".xml", ".md", ".sh", ".py", ".toml", ".yml",
                 ".yaml", ".pot", ".po", ".ini", ".txt", ""}

VALIDATORS = {
    "plugin_id": (r"^(?!org\.kde\.)[a-z][a-z0-9]*(\.[a-z][a-z0-9_]*){2,}$",
                  "lower-case reverse-domain name with at least three parts, e.g. io.github.you.mywidget "
                  "(org.kde.* is reserved for KDE)"),
    "name": (r"^[^\"\\\n]{3,60}$", "3-60 characters, no quotes or backslashes"),
    "repo_name": (r"^[A-Za-z0-9._-]{1,100}$", "letters, digits, '.', '_' and '-' only"),
    "repo_url": (r"^https://[^\s\"']+[^/\s\"']$", "an https:// URL without a trailing slash"),
    "author": (r"^[^\"\\\n<>]{2,80}$", "2-80 characters, no quotes, backslashes or <>"),
    "email": (r"^$|^[^@\s\"<>]+@[^@\s\"<>]+\.[^@\s\"<>]+$", "an e-mail address, or empty"),
    "description": (r"^[^\"\\\n]{10,200}$", "10-200 characters on one line, no quotes or backslashes"),
    "license": (r"^[A-Za-z0-9.+-]+$", "an SPDX identifier such as GPL-3.0-or-later"),
    "min_plasma": (r"^6\.\d+$", "a Plasma 6 version such as 6.0"),
    "version": (r"^\d+\.\d+\.\d+$", "a semantic version such as 0.1.0"),
}


def current():
    meta = json.loads(METADATA.read_text(encoding="utf-8"))
    plugin = meta["KPlugin"]
    author = plugin.get("Authors", [{}])[0]
    url = plugin.get("Website", "")
    return {
        "plugin_id": plugin["Id"],
        "name": plugin["Name"],
        "repo_name": url.rstrip("/").rsplit("/", 1)[-1],
        "repo_url": url,
        "author": author.get("Name", ""),
        "email": author.get("Email", ""),
        "description": plugin["Description"],
        "license": plugin["License"],
        "category": plugin["Category"],
        "min_plasma": meta.get("X-Plasma-API-Minimum-Version", "6.0"),
        "version": plugin["Version"],
    }


def validate(values):
    errors = []
    for key, (pattern, hint) in VALIDATORS.items():
        if not re.match(pattern, values[key]):
            errors.append(f"--{key.replace('_', '-')}: {values[key]!r} is not valid: {hint}")
    if values["category"] not in CATEGORIES:
        errors.append(f"--category: {values['category']!r} is not one of: {', '.join(CATEGORIES)}")
    if not values["repo_url"].endswith("/" + values["repo_name"]):
        errors.append("--repo-url must end with /<repo-name>")
    if not (REPO / "LICENSES" / f"{values['license']}.txt").exists():
        errors.append(f"--license: LICENSES/{values['license']}.txt is missing; add it first, e.g. "
                      f"`reuse download {values['license']}` (this script never downloads anything)")
    return errors


def git_is_clean():
    try:
        out = subprocess.run(["git", "-C", str(REPO), "status", "--porcelain"],
                             capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        return False
    return out.strip() == ""


def text_files():
    for path in sorted(REPO.rglob("*")):
        rel = path.relative_to(REPO)
        if any(part in SKIP_DIRS for part in rel.parts) or not path.is_file():
            continue
        if rel.name in SKIP_FILES or path.suffix not in TEXT_SUFFIXES:
            continue
        yield path


def replacements(old, new):
    pairs = []
    # Longest first, so a URL is replaced before the repository name inside it.
    for key in ("repo_url", "plugin_id", "description", "repo_name", "name", "author"):
        if old[key] and old[key] != new[key]:
            pairs.append((old[key], new[key]))
    # REUSE-IgnoreStart
    if old["license"] != new["license"]:
        pairs.append((f"SPDX-License-Identifier: {old['license']}", f"SPDX-License-Identifier: {new['license']}"))
        pairs.append((f'SPDX-License-Identifier = "{old["license"]}"', f'SPDX-License-Identifier = "{new["license"]}"'))
    # REUSE-IgnoreEnd
    return sorted(pairs, key=lambda pair: -len(pair[0]))


def apply(old, new, dry_run):
    changed = []
    pairs = replacements(old, new)
    for path in text_files():
        if path == METADATA:
            continue
        text = path.read_text(encoding="utf-8")
        updated = text
        for before, after in pairs:
            updated = updated.replace(before, after)
        if updated != text:
            changed.append(path)
            if not dry_run:
                path.write_text(updated, encoding="utf-8")

    meta = json.loads(METADATA.read_text(encoding="utf-8"))
    plugin = meta["KPlugin"]
    author = {"Name": new["author"]}
    if new["email"]:
        author["Email"] = new["email"]
    plugin.update({
        "Authors": [author],
        "BugReportUrl": new["repo_url"] + "/issues",
        "Category": new["category"],
        "Description": new["description"],
        "Id": new["plugin_id"],
        "License": new["license"],
        "Name": new["name"],
        "Version": new["version"],
        "Website": new["repo_url"],
    })
    meta["X-Plasma-API-Minimum-Version"] = new["min_plasma"]
    changed.append(METADATA)

    old_pot = REPO / "po" / f"plasma_applet_{old['plugin_id']}.pot"
    new_pot = REPO / "po" / f"plasma_applet_{new['plugin_id']}.pot"
    if dry_run:
        for path in changed:
            print(f"would update {path.relative_to(REPO)}")
        if old_pot != new_pot and old_pot.exists():
            print(f"would rename {old_pot.relative_to(REPO)} -> {new_pot.relative_to(REPO)}")
        return

    METADATA.write_text(json.dumps(meta, indent=4, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    if old_pot != new_pot and old_pot.exists():
        old_pot.rename(new_pot)
    if old["license"] != new["license"]:
        (REPO / "LICENSE").write_text((REPO / "LICENSES" / f"{new['license']}.txt").read_text(encoding="utf-8"),
                                      encoding="utf-8")
    for path in changed:
        print(f"updated {path.relative_to(REPO)}")
    print("\nDone. Review with `git diff`, then replace the example code, README text and screenshots.")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    for key in VALIDATORS:
        parser.add_argument("--" + key.replace("_", "-"))
    parser.add_argument("--category")
    parser.add_argument("--dry-run", action="store_true", help="show what would change, write nothing")
    parser.add_argument("--allow-dirty", action="store_true", help="run even with uncommitted changes")
    args = parser.parse_args()

    old = current()
    new = dict(old)
    interactive = sys.stdin.isatty()
    for key in list(VALIDATORS) + ["category"]:
        value = getattr(args, key)
        if value is None and interactive:
            label = key.replace("_", " ")
            if key == "category":
                print("Categories: " + ", ".join(CATEGORIES))
            value = input(f"{label} [{old[key]}]: ").strip() or old[key]
        if value is not None:
            new[key] = value.strip()

    errors = validate(new)
    if new["plugin_id"] == old["plugin_id"]:
        errors.append("--plugin-id must differ from the template's id, or both widgets would collide")
    if errors:
        sys.exit("init: invalid input\n  " + "\n  ".join(errors))
    if not args.dry_run and not args.allow_dirty and not git_is_clean():
        sys.exit("init: the git tree has uncommitted changes (or this is not a git checkout).\n"
                 "Commit or stash them first so the result can be reviewed and undone, or pass --allow-dirty.")
    apply(old, new, args.dry_run)


if __name__ == "__main__":
    main()
