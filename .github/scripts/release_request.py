#!/usr/bin/env python3
"""Gate release automation behind labels and an explicit maintainer comment."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path


ALLOWED_ASSOCIATIONS = {"OWNER", "MEMBER", "COLLABORATOR"}
REQUEST_LABELS = {
    "release:request",
    "release:patch",
    "release:minor",
    "release:major",
    "release:prerelease",
}
SKIP_LABELS = {"release:skip", "ignore-for-release"}
MARKER = "<!-- isar-plus-release-request -->"
RESULT_MARKER = "<!-- isar-plus-release-result -->"
SEMVER_RE = re.compile(
    r"^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
    r"(?:-([0-9A-Za-z][0-9A-Za-z.-]*))?"
    r"(?:\+([0-9A-Za-z][0-9A-Za-z.-]*))?$"
)


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def load_event() -> dict:
    event_path = os.environ.get("GITHUB_EVENT_PATH")
    if not event_path:
        fail("GITHUB_EVENT_PATH is not set")
    return json.loads(Path(event_path).read_text(encoding="utf-8"))


def repository(event: dict) -> str:
    return os.environ.get("GITHUB_REPOSITORY") or event["repository"]["full_name"]


def default_branch(event: dict) -> str:
    return event.get("repository", {}).get("default_branch", "main")


def run(cmd: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
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
    if check and result.returncode != 0:
        print(result.stdout, end="")
        print(result.stderr, end="", file=sys.stderr)
        fail(f"command failed: {' '.join(cmd)}")
    return result


def gh_api(
    repo: str,
    path: str,
    *,
    method: str = "GET",
    fields: dict[str, str] | None = None,
    check: bool = True,
):
    cmd = ["gh", "api", path]
    if method != "GET":
        cmd.extend(["-X", method])
    for key, value in (fields or {}).items():
        cmd.extend(["-f", f"{key}={value}"])
    result = run(cmd, check=check)
    if result.returncode != 0 or not result.stdout.strip():
        return None
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return result.stdout


def write_output(name: str, value: str | bool | int) -> None:
    output_path = os.environ.get("GITHUB_OUTPUT")
    text = "true" if value is True else "false" if value is False else str(value)
    if output_path:
        with Path(output_path).open("a", encoding="utf-8") as output:
            output.write(f"{name}={text}\n")
    print(f"{name}={text}")


def write_release_outputs(**values: str | bool | int) -> None:
    defaults: dict[str, str | bool | int] = {
        "should_release": False,
        "version": "",
        "base_ref": "",
        "pr_number": "",
        "release_labels": "",
    }
    defaults.update(values)
    for key, value in defaults.items():
        write_output(key, value)


def label_names(labels: list[dict] | list[str]) -> set[str]:
    names: set[str] = set()
    for label in labels:
        if isinstance(label, str):
            names.add(label)
        else:
            names.add(label.get("name", ""))
    return {name for name in names if name}


def release_labels(labels: set[str]) -> list[str]:
    return sorted(labels & REQUEST_LABELS)


def has_skip_label(labels: set[str]) -> bool:
    return bool(labels & SKIP_LABELS)


def parse_semver(value: str):
    match = SEMVER_RE.match(value)
    if not match:
        return None
    major, minor, patch, prerelease, build = match.groups()
    return {
        "raw": value,
        "prefix": "v" if value.startswith("v") else "",
        "major": int(major),
        "minor": int(minor),
        "patch": int(patch),
        "prerelease": prerelease,
        "build": build,
    }


def version_key(parsed: dict) -> tuple[int, int, int]:
    return parsed["major"], parsed["minor"], parsed["patch"]


def latest_stable_tag() -> str | None:
    result = run(["git", "tag", "--list"], check=False)
    if result.returncode != 0:
        return None
    candidates: list[tuple[tuple[int, int, int], str]] = []
    for tag in result.stdout.splitlines():
        parsed = parse_semver(tag.strip())
        if parsed and not parsed["prerelease"]:
            candidates.append((version_key(parsed), tag.strip()))
    if not candidates:
        return None
    return sorted(candidates, key=lambda item: item[0])[-1][1]


def next_patch_tag(latest: str | None) -> str:
    if not latest:
        return "v1.0.0"
    parsed = parse_semver(latest)
    if not parsed:
        return "v1.0.0"
    return (
        f"{parsed['prefix']}{parsed['major']}."
        f"{parsed['minor']}.{parsed['patch'] + 1}"
    )


def tag_exists(version: str) -> bool:
    result = run(
        ["git", "rev-parse", "--quiet", "--verify", f"refs/tags/{version}"],
        check=False,
    )
    return result.returncode == 0


def validate_version(version: str, labels: set[str]) -> str | None:
    parsed = parse_semver(version)
    if not parsed:
        return (
            "Version format is invalid. Use SemVer, for example "
            "`/release 1.2.8` or `/release v1.3.0-beta.1`."
        )
    if tag_exists(version):
        return f"`{version}` tag already exists."
    if "release:prerelease" in labels and not parsed["prerelease"]:
        return "`release:prerelease` requires a prerelease version such as `v1.3.0-beta.1`."

    latest = latest_stable_tag()
    latest_parsed = parse_semver(latest) if latest else None
    if latest_parsed and not parsed["prerelease"]:
        if version_key(parsed) <= version_key(latest_parsed):
            return f"`{version}` must be greater than the latest stable tag `{latest}`."
    return None


def issue_comments(repo: str, issue_number: int) -> list[dict]:
    comments = gh_api(
        repo,
        f"repos/{repo}/issues/{issue_number}/comments?per_page=100",
        check=False,
    )
    return comments if isinstance(comments, list) else []


def post_comment(repo: str, issue_number: int, body: str) -> None:
    gh_api(
        repo,
        f"repos/{repo}/issues/{issue_number}/comments",
        method="POST",
        fields={"body": body},
    )


def upsert_comment(repo: str, issue_number: int, marker: str, body: str) -> None:
    for comment in issue_comments(repo, issue_number):
        if marker in comment.get("body", ""):
            gh_api(
                repo,
                f"repos/{repo}/issues/comments/{comment['id']}",
                method="PATCH",
                fields={"body": body},
            )
            return
    post_comment(repo, issue_number, body)


def request_body(pr: dict, labels: list[str], latest: str | None) -> str:
    suggestion = next_patch_tag(latest)
    label_text = ", ".join(f"`{label}`" for label in labels)
    return f"""{MARKER}
Waiting for a version to prepare this release.

After the PR is merged, an authorized user can post the following comment:

`/release {suggestion}`

Detected release labels: {label_text}
Latest stable tag: `{latest or 'none'}`

Notes will be added to CHANGELOG files according to the label categories in `.github/release.yml`. Once the tag is created, the `release.yaml` workflow will be automatically dispatched.
"""


def command_version(body: str) -> str | None:
    for line in body.splitlines():
        stripped = line.strip()
        if not stripped.startswith("/release"):
            continue
        parts = stripped.split()
        if len(parts) < 2 or parts[1].lower() in {"help", "?"}:
            return ""
        return parts[1]
    return None


def fetch_issue(repo: str, number: int) -> dict:
    issue = gh_api(repo, f"repos/{repo}/issues/{number}")
    if not isinstance(issue, dict):
        fail(f"could not load issue #{number}")
    return issue


def fetch_pull(repo: str, number: int) -> dict:
    pull = gh_api(repo, f"repos/{repo}/pulls/{number}")
    if not isinstance(pull, dict):
        fail(f"could not load pull request #{number}")
    return pull


def handle_request_version() -> None:
    event = load_event()
    repo = repository(event)
    pr = event.get("pull_request")
    if not pr:
        return

    labels = label_names(pr.get("labels", []))
    action = event.get("action", "")
    label = event.get("label", {}).get("name", "")
    if action == "labeled" and label not in REQUEST_LABELS and label not in SKIP_LABELS:
        return
    if has_skip_label(labels):
        return

    rel_labels = release_labels(labels)
    if not rel_labels:
        return
    if action == "closed" and not pr.get("merged"):
        return

    latest = latest_stable_tag()
    upsert_comment(
        repo,
        pr["number"],
        MARKER,
        request_body(pr, rel_labels, latest),
    )


def stop_with_comment(repo: str, issue_number: int, message: str) -> None:
    post_comment(repo, issue_number, f"{RESULT_MARKER}\n{message}")
    write_release_outputs()


def prepare_from_comment(event: dict, repo: str) -> None:
    comment = event.get("comment", {})
    issue_number = int(event.get("issue", {}).get("number", 0))
    version = command_version(comment.get("body", ""))
    if version is None:
        write_release_outputs()
        return
    if version == "":
        stop_with_comment(
            repo,
            issue_number,
            "Usage: `/release 1.2.8` or `/release v1.3.0-beta.1`.",
        )
        return

    association = comment.get("author_association", "")
    if association not in ALLOWED_ASSOCIATIONS:
        stop_with_comment(
            repo,
            issue_number,
            "Only OWNER, MEMBER, or COLLABORATOR users can request a release.",
        )
        return

    issue = fetch_issue(repo, issue_number)
    labels = label_names(issue.get("labels", []))
    if has_skip_label(labels):
        stop_with_comment(repo, issue_number, "`release:skip` is set, so no release was created.")
        return
    rel_labels = release_labels(labels)
    if not rel_labels:
        stop_with_comment(
            repo,
            issue_number,
            "Add one of `release:request`, `release:patch`, `release:minor`, `release:major`, or `release:prerelease` before using `/release`.",
        )
        return

    pull = fetch_pull(repo, issue_number)
    if not pull.get("merged"):
        stop_with_comment(repo, issue_number, "Merge this PR before requesting a release.")
        return

    base_ref = pull.get("base", {}).get("ref") or default_branch(event)
    if base_ref != default_branch(event):
        stop_with_comment(
            repo,
            issue_number,
            f"Release requests are only allowed from `{default_branch(event)}` PRs.",
        )
        return

    version_error = validate_version(version, labels)
    if version_error:
        stop_with_comment(repo, issue_number, version_error)
        return

    write_release_outputs(
        should_release=True,
        version=version,
        base_ref=base_ref,
        pr_number=issue_number,
        release_labels=",".join(rel_labels),
    )


def prepare_from_dispatch(event: dict, repo: str) -> None:
    inputs = event.get("inputs", {})
    version = (inputs.get("version") or "").strip()
    if not version:
        fail("workflow_dispatch input `version` is required")

    labels = {inputs.get("release_label", "release:request")}
    version_error = validate_version(version, labels)
    if version_error:
        fail(version_error)

    base_ref = inputs.get("base_ref") or default_branch(event)
    pr_number = inputs.get("pr_number", "")
    write_release_outputs(
        should_release=True,
        version=version,
        base_ref=base_ref,
        pr_number=pr_number,
        release_labels=",".join(sorted(labels)),
    )


def handle_prepare() -> None:
    event = load_event()
    repo = repository(event)
    event_name = os.environ.get("GITHUB_EVENT_NAME", "")
    if event_name == "issue_comment":
        prepare_from_comment(event, repo)
    elif event_name == "workflow_dispatch":
        prepare_from_dispatch(event, repo)
    else:
        write_release_outputs()


def handle_complete(args: argparse.Namespace) -> None:
    event = load_event()
    repo = repository(event)
    event_name = os.environ.get("GITHUB_EVENT_NAME", "")
    issue_number = ""
    if event_name == "issue_comment":
        issue_number = str(event.get("issue", {}).get("number", ""))
    elif args.pr_number:
        issue_number = str(args.pr_number)

    if not issue_number:
        return

    if args.status == "success":
        body = f"""{RESULT_MARKER}
Release request accepted for `{args.version}`.

- CHANGELOG files were updated.
- `{args.version}` tag was pushed.
- `release.yaml` was dispatched.

Run: {args.run_url}
"""
    else:
        body = f"""{RESULT_MARKER}
Release request for `{args.version}` failed.

Run: {args.run_url}
"""
    post_comment(repo, int(issue_number), body)


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("request-version")
    subparsers.add_parser("prepare")

    complete = subparsers.add_parser("complete")
    complete.add_argument("--status", choices=["success", "failure"], required=True)
    complete.add_argument("--version", required=True)
    complete.add_argument("--run-url", required=True)
    complete.add_argument("--pr-number", default="")

    args = parser.parse_args()
    if args.command == "request-version":
        handle_request_version()
    elif args.command == "prepare":
        handle_prepare()
    elif args.command == "complete":
        handle_complete(args)


if __name__ == "__main__":
    main()
