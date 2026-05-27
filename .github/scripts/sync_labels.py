#!/usr/bin/env python3
"""Synchronize the simple .github/labels.yml mapping with GitHub labels."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote


LABEL_RE = re.compile(
    r"^\s*(?P<name>\"[^\"]+\"|'[^']+'|[^#][^:]*?)\s*:\s*"
    r"(?P<color>\"?#[0-9a-fA-F]{6}\"?)\s*$"
)


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    if env.get("GITHUB_TOKEN") and not env.get("GH_TOKEN"):
        env["GH_TOKEN"] = env["GITHUB_TOKEN"]
    result = subprocess.run(
        cmd,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
    )
    if result.returncode != 0:
        print(result.stdout, end="")
        print(result.stderr, end="", file=sys.stderr)
        fail(f"command failed: {' '.join(cmd)}")
    return result


def parse_labels(path: Path) -> dict[str, str]:
    labels: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        match = LABEL_RE.match(line)
        if not match:
            continue
        name = match.group("name").strip().strip("\"'")
        color = match.group("color").strip().strip("\"'").lstrip("#")
        labels[name] = color
    return labels


def existing_labels(repo: str) -> set[str]:
    result = run(["gh", "label", "list", "--repo", repo, "--limit", "1000", "--json", "name"])
    payload = json.loads(result.stdout)
    return {label["name"] for label in payload}


def sync_label(repo: str, name: str, color: str, exists: bool) -> None:
    if exists:
        encoded = quote(name, safe="")
        run(
            [
                "gh",
                "api",
                f"repos/{repo}/labels/{encoded}",
                "-X",
                "PATCH",
                "-f",
                f"new_name={name}",
                "-f",
                f"color={color}",
            ]
        )
        print(f"updated {name}")
    else:
        run(
            [
                "gh",
                "api",
                f"repos/{repo}/labels",
                "-X",
                "POST",
                "-f",
                f"name={name}",
                "-f",
                f"color={color}",
            ]
        )
        print(f"created {name}")


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: sync_labels.py .github/labels.yml")
    repo = os.environ.get("GITHUB_REPOSITORY")
    if not repo:
        fail("GITHUB_REPOSITORY is required")

    labels = parse_labels(Path(sys.argv[1]))
    current = existing_labels(repo)
    for name, color in labels.items():
        sync_label(repo, name, color, name in current)


if __name__ == "__main__":
    main()
