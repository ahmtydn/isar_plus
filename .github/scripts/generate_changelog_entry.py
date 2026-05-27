#!/usr/bin/env python3
"""Generate one release-notes body using GitHub's label-aware release notes API."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


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


def generate_notes(
    repo: str,
    version: str,
    target: str,
    previous_tag: str | None,
) -> str:
    cmd = [
        "gh",
        "api",
        f"repos/{repo}/releases/generate-notes",
        "-X",
        "POST",
        "-f",
        f"tag_name={version}",
        "-f",
        f"target_commitish={target}",
    ]
    if previous_tag:
        cmd.extend(["-f", f"previous_tag_name={previous_tag}"])

    result = run(cmd)
    payload = json.loads(result.stdout)
    notes = (payload.get("body") or "").strip()
    if not notes:
        notes = "## What's Changed\n\nNo user-facing changes were detected."
    return notes


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--target", default="main")
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY", ""))
    parser.add_argument("--previous-tag", default="")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    if not args.repo:
        fail("--repo or GITHUB_REPOSITORY is required")

    notes = generate_notes(
        args.repo,
        args.version,
        args.target,
        args.previous_tag or None,
    )
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(notes + "\n", encoding="utf-8")
    print(f"wrote release notes to {output}")


if __name__ == "__main__":
    main()
