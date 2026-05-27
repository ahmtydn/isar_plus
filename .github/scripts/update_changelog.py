#!/usr/bin/env python3
"""Insert or replace a version section in package CHANGELOG files."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


DEFAULT_CHANGELOGS = [
    "packages/isar_plus/CHANGELOG.md",
    "packages/isar_plus_flutter_libs/CHANGELOG.md",
]
HEADING_RE = re.compile(
    r"^##\s+(v?\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)\s*$",
    re.MULTILINE,
)


def normalize_version(value: str) -> str:
    return value.strip().lstrip("v")


def build_entry(version: str, notes: str) -> str:
    return f"## {version}\n\n{notes.strip()}\n\n"


def replace_existing(content: str, version: str, entry: str) -> tuple[str, bool]:
    matches = list(HEADING_RE.finditer(content))
    wanted = normalize_version(version)
    for index, match in enumerate(matches):
        heading = match.group(1).strip()
        if normalize_version(heading) != wanted:
            continue
        start = match.start()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(content)
        prefix = content[:start].rstrip()
        separator = "\n\n" if prefix else ""
        return prefix + separator + entry + content[end:].lstrip(), True
    return content, False


def insert_entry(content: str, entry: str) -> str:
    if content.startswith("# "):
        first_line_end = content.find("\n")
        if first_line_end == -1:
            return content.rstrip() + "\n\n" + entry
        return (
            content[: first_line_end + 1].rstrip()
            + "\n\n"
            + entry
            + content[first_line_end + 1 :].lstrip()
        )
    return entry + content.lstrip()


def update_changelog(path: Path, version: str, notes: str) -> None:
    content = path.read_text(encoding="utf-8") if path.exists() else ""
    entry = build_entry(version, notes)
    updated, replaced = replace_existing(content, version, entry)
    if not replaced:
        updated = insert_entry(content, entry)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(updated.rstrip() + "\n", encoding="utf-8")
    action = "replaced" if replaced else "inserted"
    print(f"{action} {version} in {path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--notes-file", required=True)
    parser.add_argument("--file", action="append", dest="files")
    args = parser.parse_args()

    notes = Path(args.notes_file).read_text(encoding="utf-8")
    files = args.files or DEFAULT_CHANGELOGS
    for file_name in files:
        update_changelog(Path(file_name), args.version, notes)


if __name__ == "__main__":
    main()
