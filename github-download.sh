#!/usr/bin/env bash
# Download a GitHub repo or only one folder from a GitHub repo.
# Tags: github, download, repo, folder, git
#
# README:
# This script helps you download files from GitHub.
# Copy this script, make it executable, then run one command.
#
# Step 1: Make it executable
#   chmod +x github-download.sh
#
# Step 2: Download a whole repo
#   ./github-download.sh --user OWNER --repo REPO
#
# Step 3: Download only one folder
#   ./github-download.sh --user OWNER --repo REPO --folder path/to/folder
#
# Example:
#   ./github-download.sh --user mac-tool --repo scripts
#
# Example with folder:
#   ./github-download.sh --user jszipp --repo jszipp --branch main --folder demo
#   ./github-download.sh --user imputnet --repo helium-macos --branch main --folder patches/helium/macos
#
# Tip:
# Replace OWNER, REPO, and path/to/folder with your real GitHub values.

set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $0 --user OWNER --repo REPO [--branch BRANCH] [--folder PATH] [--dest DIR]

Examples:
  $0 --user owner --repo repository --branch main
  $0 --user owner --repo repository --branch main --folder path/to/directory
  $0 --user owner --repo repository --branch main --folder path/to/directory --dest ~/Downloads

Options:
  -u, --user      GitHub owner/user/org name
  -r, --repo      GitHub repository name
  -b, --branch    Branch name, default: main
  -f, --folder    Folder path inside the repo. If omitted, downloads whole repo.
  -d, --dest      Download destination, default: ~/Downloads
  -h, --help      Show this help
EOF
}

make_unique_path() {
  local path="$1"

  if [[ ! -e "$path" ]]; then
    echo "$path"
    return
  fi

  local counter=1
  local new_path

  while true; do
    new_path="${path}-${counter}"

    if [[ ! -e "$new_path" ]]; then
      echo "$new_path"
      return
    fi

    counter=$((counter + 1))
  done
}

GITHUB_USER=""
GITHUB_REPO=""
BRANCH="main"
FOLDER_PATH=""
DEST_DIR="$HOME/Downloads"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--user)
      GITHUB_USER="${2:-}"
      shift 2
      ;;
    -r|--repo)
      GITHUB_REPO="${2:-}"
      shift 2
      ;;
    -b|--branch)
      BRANCH="${2:-}"
      shift 2
      ;;
    -f|--folder)
      FOLDER_PATH="${2:-}"
      shift 2
      ;;
    -d|--dest)
      DEST_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$GITHUB_USER" || -z "$GITHUB_REPO" ]]; then
  echo "Error: --user and --repo are required."
  usage
  exit 1
fi

command -v git >/dev/null 2>&1 || {
  echo "Error: git is required."
  exit 1
}

mkdir -p "$DEST_DIR"

REPO_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git"
WORK_DIR="$(mktemp -d)"
CLONE_DIR="$WORK_DIR/repo"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

if [[ -n "$FOLDER_PATH" ]]; then
  FOLDER_PATH="${FOLDER_PATH%/}"

  OUTPUT_NAME="$(basename "$FOLDER_PATH")"
  TARGET_PATH="$(make_unique_path "$DEST_DIR/$OUTPUT_NAME")"

  echo "Downloading only folder:"
  echo "  Repo:   $GITHUB_USER/$GITHUB_REPO"
  echo "  Branch: $BRANCH"
  echo "  Folder: $FOLDER_PATH"
  echo "  Output: $TARGET_PATH"

  git clone \
    --depth 1 \
    --filter=blob:none \
    --sparse \
    --branch "$BRANCH" \
    "$REPO_URL" \
    "$CLONE_DIR"

  git -C "$CLONE_DIR" sparse-checkout set "$FOLDER_PATH"

  if [[ ! -d "$CLONE_DIR/$FOLDER_PATH" ]]; then
    echo "Error: Folder path not found in the repository:"
    echo "  $FOLDER_PATH"
    exit 1
  fi

  mv "$CLONE_DIR/$FOLDER_PATH" "$TARGET_PATH"

  echo "Successfully downloaded folder to:"
  echo "  $TARGET_PATH"
else
  OUTPUT_NAME="${GITHUB_REPO}-${BRANCH}"
  TARGET_PATH="$(make_unique_path "$DEST_DIR/$OUTPUT_NAME")"

  echo "Downloading entire repository:"
  echo "  Repo:   $GITHUB_USER/$GITHUB_REPO"
  echo "  Branch: $BRANCH"
  echo "  Output: $TARGET_PATH"

  git clone \
    --depth 1 \
    --branch "$BRANCH" \
    "$REPO_URL" \
    "$TARGET_PATH"

  rm -rf "$TARGET_PATH/.git"

  echo "Successfully downloaded repository to:"
  echo "  $TARGET_PATH"
fi