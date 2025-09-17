#!/usr/bin/env bash
set -euo pipefail

# delete-all-tags.sh
# Safely backup and delete all git tags (local and remote).
# Usage:
#   ./delete-all-tags.sh            -> interactive (asks before deleting)
#   ./delete-all-tags.sh -n         -> dry-run (shows what would be done)
#   ./delete-all-tags.sh -y -r origin  -> non-interactive, delete local+remote on 'origin'

REMOTE="origin"
DRY_RUN=0
ASSUME_YES=0
VERBOSE=0

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -r, --remote NAME    Remote name to delete tags from (default: origin)
  -n, --dry-run        Show actions without performing them
  -y, --yes            Skip confirmation prompt
  -v, --verbose        Print detailed output
  -h, --help           Show this help

Examples:
  $0 -n                   # dry-run
  $0 -y -r upstream       # delete on remote 'upstream' non-interactively

This script will:
  - save local tags to a timestamped backup file
  - save remote tags (from the specified remote) to a timestamped backup file
  - delete all local tags
  - delete all remote tags on the specified remote

EOF
}

while [[ ${#} -gt 0 ]]; do
  case "$1" in
    -r|--remote)
      REMOTE="$2"; shift 2;;
    -n|--dry-run)
      DRY_RUN=1; shift;;
    -y|--yes)
      ASSUME_YES=1; shift;;
    -v|--verbose)
      VERBOSE=1; shift;;
    -h|--help)
      usage; exit 0;;
    --)
      shift; break;;
    -*|--*)
      echo "Unknown option: $1" >&2; usage; exit 1;;
    *)
      break;;
  esac
done

echo "Checking repository..."
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

TS=$(date +%Y%m%d-%H%M%S)
LOCAL_BACKUP="deleted-tags-backup-local-${TS}.txt"
REMOTE_BACKUP="deleted-tags-backup-remote-${TS}.txt"

# Collect local tags (POSIX-compatible)
LOCAL_TAGS=()
while IFS= read -r tag; do
  LOCAL_TAGS+=("$tag")
done < <(git tag -l)

# Collect remote tags (clean names) (POSIX-compatible)
REMOTE_TAGS=()
while IFS= read -r tag; do
  REMOTE_TAGS+=("$tag")
done < <(git ls-remote --tags "$REMOTE" 2>/dev/null | awk '{print $2}' | sed 's#refs/tags/##' | sed 's/\^{}//' | sort -u)

if [[ ${VERBOSE} -eq 1 ]]; then
  echo "Local tags (${#LOCAL_TAGS[@]}):"
  printf '  %s\n' "${LOCAL_TAGS[@]}"
  echo "Remote tags on '$REMOTE' (${#REMOTE_TAGS[@]}):"
  printf '  %s\n' "${REMOTE_TAGS[@]}"
fi

# Save backups
if [[ ${DRY_RUN} -eq 0 ]]; then
  printf "%s\n" "${LOCAL_TAGS[@]}" > "$LOCAL_BACKUP" || true
  printf "%s\n" "${REMOTE_TAGS[@]}" > "$REMOTE_BACKUP" || true
  echo "Backups written: $LOCAL_BACKUP, $REMOTE_BACKUP"
else
  echo "Dry-run: would write backups to $LOCAL_BACKUP and $REMOTE_BACKUP"
fi

if [[ ${#LOCAL_TAGS[@]} -eq 0 && ${#REMOTE_TAGS[@]} -eq 0 ]]; then
  echo "No tags found (local or on remote '$REMOTE'). Nothing to do."
  exit 0
fi

echo "Summary:"
echo "  Local tags: ${#LOCAL_TAGS[@]}"
echo "  Remote tags on '$REMOTE': ${#REMOTE_TAGS[@]}"

if [[ ${ASSUME_YES} -ne 1 ]]; then
  read -r -p "Proceed to delete all these tags (local + remote on '$REMOTE')? [y/N] " CONFIRM
  case "$CONFIRM" in
    [yY][eE][sS]|[yY]) ;;
    *) echo "Aborted."; exit 0;;
  esac
fi

# Delete local tags
if [[ ${#LOCAL_TAGS[@]} -gt 0 ]]; then
  echo "Deleting local tags..."
  for t in "${LOCAL_TAGS[@]}"; do
    if [[ ${DRY_RUN} -eq 1 ]]; then
      echo "git tag -d $t"
    else
      if git tag -d "$t"; then
        echo "Deleted local tag: $t"
      else
        echo "Failed to delete local tag: $t" >&2
      fi
    fi
  done
else
  echo "No local tags to delete."
fi

# Delete remote tags
if [[ ${#REMOTE_TAGS[@]} -gt 0 ]]; then
  echo "Deleting remote tags on '$REMOTE'..."
  for t in "${REMOTE_TAGS[@]}"; do
    if [[ -z "$t" ]]; then
      continue
    fi
    if [[ ${DRY_RUN} -eq 1 ]]; then
      echo "git push $REMOTE --delete $t"
    else
      if git push "$REMOTE" --delete "$t"; then
        echo "Deleted remote tag on $REMOTE: $t"
      else
        echo "Failed to delete remote tag on $REMOTE: $t" >&2
      fi
    fi
  done
else
  echo "No remote tags to delete on '$REMOTE'."
fi

# Final listing
echo "Final tag lists (local):"
git tag -l || true

echo "Final tag lists (remote '$REMOTE'):" 
if git ls-remote --tags "$REMOTE" 2>/dev/null | grep -q .; then
  git ls-remote --tags "$REMOTE" || true
else
  echo "  (no tags)"
fi

echo "Done. Backups are in: $LOCAL_BACKUP and $REMOTE_BACKUP (if not a dry-run)."
