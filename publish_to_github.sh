#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<USAGE
Usage:
  ./publish_to_github.sh [source.html] [--push]

Examples:
  ./publish_to_github.sh Grapher_v13_updated.html
  ./publish_to_github.sh --push

Behavior:
  1) Copies source file to index.html
  2) If this folder is a git repo, stages index.html (+ source file if tracked)
  3) With --push: commits and pushes to current branch
USAGE
}

SOURCE=""
DO_PUSH="false"

for arg in "$@"; do
  case "$arg" in
    --push)
      DO_PUSH="true"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$SOURCE" ]]; then
        SOURCE="$arg"
      else
        echo "Error: too many positional arguments"
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$SOURCE" ]]; then
  SOURCE="$(ls -1t Grapher_v*.html 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "$SOURCE" ]]; then
  echo "Error: no source file found. Pass one explicitly, e.g. ./publish_to_github.sh Grapher_v13_updated.html"
  exit 1
fi

if [[ ! -f "$SOURCE" ]]; then
  echo "Error: source file '$SOURCE' does not exist"
  exit 1
fi

cp "$SOURCE" index.html
printf "Created index.html from %s\n" "$SOURCE"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git add index.html
  if git ls-files --error-unmatch "$SOURCE" >/dev/null 2>&1; then
    git add "$SOURCE"
  fi

  if [[ "$DO_PUSH" == "true" ]]; then
    if git diff --cached --quiet; then
      echo "No staged changes to commit."
      exit 0
    fi

    COMMIT_MSG="Publish $(basename "$SOURCE") as index.html"
    git commit -m "$COMMIT_MSG"
    git push
    echo "Committed and pushed: $COMMIT_MSG"
  else
    echo "Staged index.html. Review and run: git commit -m 'Publish $(basename "$SOURCE") as index.html' && git push"
  fi
else
  echo "Not a git repository here. index.html is ready; commit/push from your GitHub repo folder."
fi
