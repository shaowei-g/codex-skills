#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  validate_subagent_response.sh [--file <path>]

Validate that a subagent response conforms to the shared status-only response
contract. If no file is provided, stdin is used.
EOF
}

extract_first_bullet_value() {
  local heading=$1
  local file=$2

  awk -v heading="$heading" '
    $0 == heading { in_section = 1; next }
    in_section && /^[A-Za-z][A-Za-z -]*:$/ { exit }
    in_section && /^-[[:space:]]*/ {
      sub(/^-+[[:space:]]*/, "", $0)
      print
      exit
    }
  ' "$file"
}

require_enum_value() {
  local heading=$1
  local value=$2
  shift 2
  local allowed
  for allowed in "$@"; do
    if [[ "$value" == "$allowed" ]]; then
      return 0
    fi
  done
  echo "Invalid value for $heading: $value" >&2
  exit 1
}

require_nonempty_value() {
  local heading=$1
  local value=$2
  if [[ -z "${value//[[:space:]]/}" ]]; then
    echo "Missing value for $heading" >&2
    exit 1
  fi
}

input_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) input_file=${2-}; shift 2 ;;
    --feature|--assigned-phase|--assigned-subagent|--scope)
      # Accepted for backward compatibility but ignored by the status-only schema.
      shift 2
      ;;
    --help|-h) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

tmp_file=""
cleanup() {
  if [[ -n "$tmp_file" && -f "$tmp_file" ]]; then
    rm -f "$tmp_file"
  fi
}
trap cleanup EXIT

if [[ -n "$input_file" ]]; then
  [[ -f "$input_file" ]] || { echo "Response file not found: $input_file" >&2; exit 1; }
  source_file=$input_file
else
  tmp_file=$(mktemp)
  cat > "$tmp_file"
  source_file=$tmp_file
fi

mapfile -t actual_headings < <(grep -E '^[A-Za-z][A-Za-z -]*:$' "$source_file" || true)
expected_headings=("Status:")

if [[ ${#actual_headings[@]} -ne ${#expected_headings[@]} ]]; then
  echo "Invalid heading count: expected ${#expected_headings[@]}, got ${#actual_headings[@]}" >&2
  exit 1
fi

for index in "${!expected_headings[@]}"; do
  if [[ "${actual_headings[$index]}" != "${expected_headings[$index]}" ]]; then
    echo "Heading order mismatch at position $((index + 1)): expected '${expected_headings[$index]}', got '${actual_headings[$index]}'" >&2
    exit 1
  fi
done

status=$(extract_first_bullet_value "Status:" "$source_file")
require_nonempty_value "Status:" "$status"
require_enum_value "Status:" "$status" completed blocked rejected
