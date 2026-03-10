#!/usr/bin/env bash
set -euo pipefail

ALLOWED_TYPES="feat|fix|perf|revert|docs|style|refactor|test|build|ci|chore"

usage() {
  cat <<'USAGE'
Usage:
  validate_commit_message.sh --message "<full commit message>"
  validate_commit_message.sh --file <path-to-commit-message-file>

Validation:
  - first line format: <type>(<scope>): <subject>
  - allowed types: feat|fix|perf|revert|docs|style|refactor|test|build|ci|chore
  - subject must be lowercase and must not end with "."
USAGE
}

INPUT_MESSAGE=""
INPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message)
      INPUT_MESSAGE="${2-}"
      shift 2
      ;;
    -f|--file)
      INPUT_FILE="${2-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -n "$INPUT_MESSAGE" && -n "$INPUT_FILE" ]]; then
  echo "[ERROR] Use either --message or --file, not both." >&2
  exit 2
fi

if [[ -z "$INPUT_MESSAGE" && -z "$INPUT_FILE" ]]; then
  echo "[ERROR] Missing input. Provide --message or --file." >&2
  exit 2
fi

if [[ -n "$INPUT_FILE" ]]; then
  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "[ERROR] File not found: $INPUT_FILE" >&2
    exit 2
  fi
  INPUT_MESSAGE="$(cat "$INPUT_FILE")"
fi

HEADER="$(printf '%s\n' "$INPUT_MESSAGE" | head -n 1)"

if [[ -z "$HEADER" ]]; then
  echo "[ERROR] Empty commit message." >&2
  exit 1
fi

HEADER_REGEX="^(${ALLOWED_TYPES})(\\([a-z0-9._/-]+\\))(!)?: .+$"

if ! [[ "$HEADER" =~ $HEADER_REGEX ]]; then
  echo "[ERROR] Invalid header format: $HEADER" >&2
  echo "Expected: <type>(<scope>): <subject>" >&2
  exit 1
fi

SUBJECT="${HEADER#*: }"

if [[ "$SUBJECT" =~ \.$ ]]; then
  echo "[ERROR] Subject must not end with a period." >&2
  exit 1
fi

if [[ "$SUBJECT" =~ [A-Z] ]]; then
  echo "[ERROR] Subject must be lowercase." >&2
  exit 1
fi

if [[ ${#SUBJECT} -gt 50 ]]; then
  echo "[WARN] Subject length is ${#SUBJECT}. Recommended: <= 50 characters." >&2
fi

if grep -q "^BREAKING CHANGE:" <<<"$INPUT_MESSAGE"; then
  echo "[OK] BREAKING CHANGE footer detected."
fi

echo "[OK] Conventional Commit message is valid."
